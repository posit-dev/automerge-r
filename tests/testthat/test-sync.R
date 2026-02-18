test_that("am_sync_state creates a valid sync state", {
  sync_state <- am_sync_state()
  expect_s3_class(sync_state, "am_syncstate")
  expect_type(sync_state, "externalptr")
})

test_that("print.am_syncstate outputs expected text", {
  sync_state <- am_sync_state()
  expect_snapshot(print(sync_state))
})

test_that("am_sync_encode/decode work with empty documents", {
  doc1 <- am_create()
  doc2 <- am_create()

  sync1 <- am_sync_state()
  sync2 <- am_sync_state()

  # First message from doc1
  msg1 <- am_sync_encode(doc1, sync1)
  expect_type(msg1, "raw")
  expect_gt(length(msg1), 0)

  # Receive in doc2
  am_sync_decode(doc2, sync2, msg1)

  # doc2 responds
  msg2 <- am_sync_encode(doc2, sync2)
  if (!is.null(msg2)) {
    am_sync_decode(doc1, sync1, msg2)
  }

  # Eventually both should return NULL (no more messages)
  for (i in 1:10) {
    msg1 <- am_sync_encode(doc1, sync1)
    msg2 <- am_sync_encode(doc2, sync2)
    if (is.null(msg1) && is.null(msg2)) {
      break
    }
    if (!is.null(msg1)) {
      am_sync_decode(doc2, sync2, msg1)
    }
    if (!is.null(msg2)) am_sync_decode(doc1, sync1, msg2)
  }

  expect_null(am_sync_encode(doc1, sync1))
  expect_null(am_sync_encode(doc2, sync2))
})

test_that("am_sync_encode/decode synchronize simple changes", {
  # Create two documents with different changes
  doc1 <- am_create()
  doc2 <- am_create()

  # Make changes in doc1
  am_put(doc1, AM_ROOT, "x", 1)
  am_commit(doc1, "Add x")

  # Make changes in doc2
  am_put(doc2, AM_ROOT, "y", 2)
  am_commit(doc2, "Add y")

  # Verify they're different before sync
  expect_null(am_get(doc1, AM_ROOT, "y"))
  expect_null(am_get(doc2, AM_ROOT, "x"))

  # Create sync states
  sync1 <- am_sync_state()
  sync2 <- am_sync_state()

  # Exchange messages until convergence
  for (round in 1:20) {
    msg1 <- am_sync_encode(doc1, sync1)
    msg2 <- am_sync_encode(doc2, sync2)

    if (is.null(msg1) && is.null(msg2)) {
      break
    }

    if (!is.null(msg1)) {
      am_sync_decode(doc2, sync2, msg1)
    }
    if (!is.null(msg2)) am_sync_decode(doc1, sync1, msg2)
  }

  # Both documents should now have both x and y
  expect_equal(am_get(doc1, AM_ROOT, "x"), 1)
  expect_equal(am_get(doc1, AM_ROOT, "y"), 2)
  expect_equal(am_get(doc2, AM_ROOT, "x"), 1)
  expect_equal(am_get(doc2, AM_ROOT, "y"), 2)
})

test_that("am_sync synchronizes two documents", {
  doc1 <- am_create()
  doc2 <- am_create()

  # Make different changes in each document
  am_put(doc1, AM_ROOT, "a", 1)
  am_put(doc1, AM_ROOT, "b", 2)
  am_commit(doc1)

  am_put(doc2, AM_ROOT, "c", 3)
  am_put(doc2, AM_ROOT, "d", 4)
  am_commit(doc2)

  # Sync using high-level helper
  rounds <- am_sync(doc1, doc2)

  expect_type(rounds, "double")
  expect_gt(rounds, 0)
  expect_lte(rounds, 100)

  # Both documents should have all four keys
  expect_equal(am_get(doc1, AM_ROOT, "a"), 1)
  expect_equal(am_get(doc1, AM_ROOT, "b"), 2)
  expect_equal(am_get(doc1, AM_ROOT, "c"), 3)
  expect_equal(am_get(doc1, AM_ROOT, "d"), 4)

  expect_equal(am_get(doc2, AM_ROOT, "a"), 1)
  expect_equal(am_get(doc2, AM_ROOT, "b"), 2)
  expect_equal(am_get(doc2, AM_ROOT, "c"), 3)
  expect_equal(am_get(doc2, AM_ROOT, "d"), 4)
})

test_that("am_sync handles concurrent edits", {
  # Start with synchronized documents
  doc1 <- am_create()
  am_put(doc1, AM_ROOT, "counter", 0)
  am_commit(doc1)

  # Fork to create doc2
  doc2 <- am_fork(doc1)

  # Make concurrent changes
  am_put(doc1, AM_ROOT, "counter", 1)
  am_put(doc1, AM_ROOT, "x", "from_doc1")
  am_commit(doc1, "Doc1 update")

  am_put(doc2, AM_ROOT, "counter", 10)
  am_put(doc2, AM_ROOT, "y", "from_doc2")
  am_commit(doc2, "Doc2 update")

  # Sync them
  rounds <- am_sync(doc1, doc2)
  expect_gt(rounds, 0)


  # Both should have both x and y
  expect_equal(am_get(doc1, AM_ROOT, "x"), "from_doc1")
  expect_equal(am_get(doc1, AM_ROOT, "y"), "from_doc2")
  expect_equal(am_get(doc2, AM_ROOT, "x"), "from_doc1")
  expect_equal(am_get(doc2, AM_ROOT, "y"), "from_doc2")

  # Counter should have a conflict resolved by Automerge CRDT semantics
  # (both values exist, but one is selected as the "winner")
  counter1 <- am_get(doc1, AM_ROOT, "counter")
  counter2 <- am_get(doc2, AM_ROOT, "counter")
  expect_equal(counter1, counter2) # Should be the same in both docs
})

test_that("am_get_heads returns current document heads", {
  doc <- am_create()

  # New document should have empty heads
  heads <- am_get_heads(doc)
  expect_type(heads, "list")
  expect_equal(length(heads), 0)

  # Make a change and commit
  am_put(doc, AM_ROOT, "x", 1)
  am_commit(doc)

  heads <- am_get_heads(doc)
  expect_equal(length(heads), 1)
  expect_type(heads[[1]], "raw")
  expect_gt(length(heads[[1]]), 0)

  # Make another change
  am_put(doc, AM_ROOT, "y", 2)
  am_commit(doc)

  heads2 <- am_get_heads(doc)
  expect_equal(length(heads2), 1)
  # Heads should have changed
  expect_false(identical(heads[[1]], heads2[[1]]))
})

test_that("am_get_changes returns document history", {
  doc <- am_create()

  # No changes initially
  changes <- am_get_changes(doc, NULL)
  expect_type(changes, "list")
  expect_equal(length(changes), 0)

  # Make some changes
  am_put(doc, AM_ROOT, "x", 1)
  am_commit(doc, "First change")

  am_put(doc, AM_ROOT, "y", 2)
  am_commit(doc, "Second change")

  am_put(doc, AM_ROOT, "z", 3)
  am_commit(doc, "Third change")

  # Get all changes
  changes <- am_get_changes(doc, NULL)
  expect_equal(length(changes), 3)

  # Each change should be an am_change object
  for (change in changes) {
    expect_s3_class(change, "am_change")
  }
})

test_that("am_apply_changes applies changes to a document", {
  # Create a document with changes
  doc1 <- am_create()
  am_put(doc1, AM_ROOT, "a", 1)
  am_put(doc1, AM_ROOT, "b", 2)
  am_commit(doc1)

  am_put(doc1, AM_ROOT, "c", 3)
  am_commit(doc1)

  # Get all changes
  changes <- am_get_changes(doc1, NULL)
  expect_gt(length(changes), 0)

  # Create a new document and apply changes
  doc2 <- am_create()
  am_apply_changes(doc2, changes)

  # doc2 should now have the same data as doc1
  expect_equal(am_get(doc2, AM_ROOT, "a"), 1)
  expect_equal(am_get(doc2, AM_ROOT, "b"), 2)
  expect_equal(am_get(doc2, AM_ROOT, "c"), 3)
})

test_that("am_get_changes returns full change history", {
  doc <- am_create()

  am_put(doc, AM_ROOT, "v1", "first")
  am_commit(doc, "Version 1")

  am_put(doc, AM_ROOT, "v2", "second")
  am_commit(doc, "Version 2")

  am_put(doc, AM_ROOT, "v3", "third")
  am_commit(doc, "Version 3")

  history <- am_get_changes(doc)
  expect_type(history, "list")
  expect_equal(length(history), 3)

  # Each history entry should be an am_change object
  for (entry in history) {
    expect_s3_class(entry, "am_change")
  }
})

test_that("sync works with nested objects", {
  doc1 <- am_create()
  doc2 <- am_create()

  # Create nested structure in doc1
  am_put(doc1, AM_ROOT, "config", AM_OBJ_TYPE_MAP)
  map <- am_get(doc1, AM_ROOT, "config")
  am_put(doc1, map, "host", "localhost")
  am_put(doc1, map, "port", 8080)
  am_commit(doc1, "Add config")

  # Create different structure in doc2
  am_put(doc2, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
  list <- am_get(doc2, AM_ROOT, "items")
  am_insert(doc2, list, 1, "first")
  am_insert(doc2, list, 2, "second")
  am_commit(doc2, "Add items")

  # Sync
  rounds <- am_sync(doc1, doc2)
  expect_gt(rounds, 0)

  # Both should have both structures
  config1 <- am_get(doc1, AM_ROOT, "config")
  expect_s3_class(config1, "am_object")
  expect_equal(am_get(doc1, config1, "host"), "localhost")

  items1 <- am_get(doc1, AM_ROOT, "items")
  expect_s3_class(items1, "am_object")
  expect_equal(am_length(doc1, items1), 2)

  config2 <- am_get(doc2, AM_ROOT, "config")
  expect_s3_class(config2, "am_object")

  items2 <- am_get(doc2, AM_ROOT, "items")
  expect_s3_class(items2, "am_object")
})

test_that("sync protocol errors are handled gracefully", {
  doc <- am_create()
  sync_state <- am_sync_state()

  # Try to decode invalid sync message
  invalid_msg <- raw(10) # Random bytes
  expect_error(
    am_sync_decode(doc, sync_state, invalid_msg),
    "Automerge error|expected|found"
  )

  # Verify document and sync state are still valid after error
  msg <- am_sync_encode(doc, sync_state)
  expect_true(is.raw(msg) || is.null(msg))
})

test_that("sync state is document-independent", {
  # Create multiple documents
  doc1 <- am_create()
  doc2 <- am_create()
  doc3 <- am_create()

  # Single sync state can be used with different documents
  sync_state <- am_sync_state()

  # Use it with doc1
  msg1 <- am_sync_encode(doc1, sync_state)
  expect_true(is.raw(msg1) || is.null(msg1))

  # Use same sync state with doc2 (though this is unusual)
  msg2 <- am_sync_encode(doc2, sync_state)
  expect_true(is.raw(msg2) || is.null(msg2))
})

test_that("am_apply_changes handles empty change list", {
  doc <- am_create()

  # Apply empty changes list
  am_apply_changes(doc, list())

  # Document should still be valid
  am_put(doc, AM_ROOT, "x", 1)
  expect_equal(am_get(doc, AM_ROOT, "x"), 1)
})

test_that("sync works with text objects", {
  doc1 <- am_create()
  doc2 <- am_create()

  # Create text in doc1
  am_put(doc1, AM_ROOT, "notes", AM_OBJ_TYPE_TEXT)
  text1 <- am_get(doc1, AM_ROOT, "notes")
  am_text_splice(text1, 0, 0, "Hello from doc1")
  am_commit(doc1)

  # Create text in doc2
  am_put(doc2, AM_ROOT, "greet", AM_OBJ_TYPE_TEXT)
  text2 <- am_get(doc2, AM_ROOT, "greet")
  am_text_splice(text2, 0, 0, "Hi from doc2")
  am_commit(doc2)

  # Sync
  rounds <- am_sync(doc1, doc2)
  expect_gt(rounds, 0)

  # Both should have both text objects
  notes1 <- am_get(doc1, AM_ROOT, "notes")
  greet1 <- am_get(doc1, AM_ROOT, "greet")
  expect_equal(am_text_content(notes1), "Hello from doc1")
  expect_equal(am_text_content(greet1), "Hi from doc2")

  notes2 <- am_get(doc2, AM_ROOT, "notes")
  greet2 <- am_get(doc2, AM_ROOT, "greet")
  expect_equal(am_text_content(notes2), "Hello from doc1")
  expect_equal(am_text_content(greet2), "Hi from doc2")
})

test_that("am_get_changes with specific heads", {
  doc <- am_create()

  # Make first change
  am_put(doc, AM_ROOT, "x", 1)
  am_commit(doc, "First")
  heads1 <- am_get_heads(doc)

  # Make second change
  am_put(doc, AM_ROOT, "y", 2)
  am_commit(doc, "Second")

  # Make third change
  am_put(doc, AM_ROOT, "z", 3)
  am_commit(doc, "Third")

  # Get changes since heads1 (should get changes 2 and 3)
  changes_since <- am_get_changes(doc, heads1)
  expect_type(changes_since, "list")
  expect_equal(length(changes_since), 2)

  # Returned am_change objects (borrowed from parent result) are introspectable
  expect_s3_class(changes_since[[1]], "am_change")
  expect_s3_class(changes_since[[2]], "am_change")
  expect_equal(am_change_message(changes_since[[1]]), "Second")
  expect_equal(am_change_message(changes_since[[2]]), "Third")
})

test_that("am_get_changes with multiple explicit heads errors", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "x", 1)
  am_commit(doc, "First")
  am_put(doc, AM_ROOT, "y", 2)
  am_commit(doc, "Second")

  # Construct a list of 2 heads from history hashes
  history <- am_get_changes(doc)
  two_heads <- list(am_change_hash(history[[1]]), am_change_hash(history[[2]]))

  expect_error(
    am_get_changes(doc, two_heads),
    "multiple heads are not supported"
  )
})

test_that("am_get_changes with empty heads list returns all changes", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "x", 1)
  am_commit(doc, "First")
  am_put(doc, AM_ROOT, "y", 2)
  am_commit(doc, "Second")

  changes <- am_get_changes(doc, list())
  expect_type(changes, "list")

  all_changes <- am_get_changes(doc, NULL)
  expect_equal(length(changes), length(all_changes))
})

test_that("am_get_changes with multiple heads errors", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "x", 1)
  am_commit(doc, "First")

  doc2 <- am_fork(doc)
  am_put(doc, AM_ROOT, "y", 2)
  am_commit(doc, "doc1 edit")
  am_put(doc2, AM_ROOT, "z", 3)
  am_commit(doc2, "doc2 edit")

  am_merge(doc, doc2)
  heads <- am_get_heads(doc)
  expect_true(length(heads) >= 2)

  expect_error(
    am_get_changes(doc, heads),
    "multiple heads are not supported"
  )
})

test_that("am_get_changes_added returns added changes", {
  doc1 <- am_create()
  am_put(doc1, AM_ROOT, "x", 1)
  am_commit(doc1)

  # Fork and make independent changes
  doc2 <- am_fork(doc1)

  am_put(doc2, AM_ROOT, "y", 2)
  am_commit(doc2)

  am_put(doc2, AM_ROOT, "z", 3)
  am_commit(doc2)

  # Get what was added to doc2 since the fork
  # am_get_changes_added(doc1, doc2) returns changes in doc2 not in doc1
  added <- am_get_changes_added(doc1, doc2)
  expect_type(added, "list")
  expect_equal(length(added), 2) # Two commits in doc2
})

# v1.2 Sync/Change Operations Tests -------------------------------------------

# am_get_missing_deps tests

test_that("am_get_missing_deps() returns empty for complete doc", {
  doc <- am_create()
  doc$key <- "value"
  am_commit(doc)

  missing <- am_get_missing_deps(doc)
  expect_type(missing, "list")
  expect_length(missing, 0)
})

test_that("am_get_missing_deps() with specific heads", {
  doc <- am_create()
  doc$key <- "value"
  am_commit(doc)

  heads <- am_get_heads(doc)
  missing <- am_get_missing_deps(doc, heads)
  expect_type(missing, "list")
  expect_length(missing, 0)
})

# am_load_changes tests

test_that("am_load_changes() decomposes document", {
  doc <- am_create()
  doc$key1 <- "value1"
  am_commit(doc, "First")
  doc$key2 <- "value2"
  am_commit(doc, "Second")
  bytes <- am_save(doc)

  changes <- am_load_changes(bytes)
  expect_type(changes, "list")
  expect_length(changes, 2)
  expect_s3_class(changes[[1]], "am_change")
  expect_s3_class(changes[[2]], "am_change")
  expect_equal(am_change_message(changes[[1]]), "First")
  expect_equal(am_change_message(changes[[2]]), "Second")
})

test_that("am_load_changes() changes can be applied", {
  doc1 <- am_create()
  doc1$x <- 1
  am_commit(doc1, "Add x")
  doc1$y <- 2
  am_commit(doc1, "Add y")
  bytes <- am_save(doc1)

  changes <- am_load_changes(bytes)

  doc2 <- am_create()
  am_apply_changes(doc2, changes)
  expect_equal(am_get(doc2, AM_ROOT, "x"), 1)
  expect_equal(am_get(doc2, AM_ROOT, "y"), 2)
})

test_that("am_load_changes() errors on non-raw", {
  expect_error(am_load_changes("not raw"), "data must be a raw vector")
})

test_that("am_load_changes() on empty doc", {
  doc <- am_create()
  bytes <- am_save(doc)

  changes <- am_load_changes(bytes)
  expect_type(changes, "list")
  expect_length(changes, 0)
})

# am_sync_state_encode / am_sync_state_decode tests

test_that("am_sync_state_encode() returns raw bytes", {
  sync <- am_sync_state()
  bytes <- am_sync_state_encode(sync)
  expect_type(bytes, "raw")
  expect_gt(length(bytes), 0)
})

test_that("am_sync_state_decode() restores sync state", {
  sync <- am_sync_state()
  bytes <- am_sync_state_encode(sync)

  restored <- am_sync_state_decode(bytes)
  expect_s3_class(restored, "am_syncstate")
})

test_that("sync state round-trip works with active sync", {
  doc1 <- am_create()
  doc1$key <- "value"
  am_commit(doc1)

  doc2 <- am_create()

  sync1 <- am_sync_state()
  sync2 <- am_sync_state()

  msg <- am_sync_encode(doc1, sync1)
  am_sync_decode(doc2, sync2, msg)

  # Encode and restore sync1
  bytes <- am_sync_state_encode(sync1)
  sync1_restored <- am_sync_state_decode(bytes)
  expect_s3_class(sync1_restored, "am_syncstate")
})

test_that("am_sync_state_decode() errors on non-raw", {
  expect_error(am_sync_state_decode("not raw"), "data must be a raw vector")
})

# Additional am_get_missing_deps tests

test_that("am_get_missing_deps() on empty doc returns empty", {
  doc <- am_create()
  missing <- am_get_missing_deps(doc)
  expect_type(missing, "list")
  expect_length(missing, 0)
})

test_that("am_get_missing_deps() with NULL heads same as default", {
  doc <- am_create()
  doc$key <- "value"
  am_commit(doc)

  missing_default <- am_get_missing_deps(doc)
  missing_null <- am_get_missing_deps(doc, NULL)
  expect_equal(missing_default, missing_null)
})

test_that("am_get_missing_deps() after sync returns empty", {
  doc1 <- am_create()
  doc1$x <- 1
  am_commit(doc1)

  doc2 <- am_fork(doc1)
  doc2$y <- 2
  am_commit(doc2)

  am_merge(doc1, doc2)

  missing <- am_get_missing_deps(doc1)
  expect_length(missing, 0)
})

# Additional am_load_changes tests

test_that("am_load_changes() preserves change metadata", {
  doc <- am_create()
  doc$key <- "value"
  ts <- as.POSIXct("2025-06-15 12:00:00", tz = "UTC")
  am_commit(doc, "Test message", ts)
  bytes <- am_save(doc)

  changes <- am_load_changes(bytes)
  expect_length(changes, 1)
  expect_equal(am_change_message(changes[[1]]), "Test message")
  expect_equal(am_change_actor_id(changes[[1]]), am_get_actor(doc))
  expect_equal(am_change_seq(changes[[1]]), 1L)
})

test_that("am_load_changes() with nested structures", {
  doc <- am_create()
  doc$config <- list(host = "localhost", port = 8080L)
  doc$items <- am_list("a", "b", "c")
  am_commit(doc, "Add nested")
  bytes <- am_save(doc)

  changes <- am_load_changes(bytes)
  expect_length(changes, 1)

  # Apply to new doc and verify structure
  doc2 <- am_create()
  am_apply_changes(doc2, changes)
  config <- am_get(doc2, AM_ROOT, "config")
  expect_equal(am_get(doc2, config, "host"), "localhost")
  items <- am_get(doc2, AM_ROOT, "items")
  expect_equal(am_length(doc2, items), 3)
})

test_that("am_load_changes() errors on invalid bytes", {
  expect_error(am_load_changes(raw(10)))
})

test_that("am_load_changes() preserves change dependencies", {
  doc <- am_create()
  doc$a <- 1
  am_commit(doc, "First")
  doc$b <- 2
  am_commit(doc, "Second")
  doc$c <- 3
  am_commit(doc, "Third")
  bytes <- am_save(doc)

  changes <- am_load_changes(bytes)
  expect_length(changes, 3)

  # First change has no deps, subsequent changes have deps
  deps1 <- am_change_deps(changes[[1]])
  expect_length(deps1, 0)

  deps2 <- am_change_deps(changes[[2]])
  expect_length(deps2, 1)
  expect_equal(deps2[[1]], am_change_hash(changes[[1]]))
})

test_that("am_load_changes() selective apply works", {
  doc <- am_create()
  doc$a <- 1
  am_commit(doc, "First")
  doc$b <- 2
  am_commit(doc, "Second")
  doc$c <- 3
  am_commit(doc, "Third")
  bytes <- am_save(doc)

  changes <- am_load_changes(bytes)

  # Apply only the first change
  doc2 <- am_create()
  am_apply_changes(doc2, changes[1])
  expect_equal(am_get(doc2, AM_ROOT, "a"), 1)
  expect_null(am_get(doc2, AM_ROOT, "b"))
})

# Additional am_sync_state_encode/decode tests

test_that("sync state round-trip preserves sync progress", {
  doc1 <- am_create()
  doc1$x <- 1
  am_commit(doc1)

  doc2 <- am_create()

  sync1 <- am_sync_state()
  sync2 <- am_sync_state()

  # Complete a sync
  am_sync(doc1, doc2)

  # Now make a new change in doc1
  doc1$y <- 2
  am_commit(doc1)

  # Start syncing with fresh states

  sync1 <- am_sync_state()
  sync2 <- am_sync_state()

  # Do first round of sync
  msg1 <- am_sync_encode(doc1, sync1)
  am_sync_decode(doc2, sync2, msg1)

  # Serialize and restore sync states
  bytes1 <- am_sync_state_encode(sync1)
  bytes2 <- am_sync_state_encode(sync2)
  sync1_restored <- am_sync_state_decode(bytes1)
  sync2_restored <- am_sync_state_decode(bytes2)

  # Continue syncing with restored states
  msg2 <- am_sync_encode(doc2, sync2_restored)
  if (!is.null(msg2)) {
    am_sync_decode(doc1, sync1_restored, msg2)
  }

  # Complete the sync
  for (i in 1:10) {
    msg_a <- am_sync_encode(doc1, sync1_restored)
    msg_b <- am_sync_encode(doc2, sync2_restored)
    if (is.null(msg_a) && is.null(msg_b)) break
    if (!is.null(msg_a)) am_sync_decode(doc2, sync2_restored, msg_a)
    if (!is.null(msg_b)) am_sync_decode(doc1, sync1_restored, msg_b)
  }

  expect_equal(am_get(doc2, AM_ROOT, "x"), 1)
  expect_equal(am_get(doc2, AM_ROOT, "y"), 2)
})

test_that("am_sync_state_encode() on fresh state has consistent output", {
  sync1 <- am_sync_state()
  sync2 <- am_sync_state()

  bytes1 <- am_sync_state_encode(sync1)
  bytes2 <- am_sync_state_encode(sync2)

  # Fresh sync states should produce identical encodings
  expect_equal(bytes1, bytes2)
})

test_that("am_sync_state_decode() errors on invalid bytes", {
  expect_error(am_sync_state_decode(raw(3)))
})

# Coverage Tests: Input Validation and Edge Cases =============================

# am_get_missing_deps with multiple heads error

test_that("am_get_missing_deps() errors on multiple heads", {
  doc <- am_create()
  doc$x <- 1
  am_commit(doc)

  doc2 <- am_fork(doc)
  doc$y <- 2
  am_commit(doc)
  doc2$z <- 3
  am_commit(doc2)
  am_merge(doc, doc2)

  heads <- am_get_heads(doc)
  expect_gte(length(heads), 2)
  expect_error(
    am_get_missing_deps(doc, heads),
    "multiple heads"
  )
})

# am_sync_encode/decode input validation

test_that("am_sync_decode() errors on non-raw message", {
  doc <- am_create()
  sync <- am_sync_state()
  expect_error(am_sync_decode(doc, sync, "not raw"), "raw vector")
})

# am_apply_changes input validation

test_that("am_apply_changes() errors on non-list", {
  doc <- am_create()
  expect_error(am_apply_changes(doc, "not a list"), "list")
})

# am_get_changes with empty doc returns empty

test_that("am_get_changes() on empty doc returns empty list", {
  doc <- am_create()
  changes <- am_get_changes(doc, NULL)
  expect_type(changes, "list")
  expect_length(changes, 0)
})

# am_get_heads on document with concurrent edits returns multiple heads

test_that("am_get_heads() returns multiple heads after merge without commit", {
  doc <- am_create()
  doc$x <- 1
  am_commit(doc)

  doc2 <- am_fork(doc)
  doc$y <- 2
  am_commit(doc)
  doc2$z <- 3
  am_commit(doc2)

  am_merge(doc, doc2)

  heads <- am_get_heads(doc)
  expect_equal(length(heads), 2)
  expect_type(heads[[1]], "raw")
  expect_type(heads[[2]], "raw")
})

# am_get_missing_deps with empty heads list

test_that("am_get_missing_deps() with empty heads list same as NULL", {
  doc <- am_create()
  doc$key <- "value"
  am_commit(doc)

  missing_null <- am_get_missing_deps(doc, NULL)
  missing_empty <- am_get_missing_deps(doc, list())
  expect_equal(missing_null, missing_empty)
})

# am_get_missing_deps returning actual missing deps

test_that("am_get_missing_deps() detects missing deps from unknown heads", {
  doc1 <- am_create()
  doc1$a <- 1
  am_commit(doc1)
  heads1 <- am_get_heads(doc1)

  # Empty doc doesn't have the changes
  doc2 <- am_create()
  missing <- am_get_missing_deps(doc2, heads1)
  expect_gte(length(missing), 1)
  expect_type(missing[[1]], "raw")
})

# am_get_changes with heads parameter

test_that("am_get_changes() with empty heads list", {
  doc <- am_create()
  doc$a <- 1
  am_commit(doc)
  doc$b <- 2
  am_commit(doc)

  # Empty heads list should return all changes
  changes <- am_get_changes(doc, list())
  expect_gte(length(changes), 2)
})
