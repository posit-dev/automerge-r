# Clone an Automerge document

Creates an independent deep copy of an Automerge document, preserving
the same actor ID. Changes to the clone do not affect the original, and
vice versa.

## Usage

``` r
am_clone(doc)
```

## Arguments

- doc:

  An Automerge document

## Value

A new Automerge document (independent copy with same actor ID)

## Details

Unlike
[`am_fork()`](https://posit-dev.github.io/automerge-r/reference/am_fork.md),
which assigns a new actor ID to the copy, `am_clone()` preserves the
original actor ID. This makes it suitable for archival snapshots or
checkpoints where you want an exact copy of the document state. Do not
use `am_clone()` to create branches that will make independent edits and
later be merged — use
[`am_fork()`](https://posit-dev.github.io/automerge-r/reference/am_fork.md)
for that, as two documents sharing an actor ID can cause conflicts.

## See also

[`am_fork()`](https://posit-dev.github.io/automerge-r/reference/am_fork.md)
for creating branches with a new actor ID

## Examples

``` r
doc <- am_create()
doc$key <- "value"
am_commit(doc)

clone <- am_clone(doc)
clone$key  # "value"
#> [1] "value"

# Clone preserves the actor ID
am_get_actor_hex(doc) == am_get_actor_hex(clone) # TRUE
#> [1] TRUE

# Changes to clone don't affect original
clone$key <- "changed"
doc$key  # still "value"
#> [1] "value"

am_close(doc)
am_close(clone)
```
