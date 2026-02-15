# Create an empty change

Creates a new change in the document's history without any operations.
This is useful for creating merge commits or recording metadata
(message, timestamp) without making data changes.

## Usage

``` r
am_empty_change(doc, message = NULL, time = NULL)
```

## Arguments

- doc:

  An Automerge document

- message:

  Optional commit message (character string)

- time:

  Optional timestamp (POSIXct). If `NULL`, uses current time.

## Value

The document `doc` (invisibly)

## Examples

``` r
doc <- am_create()
doc$key <- "value"
am_commit(doc, "Initial data")

# Create empty change as a checkpoint
am_empty_change(doc, "Checkpoint")

am_close(doc)
```
