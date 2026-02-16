# Get the actor ID of a document

Returns the actor ID of an Automerge document as a raw vector. The actor
ID uniquely identifies the editing session that created changes in the
document.

## Usage

``` r
am_get_actor(doc)
```

## Arguments

- doc:

  An Automerge document

## Value

A raw vector containing the actor ID bytes

## Details

For a hex string representation, use
[`am_get_actor_hex()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get_actor_hex.md).

## Examples

``` r
doc <- am_create()
actor <- am_get_actor(doc)
actor
#>  [1] b8 07 d7 fa 92 85 06 65 20 e7 c8 1f 7c dc 02 44

# Use am_get_actor_hex() for display
actor_hex <- am_get_actor_hex(doc)
cat("Actor ID:", actor_hex, "\n")
#> Actor ID: b807d7fa9285066520e7c81f7cdc0244 

am_close(doc)
```
