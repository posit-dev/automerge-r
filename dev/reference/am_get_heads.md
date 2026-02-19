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
#>  [1] 2e b1 bb 0b 0d d0 d5 02 80 7a 19 66 76 21 6d d5 2d c3 d7 fe 2c f4
#> [23] f5 62 ed 5e 89 ee b6 c8 48 c0
#> 

am_close(doc)
```
