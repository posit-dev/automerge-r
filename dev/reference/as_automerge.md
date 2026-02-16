# Convert R list to Automerge document

Converts an R list to an Automerge document. This leverages the
recursive conversion built into
[`am_put()`](https://posit-dev.github.io/automerge-r/dev/reference/am_put.md)
from Phase 3, allowing nested structures to be created in a single call.

## Usage

``` r
as_automerge(x, doc = NULL, actor_id = NULL)
```

## Arguments

- x:

  R list, vector, or scalar value to convert

- doc:

  Optional existing Automerge document. If NULL, creates a new one.

- actor_id:

  Optional actor ID for new documents (raw bytes or hex string)

## Value

An Automerge document

## Examples

``` r
# Convert nested list to Automerge
data <- list(
  name = "Alice",
  age = 30L,
  scores = list(85, 90, 95),
  metadata = list(
    created = Sys.time(),
    tags = list("user", "active")
  )
)

doc <- as_automerge(data)
doc
#> <Automerge Document>
#> Actor: 51de16ae7b03dc64d6bff34e755c7851 
#> Root keys: 4 
#> Keys: age, metadata, name, scores 
doc[["name"]]  # "Alice"
#> [1] "Alice"
doc[["age"]]   # 30L
#> [1] 30

am_close(doc)
```
