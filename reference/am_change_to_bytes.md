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
bytes
#>  [1] 85 6f 4a 83 df a2 22 48 01 3c 00 10 80 f2 ae 9f 36 0b 45 56 6e 4e
#> [23] a5 40 f8 8b 12 d9 01 01 00 07 41 64 64 20 6b 65 79 00 06 15 05 34
#> [45] 01 42 02 56 02 57 05 70 02 7f 03 6b 65 79 01 7f 01 7f 56 76 61 6c
#> [67] 75 65 7f 00

# Round-trip
restored <- am_change_from_bytes(bytes)
identical(am_change_to_bytes(restored), bytes)  # TRUE
#> [1] TRUE

am_close(doc)
```
