# Synchronization Functions

#' Create a new sync state
#'
#' Creates a new synchronization state for managing communication with a peer.
#' The sync state tracks what changes have been sent and received, enabling
#' efficient incremental synchronization.
#'
#' **IMPORTANT**: Sync state is document-independent. The same sync state
#' is used across multiple sync message exchanges with a specific peer.
#' The document is passed separately to `am_sync_encode()` and `am_sync_decode()`.
#'
#' @return An external pointer to the sync state with class `"am_syncstate"`.
#'
#' @export
#' @examples
#' # Create two documents
#' doc1 <- am_create()
#' doc2 <- am_create()
#'
#' # Create sync states for each peer
#' sync1 <- am_sync_state()
#' sync1
#' sync2 <- am_sync_state()
#'
#' # Use with am_sync_encode() and am_sync_decode()
#'
#' am_close(doc1)
#' am_close(doc2)
#'
am_sync_state <- function() {
  .Call(C_am_sync_state)
}

#' Generate a sync message
#'
#' Generates a synchronization message to send to a peer. This message contains
#' the changes that the peer needs to bring their document up to date with yours.
#'
#' If the function returns `NULL`, it means there are no more messages to send
#' (synchronization is complete from this side).
#'
#' @inheritParams am_put
#' @param sync_state A sync state object (created with `am_sync_state()`)
#'
#' @return A raw vector containing the encoded sync message, or `NULL` if no
#'   message needs to be sent.
#'
#' @export
#' @examples
#' doc <- am_create()
#' sync_state <- am_sync_state()
#'
#' # Generate first sync message
#' msg <- am_sync_encode(doc, sync_state)
#' if (!is.null(msg)) {
#'   # Send msg to peer...
#' }
#'
#' am_close(doc)
#'
am_sync_encode <- function(doc, sync_state) {
  .Call(C_am_sync_encode, doc, sync_state)
}

#' Receive and apply a sync message
#'
#' Receives a synchronization message from a peer and applies the changes
#' to the local document. This updates both the document and the sync state
#' to reflect the received changes.
#'
#' @inheritParams am_put
#' @inheritParams am_sync_encode
#' @param message A raw vector containing an encoded sync message
#'
#' @return The document `doc` (invisibly, for chaining)
#'
#' @export
#' @examples
#' doc <- am_create()
#' sync_state <- am_sync_state()
#'
#' # Receive message from peer
#' # message <- ... (received from network)
#' # am_sync_decode(doc, sync_state, message)
#'
#' am_close(doc)
#'
am_sync_decode <- function(doc, sync_state, message) {
  invisible(.Call(C_am_sync_decode, doc, sync_state, message))
}

#' Bidirectional synchronization
#'
#' Automatically synchronizes two documents by exchanging messages until
#' they converge to the same state. This is a high-level convenience function
#' that handles the entire sync protocol automatically.
#'
#' The function exchanges sync messages back and forth between the two documents
#' until both sides report no more messages to send (`am_sync_encode()` returns `NULL`).
#' The Automerge sync protocol is mathematically guaranteed to converge.
#'
#' @param doc1 First Automerge document
#' @param doc2 Second Automerge document
#'
#' @return An integer indicating the number of sync rounds completed (invisibly).
#'   Both documents are modified in place to include each other's changes.
#'
#' @export
#' @examples
#' # Create two documents with different changes
#' doc1 <- am_create()
#' doc2 <- am_create()
#'
#' # Make changes in each document
#' am_put(doc1, AM_ROOT, "x", 1)
#' am_put(doc2, AM_ROOT, "y", 2)
#'
#' # Synchronize them (documents modified in place)
#' rounds <- am_sync(doc1, doc2)
#' rounds
#'
#' # Now both documents have both x and y
#'
#' am_close(doc1)
#' am_close(doc2)
#'
am_sync <- function(doc1, doc2) {
  if (!inherits(doc1, "am_doc")) {
    stop("doc1 must be an Automerge document")
  }
  if (!inherits(doc2, "am_doc")) {
    stop("doc2 must be an Automerge document")
  }

  sync1 <- am_sync_state()
  sync2 <- am_sync_state()

  round <- 0
  repeat {
    round <- round + 1

    msg1 <- am_sync_encode(doc1, sync1)
    msg2 <- am_sync_encode(doc2, sync2)

    if (is.null(msg1) && is.null(msg2)) {
      break
    }

    if (!is.null(msg1)) {
      am_sync_decode(doc2, sync2, msg1)
    }
    if (!is.null(msg2)) {
      am_sync_decode(doc1, sync1, msg2)
    }
  }

  invisible(round)
}

# Change Tracking and History Functions --------------------------------------

#' Get the current heads of a document
#'
#' Returns the current "heads" of the document - the hashes of the most recent
#' changes. These identify the current state of the document and can be used
#' for history operations.
#'
#' @inheritParams am_put
#'
#' @return A list of raw vectors, each containing a change hash. Usually there
#'   is only one head, but after concurrent edits there may be multiple heads
#'   until they are merged by a subsequent commit.
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "x", 1)
#' am_commit(doc)
#'
#' heads <- am_get_heads(doc)
#' heads
#'
#' am_close(doc)
#'
am_get_heads <- function(doc) {
  .Call(C_am_get_heads, doc)
}

#' Get changes since specified heads
#'
#' Returns all changes that have been made to the document since the specified
#' heads. If `heads` is `NULL`, returns all changes in the document's history.
#'
#' Changes are returned as `am_change` objects that can be inspected with
#' [am_change_hash()], [am_change_message()], etc., serialized with
#' [am_change_to_bytes()], or applied to other documents using
#' [am_apply_changes()].
#'
#' @inheritParams am_put
#' @param heads A list of raw vectors (change hashes) returned by `am_get_heads()`,
#'   or `NULL` to get all changes.
#'
#' @return A list of `am_change` objects.
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "x", 1)
#' am_commit(doc)
#'
#' # Get all changes
#' all_changes <- am_get_changes(doc)
#' all_changes
#'
#' am_close(doc)
#'
am_get_changes <- function(doc, heads = NULL) {
  .Call(C_am_get_changes, doc, heads)
}

#' Apply changes to a document
#'
#' Applies a list of changes (obtained from `am_get_changes()`) to a document.
#' This is useful for manually syncing changes or for applying changes received
#' over a custom network protocol.
#'
#' @inheritParams am_put
#' @param changes A list of `am_change` objects (from [am_get_changes()] or
#'   [am_change_from_bytes()])
#'
#' @return The document `doc` (invisibly, for chaining)
#'
#' @export
#' @examples
#' # Create two documents
#' doc1 <- am_create()
#' doc2 <- am_create()
#'
#' # Make changes in doc1
#' am_put(doc1, AM_ROOT, "x", 1)
#' am_commit(doc1)
#'
#' # Get changes and apply to doc2
#' changes <- am_get_changes(doc1, NULL)
#' am_apply_changes(doc2, changes)
#'
#' # Now doc2 has the same data as doc1
#'
#' am_close(doc1)
#' am_close(doc2)
#'
am_apply_changes <- function(doc, changes) {
  invisible(.Call(C_am_apply_changes, doc, changes))
}

# Change Introspection Functions -----------------------------------------------

#' Parse a serialized change from raw bytes
#'
#' Deserializes a change from raw bytes into an `am_change` object. This is
#' useful for restoring changes that were previously serialized with
#' [am_change_to_bytes()] or saved to disk.
#'
#' Note: [am_get_changes()] and other change-returning functions already return
#' `am_change` objects directly, so this function is only needed when working
#' with raw byte representations.
#'
#' @param bytes A raw vector containing a serialized change (from
#'   [am_change_to_bytes()])
#'
#' @return An `am_change` object (external pointer) that can be passed to
#'   [am_change_hash()], [am_change_message()], [am_change_time()],
#'   [am_change_actor_id()], [am_change_seq()], and [am_change_deps()].
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "key", "value")
#' am_commit(doc, "Add key")
#'
#' # Serialize a change and restore it
#' history <- am_get_changes(doc)
#' bytes <- am_change_to_bytes(history[[1]])
#' change <- am_change_from_bytes(bytes)
#' change
#' am_change_message(change)  # "Add key"
#'
#' am_close(doc)
#'
am_change_from_bytes <- function(bytes) {
  .Call(C_am_change_from_bytes, bytes)
}

#' Serialize a change to raw bytes
#'
#' Converts an `am_change` object back to its serialized raw vector form.
#'
#' @param change An `am_change` object (from [am_get_changes()] or
#'   [am_change_from_bytes()])
#'
#' @return A raw vector containing the serialized change
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "key", "value")
#' am_commit(doc, "Add key")
#'
#' history <- am_get_changes(doc)
#' bytes <- am_change_to_bytes(history[[1]])
#' bytes
#'
#' # Round-trip
#' restored <- am_change_from_bytes(bytes)
#' identical(am_change_to_bytes(restored), bytes)  # TRUE
#'
#' am_close(doc)
#'
am_change_to_bytes <- function(change) {
  .Call(C_am_change_to_bytes, change)
}

#' Get the hash of a change
#'
#' Returns the unique hash identifier of a change. Change hashes are used
#' to reference specific points in document history (e.g., with
#' [am_get_change_by_hash()] or [am_fork()]).
#'
#' @inheritParams am_change_to_bytes
#'
#' @return A raw vector (32 bytes) containing the change hash
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "key", "value")
#' am_commit(doc, "Add key")
#'
#' history <- am_get_changes(doc)
#' hash <- am_change_hash(history[[1]])
#' hash
#'
#' am_close(doc)
#'
am_change_hash <- function(change) {
  .Call(C_am_change_hash, change)
}

#' Get the commit message of a change
#'
#' Returns the commit message attached to a change, or `NULL` if no message
#' was provided when the change was committed.
#'
#' @inheritParams am_change_to_bytes
#'
#' @return A character string containing the commit message, or `NULL`
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "key", "value")
#' am_commit(doc, "Add key")
#'
#' history <- am_get_changes(doc)
#' am_change_message(history[[1]])  # "Add key"
#'
#' am_close(doc)
#'
am_change_message <- function(change) {
  .Call(C_am_change_message, change)
}

#' Get the timestamp of a change
#'
#' Returns the timestamp recorded when the change was committed.
#' Note that timestamps are set by the committing peer and may not be
#' accurate if the peer's clock is wrong.
#'
#' @inheritParams am_change_to_bytes
#'
#' @return A `POSIXct` timestamp
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "key", "value")
#' am_commit(doc, "Add key", Sys.time())
#'
#' history <- am_get_changes(doc)
#' am_change_time(history[[1]])
#'
#' am_close(doc)
#'
am_change_time <- function(change) {
  .Call(C_am_change_time, change)
}

#' Get the actor ID of a change
#'
#' Returns the actor ID of the peer that created the change.
#'
#' @inheritParams am_change_to_bytes
#'
#' @return A raw vector containing the actor ID bytes
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "key", "value")
#' am_commit(doc, "Add key")
#'
#' history <- am_get_changes(doc)
#' actor <- am_change_actor_id(history[[1]])
#' actor
#'
#' # Should match the document's actor
#' identical(actor, am_get_actor(doc))  # TRUE
#'
#' am_close(doc)
#'
am_change_actor_id <- function(change) {
  .Call(C_am_change_actor_id, change)
}

#' Get the sequence number of a change
#'
#' Returns the sequence number of the change within its actor's history.
#' Sequence numbers start at 1 and increment with each change by the
#' same actor.
#'
#' @inheritParams am_change_to_bytes
#'
#' @return A numeric value (double, since sequence numbers can exceed R's
#'   32-bit integer range)
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "x", 1)
#' am_commit(doc, "First")
#' am_put(doc, AM_ROOT, "y", 2)
#' am_commit(doc, "Second")
#'
#' history <- am_get_changes(doc)
#' am_change_seq(history[[1]])  # 1
#' am_change_seq(history[[2]])  # 2
#'
#' am_close(doc)
#'
am_change_seq <- function(change) {
  .Call(C_am_change_seq, change)
}

#' Get the dependencies of a change
#'
#' Returns the hashes of the changes that this change depends on (i.e.,
#' its parent changes in the causal graph). The first change in a document
#' has no dependencies.
#'
#' @inheritParams am_change_to_bytes
#'
#' @return A list of raw vectors (change hashes), each 32 bytes. Returns
#'   an empty list for the first change in a document.
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "x", 1)
#' am_commit(doc, "First")
#' am_put(doc, AM_ROOT, "y", 2)
#' am_commit(doc, "Second")
#'
#' history <- am_get_changes(doc)
#' deps1 <- am_change_deps(history[[1]])
#' deps1
#'
#' deps2 <- am_change_deps(history[[2]])
#' deps2
#'
#' am_close(doc)
#'
am_change_deps <- function(change) {
  .Call(C_am_change_deps, change)
}

#' Get the number of operations in a change
#'
#' Returns the number of operations contained in the change. Useful for
#' estimating the size of changes before syncing or storing them.
#'
#' @inheritParams am_change_to_bytes
#'
#' @return An integer (or double for very large values exceeding R's 32-bit
#'   integer range)
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "x", 1)
#' am_put(doc, AM_ROOT, "y", 2)
#' am_commit(doc, "Add keys")
#'
#' history <- am_get_changes(doc)
#' am_change_size(history[[1]])  # 2
#'
#' am_close(doc)
#'
am_change_size <- function(change) {
  .Call(C_am_change_size, change)
}

# v1.2 Sync and Change Operations --------------------------------------------

#' Get missing dependencies
#'
#' Returns the change hashes of dependencies that are referenced by the
#' document but not present in its change history. This can happen when
#' changes are applied out of order or when a document is partially synced.
#'
#' @inheritParams am_put
#' @param heads Optional list of change hashes (raw vectors) to check for
#'   missing dependencies. If `NULL` (default), checks the current heads.
#'
#' @return A list of raw vectors (change hashes of missing dependencies).
#'   Returns an empty list if no dependencies are missing.
#'
#' @export
#' @examples
#' doc <- am_create()
#' doc$key <- "value"
#' am_commit(doc)
#'
#' # Complete document has no missing deps
#' missing <- am_get_missing_deps(doc)
#' missing
#'
#' am_close(doc)
#'
am_get_missing_deps <- function(doc, heads = NULL) {
  .Call(C_am_get_missing_deps, doc, heads)
}

#' Load a document as individual changes
#'
#' Decomposes a serialized document into its individual changes. This is
#' useful for inspecting the full change history or for selectively applying
#' changes to another document.
#'
#' @param data A raw vector containing a serialized Automerge document
#'   (from [am_save()])
#'
#' @return A list of `am_change` objects. Returns an empty list for an
#'   empty document.
#'
#' @export
#' @examples
#' doc <- am_create()
#' doc$key <- "value"
#' am_commit(doc, "Add key")
#' doc$key2 <- "value2"
#' am_commit(doc, "Add key2")
#' bytes <- am_save(doc)
#'
#' # Load as individual changes
#' changes <- am_load_changes(bytes)
#' changes
#' am_change_message(changes[[1]])  # "Add key"
#' am_change_message(changes[[2]])  # "Add key2"
#'
#' # Apply to a new document
#' doc2 <- am_create()
#' am_apply_changes(doc2, changes)
#' doc2$key   # "value"
#' doc2$key2  # "value2"
#'
#' am_close(doc)
#' am_close(doc2)
#'
am_load_changes <- function(data) {
  .Call(C_am_load_changes, data)
}

#' Serialize a sync state
#'
#' Encodes a sync state to a raw vector for persistence or transmission.
#' The encoded state can later be restored with [am_sync_state_decode()].
#'
#' This is useful for persisting sync progress across sessions, avoiding
#' the need to re-sync from scratch.
#'
#' @inheritParams am_sync_encode
#'
#' @return A raw vector containing the serialized sync state.
#'
#' @seealso [am_sync_state_decode()], [am_sync_state()]
#'
#' @export
#' @examples
#' sync_state <- am_sync_state()
#'
#' # Encode for storage
#' bytes <- am_sync_state_encode(sync_state)
#' bytes
#'
#' # Restore later
#' restored <- am_sync_state_decode(bytes)
#' restored
#'
am_sync_state_encode <- function(sync_state) {
  .Call(C_am_sync_state_encode, sync_state)
}

#' Deserialize a sync state
#'
#' Restores a sync state from a raw vector previously created by
#' [am_sync_state_encode()]. This allows continuing a sync session
#' from where it left off.
#'
#' @param data A raw vector containing a serialized sync state
#'
#' @return An `am_syncstate` object.
#'
#' @seealso [am_sync_state_encode()], [am_sync_state()]
#'
#' @export
#' @examples
#' sync_state <- am_sync_state()
#' bytes <- am_sync_state_encode(sync_state)
#'
#' # Restore sync state
#' restored <- am_sync_state_decode(bytes)
#' restored
#'
am_sync_state_decode <- function(data) {
  .Call(C_am_sync_state_decode, data)
}
