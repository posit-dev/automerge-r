# Restore a cursor from bytes

Restores a cursor from a raw vector previously created by
[`am_cursor_to_bytes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_cursor_to_bytes.md).
The text object is required to associate the cursor with a document.

## Usage

``` r
am_cursor_from_bytes(bytes, obj)
```

## Arguments

- bytes:

  A raw vector containing a serialized cursor

- obj:

  An Automerge text object to associate the cursor with

## Value

An `am_cursor` object

## See also

[`am_cursor_to_bytes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_cursor_to_bytes.md)

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "text", am_text("Hello World"))
text_obj <- am_get(doc, AM_ROOT, "text")

cursor <- am_cursor(text_obj, 5)
bytes <- am_cursor_to_bytes(cursor)

restored <- am_cursor_from_bytes(bytes, text_obj)
restored
#> <Automerge Cursor>
am_cursor_position(restored)  # 5
#> [1] 5

am_close(doc)
```
