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
#>  [1] d1 8c bf 97 82 88 57 9d cd a1 02 e6 25 d3 5c 84 ab 9b 3b 45 d1 fa
#> [23] c1 c6 63 7e 14 ec 28 3d 7c 74
#> 

am_close(doc)
```
