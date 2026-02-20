test_that("am_cursor creates and retrieves cursor positions", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Create cursor at position 5 (after "hello", before " ")
  cursor <- am_cursor(text_obj, 5)
  expect_s3_class(cursor, "am_cursor")

  # Retrieve cursor position
  pos <- am_cursor_position(cursor)
  expect_equal(pos, 5)
})

test_that("cursors track positions across text edits", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Create cursor at position 6 (before "world")
  cursor <- am_cursor(text_obj, 6)

  # Insert text before cursor
  am_text_splice(text_obj, 0, 0, "Hi ")

  # Cursor should move forward by 3 characters
  new_pos <- am_cursor_position(cursor)
  expect_equal(new_pos, 9)  # 6 + 3 = 9
})

test_that("cursors handle UTF-32 character indexing correctly", {
  doc <- am_create()
  # Text with emoji (single character in UTF-32)
  am_put(doc, AM_ROOT, "text", am_text("Hello😀World"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Position 6 is after emoji (position 5 is the emoji)
  cursor <- am_cursor(text_obj, 6)
  pos <- am_cursor_position(cursor)
  expect_equal(pos, 6)

  # Insert text before cursor
  am_text_splice(text_obj, 0, 0, "A")

  # Cursor moves by 1 character
  new_pos <- am_cursor_position(cursor)
  expect_equal(new_pos, 7)
})

test_that("cursors work at text boundaries", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Cursor at start (position 0, before 'h')
  cursor_start <- am_cursor(text_obj, 0)
  expect_equal(am_cursor_position(cursor_start), 0)

  # Cursor at end (position 4, at last character 'o')
  # Note: Cursors must be placed within the text, not after it
  cursor_end <- am_cursor(text_obj, 4)
  expect_equal(am_cursor_position(cursor_end), 4)
})

test_that("cursor validation rejects invalid inputs", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Non-numeric position
  expect_error(am_cursor(text_obj, "invalid"), "position must be numeric")

  # Non-scalar position
  expect_error(am_cursor(text_obj, c(1, 2)), "position must be a scalar")

  # Negative position
  expect_error(am_cursor(text_obj, -1), "position must be non-negative")

  # Invalid cursor in am_cursor_position
  expect_error(am_cursor_position("not_a_cursor"),
               "cursor must be an external pointer")
})

test_that("multiple cursors work independently", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Create multiple cursors
  cursor1 <- am_cursor(text_obj, 2)
  cursor2 <- am_cursor(text_obj, 6)
  cursor3 <- am_cursor(text_obj, 9)

  # Insert text before all cursors
  am_text_splice(text_obj, 0, 0, "XX")

  # All cursors should move by 2
  expect_equal(am_cursor_position(cursor1), 4)
  expect_equal(am_cursor_position(cursor2), 8)
  expect_equal(am_cursor_position(cursor3), 11)
})

# Cursor Serialization Tests ---------------------------------------------------

test_that("am_cursor_to_bytes() returns raw vector", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  cursor <- am_cursor(text_obj, 5)
  bytes <- am_cursor_to_bytes(cursor)
  expect_type(bytes, "raw")
  expect_true(length(bytes) > 0)
})

test_that("cursor round-trips through bytes", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  cursor <- am_cursor(text_obj, 5)
  bytes <- am_cursor_to_bytes(cursor)
  restored <- am_cursor_from_bytes(bytes, text_obj)
  expect_s3_class(restored, "am_cursor")
  expect_equal(am_cursor_position(restored), 5)
})

test_that("am_cursor_to_string() returns character", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  cursor <- am_cursor(text_obj, 5)
  str <- am_cursor_to_string(cursor)
  expect_type(str, "character")
  expect_true(nchar(str) > 0)
})

test_that("cursor round-trips through string", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  cursor <- am_cursor(text_obj, 5)
  str <- am_cursor_to_string(cursor)
  restored <- am_cursor_from_string(str, text_obj)
  expect_s3_class(restored, "am_cursor")
  expect_equal(am_cursor_position(restored), 5)
})

test_that("am_cursor_equal() detects equal cursors", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  cursor1 <- am_cursor(text_obj, 5)
  cursor2 <- am_cursor(text_obj, 5)

  expect_true(am_cursor_equal(cursor1, cursor2))
})

test_that("am_cursor_equal() detects unequal cursors", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  cursor1 <- am_cursor(text_obj, 3)
  cursor2 <- am_cursor(text_obj, 7)

  expect_false(am_cursor_equal(cursor1, cursor2))
})

test_that("am_cursor_from_bytes() errors on non-raw input", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  expect_error(am_cursor_from_bytes("not raw", text_obj), "bytes must be a raw vector")
})

test_that("am_cursor_from_string() errors on non-string input", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  expect_error(am_cursor_from_string(123, text_obj), "str must be a single character string")
})

# Historical Queries (heads parameter) Tests -----------------------------------

test_that("am_cursor() works with heads parameter", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello"))
  am_commit(doc, "initial")

  heads <- am_get_heads(doc)

  am_text_splice(am_get(doc, AM_ROOT, "text"), 5, 0, " world")
  am_commit(doc, "extended")

  text_obj <- am_get(doc, AM_ROOT, "text")
  cursor <- am_cursor(text_obj, 3, heads = heads)
  expect_s3_class(cursor, "am_cursor")
})

test_that("am_cursor_position() works with heads parameter", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello"))
  am_commit(doc, "initial")

  text_obj <- am_get(doc, AM_ROOT, "text")
  cursor <- am_cursor(text_obj, 3)
  heads <- am_get_heads(doc)

  am_text_splice(text_obj, 0, 0, "XXX")
  am_commit(doc, "insert")

  # Current state: cursor moved
  pos_current <- am_cursor_position(cursor)
  expect_equal(pos_current, 6)  # 3 + 3

  # Historical state: cursor at original position
  pos_historical <- am_cursor_position(cursor, heads = heads)
  expect_equal(pos_historical, 3)
})

test_that("am_marks() works with heads parameter", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  am_mark(text_obj, 0, 5, "bold", TRUE)
  am_commit(doc, "mark bold")

  heads_v1 <- am_get_heads(doc)

  am_mark(text_obj, 6, 11, "italic", TRUE)
  am_commit(doc, "mark italic")

  # Current state: 2 marks
  marks_now <- am_marks(text_obj)
  expect_length(marks_now, 2)

  # Historical state: only 1 mark
  marks_then <- am_marks(text_obj, heads = heads_v1)
  expect_length(marks_then, 1)
  expect_equal(marks_then[[1]]$name, "bold")
})

test_that("am_marks_at() works with heads parameter", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  am_mark(text_obj, 0, 5, "bold", TRUE)
  am_commit(doc, "mark bold")

  heads_v1 <- am_get_heads(doc)

  am_mark(text_obj, 2, 7, "underline", TRUE)
  am_commit(doc, "mark underline")

  # Current state at position 3: both marks
  marks_now <- am_marks_at(text_obj, 3)
  expect_length(marks_now, 2)

  # Historical state at position 3: only bold
  marks_then <- am_marks_at(text_obj, 3, heads = heads_v1)
  expect_length(marks_then, 1)
  expect_equal(marks_then[[1]]$name, "bold")
})

# Empty and multi-head fallback paths ------------------------------------------

test_that("am_cursor() with empty heads list falls back to current state", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello"))
  am_commit(doc, "initial")

  text_obj <- am_get(doc, AM_ROOT, "text")
  cursor <- am_cursor(text_obj, 3, heads = list())
  expect_s3_class(cursor, "am_cursor")
  expect_equal(am_cursor_position(cursor), 3)
})

test_that("am_cursor_position() with empty heads list falls back to current state", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  am_commit(doc, "initial")

  text_obj <- am_get(doc, AM_ROOT, "text")
  cursor <- am_cursor(text_obj, 5)

  am_text_splice(text_obj, 0, 0, "XX")
  am_commit(doc, "insert")

  # Empty heads list falls back to current state (cursor moved)
  pos <- am_cursor_position(cursor, heads = list())
  expect_equal(pos, 7)  # 5 + 2
})

test_that("am_marks() with empty heads list falls back to current state", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  am_mark(text_obj, 0, 5, "bold", TRUE)
  am_commit(doc, "mark bold")

  marks <- am_marks(text_obj, heads = list())
  expect_length(marks, 1)
  expect_equal(marks[[1]]$name, "bold")
})

test_that("am_marks_at() with empty heads list falls back to current state", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  am_mark(text_obj, 0, 5, "bold", TRUE)
  am_commit(doc, "mark bold")

  marks <- am_marks_at(text_obj, 3, heads = list())
  expect_length(marks, 1)
  expect_equal(marks[[1]]$name, "bold")
})

test_that("am_cursor() supports multiple heads", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello"))
  am_commit(doc, "initial")

  doc2 <- am_fork(doc)
  am_text_splice(am_get(doc, AM_ROOT, "text"), 5, 0, " world")
  am_commit(doc, "doc1 edit")
  am_text_splice(am_get(doc2, AM_ROOT, "text"), 5, 0, " there")
  am_commit(doc2, "doc2 edit")

  am_merge(doc, doc2)
  heads <- am_get_heads(doc)
  expect_true(length(heads) >= 2)

  text_obj <- am_get(doc, AM_ROOT, "text")
  cursor <- am_cursor(text_obj, 3, heads = heads)
  expect_s3_class(cursor, "am_cursor")
})

test_that("am_cursor_position() supports multiple heads", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello"))
  am_commit(doc, "initial")

  text_obj <- am_get(doc, AM_ROOT, "text")
  cursor <- am_cursor(text_obj, 3)

  doc2 <- am_fork(doc)
  am_text_splice(am_get(doc, AM_ROOT, "text"), 5, 0, " world")
  am_commit(doc, "doc1 edit")
  am_text_splice(am_get(doc2, AM_ROOT, "text"), 5, 0, " there")
  am_commit(doc2, "doc2 edit")

  am_merge(doc, doc2)
  heads <- am_get_heads(doc)
  expect_true(length(heads) >= 2)

  pos <- am_cursor_position(cursor, heads = heads)
  expect_type(pos, "integer")
})

test_that("am_marks() supports multiple heads", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")
  am_mark(text_obj, 0, 5, "bold", TRUE)
  am_commit(doc, "mark bold")

  doc2 <- am_fork(doc)
  am_put(doc, AM_ROOT, "x", 1)
  am_commit(doc, "doc1 edit")
  am_put(doc2, AM_ROOT, "y", 2)
  am_commit(doc2, "doc2 edit")

  am_merge(doc, doc2)
  heads <- am_get_heads(doc)
  expect_true(length(heads) >= 2)

  marks <- am_marks(text_obj, heads = heads)
  expect_type(marks, "list")
  expect_length(marks, 1)
})

test_that("am_marks_at() supports multiple heads", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")
  am_mark(text_obj, 0, 5, "bold", TRUE)
  am_commit(doc, "mark bold")

  doc2 <- am_fork(doc)
  am_put(doc, AM_ROOT, "x", 1)
  am_commit(doc, "doc1 edit")
  am_put(doc2, AM_ROOT, "y", 2)
  am_commit(doc2, "doc2 edit")

  am_merge(doc, doc2)
  heads <- am_get_heads(doc)
  expect_true(length(heads) >= 2)

  marks <- am_marks_at(text_obj, 3, heads = heads)
  expect_type(marks, "list")
  expect_length(marks, 1)
})

test_that("cursors remain valid after text deletion", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Create cursor at position 7 (in "world")
  cursor <- am_cursor(text_obj, 7)

  # Delete text before cursor ("hello ")
  am_text_splice(text_obj, 0, 6, "")

  # Cursor should move back by 6 characters
  new_pos <- am_cursor_position(cursor)
  expect_equal(new_pos, 1)  # 7 - 6 = 1
})

# Cursor Serialization Error Path Tests ----------------------------------------

test_that("am_cursor_to_bytes() errors on non-cursor input", {
  expect_error(am_cursor_to_bytes("not a cursor"), "cursor must be an am_cursor object")
  expect_error(am_cursor_to_bytes(123), "cursor must be an am_cursor object")
})

test_that("am_cursor_to_string() errors on non-cursor input", {
  expect_error(am_cursor_to_string("not a cursor"), "cursor must be an am_cursor object")
  expect_error(am_cursor_to_string(123), "cursor must be an am_cursor object")
})

test_that("am_cursor_equal() errors on non-cursor inputs", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello"))
  text_obj <- am_get(doc, AM_ROOT, "text")
  cursor <- am_cursor(text_obj, 2)

  expect_error(am_cursor_equal("not a cursor", cursor), "cursor1 must be an am_cursor object")
  expect_error(am_cursor_equal(cursor, "not a cursor"), "cursor2 must be an am_cursor object")
  expect_error(am_cursor_equal(123, cursor), "cursor1 must be an am_cursor object")
})

test_that("am_cursor_from_bytes() errors on non-text object", {
  expect_error(am_cursor_from_bytes(raw(10), "not an obj"), "obj must be a text object")
})

test_that("am_cursor_from_string() errors on non-text object", {
  expect_error(am_cursor_from_string("abc", "not an obj"), "obj must be a text object")
})

# Cursor Serialization Roundtrip After Edits -----------------------------------

test_that("cursor serialized via bytes tracks position after text edits", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  cursor <- am_cursor(text_obj, 5)
  bytes <- am_cursor_to_bytes(cursor)

  # Insert text before cursor position
  am_text_splice(text_obj, 0, 0, "XX")

  # Restore cursor and check it tracks the new position
  restored <- am_cursor_from_bytes(bytes, text_obj)
  expect_equal(am_cursor_position(restored), 7)  # 5 + 2
})

test_that("cursor serialized via string tracks position after text edits", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  cursor <- am_cursor(text_obj, 5)
  str <- am_cursor_to_string(cursor)

  # Insert text before cursor position
  am_text_splice(text_obj, 0, 0, "XX")

  # Restore cursor and check it tracks the new position
  restored <- am_cursor_from_string(str, text_obj)
  expect_equal(am_cursor_position(restored), 7)  # 5 + 2
})

# Cursor Equality with Serialized Cursors --------------------------------------

test_that("am_cursor_equal() works with serialized+restored cursors", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  cursor <- am_cursor(text_obj, 5)
  bytes <- am_cursor_to_bytes(cursor)
  restored <- am_cursor_from_bytes(bytes, text_obj)

  expect_true(am_cursor_equal(cursor, restored))
})

test_that("am_cursor_equal() works with string-serialized cursors", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  cursor <- am_cursor(text_obj, 5)
  str <- am_cursor_to_string(cursor)
  restored <- am_cursor_from_string(str, text_obj)

  expect_true(am_cursor_equal(cursor, restored))
})

# NULL/freed cursor pointer paths ----------------------------------------------

test_that("am_cursor_to_bytes() errors on NULL/freed cursor pointer", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  cursor <- am_cursor(text_obj, 5)
  freed_cursor <- unserialize(serialize(cursor, NULL))

  expect_error(am_cursor_to_bytes(freed_cursor), "Invalid cursor pointer")
})

test_that("am_cursor_to_string() errors on NULL/freed cursor pointer", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  cursor <- am_cursor(text_obj, 5)
  freed_cursor <- unserialize(serialize(cursor, NULL))

  expect_error(am_cursor_to_string(freed_cursor), "Invalid cursor pointer")
})

# Print Methods ----------------------------------------------------------------

test_that("print.am_cursor outputs expected text", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  cursor <- am_cursor(text_obj, 5)
  expect_snapshot(print(cursor))
})
