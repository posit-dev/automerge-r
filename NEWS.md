# automerge 0.4.0

* `am_text_update()` no longer requires the `old_text` argument; the current
  text content is now read from the document automatically.

* `am_text_content()` gains a `heads` parameter for historical text queries.

* Functions accepting a `heads` parameter now support multiple heads.

* Fixes additional Valgrind false positive in vendored automerge library.

# automerge 0.3.1

* Adds `print()` method for `am_change` objects.

* Removes vendored `tinyvec` dependency to fix Valgrind false positive.

# automerge 0.3.0

* Change-returning functions (`am_get_changes()`, `am_get_last_local_change()`, 
  `am_get_change_by_hash()`, `am_get_changes_added()`) now return `am_change`
  objects instead of raw vectors.

* Removes `am_get_history()`. Use `am_get_changes()` instead, which
  returns the full change history when called without `heads`.

* Renames `am_sync_state_new()` to `am_sync_state()`.

* Adds change introspection functions: `am_change_hash()`,
  `am_change_message()`, `am_change_time()`, `am_change_actor_id()`,
  `am_change_seq()`, `am_change_deps()`, and `am_change_size()` for
  extracting metadata from changes.
  `am_change_to_bytes()` and `am_change_from_bytes()` enable serialization
  round-trips.

* `am_cursor()`, `am_cursor_position()`, `am_marks()`, and `am_marks_at()`
  gain a `heads` parameter for querying at historical document states.

* Adds cursor serialization and comparison: `am_cursor_to_bytes()`,
  `am_cursor_from_bytes()`, `am_cursor_to_string()`,
  `am_cursor_from_string()`, and `am_cursor_equal()`.

* Adds incremental save/load: `am_save_incremental()` and
  `am_load_incremental()` for exchanging only new changes since the last save.

* Adds conflict inspection: `am_map_get_all()` and `am_list_get_all()` for
  retrieving all conflicting values at a key or index after concurrent edits.

* Adds range queries: `am_map_range()` for retrieving map entries within a key
  range, `am_list_range()` for retrieving a subrange of list items, and
  `am_items()` for getting all key-value entries from any object.

* Adds `am_mark_clear()` for removing marks from text ranges.

* Adds sync state serialization: `am_sync_state_encode()` and
  `am_sync_state_decode()` for persisting sync state across sessions.

* Adds `am_load_changes()` for decomposing saved document bytes into
  individual changes, and `am_get_missing_deps()` for checking document
  completeness.

* Adds document utilities: `am_clone()` for deep copying (preserving actor
  ID), `am_equal()` for testing document equality, `am_pending_ops()` for
  counting uncommitted operations, and `am_commit_empty()` for creating empty
  changes.

* Updates MSRV to 1.85.

# automerge 0.2.1

* Adds `str.am_doc()` method to display the structure of an Automerge document.

* Adds `am_close()` for explicitly closing a document.

* Updates MSRV to 1.84.

# automerge 0.2.0

* Initial CRAN release.

# automerge 0.1.0

* Initial implementation.
