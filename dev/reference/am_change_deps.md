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
#>  [1] b4 1e 29 55 6d eb 91 96 9e 36 59 ab fc 8e f1 a1 15 f8 a6 fe a8 1c
#> [23] 90 3b ba 21 b9 c3 38 b1 bc 01
#> 

am_close(doc)
```
