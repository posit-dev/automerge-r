# Restore a cursor from a string

Restores a cursor from a string previously created by
[`am_cursor_to_string()`](https://posit-dev.github.io/automerge-r/reference/am_cursor_to_string.md).
The text object is required to associate the cursor with a document.

## Usage

``` r
am_cursor_from_string(str, obj)
```

## Arguments

- str:

  A character string containing a serialized cursor

- obj:

  An Automerge text object to associate the cursor with

## Value

An `am_cursor` object

## See also

[`am_cursor_to_string()`](https://posit-dev.github.io/automerge-r/reference/am_cursor_to_string.md)

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "text", am_text("Hello World"))
text_obj <- am_get(doc, AM_ROOT, "text")

cursor <- am_cursor(text_obj, 5)
str <- am_cursor_to_string(cursor)

restored <- am_cursor_from_string(str, text_obj)
am_cursor_position(restored)  # 5
#> [1] 5

am_close(doc)
```
