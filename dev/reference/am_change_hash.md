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
#>  [1] 79 06 e4 dc 0d fb 3b 2f ae 73 9b 61 f1 9b 1f 5a 22 be 62 80 56 cd
#> [23] 8a af 34 d2 1b fa 5d 63 9a 48

am_close(doc)
```
