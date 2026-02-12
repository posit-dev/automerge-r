# Change Introspection Tests

test_that("am_change_hash() returns 32-byte raw vector", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc, "Add key")

  history <- am_get_history(doc)
  change <- am_change_from_bytes(history[[1]])
  hash <- am_change_hash(change)

  expect_type(hash, "raw")
  expect_equal(length(hash), 32)
})

test_that("am_change_hash() matches am_get_heads()", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc, "Add key")

  heads <- am_get_heads(doc)
  history <- am_get_history(doc)
  change <- am_change_from_bytes(history[[1]])
  hash <- am_change_hash(change)

  expect_equal(hash, heads[[1]])
})

test_that("am_change_message() returns commit message", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc, "Add key")

  history <- am_get_history(doc)
  change <- am_change_from_bytes(history[[1]])
  msg <- am_change_message(change)
  expect_equal(msg, "Add key")
})

test_that("am_change_message() returns NULL when no message", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc)

  history <- am_get_history(doc)
  change <- am_change_from_bytes(history[[1]])
  msg <- am_change_message(change)
  expect_null(msg)
})

test_that("am_change_message() handles UTF-8 messages", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc, "\u63d0\u4ea4\u6d88\u606f \U0001f389")

  history <- am_get_history(doc)
  change <- am_change_from_bytes(history[[1]])
  msg <- am_change_message(change)
  expect_equal(msg, "\u63d0\u4ea4\u6d88\u606f \U0001f389")
})

test_that("am_change_time() returns POSIXct", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc, "Add key", Sys.time())

  history <- am_get_history(doc)
  change <- am_change_from_bytes(history[[1]])
  time <- am_change_time(change)
  expect_s3_class(time, "POSIXct")
})

test_that("am_change_actor_id() matches document actor", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc, "Add key")

  history <- am_get_history(doc)
  change <- am_change_from_bytes(history[[1]])
  actor <- am_change_actor_id(change)
  expect_equal(actor, am_get_actor(doc))
})

test_that("am_change_seq() returns sequence numbers", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "x", 1)
  am_commit(doc, "First")
  am_put(doc, AM_ROOT, "y", 2)
  am_commit(doc, "Second")

  history <- am_get_history(doc)
  ch1 <- am_change_from_bytes(history[[1]])
  ch2 <- am_change_from_bytes(history[[2]])
  expect_equal(am_change_seq(ch1), 1)
  expect_equal(am_change_seq(ch2), 2)
})

test_that("am_change_deps() returns empty list for first change", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc, "First")

  history <- am_get_history(doc)
  change <- am_change_from_bytes(history[[1]])
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

  history <- am_get_history(doc)
  ch1 <- am_change_from_bytes(history[[1]])
  ch2 <- am_change_from_bytes(history[[2]])
  first_hash <- am_change_hash(ch1)
  deps <- am_change_deps(ch2)

  expect_length(deps, 1)
  expect_equal(deps[[1]], first_hash)
})

test_that("am_change_from_bytes() creates am_change object", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc, "Add key")

  history <- am_get_history(doc)
  change <- am_change_from_bytes(history[[1]])
  expect_s3_class(change, "am_change")
})

test_that("am_change_from_bytes() errors on non-raw input", {
  expect_error(am_change_from_bytes("not raw"), "bytes must be a raw vector")
})

test_that("am_change_to_bytes() round-trips through am_change", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc, "Add key")

  history <- am_get_history(doc)
  change <- am_change_from_bytes(history[[1]])
  bytes <- am_change_to_bytes(change)
  expect_equal(bytes, history[[1]])
})

test_that("am_change functions work with am_change objects", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  am_commit(doc, "Add key")

  history <- am_get_history(doc)
  change <- am_change_from_bytes(history[[1]])

  expect_type(am_change_hash(change), "raw")
  expect_equal(am_change_message(change), "Add key")
  expect_s3_class(am_change_time(change), "POSIXct")
  expect_equal(am_change_actor_id(change), am_get_actor(doc))
  expect_equal(am_change_seq(change), 1)
  expect_type(am_change_deps(change), "list")
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

  history <- am_get_history(doc)
  raw_change <- history[[1]]

  expect_error(am_change_hash(raw_change), "am_change object")
  expect_error(am_change_message(raw_change), "am_change object")
  expect_error(am_change_time(raw_change), "am_change object")
  expect_error(am_change_actor_id(raw_change), "am_change object")
  expect_error(am_change_seq(raw_change), "am_change object")
  expect_error(am_change_deps(raw_change), "am_change object")
  expect_error(am_change_to_bytes(raw_change), "am_change object")
})
