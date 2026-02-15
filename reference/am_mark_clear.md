# Clear marks from a text range

Removes marks matching the given name from a range of text. This is the
inverse of
[`am_mark()`](https://posit-dev.github.io/automerge-r/reference/am_mark.md).

## Usage

``` r
am_mark_clear(obj, start, end, name, expand = AM_MARK_EXPAND_NONE)
```

## Arguments

- obj:

  An Automerge object ID (must be a text object)

- start:

  Integer start position (0-based inter-character position, inclusive)

- end:

  Integer end position (0-based inter-character position, exclusive)

- name:

  Character string identifying the mark to clear (e.g., "bold")

- expand:

  Character string controlling mark clearing behavior at boundaries.
  Options: `"none"` (default), `"before"`, `"after"`, `"both"`. Use the
  constants
  [AM_MARK_EXPAND_NONE](https://posit-dev.github.io/automerge-r/reference/automerge-constants.md),
  [AM_MARK_EXPAND_BEFORE](https://posit-dev.github.io/automerge-r/reference/automerge-constants.md),
  [AM_MARK_EXPAND_AFTER](https://posit-dev.github.io/automerge-r/reference/automerge-constants.md),
  or
  [AM_MARK_EXPAND_BOTH](https://posit-dev.github.io/automerge-r/reference/automerge-constants.md).

## Value

The text object `obj` (invisibly)

## Indexing Convention

Uses the same 0-based inter-character position indexing as
[`am_mark()`](https://posit-dev.github.io/automerge-r/reference/am_mark.md).

## See also

[`am_mark()`](https://posit-dev.github.io/automerge-r/reference/am_mark.md),
[`am_marks()`](https://posit-dev.github.io/automerge-r/reference/am_marks.md)

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "text", am_text("Hello World"))
text_obj <- am_get(doc, AM_ROOT, "text")

# Add a mark
am_mark(text_obj, 0, 11, "bold", TRUE)
length(am_marks(text_obj))  # 1
#> [1] 1

# Clear the mark
am_mark_clear(text_obj, 0, 11, "bold")
length(am_marks(text_obj))  # 0
#> [1] 0

am_close(doc)
```
