# Save incremental changes

Serializes only the changes made since the last call to
[`am_save()`](https://posit-dev.github.io/automerge-r/dev/reference/am_save.md)
or `am_save_incremental()`. This is more efficient than saving the
entire document when only a few changes have been made.

## Usage

``` r
am_save_incremental(doc)
```

## Arguments

- doc:

  An Automerge document

## Value

A raw vector containing the incremental changes. May be empty
(zero-length) if no new changes have been made since the last save.

## Details

Use
[`am_load_incremental()`](https://posit-dev.github.io/automerge-r/dev/reference/am_load_incremental.md)
to apply these changes to another document.

## See also

[`am_load_incremental()`](https://posit-dev.github.io/automerge-r/dev/reference/am_load_incremental.md),
[`am_save()`](https://posit-dev.github.io/automerge-r/dev/reference/am_save.md)

## Examples

``` r
doc <- am_create()
doc$key <- "value"
am_commit(doc)

# Save full document
full <- am_save(doc)

# Make more changes
doc$key2 <- "value2"
am_commit(doc)

# Save only the new changes
incremental <- am_save_incremental(doc)
length(incremental) < length(full)  # TRUE (smaller)
#> [1] TRUE

am_close(doc)
```
