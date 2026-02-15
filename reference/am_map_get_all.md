# Get all conflicting values at a map key

Returns all values stored at a map key, including conflicts from
concurrent edits by different actors. When there are no conflicts, the
list contains a single element (the winning value).

## Usage

``` r
am_map_get_all(doc, obj, key, heads = NULL)
```

## Arguments

- doc:

  An Automerge document

- obj:

  An Automerge object ID (must be a map), or `AM_ROOT`

- key:

  Character string key

- heads:

  Optional list of change hashes (raw vectors) for historical query. If
  `NULL` (default), uses the current state.

## Value

A list of all values at the key. Returns an empty list if the key does
not exist.

## Examples

``` r
doc <- am_create()
doc$key <- "value"

# Single value (no conflict)
values <- am_map_get_all(doc, AM_ROOT, "key")
length(values)  # 1
#> [1] 1

am_close(doc)
```
