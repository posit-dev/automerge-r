# Load incremental changes into a document

Applies incremental changes (from
[`am_save_incremental()`](https://posit-dev.github.io/automerge-r/reference/am_save_incremental.md))
to a document. This is more efficient than loading a full document when
only a few changes need to be applied.

## Usage

``` r
am_load_incremental(doc, data)
```

## Arguments

- doc:

  An Automerge document

- data:

  A raw vector containing incremental changes (from
  [`am_save_incremental()`](https://posit-dev.github.io/automerge-r/reference/am_save_incremental.md))

## Value

The number of operations applied (numeric scalar, invisibly).

## See also

[`am_save_incremental()`](https://posit-dev.github.io/automerge-r/reference/am_save_incremental.md),
[`am_load()`](https://posit-dev.github.io/automerge-r/reference/am_load.md)

## Examples

``` r
doc1 <- am_create()
doc1$key <- "value"
am_commit(doc1)
bytes <- am_save(doc1)

doc1$key2 <- "value2"
am_commit(doc1)
incremental <- am_save_incremental(doc1)

# Load base document and apply incremental changes
doc2 <- am_load(bytes)
am_load_incremental(doc2, incremental)
doc2$key2  # "value2"
#> [1] "value2"

am_close(doc1)
am_close(doc2)
```
