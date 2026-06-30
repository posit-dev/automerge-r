# Parse a serialized change from raw bytes

Deserializes a change from raw bytes into an `am_change` object. This is
useful for restoring changes that were previously serialized with
[`am_change_to_bytes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_to_bytes.md)
or saved to disk.

## Usage

``` r
am_change_from_bytes(bytes)
```

## Arguments

- bytes:

  A raw vector containing a serialized change (from
  [`am_change_to_bytes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_to_bytes.md))

## Value

An `am_change` object (external pointer) that can be passed to
[`am_change_hash()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_hash.md),
[`am_change_message()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_message.md),
[`am_change_time()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_time.md),
[`am_change_actor_id()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_actor_id.md),
[`am_change_seq()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_seq.md),
and
[`am_change_deps()`](https://posit-dev.github.io/automerge-r/dev/reference/am_change_deps.md).

## Details

Note:
[`am_get_changes()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get_changes.md)
and other change-returning functions already return `am_change` objects
directly, so this function is only needed when working with raw byte
representations.

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "key", "value")
am_commit(doc, "Add key")

# Serialize a change and restore it
history <- am_get_changes(doc)
bytes <- am_change_to_bytes(history[[1]])
change <- am_change_from_bytes(bytes)
change
#> <Automerge Change>
#> Hash: 5e 3d f8 7c ...
#> Message: Add key 
am_change_message(change)  # "Add key"
#> [1] "Add key"

am_close(doc)
```
