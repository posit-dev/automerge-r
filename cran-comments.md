## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new submission.


Re-submission addresses the following comments:

Please always write package names, software names and API (application
programming interface) names in single quotes in title and description.
e.g: --> 'JavaScript'

Added single quotes.

If there are references describing the methods in your package, please
add these in the description field of your DESCRIPTION file in the form
authors (year) <doi:...>
authors (year, ISBN:...)
or if those are not available: <https:...>
with no space after 'doi:', 'https:' and angle brackets for
auto-linking. 

Added a reference with DOI in DESCRIPTION.

Some code lines in examples are commented out. Please never do that.
Ideally find toy examples that can be regularly executed and checked.
Lengthy examples (> 5 sec), can be wrapped in \donttest{}.
Examples in comments in:
       am_sync_decode.Rd

Examples amended and taken out of \dontrun{}
