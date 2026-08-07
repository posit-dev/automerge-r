# Load an Automerge document from binary format

Deserializes an Automerge document from the standard binary format. The
binary format is compatible across all Automerge implementations
(JavaScript, Rust, etc.).

## Usage

``` r
am_load(data)
```

## Arguments

- data:

  A raw vector containing a serialized Automerge document

## Value

An external pointer to the Automerge document with class
`c("am_doc", "automerge")`.

## Examples

``` r
# Create, save, and reload
doc1 <- am_create()
bytes <- am_save(doc1)
doc2 <- am_load(bytes)
doc2
#> <Automerge Document>
#> Actor: a6fe9a0461a51afa63798c90789ab44d 
#> Root keys: 0 

# Save to and load from file
doc3 <- am_create()
file <- tempfile()
writeBin(am_save(doc3), file)

doc4 <- am_load(readBin(file, "raw", 1e5))

unlink(file)
am_close(doc1)
am_close(doc2)
am_close(doc3)
am_close(doc4)
```
