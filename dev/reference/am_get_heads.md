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
#>  [1] f8 74 9d 2b 32 37 f4 bc 46 3e 4a 9d 5f e7 65 83 52 1f 99 9d 78 ce
#> [23] d2 aa 68 94 22 f2 42 13 2e 44
#> 

am_close(doc)
```
