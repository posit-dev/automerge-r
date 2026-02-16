# Cursor and Mark Operations

#' Create a cursor at a position in a text object
#'
#' Cursors provide stable references to positions within text objects that
#' automatically adjust as the text is edited. This enables features like
#' maintaining selection positions across concurrent edits in collaborative
#' editing scenarios.
#'
#' @param obj An Automerge object ID (must be a text object)
#' @param position Integer position in the text (0-based inter-character position)
#' @param heads Optional list of change hashes (raw vectors) to create the cursor
#'   at a historical document state. If `NULL` (default), uses the current state.
#'
#' @return An `am_cursor` object (external pointer) that can be used with
#'   [am_cursor_position()] to retrieve the current position
#'
#' @section Indexing Convention:
#' **Cursor positions use 0-based indexing** (unlike list indices which are
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
#' This matches `am_text_splice()` behavior. Positions count Unicode code points
#' (characters), not bytes.
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "text", am_text("Hello World"))
#' text_obj <- am_get(doc, AM_ROOT, "text")
#'
#' # Create cursor at position 5 (after "Hello", before " ")
#' cursor <- am_cursor(text_obj, 5)
#' cursor
#'
#' # Modify text before cursor
#' am_text_splice(text_obj, 0, 0, "Hi ")
#'
#' # Cursor position automatically adjusts
#' new_pos <- am_cursor_position(cursor)
#' new_pos  # 8 (cursor moved by 3 characters)
#'
#' am_close(doc)
#'
am_cursor <- function(obj, position, heads = NULL) {
  .Call(C_am_cursor, obj, position, heads)
}

#' Get the current position of a cursor
#'
#' Retrieves the current position of a cursor within a text object. The
#' position automatically adjusts as text is inserted or deleted before
#' the cursor's original position. The cursor remembers which text object
#' it was created for, so you only need to pass the cursor itself.
#'
#' @param cursor An `am_cursor` object created by [am_cursor()]
#' @param heads Optional list of change hashes (raw vectors) to query cursor
#'   position at a historical document state. If `NULL` (default), uses the
#'   current state.
#'
#' @return Integer position (0-based inter-character position) where the cursor
#'   currently points. See [am_cursor()] for indexing details.
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "text", am_text("Hello World"))
#' text_obj <- am_get(doc, AM_ROOT, "text")
#'
#' # Create cursor
#' cursor <- am_cursor(text_obj, 5)
#'
#' # Get position
#' pos <- am_cursor_position(cursor)
#' pos  # 5
#'
#' am_close(doc)
#'
am_cursor_position <- function(cursor, heads = NULL) {
  .Call(C_am_cursor_position, cursor, heads)
}

#' Serialize a cursor to bytes
#'
#' Converts a cursor to a raw vector representation that can be persisted
#' and later restored with [am_cursor_from_bytes()]. This enables saving
#' cursor positions across R sessions.
#'
#' @param cursor An `am_cursor` object created by [am_cursor()]
#'
#' @return A raw vector containing the serialized cursor
#'
#' @seealso [am_cursor_from_bytes()], [am_cursor_to_string()]
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "text", am_text("Hello World"))
#' text_obj <- am_get(doc, AM_ROOT, "text")
#'
#' cursor <- am_cursor(text_obj, 5)
#' bytes <- am_cursor_to_bytes(cursor)
#' bytes
#'
#' # Restore cursor later
#' restored <- am_cursor_from_bytes(bytes, text_obj)
#' am_cursor_position(restored)  # 5
#'
#' am_close(doc)
#'
am_cursor_to_bytes <- function(cursor) {
  .Call(C_am_cursor_to_bytes, cursor)
}

#' Restore a cursor from bytes
#'
#' Restores a cursor from a raw vector previously created by
#' [am_cursor_to_bytes()]. The text object is required to associate the
#' cursor with a document.
#'
#' @param bytes A raw vector containing a serialized cursor
#' @param obj An Automerge text object to associate the cursor with
#'
#' @return An `am_cursor` object
#'
#' @seealso [am_cursor_to_bytes()]
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "text", am_text("Hello World"))
#' text_obj <- am_get(doc, AM_ROOT, "text")
#'
#' cursor <- am_cursor(text_obj, 5)
#' bytes <- am_cursor_to_bytes(cursor)
#'
#' restored <- am_cursor_from_bytes(bytes, text_obj)
#' restored
#' am_cursor_position(restored)  # 5
#'
#' am_close(doc)
#'
am_cursor_from_bytes <- function(bytes, obj) {
  .Call(C_am_cursor_from_bytes, bytes, obj)
}

#' Serialize a cursor to a string
#'
#' Converts a cursor to a string representation that can be persisted
#' and later restored with [am_cursor_from_string()].
#'
#' @param cursor An `am_cursor` object created by [am_cursor()]
#'
#' @return A character string containing the serialized cursor
#'
#' @seealso [am_cursor_from_string()], [am_cursor_to_bytes()]
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "text", am_text("Hello World"))
#' text_obj <- am_get(doc, AM_ROOT, "text")
#'
#' cursor <- am_cursor(text_obj, 5)
#' str <- am_cursor_to_string(cursor)
#' str
#'
#' # Restore cursor later
#' restored <- am_cursor_from_string(str, text_obj)
#' am_cursor_position(restored)  # 5
#'
#' am_close(doc)
#'
am_cursor_to_string <- function(cursor) {
  .Call(C_am_cursor_to_string, cursor)
}

#' Restore a cursor from a string
#'
#' Restores a cursor from a string previously created by
#' [am_cursor_to_string()]. The text object is required to associate the
#' cursor with a document.
#'
#' @param str A character string containing a serialized cursor
#' @param obj An Automerge text object to associate the cursor with
#'
#' @return An `am_cursor` object
#'
#' @seealso [am_cursor_to_string()]
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "text", am_text("Hello World"))
#' text_obj <- am_get(doc, AM_ROOT, "text")
#'
#' cursor <- am_cursor(text_obj, 5)
#' str <- am_cursor_to_string(cursor)
#'
#' restored <- am_cursor_from_string(str, text_obj)
#' restored
#' am_cursor_position(restored)  # 5
#'
#' am_close(doc)
#'
am_cursor_from_string <- function(str, obj) {
  .Call(C_am_cursor_from_string, str, obj)
}

#' Test equality of two cursors
#'
#' Compares two cursors to determine if they refer to the same position
#' in a document. This compares the internal cursor representation, not
#' just the current position.
#'
#' @param cursor1 An `am_cursor` object
#' @param cursor2 An `am_cursor` object
#'
#' @return A logical scalar: `TRUE` if the cursors are equal, `FALSE` otherwise
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "text", am_text("Hello World"))
#' text_obj <- am_get(doc, AM_ROOT, "text")
#'
#' cursor1 <- am_cursor(text_obj, 5)
#' cursor2 <- am_cursor(text_obj, 5)
#' cursor3 <- am_cursor(text_obj, 3)
#'
#' am_cursor_equal(cursor1, cursor2)  # TRUE
#' am_cursor_equal(cursor1, cursor3)  # FALSE
#'
#' am_close(doc)
#'
am_cursor_equal <- function(cursor1, cursor2) {
  .Call(C_am_cursor_equal, cursor1, cursor2)
}

#' Create a mark on a text range
#'
#' Marks attach metadata or formatting information to a range of text.
#' Unlike simple annotations, marks are CRDT-aware and merge correctly
#' across concurrent edits.
#'
#' @param obj An Automerge object ID (must be a text object)
#' @param start Integer start position (0-based inter-character position, inclusive)
#' @param end Integer end position (0-based inter-character position, exclusive)
#' @param name Character string identifying the mark (e.g., "bold", "comment")
#' @param value The mark's value (any Automerge-compatible type: NULL, logical,
#'   integer, numeric, character, raw, POSIXct, or am_counter)
#' @param expand Character string controlling mark expansion behavior when text
#'   is inserted at boundaries. Options:
#'   \describe{
#'     \item{"none"}{Mark does not expand (default)}
#'     \item{"before"}{Mark expands to include text inserted before start}
#'     \item{"after"}{Mark expands to include text inserted after end}
#'     \item{"both"}{Mark expands in both directions}
#'   }
#'   Use the constants [AM_MARK_EXPAND_NONE], [AM_MARK_EXPAND_BEFORE],
#'   [AM_MARK_EXPAND_AFTER], or [AM_MARK_EXPAND_BOTH].
#'
#' @return The text object `obj` (invisibly)
#'
#' @section Indexing Convention:
#' **Mark positions use 0-based indexing** (unlike list indices which are
#' 1-based). Positions specify locations **between** characters. The range
#' `[start, end)` includes `start` but excludes `end`.
#'
#' For the text "Hello":
#' \preformatted{
#'   H e l l o
#'  0 1 2 3 4 5  <- positions (0-based, between characters)
#' }
#'
#' Marking positions 0 to 5 marks all 5 characters. Marking 0 to 3 marks "Hel".
#' Positions count Unicode code points (characters), not bytes.
#'
#' @section Expand Behavior:
#' The `expand` parameter controls what happens when text is inserted exactly
#' at the mark boundaries:
#' \itemize{
#'   \item `"none"`: New text is never included in the mark
#'   \item `"before"`: Text inserted at `start` is included
#'   \item `"after"`: Text inserted at `end` is included
#'   \item `"both"`: Text inserted at either boundary is included
#' }
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "text", am_text("Hello World"))
#' text_obj <- am_get(doc, AM_ROOT, "text")
#'
#' # Mark "Hello" as bold (positions 0-4, characters 0-4)
#' am_mark(text_obj, 0, 5, "bold", TRUE)
#'
#' # Mark "World" as italic with expansion
#' am_mark(text_obj, 6, 11, "italic", TRUE,
#'         expand = AM_MARK_EXPAND_BOTH)
#'
#' # Get all marks
#' marks <- am_marks(text_obj)
#' marks
#'
#' am_close(doc)
#'
am_mark <- function(
  obj,
  start,
  end,
  name,
  value,
  expand = AM_MARK_EXPAND_NONE
) {
  invisible(.Call(C_am_mark, obj, start, end, name, value, expand))
}

#' Get all marks in a text object
#'
#' Retrieves all marks (formatting/metadata annotations) present in a text
#' object at a specific document state.
#'
#' @param obj An Automerge object ID (must be a text object)
#' @param heads Optional list of change hashes (raw vectors) to query marks at
#'   a historical document state. If `NULL` (default), uses the current state.
#'
#' @return A list of marks, where each mark is a list with fields:
#'   \describe{
#'     \item{name}{Character string identifying the mark}
#'     \item{value}{The mark's value (various types supported)}
#'     \item{start}{Integer start position (0-based inter-character position, inclusive)}
#'     \item{end}{Integer end position (0-based inter-character position, exclusive)}
#'   }
#'   Returns an empty list if no marks are present. See [am_mark()] for
#'   indexing details.
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "text", am_text("Hello World"))
#' text_obj <- am_get(doc, AM_ROOT, "text")
#'
#' am_mark(text_obj, 0, 5, "bold", TRUE)
#' am_mark(text_obj, 6, 11, "italic", TRUE)
#'
#' marks <- am_marks(text_obj)
#' marks
#' # List of 2 marks with name, value, start, end
#'
#' am_close(doc)
#'
am_marks <- function(obj, heads = NULL) {
  .Call(C_am_marks, obj, heads)
}

#' Get marks at a specific position
#'
#' Retrieves marks that include a specific position in a text object. This
#' function efficiently filters marks at the C level, avoiding the overhead
#' of converting all marks to R objects.
#'
#' @param obj An Automerge object ID (must be a text object)
#' @param position Integer position (0-based inter-character position) to query.
#'   See [am_mark()] for indexing details.
#' @param heads Optional list of change hashes (raw vectors) to query marks at
#'   a historical document state. If `NULL` (default), uses the current state.
#'
#' @return A list of marks that include the specified position. Returns an empty
#'   list if no marks cover that position.
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "text", am_text("Hello World"))
#' text_obj <- am_get(doc, AM_ROOT, "text")
#'
#' am_mark(text_obj, 0, 5, "bold", TRUE)
#' am_mark(text_obj, 2, 7, "underline", TRUE)
#'
#' # Get marks at position 3 (inside "Hello")
#' marks_at_3 <- am_marks_at(text_obj, 3)
#' marks_at_3
#' # List of 2 marks (both "bold" and "underline" include position 3)
#'
#' am_close(doc)
#'
am_marks_at <- function(obj, position, heads = NULL) {
  .Call(C_am_marks_at, obj, position, heads)
}

# v1.2 Mark Operations -------------------------------------------------------

#' Clear marks from a text range
#'
#' Removes marks matching the given name from a range of text. This is the
#' inverse of [am_mark()].
#'
#' @param obj An Automerge object ID (must be a text object)
#' @param start Integer start position (0-based inter-character position, inclusive)
#' @param end Integer end position (0-based inter-character position, exclusive)
#' @param name Character string identifying the mark to clear (e.g., "bold")
#' @param expand Character string controlling mark clearing behavior at
#'   boundaries. Options: `"none"` (default), `"before"`, `"after"`, `"both"`.
#'   Use the constants [AM_MARK_EXPAND_NONE], [AM_MARK_EXPAND_BEFORE],
#'   [AM_MARK_EXPAND_AFTER], or [AM_MARK_EXPAND_BOTH].
#'
#' @return The text object `obj` (invisibly)
#'
#' @section Indexing Convention:
#' Uses the same 0-based inter-character position indexing as [am_mark()].
#'
#' @seealso [am_mark()], [am_marks()]
#'
#' @export
#' @examples
#' doc <- am_create()
#' am_put(doc, AM_ROOT, "text", am_text("Hello World"))
#' text_obj <- am_get(doc, AM_ROOT, "text")
#'
#' # Add a mark
#' am_mark(text_obj, 0, 11, "bold", TRUE)
#' length(am_marks(text_obj))  # 1
#'
#' # Clear the mark
#' am_mark_clear(text_obj, 0, 11, "bold")
#' length(am_marks(text_obj))  # 0
#'
#' am_close(doc)
#'
am_mark_clear <- function(
  obj,
  start,
  end,
  name,
  expand = AM_MARK_EXPAND_NONE
) {
  invisible(.Call(C_am_mark_clear, obj, start, end, name, expand))
}
