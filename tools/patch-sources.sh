#!/bin/sh
# ============================================================================
# Patch Automerge Sources for R Package Build
# ============================================================================
#
# This script applies necessary patches to the vendored automerge sources to
# ensure compatibility with CRAN requirements and cross-platform builds.
#
# Usage: ./tools/patch-sources.sh
#
# Run this script after updating automerge sources and before vendor-deps.sh.
#
# Patches Applied:
#   1. Remove rust-toolchain.toml (if present) to use system Rust
#   2. CMakeLists.txt: Remove nightly Rust requirement (use stable toolchain)
#   3. CMakeLists.txt: Fix WIN32 check to WIN32 AND MSVC for lib tool
#   4. CMakeLists.txt: Use CMake script for ar merge (GNU/BSD compatibility)
#   5. Add ar-merge-objects.cmake helper for cross-platform static lib merging
#   6. Ensure all source files end with newline (POSIX compliance)
#
# ============================================================================

set -e

RUST_DIR="src/automerge/rust"
AUTOMERGE_C_DIR="$RUST_DIR/automerge-c"
CMAKE_FILE="$AUTOMERGE_C_DIR/CMakeLists.txt"

if [ ! -d "$RUST_DIR" ]; then
    echo "Error: Must run from package root directory"
    exit 1
fi

if [ ! -f "$CMAKE_FILE" ]; then
    echo "Error: CMakeLists.txt not found at $CMAKE_FILE"
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

echo "Patching automerge sources..."

# ----------------------------------------------------------------------------
# Patch 1: Remove rust-toolchain.toml (forces specific Rust version)
# ----------------------------------------------------------------------------
TOOLCHAIN_FILE="$AUTOMERGE_C_DIR/rust-toolchain.toml"
if [ -f "$TOOLCHAIN_FILE" ]; then
    echo "  Removing rust-toolchain.toml..."
    rm -f "$TOOLCHAIN_FILE"
fi

# Also check workspace root
TOOLCHAIN_FILE_ROOT="$RUST_DIR/rust-toolchain.toml"
if [ -f "$TOOLCHAIN_FILE_ROOT" ]; then
    echo "  Removing rust-toolchain.toml from workspace root..."
    rm -f "$TOOLCHAIN_FILE_ROOT"
fi

# ----------------------------------------------------------------------------
# Patch 2: CMakeLists.txt - Remove nightly toolchain and build-std requirements
# ----------------------------------------------------------------------------
echo "  Patching CMakeLists.txt: removing nightly Rust requirement..."

# Check if patch is needed (look for nightly toolchain setting)
if grep -q "RUSTUP_TOOLCHAIN nightly" "$CMAKE_FILE" 2>/dev/null; then
    # Remove the nightly toolchain conditional block
    # Original:
    #     if (NOT RUSTC_VERSION MATCHES "nightly")
    #         set(RUSTUP_TOOLCHAIN nightly)
    #     endif()
    sedi '/if (NOT RUSTC_VERSION MATCHES "nightly")/,/endif()/d' "$CMAKE_FILE"
fi

if grep -q 'RUSTFLAGS.*panic=abort' "$CMAKE_FILE" 2>/dev/null; then
    # Remove panic=abort RUSTFLAGS line
    sedi '/set(RUSTFLAGS.*panic=abort/d' "$CMAKE_FILE"
fi

if grep -q "set(CARGO_FLAGS -Z build-std" "$CMAKE_FILE" 2>/dev/null; then
    # Replace build-std flags with simple --release
    sedi 's/set(CARGO_FLAGS -Z build-std=std,panic_abort --release \${CARGO_FLAGS})/set(CARGO_FLAGS --release ${CARGO_FLAGS})/' "$CMAKE_FILE"
    echo "    Applied nightly removal patch"
else
    echo "    (already patched or pattern not found)"
fi

# Clean up empty lines left by removals (collapse multiple blank lines)
sedi '/^$/N;/^\n$/d' "$CMAKE_FILE"

# ----------------------------------------------------------------------------
# Patch 3: CMakeLists.txt - Change if(WIN32) to if(WIN32 AND MSVC) for lib tool
# ----------------------------------------------------------------------------
echo "  Patching CMakeLists.txt: WIN32 -> WIN32 AND MSVC for lib tool..."

# Only patch the specific if(WIN32) that precedes find_program(LIB_TOOL
# NOT the if(WIN32) for library dependencies (Bcrypt, etc.)
if grep -A1 'if(WIN32)$' "$CMAKE_FILE" 2>/dev/null | grep -q 'find_program(LIB_TOOL'; then
    # Use awk for context-aware replacement
    awk '
    /if\(WIN32\)$/ {
        getline nextline
        if (nextline ~ /find_program\(LIB_TOOL/) {
            print "    if(WIN32 AND MSVC)"
            print nextline
            next
        } else {
            print
            print nextline
            next
        }
    }
    { print }
    ' "$CMAKE_FILE" > "${CMAKE_FILE}.tmp"
    mv "${CMAKE_FILE}.tmp" "$CMAKE_FILE"
    echo "    Applied WIN32 AND MSVC patch"
else
    echo "    (already patched or pattern not found)"
fi

# ----------------------------------------------------------------------------
# Patch 4: CMakeLists.txt - Use CMake script for ar merge
# ----------------------------------------------------------------------------
echo "  Patching CMakeLists.txt: using CMake script for ar merge..."

# Only replace the actual command, not the echo statement
# Pattern: line starts with whitespace, then ${CMAKE_AR} -rs (not echo)
if grep -q '^[[:space:]]*\${CMAKE_AR} -rs' "$CMAKE_FILE" 2>/dev/null; then
    # Replace direct ar command with CMake script invocation
    sedi 's|^\([[:space:]]*\)\${CMAKE_AR} -rs \$<TARGET_FILE_NAME:\${LIBRARY_NAME}> \${BINDINGS_OBJECTS_DIR}/\*\.o|\1${CMAKE_COMMAND} -DCMAKE_AR="${CMAKE_AR}" -DLIBRARY_NAME="$<TARGET_FILE_NAME:${LIBRARY_NAME}>" -DBINDINGS_OBJECTS_DIR="${BINDINGS_OBJECTS_DIR}" -DPROJECT_BINARY_DIR="${PROJECT_BINARY_DIR}" -P "${PROJECT_SOURCE_DIR}/cmake/ar-merge-objects.cmake"|' "$CMAKE_FILE"
    echo "    Applied ar-merge-objects.cmake patch"
else
    echo "    (already patched or pattern not found)"
fi

# ----------------------------------------------------------------------------
# Patch 5: Add ar-merge-objects.cmake helper script
# ----------------------------------------------------------------------------
AR_MERGE_SCRIPT="$AUTOMERGE_C_DIR/cmake/ar-merge-objects.cmake"
echo "  Creating ar-merge-objects.cmake..."

cat > "$AR_MERGE_SCRIPT" << 'EOF'
# CMake script to merge object files into an archive
# This script handles both GNU ar (with MRI script support) and BSD ar

file(GLOB OBJECT_FILES "${BINDINGS_OBJECTS_DIR}/*.o")
if(NOT OBJECT_FILES)
    message(FATAL_ERROR "No object files found in ${BINDINGS_OBJECTS_DIR}")
endif()

# Test if ar supports MRI mode (GNU ar)
execute_process(
    COMMAND ${CMAKE_AR} -M
    INPUT_FILE /dev/null
    RESULT_VARIABLE AR_MRI_TEST
    ERROR_QUIET
    OUTPUT_QUIET
)

if(AR_MRI_TEST EQUAL 0)
    # GNU ar with MRI support
    set(MRI_SCRIPT "${PROJECT_BINARY_DIR}/ar-merge.mri")
    file(WRITE ${MRI_SCRIPT} "CREATE ${LIBRARY_NAME}\n")
    foreach(OBJ_FILE ${OBJECT_FILES})
        file(APPEND ${MRI_SCRIPT} "ADDMOD ${OBJ_FILE}\n")
    endforeach()
    file(APPEND ${MRI_SCRIPT} "SAVE\nEND\n")

    execute_process(
        COMMAND ${CMAKE_AR} -M
        INPUT_FILE ${MRI_SCRIPT}
        WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
        RESULT_VARIABLE AR_RESULT
        ERROR_VARIABLE AR_ERROR
        OUTPUT_VARIABLE AR_OUTPUT
    )

    file(REMOVE ${MRI_SCRIPT})
else()
    # BSD ar (macOS) - use traditional commands
    execute_process(
        COMMAND ${CMAKE_AR} -r -s ${LIBRARY_NAME} ${OBJECT_FILES}
        WORKING_DIRECTORY ${PROJECT_BINARY_DIR}
        RESULT_VARIABLE AR_RESULT
        ERROR_VARIABLE AR_ERROR
        OUTPUT_VARIABLE AR_OUTPUT
    )
endif()

if(NOT AR_RESULT EQUAL 0)
    message(FATAL_ERROR "ar command failed with code ${AR_RESULT}\nError: ${AR_ERROR}\nOutput: ${AR_OUTPUT}")
endif()
EOF

# ----------------------------------------------------------------------------
# Patch 6: Ensure all source files end with a newline (POSIX compliance)
# ----------------------------------------------------------------------------
echo "  Ensuring source files end with newline..."

FIXED_COUNT=0
for file in $(find "$RUST_DIR" -type f \( -name "*.rs" -o -name "*.c" -o -name "*.h" -o -name "*.toml" -o -name "*.cmake" \) 2>/dev/null); do
    # Check if file exists and is not empty
    if [ -s "$file" ]; then
        # Check if file ends with newline (tail -c1 returns empty if last char is newline)
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
