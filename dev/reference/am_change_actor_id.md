# Get the actor ID of a change

Returns the actor ID of the peer that created the change.

## Usage

``` r
am_change_actor_id(change)
```

## Arguments

- change:

  An `am_change` object (from
  [`am_get_history()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get_history.md),
  [`am_get_changes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get_changes.md),
  or
  [`am_change_from_bytes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_from_bytes.md))

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
#>  [1] 60 37 0c 75 7c 9e dc f2 c9 47 6e 8e 9c 12 45 2c

# Should match the document's actor
identical(actor, am_get_actor(doc))  # TRUE
#> [1] TRUE

am_close(doc)
```
