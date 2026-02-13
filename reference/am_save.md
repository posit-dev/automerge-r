# Save an Automerge document to binary format

Serializes an Automerge document to the standard binary format, which
can be saved to disk or transmitted over a network. The binary format is
compatible across all Automerge implementations (JavaScript, Rust,
etc.).

## Usage

``` r
am_save(doc)
```

## Arguments

- doc:

  An Automerge document (created with
  [`am_create()`](https://posit-dev.github.io/automerge-r/reference/am_create.md)
  or
  [`am_load()`](https://posit-dev.github.io/automerge-r/reference/am_load.md))

## Value

A raw vector containing the serialized document

## Examples

``` r
doc <- am_create()
bytes <- am_save(doc)
bytes
#>  [1] 85 6f 4a 83 b8 1a 95 44 00 04 00 00 00 00

# Save to file
file <- tempfile()
writeBin(am_save(doc), file)

unlink(file)
am_close(doc)
```
