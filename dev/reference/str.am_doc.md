# Display the structure of an Automerge document

S3 method for [`utils::str()`](https://rdrr.io/r/utils/str.html) that
displays the structure of an Automerge document in a human-readable
format.

## Usage

``` r
# S3 method for class 'am_doc'
str(object, max.level = 2, ...)
```

## Arguments

- object:

  An automerge document object.

- max.level:

  Maximum depth to recurse into nested structures. Default 2.

- ...:

  Additional arguments (ignored).

## Value

Invisibly returns `NULL`.

## Examples

``` r
doc <- am_create()
doc$name <- "Alice"
doc$data <- list(x = 1L, y = 2L)
str(doc)
#> data: {object}
#>   x: 1
#>   y: 2
#> name: "Alice"
str(doc, max.level = 1)
#> data: {object}
#>   x: 1
#>   y: 2
#> name: "Alice"
am_close(doc)
```
