# Deserialize a sync state

Restores a sync state from a raw vector previously created by
[`am_sync_state_encode()`](https://posit-dev.github.io/automerge-r/dev/reference/am_sync_state_encode.md).
This allows continuing a sync session from where it left off.

## Usage

``` r
am_sync_state_decode(data)
```

## Arguments

- data:

  A raw vector containing a serialized sync state

## Value

An `am_syncstate` object.

## See also

[`am_sync_state_encode()`](https://posit-dev.github.io/automerge-r/dev/reference/am_sync_state_encode.md),
[`am_sync_state()`](https://posit-dev.github.io/automerge-r/dev/reference/am_sync_state.md)

## Examples

``` r
sync_state <- am_sync_state()
bytes <- am_sync_state_encode(sync_state)

# Restore sync state
restored <- am_sync_state_decode(bytes)
restored
#> <Automerge Sync State>
```
