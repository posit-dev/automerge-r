# Load a document as individual changes

Decomposes a serialized document into its individual changes. This is
useful for inspecting the full change history or for selectively
applying changes to another document.

## Usage

``` r
am_load_changes(data)
```

## Arguments

- data:

  A raw vector containing a serialized Automerge document (from
  [`am_save()`](https://posit-dev.github.io/automerge-r/reference/am_save.md))

## Value

A list of `am_change` objects. Returns an empty list for an empty
document.

## Examples

``` r
doc <- am_create()
doc$key <- "value"
am_commit(doc, "Add key")
doc$key2 <- "value2"
am_commit(doc, "Add key2")
bytes <- am_save(doc)

# Load as individual changes
changes <- am_load_changes(bytes)
changes
#> [[1]]
#> <Automerge Change>
#> Hash: ae c4 0e bc ...
#> Message: Add key 
#> 
#> [[2]]
#> <Automerge Change>
#> Hash: 0a 4b 70 bc ...
#> Message: Add key2 
#> 
am_change_message(changes[[1]])  # "Add key"
#> [1] "Add key"
am_change_message(changes[[2]])  # "Add key2"
#> [1] "Add key2"

# Apply to a new document
doc2 <- am_create()
am_apply_changes(doc2, changes)
doc2$key   # "value"
#> [1] "value"
doc2$key2  # "value2"
#> [1] "value2"

am_close(doc)
am_close(doc2)
```
