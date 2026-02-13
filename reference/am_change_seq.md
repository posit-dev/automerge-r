# Get the sequence number of a change

Returns the sequence number of the change within its actor's history.
Sequence numbers start at 1 and increment with each change by the same
actor.

## Usage

``` r
am_change_seq(change)
```

## Arguments

- change:

  An `am_change` object (from
  [`am_get_history()`](https://posit-dev.github.io/automerge-r/reference/am_get_history.md),
  [`am_get_changes()`](https://posit-dev.github.io/automerge-r/reference/am_get_changes.md),
  or
  [`am_change_from_bytes()`](https://posit-dev.github.io/automerge-r/reference/am_change_from_bytes.md))

## Value

A numeric value (double, since sequence numbers can exceed R's 32-bit
integer range)

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "x", 1)
am_commit(doc, "First")
am_put(doc, AM_ROOT, "y", 2)
am_commit(doc, "Second")

history <- am_get_history(doc)
am_change_seq(history[[1]])  # 1
#> [1] 1
am_change_seq(history[[2]])  # 2
#> [1] 2

am_close(doc)
```
