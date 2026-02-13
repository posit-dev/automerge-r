# Serialize a change to raw bytes

Converts an `am_change` object back to its serialized raw vector form.

## Usage

``` r
am_change_to_bytes(change)
```

## Arguments

- change:

  An `am_change` object (from
  [`am_get_history()`](https://posit-dev.github.io/automerge-r/reference/am_get_history.md),
  [`am_get_changes()`](https://posit-dev.github.io/automerge-r/reference/am_get_changes.md),
  or
  [`am_change_from_bytes()`](https://posit-dev.github.io/automerge-r/reference/am_change_from_bytes.md))

## Value

A raw vector containing the serialized change

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "key", "value")
am_commit(doc, "Add key")

history <- am_get_history(doc)
bytes <- am_change_to_bytes(history[[1]])

# Round-trip
restored <- am_change_from_bytes(bytes)
identical(am_change_to_bytes(restored), bytes)  # TRUE
#> [1] TRUE

am_close(doc)
```
