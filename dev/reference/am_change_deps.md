# Get the dependencies of a change

Returns the hashes of the changes that this change depends on (i.e., its
parent changes in the causal graph). The first change in a document has
no dependencies.

## Usage

``` r
am_change_deps(change)
```

## Arguments

- change:

  An `am_change` object (from
  [`am_get_changes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get_changes.md)
  or
  [`am_change_from_bytes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_from_bytes.md))

## Value

A list of raw vectors (change hashes), each 32 bytes. Returns an empty
list for the first change in a document.

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "x", 1)
am_commit(doc, "First")
am_put(doc, AM_ROOT, "y", 2)
am_commit(doc, "Second")

history <- am_get_changes(doc)
deps1 <- am_change_deps(history[[1]])
deps1
#> list()

deps2 <- am_change_deps(history[[2]])
deps2
#> [[1]]
#>  [1] e8 c6 fe 64 2d 12 45 64 e7 59 df 62 ef b8 16 a8 73 36 0e f3 fc 10
#> [23] 35 6a 18 9c 93 b4 e5 66 93 27
#> 

am_close(doc)
```
