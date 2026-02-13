# Get the hash of a change

Returns the unique hash identifier of a change. Change hashes are used
to reference specific points in document history (e.g., with
[`am_get_change_by_hash()`](https://posit-dev.github.io/automerge-r/reference/am_get_change_by_hash.md)
or
[`am_fork()`](https://posit-dev.github.io/automerge-r/reference/am_fork.md)).

## Usage

``` r
am_change_hash(change)
```

## Arguments

- change:

  An `am_change` object (from
  [`am_get_history()`](https://posit-dev.github.io/automerge-r/reference/am_get_history.md),
  [`am_get_changes()`](https://posit-dev.github.io/automerge-r/reference/am_get_changes.md),
  or
  [`am_change_from_bytes()`](https://posit-dev.github.io/automerge-r/reference/am_change_from_bytes.md))

## Value

A raw vector (32 bytes) containing the change hash

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "key", "value")
am_commit(doc, "Add key")

history <- am_get_history(doc)
hash <- am_change_hash(history[[1]])
hash
#>  [1] 6d 2e 66 60 99 fa a2 4e 8a 4d 4a 48 95 2d 66 6b 32 c4 dd 67 e3 bb
#> [23] 13 65 cb 1d d2 ff f6 04 4a 82
length(hash)  # 32 bytes
#> [1] 32

am_close(doc)
```
