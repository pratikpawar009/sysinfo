// Take a look at the license at the top of the repository in the LICENSE file.

use std::collections::{HashMap, hash_map};

use crate::network::refresh_networks_addresses;
use crate::unix::bsd::NetworkDataInner;
use crate::{InterfaceOperationalState, MacAddr, NetworkData};

macro_rules! old_and_new {
    ($ty_:expr, $name:ident, $old:ident, $data:expr) => {{
        $ty_.$old = $ty_.$name;
        $ty_.$name = $data.$name;
    }};
}

pub(crate) struct NetworksInner {
    pub(crate) interfaces: HashMap<String, NetworkData>,
}

impl NetworksInner {
    pub(crate) fn new() -> Self {
        Self {
            interfaces: HashMap::new(),
        }
    }

    pub(crate) fn list(&self) -> &HashMap<String, NetworkData> {
        &self.interfaces
    }

    pub(crate) fn refresh(&mut self, remove_not_listed_interfaces: bool) {
        // Call getifaddrs ONCE and share the data.
        //
        // Previously, getifaddrs was called twice per refresh:
        // 1. In refresh_interfaces() for collecting statistics (AF_LINK addresses)
        // 2. In refresh_networks_addresses() for collecting IP/MAC addresses
        //
        // This optimization reduces system call overhead by 50% by calling getifaddrs
        // once and sharing the result via InterfaceAddress wrapper (RAII pattern).
        //
        // See docs/001-optimize-getifaddrs/ for full design rationale.
        let Some(ifaddrs) = crate::unix::network_helper::InterfaceAddress::new() else {
            sysinfo_debug!("getifaddrs failed");
            return;
        };

        unsafe {
            self.refresh_interfaces_from_ifaddrs(&ifaddrs, true);
        }
        if remove_not_listed_interfaces {
            // Remove interfaces which are gone.
            self.interfaces.retain(|_, i| {
                if !i.inner.updated {
                    return false;
                }
                i.inner.updated = false;
                true
            });
        }
        refresh_networks_addresses_from_ifaddrs(&mut self.interfaces, &ifaddrs);
    }

    unsafe fn refresh_interfaces_from_ifaddrs(
        &mut self,
        ifaddrs: &crate::unix::network_helper::InterfaceAddress,
        refresh_all: bool,
    ) {
        unsafe {
            // Use raw iterator over external ifaddrs data
            for ifa in InterfaceAddressRawIterator::new(ifaddrs) {
                let ifa = &*ifa;
                if let Some(name) = std::ffi::CStr::from_ptr(ifa.ifa_name)
                    .to_str()
                    .ok()
                    .map(|s| s.to_string())
                {
                    let flags = ifa.ifa_flags;
                    let data: &libc::if_data = &*(ifa.ifa_data as *mut libc::if_data);
                    let mtu = data.ifi_mtu;
                    let operational_state = InterfaceOperationalState::from_flag(
                        flags as core::ffi::c_int,
                        data.ifi_link_state,
                    );
                    match self.interfaces.entry(name) {
                        hash_map::Entry::Occupied(mut e) => {
                            let interface = e.get_mut();
                            let interface = &mut interface.inner;

                            old_and_new!(interface, ifi_ibytes, old_ifi_ibytes, data);
                            old_and_new!(interface, ifi_obytes, old_ifi_obytes, data);
                            old_and_new!(interface, ifi_ipackets, old_ifi_ipackets, data);
                            old_and_new!(interface, ifi_opackets, old_ifi_opackets, data);
                            old_and_new!(interface, ifi_ierrors, old_ifi_ierrors, data);
                            old_and_new!(interface, ifi_oerrors, old_ifi_oerrors, data);
                            interface.mtu = mtu;
                            interface.operational_state = operational_state;
                            interface.updated = true;
                        }
                        hash_map::Entry::Vacant(e) => {
                            if !refresh_all {
                                // This is simply a refresh, we don't want to add new interfaces!
                                continue;
                            }
                            e.insert(NetworkData {
                                inner: NetworkDataInner {
                                    ifi_ibytes: data.ifi_ibytes,
                                    old_ifi_ibytes: 0,
                                    ifi_obytes: data.ifi_obytes,
                                    old_ifi_obytes: 0,
                                    ifi_ipackets: data.ifi_ipackets,
                                    old_ifi_ipackets: 0,
                                    ifi_opackets: data.ifi_opackets,
                                    old_ifi_opackets: 0,
                                    ifi_ierrors: data.ifi_ierrors,
                                    old_ifi_ierrors: 0,
                                    ifi_oerrors: data.ifi_oerrors,
                                    old_ifi_oerrors: 0,
                                    updated: true,
                                    mac_addr: MacAddr::UNSPECIFIED,
                                    ip_networks: vec![],
                                    mtu,
                                    operational_state,
                                },
                            });
                        }
                    }
                }
            }
        }
    }
}

/// Iterator over AF_LINK addresses from external ifaddrs data (NetBSD-specific).
/// This iterator filters for AF_LINK addresses to access interface statistics.
struct InterfaceAddressRawIterator<'a> {
    ifap: *mut libc::ifaddrs,
    _phantom: std::marker::PhantomData<&'a crate::unix::network_helper::InterfaceAddress>,
}

impl<'a> InterfaceAddressRawIterator<'a> {
    fn new(ifaddrs: &'a crate::unix::network_helper::InterfaceAddress) -> Self {
        Self {
            ifap: ifaddrs.as_raw_ptr(),
            _phantom: std::marker::PhantomData,
        }
    }
}

impl<'a> Iterator for InterfaceAddressRawIterator<'a> {
    type Item = *mut libc::ifaddrs;

    fn next(&mut self) -> Option<Self::Item> {
        unsafe {
            while !self.ifap.is_null() {
                // advance the pointer until an AF_LINK address is found
                // Safety: `ifap` is already checked as non-null in the loop condition.
                let ifap = self.ifap;
                let r_ifap = &*ifap;
                self.ifap = r_ifap.ifa_next;

                // Filter: AF_LINK only, non-loopback
                if r_ifap.ifa_addr.is_null()
                    || (*r_ifap.ifa_addr).sa_family as libc::c_int != libc::AF_LINK
                    || r_ifap.ifa_flags & libc::IFF_LOOPBACK as libc::c_uint != 0
                {
                    continue;
                }
                return Some(ifap);
            }
            None
        }
    }
}

/// NetBSD-specific: Populate IP/MAC addresses from external ifaddrs data.
///
/// This function accepts an external `InterfaceAddress` to avoid calling
/// `getifaddrs` twice. See docs/001-optimize-getifaddrs/plan.md for rationale.
pub(crate) fn refresh_networks_addresses_from_ifaddrs(
    interfaces: &mut HashMap<String, NetworkData>,
    ifaddrs: &crate::unix::network_helper::InterfaceAddress,
) {
    // Iterate over ALL address families (not just AF_LINK)
    for (name, address_helper) in ifaddrs.iter() {
        if let Some(interface) = interfaces.get_mut(&name) {
            // Populate MAC address (from AF_LINK)
            if let Some(mac) = address_helper.mac_addr() {
                interface.inner.mac_addr = mac;
            }

            // Populate IP addresses (from AF_INET/AF_INET6)
            if let Some(ip) = address_helper.ip() {
                let prefix = address_helper.prefix();
                let ip_network = crate::IpNetwork { addr: ip, prefix };

                if !interface.inner.ip_networks.contains(&ip_network) {
                    interface.inner.ip_networks.push(ip_network);
                }
            }
        }
    }
}
