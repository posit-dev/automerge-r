# Get changes since specified heads

Returns all changes that have been made to the document since the
specified heads. If `heads` is `NULL`, returns all changes in the
document's history.

## Usage

``` r
am_get_changes(doc, heads = NULL)
```

## Arguments

- doc:

  An Automerge document

- heads:

  A list of raw vectors (change hashes) returned by
  [`am_get_heads()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get_heads.md),
  or `NULL` to get all changes.

## Value

A list of `am_change` objects.

## Details

Changes are returned as `am_change` objects that can be inspected with
[`am_change_hash()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_hash.md),
[`am_change_message()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_message.md),
etc., serialized with
[`am_change_to_bytes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_to_bytes.md),
or applied to other documents using
[`am_apply_changes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_apply_changes.md).

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "x", 1)
am_commit(doc)

# Get all changes
all_changes <- am_get_changes(doc)
all_changes
#> [[1]]
#> <Automerge Change>
#> Hash: 35 9f 32 91 ...
#> 

am_close(doc)
```
