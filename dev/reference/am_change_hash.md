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
  [`am_get_history()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get_history.md),
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

history <- am_get_history(doc)
hash <- am_change_hash(history[[1]])
hash
#>  [1] 86 11 bd d8 c8 58 09 c5 ab 8b fb d9 c5 64 f9 39 3c ae bc f8 1b c8
#> [23] b8 e0 38 89 cc a7 57 42 77 27
length(hash)  # 32 bytes
#> [1] 32

am_close(doc)
```
