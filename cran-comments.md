## R CMD check results

0 errors | 0 warnings | 0 notes

This patch release fixes all current CRAN issues from the new package submission:

1. Failure to install on MacOS x64 platforms - due to minimum Rust version requirements from vendored dependencies. We've eliminated some troublesome dependencies, which also substantially reduces the source tarball size.

2. rchk unprotected variables - these have been fixed.

3. valgrind - these seem to be false positives from the use of Rust code (zero memory definitely or indirectly lost), but I've refactored and should no longer trigger these warnings.
