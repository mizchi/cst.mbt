// Microbenchmarks for the green builder hot path.
//
// `GreenNodeBuilder::token` adds a token in a parent frame. `current_offset`
// computes the running text length of the frame's children — historically by
// walking every child from `first_child_idx` to the current position, which
// makes the overall build O(N^2) on flat parent frames (e.g. a module body
// holding hundreds of top-level declarations). These benches isolate the
// `token` path on a single deep parent frame with N tokens so the per-token
// cost shows up directly and regressions on this loop are easy to spot.

///|
fn bench_flat_token_kind() -> SyntaxKind {
  SyntaxKind::new(101)
}

///|
fn bench_flat_parent_kind() -> SyntaxKind {
  SyntaxKind::new(102)
}

///|
fn run_flat_build(n : Int) -> Int {
  let builder = GreenNodeBuilder::new()
  builder.start_node(bench_flat_parent_kind())
  for i = 0; i < n; i = i + 1 {
    builder.token(bench_flat_token_kind(), "x")
  }
  builder.finish_node()
  let root = builder.finish()
  root.text_len().to_int()
}

///|
test "bench builder/flat-100" (b : @bench.T) {
  b.bench(name="builder/flat-100", fn() { b.keep(run_flat_build(100)) })
}

///|
test "bench builder/flat-500" (b : @bench.T) {
  b.bench(name="builder/flat-500", fn() { b.keep(run_flat_build(500)) })
}

///|
test "bench builder/flat-1000" (b : @bench.T) {
  b.bench(name="builder/flat-1000", fn() { b.keep(run_flat_build(1000)) })
}

///|
test "bench builder/flat-4000" (b : @bench.T) {
  b.bench(name="builder/flat-4000", fn() { b.keep(run_flat_build(4000)) })
}

///|
fn run_nested_build(depth : Int, tokens_per_node : Int) -> Int {
  let builder = GreenNodeBuilder::new()
  for i = 0; i < depth; i = i + 1 {
    builder.start_node(bench_flat_parent_kind())
    for j = 0; j < tokens_per_node; j = j + 1 {
      builder.token(bench_flat_token_kind(), "x")
    }
  }
  for i = 0; i < depth; i = i + 1 {
    builder.finish_node()
  }
  let root = builder.finish()
  root.text_len().to_int()
}

///|
test "bench builder/nested-100x10" (b : @bench.T) {
  b.bench(name="builder/nested-100x10", fn() { b.keep(run_nested_build(100, 10)) })
}
