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

# Vendor dependencies
echo "Vendoring Rust dependencies..."
cd "$RUST_DIR"
cargo vendor vendor
cd - > /dev/null

echo "Pruning unnecessary files..."

# Remove test directories
find "$VENDOR_DIR" -type d -name "tests" -exec rm -rf {} + 2>/dev/null || true

# Remove example directories
find "$VENDOR_DIR" -type d -name "examples" -exec rm -rf {} + 2>/dev/null || true

# Remove benchmark directories
find "$VENDOR_DIR" -type d -name "benches" -exec rm -rf {} + 2>/dev/null || true

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

# Remove README files (keep LICENSE files)
find "$VENDOR_DIR" -type f -name "README*" -delete 2>/dev/null || true

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

# Create compressed archive
echo "Creating archive..."
tar -cJf "$ARCHIVE" -C "$RUST_DIR" vendor

# Remove vendor directory
rm -rf "$VENDOR_DIR"

# Report size
SIZE=$(du -h "$ARCHIVE" | cut -f1)
echo "Created $ARCHIVE ($SIZE)"
echo "Done!"
