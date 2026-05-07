# Feature Specification: Optimize getifaddrs System Call

**Feature ID**: 001  
**Status**: Draft  
**Created**: 2026-05-07  
**Last Updated**: 2026-05-07  
**Owner**: Development Team  
**Related Issue**: #1598

## Overview

Optimize the NetBSD network interface refresh implementation to eliminate redundant `getifaddrs` system calls. Currently, the `refresh()` method calls `getifaddrs` twice - once in `refresh_interfaces()` and again in `refresh_networks_addresses()` - causing unnecessary performance overhead. This feature refactors the code to call `getifaddrs` only once and reuse the result across both operations.

## Problem Statement

The current implementation in `src/unix/bsd/netbsd/network.rs` has a documented FIXME (line 45-46) indicating that `getifaddrs` is called twice:

1. First call in `refresh_interfaces()` via `InterfaceAddressIterator::new()`
2. Second call in `refresh_networks_addresses()` 

Each `getifaddrs` call:
- Is a system call with kernel transition overhead
- Allocates memory for the interface list
- Traverses the kernel's network interface data structures
- Creates a linked list snapshot of all network interfaces

Calling it twice per refresh cycle:
- **Doubles system call overhead** (kernel context switches)
- **Doubles memory allocation/deallocation**
- **Doubles CPU time** spent traversing kernel structures
- **Impacts battery life** on mobile/embedded NetBSD systems
- **Degrades performance** when called frequently (monitoring, dashboards)

## Goals

### Primary Goals
- **FR-001**: Reduce `getifaddrs` calls from 2 to 1 per `refresh()` invocation
- **FR-002**: Maintain existing public API and behavior (no breaking changes)
- **FR-003**: Preserve all existing functionality (statistics, addresses, MAC addresses)
- **FR-004**: Ensure proper memory management (no leaks, correct cleanup)

### Success Criteria
- **SC-001**: System call count verification: `ktrace` shows exactly 1 `getifaddrs` call per refresh
- **SC-002**: Performance improvement: Measurable reduction in refresh() execution time
- **SC-003**: All existing tests pass without modification
- **SC-004**: No regressions in memory usage or correctness

## User Stories

### US-001: System Monitoring Application Developer
**As a** developer of a system monitoring application  
**I want** network interface refresh operations to be efficient  
**So that** I can poll network statistics frequently without significant CPU overhead

**Acceptance Criteria**:
- Refresh operations complete in <50% of current time
- CPU usage per refresh reduced by ~40-50%
- Memory allocations reduced by half

### US-002: NetBSD System Administrator
**As a** NetBSD system administrator  
**I want** accurate network statistics with minimal performance impact  
**So that** monitoring doesn't interfere with production workloads

**Acceptance Criteria**:
- All network statistics remain accurate
- Interface operational states correctly reported
- MAC addresses properly retrieved
- IP addresses correctly populated

## Functional Requirements

### FR-001: Single getifaddrs Call
**Priority**: High  
**Description**: Refactor `refresh()` to call `getifaddrs` exactly once

**Details**:
- Move `getifaddrs` call to `refresh()` method
- Pass the result to both `refresh_interfaces()` and `refresh_networks_addresses()`
- Ensure proper cleanup with `freeifaddrs` after both operations complete

**Constraints**:
- Must work with existing `InterfaceAddress` wrapper from `network_helper.rs`
- Must handle `getifaddrs` failure gracefully
- Must maintain thread-safety if applicable

### FR-002: Refactor refresh_interfaces
**Priority**: High  
**Description**: Modify `refresh_interfaces()` to accept external `ifaddrs` data

**Details**:
- Change signature to accept `&InterfaceAddress` or similar parameter
- Remove internal `InterfaceAddressIterator::new()` call
- Iterate over provided data instead of creating new iterator
- Maintain all existing statistics collection logic

**Constraints**:
- Platform-specific (NetBSD-only change)
- Must filter for `AF_LINK` addresses as before
- Must skip loopback interfaces as before

### FR-003: Refactor refresh_networks_addresses
**Priority**: High  
**Description**: Ensure `refresh_networks_addresses()` uses shared `ifaddrs` data

**Details**:
- If currently calls `getifaddrs` internally, remove that call
- Accept the same shared data structure
- Populate IP addresses and MAC addresses from shared data
- Maintain existing address family handling (IPv4, IPv6)

**Constraints**:
- Must work across all BSD variants if function is shared
- Must handle missing data gracefully

### FR-004: Memory Management
**Priority**: High  
**Description**: Ensure single allocation/deallocation cycle

**Details**:
- Allocate: One `getifaddrs` call in `refresh()`
- Use: Both `refresh_interfaces()` and `refresh_networks_addresses()` iterate
- Deallocate: One `freeifaddrs` call after both operations complete
- Leverage existing RAII pattern in `InterfaceAddress` wrapper

**Constraints**:
- Must not leak memory on early returns
- Must not double-free on error paths
- Must handle null pointers safely

## Non-Functional Requirements

### Performance
- **Target**: 40-50% reduction in `refresh()` execution time
- **Measurement**: Criterion benchmark comparing before/after
- **Verification**: ktrace system call tracing on NetBSD

### Compatibility
- **API Stability**: No changes to public `NetworksInner` interface
- **Binary Compatibility**: No changes to C FFI if applicable
- **Platform**: NetBSD-specific change, other platforms unaffected

### Testing
- **Unit Tests**: All existing network tests must pass
- **Integration Tests**: No modifications required to test suite
- **System Tests**: Manual verification on NetBSD (10.x recommended)

## Technical Constraints

### Platform Scope
- **Affected**: NetBSD only (`src/unix/bsd/netbsd/network.rs`)
- **Unaffected**: FreeBSD, Linux, macOS, Windows implementations
- **Reason**: Other platforms may use different APIs or already optimize

### Dependencies
- **Required**: Existing `InterfaceAddress` wrapper from `src/unix/network_helper.rs`
- **Assumption**: `InterfaceAddress` supports multiple iterations over same data
- **Verification**: Check if `InterfaceAddress`'s iterator can be cloned/reset

### Code Locations
```
src/unix/bsd/netbsd/network.rs
  ├── NetworksInner::refresh()          [MODIFY: Add single getifaddrs call]
  ├── NetworksInner::refresh_interfaces() [MODIFY: Accept external data]
  └── InterfaceAddressIterator          [POSSIBLY MODIFY: Support external data]

src/network.rs
  └── refresh_networks_addresses()      [VERIFY: Check if calls getifaddrs]

src/unix/network_helper.rs
  └── InterfaceAddress                  [USE: RAII wrapper for getifaddrs]
```

## Out of Scope

### Excluded from This Feature
- ❌ Optimizations for other BSD variants (FreeBSD)
- ❌ Changes to Linux/Windows/macOS implementations
- ❌ Caching of network interface data across refreshes
- ❌ Asynchronous or background refresh mechanisms
- ❌ Changes to public API or method signatures
- ❌ Performance optimization beyond getifaddrs reduction

### Future Considerations
- Benchmark-driven optimization for other platforms
- Differential updates (track only changed interfaces)
- Configurable refresh rates based on change frequency

## Assumptions

1. **InterfaceAddress Design**: The existing `InterfaceAddress` wrapper in `network_helper.rs` uses RAII pattern with `Drop` trait for cleanup
2. **Iterator Behavior**: The data returned by `getifaddrs` can be iterated multiple times or multiple iterators can work with same data
3. **Thread Safety**: Network refresh operations are not called concurrently on the same `NetworksInner` instance
4. **NetBSD Version**: Changes target modern NetBSD versions (9.x+) with stable libc API
5. **Testing Access**: Developer has access to NetBSD system for testing and syscall tracing

## Dependencies

### Internal Dependencies
- `src/unix/network_helper.rs::InterfaceAddress` - RAII wrapper for getifaddrs
- `src/network.rs::refresh_networks_addresses()` - Shared network address population logic
- `src/unix/bsd/netbsd/network.rs::InterfaceAddressIterator` - Current iterator implementation

### External Dependencies
- NetBSD `libc::getifaddrs()` - System call to retrieve interface list
- NetBSD `libc::freeifaddrs()` - Cleanup function for allocated data
- Criterion crate - For performance benchmarking (dev dependency)

## Risks and Mitigations

### Risk 1: InterfaceAddress Not Reusable
**Probability**: Medium  
**Impact**: High  
**Description**: `InterfaceAddress` iterator might consume data or not support multiple iterations

**Mitigation**:
- Inspect `InterfaceAddress` implementation before refactoring
- If needed, create new iterator type that accepts external `*mut ifaddrs` pointer
- Ensure new iterator doesn't own the data (no Drop implementation)

### Risk 2: Shared Data Lifetime Issues
**Probability**: Low  
**Impact**: High  
**Description**: Data might be freed before second operation completes

**Mitigation**:
- Use Rust borrowing to ensure data lives through both operations
- Keep `InterfaceAddress` (RAII wrapper) alive until both functions complete
- Add explicit lifetime annotations if needed

### Risk 3: Platform-Specific Behavior Differences
**Probability**: Low  
**Impact**: Medium  
**Description**: NetBSD `getifaddrs` might have subtleties that break with single-call approach

**Mitigation**:
- Test on multiple NetBSD versions (9.x, 10.x)
- Use ktrace to verify system call behavior matches expectations
- Review NetBSD man pages for `getifaddrs` guarantees

### Risk 4: Test Coverage Gaps
**Probability**: Medium  
**Impact**: Medium  
**Description**: Existing tests might not catch all edge cases in refactored code

**Mitigation**:
- Run full test suite on NetBSD platform (not just Linux CI)
- Add ktrace-based system test to verify single syscall
- Manual testing of various interface configurations (VLAN, bridge, tunnel, etc.)

## Open Questions

1. **Q**: Does `InterfaceAddress` from `network_helper.rs` support multiple iterations over the same data?  
   **Action**: Review `InterfaceAddress` implementation and document iterator behavior

2. **Q**: Does `refresh_networks_addresses()` in `src/network.rs` currently call `getifaddrs` for NetBSD?  
   **Action**: Trace code path to confirm second call location

3. **Q**: Are there any MT-safety concerns with shared ifaddrs data across function calls?  
   **Action**: Check if `refresh()` can be called concurrently, review locking

4. **Q**: What is the typical size of interface lists on NetBSD systems?  
   **Action**: Test on typical systems (laptop: 2-5 interfaces, server: 10-20 interfaces)

5. **Q**: Should we add a benchmark specifically for this optimization?  
   **Action**: Add `benches/network_refresh.rs` with before/after comparison

6. **Q**: Do we need to notify other BSD variant maintainers about this pattern?  
   **Action**: Check if FreeBSD implementation has similar issue, document findings

## Acceptance Criteria

### Functional Acceptance
- [ ] **AC-F1**: `refresh()` calls `getifaddrs` exactly once (verified with ktrace)
- [ ] **AC-F2**: All network interface statistics are correctly populated
- [ ] **AC-F3**: MAC addresses are correctly retrieved for all interfaces
- [ ] **AC-F4**: IPv4 and IPv6 addresses are correctly populated
- [ ] **AC-F5**: Interface operational states are correctly determined
- [ ] **AC-F6**: Removed interfaces are correctly pruned when flag is set

### Technical Acceptance
- [ ] **AC-T1**: All existing unit tests pass without modification
- [ ] **AC-T2**: All existing integration tests pass without modification
- [ ] **AC-T3**: Code compiles on NetBSD without warnings
- [ ] **AC-T4**: No new clippy lints introduced
- [ ] **AC-T5**: FIXME comment (lines 45-46) is removed

### Performance Acceptance
- [ ] **AC-P1**: `refresh()` execution time reduced by ≥40%
- [ ] **AC-P2**: System call overhead reduced by 50% (proven via ktrace)
- [ ] **AC-P3**: Memory allocations reduced (measurable in benchmark)
- [ ] **AC-P4**: No performance regression on other BSD platforms

### Documentation Acceptance
- [ ] **AC-D1**: CHANGELOG.md updated with optimization note
- [ ] **AC-D2**: Code comments explain single-call pattern
- [ ] **AC-D3**: Implementation notes document InterfaceAddress usage
- [ ] **AC-D4**: Benchmark results documented for reference

## References

- **Issue**: #1598 - getifaddrs called twice in NetBSD network refresh
- **File**: `src/unix/bsd/netbsd/network.rs` (lines 45-47, FIXME comment)
- **Man Pages**: 
  - NetBSD `getifaddrs(3)` - https://man.netbsd.org/getifaddrs.3
  - NetBSD `ifaddrs` structure - https://man.netbsd.org/getifaddrs.3#DESCRIPTION
- **Related Code**:
  - `src/unix/network_helper.rs::InterfaceAddress`
  - `src/network.rs::refresh_networks_addresses()`
