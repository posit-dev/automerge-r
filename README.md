
<!-- README.md is generated from README.Rmd. Please edit that file -->

# automerge

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/automerge)](https://CRAN.R-project.org/package=automerge)
[![R-CMD-check](https://github.com/posit-dev/automerge-r/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/posit-dev/automerge-r/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/posit-dev/automerge-r/graph/badge.svg)](https://app.codecov.io/gh/posit-dev/automerge-r)
<!-- badges: end -->

Conflict-free data synchronization for R

[![Ask
DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/posit-dev/automerge-r)

`automerge` brings [Automerge](https://automerge.org/) CRDTs
(Conflict-free Replicated Data Types) to R, enabling automatic merging
of concurrent changes across distributed systems without conflicts. Work
offline, collaborate in real-time, or sync across platforms—changes
merge automatically.

## Why Automerge?

Traditional approaches to distributed data either require a central
server to coordinate changes or force developers to write complex
conflict resolution logic. Automerge’s CRDT technology automatically
merges concurrent changes with mathematical guarantees, eliminating the
need for coordination and making distributed systems dramatically
simpler.

## Quick Example

``` r
library(automerge)

# Two researchers working independently
alice <- am_create()
alice$experiment <- "trial_001"
alice$temperature <- 23.5
am_commit(alice, "Alice's data")

bob <- am_create()
bob$experiment <- "trial_002"
bob$humidity <- 65
am_commit(bob, "Bob's data")

# Later, sync with zero conflicts
am_sync(alice, bob)
alice
#> <Automerge Document>
#> Actor: 430ffacff3ae9ece2c50d476120588d1 
#> Root keys: 3 
#> Keys: experiment, humidity, temperature
bob
#> <Automerge Document>
#> Actor: abb94fd55ba7c10623aa19f30ae871b1 
#> Root keys: 3 
#> Keys: experiment, humidity, temperature
```

## Key Features

- **Familiar R syntax**: Work with CRDT documents like regular R lists
- **Rich data types**: Maps, lists, text objects, counters, and
  timestamps
- **Collaborative text editing**: Cursors and marks for rich text
  applications
- **Bidirectional sync**: High-level `am_sync()` or low-level protocol
  access
- **Offline-first**: Make changes offline, merge when connected
- **Cross-platform**: Interoperates with JavaScript and other Automerge
  implementations
- **Zero dependencies**: Only base R required at runtime

## Installation

``` r
install.packages("automerge")
```

Building from source requires Rust \>= 1.85
([rustup.rs](https://rustup.rs/)) and CMake \>= 3.25 (included in
Rtools43+ on Windows).

## Documentation

- [Getting
  Started](https://posit-dev.github.io/automerge-r/articles/automerge.html):
  Introduction and basic usage
- [Quick
  Reference](https://posit-dev.github.io/automerge-r/articles/quick-reference.html):
  Function reference organized by task
- [CRDT
  Concepts](https://posit-dev.github.io/automerge-r/articles/crdt-concepts.html):
  Understanding conflict-free data types
- [Sync
  Protocol](https://posit-dev.github.io/automerge-r/articles/sync-protocol.html):
  Low-level synchronization details
- [Cross-Platform
  Synchronization](https://posit-dev.github.io/automerge-r/articles/cross-platform.html):
  Interoperability with JavaScript and other platforms
- [Function
  Reference](https://posit-dev.github.io/automerge-r/reference/index.html):
  Complete API documentation

## External Resources

- [Automerge Website](https://automerge.org/) - Official Automerge
  documentation and guides
- [Automerge GitHub](https://github.com/automerge/automerge) - Automerge
  source code
- [Local-first software](https://www.inkandswitch.com/local-first/) -
  The philosophy behind Automerge

## Related Projects

- [autosync](https://shikokuchuo.net/autosync/) - automerge-repo
  compatible R sync server
- [autoedit](https://shikokuchuo.net/autoedit/) - Collaborative code
  editor widget for R and Shiny

## License

MIT License. See [LICENSE](LICENSE) for details. This package includes
the [automerge-c](https://github.com/automerge/automerge) library (also
MIT licensed)
