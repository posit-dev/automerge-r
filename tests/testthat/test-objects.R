# Object Operations Tests (Phase 2)

# Map Operations --------------------------------------------------------------

test_that("am_put() works with map (root)", {
  doc <- am_create()
  result <- am_put(doc, AM_ROOT, "key", "value")
  expect_identical(result, doc) # Returns doc invisibly
})

test_that("am_get() retrieves map values", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "name", "Alice")
  am_put(doc, AM_ROOT, "age", 30L)

  expect_equal(am_get(doc, AM_ROOT, "name"), "Alice")
  expect_equal(am_get(doc, AM_ROOT, "age"), 30L)
})

test_that("am_get() returns NULL for missing keys", {
  doc <- am_create()
  result <- am_get(doc, AM_ROOT, "nonexistent")
  expect_null(result)
})

test_that("am_put() supports all scalar types", {
  doc <- am_create()

  # NULL
  am_put(doc, AM_ROOT, "null_val", NULL)
  expect_null(am_get(doc, AM_ROOT, "null_val"))

  # Logical
  am_put(doc, AM_ROOT, "bool_val", TRUE)
  expect_equal(am_get(doc, AM_ROOT, "bool_val"), TRUE)

  # Integer
  am_put(doc, AM_ROOT, "int_val", 42L)
  expect_equal(am_get(doc, AM_ROOT, "int_val"), 42L)

  # Numeric (double)
  am_put(doc, AM_ROOT, "num_val", 3.14)
  expect_equal(am_get(doc, AM_ROOT, "num_val"), 3.14)

  # String
  am_put(doc, AM_ROOT, "str_val", "hello")
  expect_equal(am_get(doc, AM_ROOT, "str_val"), "hello")

  # Raw bytes
  raw_val <- as.raw(c(1, 2, 3, 4))
  am_put(doc, AM_ROOT, "raw_val", raw_val)
  expect_equal(am_get(doc, AM_ROOT, "raw_val"), raw_val)
})

test_that("am_keys() returns all map keys", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "a", 1)
  am_put(doc, AM_ROOT, "b", 2)
  am_put(doc, AM_ROOT, "c", 3)

  keys <- am_keys(doc, AM_ROOT)
  expect_type(keys, "character")
  expect_length(keys, 3)
  expect_true(all(c("a", "b", "c") %in% keys))
})

test_that("am_keys() returns empty vector for empty map", {
  doc <- am_create()
  keys <- am_keys(doc, AM_ROOT)
  expect_type(keys, "character")
  expect_length(keys, 0)
})

test_that("am_length() returns map size", {
  doc <- am_create()
  expect_equal(am_length(doc, AM_ROOT), 0L)

  am_put(doc, AM_ROOT, "a", 1)
  expect_equal(am_length(doc, AM_ROOT), 1L)

  am_put(doc, AM_ROOT, "b", 2)
  expect_equal(am_length(doc, AM_ROOT), 2L)
})

test_that("am_delete() removes map entries", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")
  expect_equal(am_length(doc, AM_ROOT), 1L)

  am_delete(doc, AM_ROOT, "key")
  expect_equal(am_length(doc, AM_ROOT), 0L)
  expect_null(am_get(doc, AM_ROOT, "key"))
})

test_that("am_put() updates existing keys", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value1")
  expect_equal(am_get(doc, AM_ROOT, "key"), "value1")

  am_put(doc, AM_ROOT, "key", "value2")
  expect_equal(am_get(doc, AM_ROOT, "key"), "value2")
  expect_equal(am_length(doc, AM_ROOT), 1L) # Still only 1 key
})

# List Operations -------------------------------------------------------------

test_that("am_put() creates and works with lists", {
  doc <- am_create()

  # Create a list (returns doc, retrieve with am_get)
  am_put(doc, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
  list_obj <- am_get(doc, AM_ROOT, "items")

  # am_object is now an external pointer with am_object class
  expect_s3_class(list_obj, "am_object")
  expect_s3_class(list_obj, "am_list")
  expect_type(list_obj, "externalptr")
})

test_that("am_put() appends to lists with 'end'", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)
  list_obj <- am_get(doc, AM_ROOT, "list")

  # Append items
  am_put(doc, list_obj, "end", "first")
  am_put(doc, list_obj, "end", "second")
  am_put(doc, list_obj, "end", "third")

  expect_equal(am_length(doc, list_obj), 3L)
})

test_that("am_get() retrieves list elements by position", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)
  list_obj <- am_get(doc, AM_ROOT, "list")

  am_put(doc, list_obj, "end", "first")
  am_put(doc, list_obj, "end", "second")

  # 1-based indexing
  expect_equal(am_get(doc, list_obj, 1L), "first")
  expect_equal(am_get(doc, list_obj, 2L), "second")
})

test_that("am_put() replaces list elements at position", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)
  list_obj <- am_get(doc, AM_ROOT, "list")

  am_put(doc, list_obj, "end", "original")
  am_put(doc, list_obj, 1L, "replaced")

  expect_equal(am_get(doc, list_obj, 1L), "replaced")
  expect_equal(am_length(doc, list_obj), 1L) # Still 1 element
})

test_that("am_delete() removes list elements", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)
  list_obj <- am_get(doc, AM_ROOT, "list")

  am_put(doc, list_obj, "end", "first")
  am_put(doc, list_obj, "end", "second")
  am_put(doc, list_obj, "end", "third")

  expect_equal(am_length(doc, list_obj), 3L)

  am_delete(doc, list_obj, 2L) # Delete "second"
  expect_equal(am_length(doc, list_obj), 2L)

  # Remaining elements shift down
  expect_equal(am_get(doc, list_obj, 1L), "first")
  expect_equal(am_get(doc, list_obj, 2L), "third")
})

# Nested Objects --------------------------------------------------------------

test_that("am_put() creates nested maps", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "person", AM_OBJ_TYPE_MAP)
  person_obj <- am_get(doc, AM_ROOT, "person")

  expect_s3_class(person_obj, "am_object")

  # Add fields to nested map
  am_put(doc, person_obj, "name", "Bob")
  am_put(doc, person_obj, "age", 25L)

  expect_equal(am_get(doc, person_obj, "name"), "Bob")
  expect_equal(am_get(doc, person_obj, "age"), 25L)
})

test_that("Multiple levels of nesting work", {
  doc <- am_create()

  # Level 1: root -> "data" (map)
  am_put(doc, AM_ROOT, "data", AM_OBJ_TYPE_MAP)
  data_obj <- am_get(doc, AM_ROOT, "data")

  # Level 2: data -> "users" (list)
  am_put(doc, data_obj, "users", AM_OBJ_TYPE_LIST)
  users_obj <- am_get(doc, data_obj, "users")

  # Level 3: users[0] -> user (map)
  am_put(doc, users_obj, "end", AM_OBJ_TYPE_MAP)
  user_obj <- am_get(doc, users_obj, 1)  # Get first element (just added)

  # Level 4: user -> "name"
  am_put(doc, user_obj, "name", "Charlie")

  # Verify
  expect_equal(am_get(doc, user_obj, "name"), "Charlie")
})

# Integration Tests -----------------------------------------------------------

test_that("Map operations integrate with commit/save/load", {
  doc1 <- am_create()
  am_put(doc1, AM_ROOT, "x", 1)
  am_put(doc1, AM_ROOT, "y", 2)
  am_commit(doc1, "Add x and y")

  # Save and load
  bytes <- am_save(doc1)
  doc2 <- am_load(bytes)

  # Verify values survived
  expect_equal(am_get(doc2, AM_ROOT, "x"), 1)
  expect_equal(am_get(doc2, AM_ROOT, "y"), 2)
  expect_equal(am_length(doc2, AM_ROOT), 2L)
})

test_that("List operations integrate with commit/save/load", {
  doc1 <- am_create()
  am_put(doc1, AM_ROOT, "list", AM_OBJ_TYPE_LIST)
  list_obj <- am_get(doc1, AM_ROOT, "list")

  am_put(doc1, list_obj, "end", "a")
  am_put(doc1, list_obj, "end", "b")
  am_commit(doc1, "Create list")

  # Save and load
  bytes <- am_save(doc1)
  doc2 <- am_load(bytes)

  # Get list from loaded doc
  list_obj2 <- am_get(doc2, AM_ROOT, "list")
  expect_equal(am_length(doc2, list_obj2), 2L)
  expect_equal(am_get(doc2, list_obj2, 1L), "a")
  expect_equal(am_get(doc2, list_obj2, 2L), "b")
})

test_that("Merge works with object operations", {
  doc1 <- am_create()
  doc2 <- am_create()

  # Make changes in each doc
  am_put(doc1, AM_ROOT, "x", 1)
  am_commit(doc1, "Add x")

  am_put(doc2, AM_ROOT, "y", 2)
  am_commit(doc2, "Add y")

  # Merge doc2 into doc1
  am_merge(doc1, doc2)

  # Both keys should be present
  expect_equal(am_get(doc1, AM_ROOT, "x"), 1)
  expect_equal(am_get(doc1, AM_ROOT, "y"), 2)
  expect_equal(am_length(doc1, AM_ROOT), 2L)
})

test_that("Complex document structure", {
  doc <- am_create()

  # Create a document structure like:
  # {
  #   "title": "My Doc",
  #   "tags": ["tag1", "tag2"],
  #   "author": { "name": "Alice", "email": "alice@example.com" }
  # }

  am_put(doc, AM_ROOT, "title", "My Doc")

  am_put(doc, AM_ROOT, "tags", AM_OBJ_TYPE_LIST)
  tags_obj <- am_get(doc, AM_ROOT, "tags")
  am_put(doc, tags_obj, "end", "tag1")
  am_put(doc, tags_obj, "end", "tag2")

  am_put(doc, AM_ROOT, "author", AM_OBJ_TYPE_MAP)
  author_obj <- am_get(doc, AM_ROOT, "author")
  am_put(doc, author_obj, "name", "Alice")
  am_put(doc, author_obj, "email", "alice@example.com")

  # Verify structure
  expect_equal(am_get(doc, AM_ROOT, "title"), "My Doc")
  expect_equal(am_length(doc, tags_obj), 2L)
  expect_equal(am_get(doc, tags_obj, 1L), "tag1")
  expect_equal(am_get(doc, author_obj, "name"), "Alice")
  expect_equal(am_get(doc, author_obj, "email"), "alice@example.com")
})

# Edge Cases ------------------------------------------------------------------

test_that("am_put replaces nested object with scalar", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", list(nested = "data"))

  nested <- am_get(doc, AM_ROOT, "key")
  expect_s3_class(nested, "am_object")

  am_put(doc, AM_ROOT, "key", "scalar")
  expect_equal(am_get(doc, AM_ROOT, "key"), "scalar")
})

test_that("am_put replaces scalar with nested object", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "scalar")
  expect_equal(am_get(doc, AM_ROOT, "key"), "scalar")

  am_put(doc, AM_ROOT, "key", list(nested = "data"))
  nested <- am_get(doc, AM_ROOT, "key")
  expect_s3_class(nested, "am_object")
  expect_equal(am_get(doc, nested, "nested"), "data")
})

test_that("am_delete then re-add same key", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value1")
  am_delete(doc, AM_ROOT, "key")
  expect_null(am_get(doc, AM_ROOT, "key"))

  am_put(doc, AM_ROOT, "key", "value2")
  expect_equal(am_get(doc, AM_ROOT, "key"), "value2")
})

test_that("am_delete then re-add maintains different value", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", 100)
  am_commit(doc)
  am_delete(doc, AM_ROOT, "key")
  am_put(doc, AM_ROOT, "key", 200)

  expect_equal(am_get(doc, AM_ROOT, "key"), 200)
})

test_that("am_keys preserves keys after delete and re-add", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "a", 1)
  am_put(doc, AM_ROOT, "b", 2)
  am_delete(doc, AM_ROOT, "a")
  am_put(doc, AM_ROOT, "a", 3)

  keys <- am_keys(doc, AM_ROOT)
  expect_length(keys, 2)
  expect_true(all(c("a", "b") %in% keys))
})

test_that("am_put with UTF-8 keys", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "键", "value")
  am_put(doc, AM_ROOT, "clé", "value")
  am_put(doc, AM_ROOT, "🔑", "value")

  expect_equal(am_get(doc, AM_ROOT, "键"), "value")
  expect_equal(am_get(doc, AM_ROOT, "clé"), "value")
  expect_equal(am_get(doc, AM_ROOT, "🔑"), "value")

  keys <- am_keys(doc, AM_ROOT)
  expect_true(all(c("键", "clé", "🔑") %in% keys))
})

test_that("am_put with UTF-8 string values", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "chinese", "你好世界")
  am_put(doc, AM_ROOT, "emoji", "🎉🎊🎈")
  am_put(doc, AM_ROOT, "mixed", "Hello 世界 🌍")

  expect_equal(am_get(doc, AM_ROOT, "chinese"), "你好世界")
  expect_equal(am_get(doc, AM_ROOT, "emoji"), "🎉🎊🎈")
  expect_equal(am_get(doc, AM_ROOT, "mixed"), "Hello 世界 🌍")
})

test_that("am_put with very long key name", {
  doc <- am_create()
  long_key <- paste(rep("key", 1000), collapse = "_")
  am_put(doc, AM_ROOT, long_key, "value")
  expect_equal(am_get(doc, AM_ROOT, long_key), "value")
})

test_that("am_put handles zero values correctly", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "zero_int", 0L)
  am_put(doc, AM_ROOT, "zero_dbl", 0.0)

  expect_identical(am_get(doc, AM_ROOT, "zero_int"), 0L)
  expect_identical(am_get(doc, AM_ROOT, "zero_dbl"), 0.0)
})

test_that("am_put handles negative numbers", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "neg_int", -42L)
  am_put(doc, AM_ROOT, "neg_dbl", -3.14)

  expect_equal(am_get(doc, AM_ROOT, "neg_int"), -42L)
  expect_equal(am_get(doc, AM_ROOT, "neg_dbl"), -3.14)
})

test_that("am_put handles very small and very large doubles", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "small", 1e-308)
  am_put(doc, AM_ROOT, "large", 1e308)

  expect_equal(am_get(doc, AM_ROOT, "small"), 1e-308)
  expect_equal(am_get(doc, AM_ROOT, "large"), 1e308)
})

test_that("am_length updates correctly after mixed operations", {
  doc <- am_create()
  expect_equal(am_length(doc, AM_ROOT), 0L)

  am_put(doc, AM_ROOT, "a", 1)
  am_put(doc, AM_ROOT, "b", 2)
  expect_equal(am_length(doc, AM_ROOT), 2L)

  am_delete(doc, AM_ROOT, "a")
  expect_equal(am_length(doc, AM_ROOT), 1L)

  am_put(doc, AM_ROOT, "c", 3)
  expect_equal(am_length(doc, AM_ROOT), 2L)

  am_put(doc, AM_ROOT, "b", 22)
  expect_equal(am_length(doc, AM_ROOT), 2L)
})

test_that("list operations maintain order after deletions", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)
  list_obj <- am_get(doc, AM_ROOT, "list")

  am_put(doc, list_obj, "end", "A")
  am_put(doc, list_obj, "end", "B")
  am_put(doc, list_obj, "end", "C")
  am_put(doc, list_obj, "end", "D")

  am_delete(doc, list_obj, 2)

  expect_equal(am_get(doc, list_obj, 1), "A")
  expect_equal(am_get(doc, list_obj, 2), "C")
  expect_equal(am_get(doc, list_obj, 3), "D")
  expect_equal(am_length(doc, list_obj), 3L)
})

test_that("multiple sequential deletes from list", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)
  list_obj <- am_get(doc, AM_ROOT, "list")

  for (i in 1:5) am_put(doc, list_obj, "end", i)
  expect_equal(am_length(doc, list_obj), 5L)

  am_delete(doc, list_obj, 3)
  am_delete(doc, list_obj, 1)
  am_delete(doc, list_obj, 2)

  expect_equal(am_length(doc, list_obj), 2L)
})

test_that("empty nested structures", {
  doc <- am_create()

  am_put(doc, AM_ROOT, "empty_map", AM_OBJ_TYPE_MAP)
  empty_map <- am_get(doc, AM_ROOT, "empty_map")
  expect_equal(am_length(doc, empty_map), 0L)
  expect_equal(am_keys(doc, empty_map), character(0))

  am_put(doc, AM_ROOT, "empty_list", AM_OBJ_TYPE_LIST)
  empty_list <- am_get(doc, AM_ROOT, "empty_list")
  expect_equal(am_length(doc, empty_list), 0L)
})

test_that("nested structures persist after save/load", {
  doc1 <- am_create()

  am_put(doc1, AM_ROOT, "outer", AM_OBJ_TYPE_MAP)
  outer <- am_get(doc1, AM_ROOT, "outer")
  am_put(doc1, outer, "inner", AM_OBJ_TYPE_MAP)
  inner <- am_get(doc1, outer, "inner")
  am_put(doc1, inner, "value", 42)

  binary <- am_save(doc1)
  doc2 <- am_load(binary)

  outer2 <- am_get(doc2, AM_ROOT, "outer")
  inner2 <- am_get(doc2, outer2, "inner")
  expect_equal(am_get(doc2, inner2, "value"), 42)
})

# am_insert() Tests -----------------------------------------------------------

test_that("am_insert() inserts at position and shifts elements", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)
  list_obj <- am_get(doc, AM_ROOT, "list")

  am_put(doc, list_obj, "end", "A")
  am_put(doc, list_obj, "end", "C")

  # Insert "B" at position 2 - should shift "C" to position 3
  am_insert(doc, list_obj, 2L, "B")

  expect_equal(am_length(doc, list_obj), 3L)
  expect_equal(am_get(doc, list_obj, 1L), "A")
  expect_equal(am_get(doc, list_obj, 2L), "B")
  expect_equal(am_get(doc, list_obj, 3L), "C")
})

test_that("am_insert() at position 1 prepends to list", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)
  list_obj <- am_get(doc, AM_ROOT, "list")

  am_put(doc, list_obj, "end", "B")
  am_put(doc, list_obj, "end", "C")

  # Insert at position 1 - should shift everything down
  am_insert(doc, list_obj, 1L, "A")

  expect_equal(am_length(doc, list_obj), 3L)
  expect_equal(am_get(doc, list_obj, 1L), "A")
  expect_equal(am_get(doc, list_obj, 2L), "B")
  expect_equal(am_get(doc, list_obj, 3L), "C")
})

test_that("am_insert() vs am_put() behavior differs", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)
  list_obj <- am_get(doc, AM_ROOT, "list")

  am_put(doc, list_obj, "end", "A")
  am_put(doc, list_obj, "end", "B")

  # am_put replaces
  am_put(doc, list_obj, 2L, "REPLACED")
  expect_equal(am_length(doc, list_obj), 2L)
  expect_equal(am_get(doc, list_obj, 2L), "REPLACED")

  # am_insert shifts
  am_insert(doc, list_obj, 2L, "INSERTED")
  expect_equal(am_length(doc, list_obj), 3L)
  expect_equal(am_get(doc, list_obj, 2L), "INSERTED")
  expect_equal(am_get(doc, list_obj, 3L), "REPLACED")
})

test_that("am_insert() appends with 'end'", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)
  list_obj <- am_get(doc, AM_ROOT, "list")

  am_insert(doc, list_obj, "end", "first")
  am_insert(doc, list_obj, "end", "second")

  expect_equal(am_length(doc, list_obj), 2L)
  expect_equal(am_get(doc, list_obj, 1L), "first")
  expect_equal(am_get(doc, list_obj, 2L), "second")
})

test_that("am_insert() returns doc invisibly", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)
  list_obj <- am_get(doc, AM_ROOT, "list")

  result <- withVisible(am_insert(doc, list_obj, "end", "value"))

  expect_identical(result$value, doc)
  expect_false(result$visible)
})

test_that("am_insert() only works on lists", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "map", AM_OBJ_TYPE_MAP)
  map_obj <- am_get(doc, AM_ROOT, "map")

  expect_error(
    am_insert(doc, map_obj, 1L, "value"),
    "can only be used on list objects"
  )
})

# Type Constructors -----------------------------------------------------------

test_that("am_counter() creates counter with default value", {
  counter <- am_counter()

  expect_s3_class(counter, "am_counter")
  expect_equal(as.integer(counter), 0L)
})

test_that("am_counter() creates counter with specified value", {
  counter <- am_counter(42)

  expect_s3_class(counter, "am_counter")
  expect_equal(as.integer(counter), 42L)
})

test_that("am_counter() coerces to integer", {
  counter <- am_counter(3.7)

  expect_equal(as.integer(counter), 3L)
})

# Counter Increment Tests -----------------------------------------------------

test_that("am_counter_increment() increments counter in map", {
  doc <- am_create()
  doc$score <- am_counter(0)

  am_counter_increment(doc, AM_ROOT, "score", 10)
  expect_equal(doc$score, 10)

  am_counter_increment(doc, AM_ROOT, "score", 5)
  expect_equal(doc$score, 15)
})

test_that("am_counter_increment() accepts negative delta", {
  doc <- am_create()
  doc$score <- am_counter(100)

  am_counter_increment(doc, AM_ROOT, "score", -30)
  expect_equal(doc$score, 70)

  am_counter_increment(doc, AM_ROOT, "score", -70)
  expect_equal(doc$score, 0)
})

test_that("am_counter_increment() works in nested map", {
  doc <- am_create()
  doc$stats <- am_map(views = am_counter(0), likes = am_counter(0))
  stats_obj <- doc$stats

  am_counter_increment(doc, stats_obj, "views", 100)
  am_counter_increment(doc, stats_obj, "likes", 5)

  expect_equal(am_get(doc, stats_obj, "views"), 100)
  expect_equal(am_get(doc, stats_obj, "likes"), 5)
})

test_that("am_counter_increment() works in list (1-based indexing)", {
  doc <- am_create()
  doc$counters <- list(am_counter(0), am_counter(10), am_counter(20))
  counters_obj <- doc$counters

  am_counter_increment(doc, counters_obj, 1, 5)
  am_counter_increment(doc, counters_obj, 2, 3)
  am_counter_increment(doc, counters_obj, 3, 1)

  expect_equal(am_get(doc, counters_obj, 1), 5)
  expect_equal(am_get(doc, counters_obj, 2), 13)
  expect_equal(am_get(doc, counters_obj, 3), 21)
})

test_that("am_counter_increment() multiple increments accumulate", {
  doc <- am_create()
  doc$count <- am_counter(0)

  for (i in 1:10) {
    am_counter_increment(doc, AM_ROOT, "count", 1)
  }

  expect_equal(doc$count, 10)
})

test_that("am_counter_increment() returns doc invisibly", {
  doc <- am_create()
  doc$score <- am_counter(0)

  result <- withVisible(am_counter_increment(doc, AM_ROOT, "score", 5))

  expect_identical(result$value, doc)
  expect_false(result$visible)
})

test_that("am_counter_increment() coerces numeric to integer", {
  doc <- am_create()
  doc$score <- am_counter(0)

  am_counter_increment(doc, AM_ROOT, "score", 10.7)
  expect_equal(doc$score, 10)
})

test_that("am_counter_increment() persists after save/load", {
  doc1 <- am_create()
  doc1$score <- am_counter(5)
  am_counter_increment(doc1, AM_ROOT, "score", 10)
  am_commit(doc1, "Increment counter")

  bytes <- am_save(doc1)
  doc2 <- am_load(bytes)

  expect_equal(doc2$score, 15)

  am_counter_increment(doc2, AM_ROOT, "score", 3)
  expect_equal(doc2$score, 18)
})

test_that("am_counter_increment() concurrent increments merge correctly", {
  doc1 <- am_create()
  doc1$counter <- am_counter(0)
  am_commit(doc1, "Create counter")

  bytes <- am_save(doc1)
  doc2 <- am_load(bytes)

  am_counter_increment(doc1, AM_ROOT, "counter", 5)
  am_commit(doc1, "Doc1 increments by 5")

  am_counter_increment(doc2, AM_ROOT, "counter", 10)
  am_commit(doc2, "Doc2 increments by 10")

  am_merge(doc1, doc2)

  expect_equal(doc1$counter, 15)
})

test_that("am_counter_increment() errors on wrong object type", {
  doc <- am_create()
  doc$text <- am_text("hello")
  text_obj <- doc$text

  expect_error(
    am_counter_increment(doc, text_obj, 1, 5),
    "Cannot increment counter in text object"
  )
})

test_that("am_list() creates empty list", {
  result <- am_list()

  expect_s3_class(result, "am_list_type")
  expect_s3_class(result, "list")
  expect_length(result, 0)
})

test_that("am_list() creates list with elements", {
  result <- am_list("a", "b", "c")

  expect_s3_class(result, "am_list_type")
  expect_length(result, 3)
  expect_equal(result[[1]], "a")
  expect_equal(result[[2]], "b")
  expect_equal(result[[3]], "c")
})

test_that("am_list() handles mixed types", {
  result <- am_list(1L, "text", TRUE, 3.14)

  expect_length(result, 4)
  expect_equal(result[[1]], 1L)
  expect_equal(result[[2]], "text")
  expect_equal(result[[3]], TRUE)
  expect_equal(result[[4]], 3.14)
})

test_that("am_map() creates empty map", {
  result <- am_map()

  expect_s3_class(result, "am_map_type")
  expect_s3_class(result, "list")
  expect_length(result, 0)
})

test_that("am_map() creates map with named elements", {
  result <- am_map(key1 = "value1", key2 = "value2")

  expect_s3_class(result, "am_map_type")
  expect_length(result, 2)
  expect_equal(result$key1, "value1")
  expect_equal(result$key2, "value2")
  expect_equal(names(result), c("key1", "key2"))
})

test_that("am_map() handles mixed value types", {
  result <- am_map(int = 1L, str = "text", bool = TRUE, dbl = 3.14)

  expect_length(result, 4)
  expect_equal(result$int, 1L)
  expect_equal(result$str, "text")
  expect_equal(result$bool, TRUE)
  expect_equal(result$dbl, 3.14)
})

test_that("am_text() creates empty text object", {
  result <- am_text()

  expect_s3_class(result, "am_text_type")
  expect_s3_class(result, "character")
  expect_equal(as.character(result), "")
})

test_that("am_text() creates text with initial content", {
  result <- am_text("Hello, World!")

  expect_s3_class(result, "am_text_type")
  expect_equal(as.character(result), "Hello, World!")
})

test_that("am_text() requires scalar string", {
  expect_error(am_text(c("a", "b")), "single character string")
  expect_error(am_text(123), "single character string")
  expect_error(am_text(NULL), "single character string")
})

# Text Operations -------------------------------------------------------------

test_that("am_text_splice() inserts text", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "doc", am_text("Hello"))
  text_obj <- am_get(doc, AM_ROOT, "doc")

  am_text_splice(text_obj, 5, 0, " World")

  result <- am_text_content(text_obj)
  expect_equal(result, "Hello World")
})

test_that("am_text_splice() deletes text", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "doc", am_text("Hello World"))
  text_obj <- am_get(doc, AM_ROOT, "doc")

  am_text_splice(text_obj, 5, 6, "")

  result <- am_text_content(text_obj)
  expect_equal(result, "Hello")
})

test_that("am_text_splice() replaces text", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "doc", am_text("Hello World"))
  text_obj <- am_get(doc, AM_ROOT, "doc")

  am_text_splice(text_obj, 6, 5, "Claude")

  result <- am_text_content(text_obj)
  expect_equal(result, "Hello Claude")
})

test_that("am_text_splice() at position 0 prepends", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "doc", am_text("World"))
  text_obj <- am_get(doc, AM_ROOT, "doc")

  am_text_splice(text_obj, 0, 0, "Hello ")

  result <- am_text_content(text_obj)
  expect_equal(result, "Hello World")
})

test_that("am_text_splice() returns text_obj invisibly", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "doc", am_text("test"))
  text_obj <- am_get(doc, AM_ROOT, "doc")

  result <- withVisible(am_text_splice(text_obj, 0, 0, "x"))

  expect_identical(result$value, text_obj)
  expect_false(result$visible)
})

test_that("am_text_splice() handles UTF-8 text (character indexing)", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "doc", am_text(""))
  text_obj <- am_get(doc, AM_ROOT, "doc")

  am_text_splice(text_obj, 0, 0, "你好")
  char_len <- nchar("你好")  # Natural R character counting!
  am_text_splice(text_obj, char_len, 0, "世界")

  result <- am_text_content(text_obj)
  expect_equal(result, "你好世界")
})

test_that("am_text_splice() handles emoji", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "doc", am_text("Hello"))
  text_obj <- am_get(doc, AM_ROOT, "doc")

  am_text_splice(text_obj, 5, 0, " 🌍")

  result <- am_text_content(text_obj)
  expect_equal(result, "Hello 🌍")
})

test_that("am_text_content() returns text from text object", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "doc", am_text("Test content"))
  text_obj <- am_get(doc, AM_ROOT, "doc")

  result <- am_text_content(text_obj)

  expect_type(result, "character")
  expect_length(result, 1)
  expect_equal(result, "Test content")
})

test_that("am_text_content() returns empty string for empty text", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "doc", am_text())
  text_obj <- am_get(doc, AM_ROOT, "doc")

  result <- am_text_content(text_obj)

  expect_equal(result, "")
})

test_that("text objects persist after save/load", {
  doc1 <- am_create()
  am_put(doc1, AM_ROOT, "doc", am_text("Original"))
  text_obj <- am_get(doc1, AM_ROOT, "doc")
  am_text_splice(text_obj, 8, 0, " Text")

  binary <- am_save(doc1)
  doc2 <- am_load(binary)

  text_obj2 <- am_get(doc2, AM_ROOT, "doc")
  result <- am_text_content(text_obj2)
  expect_equal(result, "Original Text")
})

test_that("multiple text edits accumulate correctly", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "doc", am_text(""))
  text_obj <- am_get(doc, AM_ROOT, "doc")

  am_text_splice(text_obj, 0, 0, "The")
  am_text_splice(text_obj, 3, 0, " quick")
  am_text_splice(text_obj, 9, 0, " brown")
  am_text_splice(text_obj, 15, 0, " fox")

  result <- am_text_content(text_obj)
  expect_equal(result, "The quick brown fox")
})

# am_text_update() Tests ----------------------------------------------------

test_that("am_text_update() inserts text at end", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "content", am_text("Hello"))
  text_obj <- am_get(doc, AM_ROOT, "content")

  am_text_update(text_obj, "Hello", "Hello World")

  expect_equal(am_text_content(text_obj), "Hello World")
})

test_that("am_text_update() inserts text at beginning", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "content", am_text("World"))
  text_obj <- am_get(doc, AM_ROOT, "content")

  am_text_update(text_obj, "World", "Hello World")

  expect_equal(am_text_content(text_obj), "Hello World")
})

test_that("am_text_update() inserts text in middle", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "content", am_text("HelloWorld"))
  text_obj <- am_get(doc, AM_ROOT, "content")

  am_text_update(text_obj, "HelloWorld", "Hello World")

  expect_equal(am_text_content(text_obj), "Hello World")
})

test_that("am_text_update() deletes text at end", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "content", am_text("Hello World"))
  text_obj <- am_get(doc, AM_ROOT, "content")

  am_text_update(text_obj, "Hello World", "Hello")

  expect_equal(am_text_content(text_obj), "Hello")
})

test_that("am_text_update() deletes text at beginning", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "content", am_text("Hello World"))
  text_obj <- am_get(doc, AM_ROOT, "content")

  am_text_update(text_obj, "Hello World", "World")

  expect_equal(am_text_content(text_obj), "World")
})

test_that("am_text_update() deletes text in middle", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "content", am_text("Hello World"))
  text_obj <- am_get(doc, AM_ROOT, "content")

  am_text_update(text_obj, "Hello World", "HelloWorld")

  expect_equal(am_text_content(text_obj), "HelloWorld")
})

test_that("am_text_update() replaces text", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "content", am_text("Hello World"))
  text_obj <- am_get(doc, AM_ROOT, "content")

  am_text_update(text_obj, "Hello World", "Hello Claude")

  expect_equal(am_text_content(text_obj), "Hello Claude")
})

test_that("am_text_update() handles identical strings (no-op)", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "content", am_text("Hello"))
  text_obj <- am_get(doc, AM_ROOT, "content")

  am_text_update(text_obj, "Hello", "Hello")

  expect_equal(am_text_content(text_obj), "Hello")
})

test_that("am_text_update() handles empty to non-empty", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "content", am_text(""))
  text_obj <- am_get(doc, AM_ROOT, "content")

  am_text_update(text_obj, "", "Hello")

  expect_equal(am_text_content(text_obj), "Hello")
})

test_that("am_text_update() handles non-empty to empty", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "content", am_text("Hello"))
  text_obj <- am_get(doc, AM_ROOT, "content")

  am_text_update(text_obj, "Hello", "")

  expect_equal(am_text_content(text_obj), "")
})

test_that("am_text_update() handles UTF-8 characters", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "content", am_text("你好"))
  text_obj <- am_get(doc, AM_ROOT, "content")

  am_text_update(text_obj, "你好", "你好世界")

  expect_equal(am_text_content(text_obj), "你好世界")
})

test_that("am_text_update() handles emoji", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "content", am_text("Hello"))
  text_obj <- am_get(doc, AM_ROOT, "content")

  am_text_update(text_obj, "Hello", "Hello 🌍")

  expect_equal(am_text_content(text_obj), "Hello 🌍")
})

test_that("am_text_update() handles emoji deletion", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "content", am_text("Hello 🌍 World"))
  text_obj <- am_get(doc, AM_ROOT, "content")

  am_text_update(text_obj, "Hello 🌍 World", "Hello World")

  expect_equal(am_text_content(text_obj), "Hello World")
})

test_that("am_text_update() handles mixed Unicode", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "content", am_text("Hello 世界"))
  text_obj <- am_get(doc, AM_ROOT, "content")

  am_text_update(text_obj, "Hello 世界", "Hello 🌍 世界!")

  expect_equal(am_text_content(text_obj), "Hello 🌍 世界!")
})

test_that("am_text_update() returns invisibly", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "content", am_text("Hello"))
  text_obj <- am_get(doc, AM_ROOT, "content")

  result <- withVisible(am_text_update(text_obj, "Hello", "Hello World"))

  expect_null(result$value)
  expect_false(result$visible)
})

test_that("am_text_update() errors on non-string old_text", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "content", am_text("Hello"))
  text_obj <- am_get(doc, AM_ROOT, "content")

  expect_error(am_text_update(text_obj, 123, "Hello"), "single string")
})

test_that("am_text_update() errors on non-string new_text", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "content", am_text("Hello"))
  text_obj <- am_get(doc, AM_ROOT, "content")

  expect_error(am_text_update(text_obj, "Hello", 123), "single string")
})

test_that("am_text_update() errors on NA old_text", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "content", am_text("Hello"))
  text_obj <- am_get(doc, AM_ROOT, "content")

  expect_error(am_text_update(text_obj, NA_character_, "Hello"), "NA")
})

test_that("am_text_update() errors on NA new_text", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "content", am_text("Hello"))
  text_obj <- am_get(doc, AM_ROOT, "content")

  expect_error(am_text_update(text_obj, "Hello", NA_character_), "NA")
})

test_that("am_text_update() handles single character changes", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "content", am_text("cat"))
  text_obj <- am_get(doc, AM_ROOT, "content")

  am_text_update(text_obj, "cat", "bat")

  expect_equal(am_text_content(text_obj), "bat")
})

test_that("am_text_update() handles complete replacement", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "content", am_text("Hello"))
  text_obj <- am_get(doc, AM_ROOT, "content")

  am_text_update(text_obj, "Hello", "World")

  expect_equal(am_text_content(text_obj), "World")
})

test_that("am_text_update() persists after save/load", {
  doc1 <- am_create()
  am_put(doc1, AM_ROOT, "content", am_text("Hello"))
  text_obj <- am_get(doc1, AM_ROOT, "content")
  am_text_update(text_obj, "Hello", "Hello World")
  am_commit(doc1, "Edit text")

  bytes <- am_save(doc1)
  doc2 <- am_load(bytes)

  text_obj2 <- am_get(doc2, AM_ROOT, "content")
  expect_equal(am_text_content(text_obj2), "Hello World")
})

# am_values() Tests -----------------------------------------------------------

test_that("am_values() returns all values from map", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "a", 1)
  am_put(doc, AM_ROOT, "b", 2)
  am_put(doc, AM_ROOT, "c", 3)

  values <- am_values(doc, AM_ROOT)

  expect_type(values, "list")
  expect_length(values, 3)
  expect_true(all(c(1, 2, 3) %in% values))
})

test_that("am_values() returns all values from list", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)
  list_obj <- am_get(doc, AM_ROOT, "list")

  am_put(doc, list_obj, "end", "first")
  am_put(doc, list_obj, "end", "second")
  am_put(doc, list_obj, "end", "third")

  values <- am_values(doc, list_obj)

  expect_type(values, "list")
  expect_length(values, 3)
  expect_equal(values[[1]], "first")
  expect_equal(values[[2]], "second")
  expect_equal(values[[3]], "third")
})

test_that("am_values() returns empty list for empty map", {
  doc <- am_create()

  values <- am_values(doc, AM_ROOT)

  expect_type(values, "list")
  expect_length(values, 0)
})

test_that("am_values() returns empty list for empty list", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)
  list_obj <- am_get(doc, AM_ROOT, "list")

  values <- am_values(doc, list_obj)

  expect_type(values, "list")
  expect_length(values, 0)
})

test_that("am_values() handles mixed types", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "int", 42L)
  am_put(doc, AM_ROOT, "str", "text")
  am_put(doc, AM_ROOT, "bool", TRUE)
  am_put(doc, AM_ROOT, "null", NULL)

  values <- am_values(doc, AM_ROOT)

  expect_length(values, 4)
  expect_true(42L %in% values)
  expect_true("text" %in% values)
  expect_true(TRUE %in% values)
})

test_that("am_values() includes nested objects", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "scalar", "value")
  am_put(doc, AM_ROOT, "nested", AM_OBJ_TYPE_MAP)
  nested <- am_get(doc, AM_ROOT, "nested")

  values <- am_values(doc, AM_ROOT)

  expect_length(values, 2)
  expect_true("value" %in% values)
  expect_true(any(sapply(values, function(v) inherits(v, "am_object"))))
})

# List Edge Cases -------------------------------------------------------------

test_that("am_get() with index 0 returns NULL", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)
  list_obj <- am_get(doc, AM_ROOT, "list")
  am_put(doc, list_obj, "end", "value")

  result <- am_get(doc, list_obj, 0L)

  expect_null(result)
})

test_that("am_get() with negative index returns NULL", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)
  list_obj <- am_get(doc, AM_ROOT, "list")
  am_put(doc, list_obj, "end", "value")

  result <- am_get(doc, list_obj, -1L)

  expect_null(result)
})

test_that("am_get() with out-of-bounds index returns NULL", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)
  list_obj <- am_get(doc, AM_ROOT, "list")
  am_put(doc, list_obj, "end", "value")

  result <- am_get(doc, list_obj, 100L)

  expect_null(result)
})

test_that("am_get() on empty list returns NULL", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "list", AM_OBJ_TYPE_LIST)
  list_obj <- am_get(doc, AM_ROOT, "list")

  result <- am_get(doc, list_obj, 1L)

  expect_null(result)
})

# Return Value Tests ----------------------------------------------------------

test_that("am_put() with scalar returns doc invisibly", {
  doc <- am_create()

  result <- withVisible(am_put(doc, AM_ROOT, "key", "value"))

  expect_identical(result$value, doc)
  expect_false(result$visible)
})

test_that("am_put() with object type returns doc invisibly", {
  doc <- am_create()

  result <- withVisible(am_put(doc, AM_ROOT, "key", AM_OBJ_TYPE_MAP))

  expect_identical(result$value, doc)
  expect_false(result$visible)
})

test_that("am_delete() returns doc invisibly", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "key", "value")

  result <- withVisible(am_delete(doc, AM_ROOT, "key"))

  expect_identical(result$value, doc)
  expect_false(result$visible)
})

# Unsigned Integer Type Preservation -------------------------------------------

test_that("am_uint64() creates unsigned integer type", {
  x <- am_uint64(12345)
  expect_s3_class(x, "am_uint64")
  expect_equal(as.numeric(x), 12345)
})

test_that("am_uint64() rejects negative values", {
  expect_error(am_uint64(-1), "non-negative")
})

test_that("am_uint64() warns for values exceeding 2^53", {
  # Use 2^54 since 2^53 + 1 == 2^53 in floating point
  expect_warning(am_uint64(2^54), "precision")
})

test_that("am_uint64 round-trips through document", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "id", am_uint64(12345))

  val <- am_get(doc, AM_ROOT, "id")
  expect_s3_class(val, "am_uint64")
  expect_equal(as.numeric(val), 12345)
})

test_that("am_uint64 in list round-trips correctly", {
  doc <- am_create()
  doc$items <- list(am_uint64(1), am_uint64(2), am_uint64(3))

  items <- as.list(doc$items)
  expect_s3_class(items[[1]], "am_uint64")
  expect_s3_class(items[[2]], "am_uint64")
  expect_s3_class(items[[3]], "am_uint64")
})

test_that("am_uint64 preserves type through as.list() round-trip", {
  doc <- am_create()
  doc$val <- am_uint64(42)

  # Simulate the problematic workflow: read, modify other things, write back
  lst <- as.list(doc)
  expect_s3_class(lst$val, "am_uint64")

  # Create new doc and populate from list
  doc2 <- am_create()
  for (key in names(lst)) {
    am_put(doc2, AM_ROOT, key, lst[[key]])
  }

  val2 <- am_get(doc2, AM_ROOT, "val")
  expect_s3_class(val2, "am_uint64")
})

test_that("am_uint64 persists through save/load", {
  doc1 <- am_create()
  am_put(doc1, AM_ROOT, "id", am_uint64(999))
  am_commit(doc1, "Add uint64")

  bytes <- am_save(doc1)
  doc2 <- am_load(bytes)

  val <- am_get(doc2, AM_ROOT, "id")
  expect_s3_class(val, "am_uint64")
  expect_equal(as.numeric(val), 999)
})

test_that("am_uint64 with value 0 works correctly", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "zero", am_uint64(0))

  val <- am_get(doc, AM_ROOT, "zero")
  expect_s3_class(val, "am_uint64")
  expect_equal(as.numeric(val), 0)
})

test_that("am_uint64 with large value (within precision) works", {
  doc <- am_create()
  large_val <- 2^50  # Safe within 2^53
  am_put(doc, AM_ROOT, "large", am_uint64(large_val))

  val <- am_get(doc, AM_ROOT, "large")
  expect_s3_class(val, "am_uint64")
  expect_equal(as.numeric(val), large_val)
})

# am_uint64 Snapshot Tests -----------------------------------------------------

test_that("am_uint64() warns for precision loss", {
  expect_snapshot({
    am_uint64(2^54)
  })
})

test_that("print.am_uint64 displays value correctly", {
  expect_snapshot({
    print(am_uint64(12345))
  })

  expect_snapshot({
    print(am_uint64(0))
  })

  expect_snapshot({
    print(am_uint64(2^50))
  })
})

test_that("am_put with invalid am_uint64 errors", {
  doc <- am_create()

  # Non-scalar am_uint64
  bad_uint <- structure(c(1, 2), class = "am_uint64")
  expect_snapshot(error = TRUE, {
    am_put(doc, AM_ROOT, "bad", bad_uint)
  })

  # Non-numeric am_uint64
  bad_uint2 <- structure(1L, class = "am_uint64")
  expect_snapshot(error = TRUE, {
    am_put(doc, AM_ROOT, "bad", bad_uint2)
  })
})

test_that("am_get warns for uint64 exceeding 2^53", {
  doc <- am_create()
  # Store large value (R warns on creation, C warns on retrieval)
  suppressWarnings(am_put(doc, AM_ROOT, "big", am_uint64(2^54)))

  expect_snapshot({
    am_get(doc, AM_ROOT, "big")
  })
})

test_that("am_values warns for uint64 exceeding 2^53", {
  doc <- am_create()
  suppressWarnings(am_put(doc, AM_ROOT, "big", am_uint64(2^54)))

  expect_snapshot({
    am_values(doc, AM_ROOT)
  })
})

# v1.2 Object Operations Tests ------------------------------------------------

# am_map_get_all tests

test_that("am_map_get_all() returns single value when no conflict", {
  doc <- am_create()
  doc$key <- "value"

  values <- am_map_get_all(doc, AM_ROOT, "key")
  expect_type(values, "list")
  expect_length(values, 1)
  expect_equal(values[[1]], "value")
})

test_that("am_map_get_all() returns multiple values with conflict", {
  doc1 <- am_create()
  doc1$key <- "original"
  am_commit(doc1)

  doc2 <- am_fork(doc1)

  doc1$key <- "from_doc1"
  am_commit(doc1)

  doc2$key <- "from_doc2"
  am_commit(doc2)

  am_merge(doc1, doc2)

  values <- am_map_get_all(doc1, AM_ROOT, "key")
  expect_type(values, "list")
  expect_gte(length(values), 1)
})

test_that("am_map_get_all() errors on non-string key", {
  doc <- am_create()
  expect_error(am_map_get_all(doc, AM_ROOT, 123), "character string")
})

# am_list_get_all tests

test_that("am_list_get_all() returns single value when no conflict", {
  doc <- am_create()
  doc$items <- list("a", "b", "c")
  items <- doc$items

  values <- am_list_get_all(doc, items, 1)
  expect_type(values, "list")
  expect_length(values, 1)
  expect_equal(values[[1]], "a")
})

test_that("am_list_get_all() errors on invalid position", {
  doc <- am_create()
  doc$items <- list("a")
  items <- doc$items

  expect_error(am_list_get_all(doc, items, 0), "pos must be >= 1")
})

# am_map_range tests

test_that("am_map_range() returns subset of keys", {
  doc <- am_create()
  doc$a <- 1
  doc$b <- 2
  doc$c <- 3
  doc$d <- 4

  range <- am_map_range(doc, AM_ROOT, "b", "c")
  expect_type(range, "list")
  expect_length(range, 2)
  expect_true("b" %in% names(range))
  expect_true("c" %in% names(range))
  expect_false("a" %in% names(range))
  expect_false("d" %in% names(range))
})

test_that("am_map_range() with wide strings returns all", {
  doc <- am_create()
  doc$a <- 1
  doc$b <- 2
  doc$c <- 3

  # Use a range that brackets all possible keys
  range <- am_map_range(doc, AM_ROOT, "a", "z")
  expect_length(range, 3)
})

test_that("am_map_range() with same begin/end returns single key", {
  doc <- am_create()
  doc$a <- 1
  doc$b <- 2

  # Same begin and end selects just that key (inclusive)
  range <- am_map_range(doc, AM_ROOT, "a", "a")
  expect_length(range, 1)
  expect_true("a" %in% names(range))

  # Key that doesn't exist still returns empty
  range2 <- am_map_range(doc, AM_ROOT, "c", "c")
  expect_length(range2, 0)
})

test_that("am_map_range() errors on non-string args", {
  doc <- am_create()
  expect_error(am_map_range(doc, AM_ROOT, 1, "z"), "character string")
  expect_error(am_map_range(doc, AM_ROOT, "a", 2), "character string")
})

# am_list_range tests

test_that("am_list_range() returns subset of elements", {
  doc <- am_create()
  doc$items <- list("a", "b", "c", "d", "e")
  items <- doc$items

  range <- am_list_range(doc, items, 2, 4)
  expect_type(range, "list")
  expect_length(range, 3)
  expect_equal(range[[1]], "b")
  expect_equal(range[[2]], "c")
  expect_equal(range[[3]], "d")
})

test_that("am_list_range() errors on invalid begin", {
  doc <- am_create()
  doc$items <- list("a", "b")
  items <- doc$items

  expect_error(am_list_range(doc, items, 0, 2), "begin must be >= 1")
})

test_that("am_list_range() errors on invalid end", {
  doc <- am_create()
  doc$items <- list("a", "b")
  items <- doc$items

  expect_error(am_list_range(doc, items, 1, 0), "end must be >= 1")
  expect_error(am_list_range(doc, items, 1, -1), "end must be >= 1")
})

# am_items tests

test_that("am_items() returns items from map", {
  doc <- am_create()
  doc$name <- "Alice"
  doc$age <- 30L

  items <- am_items(doc, AM_ROOT)
  expect_type(items, "list")
  expect_length(items, 2)

  # Items should have key and value fields
  expect_true(all(vapply(items, function(x) "key" %in% names(x), logical(1))))
  expect_true(all(vapply(items, function(x) "value" %in% names(x), logical(1))))
})

test_that("am_items() returns items from list", {
  doc <- am_create()
  doc$items <- list("a", "b", "c")
  items_obj <- doc$items

  items <- am_items(doc, items_obj)
  expect_type(items, "list")
  expect_length(items, 3)

  expect_true(all(vapply(items, function(x) "key" %in% names(x), logical(1))))
  expect_true(all(vapply(items, function(x) "value" %in% names(x), logical(1))))
})

test_that("am_items() returns empty list for empty object", {
  doc <- am_create()
  items <- am_items(doc, AM_ROOT)
  expect_length(items, 0)
})

# Additional am_map_get_all tests

test_that("am_map_get_all() returns empty for non-existent key", {
  doc <- am_create()
  doc$key <- "value"

  values <- am_map_get_all(doc, AM_ROOT, "nonexistent")
  expect_type(values, "list")
  expect_length(values, 0)
})

test_that("am_map_get_all() works on nested map", {
  doc <- am_create()
  doc$config <- list(host = "localhost", port = 8080L)
  config <- am_get(doc, AM_ROOT, "config")

  values <- am_map_get_all(doc, config, "host")
  expect_length(values, 1)
  expect_equal(values[[1]], "localhost")
})

test_that("am_map_get_all() returns nested objects", {
  doc <- am_create()
  doc$nested <- list(inner = list(deep = "value"))

  values <- am_map_get_all(doc, AM_ROOT, "nested")
  expect_length(values, 1)
  expect_s3_class(values[[1]], "am_object")
})

test_that("am_map_get_all() with historical heads", {
  doc <- am_create()
  doc$key <- "v1"
  am_commit(doc, "Version 1")
  heads_v1 <- am_get_heads(doc)

  doc$key <- "v2"
  am_commit(doc, "Version 2")

  # Current value
  values_now <- am_map_get_all(doc, AM_ROOT, "key")
  expect_equal(values_now[[1]], "v2")

  # Value at heads_v1
  values_then <- am_map_get_all(doc, AM_ROOT, "key", heads_v1)
  expect_equal(values_then[[1]], "v1")
})

test_that("am_map_get_all() both values present after conflict", {
  doc1 <- am_create()
  doc1$status <- "draft"
  am_commit(doc1)

  doc2 <- am_fork(doc1)
  doc1$status <- "published"
  am_commit(doc1)
  doc2$status <- "archived"
  am_commit(doc2)

  am_merge(doc1, doc2)

  values <- am_map_get_all(doc1, AM_ROOT, "status")
  expect_length(values, 2)
  expect_setequal(unlist(values), c("published", "archived"))
})

# Additional am_list_get_all tests

test_that("am_list_get_all() returns multiple values with conflict", {
  doc1 <- am_create()
  doc1$items <- list(100L)
  am_commit(doc1)

  doc2 <- am_fork(doc1)
  items1 <- am_get(doc1, AM_ROOT, "items")
  items2 <- am_get(doc2, AM_ROOT, "items")

  am_put(doc1, items1, 1, 200L)
  am_commit(doc1)
  am_put(doc2, items2, 1, 300L)
  am_commit(doc2)

  am_merge(doc1, doc2)
  values <- am_list_get_all(doc1, items1, 1)
  expect_length(values, 2)
  expect_setequal(unlist(values), c(200L, 300L))
})

test_that("am_list_get_all() with historical heads", {
  doc <- am_create()
  doc$items <- list("first")
  am_commit(doc)
  heads_v1 <- am_get_heads(doc)

  items <- am_get(doc, AM_ROOT, "items")
  am_put(doc, items, 1, "second")
  am_commit(doc)

  values_now <- am_list_get_all(doc, items, 1)
  expect_equal(values_now[[1]], "second")

  values_then <- am_list_get_all(doc, items, 1, heads_v1)
  expect_equal(values_then[[1]], "first")
})

# Additional am_map_range tests

test_that("am_map_range() on empty map returns empty", {
  doc <- am_create()
  range <- am_map_range(doc, AM_ROOT, "a", "z")
  expect_length(range, 0)
})

test_that("am_map_range() with nested objects", {
  doc <- am_create()
  doc$config <- list(host = "localhost")
  doc$data <- list(value = 42)
  doc$meta <- list(version = "1.0")

  range <- am_map_range(doc, AM_ROOT, "config", "data")
  expect_length(range, 2)
  expect_true("config" %in% names(range))
  expect_true("data" %in% names(range))
  expect_false("meta" %in% names(range))
  expect_s3_class(range[["config"]], "am_object")
})

test_that("am_map_range() with historical heads", {
  doc <- am_create()
  doc$a <- 1
  doc$b <- 2
  am_commit(doc)
  heads_v1 <- am_get_heads(doc)

  doc$c <- 3
  am_commit(doc)

  range_now <- am_map_range(doc, AM_ROOT, "a", "z")
  expect_length(range_now, 3)

  range_then <- am_map_range(doc, AM_ROOT, "a", "z", heads_v1)
  expect_length(range_then, 2)
})

# Additional am_list_range tests

test_that("am_list_range() full range returns all items", {
  doc <- am_create()
  doc$items <- list("a", "b", "c")
  items <- doc$items

  range <- am_list_range(doc, items, 1, 3)
  expect_length(range, 3)
  expect_equal(range[[1]], "a")
  expect_equal(range[[3]], "c")
})

test_that("am_list_range() single element range", {
  doc <- am_create()
  doc$items <- list("a", "b", "c")
  items <- doc$items

  range <- am_list_range(doc, items, 2, 2)
  expect_length(range, 1)
  expect_equal(range[[1]], "b")
})

test_that("am_list_range() with nested objects", {
  doc <- am_create()
  doc$items <- list(list(name = "Alice"), list(name = "Bob"))
  items <- doc$items

  range <- am_list_range(doc, items, 1, 2)
  expect_length(range, 2)
  expect_s3_class(range[[1]], "am_object")
})

test_that("am_list_range() with historical heads", {
  doc <- am_create()
  doc$items <- list("a", "b")
  am_commit(doc)
  heads_v1 <- am_get_heads(doc)

  items <- am_get(doc, AM_ROOT, "items")
  am_insert(doc, items, "end", "c")
  am_commit(doc)

  range_now <- am_list_range(doc, items, 1, 3)
  expect_length(range_now, 3)

  range_then <- am_list_range(doc, items, 1, 2, heads_v1)
  expect_length(range_then, 2)
})

test_that("am_list_range() on empty list returns empty", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
  items <- am_get(doc, AM_ROOT, "items")

  range <- am_list_range(doc, items, 1, 1)
  expect_length(range, 0)
})

# Additional am_items tests

test_that("am_items() map items have string keys", {
  doc <- am_create()
  doc$alpha <- 1
  doc$beta <- 2

  items <- am_items(doc, AM_ROOT)
  keys <- vapply(items, function(x) x$key, character(1))
  expect_setequal(keys, c("alpha", "beta"))
})

test_that("am_items() list items have integer keys", {
  doc <- am_create()
  doc$items <- list("a", "b", "c")
  items_obj <- doc$items

  items <- am_items(doc, items_obj)
  keys <- vapply(items, function(x) x$key, integer(1))
  expect_equal(keys, c(1L, 2L, 3L))
})

test_that("am_items() with mixed value types", {
  doc <- am_create()
  doc$str <- "text"
  doc$int <- 42L
  doc$bool <- TRUE
  doc$dbl <- 3.14

  items <- am_items(doc, AM_ROOT)
  expect_length(items, 4)
  values <- lapply(items, function(x) x$value)
  expect_true("text" %in% values)
  expect_true(42L %in% values)
})

test_that("am_items() with nested objects returns am_object", {
  doc <- am_create()
  doc$nested <- list(key = "value")

  items <- am_items(doc, AM_ROOT)
  expect_length(items, 1)
  expect_s3_class(items[[1]]$value, "am_object")
})

test_that("am_items() with historical heads", {
  doc <- am_create()
  doc$a <- 1
  am_commit(doc)
  heads_v1 <- am_get_heads(doc)

  doc$b <- 2
  am_commit(doc)

  items_now <- am_items(doc, AM_ROOT)
  expect_length(items_now, 2)

  items_then <- am_items(doc, AM_ROOT, heads_v1)
  expect_length(items_then, 1)
})

# Coverage Tests: Input Validation and Edge Cases =============================

# am_put edge cases for type dispatch

test_that("am_put() with raw bytes into map", {
  doc <- am_create()
  raw_data <- as.raw(c(0x01, 0x02, 0x03))
  am_put(doc, AM_ROOT, "data", raw_data)
  result <- am_get(doc, AM_ROOT, "data")
  expect_type(result, "raw")
  expect_equal(result, raw_data)
})

test_that("am_put() with raw bytes into list", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
  items <- am_get(doc, AM_ROOT, "items")
  am_insert(doc, items, 1, as.raw(c(0xDE, 0xAD)))
  val <- am_get(doc, items, 1)
  expect_type(val, "raw")
  expect_equal(val, as.raw(c(0xDE, 0xAD)))
})

test_that("am_put() with POSIXct into map and list", {
  doc <- am_create()
  ts <- as.POSIXct("2025-06-15 12:00:00", tz = "UTC")
  am_put(doc, AM_ROOT, "time", ts)
  result <- am_get(doc, AM_ROOT, "time")
  expect_s3_class(result, "POSIXct")

  # Into list
  am_put(doc, AM_ROOT, "times", AM_OBJ_TYPE_LIST)
  times <- am_get(doc, AM_ROOT, "times")
  am_insert(doc, times, 1, ts)
  val <- am_get(doc, times, 1)
  expect_s3_class(val, "POSIXct")
})

test_that("am_put() with counter into list", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
  items <- am_get(doc, AM_ROOT, "items")
  am_insert(doc, items, 1, am_counter(5))
  val <- am_get(doc, items, 1)
  expect_s3_class(val, "am_counter")
  expect_equal(as.integer(val), 5L)
})

test_that("am_put() with am_uint64 into list", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
  items <- am_get(doc, AM_ROOT, "items")
  am_insert(doc, items, 1, am_uint64(42))
  val <- am_get(doc, items, 1)
  expect_s3_class(val, "am_uint64")
  expect_equal(as.numeric(val), 42)
})

test_that("am_put() with am_text() into list", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
  items <- am_get(doc, AM_ROOT, "items")
  am_insert(doc, items, 1, am_text("hello"))
  val <- am_get(doc, items, 1)
  expect_s3_class(val, "am_text")
  expect_equal(am_text_content(val), "hello")
})

test_that("am_put() with boolean into list", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
  items <- am_get(doc, AM_ROOT, "items")
  am_insert(doc, items, 1, TRUE)
  val <- am_get(doc, items, 1)
  expect_true(val)
})

test_that("am_put() with integer into list", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
  items <- am_get(doc, AM_ROOT, "items")
  am_insert(doc, items, 1, 42L)
  val <- am_get(doc, items, 1)
  expect_equal(val, 42L)
})

test_that("am_put() with double into list", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
  items <- am_get(doc, AM_ROOT, "items")
  am_insert(doc, items, 1, 3.14)
  val <- am_get(doc, items, 1)
  expect_equal(val, 3.14)
})

test_that("am_put() with string into list", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
  items <- am_get(doc, AM_ROOT, "items")
  am_insert(doc, items, 1, "hello")
  val <- am_get(doc, items, 1)
  expect_equal(val, "hello")
})

test_that("am_put() with NULL into list", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
  items <- am_get(doc, AM_ROOT, "items")
  am_insert(doc, items, 1, NULL)
  val <- am_get(doc, items, 1)
  expect_null(val)
})

test_that("am_put() with nested list into list (unnamed = list type)", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
  items <- am_get(doc, AM_ROOT, "items")
  am_insert(doc, items, 1, list("a", "b"))
  val <- am_get(doc, items, 1)
  expect_s3_class(val, "am_object")
  expect_equal(am_length(doc, val), 2)
})

test_that("am_put() with nested named list into list (named = map type)", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
  items <- am_get(doc, AM_ROOT, "items")
  am_insert(doc, items, 1, list(x = 1))
  val <- am_get(doc, items, 1)
  expect_s3_class(val, "am_object")
  expect_equal(am_get(doc, val, "x"), 1)
})

test_that("am_put() with AM_OBJ_TYPE_LIST constant into list", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
  items <- am_get(doc, AM_ROOT, "items")
  am_insert(doc, items, 1, AM_OBJ_TYPE_LIST)
  val <- am_get(doc, items, 1)
  expect_s3_class(val, "am_object")
})

test_that("am_put() with AM_OBJ_TYPE_MAP constant into list", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
  items <- am_get(doc, AM_ROOT, "items")
  am_insert(doc, items, 1, AM_OBJ_TYPE_MAP)
  val <- am_get(doc, items, 1)
  expect_s3_class(val, "am_object")
})

test_that("am_put() with AM_OBJ_TYPE_TEXT constant into list", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
  items <- am_get(doc, AM_ROOT, "items")
  am_insert(doc, items, 1, AM_OBJ_TYPE_TEXT)
  val <- am_get(doc, items, 1)
  expect_s3_class(val, "am_text")
})

test_that("am_put() with am_list_type into map", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "lst", am_list("x", "y"))
  val <- am_get(doc, AM_ROOT, "lst")
  expect_s3_class(val, "am_object")
  expect_equal(am_length(doc, val), 2)
})

test_that("am_put() with am_map_type into map", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "m", am_map(a = 1, b = 2))
  val <- am_get(doc, AM_ROOT, "m")
  expect_s3_class(val, "am_object")
  expect_equal(am_get(doc, val, "a"), 1)
})

# am_get / am_delete input validation

test_that("am_get() errors on unsupported key type", {
  doc <- am_create()
  expect_error(am_get(doc, AM_ROOT, TRUE), "character string.*numeric")
})

test_that("am_delete() errors on unsupported key type", {
  doc <- am_create()
  expect_error(am_delete(doc, AM_ROOT, TRUE), "character string.*numeric")
})

test_that("am_delete() from list by position", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
  items <- am_get(doc, AM_ROOT, "items")
  am_insert(doc, items, 1, "a")
  am_insert(doc, items, 2, "b")
  am_delete(doc, items, 1)
  expect_equal(am_length(doc, items), 1)
})

test_that("am_delete() errors on non-positive list position", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
  items <- am_get(doc, AM_ROOT, "items")
  am_insert(doc, items, 1, "a")
  expect_error(am_delete(doc, items, 0L), "positive")
})

# am_values includes nested objects from lists

test_that("am_values() with nested objects in lists", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
  items <- am_get(doc, AM_ROOT, "items")
  am_insert(doc, items, 1, "scalar")
  am_insert(doc, items, 2, AM_OBJ_TYPE_MAP)

  values <- am_values(doc, items)
  expect_length(values, 2)
  expect_equal(values[[1]], "scalar")
  expect_s3_class(values[[2]], "am_object")
})

# Multiple heads error paths

test_that("am_map_get_all() errors on multiple heads", {
  doc <- am_create()
  doc$key <- "v1"
  am_commit(doc)

  doc2 <- am_fork(doc)
  doc$key <- "v2"
  am_commit(doc)
  doc2$key <- "v3"
  am_commit(doc2)
  am_merge(doc, doc2)

  heads <- am_get_heads(doc)
  expect_gte(length(heads), 2)
  expect_error(
    am_map_get_all(doc, AM_ROOT, "key", heads),
    "multiple heads"
  )
})

test_that("am_list_get_all() errors on multiple heads", {
  doc <- am_create()
  doc$items <- list("a")
  am_commit(doc)

  doc2 <- am_fork(doc)
  items1 <- am_get(doc, AM_ROOT, "items")
  items2 <- am_get(doc2, AM_ROOT, "items")
  am_put(doc, items1, 1, "b")
  am_commit(doc)
  am_put(doc2, items2, 1, "c")
  am_commit(doc2)
  am_merge(doc, doc2)

  heads <- am_get_heads(doc)
  expect_gte(length(heads), 2)
  expect_error(
    am_list_get_all(doc, items1, 1, heads),
    "multiple heads"
  )
})

test_that("am_map_range() errors on multiple heads", {
  doc <- am_create()
  doc$a <- 1
  am_commit(doc)

  doc2 <- am_fork(doc)
  doc$b <- 2
  am_commit(doc)
  doc2$c <- 3
  am_commit(doc2)
  am_merge(doc, doc2)

  heads <- am_get_heads(doc)
  expect_gte(length(heads), 2)
  expect_error(
    am_map_range(doc, AM_ROOT, "a", "z", heads),
    "multiple heads"
  )
})

test_that("am_list_range() errors on multiple heads", {
  doc <- am_create()
  doc$items <- list("a", "b")
  am_commit(doc)

  doc2 <- am_fork(doc)
  items1 <- am_get(doc, AM_ROOT, "items")
  items2 <- am_get(doc2, AM_ROOT, "items")
  am_insert(doc, items1, "end", "c")
  am_commit(doc)
  am_insert(doc2, items2, "end", "d")
  am_commit(doc2)
  am_merge(doc, doc2)

  heads <- am_get_heads(doc)
  expect_gte(length(heads), 2)
  expect_error(
    am_list_range(doc, items1, 1, 5, heads),
    "multiple heads"
  )
})

test_that("am_items() errors on multiple heads", {
  doc <- am_create()
  doc$a <- 1
  am_commit(doc)

  doc2 <- am_fork(doc)
  doc$b <- 2
  am_commit(doc)
  doc2$c <- 3
  am_commit(doc2)
  am_merge(doc, doc2)

  heads <- am_get_heads(doc)
  expect_gte(length(heads), 2)
  expect_error(
    am_items(doc, AM_ROOT, heads),
    "multiple heads"
  )
})

# am_list_get_all input validation

test_that("am_list_get_all() errors on non-scalar pos", {
  doc <- am_create()
  doc$items <- list("a", "b")
  items <- doc$items
  expect_error(am_list_get_all(doc, items, c(1, 2)), "scalar")
})

# am_list_range input validation

test_that("am_list_range() errors on non-numeric begin", {
  doc <- am_create()
  doc$items <- list("a")
  items <- doc$items
  expect_error(am_list_range(doc, items, "a", 2), "numeric")
})

test_that("am_list_range() errors on non-numeric end", {
  doc <- am_create()
  doc$items <- list("a")
  items <- doc$items
  expect_error(am_list_range(doc, items, 1, "b"), "numeric")
})

test_that("am_list_range() errors on non-scalar", {
  doc <- am_create()
  doc$items <- list("a", "b")
  items <- doc$items
  expect_error(am_list_range(doc, items, c(1, 2), 3), "scalar")
})

# am_insert error

test_that("am_insert() errors on non-list objects", {
  doc <- am_create()
  expect_error(am_insert(doc, AM_ROOT, 1, "x"), "list objects")
})

# am_text_splice validation

test_that("am_text_splice() errors on non-numeric pos", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  expect_error(am_text_splice(text_obj, "a", 0, "x"), "pos must be numeric")
})

test_that("am_text_splice() errors on negative pos", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  expect_error(am_text_splice(text_obj, -1L, 0, "x"), "non-negative")
})

test_that("am_text_splice() errors on non-numeric del_count", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  expect_error(am_text_splice(text_obj, 0, "a", "x"), "del_count must be numeric")
})

test_that("am_text_splice() errors on negative del_count", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  expect_error(am_text_splice(text_obj, 0, -1L, "x"), "non-negative")
})

test_that("am_text_splice() errors on non-string text", {
  doc <- am_create()
  doc$t <- am_text("hello")
  text_obj <- doc$t
  expect_error(am_text_splice(text_obj, 0, 0, 123), "single character string")
})

# am_get with non-scalar list position

test_that("am_get() errors on non-scalar list position", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
  items <- am_get(doc, AM_ROOT, "items")
  am_insert(doc, items, 1, "a")
  expect_error(am_get(doc, items, c(1L, 2L)), "scalar")
})

# am_map_get_all with empty heads list

test_that("am_map_get_all() with empty heads list same as NULL", {
  doc <- am_create()
  doc$key <- "value"
  am_commit(doc)

  vals_null <- am_map_get_all(doc, AM_ROOT, "key")
  vals_empty <- am_map_get_all(doc, AM_ROOT, "key", list())
  expect_equal(length(vals_null), length(vals_empty))
})

# am_list_get_all with non-scalar errors

test_that("am_list_get_all() errors on non-numeric pos", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
  items <- am_get(doc, AM_ROOT, "items")
  am_insert(doc, items, 1, "a")
  expect_error(am_list_get_all(doc, items, "a"), "numeric")
})

# am_put with invalid list position type (not numeric, not "end")

test_that("am_put() errors on invalid list position type", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
  items <- am_get(doc, AM_ROOT, "items")
  am_insert(doc, items, 1, "a")
  expect_error(am_put(doc, items, TRUE, "x"), "numeric")
})

# am_put with invalid string position (not "end")

test_that("am_put() errors on non-'end' string list position", {
  doc <- am_create()
  am_put(doc, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
  items <- am_get(doc, AM_ROOT, "items")
  expect_error(am_put(doc, items, "middle", "x"), "numeric.*end")
})

# am_values with map (tests the key-based iteration path)

test_that("am_values() on map returns named values", {
  doc <- am_create()
  doc$a <- 1
  doc$b <- "hello"
  doc$c <- TRUE

  values <- am_values(doc, AM_ROOT)
  expect_length(values, 3)
})

# am_items() for list items with various types

test_that("am_items() returns items from list with nested objects", {
  doc <- am_create()
  doc$items <- list("a", 42L, TRUE)
  items_obj <- doc$items
  items <- am_items(doc, items_obj)
  expect_length(items, 3)
  expect_equal(items[[1]]$key, 1L)
  expect_equal(items[[2]]$key, 2L)
  expect_equal(items[[3]]$key, 3L)
  expect_equal(items[[1]]$value, "a")
  expect_equal(items[[2]]$value, 42L)
  expect_true(items[[3]]$value)
})
