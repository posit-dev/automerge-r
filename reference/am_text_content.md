# Get text content from a text object

Retrieve the full text content from a text object as a string.

## Usage

``` r
am_text_content(text_obj, heads = NULL)
```

## Arguments

- text_obj:

  An Automerge text object ID

- heads:

  Optional list of change hashes (raw vectors) for historical query. If
  `NULL` (default), uses the current state.

## Value

Character string with the full text

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "doc", am_text("Hello"))
text_obj <- am_get(doc, AM_ROOT, "doc")
text_obj
#> <Automerge Text>
#> Length: 5 characters
#> Content: "Hello" 

text <- am_text_content(text_obj)
text  # "Hello"
#> [1] "Hello"

am_close(doc)
```
