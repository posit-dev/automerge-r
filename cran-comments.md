## R CMD check results

0 errors | 0 warnings | 0 notes

This release fixes all current CRAN issues:

1. valgrind - the "conditional jump depends on uninitialised value" warning is a false positive (zero memory definitely or indirectly lost). It is caused by the compiler reading struct padding bytes during inlined comparisons. We have patched the vendored sources to use manual comparison methods that avoid reading padding, which should eliminate the warnings.
