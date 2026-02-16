# Get document history

Returns the full change history of the document as a list of `am_change`
objects. Use the change introspection functions
([`am_change_hash()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_hash.md),
[`am_change_message()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_message.md),
[`am_change_time()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_time.md),
[`am_change_actor_id()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_actor_id.md),
[`am_change_seq()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_seq.md),
[`am_change_deps()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_deps.md))
to extract metadata from each change.

## Usage

``` r
am_get_history(doc)
```

## Arguments

- doc:

  An Automerge document

## Value

A list of `am_change` objects, one for each change in the document's
history, in chronological order.

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "x", 1)
am_commit(doc, "Initial")
am_put(doc, AM_ROOT, "x", 2)
am_commit(doc, "Update")

history <- am_get_history(doc)
cat("Document history contains", length(history), "change(s)\n")
#> Document history contains 2 change(s)

am_close(doc)
```
