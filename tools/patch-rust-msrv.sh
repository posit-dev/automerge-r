#!/bin/sh
# ============================================================================
# MSRV Patch Script for Automerge Rust Dependencies
# ============================================================================
#
# This script reduces the Minimum Supported Rust Version (MSRV) from 1.89 to
# 1.80 by downgrading dependencies and replacing unstable std library features.
#
# IMPORTANT: These patches have already been applied to the source files and
# vendored dependencies in this package. This script is kept for reference
# and for use when updating the bundled Automerge Rust source.
#
# When updating automerge (src/automerge/rust/):
#   1. Update the Rust source from upstream
#   2. Run this script: ./tools/patch-rust-msrv.sh src/automerge/rust
#   3. Run vendor script: ./tools/vendor-deps.sh
#
# Dependency changes:
#   smol_str:   0.3 -> 0.2   (MSRV 1.89 -> 1.56)
#   sha2:       0.11-pre -> 0.10 (MSRV 1.85 -> 1.72)
#   getrandom:  0.3 -> 0.2   (MSRV 1.85 -> 1.60)
#   rand:       0.9 -> 0.8   (MSRV 1.85 -> 1.56)
#   cbindgen:   0.29 -> 0.26 (transitive dep indexmap requires 1.82)
#
# Source code changes (unstable std library features):
#   - iter::repeat_n -> iter::repeat().take()
#   - is_sorted() -> windows(2).all()
#   - rand 0.9 API -> rand 0.8 API
#   - getrandom 0.3 API -> getrandom 0.2 API
#
# ============================================================================

set -e

RUST_DIR="$1"

if [ -z "$RUST_DIR" ]; then
    echo "Usage: $0 <path-to-rust-dir>"
    exit 1
fi

if [ ! -d "$RUST_DIR" ]; then
    echo "Error: Directory not found: $RUST_DIR"
    exit 1
fi

# Portable sed -i (works on both macOS and Linux)
sedi() {
    if [ "$(uname)" = "Darwin" ]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# Patch automerge/Cargo.toml
CARGO_AUTOMERGE="$RUST_DIR/automerge/Cargo.toml"
if [ -f "$CARGO_AUTOMERGE" ]; then
    sedi 's/rust-version = "1.89.0"/rust-version = "1.80.0"/' "$CARGO_AUTOMERGE"
    sedi 's/sha2 = "0.11.0-pre.5"/sha2 = "0.10.8"/' "$CARGO_AUTOMERGE"
    sedi 's/smol_str = { version = "0.3"/smol_str = { version = "0.2"/' "$CARGO_AUTOMERGE"
    sedi 's/getrandom = "0.3"/getrandom = "0.2"/' "$CARGO_AUTOMERGE"
    sedi 's/rand = { version = "\^0.9"/rand = { version = "^0.8"/' "$CARGO_AUTOMERGE"
    # getrandom 0.2 uses "js" feature instead of "wasm_js"
    sedi 's/getrandom\/wasm_js/getrandom\/js/' "$CARGO_AUTOMERGE"
fi

# Patch automerge-c/Cargo.toml
CARGO_AUTOMERGE_C="$RUST_DIR/automerge-c/Cargo.toml"
if [ -f "$CARGO_AUTOMERGE_C" ]; then
    sedi 's/smol_str = "0.3"/smol_str = "0.2"/' "$CARGO_AUTOMERGE_C"
    sedi 's/cbindgen = "\^0.29"/cbindgen = "^0.26"/' "$CARGO_AUTOMERGE_C"
fi

# Patch automerge-c/cmake/Cargo.toml.in (CMake template)
CARGO_CMAKE="$RUST_DIR/automerge-c/cmake/Cargo.toml.in"
if [ -f "$CARGO_CMAKE" ]; then
    sedi 's/smol_str = "0.3"/smol_str = "0.2"/' "$CARGO_CMAKE"
    sedi 's/cbindgen = "\^0.29"/cbindgen = "^0.26"/' "$CARGO_CMAKE"
fi

# Patch hexane/Cargo.toml
CARGO_HEXANE="$RUST_DIR/hexane/Cargo.toml"
if [ -f "$CARGO_HEXANE" ]; then
    sedi 's/rand = { version = "\^0.9"/rand = { version = "^0.8"/' "$CARGO_HEXANE"
fi

# Patch automerge/src/types.rs
TYPES_RS="$RUST_DIR/automerge/src/types.rs"
if [ -f "$TYPES_RS" ]; then
    sedi 's/distr::{Distribution, StandardUniform}/distributions::{Distribution, Standard}/' "$TYPES_RS"
    sedi 's/impl Distribution<ActorId> for StandardUniform/impl Distribution<ActorId> for Standard/' "$TYPES_RS"
    sedi 's/getrandom::fill/getrandom::getrandom/' "$TYPES_RS"
fi

# Patch automerge/src/op_set2/skip_list.rs
SKIP_LIST_RS="$RUST_DIR/automerge/src/op_set2/skip_list.rs"
if [ -f "$SKIP_LIST_RS" ]; then
    sedi 's/rand::rng()/rand::thread_rng()/' "$SKIP_LIST_RS"
fi

# Patch automerge/src/op_set2/op_set.rs
OP_SET_RS="$RUST_DIR/automerge/src/op_set2/op_set.rs"
if [ -f "$OP_SET_RS" ]; then
    sedi 's/rand::distr::Alphanumeric/rand::distributions::Alphanumeric/' "$OP_SET_RS"
    sedi 's/rand::rng()/rand::thread_rng()/' "$OP_SET_RS"
fi

# Patch automerge/src/change_graph.rs (unstable iter::repeat_n)
CHANGE_GRAPH_RS="$RUST_DIR/automerge/src/change_graph.rs"
if [ -f "$CHANGE_GRAPH_RS" ]; then
    sedi 's/std::iter::repeat_n(None, iter.len())/std::iter::repeat(None).take(iter.len())/' "$CHANGE_GRAPH_RS"
fi

# Patch automerge/src/op_set2/change/collector.rs (unstable iter::repeat_n)
COLLECTOR_RS="$RUST_DIR/automerge/src/op_set2/change/collector.rs"
if [ -f "$COLLECTOR_RS" ]; then
    sedi 's/std::iter::repeat_n(None, num_ops)/std::iter::repeat(None).take(num_ops)/' "$COLLECTOR_RS"
fi

# Patch automerge/src/storage/columns/raw_column.rs (unstable is_sorted)
RAW_COLUMN_RS="$RUST_DIR/automerge/src/storage/columns/raw_column.rs"
if [ -f "$RAW_COLUMN_RS" ]; then
    sedi 's/debug_assert!(self.0.iter().map(|i| i.spec()).is_sorted());/debug_assert!(self.0.windows(2).all(|w| w[0].spec() <= w[1].spec()));/' "$RAW_COLUMN_RS"
fi

# Remove Cargo.lock to allow fresh dependency resolution
if [ -f "$RUST_DIR/Cargo.lock" ]; then
    rm -f "$RUST_DIR/Cargo.lock"
fi

echo "MSRV patch applied successfully (target: Rust 1.80)"
