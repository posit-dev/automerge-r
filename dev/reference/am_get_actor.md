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
#>  [1] ae 4a a4 d4 68 bb cf 12 11 c7 76 94 8b 03 4d 96

# Use am_get_actor_hex() for display
actor_hex <- am_get_actor_hex(doc)
cat("Actor ID:", actor_hex, "\n")
#> Actor ID: ae4aa4d468bbcf1211c776948b034d96 

am_close(doc)
```
