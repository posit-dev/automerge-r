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
#>  [1] fe 5f 5c eb 6f d8 69 17 bd 55 32 61 0b da 7a c7

# Use am_get_actor_hex() for display
actor_hex <- am_get_actor_hex(doc)
cat("Actor ID:", actor_hex, "\n")
#> Actor ID: fe5f5ceb6fd86917bd5532610bda7ac7 

am_close(doc)
```
