# Fork an Automerge document

Creates a fork of an Automerge document at the current heads or at a
specific point in history. The forked document shares history with the
original up to the fork point but can diverge afterwards. The fork is
assigned a new actor ID, so changes made on the fork are distinguishable
from the original when merged or synced.

## Usage

``` r
am_fork(doc, heads = NULL)
```

## Arguments

- doc:

  An Automerge document

- heads:

  Optional list of change hashes to fork at a specific point in the
  document's history. If `NULL` (default) or an empty list, forks at
  current heads. Each hash should be a raw vector (32 bytes).

## Value

A new Automerge document (fork of the original)

## Details

Use `am_fork()` when creating independent branches of a document that
may later be merged or synced. Use
[`am_clone()`](https://posit-dev.github.io/automerge-r/dev/reference/am_clone.md)
instead if you need an exact copy that preserves the original actor ID
(e.g. for archival or snapshotting purposes).

## See also

[`am_clone()`](https://posit-dev.github.io/automerge-r/dev/reference/am_clone.md)
for an exact copy preserving the actor ID

## Examples

``` r
doc1 <- am_create()
doc2 <- am_fork(doc1)
doc2
#> <Automerge Document>
#> Actor: 4dd780219a34c4e3a97c8d891e235065 
#> Root keys: 0 

# Fork has a different actor ID
am_get_actor_hex(doc1) != am_get_actor_hex(doc2) # TRUE
#> [1] TRUE

# Now doc1 and doc2 can diverge independently
am_close(doc1)
am_close(doc2)
```
