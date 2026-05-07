# Data Model: Optimize getifaddrs System Call

**Feature**: 001 - Optimize getifaddrs System Call  
**Created**: 2026-05-07  
**Status**: Complete

---

## Overview

This document defines the data structures and relationships involved in the getifaddrs optimization. Since this is a performance optimization rather than a new feature, the data model remains largely unchanged from the existing implementation. This document describes the entities involved and their relationships.

---

## Entity: InterfaceAddress (RAII Wrapper)

### Purpose
Manages the lifetime of the C-allocated linked list returned by `getifaddrs` system call.

### Location
`src/unix/network_helper.rs`

### Structure
```rust
pub(crate) struct InterfaceAddress {
    /// Pointer to the first element in linked list
    buf: *mut libc::ifaddrs,
}
```

### Fields

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| `buf` | `*mut libc::ifaddrs` | Raw pointer to first ifaddrs node | Never NULL, owned pointer |

### Invariants
- `buf` is always non-NULL (validated in constructor)
- `buf` points to valid memory allocated by `getifaddrs`
- Only one `InterfaceAddress` owns this pointer (no cloning)
- Automatically freed via `Drop` trait when instance goes out of scope

### Lifecycle
1. **Creation**: `InterfaceAddress::new()` calls `libc::getifaddrs(&mut ifap)`
2. **Usage**: Consumers call `.iter()` or `.as_raw_ptr()` to access data
3. **Cleanup**: `Drop::drop()` calls `libc::freeifaddrs(self.buf)` automatically

### Methods

**`new() -> Option<Self>`**
- Calls `getifaddrs` system call
- Returns `Some(InterfaceAddress)` on success
- Returns `None` if system call fails or returns NULL
- Ensures `buf` is never NULL in constructed instance

**`iter(&self) -> InterfaceAddressIterator<'_>`**
- Returns safe iterator over interface/address pairs
- Lifetime parameter ensures iterator doesn't outlive wrapper
- Used by generic network address collection code

**`as_raw_ptr(&self) -> *mut libc::ifaddrs`**
- Returns raw pointer for platform-specific code
- Used by NetBSD-specific iterator that needs AF_LINK filtering
- Safety: Caller must not call `freeifaddrs` on this pointer
- Pointer valid for lifetime of `InterfaceAddress`

---

## Entity: InterfaceAddressRawIterator

### Purpose
NetBSD-specific iterator that filters for AF_LINK addresses to collect interface statistics.

### Location
`src/unix/bsd/netbsd/network.rs`

### Structure
```rust
struct InterfaceAddressRawIterator<'a> {
    ifap: *mut libc::ifaddrs,
    _phantom: PhantomData<&'a InterfaceAddress>,
}
```

### Fields

| Field | Type | Description | Constraints |
|-------|------|-------------|-------------|
| `ifap` | `*mut libc::ifaddrs` | Current position in linked list | Can be NULL (end of list) |
| `_phantom` | `PhantomData<&'a InterfaceAddress>` | Lifetime marker | Ties iterator to wrapper lifetime |

### Behavior
- Iterates through `getifaddrs` linked list
- Filters for AF_LINK family addresses only (hardware/statistics)
- Skips loopback interfaces (IFF_LOOPBACK flag check)
- Returns raw `*mut libc::ifaddrs` pointers (unsafe, NetBSD-specific)

### Lifecycle
1. **Creation**: `new(&'a InterfaceAddress)` - borrows wrapper for lifetime `'a`
2. **Iteration**: Traverses linked list via `ifa_next` pointers
3. **Termination**: Returns `None` when `ifap` becomes NULL

---

## Entity: NetworkData

### Purpose
Stores collected network interface information including statistics, addresses, and operational state.

### Location
`src/common/network.rs`, `src/unix/bsd/mod.rs`

### Structure (Relevant Fields)
```rust
pub struct NetworkData {
    inner: NetworkDataInner,
}

pub(crate) struct NetworkDataInner {
    // Statistics (from AF_LINK addresses)
    ifi_ibytes: u64,
    ifi_obytes: u64,
    ifi_ipackets: u64,
    ifi_opackets: u64,
    ifi_ierrors: u64,
    ifi_oerrors: u64,
    old_ifi_ibytes: u64,
    old_ifi_obytes: u64,
    old_ifi_ipackets: u64,
    old_ifi_opackets: u64,
    old_ifi_ierrors: u64,
    old_ifi_oerrors: u64,
    
    // Addresses (from AF_INET/AF_INET6)
    mac_addr: MacAddr,
    ip_networks: Vec<IpNetwork>,
    
    // Metadata
    mtu: u32,
    operational_state: InterfaceOperationalState,
    updated: bool,
}
```

### Data Sources

**From AF_LINK addresses** (via `refresh_interfaces_from_ifaddrs`):
- `ifi_ibytes`, `ifi_obytes` - byte counters
- `ifi_ipackets`, `ifi_opackets` - packet counters
- `ifi_ierrors`, `ifi_oerrors` - error counters
- `mtu` - Maximum Transmission Unit
- `operational_state` - Interface up/down status

**From AF_INET/AF_INET6 addresses** (via `refresh_networks_addresses_from_ifaddrs`):
- `mac_addr` - Hardware MAC address (from AF_LINK)
- `ip_networks` - List of IP addresses with prefix lengths

### State Transitions
1. **New Interface**: Created in `Vacant` entry path with initial statistics
2. **Updated Interface**: Statistics updated via `old_and_new!` macro, preserves old values for delta calculation
3. **Removed Interface**: Filtered out if `updated` flag is false after refresh

---

## Entity: ifaddrs (C Structure)

### Purpose
External C structure from `libc` representing a single network interface address entry.

### Location
`libc` crate, defined by NetBSD system headers

### Structure (Simplified)
```c
struct ifaddrs {
    struct ifaddrs *ifa_next;    // Next entry in linked list
    char           *ifa_name;    // Interface name (e.g., "em0")
    unsigned int    ifa_flags;   // Interface flags (IFF_UP, etc.)
    struct sockaddr *ifa_addr;   // Address (AF_LINK/AF_INET/AF_INET6)
    struct sockaddr *ifa_netmask; // Netmask
    union {
        struct sockaddr *ifu_broadaddr;
        struct sockaddr *ifu_dstaddr;
    } ifa_ifu;
    void           *ifa_data;    // Platform-specific data (if_data*)
};
```

### Lifetime
- Allocated by `getifaddrs()` in kernel space, returned to userspace
- Forms a NULL-terminated linked list (last `ifa_next` is NULL)
- MUST be freed with `freeifaddrs()` to prevent memory leak
- Managed by `InterfaceAddress` wrapper in our implementation

---

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│  refresh() - NetBSD NetworksInner method                    │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       │ 1. Call getifaddrs ONCE
                       ▼
          ┌────────────────────────────┐
          │  InterfaceAddress::new()   │
          │  - Calls libc::getifaddrs  │
          │  - Returns RAII wrapper    │
          └────────┬───────────────────┘
                   │
                   │ Wrapper contains: *mut libc::ifaddrs
                   │
        ┌──────────┴──────────┐
        │                     │
        ▼                     ▼
┌─────────────────┐  ┌─────────────────────────────┐
│  AF_LINK only   │  │  ALL address families       │
│  (statistics)   │  │  (IP/MAC addresses)         │
└────────┬────────┘  └───────────┬─────────────────┘
         │                       │
         ▼                       ▼
┌────────────────────┐  ┌──────────────────────────────┐
│ refresh_interfaces │  │ refresh_networks_addresses   │
│ _from_ifaddrs      │  │ _from_ifaddrs                │
│                    │  │                              │
│ Uses:              │  │ Uses:                        │
│ - Raw iterator     │  │ - InterfaceAddress.iter()    │
│ - Filters AF_LINK  │  │ - Processes all families     │
│                    │  │                              │
│ Collects:          │  │ Collects:                    │
│ - Statistics       │  │ - MAC addresses              │
│ - MTU              │  │ - IP addresses               │
│ - Operational state│  │ - Prefixes/netmasks          │
└────────┬───────────┘  └──────────┬───────────────────┘
         │                         │
         └──────────┬──────────────┘
                    │
                    ▼
          ┌─────────────────────┐
          │  NetworkData        │
          │  (per interface)    │
          │                     │
          │  - Statistics       │
          │  - IP addresses     │
          │  - MAC address      │
          │  - MTU, state       │
          └─────────────────────┘
                    │
                    │ Automatic cleanup
                    ▼
          ┌─────────────────────┐
          │  Drop::drop()       │
          │  on InterfaceAddress│
          │                     │
          │  Calls freeifaddrs  │
          └─────────────────────┘
```

---

## Relationships

### InterfaceAddress ↔ ifaddrs
- **Relationship**: Owns (1:1)
- **Cardinality**: One `InterfaceAddress` owns one `ifaddrs` linked list head
- **Lifetime**: `ifaddrs` lifetime bound to `InterfaceAddress` lifetime
- **Cleanup**: Automatic via `Drop` trait

### InterfaceAddress ↔ InterfaceAddressRawIterator  
- **Relationship**: Borrowed by (1:N during iteration)
- **Cardinality**: One wrapper, multiple iterator instances possible
- **Lifetime**: Iterator cannot outlive wrapper (enforced by `'a` lifetime)
- **Safety**: Iterator uses raw pointer, requires `unsafe` but wrapper guarantees validity

### ifaddrs ↔ NetworkData
- **Relationship**: Populates (N:M)
- **Cardinality**: Multiple `ifaddrs` entries populate each `NetworkData` instance
- **Flow**: AF_LINK entries provide statistics, AF_INET/AF_INET6 provide addresses
- **Aggregation**: Multiple addresses per interface accumulated in `ip_networks` vector

---

## Data Invariants

1. **No NULL InterfaceAddress**: Constructor returns `Option`, ensures `buf` is never NULL in constructed instance
2. **No Double-Free**: Only `Drop` trait calls `freeifaddrs`, called exactly once
3. **No Dangling Pointers**: Lifetime parameters prevent iterator outliving wrapper
4. **Consistent NetworkData**: Both statistic and address updates occur atomically within single `refresh()` call
5. **No Data Loss**: All `ifaddrs` entries processed (AF_LINK for stats, AF_INET/AF_INET6 for addresses)

---

## Performance Characteristics

### Memory Usage
- **Before Optimization**: Two full `ifaddrs` linked lists allocated (2× memory)
- **After Optimization**: One `ifaddrs` linked list (1× memory)
- **Savings**: 50% reduction in peak memory for network refresh

### CPU Usage
- **Before**: Two system calls, two linked list traversals
- **After**: One system call, one traversal for AF_LINK, one for all families
- **Net Effect**: ~50% reduction in syscall overhead, similar traversal cost

### Scalability
- **Linear with Interfaces**: Cost scales with interface count
- **Typical Systems**: 2-10 interfaces (low overhead)
- **High-Density Systems**: 100+ interfaces (optimization more significant)

---

## Summary

The data model centers on the `InterfaceAddress` RAII wrapper, which ensures memory safety while allowing efficient reuse of `getifaddrs` results. The optimization maintains all existing data structures and relationships while eliminating redundant system calls. No changes to the public API or data model from a consumer perspective.
