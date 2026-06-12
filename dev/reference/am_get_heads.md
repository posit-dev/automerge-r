# Get the current heads of a document

Returns the current "heads" of the document - the hashes of the most
recent changes. These identify the current state of the document and can
be used for history operations.

## Usage

``` r
am_get_heads(doc)
```

## Arguments

- doc:

  An Automerge document

## Value

A list of raw vectors, each containing a change hash. Usually there is
only one head, but after concurrent edits there may be multiple heads
until they are merged by a subsequent commit.

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "x", 1)
am_commit(doc)

heads <- am_get_heads(doc)
heads
#> [[1]]
#>  [1] d2 c2 d3 37 cc 46 f7 c8 f0 5e 99 b4 49 04 1d 42 5e d8 b4 0a 71 c9
#> [23] 0b ca 86 74 d1 e9 58 56 f3 0c
#> 

am_close(doc)
```
