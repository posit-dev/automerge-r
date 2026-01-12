# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an R package (`automerge`) that provides bindings to the Automerge Conflict-free Replicated Data Type (CRDT) library via its C FFI. The package enables automatic merging of concurrent changes across distributed systems without conflicts.

**Key Architecture:**
- R package with C bindings to Rust-based automerge-c library
- R layer provides idiomatic S3 methods (`$`, `[[`, `length`, `names`, `as.list`)
- C layer wraps automerge-c API with memory-safe external pointer management
- Zero R package dependencies (only base R)

## Build Commands

```bash
# Install package (triggers configure + build)
R CMD INSTALL .

# Build package tarball
R CMD build .

# Check package
R CMD check automerge_*.tar.gz

# Clean build artifacts
./cleanup
```

## Development Workflow

```r
# Load package for development
devtools::load_all()

# Run all tests
devtools::test()

# Run a single test file
testthat::test_file("tests/testthat/test-document.R")

# Build documentation
devtools::document()
```

## Build System

The package uses a two-phase build approach:

1. **System Library Detection**: Tries to find system-installed `automerge-c`
   - Searches standard prefixes and pkg-config
   - Verifies UTF-32 character indexing compatibility
   - Set `AUTOMERGE_LIBS=1` to force bundled build

2. **Bundled Build**: If system library not found, builds from `src/automerge/rust/automerge-c/`
   - Uses CMake with `-DUTF32_INDEXING=ON`
   - Requires Rust >= 1.89.0 and CMake >= 3.25

## Code Structure

### R Layer (`R/`)
- `document.R`: Document lifecycle (create, save, load, fork, merge, commit)
- `objects.R`: Object operations (put, get, delete, insert) and type constructors
- `methods.R`: S3 methods for `am_doc`, `am_object`, and subtypes
- `sync.R`: Synchronization (am_sync, am_sync_encode/decode, change tracking)
- `cursors.R`: Cursor and mark operations for text
- `constants.R`: Exported constants (`AM_ROOT`, `AM_OBJ_TYPE_*`, `AM_MARK_EXPAND_*`)

### C Layer (`src/`)
- `automerge.h`: Data structures, function declarations, CHECK_RESULT macro
- `document.c`: Document operations
- `objects.c`: Map/list/text operations
- `sync.c`: Sync protocol implementation
- `cursors.c`: Cursor and mark operations
- `memory.c`: External pointer wrappers and finalizers
- `errors.c`: Error handling with file/line context
- `init.c`: R package registration

## Code Style

- Comments should be sparse and address the "why", not the "what"

## Important Notes

### Indexing Conventions

**1-based indexing (element indices):**
- List operations: `am_get()`, `am_put()`, `am_delete()`, `am_insert()`
- Counter operations in lists

**0-based indexing (inter-character positions):**
- Text operations: `am_text_splice()`
- Cursor operations: `am_cursor()`, `am_cursor_position()`
- Mark operations: `am_mark_create()`, `am_marks()`
- Positions specify locations **between** characters (0 = before first character)

### UTF-32 Character Indexing

Text positions use Unicode code points, not bytes. The emoji "😀" counts as 1 character at position 5 in "Hello😀", matching R's `nchar()` behavior. JavaScript uses UTF-16, so positions may differ for some Unicode characters.

### Memory Management

- `am_doc` and `am_syncstate` structs wrap AMresult* (owns memory) and borrowed pointers
- External pointers use finalizers to prevent memory leaks
- `get_doc_from_objid()` extracts parent document from nested object protection chain
