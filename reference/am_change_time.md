# Get the timestamp of a change

Returns the timestamp recorded when the change was committed. Note that
timestamps are set by the committing peer and may not be accurate if the
peer's clock is wrong.

## Usage

``` r
am_change_time(change)
```

## Arguments

- change:

  An `am_change` object (from
  [`am_get_changes()`](https://posit-dev.github.io/automerge-r/reference/am_get_changes.md)
  or
  [`am_change_from_bytes()`](https://posit-dev.github.io/automerge-r/reference/am_change_from_bytes.md))

## Value

A `POSIXct` timestamp

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "key", "value")
am_commit(doc, "Add key", Sys.time())

history <- am_get_changes(doc)
am_change_time(history[[1]])
#> [1] "2026-07-09 17:21:57 UTC"

am_close(doc)
```
