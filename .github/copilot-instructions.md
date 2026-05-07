<!-- SPECKIT START -->
For additional context about technologies to be used, project structure,
shell commands, and other important information, read the current plan:

**Current Feature**: Optimize getifaddrs System Call
**Plan**: docs/001-optimize-getifaddrs/plan.md
**Specification**: docs/001-optimize-getifaddrs/spec.md

**Key Context**:
- Rust crate for cross-platform system information retrieval
- Fixing issue #1598: getifaddrs called twice unnecessarily in NetBSD
- Performance optimization to reduce system call overhead
- Platform-specific change: NetBSD only (src/unix/bsd/netbsd/network.rs)
- Must maintain existing API and behavior while improving performance

**Important Files**:
- src/unix/bsd/netbsd/network.rs - NetBSD network implementation (lines 45-47 FIXME)
- src/unix/network_helper.rs - InterfaceAddress RAII wrapper
- src/network.rs - refresh_networks_addresses function
- tests/network.rs - Network-related tests

**Design Artifacts**:
- Research: docs/001-optimize-getifaddrs/research.md
- Implementation Plan: docs/001-optimize-getifaddrs/plan.md
- Testing Guide: docs/001-optimize-getifaddrs/quickstart.md
<!-- SPECKIT END -->
