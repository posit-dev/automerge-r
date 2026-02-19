# Get the number of operations in a change

Returns the number of operations contained in the change. Useful for
estimating the size of changes before syncing or storing them.

## Usage

``` r
am_change_size(change)
```

## Arguments

- change:

  An `am_change` object (from
  [`am_get_changes()`](https://posit-dev.github.io/automerge-r/reference/am_get_changes.md)
  or
  [`am_change_from_bytes()`](https://posit-dev.github.io/automerge-r/reference/am_change_from_bytes.md))

## Value

An integer (or double for very large values exceeding R's 32-bit integer
range)

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "x", 1)
am_put(doc, AM_ROOT, "y", 2)
am_commit(doc, "Add keys")

history <- am_get_changes(doc)
am_change_size(history[[1]])  # 2
#> [1] 2

am_close(doc)
```
