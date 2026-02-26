## R CMD check results

0 errors | 0 warnings | 0 notes

The previous version had some residual "conditional jump depends on uninitialised value" Valgrind warnings. Apologies for this - I thought I had fixed them all, but unfortunately I am unable to reproduce these myself. Again, these are false positives as Valgrind does not know about the extra safeguards that Rust has - there is zero memory lost. In case there continue to be issues, I request a dispensation, otherwise I shall be forced to take this off CRAN. Thanks.