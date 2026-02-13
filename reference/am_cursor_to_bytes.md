# Serialize a cursor to bytes

Converts a cursor to a raw vector representation that can be persisted
and later restored with
[`am_cursor_from_bytes()`](https://posit-dev.github.io/automerge-r/reference/am_cursor_from_bytes.md).
This enables saving cursor positions across R sessions.

## Usage

``` r
am_cursor_to_bytes(cursor)
```

## Arguments

- cursor:

  An `am_cursor` object created by
  [`am_cursor()`](https://posit-dev.github.io/automerge-r/reference/am_cursor.md)

## Value

A raw vector containing the serialized cursor

## See also

[`am_cursor_from_bytes()`](https://posit-dev.github.io/automerge-r/reference/am_cursor_from_bytes.md),
[`am_cursor_to_string()`](https://posit-dev.github.io/automerge-r/reference/am_cursor_to_string.md)

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "text", am_text("Hello World"))
text_obj <- am_get(doc, AM_ROOT, "text")

cursor <- am_cursor(text_obj, 5)
bytes <- am_cursor_to_bytes(cursor)
bytes
#>  [1] 01 03 10 bc 4a 0d 3d d1 9a ce b7 ba 96 1b 10 4e 2f 84 28 07 02

# Restore cursor later
restored <- am_cursor_from_bytes(bytes, text_obj)
am_cursor_position(restored)  # 5
#> [1] 5

am_close(doc)
```
