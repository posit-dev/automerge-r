# automerge (development version)

* Adds change introspection functions: `am_change_hash()`,
  `am_change_message()`, `am_change_time()`, `am_change_actor_id()`,
  `am_change_seq()`, and `am_change_deps()` for extracting metadata from
  changes. `am_change_to_bytes()` and `am_change_from_bytes()` enable
  serialization round-trips.

* Change-returning functions (`am_get_changes()`, `am_get_history()`,
  `am_get_last_local_change()`, `am_get_change_by_hash()`,
  `am_get_changes_added()`) now return `am_change` objects instead of raw
  vectors.

* Adds cursor serialization and comparison: `am_cursor_to_bytes()`,
  `am_cursor_from_bytes()`, `am_cursor_to_string()`,
  `am_cursor_from_string()`, and `am_cursor_equal()`.

* `am_cursor()`, `am_cursor_position()`, `am_marks()`, and `am_marks_at()`
  gain a `heads` parameter for querying at historical document states.

* Renames `am_sync_state_new()` to `am_sync_state()`.

* Updates MSRV to 1.85.

# automerge 0.2.1

* Adds `str.am_doc()` method to display the structure of an Automerge document.
* Adds `am_close()` for explicitly closing a document.
* Updates MSRV to 1.84.

# automerge 0.2.0

* Initial CRAN release.

# automerge 0.1.0

* Initial implementation.
