# Close an Automerge document

Explicitly frees the resources associated with an Automerge document.
After calling this function, the document becomes invalid and should not
be used.

## Usage

``` r
am_close(doc)
```

## Arguments

- doc:

  An Automerge document

## Value

`NULL` (invisibly)

## Details

This function is useful when you need deterministic cleanup rather than
waiting for garbage collection. It is safe to call on a document that
has already been closed.

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "key", "value")

# Explicitly free resources
am_close(doc)

# Document is now invalid - do not use after closing
```
