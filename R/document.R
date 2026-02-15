# Document Lifecycle Functions

#' Close an Automerge document
#'
#' Explicitly frees the resources associated with an Automerge document.
#' After calling this function, the document becomes invalid and should
#' not be used.
#'
#' This function is useful when you need deterministic cleanup rather than
#' waiting for garbage collection. It is safe to call on a document that
#' has already been closed.
#'
#' @param doc An Automerge document (created with `am_create()` or `am_load()`)
#'
#' @return `NULL` (invisibly)
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "key", "value")
#'
#' # Explicitly free resources
#' am_close(doc)
#'
#' # Document is now invalid - do not use after closing
#'
am_close <- function(doc) {
  invisible(.Call(C_am_close, doc))
}

#' Create a new Automerge document
#'
#' Creates a new Automerge document with an optional custom actor ID.
#' If no actor ID is provided, a random one is generated.
#'
#' @param actor_id Optional actor ID. Can be:
#'   \itemize{
#'     \item `NULL` (default) - Generate random actor ID
#'     \item Character string - Hex-encoded actor ID
#'     \item Raw vector - Binary actor ID bytes
#'   }
#'
#' @return An external pointer to the Automerge document with class
#'   `c("am_doc", "automerge")`.
#'
#' @section Thread Safety:
#' The automerge package is NOT thread-safe. Do not access the same document
#' from multiple R threads concurrently. Each thread should create its own
#' document with `am_create()` and synchronize changes via
#' `am_sync_*()` functions after thread completion.
#'
#' @export
#' @examples
#' # Create document with random actor ID
#' doc1 <- am_create()
#' doc1
#'
#' # Create with custom hex actor ID
#' doc2 <- am_create("0123456789abcdef0123456789abcdef")
#'
#' # Create with raw bytes actor ID
#' actor_bytes <- as.raw(1:16)
#' doc3 <- am_create(actor_bytes)
#'
#' am_close(doc1)
#' am_close(doc2)
#' am_close(doc3)
#'
am_create <- function(actor_id = NULL) {
  .Call(C_am_create, actor_id)
}

#' Save an Automerge document to binary format
#'
#' Serializes an Automerge document to the standard binary format,
#' which can be saved to disk or transmitted over a network.
#' The binary format is compatible across all Automerge implementations
#' (JavaScript, Rust, etc.).
#'
#' @param doc An Automerge document (created with `am_create()` or `am_load()`)
#'
#' @return A raw vector containing the serialized document
#'
#' @export
#' @examples
#' doc <- am_create()
#' bytes <- am_save(doc)
#' bytes
#'
#' # Save to file
#' file <- tempfile()
#' writeBin(am_save(doc), file)
#'
#' unlink(file)
#' am_close(doc)
#'
am_save <- function(doc) {
  .Call(C_am_save, doc)
}

#' Load an Automerge document from binary format
#'
#' Deserializes an Automerge document from the standard binary format.
#' The binary format is compatible across all Automerge implementations
#' (JavaScript, Rust, etc.).
#'
#' @param data A raw vector containing a serialized Automerge document
#'
#' @return An external pointer to the Automerge document with class
#'   `c("am_doc", "automerge")`.
#'
#' @export
#' @examples
#' # Create, save, and reload
#' doc1 <- am_create()
#' bytes <- am_save(doc1)
#' doc2 <- am_load(bytes)
#' doc2
#'
#' # Save to and load from file
#' doc3 <- am_create()
#' file <- tempfile()
#' writeBin(am_save(doc3), file)
#'
#' doc4 <- am_load(readBin(file, "raw", 1e5))
#'
#' unlink(file)
#' am_close(doc1)
#' am_close(doc2)
#' am_close(doc3)
#' am_close(doc4)
#'
am_load <- function(data) {
  .Call(C_am_load, data)
}

#' Fork an Automerge document
#'
#' Creates a fork of an Automerge document at the current heads or
#' at a specific point in history. The forked document shares history
#' with the original up to the fork point but can diverge afterwards.
#' The fork is assigned a new actor ID, so changes made on the fork
#' are distinguishable from the original when merged or synced.
#'
#' Use `am_fork()` when creating independent branches of a document
#' that may later be merged or synced. Use [am_clone()] instead if you
#' need an exact copy that preserves the original actor ID (e.g. for
#' archival or snapshotting purposes).
#'
#' @param doc An Automerge document
#' @param heads Optional list of change hashes to fork at a specific point in
#'   the document's history. If `NULL` (default) or an empty list, forks at
#'   current heads. Each hash should be a raw vector (32 bytes).
#'
#' @return A new Automerge document (fork of the original)
#'
#' @seealso [am_clone()] for an exact copy preserving the actor ID
#' @export
#' @examples
#' doc1 <- am_create()
#' doc2 <- am_fork(doc1)
#' doc2
#'
#' # Fork has a different actor ID
#' am_get_actor_hex(doc1) != am_get_actor_hex(doc2) # TRUE
#'
#' # Now doc1 and doc2 can diverge independently
#' am_close(doc1)
#' am_close(doc2)
#'
am_fork <- function(doc, heads = NULL) {
  .Call(C_am_fork, doc, heads)
}

#' Merge changes from another document
#'
#' Merges all changes from another Automerge document into this one.
#' This is a one-way merge: changes flow from `other` into `doc`,
#' but `other` is not modified. For bidirectional synchronization,
#' use [am_sync()].
#'
#' @param doc Target document (will receive changes)
#' @param other Source document (provides changes)
#'
#' @return The target document `doc` (invisibly)
#'
#' @export
#' @examples
#' doc1 <- am_create()
#' doc2 <- am_create()
#'
#' # Make changes in each document
#' am_put(doc1, AM_ROOT, "x", 1)
#' am_put(doc2, AM_ROOT, "y", 2)
#'
#' # Merge doc2's changes into doc1
#' am_merge(doc1, doc2)
#'
#' # Now doc1 has both x and y
#' am_close(doc1)
#' am_close(doc2)
#'
am_merge <- function(doc, other) {
  invisible(.Call(C_am_merge, doc, other))
}

#' Get the actor ID of a document
#'
#' Returns the actor ID of an Automerge document as a raw vector.
#' The actor ID uniquely identifies the editing session that created
#' changes in the document.
#'
#' For a hex string representation, use [am_get_actor_hex()].
#'
#' @param doc An Automerge document
#'
#' @return A raw vector containing the actor ID bytes
#'
#' @export
#' @examples
#' doc <- am_create()
#' actor <- am_get_actor(doc)
#' actor
#'
#' # Use am_get_actor_hex() for display
#' actor_hex <- am_get_actor_hex(doc)
#' cat("Actor ID:", actor_hex, "\n")
#'
#' am_close(doc)
#'
am_get_actor <- function(doc) {
  .Call(C_am_get_actor, doc)
}

#' Get the actor ID as a hex string
#'
#' Returns the actor ID of an Automerge document as a hex-encoded string.
#' This is more efficient than converting the raw bytes returned by
#' [am_get_actor()] using R-level string operations.
#'
#' @param doc An Automerge document
#'
#' @return A character string containing the hex-encoded actor ID
#'
#' @export
#' @examples
#' doc <- am_create()
#' actor_hex <- am_get_actor_hex(doc)
#' actor_hex
#'
#' am_close(doc)
#'
am_get_actor_hex <- function(doc) {
  .Call(C_am_get_actor_hex, doc)
}

#' Set the actor ID of a document
#'
#' Sets the actor ID for an Automerge document. This should typically
#' be done before making any changes. Changing the actor ID mid-session
#' is not recommended as it can complicate change attribution.
#'
#' @param doc An Automerge document
#' @param actor_id The new actor ID. Can be:
#'   \itemize{
#'     \item `NULL` - Generate new random actor ID
#'     \item Character string - Hex-encoded actor ID
#'     \item Raw vector - Binary actor ID bytes
#'   }
#'
#' @return The document `doc` (invisibly)
#'
#' @export
#' @examples
#' doc <- am_create()
#'
#' # Set custom actor ID from hex string
#' am_set_actor(doc, "0123456789abcdef0123456789abcdef")
#'
#' # Generate new random actor ID
#' am_set_actor(doc, NULL)
#'
#' am_close(doc)
#'
am_set_actor <- function(doc, actor_id) {
  invisible(.Call(C_am_set_actor, doc, actor_id))
}

#' Commit pending changes
#'
#' Commits all pending operations in the current transaction,
#' creating a new change in the document's history. Commits can
#' include an optional message (like a git commit message) and
#' timestamp.
#'
#' @param doc An Automerge document
#' @param message Optional commit message (character string)
#' @param time Optional timestamp (POSIXct). If `NULL`, uses current time.
#'
#' @return The document `doc` (invisibly)
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "key", "value")
#' am_commit(doc, "Add initial data")
#'
#' # Commit with specific timestamp
#' am_commit(doc, "Update", Sys.time())
#'
#' am_close(doc)
#'
am_commit <- function(doc, message = NULL, time = NULL) {
  invisible(.Call(C_am_commit, doc, message, time))
}

#' Roll back pending operations
#'
#' Cancels all pending operations in the current transaction without
#' committing them. This allows you to discard changes since the last
#' commit.
#'
#' @param doc An Automerge document
#'
#' @return The document `doc` (invisibly)
#'
#' @export
#' @examples
#' doc <- am_create()
#'
#' am_put(doc, AM_ROOT, "key", "value")
#' # Changed my mind, discard the put
#' am_rollback(doc)
#'
#' am_close(doc)
#'
am_rollback <- function(doc) {
  invisible(.Call(C_am_rollback, doc))
}

# Historical Query and Advanced Fork/Merge Functions (Phase 6) ---------------

#' Get the last change made by the local actor
#'
#' Returns the most recent change created by this document's actor.
#' Useful for tracking local changes or implementing undo/redo functionality.
#'
#' @param doc An Automerge document
#'
#' @return An `am_change` object, or `NULL` if no local changes have been made.
#'
#' @export
#' @examples
#' doc <- am_create()
#'
#' # Initially, no local changes
#' am_get_last_local_change(doc)  # NULL
#'
#' # Make a change
#' doc$key <- "value"
#' am_commit(doc, "Add key")
#'
#' # Now we have a local change
#' change <- am_get_last_local_change(doc)
#' change
#' am_change_message(change)  # "Add key"
#'
#' am_close(doc)
#'
am_get_last_local_change <- function(doc) {
  .Call(C_am_get_last_local_change, doc)
}

#' Get a specific change by its hash
#'
#' Retrieves a change from the document's history by its unique hash identifier.
#' The hash is typically obtained from `am_get_heads()` or
#' `am_change_hash()`.
#'
#' @param doc An Automerge document
#' @param hash A raw vector containing the change hash (must be exactly 32 bytes)
#'
#' @return An `am_change` object, or `NULL` if the change hash is not found
#'   in the document.
#'
#' @export
#' @examples
#' doc <- am_create()
#' doc$key <- "value"
#' am_commit(doc, "Add key")
#'
#' # Get the current heads (change hashes)
#' heads <- am_get_heads(doc)
#' head_hash <- heads[[1]]
#'
#' # Retrieve the change by its hash
#' change <- am_get_change_by_hash(doc, head_hash)
#' change
#' am_change_message(change)  # "Add key"
#'
#' am_close(doc)
#'
am_get_change_by_hash <- function(doc, hash) {
  .Call(C_am_get_change_by_hash, doc, hash)
}

#' Get changes in one document that are not in another
#'
#' Compares two documents and returns the changes that exist in `doc2`
#' but not in `doc1`. This is useful for determining what changes need to be
#' applied to bring `doc1` up to date with `doc2`, or for implementing
#' custom synchronization logic.
#'
#' @param doc1 An Automerge document (base/reference document)
#' @param doc2 An Automerge document (comparison document)
#'
#' @return A list of `am_change` objects representing changes that exist in
#'   `doc2` but not in `doc1`. Returns an empty list if `doc1` already
#'   contains all changes from `doc2`.
#'
#' @export
#' @examples
#' # Create two independent documents
#' doc1 <- am_create()
#' doc1$x <- 1
#' am_commit(doc1, "Add x")
#'
#' doc2 <- am_create()
#' doc2$y <- 2
#' am_commit(doc2, "Add y")
#'
#' # Find changes in doc2 that aren't in doc1
#' changes <- am_get_changes_added(doc1, doc2)
#' changes
#' length(changes)  # 1 change
#'
#' # Apply those changes to doc1
#' am_apply_changes(doc1, changes)
#'
#' # Now doc1 has both x and y
#' names(doc1)  # "x" "y"
#'
#' am_close(doc1)
#' am_close(doc2)
#'
am_get_changes_added <- function(doc1, doc2) {
  .Call(C_am_get_changes_added, doc1, doc2)
}

# v1.2 Document Operations ---------------------------------------------------

#' Clone an Automerge document
#'
#' Creates an independent deep copy of an Automerge document, preserving
#' the same actor ID. Changes to the clone do not affect the original,
#' and vice versa.
#'
#' Unlike [am_fork()], which assigns a new actor ID to the copy,
#' `am_clone()` preserves the original actor ID. This makes it suitable
#' for archival snapshots or checkpoints where you want an exact copy of
#' the document state. Do not use `am_clone()` to create branches that
#' will make independent edits and later be merged — use [am_fork()]
#' for that, as two documents sharing an actor ID can cause conflicts.
#'
#' @param doc An Automerge document
#'
#' @return A new Automerge document (independent copy with same actor ID)
#'
#' @seealso [am_fork()] for creating branches with a new actor ID
#' @export
#' @examples
#' doc <- am_create()
#' doc$key <- "value"
#' am_commit(doc)
#'
#' clone <- am_clone(doc)
#' clone$key  # "value"
#'
#' # Clone preserves the actor ID
#' am_get_actor_hex(doc) == am_get_actor_hex(clone) # TRUE
#'
#' # Changes to clone don't affect original
#' clone$key <- "changed"
#' doc$key  # still "value"
#'
#' am_close(doc)
#' am_close(clone)
#'
am_clone <- function(doc) {
  .Call(C_am_clone, doc)
}

#' Test document equality
#'
#' Tests whether two Automerge documents have the same content. Documents
#' are equal if they have the same set of changes applied, regardless of
#' how they were created.
#'
#' @param doc1 An Automerge document
#' @param doc2 An Automerge document
#'
#' @return A logical scalar: `TRUE` if the documents are equal, `FALSE`
#'   otherwise.
#'
#' @export
#' @examples
#' doc1 <- am_create()
#' doc1$key <- "value"
#' am_commit(doc1)
#'
#' doc2 <- am_clone(doc1)
#' am_equal(doc1, doc2)  # TRUE
#'
#' doc2$key <- "different"
#' am_equal(doc1, doc2)  # FALSE
#'
#' am_close(doc1)
#' am_close(doc2)
#'
am_equal <- function(doc1, doc2) {
  .Call(C_am_equal, doc1, doc2)
}

#' Get the number of pending operations
#'
#' Returns the number of operations that have been applied to the document
#' but not yet committed. This is useful for determining whether a commit
#' is needed.
#'
#' @param doc An Automerge document
#'
#' @return An integer indicating the number of pending operations. Returns 0
#'   if there are no uncommitted changes.
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_pending_ops(doc)  # 0
#'
#' doc$key <- "value"
#' am_pending_ops(doc)  # > 0
#'
#' am_commit(doc)
#' am_pending_ops(doc)  # 0
#'
#' am_close(doc)
#'
am_pending_ops <- function(doc) {
  .Call(C_am_pending_ops, doc)
}

#' Create an empty change
#'
#' Creates a new change in the document's history without any operations.
#' This is useful for creating merge commits or recording metadata
#' (message, timestamp) without making data changes.
#'
#' @param doc An Automerge document
#' @param message Optional commit message (character string)
#' @param time Optional timestamp (POSIXct). If `NULL`, uses current time.
#'
#' @return The document `doc` (invisibly)
#'
#' @export
#' @examples
#' doc <- am_create()
#' doc$key <- "value"
#' am_commit(doc, "Initial data")
#'
#' # Create empty change as a checkpoint
#' am_commit_empty(doc, "Checkpoint")
#'
#' am_close(doc)
#'
am_commit_empty <- function(doc, message = NULL, time = NULL) {
  invisible(.Call(C_am_commit_empty, doc, message, time))
}

#' Save incremental changes
#'
#' Serializes only the changes made since the last call to `am_save()` or
#' `am_save_incremental()`. This is more efficient than saving the entire
#' document when only a few changes have been made.
#'
#' Use [am_load_incremental()] to apply these changes to another document.
#'
#' @param doc An Automerge document
#'
#' @return A raw vector containing the incremental changes. May be empty
#'   (zero-length) if no new changes have been made since the last save.
#'
#' @seealso [am_load_incremental()], [am_save()]
#'
#' @export
#' @examples
#' doc <- am_create()
#' doc$key <- "value"
#' am_commit(doc)
#'
#' # Save full document
#' full <- am_save(doc)
#'
#' # Make more changes
#' doc$key2 <- "value2"
#' am_commit(doc)
#'
#' # Save only the new changes
#' incremental <- am_save_incremental(doc)
#' length(incremental) < length(full)  # TRUE (smaller)
#'
#' am_close(doc)
#'
am_save_incremental <- function(doc) {
  .Call(C_am_save_incremental, doc)
}

#' Load incremental changes into a document
#'
#' Applies incremental changes (from [am_save_incremental()]) to a document.
#' This is more efficient than loading a full document when only a few
#' changes need to be applied.
#'
#' @param doc An Automerge document
#' @param data A raw vector containing incremental changes (from
#'   [am_save_incremental()])
#'
#' @return The number of operations applied (numeric scalar, invisibly).
#'
#' @seealso [am_save_incremental()], [am_load()]
#'
#' @export
#' @examples
#' doc1 <- am_create()
#' doc1$key <- "value"
#' am_commit(doc1)
#' bytes <- am_save(doc1)
#'
#' doc1$key2 <- "value2"
#' am_commit(doc1)
#' incremental <- am_save_incremental(doc1)
#'
#' # Load base document and apply incremental changes
#' doc2 <- am_load(bytes)
#' am_load_incremental(doc2, incremental)
#' doc2$key2  # "value2"
#'
#' am_close(doc1)
#' am_close(doc2)
#'
am_load_incremental <- function(doc, data) {
  invisible(.Call(C_am_load_incremental, doc, data))
}
