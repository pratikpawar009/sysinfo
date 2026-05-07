# QuickStart Guide: Testing & Verifying Optimization

**Feature**: 001 - Optimize getifaddrs System Call  
**Audience**: Developers, QA, Reviewers  
**Platform**: NetBSD (primary), Linux/FreeBSD (regression testing)

---

## Prerequisites

### Required
- Rust toolchain 1.95+ (`rustup default stable`)
- NetBSD 9.x or 10.x (for primary testing)
- `cargo` and `cargo-criterion` installed

### Optional
- `ktrace`/`kdump` (NetBSD system call tracer)
- `valgrind` (memory leak detection, if available on NetBSD)
- `gh` CLI (for PR creation)

---

## Quick Verification (5 minutes)

### Step 1: Build and Test

```bash
# Clone and checkout feature branch
git clone https://github.com/GuillaumeGomez/sysinfo.git
cd sysinfo
git checkout feature/test_changes

# Build
cargo build --release

# Run tests
cargo test --lib --test network
```

**Expected**: All 83 tests pass (44 lib + 39 integration)

### Step 2: Run Simple Example

```bash
# Build example
cargo build --example simple

# Run  
./target/debug/examples/simple
```

**Expected**: Output shows network interfaces with statistics

---

## System Call Verification (NetBSD)

### Using ktrace to Verify Single getifaddrs Call

**Purpose**: Prove that `getifaddrs` is called exactly once per refresh (not twice).

#### Step 1: Build Test Program

```bash
cargo build --release --example simple
```

#### Step 2: Trace System Calls

```bash
# Run with syscall tracing
ktrace -t c -f ktrace.out ./target/release/examples/simple

# Alternative: trace specific syscalls only
ktrace -t c -f ktrace.out -i ./target/release/examples/simple
```

#### Step 3: Analyze Trace

```bash
# Extract getifaddrs calls
kdump -f ktrace.out | grep 'getifaddrs'

# Count occurrences
kdump -f ktrace.out | grep -c 'getifaddrs'
```

**Expected Output (BEFORE optimization)**:
```
 18937 simple   CALL  getifaddrs(0x7f7fffd00)
 18937 simple   RET   getifaddrs 0
 18937 simple   CALL  getifaddrs(0x7f7fffd08)  # DUPLICATE!
 18937 simple   RET   getifaddrs 0
 18937 simple   CALL  freeifaddrs(0x7f7fff000)
 18937 simple   CALL  freeifaddrs(0x7f7fff008)  # DUPLICATE!
```

**Expected Output (AFTER optimization)**:
```
 18937 simple   CALL  getifaddrs(0x7f7fffd00)
 18937 simple   RET   getifaddrs 0
 18937 simple   CALL  freeifaddrs(0x7f7fff000)
```

**Verification**:
```bash
# Should output: 1
kdump -f ktrace.out | grep -c 'CALL.*getifaddrs'
```

✅ **PASS**: Exactly 1 `getifaddrs` call  
❌ **FAIL**: 2 or more calls (optimization not working)

---

## Performance Benchmarking

### Using Criterion

#### Step 1: Create Benchmark (if not exists)

File: `benches/network_refresh.rs`

```rust
use criterion::{black_box, criterion_group, criterion_main, Criterion};
use sysinfo::Networks;

fn network_refresh_benchmark(c: &mut Criterion) {
    c.bench_function("network_refresh", |b| {
        let mut networks = Networks::new();
        b.iter(|| {
            networks.refresh(black_box(true));
        });
    });
}

fn network_refresh_with_list_benchmark(c: &mut Criterion) {
    c.bench_function("network_refresh_with_list", |b| {
        let mut networks = Networks::new();
        networks.refresh(true);
        b.iter(|| {
            networks.refresh(black_box(false));
            let _ = networks.iter().count();
        });
    });
}

criterion_group!(benches, network_refresh_benchmark, network_refresh_with_list_benchmark);
criterion_main!(benches);
```

#### Step 2: Baseline (Before Optimization)

```bash
# Switch to main branch
git checkout main

# Run benchmark and save baseline
cargo bench --bench network_refresh -- --save-baseline before
```

#### Step 3: Compare (After Optimization)

```bash
# Switch to feature branch
git checkout feature/test_changes

# Run and compare to baseline  
cargo bench --bench network_refresh -- --baseline before
```

**Expected Output**:
```
network_refresh         time:   [42.5 µs 45.8 µs 49.2 µs]
                        change: [-52.1% -48.3% -44.7%] (improvement)
                        Performance has improved.

network_refresh_with_list
                        time:   [38.2 µs 41.5 µs 45.1 µs]
                        change: [-51.8% -47.9% -43.2%] (improvement)
```

**Interpretation**:
- **40-50% improvement** ✅ Optimization successful  
- **<30% improvement** ⚠ Investigate (may need more iterations)
- **No improvement** ❌ Optimization not working

---

## Functional Testing

### Test 1: Interface Enumeration

```bash
cargo run --example simple 2>&1 | grep -A 5 "interface:"
```

**Expected**: All network interfaces listed with names

**Verify**:
- Physical interfaces (e.g., `bge0`, `wm0`)
- Virtual interfaces (e.g., `bridge0`, `vlan0`)
- Loopback excluded or shown separately

### Test 2: Statistics Accuracy

```rust
// Create test program: verify_stats.rs
use sysinfo::Networks;

fn main() {
    let mut networks = Networks::new();
    networks.refresh(true);
    
    for (name, data) in networks.iter() {
        println!("{}: rx={} bytes, tx={} bytes",
            name,
            data.received(),
            data.transmitted()
        );
        
        assert!(data.received() >= 0, "RX must be non-negative");
        assert!(data.transmitted() >= 0, "TX must be non-negative");
    }
    
    println!("✅ Statistics validation passed");
}
```

```bash
rustc --edition 2021 verify_stats.rs -L target/release/deps
./verify_stats
```

**Expected**: Non-zero bytes for active interfaces, no panics

### Test 3: MAC Address Retrieval

```bash
cargo test --test network -- --test-threads=1 --nocapture test_mac_address
```

**Expected**: Valid MAC addresses for physical interfaces

**Manual Verification**:
```bash
# Compare with ifconfig output
ifconfig | grep -A 1 "^[a-z]" | grep "address:"
```

### Test 4: IP Address Population

```bash
cargo test --test network -- --test-threads=1 test_addresses
```

**Expected**: 
- IPv4 addresses match `ifconfig`
- IPv6 addresses match `ifconfig`
- Addresses correctly associated with interface names

---

## Regression Testing (Other Platforms)

### Linux Regression Check

```bash
# On Linux system
cargo build --release
cargo test --lib --test network

# Ensure no NetBSD-specific code affects Linux
grep -r "target_os.*netbsd" src/unix/linux/
```

**Expected**: Clean build, all tests pass, no NetBSD symbols

### FreeBSD Regression Check

```bash
# On FreeBSD system
cargo build --release
cargo test --lib --test network
```

**Expected**: Clean build, all tests pass (FreeBSD uses different code path)

---

## Memory Safety Verification

### Using Valgrind (if available)

```bash
# Build with debug symbols
cargo build --example simple

# Run with leak detection
valgrind --leak-check=full \
         --show-leak-kinds=all \
         --track-origins=yes \
         ./target/debug/examples/simple
```

**Expected**:
```
==12345== HEAP SUMMARY:
==12345==     in use at exit: 0 bytes in 0 blocks
==12345==   total heap usage: X allocs, X frees, Y bytes allocated
==12345== 
==12345== All heap blocks were freed -- no leaks are possible
```

✅ **PASS**: "All heap blocks were freed"  
❌ **FAIL**: Any "definitely lost" or "indirectly lost" blocks

### Using Rust Miri

```bash
# Install miri
rustup +nightly component add miri

# Run network tests under miri
cargo +nightly miri test --lib network
```

**Expected**: No undefined behavior detected

**Note**: Miri may not support all libc calls; focus on Rust-level safety.

---

## Test Matrix

| Test | Platform | Tool | Time | Priority |
|------|----------|------|------|----------|
| **Compilation** | All | cargo | 2 min | HIGH |
| **Unit Tests** | All | cargo test | 3 min | HIGH |
| **Integration Tests** | All | cargo test | 5 min | HIGH |
| **System Call Trace** | NetBSD | ktrace | 2 min | HIGH |
| **Performance Bench** | NetBSD | criterion | 10 min | MEDIUM |
| **Memory Leak Check** | NetBSD | valgrind | 5 min | MEDIUM |
| **Linux Regression** | Linux | cargo test | 3 min | MEDIUM |
| **FreeBSD Regression** | FreeBSD | cargo test | 3 min | LOW |

**Total Testing Time**: ~30 minutes (comprehensive)  
**Minimal Verification**: ~10 minutes (compile + tests + ktrace)

---

## Troubleshooting

### Issue: ktrace shows 2 getifaddrs calls

**Symptom**: `kdump | grep -c getifaddrs` outputs `2`

**Diagnosis**:
1. Verify you're testing the feature branch:
   ```bash
   git branch --show-current  # Should show: feature/test_changes
   ```

2. Check build is using new code:
   ```bash
   cargo clean
   cargo build --release --example simple
   ```

3. Inspect network.rs implementation:
   ```bash
   grep -A 5 "fn refresh" src/unix/bsd/netbsd/network.rs
   ```

**Expected**: Should see `InterfaceAddress::new()` called once in `refresh()`

---

### Issue: Performance not improved

**Symptom**: Benchmark shows <30% improvement

**Diagnosis**:

1. **Check baseline was saved**:
   ```bash
   ls -la target/criterion/network_refresh/before/
   ```

2. **Run on quiet system**:
   - Close other applications
   - Disable unnecessary services
   - Run multiple times and average

3. **Verify optimization enabled**:
   ```bash
   cargo bench --release  # Ensure --release flag
   ```

4. **Check system specs**:
   - Fast syscalls may show less dramatic improvement
   - Run on system with 10+ network interfaces for better measurement

---

### Issue: Tests failing after changes

**Symptom**: `cargo test` reports failures

**Diagnosis**:

1. **Identify failing test**:
   ```bash
   cargo test -- --nocapture 2>&1 | grep -A 10 "FAILED"
   ```

2. **Run single test**:
   ```bash
   cargo test --test network test_<failing_test> -- --exact --nocapture
   ```

3. **Compare with main branch**:
   ```bash
   git stash
   cargo test--test network test_<failing_test>
   git stash pop
   ```

4. **Check for NetBSD-specific issues**:
   - AF_LINK filtering logic
   - Interface name parsing
   - Statistics extraction from `if_data`

---

## Acceptance Checklist

Before merging, verify all items:

### Functional
- [ ] All 83 tests pass on NetBSD
- [ ] Network interfaces correctly enumerated
- [ ] MAC addresses correct (compare with `ifconfig`)
- [ ] IPv4/IPv6 addresses correct
- [ ] Statistics (rx/tx bytes, packets, errors) accurate
- [ ] Loopback filtering works
- [ ] Hot-plug interfaces detected (if testing available)

### Performance
- [ ] ktrace shows exactly 1 `getifaddrs` call
- [ ] Benchmark shows ≥40% improvement
- [ ] No memory leaks (valgrind clean)
- [ ] No performance regression on other platforms

### Code Quality
- [ ] Compiles without warnings (`cargo build --release`)
- [ ] No new clippy lints (`cargo clippy`)
- [ ] FIXME comment removed (network.rs lines 45-46)
- [ ] Code documented with implementation notes

### Regression
- [ ] Linux builds and tests pass
- [ ] FreeBSD builds and tests pass
- [ ] Public API unchanged (no semver breaks)

---

## Quick Reference Commands

```bash
# Full test suite
cargo test --all

# NetBSD-specific test
cargo test --test network

# System call trace
ktrace -t c ./target/release/examples/simple && kdump | grep getifaddrs

# Performance benchmark
cargo bench --bench network_refresh

# Memory check
valgrind --leak-check=full ./target/debug/examples/simple

# Build for release
cargo build --release

# Check code quality
cargo clippy -- -D warnings
```

---

## Getting Help

**Documentation**:
- [spec.md](spec.md) - Feature requirements
- [plan.md](plan.md) - Implementation design  
- [research.md](research.md) - Technical findings

**Issue Tracking**:
- GitHub Issue #1598

**Related Files**:
- `src/unix/bsd/netbsd/network.rs` - Implementation
- `src/unix/network_helper.rs` - InterfaceAddress helper
- `benches/network_refresh.rs` - Performance tests

---

**Status**: Ready for Testing ✅  
**Est. Testing Time**: 30 minutes (full), 10 minutes (core)
