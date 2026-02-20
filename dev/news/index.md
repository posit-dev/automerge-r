# Changelog

## automerge (development version)

- Fixes additional Valgrind false positive in vendored automerge
  library.

## automerge 0.3.1

CRAN release: 2026-02-19

- Adds [`print()`](https://rdrr.io/r/base/print.html) method for
  `am_change` objects.

- Removes vendored `tinyvec` dependency to fix Valgrind false positive.

## automerge 0.3.0

CRAN release: 2026-02-17

- Change-returning functions
  ([`am_get_changes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get_changes.md),
  [`am_get_last_local_change()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get_last_local_change.md),
  [`am_get_change_by_hash()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get_change_by_hash.md),
  [`am_get_changes_added()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get_changes_added.md))
  now return `am_change` objects instead of raw vectors.

- Removes `am_get_history()`. Use
  [`am_get_changes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get_changes.md)
  instead, which returns the full change history when called without
  `heads`.

- Renames `am_sync_state_new()` to
  [`am_sync_state()`](https://posit-dev.github.io/automerge-r/dev/reference/am_sync_state.md).

- Adds change introspection functions:
  [`am_change_hash()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_hash.md),
  [`am_change_message()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_message.md),
  [`am_change_time()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_time.md),
  [`am_change_actor_id()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_actor_id.md),
  [`am_change_seq()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_seq.md),
  [`am_change_deps()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_deps.md),
  and
  [`am_change_size()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_size.md)
  for extracting metadata from changes.
  [`am_change_to_bytes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_to_bytes.md)
  and
  [`am_change_from_bytes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_from_bytes.md)
  enable serialization round-trips.

- [`am_cursor()`](https://posit-dev.github.io/automerge-r/dev/reference/am_cursor.md),
  [`am_cursor_position()`](https://posit-dev.github.io/automerge-r/dev/reference/am_cursor_position.md),
  [`am_marks()`](https://posit-dev.github.io/automerge-r/dev/reference/am_marks.md),
  and
  [`am_marks_at()`](https://posit-dev.github.io/automerge-r/dev/reference/am_marks_at.md)
  gain a `heads` parameter for querying at historical document states.

- Adds cursor serialization and comparison:
  [`am_cursor_to_bytes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_cursor_to_bytes.md),
  [`am_cursor_from_bytes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_cursor_from_bytes.md),
  [`am_cursor_to_string()`](https://posit-dev.github.io/automerge-r/dev/reference/am_cursor_to_string.md),
  [`am_cursor_from_string()`](https://posit-dev.github.io/automerge-r/dev/reference/am_cursor_from_string.md),
  and
  [`am_cursor_equal()`](https://posit-dev.github.io/automerge-r/dev/reference/am_cursor_equal.md).

- Adds incremental save/load:
  [`am_save_incremental()`](https://posit-dev.github.io/automerge-r/dev/reference/am_save_incremental.md)
  and
  [`am_load_incremental()`](https://posit-dev.github.io/automerge-r/dev/reference/am_load_incremental.md)
  for exchanging only new changes since the last save.

- Adds conflict inspection:
  [`am_map_get_all()`](https://posit-dev.github.io/automerge-r/dev/reference/am_map_get_all.md)
  and
  [`am_list_get_all()`](https://posit-dev.github.io/automerge-r/dev/reference/am_list_get_all.md)
  for retrieving all conflicting values at a key or index after
  concurrent edits.

- Adds range queries:
  [`am_map_range()`](https://posit-dev.github.io/automerge-r/dev/reference/am_map_range.md)
  for retrieving map entries within a key range,
  [`am_list_range()`](https://posit-dev.github.io/automerge-r/dev/reference/am_list_range.md)
  for retrieving a subrange of list items, and
  [`am_items()`](https://posit-dev.github.io/automerge-r/dev/reference/am_items.md)
  for getting all key-value entries from any object.

- Adds
  [`am_mark_clear()`](https://posit-dev.github.io/automerge-r/dev/reference/am_mark_clear.md)
  for removing marks from text ranges.

- Adds sync state serialization:
  [`am_sync_state_encode()`](https://posit-dev.github.io/automerge-r/dev/reference/am_sync_state_encode.md)
  and
  [`am_sync_state_decode()`](https://posit-dev.github.io/automerge-r/dev/reference/am_sync_state_decode.md)
  for persisting sync state across sessions.

- Adds
  [`am_load_changes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_load_changes.md)
  for decomposing saved document bytes into individual changes, and
  [`am_get_missing_deps()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get_missing_deps.md)
  for checking document completeness.

- Adds document utilities:
  [`am_clone()`](https://posit-dev.github.io/automerge-r/dev/reference/am_clone.md)
  for deep copying (preserving actor ID),
  [`am_equal()`](https://posit-dev.github.io/automerge-r/dev/reference/am_equal.md)
  for testing document equality,
  [`am_pending_ops()`](https://posit-dev.github.io/automerge-r/dev/reference/am_pending_ops.md)
  for counting uncommitted operations, and
  [`am_commit_empty()`](https://posit-dev.github.io/automerge-r/dev/reference/am_commit_empty.md)
  for creating empty changes.

- Updates MSRV to 1.85.

## automerge 0.2.1

CRAN release: 2026-02-05

- Adds
  [`str.am_doc()`](https://posit-dev.github.io/automerge-r/dev/reference/str.am_doc.md)
  method to display the structure of an Automerge document.

- Adds
  [`am_close()`](https://posit-dev.github.io/automerge-r/dev/reference/am_close.md)
  for explicitly closing a document.

- Updates MSRV to 1.84.

## automerge 0.2.0

CRAN release: 2026-01-31

- Initial CRAN release.

## automerge 0.1.0

- Initial implementation.
