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
[`am_get_actor_hex()`](https://posit-dev.github.io/automerge-r/reference/am_get_actor_hex.md).

## Examples

``` r
doc <- am_create()
actor <- am_get_actor(doc)
actor
#>  [1] 5e a3 7b c1 51 c8 38 6c 8f a5 99 4d 2c d2 3a de

# Use am_get_actor_hex() for display
actor_hex <- am_get_actor_hex(doc)
cat("Actor ID:", actor_hex, "\n")
#> Actor ID: 5ea37bc151c8386c8fa5994d2cd23ade 

am_close(doc)
```
