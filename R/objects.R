# Object Operations

#' Put a value into an Automerge map or list
#'
#' Inserts or updates a value in an Automerge map or list. The function
#' automatically dispatches to the appropriate operation based on the object
#' type and key/position type.
#'
#' @param doc An Automerge document
#' @param obj An Automerge object ID (from nested object), or `AM_ROOT`
#'   for the document root
#' @param key For maps: character string key. For lists: numeric index
#'   (1-based) or `"end"` to append
#' @param value The value to store. Supported types:
#'   \itemize{
#'     \item `NULL` - stores null
#'     \item Logical - stores boolean (must be scalar)
#'     \item Integer - stores integer (must be scalar)
#'     \item Numeric - stores double (must be scalar)
#'     \item Character - stores string (must be scalar)
#'     \item Raw - stores bytes
#'     \item `AM_OBJ_TYPE_LIST/MAP/TEXT` - creates nested object
#'   }
#'
#' @return The document `doc` (invisibly).
#'
#' @export
#' @examples
#' doc <- am_create()
#'
#' # Put values in root map (returns doc invisibly)
#' am_put(doc, AM_ROOT, "name", "Alice")
#' am_put(doc, AM_ROOT, "age", 30L)
#' am_put(doc, AM_ROOT, "active", TRUE)
#'
#' # Create nested list and retrieve it
#' am_put(doc, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
#' items <- am_get(doc, AM_ROOT, "items")
am_put <- function(doc, obj, key, value) {
  invisible(.Call(C_am_put, doc, obj, key, value))
}

#' Get a value from an Automerge map or list
#'
#' Retrieves a value from an Automerge map or list. Returns `NULL`
#' if the key or index doesn't exist.
#'
#' @param doc An Automerge document
#' @param obj An Automerge object ID (from nested object), or `AM_ROOT`
#'   for the document root
#' @param key For maps: character string key. For lists: numeric index
#'   (1-based). Returns `NULL` for indices `<= 0` or beyond list length.
#'
#' @return The value at the specified key/position, or `NULL` if not found.
#'   Nested objects are returned as `am_object` instances.
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "name", "Alice")
#'
#' name <- am_get(doc, AM_ROOT, "name")
#' name  # "Alice"
am_get <- function(doc, obj, key) {
  .Call(C_am_get, doc, obj, key)
}

#' Delete a key from a map or element from a list
#'
#' Removes a key-value pair from a map or an element from a list.
#'
#' @param doc An Automerge document
#' @param obj An Automerge object ID (from nested object), or `AM_ROOT`
#'   for the document root
#' @param key For maps: character string key to delete. For lists: numeric
#'   index (1-based, like R vectors) to delete
#'
#' @return The document `doc` (invisibly)
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "temp", "value")
#' am_delete(doc, AM_ROOT, "temp")
am_delete <- function(doc, obj, key) {
  invisible(.Call(C_am_delete, doc, obj, key))
}

#' Get all keys from an Automerge map
#'
#' Returns a character vector of all keys in a map.
#'
#' @param doc An Automerge document
#' @param obj An Automerge object ID (must be a map), or `AM_ROOT`
#'   for the document root
#'
#' @return Character vector of keys (empty if map is empty)
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "a", 1)
#' am_put(doc, AM_ROOT, "b", 2)
#'
#' keys <- am_keys(doc, AM_ROOT)
#' keys  # c("a", "b")
am_keys <- function(doc, obj) {
  .Call(C_am_keys, doc, obj)
}

#' Get the length of an Automerge map or list
#'
#' Returns the number of key-value pairs in a map or elements in a list.
#'
#' @param doc An Automerge document
#' @param obj An Automerge object ID, or `AM_ROOT` for the document root
#'
#' @return Integer length/size
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "a", 1)
#' am_put(doc, AM_ROOT, "b", 2)
#'
#' len <- am_length(doc, AM_ROOT)
#' len  # 2
am_length <- function(doc, obj) {
  .Call(C_am_length, doc, obj)
}

#' Insert a value into an Automerge list
#'
#' This is an alias for `am_put()` with insert semantics for lists.
#' For lists, `am_put()` with a numeric index replaces the element
#' at that index, while `am_insert()` shifts elements to make room.
#'
#' @param doc An Automerge document
#' @param obj An Automerge object ID (must be a list)
#' @param pos Numeric index (1-based, like R vectors) where to insert, or `"end"`
#'   to append
#' @param value The value to insert
#'
#' @return The document `doc` (invisibly)
#'
#' @export
#' @examples
#' doc <- am_create()
#' # Create a list and get it
#' am_put(doc, AM_ROOT, "items", AM_OBJ_TYPE_LIST)
#' items <- am_get(doc, AM_ROOT, "items")
#'
#' # Insert items
#' am_insert(doc, items, "end", "first")
#' am_insert(doc, items, "end", "second")
am_insert <- function(doc, obj, pos, value) {
  invisible(.Call(C_am_insert, doc, obj, pos, value))
}

# Type Constructors -----------------------------------------------------------

#' Create an Automerge counter
#'
#' Creates a counter value for use with Automerge. Counters are CRDT types
#' that support conflict-free increment and decrement operations.
#'
#' @param value Initial counter value (default 0)
#' @return An `am_counter` object
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "score", am_counter(0))
am_counter <- function(value = 0L) {
  structure(as.integer(value), class = "am_counter")
}

#' Create an unsigned 64-bit integer value
#'
#' Creates an `am_uint64` object for storing unsigned 64-bit integers in Automerge
#' documents. This preserves type fidelity when syncing with other language
#' bindings (JavaScript BigInt, Python int, etc.).
#'
#' @param value Numeric value (default 0). Values beyond 2^53 may lose precision.
#' @return An `am_uint64` object
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "id", am_uint64(12345))
am_uint64 <- function(value = 0) {
  value <- as.numeric(value)
  if (value < 0) {
    stop("am_uint64 requires a non-negative value")
  }
  if (value > 2^53) {
    warning("Value exceeds 2^53; precision may be lost")
  }
  structure(value, class = "am_uint64")
}

#' Create an Automerge list
#'
#' Creates an R list with explicit Automerge list type. Use this when you
#' need to create an empty list or force list type interpretation.
#'
#' @param ... Elements to include in the list
#' @return A list with class `am_list_type`
#' @export
#' @examples
#' # Empty list (avoids ambiguity)
#' am_list()
#'
#' # Populated list
#' am_list("a", "b", "c")
am_list <- function(...) {
  structure(list(...), class = c("am_list_type", "list"))
}

#' Create an Automerge map
#'
#' Creates an R list with explicit Automerge map type. Use this when you
#' need to create an empty map or force map type interpretation.
#'
#' @param ... Named elements to include in the map
#' @return A named list with class `am_map_type`
#' @export
#' @examples
#' # Empty map (avoids ambiguity)
#' am_map()
#'
#' # Populated map
#' am_map(key1 = "value1", key2 = "value2")
am_map <- function(...) {
  structure(list(...), class = c("am_map_type", "list"))
}

#' Create an Automerge text object
#'
#' Creates a text object for collaborative character-level editing.
#' Unlike regular strings (which use last-write-wins semantics),
#' text objects support character-level CRDT merging of concurrent edits,
#' cursor stability, and marks/formatting.
#'
#' Use text objects for collaborative document editing. Use regular strings
#' for metadata, labels, and IDs (99\% of cases).
#'
#' @param initial Initial text content (default "")
#' @return A character vector with class `am_text_type`
#' @export
#' @examples
#' # Empty text object
#' am_text()
#'
#' # Text with initial content
#' am_text("Hello, World!")
am_text <- function(initial = "") {
  if (!is.character(initial) || length(initial) != 1) {
    stop("initial must be a single character string")
  }
  structure(initial, class = c("am_text_type", "character"))
}

# Text Operations -------------------------------------------------------------

#' Splice text in a text object
#'
#' Insert or delete characters in a text object. This is the primary way to
#' edit text CRDT objects.
#'
#' @param text_obj An Automerge text object ID
#' @param pos Character position to start splice (0-based inter-character position)
#' @param del_count Number of characters to delete (counts Unicode code points)
#' @param text Text to insert
#' @return The text object `text_obj` (invisibly)
#'
#' @section Indexing Convention:
#' **Text positions use 0-based indexing** (unlike list indices which are
#' 1-based). This is because positions specify locations **between** characters,
#' not the characters themselves:
#' \itemize{
#'   \item Position 0 = before the first character
#'   \item Position 1 = between 1st and 2nd characters
#'   \item Position 5 = after the 5th character
#' }
#'
#' For the text "Hello":
#' \preformatted{
#'   H e l l o
#'  0 1 2 3 4 5  <- positions (0-based, between characters)
#' }
#'
#' Positions count Unicode code points (characters), not bytes. The word
#' "Français" counts as 8 characters, matching R's `nchar()` behavior.
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "doc", am_text("Hello"))
#' text_obj <- am_get(doc, AM_ROOT, "doc")
#'
#' # Insert " World" at position 5 (after "Hello")
#' am_text_splice(text_obj, 5, 0, " World")
#'
#' # Get the full text
#' am_text_content(text_obj)  # "Hello World"
#'
#' # Works naturally with multibyte characters
#' am_put(doc, AM_ROOT, "greet", am_text(""))
#' text_obj2 <- am_get(doc, AM_ROOT, "greet")
#' am_text_splice(text_obj2, 0, 0, "Column café")
#' # Position 11 is after "café" (character index, not bytes)
#' am_text_splice(text_obj2, 11, 0, "!")
#' am_text_content(text_obj2)  # "Column café!"
am_text_splice <- function(text_obj, pos, del_count, text) {
  invisible(.Call(C_am_text_splice, text_obj, pos, del_count, text))
}

#' Get text content from a text object
#'
#' Retrieve the full text content from a text object as a string.
#'
#' @param text_obj An Automerge text object ID
#' @return Character string with the full text
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "doc", am_text("Hello"))
#' text_obj <- am_get(doc, AM_ROOT, "doc")
#'
#' text <- am_text_content(text_obj)
#' text  # "Hello"
am_text_content <- function(text_obj) {
  .Call(C_am_text_content, text_obj)
}

#' Update text content
#'
#' An optimized function for collaborative editing that computes the minimal
#' diff between old and new text and applies it directly to the text object.
#' This avoids intermediate R object allocation, making it more efficient than
#' separate diff computation and splice operations.
#'
#' Positions use Unicode code points (matching R's `nchar()` behavior), not
#' bytes. This means multibyte characters like emoji count as single characters.
#'
#' @param text_obj An Automerge text object ID
#' @param old_text The previous text content (single string)
#' @param new_text The new text content (single string)
#' @return Invisible NULL (called for side effect)
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "content", am_text("Hello"))
#' text_obj <- am_get(doc, AM_ROOT, "content")
#'
#' # Efficiently update text by computing and applying diff in one step
#' am_text_update(text_obj, "Hello", "Hello World")
#' am_text_content(text_obj)  # "Hello World"
#'
#' # Works with Unicode
#' am_text_update(text_obj, "Hello World", "Hello World!")
#' am_text_content(text_obj)  # "Hello World!"
am_text_update <- function(text_obj, old_text, new_text) {
  invisible(.Call(C_am_text_update, text_obj, old_text, new_text))
}

#' Get all values from a map or list
#'
#' Returns all values from an Automerge map or list as an R list.
#'
#' @param doc An Automerge document
#' @param obj An Automerge object ID, or `AM_ROOT` for the document root
#' @return R list of values
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "a", 1)
#' am_put(doc, AM_ROOT, "b", 2)
#' am_put(doc, AM_ROOT, "c", 3)
#'
#' values <- am_values(doc, AM_ROOT)
#' values  # list(1, 2, 3)
am_values <- function(doc, obj) {
  .Call(C_am_values, doc, obj)
}

#' Increment a counter value
#'
#' Increments an Automerge counter by the specified delta. Counters are CRDT types
#' that support concurrent increments from multiple actors. Unlike regular integers,
#' counter increments are commutative and do not conflict when merged.
#'
#' The delta can be negative to decrement the counter.
#'
#' @param doc An Automerge document
#' @param obj An Automerge object ID (map or list), or `AM_ROOT` for the document root
#' @param key For maps: a character string key. For lists: an integer index (1-based)
#' @param delta Integer value to add to the counter (can be negative)
#' @return The document (invisibly), allowing for chaining with pipes
#' @export
#' @examples
#' # Counter in document root (map)
#' doc <- am_create()
#' doc$score <- am_counter(0)
#' am_counter_increment(doc, AM_ROOT, "score", 10)
#' doc$score  # 10
#'
#' am_counter_increment(doc, AM_ROOT, "score", 5)
#' doc$score  # 15
#'
#' # Decrement with negative delta
#' am_counter_increment(doc, AM_ROOT, "score", -3)
#' doc$score  # 12
#'
#' # Counter in a nested map
#' doc$stats <- am_map(views = am_counter(0))
#' stats_obj <- doc$stats
#' am_counter_increment(doc, stats_obj, "views", 100)
#'
#' # Counter in a list (1-based indexing)
#' doc$counters <- list(am_counter(0), am_counter(5))
#' counters_obj <- doc$counters
#' am_counter_increment(doc, counters_obj, 1, 1)  # Increment first counter
#' am_counter_increment(doc, counters_obj, 2, 2)  # Increment second counter
am_counter_increment <- function(doc, obj, key, delta) {
  invisible(.Call(C_am_counter_increment, doc, obj, key, delta))
}
