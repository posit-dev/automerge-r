#!/bin/sh
# ============================================================================
# Patch Automerge Sources for R Package Build
# ============================================================================
#
# This script converts the upstream automerge-c sources, which build with
# CMake, into a CMake-free layout that the package's configure script builds
# with Cargo directly. CMake's only essential jobs for this package were
# (1) substituting the Cargo.toml / cbindgen.toml templates and (2) running
# Cargo + cbindgen; the configure script now does (2) (plus the two header
# fix-ups CMake applied), so here we do (1) and remove the CMake machinery.
#
# Usage: ./tools/patch-sources.sh
#
# Run this FIRST when updating the bundled automerge sources, then:
#   1. ./tools/patch-rust-msrv.sh src/automerge/rust   (downgrade MSRV deps)
#   2. ./tools/vendor-deps.sh                          (refresh vendor.tar.xz)
#
# Changes applied to src/automerge/rust/automerge-c:
#   1. Remove rust-toolchain.toml (forces a specific Rust version)
#   2. Generate Cargo.toml    from cmake/Cargo.toml.in   (CMake configure_file)
#   3. Generate cbindgen.toml from cmake/cbindgen.toml.in (CMake configure_file)
#   4. Remove CMakeLists.txt and the cmake/ helper directory
#   5. Ensure all source files end with a newline (POSIX compliance)
#
# The substitutions in steps 2-3 mirror the defaults in upstream's
# CMakeLists.txt: PROJECT_NAME=automerge-c, BINDINGS_NAME=automerge_core,
# LIBRARY_NAME=automerge, and INCLUDE_GUARD_PREFIX=AUTOMERGE_C. PROJECT_VERSION
# is read from the project() declaration so it tracks upstream bumps.
#
# ============================================================================

set -e

RUST_DIR="src/automerge/rust"
AUTOMERGE_C_DIR="$RUST_DIR/automerge-c"
CMAKE_DIR="$AUTOMERGE_C_DIR/cmake"
CMAKE_FILE="$AUTOMERGE_C_DIR/CMakeLists.txt"

if [ ! -d "$RUST_DIR" ]; then
    echo "Error: Must run from package root directory"
    exit 1
fi

echo "Patching automerge sources (CMake-free layout)..."

# ----------------------------------------------------------------------------
# Patch 1: Remove rust-toolchain.toml (forces a specific Rust version)
# ----------------------------------------------------------------------------
for toolchain in "$AUTOMERGE_C_DIR/rust-toolchain.toml" "$RUST_DIR/rust-toolchain.toml"; do
    if [ -f "$toolchain" ]; then
        echo "  Removing $toolchain..."
        rm -f "$toolchain"
    fi
done

# ----------------------------------------------------------------------------
# Patches 2-4: Replace CMake's configure_file + build orchestration
# ----------------------------------------------------------------------------
if [ -f "$CMAKE_DIR/Cargo.toml.in" ]; then
    # Read the version from the project() declaration before removing CMakeLists.
    PROJECT_VERSION=$(sed -n 's/^[[:space:]]*project(automerge-c VERSION \([0-9.]*\).*/\1/p' "$CMAKE_FILE" | head -1)
    if [ -z "$PROJECT_VERSION" ]; then
        echo "Error: could not read PROJECT_VERSION from $CMAKE_FILE"
        exit 1
    fi
    echo "  Generating Cargo.toml from cmake/Cargo.toml.in (version $PROJECT_VERSION)..."
    sed -e 's/${PROJECT_NAME}/automerge-c/g' \
        -e "s/\${PROJECT_VERSION}/${PROJECT_VERSION}/g" \
        -e 's/${BINDINGS_NAME}/automerge_core/g' \
        -e 's/${LIBRARY_NAME}/automerge/g' \
        "$CMAKE_DIR/Cargo.toml.in" > "$AUTOMERGE_C_DIR/Cargo.toml"

    echo "  Generating cbindgen.toml from cmake/cbindgen.toml.in..."
    sed 's/@INCLUDE_GUARD_PREFIX@/AUTOMERGE_C/g' \
        "$CMAKE_DIR/cbindgen.toml.in" > "$AUTOMERGE_C_DIR/cbindgen.toml"

    echo "  Removing CMakeLists.txt and cmake/ ..."
    rm -f "$CMAKE_FILE"
    rm -rf "$CMAKE_DIR"
else
    echo "  CMake templates absent; sources already converted (skipping 2-4)."
fi

# ----------------------------------------------------------------------------
# Patch 5: Ensure all source files end with a newline (POSIX compliance)
# ----------------------------------------------------------------------------
echo "  Ensuring source files end with newline..."

FIXED_COUNT=0
for file in $(find "$RUST_DIR" -type f \( -name "*.rs" -o -name "*.c" -o -name "*.h" -o -name "*.toml" \) 2>/dev/null); do
    if [ -s "$file" ]; then
        if [ -n "$(tail -c1 "$file")" ]; then
            echo "" >> "$file"
            FIXED_COUNT=$((FIXED_COUNT + 1))
        fi
    fi
done

if [ "$FIXED_COUNT" -gt 0 ]; then
    echo "    Added missing newlines to $FIXED_COUNT file(s)"
else
    echo "    All files already end with newline"
fi

echo "Done!"
echo ""
echo "Next steps:"
echo "  1. Run ./tools/patch-rust-msrv.sh src/automerge/rust (if MSRV patches needed)"
echo "  2. Run ./tools/vendor-deps.sh (to update vendor.tar.xz)"
