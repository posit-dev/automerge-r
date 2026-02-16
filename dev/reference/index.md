# Package index

## Document Lifecycle

Create, save, load, and manage Automerge documents

- [`am_create()`](https://posit-dev.github.io/automerge-r/dev/reference/am_create.md)
  : Create a new Automerge document
- [`am_load()`](https://posit-dev.github.io/automerge-r/dev/reference/am_load.md)
  : Load an Automerge document from binary format
- [`am_save()`](https://posit-dev.github.io/automerge-r/dev/reference/am_save.md)
  : Save an Automerge document to binary format
- [`am_fork()`](https://posit-dev.github.io/automerge-r/dev/reference/am_fork.md)
  : Fork an Automerge document
- [`am_merge()`](https://posit-dev.github.io/automerge-r/dev/reference/am_merge.md)
  : Merge changes from another document
- [`am_commit()`](https://posit-dev.github.io/automerge-r/dev/reference/am_commit.md)
  : Commit pending changes
- [`am_rollback()`](https://posit-dev.github.io/automerge-r/dev/reference/am_rollback.md)
  : Roll back pending operations
- [`am_close()`](https://posit-dev.github.io/automerge-r/dev/reference/am_close.md)
  : Close an Automerge document
- [`am_clone()`](https://posit-dev.github.io/automerge-r/dev/reference/am_clone.md)
  : Clone an Automerge document
- [`am_equal()`](https://posit-dev.github.io/automerge-r/dev/reference/am_equal.md)
  : Test document equality
- [`am_pending_ops()`](https://posit-dev.github.io/automerge-r/dev/reference/am_pending_ops.md)
  : Get the number of pending operations
- [`am_commit_empty()`](https://posit-dev.github.io/automerge-r/dev/reference/am_commit_empty.md)
  : Create an empty change
- [`am_save_incremental()`](https://posit-dev.github.io/automerge-r/dev/reference/am_save_incremental.md)
  : Save incremental changes
- [`am_load_incremental()`](https://posit-dev.github.io/automerge-r/dev/reference/am_load_incremental.md)
  : Load incremental changes into a document

## Actor Management

Get and set actor IDs

- [`am_get_actor()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get_actor.md)
  : Get the actor ID of a document
- [`am_get_actor_hex()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get_actor_hex.md)
  : Get the actor ID as a hex string
- [`am_set_actor()`](https://posit-dev.github.io/automerge-r/dev/reference/am_set_actor.md)
  : Set the actor ID of a document

## Object Operations

Create and manipulate maps, lists, and nested objects

- [`am_put()`](https://posit-dev.github.io/automerge-r/dev/reference/am_put.md)
  : Put a value into an Automerge map or list
- [`am_get()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get.md)
  : Get a value from an Automerge map or list
- [`am_delete()`](https://posit-dev.github.io/automerge-r/dev/reference/am_delete.md)
  : Delete a key from a map or element from a list
- [`am_insert()`](https://posit-dev.github.io/automerge-r/dev/reference/am_insert.md)
  : Insert a value into an Automerge list
- [`am_keys()`](https://posit-dev.github.io/automerge-r/dev/reference/am_keys.md)
  : Get all keys from an Automerge map
- [`am_values()`](https://posit-dev.github.io/automerge-r/dev/reference/am_values.md)
  : Get all values from a map or list
- [`am_length()`](https://posit-dev.github.io/automerge-r/dev/reference/am_length.md)
  : Get the length of an Automerge map or list
- [`am_items()`](https://posit-dev.github.io/automerge-r/dev/reference/am_items.md)
  : Get full item details from an object
- [`am_list_range()`](https://posit-dev.github.io/automerge-r/dev/reference/am_list_range.md)
  : Get a range of list items
- [`am_map_range()`](https://posit-dev.github.io/automerge-r/dev/reference/am_map_range.md)
  : Get a range of map items by key
- [`am_list_get_all()`](https://posit-dev.github.io/automerge-r/dev/reference/am_list_get_all.md)
  : Get all conflicting values at a list position
- [`am_map_get_all()`](https://posit-dev.github.io/automerge-r/dev/reference/am_map_get_all.md)
  : Get all conflicting values at a map key

## Text Operations

Work with collaborative text objects

- [`am_text()`](https://posit-dev.github.io/automerge-r/dev/reference/am_text.md)
  : Create an Automerge text object
- [`am_text_content()`](https://posit-dev.github.io/automerge-r/dev/reference/am_text_content.md)
  : Get text content from a text object
- [`am_text_splice()`](https://posit-dev.github.io/automerge-r/dev/reference/am_text_splice.md)
  : Splice text in a text object
- [`am_text_update()`](https://posit-dev.github.io/automerge-r/dev/reference/am_text_update.md)
  : Update text content
- [`as.character(`*`<am_text>`*`)`](https://posit-dev.github.io/automerge-r/dev/reference/as.character.am_text.md)
  : Convert text object to character string

## Counters

Create and increment CRDT counters

- [`am_counter()`](https://posit-dev.github.io/automerge-r/dev/reference/am_counter.md)
  : Create an Automerge counter
- [`am_counter_increment()`](https://posit-dev.github.io/automerge-r/dev/reference/am_counter_increment.md)
  : Increment a counter value

## Cursors and Marks

Stable positions, text formatting, and cursor serialization

- [`am_cursor()`](https://posit-dev.github.io/automerge-r/dev/reference/am_cursor.md)
  : Create a cursor at a position in a text object
- [`am_cursor_position()`](https://posit-dev.github.io/automerge-r/dev/reference/am_cursor_position.md)
  : Get the current position of a cursor
- [`am_cursor_to_bytes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_cursor_to_bytes.md)
  : Serialize a cursor to bytes
- [`am_cursor_from_bytes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_cursor_from_bytes.md)
  : Restore a cursor from bytes
- [`am_cursor_to_string()`](https://posit-dev.github.io/automerge-r/dev/reference/am_cursor_to_string.md)
  : Serialize a cursor to a string
- [`am_cursor_from_string()`](https://posit-dev.github.io/automerge-r/dev/reference/am_cursor_from_string.md)
  : Restore a cursor from a string
- [`am_cursor_equal()`](https://posit-dev.github.io/automerge-r/dev/reference/am_cursor_equal.md)
  : Test equality of two cursors
- [`am_mark()`](https://posit-dev.github.io/automerge-r/dev/reference/am_mark.md)
  : Create a mark on a text range
- [`am_mark_clear()`](https://posit-dev.github.io/automerge-r/dev/reference/am_mark_clear.md)
  : Clear marks from a text range
- [`am_marks()`](https://posit-dev.github.io/automerge-r/dev/reference/am_marks.md)
  : Get all marks in a text object
- [`am_marks_at()`](https://posit-dev.github.io/automerge-r/dev/reference/am_marks_at.md)
  : Get marks at a specific position

## Synchronization

Sync documents across peers

- [`am_sync()`](https://posit-dev.github.io/automerge-r/dev/reference/am_sync.md)
  : Bidirectional synchronization
- [`am_sync_state()`](https://posit-dev.github.io/automerge-r/dev/reference/am_sync_state.md)
  : Create a new sync state
- [`am_sync_encode()`](https://posit-dev.github.io/automerge-r/dev/reference/am_sync_encode.md)
  : Generate a sync message
- [`am_sync_decode()`](https://posit-dev.github.io/automerge-r/dev/reference/am_sync_decode.md)
  : Receive and apply a sync message
- [`am_sync_state_encode()`](https://posit-dev.github.io/automerge-r/dev/reference/am_sync_state_encode.md)
  : Serialize a sync state
- [`am_sync_state_decode()`](https://posit-dev.github.io/automerge-r/dev/reference/am_sync_state_decode.md)
  : Deserialize a sync state

## History and Changes

Track document history and inspect changes

- [`am_get_heads()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get_heads.md)
  : Get the current heads of a document
- [`am_get_changes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get_changes.md)
  : Get changes since specified heads
- [`am_get_history()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get_history.md)
  : Get document history
- [`am_apply_changes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_apply_changes.md)
  : Apply changes to a document
- [`am_get_last_local_change()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get_last_local_change.md)
  : Get the last change made by the local actor
- [`am_get_change_by_hash()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get_change_by_hash.md)
  : Get a specific change by its hash
- [`am_get_changes_added()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get_changes_added.md)
  : Get changes in one document that are not in another
- [`am_change_from_bytes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_from_bytes.md)
  : Parse a serialized change from raw bytes
- [`am_change_to_bytes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_to_bytes.md)
  : Serialize a change to raw bytes
- [`am_change_hash()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_hash.md)
  : Get the hash of a change
- [`am_change_message()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_message.md)
  : Get the commit message of a change
- [`am_change_time()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_time.md)
  : Get the timestamp of a change
- [`am_change_actor_id()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_actor_id.md)
  : Get the actor ID of a change
- [`am_change_seq()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_seq.md)
  : Get the sequence number of a change
- [`am_change_deps()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_deps.md)
  : Get the dependencies of a change
- [`am_get_missing_deps()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get_missing_deps.md)
  : Get missing dependencies
- [`am_load_changes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_load_changes.md)
  : Load a document as individual changes

## Type Constructors

Explicit type constructors for objects

- [`am_list()`](https://posit-dev.github.io/automerge-r/dev/reference/am_list.md)
  : Create an Automerge list
- [`am_map()`](https://posit-dev.github.io/automerge-r/dev/reference/am_map.md)
  : Create an Automerge map
- [`am_uint64()`](https://posit-dev.github.io/automerge-r/dev/reference/am_uint64.md)
  : Create an unsigned 64-bit integer value

## Path-Based Access

Navigate deep nested structures

- [`am_get_path()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get_path.md)
  : Navigate deep structures with path
- [`am_put_path()`](https://posit-dev.github.io/automerge-r/dev/reference/am_put_path.md)
  : Set value at path
- [`am_delete_path()`](https://posit-dev.github.io/automerge-r/dev/reference/am_delete_path.md)
  : Delete value at path

## Conversion Helpers

Convert between R lists and Automerge documents

- [`as_automerge()`](https://posit-dev.github.io/automerge-r/dev/reference/as_automerge.md)
  : Convert R list to Automerge document
- [`from_automerge()`](https://posit-dev.github.io/automerge-r/dev/reference/from_automerge.md)
  : Convert Automerge document to R list

## Constants

Package constants and enumerations

- [`AM_ROOT`](https://posit-dev.github.io/automerge-r/dev/reference/automerge-constants.md)
  [`AM_OBJ_TYPE_LIST`](https://posit-dev.github.io/automerge-r/dev/reference/automerge-constants.md)
  [`AM_OBJ_TYPE_MAP`](https://posit-dev.github.io/automerge-r/dev/reference/automerge-constants.md)
  [`AM_OBJ_TYPE_TEXT`](https://posit-dev.github.io/automerge-r/dev/reference/automerge-constants.md)
  [`AM_MARK_EXPAND_NONE`](https://posit-dev.github.io/automerge-r/dev/reference/automerge-constants.md)
  [`AM_MARK_EXPAND_BEFORE`](https://posit-dev.github.io/automerge-r/dev/reference/automerge-constants.md)
  [`AM_MARK_EXPAND_AFTER`](https://posit-dev.github.io/automerge-r/dev/reference/automerge-constants.md)
  [`AM_MARK_EXPAND_BOTH`](https://posit-dev.github.io/automerge-r/dev/reference/automerge-constants.md)
  : Automerge Constants

## S3 Methods

R methods for Automerge objects

- [`` `[[`( ``*`<am_doc>`*`)`](https://posit-dev.github.io/automerge-r/dev/reference/extract-am_doc.md)
  [`` `$`( ``*`<am_doc>`*`)`](https://posit-dev.github.io/automerge-r/dev/reference/extract-am_doc.md)
  : Extract from Automerge document root
- [`` `[[<-`( ``*`<am_doc>`*`)`](https://posit-dev.github.io/automerge-r/dev/reference/replace-am_doc.md)
  [`` `$<-`( ``*`<am_doc>`*`)`](https://posit-dev.github.io/automerge-r/dev/reference/replace-am_doc.md)
  : Replace in Automerge document root
- [`` `[[`( ``*`<am_object>`*`)`](https://posit-dev.github.io/automerge-r/dev/reference/extract-am_object.md)
  [`` `$`( ``*`<am_object>`*`)`](https://posit-dev.github.io/automerge-r/dev/reference/extract-am_object.md)
  : Extract from Automerge object
- [`` `[[<-`( ``*`<am_object>`*`)`](https://posit-dev.github.io/automerge-r/dev/reference/replace-am_object.md)
  [`` `$<-`( ``*`<am_object>`*`)`](https://posit-dev.github.io/automerge-r/dev/reference/replace-am_object.md)
  : Replace in Automerge object
- [`length(`*`<am_doc>`*`)`](https://posit-dev.github.io/automerge-r/dev/reference/length.am_doc.md)
  : Get length of document root
- [`length(`*`<am_object>`*`)`](https://posit-dev.github.io/automerge-r/dev/reference/length.am_object.md)
  : Get length of Automerge object
- [`names(`*`<am_doc>`*`)`](https://posit-dev.github.io/automerge-r/dev/reference/names.am_doc.md)
  : Get names from document root
- [`names(`*`<am_map>`*`)`](https://posit-dev.github.io/automerge-r/dev/reference/names.am_map.md)
  : Get names from Automerge map object
- [`as.list(`*`<am_doc>`*`)`](https://posit-dev.github.io/automerge-r/dev/reference/as.list.am_doc.md)
  : Convert document root to R list
- [`str(`*`<am_doc>`*`)`](https://posit-dev.github.io/automerge-r/dev/reference/str.am_doc.md)
  : Display the structure of an Automerge document
