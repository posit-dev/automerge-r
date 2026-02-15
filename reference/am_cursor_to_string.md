# Serialize a cursor to a string

Converts a cursor to a string representation that can be persisted and
later restored with
[`am_cursor_from_string()`](https://posit-dev.github.io/automerge-r/reference/am_cursor_from_string.md).

## Usage

``` r
am_cursor_to_string(cursor)
```

## Arguments

- cursor:

  An `am_cursor` object created by
  [`am_cursor()`](https://posit-dev.github.io/automerge-r/reference/am_cursor.md)

## Value

A character string containing the serialized cursor

## See also

[`am_cursor_from_string()`](https://posit-dev.github.io/automerge-r/reference/am_cursor_from_string.md),
[`am_cursor_to_bytes()`](https://posit-dev.github.io/automerge-r/reference/am_cursor_to_bytes.md)

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "text", am_text("Hello World"))
text_obj <- am_get(doc, AM_ROOT, "text")

cursor <- am_cursor(text_obj, 5)
str <- am_cursor_to_string(cursor)
str
#> [1] "7@046c72ec0b47256eb9461e5660a87415"

# Restore cursor later
restored <- am_cursor_from_string(str, text_obj)
am_cursor_position(restored)  # 5
#> [1] 5

am_close(doc)
```
