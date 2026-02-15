# Get all conflicting values at a list position

Returns all values stored at a list position, including conflicts from
concurrent edits. When there are no conflicts, the list contains a
single element (the winning value).

## Usage

``` r
am_list_get_all(doc, obj, pos, heads = NULL)
```

## Arguments

- doc:

  An Automerge document

- obj:

  An Automerge object ID (must be a list)

- pos:

  Numeric index (1-based, like R vectors)

- heads:

  Optional list of change hashes (raw vectors) for historical query. If
  `NULL` (default), uses the current state.

## Value

A list of all values at the position. Returns an empty list if the
position does not exist.

## Examples

``` r
doc <- am_create()
doc$items <- list("a", "b", "c")
items <- doc$items

# Single value (no conflict)
values <- am_list_get_all(doc, items, 1)
length(values)  # 1
#> [1] 1

am_close(doc)
```
