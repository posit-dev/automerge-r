# Update text content

An optimized function for collaborative editing that reads the current
text content from the document, computes the minimal diff against the
new text, and applies it directly. This avoids intermediate R object
allocation, making it more efficient than separate diff computation and
splice operations.

## Usage

``` r
am_text_update(text_obj, new_text)
```

## Arguments

- text_obj:

  An Automerge text object ID

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
text_obj
#> <Automerge Text>
#> Length: 5 characters
#> Content: "Hello" 

# Efficiently update text by computing and applying diff in one step
am_text_update(text_obj, "Hello World")
am_text_content(text_obj)  # "Hello World"
#> [1] "Hello World"

# Works with Unicode
am_text_update(text_obj, "Hello World!")
am_text_content(text_obj)  # "Hello World!"
#> [1] "Hello World!"

am_close(doc)
```
