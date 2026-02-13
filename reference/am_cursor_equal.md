# Test equality of two cursors

Compares two cursors to determine if they refer to the same position in
a document. This compares the internal cursor representation, not just
the current position.

## Usage

``` r
am_cursor_equal(cursor1, cursor2)
```

## Arguments

- cursor1:

  An `am_cursor` object

- cursor2:

  An `am_cursor` object

## Value

A logical scalar: `TRUE` if the cursors are equal, `FALSE` otherwise

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "text", am_text("Hello World"))
text_obj <- am_get(doc, AM_ROOT, "text")

cursor1 <- am_cursor(text_obj, 5)
cursor2 <- am_cursor(text_obj, 5)
cursor3 <- am_cursor(text_obj, 3)

am_cursor_equal(cursor1, cursor2)  # TRUE
#> [1] TRUE
am_cursor_equal(cursor1, cursor3)  # FALSE
#> [1] FALSE

am_close(doc)
```
