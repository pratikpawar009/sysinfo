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
