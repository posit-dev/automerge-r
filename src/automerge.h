#ifndef R_AUTOMERGE_H
#define R_AUTOMERGE_H

#ifndef R_NO_REMAP
#define R_NO_REMAP
#endif
#ifndef STRICT_R_HEADERS
#define STRICT_R_HEADERS
#endif
#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>
#include <string.h>  // For memcpy, strlen
#include <stdbool.h> // For bool type
#include <automerge-c/automerge.h>

// Protect against malicious input causing stack overflow
#define MAX_ERROR_MSG_SIZE 8192

// Memory Management Structures ------------------------------------------------

// Document wrapper
// Stores the owning AMresult* and the borrowed AMdoc* pointer.
// The AMdoc* is extracted from the result and is valid as long as the result lives.
typedef struct {
    AMresult *result;  // Owns the document (freed in finalizer)
    AMdoc *doc;        // Borrowed pointer extracted from result
} am_doc;

// Sync state wrapper (owns AMresult, state pointer is borrowed)
typedef struct {
    AMresult *result;       // Owns the sync state (must be freed by finalizer)
    AMsyncState *state;     // Borrowed pointer extracted from result
} am_syncstate;

// Change wrapper (owned changes only)
// Stores the owning AMresult* and the borrowed AMchange* pointer.
// Borrowed changes store AMchange* directly in the ext_ptr (no struct).
typedef struct {
    AMresult *result;   // Owns the change (freed in finalizer)
    AMchange *change;   // Borrowed pointer extracted from result
} am_change_data;

// Function Declarations -------------------------------------------------------

// Document operations (document.c)
SEXP C_am_close(SEXP doc_ptr);
SEXP C_am_create(SEXP actor_id);
SEXP C_am_save(SEXP doc_ptr);
SEXP C_am_load(SEXP data);
SEXP C_am_fork(SEXP doc_ptr, SEXP heads);
SEXP C_am_merge(SEXP doc_ptr, SEXP other_ptr);
SEXP C_am_get_actor(SEXP doc_ptr);
SEXP C_am_get_actor_hex(SEXP doc_ptr);
SEXP C_am_set_actor(SEXP doc_ptr, SEXP actor_id);
SEXP C_am_commit(SEXP doc_ptr, SEXP message, SEXP time);
SEXP C_am_rollback(SEXP doc_ptr);
SEXP C_am_get_last_local_change(SEXP doc_ptr);
SEXP C_am_get_change_by_hash(SEXP doc_ptr, SEXP hash);
SEXP C_am_get_changes_added(SEXP doc1_ptr, SEXP doc2_ptr);
// Change introspection (changes.c)
SEXP C_am_change_hash(SEXP change);
SEXP C_am_change_message(SEXP change);
SEXP C_am_change_time(SEXP change);
SEXP C_am_change_actor_id(SEXP change);
SEXP C_am_change_seq(SEXP change);
SEXP C_am_change_deps(SEXP change);
SEXP C_am_change_from_bytes(SEXP bytes);
SEXP C_am_change_to_bytes(SEXP change);
SEXP C_am_change_size(SEXP change);

// v1.2 Document operations (document.c)
SEXP C_am_clone(SEXP doc_ptr);
SEXP C_am_equal(SEXP doc1_ptr, SEXP doc2_ptr);
SEXP C_am_pending_ops(SEXP doc_ptr);
SEXP C_am_commit_empty(SEXP doc_ptr, SEXP message, SEXP time);
SEXP C_am_save_incremental(SEXP doc_ptr);
SEXP C_am_load_incremental(SEXP doc_ptr, SEXP data);

// Shared helpers
AMresult* convert_r_heads_to_amresult(SEXP heads_list, AMresult ***results_out, size_t *n_results);
AMitems* resolve_heads(SEXP heads, AMitems *heads_items_out, AMresult **heads_result_out);

// Object operations (objects.c)
SEXP C_am_put(SEXP doc_ptr, SEXP obj_ptr, SEXP key_or_pos, SEXP value);
SEXP C_am_get(SEXP doc_ptr, SEXP obj_ptr, SEXP key_or_pos);
SEXP C_am_delete(SEXP doc_ptr, SEXP obj_ptr, SEXP key_or_pos);
SEXP C_am_keys(SEXP doc_ptr, SEXP obj_ptr);
SEXP C_am_length(SEXP doc_ptr, SEXP obj_ptr);
SEXP C_am_insert(SEXP doc_ptr, SEXP obj_ptr, SEXP pos, SEXP value);
SEXP C_am_text_splice(SEXP text_ptr, SEXP pos, SEXP del_count, SEXP text);
SEXP C_am_text_content(SEXP text_ptr);
SEXP C_am_text_update(SEXP text_ptr, SEXP old_str, SEXP new_str);
SEXP C_am_values(SEXP doc_ptr, SEXP obj_ptr);
SEXP C_am_counter_increment(SEXP doc_ptr, SEXP obj_ptr, SEXP key_or_pos, SEXP delta);
// v1.2 Object operations (objects.c)
SEXP C_am_map_get_all(SEXP doc_ptr, SEXP obj_ptr, SEXP key, SEXP heads);
SEXP C_am_list_get_all(SEXP doc_ptr, SEXP obj_ptr, SEXP pos, SEXP heads);
SEXP C_am_map_range(SEXP doc_ptr, SEXP obj_ptr, SEXP begin, SEXP end, SEXP heads);
SEXP C_am_list_range(SEXP doc_ptr, SEXP obj_ptr, SEXP begin, SEXP end, SEXP heads);
SEXP C_am_items(SEXP doc_ptr, SEXP obj_ptr, SEXP heads);

// Synchronization operations (sync.c)
SEXP C_am_sync_state(void);
SEXP C_am_sync_encode(SEXP doc_ptr, SEXP sync_state_ptr);
SEXP C_am_sync_decode(SEXP doc_ptr, SEXP sync_state_ptr, SEXP message);
SEXP C_am_get_heads(SEXP doc_ptr);
SEXP C_am_get_changes(SEXP doc_ptr, SEXP heads);
SEXP C_am_apply_changes(SEXP doc_ptr, SEXP changes);
// v1.2 Sync/change operations (sync.c, changes.c)
SEXP C_am_get_missing_deps(SEXP doc_ptr, SEXP heads);
SEXP C_am_load_changes(SEXP data);
SEXP C_am_sync_state_encode(SEXP sync_state_ptr);
SEXP C_am_sync_state_decode(SEXP data);

// Cursor and mark operations (cursors.c)
SEXP C_am_cursor(SEXP obj_ptr, SEXP position, SEXP heads);
SEXP C_am_cursor_position(SEXP cursor_ptr, SEXP heads);
SEXP C_am_mark(SEXP obj_ptr, SEXP start, SEXP end, SEXP name, SEXP value, SEXP expand);
SEXP C_am_marks(SEXP obj_ptr, SEXP heads);
SEXP C_am_marks_at(SEXP obj_ptr, SEXP position, SEXP heads);
SEXP C_am_cursor_to_bytes(SEXP cursor_ptr);
SEXP C_am_cursor_from_bytes(SEXP bytes, SEXP obj_ptr);
SEXP C_am_cursor_to_string(SEXP cursor_ptr);
SEXP C_am_cursor_from_string(SEXP str, SEXP obj_ptr);
SEXP C_am_cursor_equal(SEXP cursor1_ptr, SEXP cursor2_ptr);
// v1.2 Mark operations (cursors.c)
SEXP C_am_mark_clear(SEXP obj_ptr, SEXP start, SEXP end, SEXP name, SEXP expand);

// Finalizers (memory.c)
void am_doc_finalizer(SEXP ext_ptr);
void am_result_finalizer(SEXP ext_ptr);
void am_syncstate_finalizer(SEXP ext_ptr);
void am_change_finalizer(SEXP ext_ptr);

// Change wrapping helpers (changes.c)
SEXP wrap_am_change_owned(AMresult *result);
SEXP wrap_am_change_borrowed(AMchange *ch, SEXP parent_result_ptr);
AMchange *get_change(SEXP change_ptr);

// Helper functions (memory.c)
AMdoc *get_doc(SEXP doc_ptr);
AMsyncState *get_syncstate(SEXP sync_state_ptr);
const AMobjId *get_objid(SEXP obj_ptr);
SEXP get_doc_from_objid(SEXP obj_ptr);  // Extract doc from am_object protection chain
SEXP C_get_doc_from_objid(SEXP obj_ptr);  // Exported for R .Call() interface
SEXP wrap_am_result(AMresult *result, SEXP parent_doc_sexp);
SEXP am_wrap_objid(const AMobjId *obj_id, SEXP parent_result_sexp);
SEXP am_wrap_nested_object(const AMobjId *obj_id, SEXP parent_result_sexp);

// Error handling (errors.c)
void check_result_impl(AMresult *result, AMvalType expected_type,
                       const char *file, int line);

/**
 * CHECK_RESULT macro - validates AMresult and expected type.
 * Calls Rf_error() on failure (does not return).
 *
 * Usage:
 *   AMresult* result = AMmapPutStr(doc, obj_id, key, value);
 *   CHECK_RESULT(result, AM_VAL_TYPE_VOID);
 *
 * IMPORTANT: This macro calls AMresultFree(result) on error, so the result
 * is consumed. Do not use the result after calling CHECK_RESULT on error paths.
 */
#define CHECK_RESULT(result, expected_type) \
    check_result_impl((result), (expected_type), __FILE__, __LINE__)

#endif // R_AUTOMERGE_H
