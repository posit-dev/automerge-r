# Get missing dependencies

Returns the change hashes of dependencies that are referenced by the
document but not present in its change history. This can happen when
changes are applied out of order or when a document is partially synced.

## Usage

``` r
am_get_missing_deps(doc, heads = NULL)
```

## Arguments

- doc:

  An Automerge document

- heads:

  Optional list of change hashes (raw vectors) to check for missing
  dependencies. If `NULL` (default), checks the current heads.

## Value

A list of raw vectors (change hashes of missing dependencies). Returns
an empty list if no dependencies are missing.

## Examples

``` r
doc <- am_create()
doc$key <- "value"
am_commit(doc)

# Complete document has no missing deps
missing <- am_get_missing_deps(doc)
length(missing)  # 0
#> [1] 0

am_close(doc)
```
