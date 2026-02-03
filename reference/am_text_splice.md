# Splice text in a text object

Insert or delete characters in a text object. This is the primary way to
edit text CRDT objects.

## Usage

``` r
am_text_splice(text_obj, pos, del_count, text)
```

## Arguments

- text_obj:

  An Automerge text object ID

- pos:

  Character position to start splice (0-based inter-character position)

- del_count:

  Number of characters to delete (counts Unicode code points)

- text:

  Text to insert

## Value

The text object `text_obj` (invisibly)

## Indexing Convention

**Text positions use 0-based indexing** (unlike list indices which are
1-based). This is because positions specify locations **between**
characters, not the characters themselves:

- Position 0 = before the first character

- Position 1 = between 1st and 2nd characters

- Position 5 = after the 5th character

For the text "Hello":

      H e l l o
     0 1 2 3 4 5  <- positions (0-based, between characters)

Positions count Unicode code points (characters), not bytes. The word
"Français" counts as 8 characters, matching R's
[`nchar()`](https://rdrr.io/r/base/nchar.html) behavior.

## Examples

``` r
doc <- am_create()
am_put(doc, AM_ROOT, "doc", am_text("Hello"))
text_obj <- am_get(doc, AM_ROOT, "doc")

# Insert " World" at position 5 (after "Hello")
am_text_splice(text_obj, 5, 0, " World")

# Get the full text
am_text_content(text_obj)  # "Hello World"
#> [1] "Hello World"

# Works naturally with multibyte characters
am_put(doc, AM_ROOT, "greet", am_text(""))
text_obj2 <- am_get(doc, AM_ROOT, "greet")
am_text_splice(text_obj2, 0, 0, "Column café")
# Position 11 is after "café" (character index, not bytes)
am_text_splice(text_obj2, 11, 0, "!")
am_text_content(text_obj2)  # "Column café!"
#> [1] "Column café!"
am_close(doc)
```
