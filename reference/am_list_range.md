# Get a range of list items

Returns list elements within the index range `[begin, end]`. Uses
1-based indexing consistent with R conventions.

## Usage

``` r
am_list_range(doc, obj, begin, end, heads = NULL)
```

## Arguments

- doc:

  An Automerge document

- obj:

  An Automerge object ID (must be a list)

- begin:

  Start index (1-based, inclusive)

- end:

  End index (1-based, inclusive)

- heads:

  Optional list of change hashes (raw vectors) for historical query. If
  `NULL` (default), uses the current state.

## Value

A list of values in the index range.

## Examples

``` r
doc <- am_create()
doc$items <- list("a", "b", "c", "d", "e")
items <- doc$items

# Get elements 2 through 4 -> "b", "c", "d"
range <- am_list_range(doc, items, 2, 4)
range
#> [[1]]
#> [1] "b"
#> 
#> [[2]]
#> [1] "c"
#> 
#> [[3]]
#> [1] "d"
#> 

am_close(doc)
```
