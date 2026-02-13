# Changelog

## automerge (development version)

- Adds change introspection functions:
  [`am_change_hash()`](https://posit-dev.github.io/automerge-r/reference/am_change_hash.md),
  [`am_change_message()`](https://posit-dev.github.io/automerge-r/reference/am_change_message.md),
  [`am_change_time()`](https://posit-dev.github.io/automerge-r/reference/am_change_time.md),
  [`am_change_actor_id()`](https://posit-dev.github.io/automerge-r/reference/am_change_actor_id.md),
  [`am_change_seq()`](https://posit-dev.github.io/automerge-r/reference/am_change_seq.md),
  and
  [`am_change_deps()`](https://posit-dev.github.io/automerge-r/reference/am_change_deps.md)
  for extracting metadata from changes.
  [`am_change_to_bytes()`](https://posit-dev.github.io/automerge-r/reference/am_change_to_bytes.md)
  and
  [`am_change_from_bytes()`](https://posit-dev.github.io/automerge-r/reference/am_change_from_bytes.md)
  enable serialization round-trips.

- Change-returning functions
  ([`am_get_changes()`](https://posit-dev.github.io/automerge-r/reference/am_get_changes.md),
  [`am_get_history()`](https://posit-dev.github.io/automerge-r/reference/am_get_history.md),
  [`am_get_last_local_change()`](https://posit-dev.github.io/automerge-r/reference/am_get_last_local_change.md),
  [`am_get_change_by_hash()`](https://posit-dev.github.io/automerge-r/reference/am_get_change_by_hash.md),
  [`am_get_changes_added()`](https://posit-dev.github.io/automerge-r/reference/am_get_changes_added.md))
  now return `am_change` objects instead of raw vectors.

- Adds cursor serialization and comparison:
  [`am_cursor_to_bytes()`](https://posit-dev.github.io/automerge-r/reference/am_cursor_to_bytes.md),
  [`am_cursor_from_bytes()`](https://posit-dev.github.io/automerge-r/reference/am_cursor_from_bytes.md),
  [`am_cursor_to_string()`](https://posit-dev.github.io/automerge-r/reference/am_cursor_to_string.md),
  [`am_cursor_from_string()`](https://posit-dev.github.io/automerge-r/reference/am_cursor_from_string.md),
  and
  [`am_cursor_equal()`](https://posit-dev.github.io/automerge-r/reference/am_cursor_equal.md).

- [`am_cursor()`](https://posit-dev.github.io/automerge-r/reference/am_cursor.md),
  [`am_cursor_position()`](https://posit-dev.github.io/automerge-r/reference/am_cursor_position.md),
  [`am_marks()`](https://posit-dev.github.io/automerge-r/reference/am_marks.md),
  and
  [`am_marks_at()`](https://posit-dev.github.io/automerge-r/reference/am_marks_at.md)
  gain a `heads` parameter for querying at historical document states.

- Renames `am_sync_state_new()` to
  [`am_sync_state()`](https://posit-dev.github.io/automerge-r/reference/am_sync_state.md).

- Updates MSRV to 1.85.

## automerge 0.2.1

CRAN release: 2026-02-05

- Adds
  [`str.am_doc()`](https://posit-dev.github.io/automerge-r/reference/str.am_doc.md)
  method to display the structure of an Automerge document.
- Adds
  [`am_close()`](https://posit-dev.github.io/automerge-r/reference/am_close.md)
  for explicitly closing a document.
- Updates MSRV to 1.84.

## automerge 0.2.0

CRAN release: 2026-01-31

- Initial CRAN release.

## automerge 0.1.0

- Initial implementation.
