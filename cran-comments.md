## R CMD check results

0 errors | 0 warnings | 0 notes

The "conditional jump depends on uninitialised value" Valgrind warnings reported for the previous version have now been reproduced (in the CRAN configuration: Fedora 40, Valgrind 3.24) and traced to the bundled Rust 'automerge' crate (in `PatchLog::migrate_actors`), not to the package's own C code. They are resolved by upgrading the bundled crate to 0.10.0, and this version runs cleanly under Valgrind (and additionally under gcc ASAN/UBSAN).