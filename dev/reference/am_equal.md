# Test document equality

Tests whether two Automerge documents have the same content. Documents
are equal if they have the same set of changes applied, regardless of
how they were created.

## Usage

``` r
am_equal(doc1, doc2)
```

## Arguments

- doc1:

  An Automerge document

- doc2:

  An Automerge document

## Value

A logical scalar: `TRUE` if the documents are equal, `FALSE` otherwise.

## Examples

``` r
doc1 <- am_create()
doc1$key <- "value"
am_commit(doc1)

doc2 <- am_clone(doc1)
am_equal(doc1, doc2)  # TRUE
#> [1] TRUE

doc2$key <- "different"
am_equal(doc1, doc2)  # FALSE
#> [1] FALSE

am_close(doc1)
am_close(doc2)
```
