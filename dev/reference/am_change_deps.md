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
#>  [1] 9c 61 8f 54 fb 02 07 57 25 40 2a 11 3f 61 f0 10 fc 26 5f 22 97 56
#> [23] e7 27 57 33 27 2a b7 d8 0d a2
#> 

am_close(doc)
```
