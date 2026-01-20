# Compute diff and splice text in one operation

An optimized function for collaborative editing that computes the
minimal diff between old and new text and applies it directly to the
text object. This avoids intermediate R object allocation, making it
more efficient than separate diff computation and splice operations.

## Usage

``` r
am_text_splice_diff(text_obj, old_text, new_text)
```

## Arguments

- text_obj:

  An Automerge text object ID

- old_text:

  The previous text content (single string)

- new_text:

  The new text content (single string)

## Value

Invisible NULL (called for side effect)

## Details

Positions use Unicode code points (matching R's
[`nchar()`](https://rdrr.io/r/base/nchar.html) behavior), not bytes.
This means multibyte characters like emoji count as single characters.

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "content", am_text("Hello"))
text_obj <- am_get(doc, AM_ROOT, "content")

# Efficiently update text by computing and applying diff in one step
am_text_splice_diff(text_obj, "Hello", "Hello World")
am_text_get(text_obj)  # "Hello World"
#> [1] "Hello World"

# Works with Unicode
am_text_splice_diff(text_obj, "Hello World", "Hello World!")
am_text_get(text_obj)  # "Hello World!"
#> [1] "Hello World!"
```
