#!/bin/sh
# ============================================================================
# Vendor Rust Dependencies for Automerge
# ============================================================================
#
# This script vendors Rust dependencies and removes unnecessary files to
# minimize the package size. It should be run from the package root directory.
#
# Usage: ./tools/vendor-deps.sh
#
# Prerequisites:
#   - Rust toolchain installed (cargo)
#   - Run tools/patch-rust-msrv.sh first if updating automerge source
#
# Size Optimization Strategy:
#   1. Temporarily removes [dev-dependencies] sections before vendoring
#   2. Pins tempfile to 3.3.0 (uses winapi instead of windows-sys for smaller footprint)
#   3. Removes unused WASM-related crates (web-sys, js-sys, wasm-bindgen, wit-bindgen)
#   4. Prunes test/example/benchmark directories and documentation
#
# ============================================================================

set -e

RUST_DIR="src/automerge/rust"
VENDOR_DIR="$RUST_DIR/vendor"
ARCHIVE="$RUST_DIR/vendor.tar.xz"

if [ ! -d "$RUST_DIR" ]; then
    echo "Error: Must run from package root directory"
    exit 1
fi

# Remove old vendor directory and archive
rm -rf "$VENDOR_DIR"
rm -f "$ARCHIVE"

# ----------------------------------------------------------------------------
# Step 1: Temporarily remove dev-dependencies and WASM deps to reduce vendor size
# ----------------------------------------------------------------------------
echo "Preparing Cargo.toml files (removing dev-dependencies and WASM deps)..."

# Files with dev-dependencies that need modification
CARGO_FILES="$RUST_DIR/automerge/Cargo.toml $RUST_DIR/hexane/Cargo.toml"

# Backup and strip dev-dependencies and WASM optional deps
for cargo_file in $CARGO_FILES; do
    if [ -f "$cargo_file" ]; then
        cp "$cargo_file" "${cargo_file}.bak"
        # Remove section contents (keep headers for idempotent patching)
        # Remove wasm feature line and js-sys, wasm-bindgen optional deps
        # Using awk for BSD/GNU portability
        awk '
            /^\[dev-dependencies\]/ { skip = 1; print; next }
            /^\[dependencies\.web-sys\]/ { skip = 1; print; next }
            /^\[/ { skip = 0 }
            skip { next }
            /^wasm = \[/ { next }
            /^js-sys = / { next }
            /^wasm-bindgen = / { next }
            { print }
        ' "$cargo_file" > "${cargo_file}.tmp"
        mv "${cargo_file}.tmp" "$cargo_file"
    fi
done

# Regenerate Cargo.lock without dev-dependencies
echo "Regenerating Cargo.lock..."
cd "$RUST_DIR"
cargo generate-lockfile
# Pin tempfile to 3.3.0 to use winapi instead of windows-sys (smaller dependency footprint)
cargo update -p tempfile --precise 3.3.0
cd - > /dev/null

# Vendor dependencies (now without dev-dependencies)
echo "Vendoring Rust dependencies..."
cd "$RUST_DIR"
cargo vendor vendor
cd - > /dev/null

# Remove backup files (keep stripped Cargo.toml files without dev-deps and WASM)
echo "Removing backup files..."
for cargo_file in $CARGO_FILES; do
    rm -f "${cargo_file}.bak"
done

# ----------------------------------------------------------------------------
# Step 2: Remove WASM-related crates (unused by C FFI, excluded from Cargo.lock)
# ----------------------------------------------------------------------------
echo "Removing WASM-related crates..."
WASM_CRATES="web-sys js-sys wasm-bindgen wasm-bindgen-backend wasm-bindgen-macro wasm-bindgen-macro-support wasm-bindgen-shared wit-bindgen wit-bindgen-rt wasip2"
for crate in $WASM_CRATES; do
    rm -rf "$VENDOR_DIR/$crate"
done

echo "Pruning unnecessary files..."

# Remove test, example, and benchmark directories
find "$VENDOR_DIR" -type d -name "tests" -exec rm -rf {} + 2>/dev/null || true
find "$VENDOR_DIR" -type d -name "examples" -exec rm -rf {} + 2>/dev/null || true
find "$VENDOR_DIR" -type d -name "benches" -exec rm -rf {} + 2>/dev/null || true

# Remove README files
find "$VENDOR_DIR" -type f -name "README*" -delete 2>/dev/null || true

# Restore empty placeholders for crates with build.rs or include_str! that require them
mkdir -p "$VENDOR_DIR/cbindgen/tests/rust" "$VENDOR_DIR/cbindgen/tests/depfile"
mkdir -p "$VENDOR_DIR/winnow/examples/css"
touch "$VENDOR_DIR/winnow/examples/css/parser.rs"
# getrandom requires README.md (may have version suffix like getrandom-0.2.17)
for dir in "$VENDOR_DIR"/getrandom*; do
    [ -d "$dir" ] && touch "$dir/README.md"
done

# Remove CI directories
find "$VENDOR_DIR" -type d -name ".github" -exec rm -rf {} + 2>/dev/null || true
find "$VENDOR_DIR" -type d -name "ci" -exec rm -rf {} + 2>/dev/null || true

# Remove script directories (dev tooling)
find "$VENDOR_DIR" -type d -name "scripts" -exec rm -rf {} + 2>/dev/null || true
find "$VENDOR_DIR" -type d -name "bin" -exec rm -rf {} + 2>/dev/null || true

# Remove documentation files (keep LICENSE files)
find "$VENDOR_DIR" -type f -name "CHANGELOG*" -delete 2>/dev/null || true
find "$VENDOR_DIR" -type f -name "HISTORY*" -delete 2>/dev/null || true
find "$VENDOR_DIR" -type f -name "NEWS*" -delete 2>/dev/null || true

# Remove shell scripts (development tooling)
find "$VENDOR_DIR" -type f -name "*.sh" -delete 2>/dev/null || true

# Remove CI configuration files
find "$VENDOR_DIR" -type f -name ".travis.yml" -delete 2>/dev/null || true
find "$VENDOR_DIR" -type f -name ".appveyor.yml" -delete 2>/dev/null || true
find "$VENDOR_DIR" -type f -name "azure-pipelines.yml" -delete 2>/dev/null || true
find "$VENDOR_DIR" -type f -name ".circleci" -delete 2>/dev/null || true

# Remove editor and tool config
find "$VENDOR_DIR" -type f -name ".editorconfig" -delete 2>/dev/null || true
find "$VENDOR_DIR" -type f -name ".gitattributes" -delete 2>/dev/null || true
find "$VENDOR_DIR" -type f -name "rustfmt.toml" -delete 2>/dev/null || true
find "$VENDOR_DIR" -type f -name ".rustfmt.toml" -delete 2>/dev/null || true
find "$VENDOR_DIR" -type f -name "clippy.toml" -delete 2>/dev/null || true
find "$VENDOR_DIR" -type f -name ".clippy.toml" -delete 2>/dev/null || true

# Clear file checksums (Cargo will skip file verification but keep package checksum)
echo "Updating checksum files..."
for checksum in "$VENDOR_DIR"/*/.cargo-checksum.json; do
    if [ -f "$checksum" ]; then
        # Extract package checksum and set files to empty
        pkg=$(sed -n 's/.*"package":"\([^"]*\)".*/\1/p' "$checksum")
        echo "{\"files\":{},\"package\":\"$pkg\"}" > "$checksum"
    fi
done

# ----------------------------------------------------------------------------
# Generate inst/AUTHORS from vendored crate metadata
# ----------------------------------------------------------------------------
echo "Generating inst/AUTHORS..."

AUTHORS_FILE="inst/AUTHORS"
mkdir -p inst

{
    echo "Authors of bundled Rust crates:"
    echo ""

    for cargo_toml in "$VENDOR_DIR"/*/Cargo.toml; do
        if [ -f "$cargo_toml" ]; then
            # Extract name
            name=$(sed -n 's/^name *= *"\([^"]*\)".*/\1/p' "$cargo_toml" | head -1)
            # Extract version
            version=$(sed -n 's/^version *= *"\([^"]*\)".*/\1/p' "$cargo_toml" | head -1)

            # Extract authors - handle both single-line and multi-line formats:
            #   authors = ["Name <email>"]
            #   authors = [
            #       "Name <email>",
            #   ]
            authors=$(awk '
                /^authors *= *\[/ {
                    # Start collecting authors
                    in_authors = 1
                    line = $0
                    # Check if single-line (contains closing bracket)
                    if (match(line, /\]/)) {
                        gsub(/.*\[/, "", line)
                        gsub(/\].*/, "", line)
                        print line
                        in_authors = 0
                        next
                    }
                    next
                }
                in_authors {
                    if (/\]/) {
                        in_authors = 0
                        next
                    }
                    # Print author lines (strip leading whitespace)
                    gsub(/^[[:space:]]+/, "")
                    print
                }
            ' "$cargo_toml" | \
                tr -d '\n' | \
                sed 's/"[[:space:]]*,[[:space:]]*/", /g' | \
                sed 's/"//g' | \
                sed 's/[[:space:]]*<[^>]*>//g' | \
                sed 's/^[[:space:]]*//' | \
                sed 's/[[:space:]]*$//' | \
                sed 's/,[[:space:]]*$//')

            if [ -n "$name" ] && [ -n "$authors" ] && [ "$authors" != "," ]; then
                echo " - $name $version: $authors"
            fi
        fi
    done | sort

    echo ""
    echo "(Generated from Cargo.toml files on $(date +%Y-%m-%d))"
} > "$AUTHORS_FILE"

CRATE_COUNT=$(grep -c "^ - " "$AUTHORS_FILE" || echo "0")
echo "  Written $AUTHORS_FILE with $CRATE_COUNT crate entries"

# ----------------------------------------------------------------------------
# Patch CMakeLists.txt to pass CARGO_HOME to cargo
# ----------------------------------------------------------------------------
echo "Patching CMakeLists.txt..."

CMAKELISTS="$RUST_DIR/automerge-c/CMakeLists.txt"

# Add CARGO_HOME to the cargo build command and limit parallel jobs to 2
# (CRAN policy compliance). Source replacement config is generated by
# configure scripts with absolute paths, since CARGO_SOURCE_* env vars
# don't work for source replacement settings.
sed -i.bak 's|\(${CMAKE_COMMAND} -E env\) \(CARGO_TARGET_DIR=\)|\1 CARGO_HOME=$ENV{CARGO_HOME} \2|; s|\(${CARGO_CMD} build\) \(${CARGO_FLAGS}\)|\1 -j2 \2|' "$CMAKELISTS"
rm -f "${CMAKELISTS}.bak"

# Create compressed archive
echo "Creating archive..."
tar -cJf "$ARCHIVE" -C "$RUST_DIR" vendor

# Remove vendor directory
rm -rf "$VENDOR_DIR"

# Report size
SIZE=$(du -h "$ARCHIVE" | cut -f1)
echo "Created $ARCHIVE ($SIZE)"
echo "Done!"
