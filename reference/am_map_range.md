# Get a range of map items by key

Returns map entries whose keys fall within the lexicographic range
`[begin, end)`.

## Usage

``` r
am_map_range(doc, obj, begin = "", end = "", heads = NULL)
```

## Arguments

- doc:

  An Automerge document

- obj:

  An Automerge object ID (must be a map), or `AM_ROOT`

- begin:

  Start key (inclusive).

- end:

  End key (exclusive).

- heads:

  Optional list of change hashes (raw vectors) for historical query. If
  `NULL` (default), uses the current state.

## Value

A named list of values in the key range.

## Examples

``` r
doc <- am_create()
doc$a <- 1
doc$b <- 2
doc$c <- 3
doc$d <- 4

# Get entries with keys in [b, d) -> b and c
range <- am_map_range(doc, AM_ROOT, "b", "d")
names(range)  # "b" "c"
#> [1] "b" "c"

# Get all entries
all <- am_map_range(doc, AM_ROOT, "", "")

am_close(doc)
```
