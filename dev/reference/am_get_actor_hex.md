# Get the actor ID as a hex string

Returns the actor ID of an Automerge document as a hex-encoded string.
This is more efficient than converting the raw bytes returned by
[`am_get_actor()`](https://posit-dev.github.io/automerge-r/dev/reference/am_get_actor.md)
using R-level string operations.

## Usage

``` r
am_get_actor_hex(doc)
```

## Arguments

- doc:

  An Automerge document

## Value

A character string containing the hex-encoded actor ID

## Examples

``` r
doc <- am_create()
actor_hex <- am_get_actor_hex(doc)
actor_hex
#> [1] "de01bf4831e5f77a0669152bcebb1197"

am_close(doc)
```
