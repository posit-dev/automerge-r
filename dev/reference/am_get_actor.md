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
#>  [1] 0c 12 21 69 9e ea ae 0e 99 29 a4 72 bc 4a 29 9b

# Use am_get_actor_hex() for display
actor_hex <- am_get_actor_hex(doc)
cat("Actor ID:", actor_hex, "\n")
#> Actor ID: 0c1221699eeaae0e9929a472bc4a299b 

am_close(doc)
```
