# Create a new Automerge document

Creates a new Automerge document with an optional custom actor ID. If no
actor ID is provided, a random one is generated.

## Usage

``` r
am_create(actor_id = NULL)
```

## Arguments

- actor_id:

  Optional actor ID. Can be:

  - `NULL` (default) - Generate random actor ID

  - Character string - Hex-encoded actor ID

  - Raw vector - Binary actor ID bytes

## Value

An external pointer to the Automerge document with class
`c("am_doc", "automerge")`.

## Thread Safety

The automerge package is NOT thread-safe. Do not access the same
document from multiple R threads concurrently. Each thread should create
its own document with `am_create()` and synchronize changes via
`am_sync_*()` functions after thread completion.

## Examples

``` r
# Create document with random actor ID
doc1 <- am_create()
doc1
#> <Automerge Document>
#> Actor: f135be32c2428ccbd4e9cd0d1c6036b9 
#> Root keys: 0 

# Create with custom hex actor ID
doc2 <- am_create("0123456789abcdef0123456789abcdef")

# Create with raw bytes actor ID
actor_bytes <- as.raw(1:16)
doc3 <- am_create(actor_bytes)

am_close(doc1)
am_close(doc2)
am_close(doc3)
```
