# Document Lifecycle Tests (Phase 2)

test_that("am_close() returns NULL invisibly", {
  doc <- am_create()
  result <- am_close(doc)
  expect_null(result)
})

test_that("am_close() can be called twice (idempotent)", {
  doc <- am_create()
  expect_no_error(am_close(doc))
  expect_no_error(am_close(doc))
})

test_that("document operations error after am_close()", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_close(doc)

  expect_error(am_get(doc, AM_ROOT, "key"))
  expect_error(am_save(doc))
  expect_error(am_fork(doc))
})

test_that("am_create() creates a valid document", {
  doc <- am_create()
  expect_s3_class(doc, "am_doc")
  expect_s3_class(doc, "automerge")
})

test_that("am_create() works with NULL actor_id", {
  doc <- am_create(NULL)
  expect_s3_class(doc, "am_doc")
  actor <- am_get_actor(doc)
  expect_type(actor, "raw")
  expect_true(length(actor) > 0)
})

test_that("am_create() works with hex string actor_id", {
  # Create with specific hex actor ID (32 hex chars = 16 bytes)
  hex_id <- paste0(rep("0", 32), collapse = "")
  doc <- am_create(hex_id)
  expect_s3_class(doc, "am_doc")
})

test_that("am_create() works with raw bytes actor_id", {
  # Create with 16 byte actor ID
  actor_bytes <- as.raw(1:16)
  doc <- am_create(actor_bytes)
  expect_s3_class(doc, "am_doc")

  # Verify actor ID was set correctly
  retrieved_actor <- am_get_actor(doc)
  expect_equal(retrieved_actor, actor_bytes)
})

test_that("am_create() errors on invalid actor_id", {
  expect_error(am_create(123), "actor_id must be NULL")
  expect_error(am_create(list()), "actor_id must be NULL")
})

test_that("am_save() returns raw bytes", {
  doc <- am_create()
  bytes <- am_save(doc)
  expect_type(bytes, "raw")
  expect_true(length(bytes) > 0)
})

test_that("am_load() restores a saved document", {
  doc1 <- am_create()
  bytes <- am_save(doc1)

  doc2 <- am_load(bytes)
  expect_s3_class(doc2, "am_doc")
})

test_that("am_load() errors on non-raw input", {
  expect_error(am_load("not raw"), "data must be a raw vector")
  expect_error(am_load(123), "data must be a raw vector")
})

test_that("am_fork() creates independent copy", {
  doc1 <- am_create()
  doc2 <- am_fork(doc1)

  expect_s3_class(doc2, "am_doc")
  # doc1 and doc2 should be different external pointers
  expect_false(identical(doc1, doc2))
})

test_that("am_merge() combines documents", {
  doc1 <- am_create()
  doc2 <- am_create()

  # Merge doc2 into doc1
  result <- am_merge(doc1, doc2)
  expect_identical(result, doc1) # Should return doc1
})

test_that("am_get_actor() returns raw bytes", {
  doc <- am_create()
  actor <- am_get_actor(doc)

  expect_type(actor, "raw")
  expect_true(length(actor) > 0)

  # Can display as hex
  hex_str <- paste(format(actor, width = 2), collapse = "")
  expect_type(hex_str, "character")
  expect_true(nchar(hex_str) > 0)
})

test_that("am_set_actor() changes actor ID", {
  doc <- am_create()
  original_actor <- am_get_actor(doc)

  # Set new random actor ID
  am_set_actor(doc, NULL)
  new_actor <- am_get_actor(doc)

  expect_type(new_actor, "raw")
  # New actor should be different (almost certainly)
  expect_false(identical(original_actor, new_actor))
})

test_that("am_set_actor() works with hex string", {
  doc <- am_create()
  hex_id <- paste0(rep("0", 32), collapse = "")

  am_set_actor(doc, hex_id)
  actor <- am_get_actor(doc)

  expect_type(actor, "raw")
  expect_equal(length(actor), 16)
})

test_that("am_set_actor() works with raw bytes", {
  doc <- am_create()
  new_actor_bytes <- as.raw(seq(16, 1, -1)) # 16 bytes in reverse

  am_set_actor(doc, new_actor_bytes)
  retrieved_actor <- am_get_actor(doc)

  expect_equal(retrieved_actor, new_actor_bytes)
})

test_that("am_get_actor_hex() returns hex string", {
  doc <- am_create()
  actor_hex <- am_get_actor_hex(doc)

  expect_type(actor_hex, "character")
  expect_equal(length(actor_hex), 1)
  expect_true(nchar(actor_hex) > 0)
  expect_match(actor_hex, "^[0-9a-f]+$")
})

test_that("am_get_actor_hex() matches am_get_actor() conversion", {
  doc <- am_create()
  actor_raw <- am_get_actor(doc)
  actor_hex <- am_get_actor_hex(doc)

  manual_hex <- paste(format(actor_raw, width = 2), collapse = "")
  expect_equal(actor_hex, manual_hex)
})

test_that("am_get_actor_hex() works with custom actor ID", {
  doc <- am_create()
  custom_hex <- "0123456789abcdef0123456789abcdef"
  am_set_actor(doc, custom_hex)

  retrieved_hex <- am_get_actor_hex(doc)
  expect_equal(retrieved_hex, custom_hex)
})

test_that("am_commit() works with no arguments", {
  doc <- am_create()
  result <- am_commit(doc)
  expect_identical(result, doc) # Returns doc invisibly
})

test_that("am_commit() works with message", {
  doc <- am_create()
  result <- am_commit(doc, "Test commit message")
  expect_identical(result, doc)
})

test_that("am_commit() works with message and time", {
  doc <- am_create()
  timestamp <- Sys.time()
  result <- am_commit(doc, "Commit with timestamp", timestamp)
  expect_identical(result, doc)
})

test_that("am_commit() errors on invalid message", {
  doc <- am_create()
  expect_error(am_commit(doc, 123), "message must be NULL")
  expect_error(am_commit(doc, c("a", "b")), "message must be NULL")
})

test_that("am_commit() errors on invalid time", {
  doc <- am_create()
  expect_error(am_commit(doc, NULL, "not a time"), "time must be NULL")
  expect_error(am_commit(doc, NULL, 12345), "time must be NULL")
})

test_that("am_rollback() works", {
  doc <- am_create()
  result <- am_rollback(doc)
  expect_identical(result, doc) # Returns doc invisibly
})

test_that("Document lifecycle integration test", {
  # Create document
  doc1 <- am_create()

  # Commit some changes (even though we haven't added data yet)
  am_commit(doc1, "Initial commit")

  # Save to bytes
  bytes <- am_save(doc1)
  expect_type(bytes, "raw")

  # Load from bytes
  doc2 <- am_load(bytes)
  expect_s3_class(doc2, "am_doc")

  # Fork the document
  doc3 <- am_fork(doc2)
  expect_s3_class(doc3, "am_doc")

  # Merge (even though they're identical)
  am_merge(doc1, doc3)

  # All operations succeeded without error
  expect_true(TRUE)
})

test_that("Actor ID round-trip works", {
  doc1 <- am_create()
  actor1 <- am_get_actor(doc1)

  # Create new document with same actor
  doc2 <- am_create(actor1)
  actor2 <- am_get_actor(doc2)

  expect_equal(actor1, actor2)
})

# Edge Cases ------------------------------------------------------------------

test_that("am_commit without changes succeeds", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc, "First commit")

  expect_no_error(am_commit(doc, "Second commit without changes"))
})

test_that("am_commit with empty message", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc, "")

  expect_equal(am_get(doc, AM_ROOT, "key"), "value")
})

test_that("am_commit with very long message", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")

  long_message <- paste(rep("Long message text. ", 500), collapse = "")
  am_commit(doc, long_message)

  expect_equal(am_get(doc, AM_ROOT, "key"), "value")
})

test_that("am_commit with special characters in message", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")

  special_message <- "Commit\nwith\ttabs\rand\nnewlines\r\n"
  am_commit(doc, special_message)

  expect_equal(am_get(doc, AM_ROOT, "key"), "value")
})

test_that("am_commit with UTF-8 message", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")

  utf8_message <- "提交消息 🎉 Mensaje de confirmación"
  am_commit(doc, utf8_message)

  expect_equal(am_get(doc, AM_ROOT, "key"), "value")
})

test_that("am_merge with same document", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc)

  expect_no_error(am_merge(doc, doc))
  expect_equal(am_get(doc, AM_ROOT, "key"), "value")
})

test_that("am_merge with unrelated documents", {
  doc1 <- am_create()
  am_put(doc1, AM_ROOT, "key1", "value1")
  am_commit(doc1)

  doc2 <- am_create()
  am_put(doc2, AM_ROOT, "key2", "value2")
  am_commit(doc2)

  am_merge(doc1, doc2)

  expect_equal(am_get(doc1, AM_ROOT, "key1"), "value1")
  expect_equal(am_get(doc1, AM_ROOT, "key2"), "value2")
})

test_that("am_merge handles concurrent changes to same key", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "original")
  am_commit(doc)

  doc1 <- am_fork(doc)
  doc2 <- am_fork(doc)

  am_put(doc1, AM_ROOT, "key", "change1")
  am_commit(doc1)

  am_put(doc2, AM_ROOT, "key", "change2")
  am_commit(doc2)

  am_merge(doc1, doc2)

  result <- am_get(doc1, AM_ROOT, "key")
  expect_true(result %in% c("change1", "change2"))
})

test_that("am_fork preserves all data", {
  doc1 <- am_create()
  am_put(doc1, AM_ROOT, "key1", "value1")
  am_put(doc1, AM_ROOT, "key2", list(nested = "data"))
  am_commit(doc1, "Initial data")

  doc2 <- am_fork(doc1)

  expect_equal(am_get(doc2, AM_ROOT, "key1"), "value1")

  nested <- am_get(doc2, AM_ROOT, "key2")
  expect_s3_class(nested, "am_object")
  expect_equal(am_get(doc2, nested, "nested"), "data")
})

test_that("am_save on empty document", {
  doc <- am_create()
  bytes <- am_save(doc)

  expect_type(bytes, "raw")
  expect_true(length(bytes) > 0)

  doc2 <- am_load(bytes)
  expect_s3_class(doc2, "am_doc")
  expect_equal(am_length(doc2, AM_ROOT), 0)
})

test_that("am_save/load preserves complex structure", {
  doc1 <- am_create()
  doc1$users <- am_list(
    list(name = "Alice", age = 30L),
    list(name = "Bob", age = 25L)
  )
  doc1$metadata <- list(
    version = "1.0",
    created = Sys.time()
  )

  bytes <- am_save(doc1)
  doc2 <- am_load(bytes)

  users <- doc2$users
  expect_equal(users[[1]]$name, "Alice")
  expect_equal(users[[2]]$name, "Bob")

  metadata <- doc2$metadata
  expect_equal(metadata$version, "1.0")
})

test_that("am_rollback clears uncommitted changes", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key1", "value1")
  am_commit(doc)

  am_put(doc, AM_ROOT, "key2", "value2")
  expect_equal(am_get(doc, AM_ROOT, "key2"), "value2")

  am_rollback(doc)

  expect_null(am_get(doc, AM_ROOT, "key2"))
  expect_equal(am_get(doc, AM_ROOT, "key1"), "value1")
})

test_that("am_rollback on empty transaction", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc)

  expect_no_error(am_rollback(doc))
  expect_equal(am_get(doc, AM_ROOT, "key"), "value")
})

test_that("multiple consecutive commits", {
  doc <- am_create()

  am_put(doc, AM_ROOT, "key1", "value1")
  am_commit(doc, "Commit 1")

  am_put(doc, AM_ROOT, "key2", "value2")
  am_commit(doc, "Commit 2")

  am_put(doc, AM_ROOT, "key3", "value3")
  am_commit(doc, "Commit 3")

  expect_equal(am_get(doc, AM_ROOT, "key1"), "value1")
  expect_equal(am_get(doc, AM_ROOT, "key2"), "value2")
  expect_equal(am_get(doc, AM_ROOT, "key3"), "value3")
})

test_that("am_set_actor changes actor ID", {
  doc <- am_create()
  original_actor <- am_get_actor(doc)

  new_actor <- as.raw(rep(0xFF, 16))
  am_set_actor(doc, new_actor)

  current_actor <- am_get_actor(doc)
  expect_equal(current_actor, new_actor)
  expect_false(identical(current_actor, original_actor))
})

test_that("am_get_actor returns consistent format", {
  doc1 <- am_create()
  actor1 <- am_get_actor(doc1)

  expect_type(actor1, "raw")
  expect_equal(length(actor1), 16)

  doc2 <- am_create(actor1)
  actor2 <- am_get_actor(doc2)

  expect_identical(actor1, actor2)
})

test_that("documents with different actors can merge", {
  doc1 <- am_create()
  am_put(doc1, AM_ROOT, "from", "doc1")
  am_commit(doc1)

  doc2 <- am_create()
  am_put(doc2, AM_ROOT, "from", "doc2")
  am_commit(doc2)

  actor1 <- am_get_actor(doc1)
  actor2 <- am_get_actor(doc2)
  expect_false(identical(actor1, actor2))

  am_merge(doc1, doc2)

  expect_true(am_get(doc1, AM_ROOT, "from") %in% c("doc1", "doc2"))
})

# Historical Query Tests (Phase 6) --------------------------------------------

test_that("am_get_last_local_change() returns NULL for new document", {
  doc <- am_create()
  change <- am_get_last_local_change(doc)
  expect_null(change)
})

test_that("am_get_last_local_change() returns am_change after commit", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc, "Add key")

  change <- am_get_last_local_change(doc)
  expect_s3_class(change, "am_change")
  expect_equal(am_change_message(change), "Add key")
})

test_that("am_get_last_local_change() returns most recent change", {
  doc <- am_create()

  am_put(doc, AM_ROOT, "key1", "value1")
  am_commit(doc, "First commit")
  change1 <- am_get_last_local_change(doc)

  am_put(doc, AM_ROOT, "key2", "value2")
  am_commit(doc, "Second commit")
  change2 <- am_get_last_local_change(doc)

  expect_s3_class(change1, "am_change")
  expect_s3_class(change2, "am_change")
  expect_equal(am_change_message(change1), "First commit")
  expect_equal(am_change_message(change2), "Second commit")
})

test_that("am_get_change_by_hash() retrieves existing change", {
  doc <- am_create()
  doc$key <- "value"
  am_commit(doc, "Add key")

  heads <- am_get_heads(doc)
  expect_length(heads, 1)

  change <- am_get_change_by_hash(doc, heads[[1]])
  expect_s3_class(change, "am_change")
  expect_equal(am_change_message(change), "Add key")
})

test_that("am_get_change_by_hash() returns NULL for non-existent hash", {
  doc <- am_create()
  doc$key <- "value"
  am_commit(doc)

  fake_hash <- as.raw(rep(0xFF, 32))
  change <- am_get_change_by_hash(doc, fake_hash)
  expect_null(change)
})

test_that("am_get_change_by_hash() errors on invalid hash length", {
  doc <- am_create()
  doc$key <- "value"
  am_commit(doc)

  expect_error(
    am_get_change_by_hash(doc, as.raw(1:10)),
    "Change hash must be exactly 32 bytes"
  )
})

test_that("am_get_change_by_hash() errors on non-raw hash", {
  doc <- am_create()
  expect_error(
    am_get_change_by_hash(doc, "not a raw vector"),
    "hash must be a raw vector"
  )
})

test_that("am_get_changes_added() returns empty list for identical documents", {
  doc1 <- am_create()
  doc1$key <- "value"
  am_commit(doc1)

  doc2 <- am_fork(doc1)

  changes <- am_get_changes_added(doc1, doc2)
  expect_type(changes, "list")
  expect_length(changes, 0)
})

test_that("am_get_changes_added() finds new changes in doc2", {
  doc1 <- am_create()
  doc1$x <- 1
  am_commit(doc1, "Add x")

  doc2 <- am_create()
  doc2$y <- 2
  am_commit(doc2, "Add y")

  changes <- am_get_changes_added(doc1, doc2)
  expect_type(changes, "list")
  expect_length(changes, 1)
  expect_s3_class(changes[[1]], "am_change")
})

test_that("am_get_changes_added() can sync documents", {
  doc1 <- am_create()
  doc1$from_doc1 <- "value1"
  am_commit(doc1)

  doc2 <- am_create()
  doc2$from_doc2 <- "value2"
  am_commit(doc2)

  changes <- am_get_changes_added(doc1, doc2)
  am_apply_changes(doc1, changes)

  expect_equal(am_get(doc1, AM_ROOT, "from_doc1"), "value1")
  expect_equal(am_get(doc1, AM_ROOT, "from_doc2"), "value2")
})

test_that("am_get_changes_added() works with forked documents", {
  base <- am_create()
  base$initial <- "value"
  am_commit(base)

  fork1 <- am_fork(base)
  fork1$fork1_data <- "data1"
  am_commit(fork1)

  fork2 <- am_fork(base)
  fork2$fork2_data <- "data2"
  am_commit(fork2)

  changes <- am_get_changes_added(fork1, fork2)
  expect_length(changes, 1)

  am_apply_changes(fork1, changes)
  expect_equal(am_get(fork1, AM_ROOT, "fork2_data"), "data2")
})

test_that("am_fork() at specific head (single) works", {
  doc <- am_create()
  doc$v1 <- "first"
  am_commit(doc, "v1")

  heads_v1 <- am_get_heads(doc)

  doc$v2 <- "second"
  am_commit(doc, "v2")

  # Fork at v1 heads
  fork_at_v1 <- am_fork(doc, heads_v1)
  expect_s3_class(fork_at_v1, "am_doc")

  # Forked document should only have v1 data
  expect_equal(am_get(fork_at_v1, AM_ROOT, "v1"), "first")
  expect_null(am_get(fork_at_v1, AM_ROOT, "v2"))
})

test_that("am_fork() with empty list works like NULL", {
  doc <- am_create()
  doc$key <- "value"
  am_commit(doc)

  fork_current <- am_fork(doc, NULL)
  fork_empty <- am_fork(doc, list())

  expect_equal(
    am_get(fork_current, AM_ROOT, "key"),
    am_get(fork_empty, AM_ROOT, "key")
  )
})

# v1.2 Document Operations Tests ----------------------------------------------

# am_clone tests

test_that("am_clone() creates an independent deep copy", {
  doc <- am_create()
  doc$key <- "value"
  am_commit(doc)

  clone <- am_clone(doc)
  expect_s3_class(clone, "am_doc")
  expect_s3_class(clone, "automerge")
  expect_equal(am_get(clone, AM_ROOT, "key"), "value")
})

test_that("am_clone() produces independent document", {
  doc <- am_create()
  doc$key <- "original"
  am_commit(doc)

  clone <- am_clone(doc)

  clone$key <- "changed"
  am_commit(clone)

  expect_equal(am_get(doc, AM_ROOT, "key"), "original")
  expect_equal(am_get(clone, AM_ROOT, "key"), "changed")
})

test_that("am_clone() of empty document works", {
  doc <- am_create()
  clone <- am_clone(doc)
  expect_s3_class(clone, "am_doc")
  expect_equal(am_length(clone, AM_ROOT), 0)
})

# am_equal tests

test_that("am_equal() returns TRUE for equal docs", {
  doc1 <- am_create()
  doc1$key <- "value"
  am_commit(doc1)

  doc2 <- am_clone(doc1)
  expect_true(am_equal(doc1, doc2))
})

test_that("am_equal() returns FALSE for unequal docs", {
  doc1 <- am_create()
  doc1$key <- "value1"
  am_commit(doc1)

  doc2 <- am_clone(doc1)
  doc2$key <- "value2"
  am_commit(doc2)

  expect_false(am_equal(doc1, doc2))
})

test_that("am_equal() for empty documents", {
  doc1 <- am_create()
  doc2 <- am_create()
  expect_true(am_equal(doc1, doc2))
})

test_that("am_equal() after merge", {
  doc1 <- am_create()
  doc1$x <- 1
  am_commit(doc1)

  doc2 <- am_clone(doc1)
  doc2$y <- 2
  am_commit(doc2)

  am_merge(doc1, doc2)
  am_merge(doc2, doc1)

  expect_true(am_equal(doc1, doc2))
})

# am_pending_ops tests

test_that("am_pending_ops() is zero on fresh doc", {
  doc <- am_create()
  expect_equal(am_pending_ops(doc), 0L)
})

test_that("am_pending_ops() is non-zero after put", {
  doc <- am_create()
  doc$key <- "value"
  expect_gt(am_pending_ops(doc), 0L)
})

test_that("am_pending_ops() returns to zero after commit", {
  doc <- am_create()
  doc$key <- "value"
  am_commit(doc)
  expect_equal(am_pending_ops(doc), 0L)
})

# am_commit_empty tests

test_that("am_commit_empty() adds to history", {
  doc <- am_create()
  doc$key <- "value"
  am_commit(doc, "First")
  heads_before <- am_get_heads(doc)

  am_commit_empty(doc, "Empty change")
  heads_after <- am_get_heads(doc)

  expect_false(identical(heads_before, heads_after))
})

test_that("am_commit_empty() preserves message", {
  doc <- am_create()
  doc$key <- "value"
  am_commit(doc, "Setup")

  am_commit_empty(doc, "Checkpoint message")

  change <- am_get_last_local_change(doc)
  expect_equal(am_change_message(change), "Checkpoint message")
})

test_that("am_commit_empty() returns doc invisibly", {
  doc <- am_create()
  doc$key <- "value"
  am_commit(doc)
  result <- am_commit_empty(doc, "test")
  expect_identical(result, doc)
})

# am_save_incremental / am_load_incremental tests

test_that("am_save_incremental() returns raw bytes", {
  doc <- am_create()
  doc$key <- "value"
  am_commit(doc)
  bytes <- am_save_incremental(doc)
  expect_type(bytes, "raw")
})

test_that("incremental save/load round-trip works", {
  doc1 <- am_create()
  doc1$key1 <- "value1"
  am_commit(doc1)
  full_bytes <- am_save(doc1)

  doc1$key2 <- "value2"
  am_commit(doc1)
  incremental <- am_save_incremental(doc1)

  doc2 <- am_load(full_bytes)
  am_load_incremental(doc2, incremental)
  expect_equal(am_get(doc2, AM_ROOT, "key2"), "value2")
})

test_that("am_save_incremental() after no changes returns empty or small bytes", {
  doc <- am_create()
  doc$key <- "value"
  am_commit(doc)
  am_save(doc)

  # Second incremental save with no new changes
  incremental <- am_save_incremental(doc)
  expect_type(incremental, "raw")
})

test_that("am_load_incremental() errors on non-raw input", {
  doc <- am_create()
  expect_error(am_load_incremental(doc, "not raw"), "data must be a raw vector")
})

test_that("multiple incremental saves accumulate correctly", {
  doc1 <- am_create()
  doc1$a <- 1
  am_commit(doc1)
  full <- am_save(doc1)

  doc1$b <- 2
  am_commit(doc1)
  inc1 <- am_save_incremental(doc1)

  doc1$c <- 3
  am_commit(doc1)
  inc2 <- am_save_incremental(doc1)

  doc2 <- am_load(full)
  am_load_incremental(doc2, inc1)
  am_load_incremental(doc2, inc2)

  expect_equal(am_get(doc2, AM_ROOT, "a"), 1)
  expect_equal(am_get(doc2, AM_ROOT, "b"), 2)
  expect_equal(am_get(doc2, AM_ROOT, "c"), 3)
})

# Additional am_clone tests

test_that("am_clone() preserves the actor ID", {
  doc <- am_create()
  doc$key <- "value"
  am_commit(doc)

  clone <- am_clone(doc)
  expect_equal(am_get_actor(doc), am_get_actor(clone))
  expect_equal(am_get_actor_hex(doc), am_get_actor_hex(clone))
})

test_that("am_clone() preserves nested structures", {
  doc <- am_create()
  doc$config <- list(host = "localhost", port = 8080L)
  doc$items <- am_list("a", "b", "c")
  am_commit(doc)

  clone <- am_clone(doc)
  config <- am_get(clone, AM_ROOT, "config")
  expect_equal(am_get(clone, config, "host"), "localhost")
  expect_equal(am_get(clone, config, "port"), 8080L)
  items <- am_get(clone, AM_ROOT, "items")
  expect_equal(am_length(clone, items), 3)
})

test_that("am_clone() preserves history", {
  doc <- am_create()
  doc$v1 <- 1
  am_commit(doc, "First")
  doc$v2 <- 2
  am_commit(doc, "Second")

  clone <- am_clone(doc)
  history <- am_get_changes(clone)
  expect_length(history, 2)
  expect_equal(am_change_message(history[[1]]), "First")
  expect_equal(am_change_message(history[[2]]), "Second")
})

# Additional am_equal tests

test_that("am_equal() is reflexive", {
  doc <- am_create()
  doc$key <- "value"
  am_commit(doc)
  expect_true(am_equal(doc, doc))
})

test_that("am_equal() after fork and mutual merge", {
  doc1 <- am_create()
  doc1$x <- 1
  am_commit(doc1)

  doc2 <- am_fork(doc1)
  doc2$y <- 2
  am_commit(doc2)

  doc1$z <- 3
  am_commit(doc1)

  am_merge(doc1, doc2)
  am_merge(doc2, doc1)

  expect_true(am_equal(doc1, doc2))
})

test_that("am_equal() distinguishes docs with different content", {
  doc1 <- am_create()
  doc1$key <- "alpha"
  am_commit(doc1)

  doc2 <- am_create()
  doc2$key <- "beta"
  am_commit(doc2)

  expect_false(am_equal(doc1, doc2))
})

# Additional am_pending_ops tests

test_that("am_pending_ops() counts multiple operations", {
  doc <- am_create()
  doc$a <- 1
  doc$b <- 2
  doc$c <- 3
  expect_gt(am_pending_ops(doc), 1L)
})

test_that("am_pending_ops() returns zero after rollback", {
  doc <- am_create()
  doc$key <- "value"
  expect_gt(am_pending_ops(doc), 0L)
  am_rollback(doc)
  expect_equal(am_pending_ops(doc), 0L)
})

# Additional am_commit_empty tests

test_that("am_commit_empty() on fresh doc creates head", {
  doc <- am_create()
  expect_length(am_get_heads(doc), 0)
  am_commit_empty(doc, "Genesis")
  expect_length(am_get_heads(doc), 1)
})

test_that("am_commit_empty() with timestamp", {
  doc <- am_create()
  doc$key <- "value"
  am_commit(doc)

  ts <- as.POSIXct("2025-06-15 12:00:00", tz = "UTC")
  am_commit_empty(doc, "Timestamped", ts)

  change <- am_get_last_local_change(doc)
  expect_s3_class(am_change_time(change), "POSIXct")
})

test_that("am_commit_empty() without message", {
  doc <- am_create()
  doc$key <- "value"
  am_commit(doc)

  am_commit_empty(doc)
  change <- am_get_last_local_change(doc)
  expect_null(am_change_message(change))
})

# Additional am_save_incremental / am_load_incremental tests

test_that("am_load_incremental() returns operation count invisibly", {
  doc1 <- am_create()
  doc1$key <- "value"
  am_commit(doc1)
  full <- am_save(doc1)

  doc1$key2 <- "value2"
  am_commit(doc1)
  inc <- am_save_incremental(doc1)

  doc2 <- am_load(full)
  result <- withVisible(am_load_incremental(doc2, inc))
  expect_false(result$visible)
  expect_type(result$value, "double")
})

test_that("incremental save/load with nested objects", {
  doc1 <- am_create()
  doc1$base <- "data"
  am_commit(doc1)
  full <- am_save(doc1)

  doc1$config <- list(host = "localhost", port = 8080L)
  am_commit(doc1)
  inc <- am_save_incremental(doc1)

  doc2 <- am_load(full)
  am_load_incremental(doc2, inc)
  config <- am_get(doc2, AM_ROOT, "config")
  expect_equal(am_get(doc2, config, "host"), "localhost")
})

test_that("am_save_incremental() resets after am_save()", {
  doc <- am_create()
  doc$a <- 1
  am_commit(doc)

  inc1 <- am_save_incremental(doc)
  expect_gt(length(inc1), 0)

  # After full save, incremental should have nothing new

  am_save(doc)
  inc2 <- am_save_incremental(doc)
  expect_lte(length(inc2), length(inc1))
})

test_that("am_load_incremental() errors on invalid bytes", {
  doc <- am_create()
  expect_error(am_load_incremental(doc, raw(10)))
})

# Coverage Tests: Input Validation and Edge Cases =============================

test_that("am_fork() supports multiple heads", {
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
  forked <- am_fork(doc, heads)
  expect_s3_class(forked, "am_doc")
  expect_equal(forked$x, 1)
  expect_equal(forked$y, 2)
  expect_equal(forked$z, 3)
})

test_that("am_commit_empty() errors on invalid message type", {
  doc <- am_create()
  expect_error(am_commit_empty(doc, message = 123), "character string")
})

test_that("am_commit_empty() errors on invalid time type", {
  doc <- am_create()
  expect_error(am_commit_empty(doc, time = "not a time"), "POSIXct")
})

test_that("am_create() errors on invalid actor_id type", {
  expect_error(am_create(123L), "NULL.*character string.*raw bytes")
})

test_that("am_set_actor() errors on invalid type", {
  doc <- am_create()
  expect_error(am_set_actor(doc, 123L), "NULL.*character string.*raw bytes")
})

test_that("am_get_changes_added() returns new changes from fork", {
  doc1 <- am_create()
  doc1$x <- 1
  am_commit(doc1)

  doc2 <- am_fork(doc1)
  doc2$y <- 2
  am_commit(doc2)

  changes <- am_get_changes_added(doc1, doc2)
  expect_length(changes, 1)
  expect_s3_class(changes[[1]], "am_change")
})

test_that("am_get_changes() errors on non-raw head in list", {
  doc <- am_create()
  doc$x <- 1
  am_commit(doc)
  expect_error(am_get_changes(doc, list("not raw")), "raw vectors")
})
