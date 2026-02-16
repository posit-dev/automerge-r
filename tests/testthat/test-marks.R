test_that("am_mark creates marks on text ranges", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Mark "hello" (positions 0-4) as bold
  am_mark(text_obj, 0, 5, "bold", TRUE)

  # Get marks
  marks <- am_marks(text_obj)
  expect_length(marks, 1)
  expect_equal(marks[[1]]$name, "bold")
  expect_equal(marks[[1]]$value, TRUE)
  expect_equal(marks[[1]]$start, 0)
  expect_equal(marks[[1]]$end, 5)
})

test_that("multiple marks can exist on same text", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Add multiple marks
  am_mark(text_obj, 0, 5, "bold", TRUE)
  am_mark(text_obj, 6, 11, "italic", TRUE)
  am_mark(text_obj, 2, 8, "underline", TRUE)

  # Get all marks
  marks <- am_marks(text_obj)
  expect_length(marks, 3)

  # Check mark names
  mark_names <- sapply(marks, function(m) m$name)
  expect_setequal(mark_names, c("bold", "italic", "underline"))
})

test_that("mark expand mode 'none' works correctly", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Mark with expand = "none" (positions 0-4 cover "hello")
  am_mark(text_obj, 0, 5, "bold", TRUE, expand = AM_MARK_EXPAND_NONE)

  # Insert text at start boundary (position 0)
  am_text_splice(text_obj, 0, 0, "X")

  # Mark should not expand to include new text
  marks <- am_marks(text_obj)
  expect_equal(marks[[1]]$start, 1)  # Shifted by 1
  expect_equal(marks[[1]]$end, 6)    # Shifted by 1

  # Insert text at end boundary (position 6)
  am_text_splice(text_obj, 6, 0, "Y")

  # Mark should not include new text at end
  marks <- am_marks(text_obj)
  expect_equal(marks[[1]]$start, 1)
  expect_equal(marks[[1]]$end, 6)  # Does not include "Y"
})

test_that("mark expand mode 'before' can be set", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Mark with expand = "before"
  am_mark(text_obj, 0, 5, "bold", TRUE, expand = AM_MARK_EXPAND_BEFORE)

  marks <- am_marks(text_obj)
  expect_length(marks, 1)
  expect_equal(marks[[1]]$name, "bold")
})

test_that("mark expand mode 'after' can be set", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Mark with expand = "after"
  am_mark(text_obj, 0, 5, "bold", TRUE, expand = AM_MARK_EXPAND_AFTER)

  marks <- am_marks(text_obj)
  expect_length(marks, 1)
  expect_equal(marks[[1]]$name, "bold")
})

test_that("mark expand mode 'both' can be set", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Mark with expand = "both"
  am_mark(text_obj, 0, 5, "bold", TRUE, expand = AM_MARK_EXPAND_BOTH)

  marks <- am_marks(text_obj)
  expect_length(marks, 1)
  expect_equal(marks[[1]]$name, "bold")
})

test_that("mark values support various types", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Boolean value
  am_mark(text_obj, 0, 1, "bool", TRUE)

  # Integer value
  am_mark(text_obj, 1, 2, "int", 42L)

  # Numeric value
  am_mark(text_obj, 2, 3, "num", 3.14)

  # String value
  am_mark(text_obj, 3, 4, "str", "test")

  # Note: NULL values are accepted but don't create visible marks
  # (NULL is used to clear/remove marks in automerge-c)
  am_mark(text_obj, 4, 5, "null", NULL)

  marks <- am_marks(text_obj)
  expect_length(marks, 4)  # NULL mark doesn't appear in results

  # Verify values
  expect_equal(marks[[1]]$value, TRUE)
  expect_equal(marks[[2]]$value, 42L)
  expect_equal(marks[[3]]$value, 3.14)
  expect_equal(marks[[4]]$value, "test")
})

test_that("am_marks_at returns marks at specific position", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Create overlapping marks
  am_mark(text_obj, 0, 5, "bold", TRUE)      # Covers positions 0-4
  am_mark(text_obj, 2, 8, "underline", TRUE) # Covers positions 2-7
  am_mark(text_obj, 6, 11, "italic", TRUE)   # Covers positions 6-10

  # Position 0: only "bold"
  marks_at_0 <- am_marks_at(text_obj, 0)
  expect_length(marks_at_0, 1)
  expect_equal(marks_at_0[[1]]$name, "bold")

  # Position 3: "bold" and "underline"
  marks_at_3 <- am_marks_at(text_obj, 3)
  expect_length(marks_at_3, 2)
  mark_names <- sapply(marks_at_3, function(m) m$name)
  expect_setequal(mark_names, c("bold", "underline"))

  # Position 6: "underline" and "italic"
  marks_at_6 <- am_marks_at(text_obj, 6)
  expect_length(marks_at_6, 2)
  mark_names <- sapply(marks_at_6, function(m) m$name)
  expect_setequal(mark_names, c("underline", "italic"))

  # Position 9: only "italic"
  marks_at_9 <- am_marks_at(text_obj, 9)
  expect_length(marks_at_9, 1)
  expect_equal(marks_at_9[[1]]$name, "italic")

  # Position outside all marks
  marks_at_11 <- am_marks_at(text_obj, 11)
  expect_length(marks_at_11, 0)
})

test_that("marks work with UTF-32 character indexing", {
  doc <- am_create()
  # Text with emoji (single character in UTF-32)
  am_put(doc, AM_ROOT, "text", am_text("Hello😀World"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Mark the emoji (position 5, which is where emoji is)
  am_mark(text_obj, 5, 6, "emoji", TRUE)

  marks <- am_marks(text_obj)
  expect_equal(marks[[1]]$start, 5)
  expect_equal(marks[[1]]$end, 6)
  expect_equal(marks[[1]]$name, "emoji")
})

test_that("mark validation rejects invalid inputs", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Invalid start position
  expect_error(am_mark(text_obj, -1, 3, "test", TRUE),
               "start must be non-negative")
  expect_error(am_mark(text_obj, "a", 3, "test", TRUE),
               "start must be numeric")

  # Invalid end position
  expect_error(am_mark(text_obj, 1, -1, "test", TRUE),
               "end must be non-negative")
  expect_error(am_mark(text_obj, 1, "a", "test", TRUE),
               "end must be numeric")

  # End before or equal to start
  expect_error(am_mark(text_obj, 5, 3, "test", TRUE),
               "end must be greater than start")
  expect_error(am_mark(text_obj, 3, 3, "test", TRUE),
               "end must be greater than start")

  # Invalid name
  expect_error(am_mark(text_obj, 1, 3, c("a", "b"), TRUE),
               "name must be a single character string")

  # Invalid expand mode
  expect_error(am_mark(text_obj, 1, 3, "test", TRUE, expand = "invalid"),
               "Invalid expand value")
  expect_error(am_mark(text_obj, 1, 3, "test", TRUE, expand = 123),
               "expand must be a single character string")
})

test_that("marks with counter and timestamp values", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Counter value
  counter <- structure(5L, class = "am_counter")
  am_mark(text_obj, 0, 2, "counter", counter)

  # Timestamp value
  timestamp <- as.POSIXct("2025-01-01 12:00:00", tz = "UTC")
  am_mark(text_obj, 3, 5, "timestamp", timestamp)

  marks <- am_marks(text_obj)
  expect_length(marks, 2)

  # Verify counter value
  expect_s3_class(marks[[1]]$value, "am_counter")
  expect_equal(as.integer(marks[[1]]$value), 5L)

  # Verify timestamp value
  expect_s3_class(marks[[2]]$value, "POSIXct")
})

test_that("marks return empty list when no marks exist", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  marks <- am_marks(text_obj)
  expect_length(marks, 0)

  marks_at_5 <- am_marks_at(text_obj, 5)
  expect_length(marks_at_5, 0)
})

test_that("marks work across document commits", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Create mark before commit
  am_mark(text_obj, 0, 5, "bold", TRUE)
  am_commit(doc, "Add bold mark")

  # Mark should still exist after commit
  marks <- am_marks(text_obj)
  expect_length(marks, 1)
  expect_equal(marks[[1]]$name, "bold")

  # Add another mark after commit
  am_mark(text_obj, 6, 11, "italic", TRUE)
  am_commit(doc, "Add italic mark")

  # Both marks should exist
  marks <- am_marks(text_obj)
  expect_length(marks, 2)
})

test_that("marks support raw bytes values", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Create mark with raw bytes
  raw_data <- as.raw(c(0x48, 0x65, 0x6c, 0x6c, 0x6f))
  am_mark(text_obj, 0, 5, "data", raw_data)

  # Retrieve and verify
  marks <- am_marks(text_obj)
  expect_length(marks, 1)
  expect_equal(marks[[1]]$name, "data")
  expect_type(marks[[1]]$value, "raw")
  expect_equal(marks[[1]]$value, raw_data)
})

test_that("mark values reject non-scalar POSIXct", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Vector POSIXct should fail
  timestamps <- as.POSIXct(c("2025-01-01 12:00:00", "2025-01-02 12:00:00"), tz = "UTC")
  expect_error(
    am_mark(text_obj, 0, 5, "timestamp", timestamps),
    "Mark value must be scalar"
  )
})

test_that("mark values reject non-scalar counters", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Vector counter should fail
  counters <- structure(c(1L, 2L), class = "am_counter")
  expect_error(
    am_mark(text_obj, 0, 5, "counter", counters),
    "Counter must be a scalar integer"
  )
})

test_that("mark values reject unsupported types", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # List should fail
  expect_error(
    am_mark(text_obj, 0, 5, "test", list(a = 1)),
    "Unsupported mark value type"
  )

  # Function should fail
  expect_error(
    am_mark(text_obj, 0, 5, "test", function() {}),
    "Unsupported mark value type"
  )
})

test_that("mark expand mode 'after' expands correctly", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Mark "hello" with expand = "after"
  am_mark(text_obj, 0, 5, "bold", TRUE, expand = AM_MARK_EXPAND_AFTER)

  # Insert text at end boundary (position 5, after "hello")
  am_text_splice(text_obj, 5, 0, "X")

  # Mark should expand to include "X"
  marks <- am_marks(text_obj)
  expect_equal(marks[[1]]$end, 6)
})

test_that("mark expand mode 'before' expands correctly", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Mark "hello" with expand = "before"
  am_mark(text_obj, 0, 5, "bold", TRUE, expand = AM_MARK_EXPAND_BEFORE)

  # Insert text at start boundary (position 0, before "hello")
  am_text_splice(text_obj, 0, 0, "X")

  # Mark should expand to include "X"
  marks <- am_marks(text_obj)
  expect_equal(marks[[1]]$start, 0)
  expect_equal(marks[[1]]$end, 6)
})

test_that("mark expand mode 'both' expands in both directions", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Mark "hello" with expand = "both"
  am_mark(text_obj, 0, 5, "bold", TRUE, expand = AM_MARK_EXPAND_BOTH)

  # Insert text at start
  am_text_splice(text_obj, 0, 0, "X")
  marks <- am_marks(text_obj)
  expect_equal(marks[[1]]$start, 0)
  expect_equal(marks[[1]]$end, 6)

  # Insert text at end
  am_text_splice(text_obj, 6, 0, "Y")
  marks <- am_marks(text_obj)
  expect_equal(marks[[1]]$start, 0)
  expect_equal(marks[[1]]$end, 7)
})

test_that("am_uint64 mark values round-trip correctly", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("Hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  am_mark(text_obj, 0, 5, "revision", am_uint64(12345))

  marks <- am_marks(text_obj)
  expect_length(marks, 1)
  expect_s3_class(marks[[1]]$value, "am_uint64")
  expect_equal(as.numeric(marks[[1]]$value), 12345)
})

# am_uint64 Snapshot Tests -----------------------------------------------------

test_that("am_mark with invalid am_uint64 errors", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("Hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Non-scalar am_uint64
  bad_uint <- structure(c(1, 2), class = "am_uint64")
  expect_snapshot(error = TRUE, {
    am_mark(text_obj, 0, 5, "bad", bad_uint)
  })

  # Non-numeric am_uint64
  bad_uint2 <- structure(1L, class = "am_uint64")
  expect_snapshot(error = TRUE, {
    am_mark(text_obj, 0, 5, "bad", bad_uint2)
  })
})

test_that("am_marks warns for uint64 exceeding 2^53", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("Hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  suppressWarnings(am_mark(text_obj, 0, 5, "big", am_uint64(2^54)))

  expect_snapshot({
    am_marks(text_obj)
  })
})

test_that("am_marks_at warns for uint64 exceeding 2^53", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("Hello world"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  suppressWarnings(am_mark(text_obj, 0, 5, "big", am_uint64(2^54)))

  expect_snapshot({
    am_marks_at(text_obj, 2)
  })
})

# v1.2 Mark Operations Tests --------------------------------------------------

# am_mark_clear tests

test_that("am_mark_clear() removes a mark", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("Hello World"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  am_mark(text_obj, 0, 11, "bold", TRUE)
  expect_length(am_marks(text_obj), 1)

  am_mark_clear(text_obj, 0, 11, "bold")
  expect_length(am_marks(text_obj), 0)
})

test_that("am_mark_clear() only clears specified mark", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("Hello World"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  am_mark(text_obj, 0, 11, "bold", TRUE)
  am_mark(text_obj, 0, 11, "italic", TRUE)
  expect_length(am_marks(text_obj), 2)

  am_mark_clear(text_obj, 0, 11, "bold")

  marks <- am_marks(text_obj)
  expect_length(marks, 1)
  expect_equal(marks[[1]]$name, "italic")
})

test_that("am_mark() returns text_obj invisibly", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("Hello"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  result <- withVisible(am_mark(text_obj, 0, 5, "bold", TRUE))
  expect_identical(result$value, text_obj)
  expect_false(result$visible)
})

test_that("am_mark_clear() returns text_obj invisibly", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("Hello"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  am_mark(text_obj, 0, 5, "bold", TRUE)

  result <- withVisible(am_mark_clear(text_obj, 0, 5, "bold"))
  expect_identical(result$value, text_obj)
  expect_false(result$visible)
})

test_that("am_mark_clear() errors on invalid range", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("Hello"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  expect_error(am_mark_clear(text_obj, 5, 3, "bold"), "end must be greater than start")
})

test_that("am_mark_clear() partial range", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("Hello World"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  am_mark(text_obj, 0, 11, "bold", TRUE)
  am_mark_clear(text_obj, 0, 5, "bold")

  marks <- am_marks(text_obj)
  # After clearing first half, mark should remain on second half
  expect_gte(length(marks), 1)
})

test_that("am_mark_clear() on non-existent mark is no-op", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("Hello World"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  am_mark(text_obj, 0, 11, "bold", TRUE)
  # Clear a mark that doesn't exist
  am_mark_clear(text_obj, 0, 11, "italic")

  marks <- am_marks(text_obj)
  expect_length(marks, 1)
  expect_equal(marks[[1]]$name, "bold")
})

test_that("am_mark_clear() persists after commit and save/load", {
  doc1 <- am_create()
  am_put(doc1, AM_ROOT, "text", am_text("Hello World"))
  text_obj <- am_get(doc1, AM_ROOT, "text")

  am_mark(text_obj, 0, 11, "bold", TRUE)
  am_mark(text_obj, 0, 11, "italic", TRUE)
  am_commit(doc1, "Add marks")

  am_mark_clear(text_obj, 0, 11, "bold")
  am_commit(doc1, "Clear bold")

  bytes <- am_save(doc1)
  doc2 <- am_load(bytes)
  text_obj2 <- am_get(doc2, AM_ROOT, "text")

  marks <- am_marks(text_obj2)
  expect_length(marks, 1)
  expect_equal(marks[[1]]$name, "italic")
})

test_that("am_mark_clear() with expand mode", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("Hello World"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  am_mark(text_obj, 0, 11, "bold", TRUE, expand = AM_MARK_EXPAND_BOTH)
  am_mark_clear(text_obj, 0, 11, "bold", expand = AM_MARK_EXPAND_BOTH)

  marks <- am_marks(text_obj)
  expect_length(marks, 0)
})

test_that("am_mark_clear() survives sync", {
  doc1 <- am_create()
  am_put(doc1, AM_ROOT, "text", am_text("Hello World"))
  text_obj1 <- am_get(doc1, AM_ROOT, "text")

  am_mark(text_obj1, 0, 11, "bold", TRUE)
  am_mark(text_obj1, 0, 11, "italic", TRUE)
  am_commit(doc1, "Add marks")

  doc2 <- am_fork(doc1)
  text_obj2 <- am_get(doc2, AM_ROOT, "text")

  # Clear bold in doc2
  am_mark_clear(text_obj2, 0, 11, "bold")
  am_commit(doc2, "Clear bold")

  am_merge(doc1, doc2)

  marks <- am_marks(text_obj1)
  expect_length(marks, 1)
  expect_equal(marks[[1]]$name, "italic")
})

test_that("am_mark_clear() clears overlapping marks correctly", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text("Hello World"))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Create two overlapping bold marks
  am_mark(text_obj, 0, 5, "bold", TRUE)   # "Hello"
  am_mark(text_obj, 3, 11, "bold", TRUE)  # "lo World"

  # Clear bold on full range
  am_mark_clear(text_obj, 0, 11, "bold")

  marks <- am_marks(text_obj)
  expect_length(marks, 0)
})

test_that("am_mark_clear() validates range on empty text", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "text", am_text(""))
  text_obj <- am_get(doc, AM_ROOT, "text")

  # Clearing requires end > start
  expect_error(am_mark_clear(text_obj, 0, 0, "bold"), "end must be greater than start")
})

# Coverage Tests: Input Validation and Edge Cases =============================

# am_mark input validation

test_that("am_mark() errors on non-numeric start", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  expect_error(am_mark(text_obj, "a", 5, "bold", TRUE), "start must be numeric")
})

test_that("am_mark() errors on negative start", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  expect_error(am_mark(text_obj, -1L, 5, "bold", TRUE), "non-negative")
})

test_that("am_mark() errors on non-numeric end", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  expect_error(am_mark(text_obj, 0, "a", "bold", TRUE), "end must be numeric")
})

test_that("am_mark() errors on negative end", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  expect_error(am_mark(text_obj, 0, -1L, "bold", TRUE), "non-negative")
})

test_that("am_mark() errors on end <= start", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  expect_error(am_mark(text_obj, 3, 2, "bold", TRUE), "end must be greater than start")
})

test_that("am_mark() errors on non-string name", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  expect_error(am_mark(text_obj, 0, 5, 123, TRUE), "single character string")
})

test_that("am_mark() errors on invalid expand", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  expect_error(am_mark(text_obj, 0, 5, "bold", TRUE, expand = "invalid"), "Invalid expand")
})

# am_mark with various value types

test_that("am_mark() with integer value", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  am_mark(text_obj, 0, 5, "size", 16L)
  marks <- am_marks(text_obj)
  expect_length(marks, 1)
  expect_equal(marks[[1]]$value, 16L)
})

test_that("am_mark() with double value", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  am_mark(text_obj, 0, 5, "opacity", 0.5)
  marks <- am_marks(text_obj)
  expect_length(marks, 1)
  expect_equal(marks[[1]]$value, 0.5)
})

test_that("am_mark() with string value", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  am_mark(text_obj, 0, 5, "color", "red")
  marks <- am_marks(text_obj)
  expect_length(marks, 1)
  expect_equal(marks[[1]]$value, "red")
})

test_that("am_mark() with NULL value removes the mark", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  am_mark(text_obj, 0, 5, "bold", TRUE)
  expect_length(am_marks(text_obj), 1)

  # NULL value acts as unmark
  am_mark(text_obj, 0, 5, "bold", NULL)
  expect_length(am_marks(text_obj), 0)
})

test_that("am_mark() with raw bytes value", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  am_mark(text_obj, 0, 5, "data", as.raw(c(0x01, 0x02)))
  marks <- am_marks(text_obj)
  expect_length(marks, 1)
  expect_type(marks[[1]]$value, "raw")
})

# am_mark with expand modes

test_that("am_mark() with expand = 'before'", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  am_mark(text_obj, 0, 5, "bold", TRUE, expand = AM_MARK_EXPAND_BEFORE)
  marks <- am_marks(text_obj)
  expect_length(marks, 1)
})

test_that("am_mark() with expand = 'after'", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  am_mark(text_obj, 0, 5, "bold", TRUE, expand = AM_MARK_EXPAND_AFTER)
  marks <- am_marks(text_obj)
  expect_length(marks, 1)
})

test_that("am_mark() with expand = 'both'", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  am_mark(text_obj, 0, 5, "bold", TRUE, expand = AM_MARK_EXPAND_BOTH)
  marks <- am_marks(text_obj)
  expect_length(marks, 1)
})

# am_mark_clear input validation

test_that("am_mark_clear() errors on non-numeric start", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  expect_error(am_mark_clear(text_obj, "a", 5, "bold"), "start must be numeric")
})

test_that("am_mark_clear() errors on negative start", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  expect_error(am_mark_clear(text_obj, -1L, 5, "bold"), "non-negative")
})

test_that("am_mark_clear() errors on non-numeric end", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  expect_error(am_mark_clear(text_obj, 0, "a", "bold"), "end must be numeric")
})

test_that("am_mark_clear() errors on negative end", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  expect_error(am_mark_clear(text_obj, 0, -1L, "bold"), "non-negative")
})

test_that("am_mark_clear() errors on non-string name", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  expect_error(am_mark_clear(text_obj, 0, 5, 123), "single character string")
})

# am_marks_at input validation

test_that("am_marks_at() errors on non-numeric position", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  expect_error(am_marks_at(text_obj, "a"), "position must be numeric")
})

test_that("am_marks_at() errors on negative position", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  expect_error(am_marks_at(text_obj, -1L), "non-negative")
})

test_that("am_marks_at() errors on non-scalar position", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  expect_error(am_marks_at(text_obj, c(0, 1)), "scalar")
})

# am_text_update for diffing

test_that("am_text_update() with identical strings is no-op", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t

  am_text_update(text_obj, "hello", "hello")
  expect_equal(am_text_content(text_obj), "hello")
})

test_that("am_text_update() errors on non-string arguments", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  expect_error(am_text_update(text_obj, 123, "hello"), "single string")
  expect_error(am_text_update(text_obj, "hello", 123), "single string")
})

test_that("am_text_update() errors on NA strings", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  expect_error(am_text_update(text_obj, NA_character_, "hello"), "NA strings")
  expect_error(am_text_update(text_obj, "hello", NA_character_), "NA strings")
})

# am_counter_increment in lists

test_that("am_counter_increment() in list by position", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
  items <- am_get(doc, AM_ROOT, "items")
  am_insert(doc, items, 1, am_counter(0))

  am_counter_increment(doc, items, 1, 5L)
  val <- am_get(doc, items, 1)
  expect_s3_class(val, "am_counter")
  expect_equal(as.integer(val), 5L)
})

test_that("am_counter_increment() errors on non-scalar delta", {
  doc <- am_create()
  doc$cnt <- am_counter(0)
  expect_error(am_counter_increment(doc, AM_ROOT, "cnt", c(1L, 2L)), "scalar")
})

test_that("am_counter_increment() errors on non-numeric delta", {
  doc <- am_create()
  doc$cnt <- am_counter(0)
  expect_error(am_counter_increment(doc, AM_ROOT, "cnt", "one"), "numeric")
})

# am_mark_clear() non-scalar validation

test_that("am_mark_clear() errors on non-scalar start", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  expect_error(am_mark_clear(text_obj, c(0, 1), 5, "bold"), "scalar")
})

test_that("am_mark_clear() errors on non-scalar end", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  expect_error(am_mark_clear(text_obj, 0, c(5, 6), "bold"), "scalar")
})

# am_mark() non-scalar validation

test_that("am_mark() errors on non-scalar start", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  expect_error(am_mark(text_obj, c(0, 1), 5, "bold", TRUE), "scalar")
})

test_that("am_mark() errors on non-scalar end", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  expect_error(am_mark(text_obj, 0, c(5, 6), "bold", TRUE), "scalar")
})

# am_marks with heads parameter

test_that("am_marks() with historical heads", {
  doc <- am_create()
  doc$t <- am_text("hello world")
  text_obj <- doc$t
  am_commit(doc)
  heads_v1 <- am_get_heads(doc)

  am_mark(text_obj, 0, 5, "bold", TRUE)
  am_commit(doc)

  # At v1, no marks exist
  marks_v1 <- am_marks(text_obj, heads_v1)
  expect_length(marks_v1, 0)

  # At current, mark exists
  marks_now <- am_marks(text_obj)
  expect_length(marks_now, 1)
})

# am_marks_at filtering

test_that("am_marks_at() filters by position correctly", {
  doc <- am_create()
  doc$t <- am_text("hello world")
  text_obj <- doc$t

  am_mark(text_obj, 0, 5, "bold", TRUE)    # "hello"
  am_mark(text_obj, 6, 11, "italic", TRUE) # "world"

  marks_at_2 <- am_marks_at(text_obj, 2)
  expect_length(marks_at_2, 1)
  expect_equal(marks_at_2[[1]]$name, "bold")

  marks_at_7 <- am_marks_at(text_obj, 7)
  expect_length(marks_at_7, 1)
  expect_equal(marks_at_7[[1]]$name, "italic")

  # Position between marks
  marks_at_5 <- am_marks_at(text_obj, 5)
  expect_length(marks_at_5, 0)
})
