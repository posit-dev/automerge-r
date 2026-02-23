#include "automerge.h"

static const R_CallMethodDef CallEntries[] = {
    // Document lifecycle
    {"C_am_close", (DL_FUNC) &C_am_close, 1},
    {"C_am_create", (DL_FUNC) &C_am_create, 1},
    {"C_am_save", (DL_FUNC) &C_am_save, 1},
    {"C_am_load", (DL_FUNC) &C_am_load, 1},
    {"C_am_fork", (DL_FUNC) &C_am_fork, 2},
    {"C_am_merge", (DL_FUNC) &C_am_merge, 2},
    {"C_am_get_actor", (DL_FUNC) &C_am_get_actor, 1},
    {"C_am_get_actor_hex", (DL_FUNC) &C_am_get_actor_hex, 1},
    {"C_am_set_actor", (DL_FUNC) &C_am_set_actor, 2},
    {"C_am_commit", (DL_FUNC) &C_am_commit, 3},
    {"C_am_rollback", (DL_FUNC) &C_am_rollback, 1},
    // Object operations
    {"C_am_put", (DL_FUNC) &C_am_put, 4},
    {"C_am_get", (DL_FUNC) &C_am_get, 3},
    {"C_am_delete", (DL_FUNC) &C_am_delete, 3},
    {"C_am_keys", (DL_FUNC) &C_am_keys, 2},
    {"C_am_length", (DL_FUNC) &C_am_length, 2},
    {"C_am_insert", (DL_FUNC) &C_am_insert, 4},
    {"C_am_text_splice", (DL_FUNC) &C_am_text_splice, 4},
    {"C_am_text_content", (DL_FUNC) &C_am_text_content, 2},
    {"C_am_text_update", (DL_FUNC) &C_am_text_update, 2},
    {"C_am_values", (DL_FUNC) &C_am_values, 2},
    {"C_am_counter_increment", (DL_FUNC) &C_am_counter_increment, 4},
    // Synchronization operations
    {"C_am_sync_state", (DL_FUNC) &C_am_sync_state, 0},
    {"C_am_sync_encode", (DL_FUNC) &C_am_sync_encode, 2},
    {"C_am_sync_decode", (DL_FUNC) &C_am_sync_decode, 3},
    {"C_am_get_heads", (DL_FUNC) &C_am_get_heads, 1},
    {"C_am_get_changes", (DL_FUNC) &C_am_get_changes, 2},
    {"C_am_apply_changes", (DL_FUNC) &C_am_apply_changes, 2},
    // Historical queries
    {"C_am_get_last_local_change", (DL_FUNC) &C_am_get_last_local_change, 1},
    {"C_am_get_change_by_hash", (DL_FUNC) &C_am_get_change_by_hash, 2},
    {"C_am_get_changes_added", (DL_FUNC) &C_am_get_changes_added, 2},
    // Change introspection
    {"C_am_change_hash", (DL_FUNC) &C_am_change_hash, 1},
    {"C_am_change_message", (DL_FUNC) &C_am_change_message, 1},
    {"C_am_change_time", (DL_FUNC) &C_am_change_time, 1},
    {"C_am_change_actor_id", (DL_FUNC) &C_am_change_actor_id, 1},
    {"C_am_change_seq", (DL_FUNC) &C_am_change_seq, 1},
    {"C_am_change_deps", (DL_FUNC) &C_am_change_deps, 1},
    {"C_am_change_from_bytes", (DL_FUNC) &C_am_change_from_bytes, 1},
    {"C_am_change_to_bytes", (DL_FUNC) &C_am_change_to_bytes, 1},
    {"C_am_change_size", (DL_FUNC) &C_am_change_size, 1},
    // Cursor and mark operations
    {"C_am_cursor", (DL_FUNC) &C_am_cursor, 3},
    {"C_am_cursor_position", (DL_FUNC) &C_am_cursor_position, 2},
    {"C_am_mark", (DL_FUNC) &C_am_mark, 6},
    {"C_am_marks", (DL_FUNC) &C_am_marks, 2},
    {"C_am_marks_at", (DL_FUNC) &C_am_marks_at, 3},
    // Cursor serialization
    {"C_am_cursor_to_bytes", (DL_FUNC) &C_am_cursor_to_bytes, 1},
    {"C_am_cursor_from_bytes", (DL_FUNC) &C_am_cursor_from_bytes, 2},
    {"C_am_cursor_to_string", (DL_FUNC) &C_am_cursor_to_string, 1},
    {"C_am_cursor_from_string", (DL_FUNC) &C_am_cursor_from_string, 2},
    {"C_am_cursor_equal", (DL_FUNC) &C_am_cursor_equal, 2},
    // v1.2 Document operations
    {"C_am_clone", (DL_FUNC) &C_am_clone, 1},
    {"C_am_equal", (DL_FUNC) &C_am_equal, 2},
    {"C_am_pending_ops", (DL_FUNC) &C_am_pending_ops, 1},
    {"C_am_commit_empty", (DL_FUNC) &C_am_commit_empty, 3},
    {"C_am_save_incremental", (DL_FUNC) &C_am_save_incremental, 1},
    {"C_am_load_incremental", (DL_FUNC) &C_am_load_incremental, 2},
    // v1.2 Object operations
    {"C_am_map_get_all", (DL_FUNC) &C_am_map_get_all, 4},
    {"C_am_list_get_all", (DL_FUNC) &C_am_list_get_all, 4},
    {"C_am_map_range", (DL_FUNC) &C_am_map_range, 5},
    {"C_am_list_range", (DL_FUNC) &C_am_list_range, 5},
    {"C_am_items", (DL_FUNC) &C_am_items, 3},
    // v1.2 Change/sync operations
    {"C_am_get_missing_deps", (DL_FUNC) &C_am_get_missing_deps, 2},
    {"C_am_load_changes", (DL_FUNC) &C_am_load_changes, 1},
    // v1.2 Mark operations
    {"C_am_mark_clear", (DL_FUNC) &C_am_mark_clear, 5},
    // v1.2 Sync serialization
    {"C_am_sync_state_encode", (DL_FUNC) &C_am_sync_state_encode, 1},
    {"C_am_sync_state_decode", (DL_FUNC) &C_am_sync_state_decode, 1},
    // Helper functions
    {"C_get_doc_from_objid", (DL_FUNC) &C_get_doc_from_objid, 1},
    {NULL, NULL, 0}
};

void R_init_automerge(DllInfo *dll) {
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
    R_forceSymbols(dll, TRUE);
}
