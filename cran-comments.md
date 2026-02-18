## R CMD check results

0 errors | 0 warnings | 1 note

New submission
  
Package was archived on CRAN

CRAN repository db overrides:
    X-CRAN-Comment: Archived on 2026-02-18 aw issues were not corrected
      in multiple re-submissions.

This release fixes CRAN issues from the archived package:

1. valgrind - the previous "conditional jump depends on uninitialised value" warnings were false positives caused by a Rust dependency (tinyvec). This dependency has now been removed entirely from the vendored sources, so the warnings can no longer occur.
