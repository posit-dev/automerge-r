# Get the hash of a change

Returns the unique hash identifier of a change. Change hashes are used
to reference specific points in document history (e.g., with
[`am_get_change_by_hash()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get_change_by_hash.md)
or
[`am_fork()`](https://posit-dev.github.io/automerge-r/dev/reference/am_fork.md)).

## Usage

``` r
am_change_hash(change)
```

## Arguments

- change:

  An `am_change` object (from
  [`am_get_changes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get_changes.md)
  or
  [`am_change_from_bytes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_from_bytes.md))

## Value

A raw vector (32 bytes) containing the change hash

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "key", "value")
am_commit(doc, "Add key")

history <- am_get_changes(doc)
hash <- am_change_hash(history[[1]])
hash
#>  [1] 9a 5b 00 10 7b f8 88 c6 38 a1 de 5c c5 25 a0 4d a1 45 5f 07 54 30
#> [23] 18 39 66 5a 5c 05 3b 7f 98 cc

am_close(doc)
```
