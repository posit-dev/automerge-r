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
  [`am_get_changes()`](https://posit-dev.github.io/automerge-r/reference/am_get_changes.md)
  or
  [`am_change_from_bytes()`](https://posit-dev.github.io/automerge-r/reference/am_change_from_bytes.md))

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
#>  [1] 92 86 c1 93 6b 91 56 cf 52 ef 85 48 f9 aa 20 96 db 6f ba f9 f7 a5
#> [23] 96 7a 68 fa 99 37 e6 1c f3 88
#> 

am_close(doc)
```
