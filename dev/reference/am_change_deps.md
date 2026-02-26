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
#>  [1] 9a 00 9d 7c aa 4b b4 84 cb 60 fa 73 34 cd 77 1a 48 a3 1e b2 d6 4a
#> [23] 9c f5 08 23 b3 dc 29 d2 64 1f
#> 

am_close(doc)
```
