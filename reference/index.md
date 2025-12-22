# Package index

## Document Lifecycle

Create, save, load, and manage Automerge documents

- [`am_create()`](https://shikokuchuo.net/automerge-r/reference/am_create.md)
  : Create a new Automerge document
- [`am_load()`](https://shikokuchuo.net/automerge-r/reference/am_load.md)
  : Load an Automerge document from binary format
- [`am_save()`](https://shikokuchuo.net/automerge-r/reference/am_save.md)
  : Save an Automerge document to binary format
- [`am_fork()`](https://shikokuchuo.net/automerge-r/reference/am_fork.md)
  : Fork an Automerge document
- [`am_merge()`](https://shikokuchuo.net/automerge-r/reference/am_merge.md)
  : Merge changes from another document
- [`am_commit()`](https://shikokuchuo.net/automerge-r/reference/am_commit.md)
  : Commit pending changes
- [`am_rollback()`](https://shikokuchuo.net/automerge-r/reference/am_rollback.md)
  : Roll back pending operations

## Actor Management

Get and set document actor IDs

- [`am_get_actor()`](https://shikokuchuo.net/automerge-r/reference/am_get_actor.md)
  : Get the actor ID of a document
- [`am_get_actor_hex()`](https://shikokuchuo.net/automerge-r/reference/am_get_actor_hex.md)
  : Get the actor ID as a hex string
- [`am_set_actor()`](https://shikokuchuo.net/automerge-r/reference/am_set_actor.md)
  : Set the actor ID of a document

## Object Operations

Create and manipulate maps, lists, and nested objects

- [`am_put()`](https://shikokuchuo.net/automerge-r/reference/am_put.md)
  : Put a value into an Automerge map or list
- [`am_get()`](https://shikokuchuo.net/automerge-r/reference/am_get.md)
  : Get a value from an Automerge map or list
- [`am_delete()`](https://shikokuchuo.net/automerge-r/reference/am_delete.md)
  : Delete a key from a map or element from a list
- [`am_insert()`](https://shikokuchuo.net/automerge-r/reference/am_insert.md)
  : Insert a value into an Automerge list
- [`am_keys()`](https://shikokuchuo.net/automerge-r/reference/am_keys.md)
  : Get all keys from an Automerge map
- [`am_values()`](https://shikokuchuo.net/automerge-r/reference/am_values.md)
  : Get all values from a map or list
- [`am_length()`](https://shikokuchuo.net/automerge-r/reference/am_length.md)
  : Get the length of an Automerge map or list

## Text Operations

Work with collaborative text objects

- [`am_text()`](https://shikokuchuo.net/automerge-r/reference/am_text.md)
  : Create an Automerge text object
- [`am_text_get()`](https://shikokuchuo.net/automerge-r/reference/am_text_get.md)
  : Get text from a text object
- [`am_text_splice()`](https://shikokuchuo.net/automerge-r/reference/am_text_splice.md)
  : Splice text in a text object
- [`as.character(`*`<am_text>`*`)`](https://shikokuchuo.net/automerge-r/reference/as.character.am_text.md)
  : Convert text object to character string

## Counters

Create and increment CRDT counters

- [`am_counter()`](https://shikokuchuo.net/automerge-r/reference/am_counter.md)
  : Create an Automerge counter
- [`am_counter_increment()`](https://shikokuchuo.net/automerge-r/reference/am_counter_increment.md)
  : Increment a counter value

## Cursors and Marks

Stable positions and text formatting

- [`am_cursor()`](https://shikokuchuo.net/automerge-r/reference/am_cursor.md)
  : Create a cursor at a position in a text object
- [`am_cursor_position()`](https://shikokuchuo.net/automerge-r/reference/am_cursor_position.md)
  : Get the current position of a cursor
- [`am_mark_create()`](https://shikokuchuo.net/automerge-r/reference/am_mark_create.md)
  : Create a mark on a text range
- [`am_marks()`](https://shikokuchuo.net/automerge-r/reference/am_marks.md)
  : Get all marks in a text object
- [`am_marks_at()`](https://shikokuchuo.net/automerge-r/reference/am_marks_at.md)
  : Get marks at a specific position

## Synchronization

Sync documents across peers

- [`am_sync()`](https://shikokuchuo.net/automerge-r/reference/am_sync.md)
  : Bidirectional synchronization
- [`am_sync_state_new()`](https://shikokuchuo.net/automerge-r/reference/am_sync_state_new.md)
  : Create a new sync state
- [`am_sync_encode()`](https://shikokuchuo.net/automerge-r/reference/am_sync_encode.md)
  : Generate a sync message
- [`am_sync_decode()`](https://shikokuchuo.net/automerge-r/reference/am_sync_decode.md)
  : Receive and apply a sync message

## History and Changes

Track document history and changes

- [`am_get_heads()`](https://shikokuchuo.net/automerge-r/reference/am_get_heads.md)
  : Get the current heads of a document
- [`am_get_changes()`](https://shikokuchuo.net/automerge-r/reference/am_get_changes.md)
  : Get changes since specified heads
- [`am_get_history()`](https://shikokuchuo.net/automerge-r/reference/am_get_history.md)
  : Get document history
- [`am_apply_changes()`](https://shikokuchuo.net/automerge-r/reference/am_apply_changes.md)
  : Apply changes to a document
- [`am_get_last_local_change()`](https://shikokuchuo.net/automerge-r/reference/am_get_last_local_change.md)
  : Get the last change made by the local actor
- [`am_get_change_by_hash()`](https://shikokuchuo.net/automerge-r/reference/am_get_change_by_hash.md)
  : Get a specific change by its hash
- [`am_get_changes_added()`](https://shikokuchuo.net/automerge-r/reference/am_get_changes_added.md)
  : Get changes in one document that are not in another

## Type Constructors

Explicit type constructors for objects

- [`am_list()`](https://shikokuchuo.net/automerge-r/reference/am_list.md)
  : Create an Automerge list
- [`am_map()`](https://shikokuchuo.net/automerge-r/reference/am_map.md)
  : Create an Automerge map
- [`am_uint64()`](https://shikokuchuo.net/automerge-r/reference/am_uint64.md)
  : Create an unsigned 64-bit integer value

## Path-Based Access

Navigate deep nested structures

- [`am_get_path()`](https://shikokuchuo.net/automerge-r/reference/am_get_path.md)
  : Navigate deep structures with path
- [`am_put_path()`](https://shikokuchuo.net/automerge-r/reference/am_put_path.md)
  : Set value at path
- [`am_delete_path()`](https://shikokuchuo.net/automerge-r/reference/am_delete_path.md)
  : Delete value at path

## Conversion Helpers

Convert between R lists and Automerge documents

- [`as_automerge()`](https://shikokuchuo.net/automerge-r/reference/as_automerge.md)
  : Convert R list to Automerge document
- [`from_automerge()`](https://shikokuchuo.net/automerge-r/reference/from_automerge.md)
  : Convert Automerge document to R list

## Constants

Package constants and enumerations

- [`AM_ROOT`](https://shikokuchuo.net/automerge-r/reference/automerge-constants.md)
  [`AM_OBJ_TYPE_LIST`](https://shikokuchuo.net/automerge-r/reference/automerge-constants.md)
  [`AM_OBJ_TYPE_MAP`](https://shikokuchuo.net/automerge-r/reference/automerge-constants.md)
  [`AM_OBJ_TYPE_TEXT`](https://shikokuchuo.net/automerge-r/reference/automerge-constants.md)
  [`AM_MARK_EXPAND_NONE`](https://shikokuchuo.net/automerge-r/reference/automerge-constants.md)
  [`AM_MARK_EXPAND_BEFORE`](https://shikokuchuo.net/automerge-r/reference/automerge-constants.md)
  [`AM_MARK_EXPAND_AFTER`](https://shikokuchuo.net/automerge-r/reference/automerge-constants.md)
  [`AM_MARK_EXPAND_BOTH`](https://shikokuchuo.net/automerge-r/reference/automerge-constants.md)
  : Automerge Constants

## S3 Methods

R methods for Automerge objects

- [`` `[[`( ``*`<am_doc>`*`)`](https://shikokuchuo.net/automerge-r/reference/extract-am_doc.md)
  [`` `$`( ``*`<am_doc>`*`)`](https://shikokuchuo.net/automerge-r/reference/extract-am_doc.md)
  : Extract from Automerge document root
- [`` `[[<-`( ``*`<am_doc>`*`)`](https://shikokuchuo.net/automerge-r/reference/replace-am_doc.md)
  [`` `$<-`( ``*`<am_doc>`*`)`](https://shikokuchuo.net/automerge-r/reference/replace-am_doc.md)
  : Replace in Automerge document root
- [`` `[[`( ``*`<am_object>`*`)`](https://shikokuchuo.net/automerge-r/reference/extract-am_object.md)
  [`` `$`( ``*`<am_object>`*`)`](https://shikokuchuo.net/automerge-r/reference/extract-am_object.md)
  : Extract from Automerge object
- [`` `[[<-`( ``*`<am_object>`*`)`](https://shikokuchuo.net/automerge-r/reference/replace-am_object.md)
  [`` `$<-`( ``*`<am_object>`*`)`](https://shikokuchuo.net/automerge-r/reference/replace-am_object.md)
  : Replace in Automerge object
- [`length(`*`<am_doc>`*`)`](https://shikokuchuo.net/automerge-r/reference/length.am_doc.md)
  : Get length of document root
- [`length(`*`<am_object>`*`)`](https://shikokuchuo.net/automerge-r/reference/length.am_object.md)
  : Get length of Automerge object
- [`names(`*`<am_doc>`*`)`](https://shikokuchuo.net/automerge-r/reference/names.am_doc.md)
  : Get names from document root
- [`names(`*`<am_map>`*`)`](https://shikokuchuo.net/automerge-r/reference/names.am_map.md)
  : Get names from Automerge map object
- [`as.list(`*`<am_doc>`*`)`](https://shikokuchuo.net/automerge-r/reference/as.list.am_doc.md)
  : Convert document root to R list
