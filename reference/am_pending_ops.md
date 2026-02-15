# Get the number of pending operations

Returns the number of operations that have been applied to the document
but not yet committed. This is useful for determining whether a commit
is needed.

## Usage

``` r
am_pending_ops(doc)
```

## Arguments

- doc:

  An Automerge document

## Value

An integer indicating the number of pending operations. Returns 0 if
there are no uncommitted changes.

## Examples

``` r
doc <- am_create()
am_pending_ops(doc)  # 0
#> [1] 0

doc$key <- "value"
am_pending_ops(doc)  # > 0
#> [1] 1

am_commit(doc)
am_pending_ops(doc)  # 0
#> [1] 0

am_close(doc)
```
