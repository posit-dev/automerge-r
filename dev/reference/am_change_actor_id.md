# Get the actor ID of a change

Returns the actor ID of the peer that created the change.

## Usage

``` r
am_change_actor_id(change)
```

## Arguments

- change:

  An `am_change` object (from
  [`am_get_changes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get_changes.md)
  or
  [`am_change_from_bytes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_from_bytes.md))

## Value

A raw vector containing the actor ID bytes

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "key", "value")
am_commit(doc, "Add key")

history <- am_get_changes(doc)
actor <- am_change_actor_id(history[[1]])
actor
#>  [1] 3e f2 6c 8d 09 1b 8d 0a 65 78 d9 c7 3d fe f6 2e

# Should match the document's actor
identical(actor, am_get_actor(doc))  # TRUE
#> [1] TRUE

am_close(doc)
```
