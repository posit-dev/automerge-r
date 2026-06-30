# Documents own internal automerge state (e.g. the transaction op HashMap) that
# is only released when am_close() runs. R does not fire external pointer
# finalizers at process exit, so any document still live at the end of the test
# run is reported by Valgrind as "possibly lost" -- the block is reachable, but
# hashbrown keeps an interior pointer so it is not classed as "still reachable".
#
# These local_* helpers wrap the four document constructors and register
# am_close() to run when the calling test_that() block finishes, so every
# document is freed deterministically regardless of garbage collection timing.
# am_close() is idempotent, so an extra explicit close in a test is harmless.
# defer() is the vendored base-R helper from R/import-standalone-defer.R.

local_create <- function(actor_id = NULL, .env = parent.frame()) {
  doc <- am_create(actor_id)
  defer(am_close(doc), envir = .env)
  doc
}

local_load <- function(data, .env = parent.frame()) {
  doc <- am_load(data)
  defer(am_close(doc), envir = .env)
  doc
}

local_fork <- function(doc, heads = NULL, .env = parent.frame()) {
  forked <- am_fork(doc, heads)
  defer(am_close(forked), envir = .env)
  forked
}

local_clone <- function(doc, .env = parent.frame()) {
  cloned <- am_clone(doc)
  defer(am_close(cloned), envir = .env)
  cloned
}
