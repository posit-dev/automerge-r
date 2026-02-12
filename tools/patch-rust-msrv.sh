#!/bin/sh
# ============================================================================
# MSRV Patch Script for Automerge Rust Dependencies
# ============================================================================
#
# This script reduces the Minimum Supported Rust Version (MSRV) from 1.89 to
# 1.85 by downgrading dependencies that require Rust 1.89+.
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
#   cbindgen:   add default-features = false (removes clap CLI dependency)
#   rand:       default-features = false (removes rand_chacha/ppv-lite86/zerocopy chain)
#   sha2:       default-features = false (removes const-oid)
#   dot:        remove unused optional dependency and optree-visualisation feature
#
# Note: tempfile is pinned to 3.3.0 in vendor-deps.sh to use winapi
# instead of windows-sys (smaller dependency footprint)
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
    sedi 's/smol_str = { version = "0.3"/smol_str = { version = "0.2"/' "$CARGO_AUTOMERGE"
    # Disable rand default features (only core traits needed; small_rng is test-only)
    sedi 's/rand = { version = "\^0.9", optional = false, features = \["small_rng"\] }/rand = { version = "^0.9", default-features = false }/' "$CARGO_AUTOMERGE"
    # Disable sha2 default features (no OID support needed)
    sedi 's/sha2 = "0.11.0-pre.5"/sha2 = { version = "0.11.0-pre.5", default-features = false }/' "$CARGO_AUTOMERGE"
    # Remove unused dot optional dependency and its feature
    sedi '/^dot = /d' "$CARGO_AUTOMERGE"
    sedi '/^optree-visualisation = /d' "$CARGO_AUTOMERGE"
fi

# Patch automerge-c/Cargo.toml
CARGO_AUTOMERGE_C="$RUST_DIR/automerge-c/Cargo.toml"
if [ -f "$CARGO_AUTOMERGE_C" ]; then
    sedi 's/smol_str = "0.3"/smol_str = "0.2"/' "$CARGO_AUTOMERGE_C"
    sedi 's/cbindgen = "\^0.29"/cbindgen = { version = "^0.29", default-features = false }/' "$CARGO_AUTOMERGE_C"
fi

# Patch automerge-c/cmake/Cargo.toml.in (CMake template)
CARGO_CMAKE="$RUST_DIR/automerge-c/cmake/Cargo.toml.in"
if [ -f "$CARGO_CMAKE" ]; then
    sedi 's/smol_str = "0.3"/smol_str = "0.2"/' "$CARGO_CMAKE"
    sedi 's/cbindgen = "\^0.29"/cbindgen = { version = "^0.29", default-features = false }/' "$CARGO_CMAKE"
fi

# Remove Cargo.lock to allow fresh dependency resolution
if [ -f "$RUST_DIR/Cargo.lock" ]; then
    rm -f "$RUST_DIR/Cargo.lock"
fi

echo "MSRV patch applied successfully (target: Rust 1.85)"
