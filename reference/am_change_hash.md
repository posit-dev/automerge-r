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
#>  [1] a1 42 a5 57 08 5c b3 f1 15 53 89 84 09 1b 62 5a 1c 73 3b 43 29 6a
#> [23] 1f 62 e6 05 70 73 93 33 1f 8d
length(hash)  # 32 bytes
#> [1] 32

am_close(doc)
```
