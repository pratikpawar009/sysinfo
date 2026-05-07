<!--
Sync Impact Report (2026-05-07)
- Version: 0.0.0 → 1.0.0 (Initial ratification)
- Status: NEW CONSTITUTION
- Principles Added: 5 core principles
  1. Cross-Platform Compatibility
  2. Performance Optimization
  3. Memory Safety & RAII
  4. API Stability
  5. Platform-Specific Testing
- Templates Status:
  ✅ Constitution created
  ⚠ Plan template - pending creation
  ⚠ Spec template - pending creation
  ⚠ Tasks template - pending creation
- Follow-up: Create supporting templates to align with constitutional principles
-->

# Project Constitution

---
**Version**: 1.0.0  
**Ratified**: 2026-05-07  
**Last Amended**: 2026-05-07  
**Status**: Active
---

## Preamble

This constitution defines the non-negotiable principles, standards, and governance rules for **sysinfo**. Every design artifact, implementation task, code review, and architectural decision MUST align with these principles.

**Mission**: Provide a safe, efficient, and reliable cross-platform Rust crate for retrieving system information across all supported operating systems.

**Scope**: This constitution applies to all development work on the sysinfo crate, including but not limited to: platform-specific implementations, API design, performance optimizations, testing strategies, and external contributions.

---

## Article I: Core Principles

These principles are **immutable** during implementation. Changes require explicit constitutional amendment through the governance process defined in Article III.

### Principle 1: Cross-Platform Compatibility

**Rule**: All features MUST maintain consistent behavior across all supported platforms (Linux, macOS, Windows, FreeBSD, NetBSD, iOS, Android, Raspberry Pi). Platform-specific implementations MUST provide equivalent functionality or gracefully degrade with clear documentation when platform limitations exist.

**Rationale**: Users depend on sysinfo for consistent cross-platform system information retrieval. Breaking platform parity creates technical debt and reduces library utility.

**Validation Criteria**:
- All public APIs work identically across supported platforms unless explicitly documented otherwise
- Platform-specific code is isolated in appropriate module boundaries (e.g., `src/unix/`, `src/windows/`)
- Fallback mechanisms exist for platform-limited functionality
- CI/CD tests run on all major supported platforms

---

### Principle 2: Performance Optimization

**Rule**: System calls and resource-intensive operations MUST be minimized and optimized. Redundant system calls, unnecessary allocations, and inefficient algorithms are prohibited. Performance regressions require justification and must be traded off against other constitutional principles.

**Rationale**: System information retrieval should impose minimal overhead on host applications. Users expect efficient, low-latency operations, especially when polling system state repeatedly. Current optimization work (Issue #1598) exemplifies this principle.

**Validation Criteria**:
- System calls are counted and documented for each operation
- Benchmarks exist for critical paths
- Performance regressions are detected in CI
- Memory allocations are profiled and justified
- Redundant operations are eliminated (e.g., duplicate `getifaddrs` calls)

---

### Principle 3: Memory Safety & RAII

**Rule**: All resource management MUST follow Rust's ownership model and RAII patterns. Foreign function interface (FFI) calls MUST be properly wrapped to guarantee memory safety. Manual memory management MUST use established wrapper types (e.g., `InterfaceAddress` for `getifaddrs` results).

**Rationale**: Memory safety is Rust's core guarantee. Unsafe code in FFI boundaries must be carefully managed to prevent leaks, use-after-free, and undefined behavior.

**Validation Criteria**:
- All FFI allocations have corresponding RAII wrappers
- No memory leaks detected by Valgrind or sanitizers
- Unsafe blocks are minimized and documented with safety invariants
- Drop implementations properly release system resources
- Miri tests pass for platform-independent code

---

### Principle 4: API Stability

**Rule**: Public API changes MUST follow semantic versioning strictly. Breaking changes require major version bumps and MUST include migration guides. Internal refactorings MUST NOT alter public API behavior or signatures without explicit versioning.

**Rationale**: Downstream users depend on API stability for production systems. Unannounced breaking changes create ecosystem churn and erode trust.

**Validation Criteria**:
- `cargo-semver-checks` passes on all releases
- Breaking changes documented in CHANGELOG and migration_guide.md
- Deprecation warnings precede removal by at least one minor version
- Internal refactorings maintain identical public behavior
- Integration tests validate API contract preservation

---

### Principle 5: Platform-Specific Testing

**Rule**: Every platform-specific code path MUST have corresponding test coverage. Tests MUST run on the target platform in CI. Mock-based testing is insufficient for platform-specific behavior validation.

**Rationale**: Platform-specific bugs are only detectable on the target platform. Cross-compilation and mocking cannot catch platform-specific race conditions, syscall variations, or OS version differences.

**Validation Criteria**:
- CI matrix includes all supported platforms
- Platform-specific modules have dedicated test files
- Tests validate actual system calls, not mocks
- Edge cases (missing permissions, unavailable data) are tested
- FreeBSD, NetBSD, and other BSD variants have dedicated CI runners

---

## Article II: Technical Standards

### Code Quality

- **Rust Edition**: Use the minimum supported Rust version (currently 1.95) unless explicitly upgraded
- **Linting**: All code MUST pass `clippy` with standard warnings enforced
- **Formatting**: All code MUST be formatted with `rustfmt` using project defaults
- **Documentation**: Public APIs MUST have docstring examples that compile and run via `cargo test --doc`
- **Unsafe Code**: Unsafe blocks MUST include safety comments explaining invariants and why the code is sound

### Documentation

- **README**: MUST reflect current OS support matrix and usage examples
- **CHANGELOG**: MUST document all user-facing changes following Keep a Changelog format
- **Migration Guide**: MUST be updated for all breaking changes with before/after code samples
- **Inline Docs**: Complex platform-specific logic MUST include rationale comments
- **FIXME/TODO**: Outstanding issues MUST reference GitHub issue numbers

### Testing

- **Unit Tests**: Every module MUST have unit tests for public and critical internal functions
- **Integration Tests**: Public APIs MUST have `tests/` integration test coverage
- **Platform Tests**: Platform-specific code paths MUST be tested on target platforms in CI
- **Benchmarks**: Performance-critical paths MUST have benchmarks in `benches/`
- **Regression Tests**: Bug fixes MUST include regression tests to prevent reoccurrence

### Performance

- **System Call Limits**: Minimize system calls; document and justify each call
- **Allocation Limits**: Avoid allocations in hot paths; use stack allocation where safe
- **Caching**: Cache expensive operations (e.g., interface lists) when semantically correct
- **Profiling**: Performance-critical code MUST be profiled under realistic workloads
- **Benchmarking**: Changes affecting hot paths MUST include before/after benchmark results

---

## Article III: Governance

### Amendment Process

1. **Proposal**: Constitutional amendments MUST be proposed via GitHub issue with rationale
2. **Discussion**: Maintainers and community discuss implications for at least 7 days
3. **Approval**: Amendments require approval from at least two core maintainers
4. **Documentation**: Approved amendments are incorporated via `/constitution` agent command
5. **Synchronization**: Dependent templates (spec, plan, tasks) MUST be updated to reflect changes
6. **Version Bump**: Constitution version is updated per semantic versioning rules

### Version Control

Constitution versions follow semantic versioning:
- **MAJOR**: Backward-incompatible principle changes, removed principles, or fundamental redefinitions
- **MINOR**: New principles added or material expansion of existing guidance
- **PATCH**: Clarifications, wording improvements, typo fixes, non-semantic refinements

### Compliance Review

- **Pre-Merge**: All pull requests MUST align with constitutional principles
- **Code Review**: Reviewers MUST cite constitutional violations explicitly
- **Spec Review**: Feature specs MUST include constitutional compliance checklist
- **Audit**: Quarterly review of codebase for constitutional drift
- **Violations**: Constitutional violations MUST be resolved before merge or require amendment

---

## Article IV: Conflict Resolution

When conflicts arise between principles:

1. **Safety First**: Memory Safety & RAII (Principle 3) takes precedence over Performance (Principle 2)
2. **Stability Over Features**: API Stability (Principle 4) takes precedence over adding new functionality
3. **Compatibility Over Performance**: Cross-Platform Compatibility (Principle 1) takes precedence over platform-specific optimizations
4. **Testing Non-Negotiable**: Platform-Specific Testing (Principle 5) cannot be waived for expediency
5. **Escalation**: Irreconcilable conflicts MUST be escalated to constitutional amendment process

**Priority Order** (highest to lowest):
1. Memory Safety & RAII (Principle 3)
2. Cross-Platform Compatibility (Principle 1)
3. API Stability (Principle 4)
4. Platform-Specific Testing (Principle 5)
5. Performance Optimization (Principle 2)

**Note**: This order provides guidance; real-world situations may require nuanced judgment. Document reasoning when deviating.

---

**End of Constitution**
