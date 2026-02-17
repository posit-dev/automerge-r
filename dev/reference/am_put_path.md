# Set value at path

Set a value in an Automerge document using a path vector. Can optionally
create intermediate objects automatically.

## Usage

``` r
am_put_path(doc, path, value, create_intermediate = TRUE)
```

## Arguments

- doc:

  An Automerge document

- path:

  Character vector, numeric vector, or list of mixed types specifying
  the path to navigate

- value:

  The value to store. Supported types:

  - `NULL` - stores null

  - Logical - stores boolean (must be scalar)

  - Integer - stores integer (must be scalar)

  - Numeric - stores double (must be scalar)

  - Character - stores string (must be scalar)

  - Raw - stores bytes

  - `AM_OBJ_TYPE_LIST/MAP/TEXT` - creates nested object

- create_intermediate:

  Logical. If TRUE, creates intermediate maps as needed. Default TRUE.

## Value

The document (invisibly)

## Examples

``` r
doc <- am_create()

# Create nested structure with automatic intermediate objects
am_put_path(doc, c("user", "address", "city"), "Boston")
am_put_path(doc, c("user", "address", "zip"), 02101L)
am_put_path(doc, c("user", "name"), "Alice")

# Verify
am_get_path(doc, c("user", "address", "city"))  # "Boston"
#> [1] "Boston"

am_close(doc)
```
