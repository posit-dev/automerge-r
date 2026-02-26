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
#>  [1] ca 5c 76 0d 61 ea 07 b9 29 21 8b da 7b 1d a1 49 2f 99 36 97 23 68
#> [23] e7 ee 81 46 14 61 db 9d 51 bb
#> 

am_close(doc)
```
