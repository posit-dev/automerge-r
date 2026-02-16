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
  [`am_get_changes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get_changes.md),
  [`am_get_changes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get_changes.md),
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
#>  [1] 58 35 ec 3d 68 98 72 76 94 b4 e7 cf 60 8a e3 e2 7c 83 1f 23 40 50
#> [23] 49 9e 17 94 e3 04 a0 db 11 f3
length(hash)  # 32 bytes
#> [1] 32

am_close(doc)
```
