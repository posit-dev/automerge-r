# Change Introspection Tests

test_that("am_change_hash() returns 32-byte raw vector", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc, "Add key")

  history <- am_get_changes(doc)
  change <- history[[1]]
  hash <- am_change_hash(change)

  expect_type(hash, "raw")
  expect_equal(length(hash), 32)
})

test_that("am_change_hash() matches am_get_heads()", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc, "Add key")

  heads <- am_get_heads(doc)
  history <- am_get_changes(doc)
  change <- history[[1]]
  hash <- am_change_hash(change)

  expect_equal(hash, heads[[1]])
})

test_that("am_change_message() returns commit message", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc, "Add key")

  history <- am_get_changes(doc)
  change <- history[[1]]
  msg <- am_change_message(change)
  expect_equal(msg, "Add key")
})

test_that("am_change_message() returns NULL when no message", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc)

  history <- am_get_changes(doc)
  change <- history[[1]]
  msg <- am_change_message(change)
  expect_null(msg)
})

test_that("am_change_message() handles UTF-8 messages", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc, "\u63d0\u4ea4\u6d88\u606f \U0001f389")

  history <- am_get_changes(doc)
  change <- history[[1]]
  msg <- am_change_message(change)
  expect_equal(msg, "\u63d0\u4ea4\u6d88\u606f \U0001f389")
})

test_that("am_change_time() returns POSIXct", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc, "Add key", Sys.time())

  history <- am_get_changes(doc)
  change <- history[[1]]
  time <- am_change_time(change)
  expect_s3_class(time, "POSIXct")
})

test_that("am_change_actor_id() matches document actor", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc, "Add key")

  history <- am_get_changes(doc)
  change <- history[[1]]
  actor <- am_change_actor_id(change)
  expect_equal(actor, am_get_actor(doc))
})

test_that("am_change_seq() returns sequence numbers", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "x", 1)
  am_commit(doc, "First")
  am_put(doc, AM_ROOT, "y", 2)
  am_commit(doc, "Second")

  history <- am_get_changes(doc)
  ch1 <- history[[1]]
  ch2 <- history[[2]]
  expect_equal(am_change_seq(ch1), 1)
  expect_equal(am_change_seq(ch2), 2)
})

test_that("am_change_deps() returns empty list for first change", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc, "First")

  history <- am_get_changes(doc)
  change <- history[[1]]
  deps <- am_change_deps(change)
  expect_type(deps, "list")
  expect_length(deps, 0)
})

test_that("am_change_deps() returns parent hash for second change", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "x", 1)
  am_commit(doc, "First")
  am_put(doc, AM_ROOT, "y", 2)
  am_commit(doc, "Second")

  history <- am_get_changes(doc)
  ch1 <- history[[1]]
  ch2 <- history[[2]]
  first_hash <- am_change_hash(ch1)
  deps <- am_change_deps(ch2)

  expect_length(deps, 1)
  expect_equal(deps[[1]], first_hash)
})

test_that("am_change_from_bytes() creates am_change object", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc, "Add key")

  history <- am_get_changes(doc)
  bytes <- am_change_to_bytes(history[[1]])
  change <- am_change_from_bytes(bytes)
  expect_s3_class(change, "am_change")
})

test_that("am_change_from_bytes() errors on non-raw input", {
  expect_error(am_change_from_bytes("not raw"), "bytes must be a raw vector")
})

test_that("am_change_to_bytes() round-trips through am_change_from_bytes()", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc, "Add key")

  history <- am_get_changes(doc)
  change <- history[[1]]
  bytes <- am_change_to_bytes(change)
  restored <- am_change_from_bytes(bytes)
  expect_equal(am_change_to_bytes(restored), bytes)
})

test_that("am_get_changes() returns am_change objects directly", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc, "Add key")

  history <- am_get_changes(doc)
  expect_s3_class(history[[1]], "am_change")

  # Can use introspection functions directly without am_change_from_bytes()
  expect_type(am_change_hash(history[[1]]), "raw")
  expect_equal(am_change_message(history[[1]]), "Add key")
  expect_s3_class(am_change_time(history[[1]]), "POSIXct")
  expect_equal(am_change_actor_id(history[[1]]), am_get_actor(doc))
  expect_equal(am_change_seq(history[[1]]), 1)
  expect_type(am_change_deps(history[[1]]), "list")
})

test_that("am_change functions error on invalid input", {
  expect_error(am_change_hash(123), "am_change object")
  expect_error(am_change_message(123), "am_change object")
  expect_error(am_change_time(123), "am_change object")
  expect_error(am_change_actor_id(123), "am_change object")
  expect_error(am_change_seq(123), "am_change object")
  expect_error(am_change_deps(123), "am_change object")
})

test_that("am_change functions error on raw bytes (must parse first)", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc, "Add key")

  history <- am_get_changes(doc)
  raw_change <- am_change_to_bytes(history[[1]])

  expect_error(am_change_hash(raw_change), "am_change object")
  expect_error(am_change_message(raw_change), "am_change object")
  expect_error(am_change_time(raw_change), "am_change object")
  expect_error(am_change_actor_id(raw_change), "am_change object")
  expect_error(am_change_seq(raw_change), "am_change object")
  expect_error(am_change_deps(raw_change), "am_change object")
  expect_error(am_change_to_bytes(raw_change), "am_change object")
})

test_that("am_apply_changes() errors on invalid am_change external pointer", {
  doc <- am_create()

  # A closed doc is an external pointer with NULL address,
  # which triggers the !data check in the am_change validation loop
  closed_doc <- am_create()
  am_close(closed_doc)

  expect_error(
    am_apply_changes(doc, list(closed_doc)),
    "Invalid am_change pointer"
  )
})

# Change Size and Empty Tests --------------------------------------------------

test_that("am_change_size() returns number of operations", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "x", 1)
  am_put(doc, AM_ROOT, "y", 2)
  am_commit(doc, "Two ops")
  am_commit_empty(doc, "Empty")

  history <- am_get_changes(doc)
  expect_equal(am_change_size(history[[1]]), 2L)
  expect_equal(am_change_size(history[[2]]), 0L)
})

test_that("am_change_size() errors on invalid input", {
  expect_error(am_change_size(123), "am_change object")
})

# Change Metadata Round-Trip Tests ---------------------------------------------

test_that("am_change_from_bytes() preserves all metadata through round-trip", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  time <- Sys.time()
  am_commit(doc, "Test message", time)

  history <- am_get_changes(doc)
  original <- history[[1]]

  bytes <- am_change_to_bytes(original)
  restored <- am_change_from_bytes(bytes)

  expect_equal(am_change_hash(restored), am_change_hash(original))
  expect_equal(am_change_message(restored), "Test message")
  expect_equal(am_change_actor_id(restored), am_change_actor_id(original))
  expect_equal(am_change_seq(restored), am_change_seq(original))
  expect_equal(am_change_deps(restored), am_change_deps(original))
  expect_s3_class(am_change_time(restored), "POSIXct")
})

test_that("am_change_to_bytes() returns raw vector", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc, "Add key")

  history <- am_get_changes(doc)
  bytes <- am_change_to_bytes(history[[1]])
  expect_type(bytes, "raw")
  expect_true(length(bytes) > 0)
})

test_that("am_change_from_bytes() errors on corrupted data", {
  expect_error(am_change_from_bytes(raw(10)))
  expect_error(am_change_from_bytes(as.raw(c(0xFF, 0xFF, 0xFF))))
})

test_that("am_change_time() returns POSIXct even without explicit timestamp", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc)

  history <- am_get_changes(doc)
  time <- am_change_time(history[[1]])
  expect_s3_class(time, "POSIXct")
})

test_that("am_change_seq() returns numeric (double)", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc, "Add key")

  history <- am_get_changes(doc)
  seq <- am_change_seq(history[[1]])
  expect_type(seq, "double")
})

# Change Dependencies with Multiple Parents ------------------------------------

test_that("am_change_deps() returns multiple deps after merging concurrent changes", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "base", 0)
  am_commit(doc, "Base")

  # Fork and create concurrent changes
  doc2 <- am_fork(doc)
  am_put(doc, AM_ROOT, "x", 1)
  am_commit(doc, "Add x")

  am_put(doc2, AM_ROOT, "y", 2)
  am_commit(doc2, "Add y")

  # Merge creates concurrent heads
  am_merge(doc, doc2)

  # A new commit after merge depends on both concurrent heads
  am_put(doc, AM_ROOT, "z", 3)
  am_commit(doc, "After merge")

  history <- am_get_changes(doc)
  last_change <- history[[length(history)]]
  deps <- am_change_deps(last_change)

  expect_true(length(deps) >= 2)
  for (dep in deps) {
    expect_type(dep, "raw")
    expect_equal(length(dep), 32)
  }
})

# Change Introspection on Serialized Changes from get_changes ------------------

test_that("am_get_changes() returns introspectable am_change objects", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "x", 1)
  am_commit(doc, "First")
  am_put(doc, AM_ROOT, "y", 2)
  am_commit(doc, "Second")

  changes <- am_get_changes(doc, NULL)
  expect_length(changes, 2)

  expect_equal(am_change_message(changes[[1]]), "First")
  expect_equal(am_change_message(changes[[2]]), "Second")
  expect_equal(am_change_seq(changes[[1]]), 1)
  expect_equal(am_change_seq(changes[[2]]), 2)
})

test_that("am_get_last_local_change() returns introspectable am_change", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc, "Local change")

  change <- am_get_last_local_change(doc)
  expect_s3_class(change, "am_change")
  expect_equal(am_change_message(change), "Local change")
  expect_type(am_change_hash(change), "raw")
  expect_equal(am_change_actor_id(change), am_get_actor(doc))
})

test_that("am_get_change_by_hash() returns introspectable am_change", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc, "By hash")

  heads <- am_get_heads(doc)
  change <- am_get_change_by_hash(doc, heads[[1]])
  expect_s3_class(change, "am_change")
  expect_equal(am_change_message(change), "By hash")
  expect_equal(am_change_hash(change), heads[[1]])
})

test_that("am_get_changes_added() returns introspectable am_change objects", {
  doc1 <- am_create()
  am_put(doc1, AM_ROOT, "x", 1)
  am_commit(doc1, "In doc1")

  doc2 <- am_fork(doc1)
  am_put(doc2, AM_ROOT, "y", 2)
  am_commit(doc2, "In doc2")

  added <- am_get_changes_added(doc1, doc2)
  expect_length(added, 1)
  expect_s3_class(added[[1]], "am_change")
  expect_equal(am_change_message(added[[1]]), "In doc2")
})
