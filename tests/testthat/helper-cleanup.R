# Documents own internal automerge state (e.g. the transaction op HashMap) that
# is only released when am_close() runs. R does not fire external pointer
# finalizers at process exit, so any document still live at the end of the test
# run is reported by Valgrind as "possibly lost" -- the block is reachable, but
# hashbrown keeps an interior pointer so it is not classed as "still reachable".
#
# Shadowing the four document constructors registers am_close() to run when the
# calling test_that() block finishes, so every document is freed deterministically
# regardless of garbage collection timing. am_close() is idempotent, so an extra
# explicit close in a test is harmless. defer() is the vendored base-R helper
# from R/import-standalone-defer.R.

am_create <- function(actor_id = NULL, .env = parent.frame()) {
  doc <- automerge::am_create(actor_id)
  defer(automerge::am_close(doc), envir = .env)
  doc
}

am_load <- function(data, .env = parent.frame()) {
  doc <- automerge::am_load(data)
  defer(automerge::am_close(doc), envir = .env)
  doc
}

am_fork <- function(doc, heads = NULL, .env = parent.frame()) {
  forked <- automerge::am_fork(doc, heads)
  defer(automerge::am_close(forked), envir = .env)
  forked
}

am_clone <- function(doc, .env = parent.frame()) {
  cloned <- automerge::am_clone(doc)
  defer(automerge::am_close(cloned), envir = .env)
  cloned
}
