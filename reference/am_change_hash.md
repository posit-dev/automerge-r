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
#>  [1] 0d d4 bd 81 5d 20 53 92 d0 4d 57 46 99 75 2a 4e be 0d 52 5d 48 20
#> [23] 54 29 d7 6c 79 86 02 e0 f4 bb
length(hash)  # 32 bytes
#> [1] 32

am_close(doc)
```
