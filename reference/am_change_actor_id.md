# Get the actor ID of a change

Returns the actor ID of the peer that created the change.

## Usage

``` r
am_change_actor_id(change)
```

## Arguments

- change:

  An `am_change` object (from
  [`am_get_history()`](https://posit-dev.github.io/automerge-r/reference/am_get_history.md),
  [`am_get_changes()`](https://posit-dev.github.io/automerge-r/reference/am_get_changes.md),
  or
  [`am_change_from_bytes()`](https://posit-dev.github.io/automerge-r/reference/am_change_from_bytes.md))

## Value

A raw vector containing the actor ID bytes

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "key", "value")
am_commit(doc, "Add key")

history <- am_get_history(doc)
actor <- am_change_actor_id(history[[1]])
actor
#>  [1] 78 37 4d cc 10 07 de cb d1 ec 2a 4d 41 0e 63 2a

# Should match the document's actor
identical(actor, am_get_actor(doc))  # TRUE
#> [1] TRUE

am_close(doc)
```
