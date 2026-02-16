# Get the commit message of a change

Returns the commit message attached to a change, or `NULL` if no message
was provided when the change was committed.

## Usage

``` r
am_change_message(change)
```

## Arguments

- change:

  An `am_change` object (from
  [`am_get_changes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get_changes.md),
  [`am_get_changes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get_changes.md),
  or
  [`am_change_from_bytes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_from_bytes.md))

## Value

A character string containing the commit message, or `NULL`

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "key", "value")
am_commit(doc, "Add key")

history <- am_get_changes(doc)
am_change_message(history[[1]])  # "Add key"
#> [1] "Add key"

am_close(doc)
```
