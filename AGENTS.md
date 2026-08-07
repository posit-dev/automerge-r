# AGENTS.md

Guidance for AI coding agents working **on** the automerge package. automerge provides R bindings to the Automerge Conflict-free Replicated Data Type (CRDT) library via its C FFI, enabling automatic merging of concurrent changes across distributed systems without conflicts. Zero R package dependencies (only base R).

Claude Code users: add `.claude/CLAUDE.md` containing `@../AGENTS.md` to import this file (`.claude/` is gitignored).

## Architecture

- R package with C bindings to the Rust-based automerge-c library
- R layer provides idiomatic S3 methods (`$`, `[[`, `length`, `names`, `as.list`)
- C layer wraps the automerge-c API with memory-safe external pointer management

## Commands

```r
devtools::load_all()                                    # load package for development
devtools::test()                                        # run all tests
testthat::test_file("tests/testthat/test-document.R")   # run a single test file
devtools::document()                                    # roxygen2 -> man/, NAMESPACE
```

```bash
R CMD INSTALL .          # install package (triggers configure + build)
R CMD build .
R CMD check automerge_*.tar.gz
./cleanup                # clean build artifacts
```

## Build System

The package uses a two-phase build approach:

1. **System Library Detection**: Tries to find system-installed `automerge-c`
   - Searches standard prefixes and pkg-config
   - Verifies UTF-32 character indexing compatibility
   - Set `AUTOMERGE_LIBS=1` to force bundled build

2. **Bundled Build**: If system library not found, builds from `src/automerge/rust/automerge-c/`
   - Uses CMake with `-DUTF32_INDEXING=ON`
   - Requires Rust >= 1.85.0 and CMake >= 3.25

## Codebase Shape

### R Layer (`R/`)

- `document.R`: Document lifecycle (create, save, load, fork, merge, commit, rollback, clone)
- `objects.R`: Object operations (put, get, delete, insert) and type constructors
- `methods.R`: S3 methods for `am_doc`, `am_object`, and subtypes
- `sync.R`: Synchronization (am_sync, am_sync_encode/decode, change tracking)
- `cursors.R`: Cursor and mark operations for text
- `convenience.R`: High-level convenience functions
- `constants.R`: Exported constants (`AM_ROOT`, `AM_OBJ_TYPE_*`, `AM_MARK_EXPAND_*`)

All R functions are thin `.Call()` wrappers (e.g., `am_put <- function(doc, obj, key, value) invisible(.Call(C_am_put, doc, obj, key, value))`). All logic lives in C.

### C Layer (`src/`)

- `automerge.h`: Data structures, function declarations, CHECK_RESULT macro
- `document.c`: Document lifecycle operations
- `objects.c`: Map/list/text operations and R↔Automerge type conversion
- `changes.c`: Change wrapping (owned vs borrowed) and introspection
- `sync.c`: Sync protocol implementation
- `cursors.c`: Cursor and mark operations
- `memory.c`: External pointer wrappers and finalizers
- `errors.c`: Error handling with file/line context
- `init.c`: R package registration (83 C functions)

## Formatter

Air, configured in `air.toml` (default settings).

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
- Mark operations: `am_mark()`, `am_marks()`
- Positions specify locations **between** characters (0 = before first character)

### UTF-32 Character Indexing

Text positions use Unicode code points, not bytes. The emoji "😀" counts as 1 character at position 5 in "Hello😀", matching R's `nchar()` behavior. JavaScript uses UTF-16, so positions may differ for some Unicode characters.

### Memory Management

- `am_doc` and `am_syncstate` structs wrap AMresult* (owns memory) and borrowed pointers (AMdoc*, AMsyncState*)
- External pointers use finalizers to prevent memory leaks
- **Protection chain**: Nested objects form a chain `obj_id_ptr → result_ptr → doc_ptr` via `R_ExternalPtrProtected()`. This keeps the parent document alive while nested objects exist, and enables `get_doc_from_objid()` to traverse back to the doc — which is how `user$nested$key <- value` works without passing the doc explicitly
- **Owned vs borrowed changes**: `changes.c` uses a dual finalizer pattern — owned changes (`am_change_data` struct with `AMresult*`) are freed by the finalizer, while borrowed changes (raw `AMchange*` with parent protection) are no-ops. Distinguished by checking `R_ExternalPtrProtected() == R_NilValue`

### Error Handling

- `CHECK_RESULT(result, expected_type)` macro validates AMresult* status and value type
- Automatically frees AMresult* on error before calling `Rf_error()` — caller must not use the result after CHECK_RESULT
- Includes file/line context for debugging (`__FILE__`, `__LINE__`)

## Packaging Notes

- roxygen2 with markdown; `NAMESPACE` is generated — never hand-edit.
- Version is `major.minor.patch.dev` (current dev tag `.9000`).
- `AGENTS.md`, `.claude/`, and `.posit/` are in `.Rbuildignore` and don't ship to CRAN.
