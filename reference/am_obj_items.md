# Get full item details from an object

Returns detailed information about each entry in a map or list,
including the key (or index) and value for each item. This provides more
information than
[`am_values()`](https://posit-dev.github.io/automerge-r/reference/am_values.md)
alone.

## Usage

``` r
am_obj_items(doc, obj, heads = NULL)
```

## Arguments

- doc:

  An Automerge document

- obj:

  An Automerge object ID, or `AM_ROOT` for the document root

- heads:

  Optional list of change hashes (raw vectors) for historical query. If
  `NULL` (default), uses the current state.

## Value

A list of lists, where each inner list has fields:

- key:

  For maps: the character key. For lists: the 1-based integer index.

- value:

  The value at this entry.

## Examples

``` r
doc <- am_create()
doc$name <- "Alice"
doc$age <- 30L

items <- am_obj_items(doc, AM_ROOT)
items[[1]]$key    # "age" (sorted lexicographically)
#> NULL
items[[1]]$value  # 30
#> [1] 30

am_close(doc)
```
