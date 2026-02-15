# Serialize a sync state

Encodes a sync state to a raw vector for persistence or transmission.
The encoded state can later be restored with
[`am_sync_state_decode()`](https://posit-dev.github.io/automerge-r/reference/am_sync_state_decode.md).

## Usage

``` r
am_sync_state_encode(sync_state)
```

## Arguments

- sync_state:

  A sync state object (created with
  [`am_sync_state()`](https://posit-dev.github.io/automerge-r/reference/am_sync_state.md))

## Value

A raw vector containing the serialized sync state.

## Details

This is useful for persisting sync progress across sessions, avoiding
the need to re-sync from scratch.

## See also

[`am_sync_state_decode()`](https://posit-dev.github.io/automerge-r/reference/am_sync_state_decode.md),
[`am_sync_state()`](https://posit-dev.github.io/automerge-r/reference/am_sync_state.md)

## Examples

``` r
sync_state <- am_sync_state()

# Encode for storage
bytes <- am_sync_state_encode(sync_state)
bytes
#> [1] 43 00

# Restore later
restored <- am_sync_state_decode(bytes)
restored
#> <Automerge Sync State>
```
