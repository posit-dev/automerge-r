#include "automerge.h"

// Synchronization Functions ------------------------------------------------

/**
 * Create a new sync state for managing synchronization with a peer.
 *
 * IMPORTANT: Sync state is document-independent. The document is passed
 * separately to am_sync_encode() and am_sync_decode() at call time.
 *
 * @return External pointer to am_syncstate structure (with class "am_syncstate")
 */
SEXP C_am_sync_state(void) {
    AMresult *result = AMsyncStateInit();
    CHECK_RESULT(result, AM_VAL_TYPE_SYNC_STATE);

    AMitem *item = AMresultItem(result);
    AMsyncState *state = NULL;
    AMitemToSyncState(item, &state);

    am_syncstate *state_wrapper = malloc(sizeof(am_syncstate));
    if (!state_wrapper) {
        AMresultFree(result);
        Rf_error("Failed to allocate memory for sync state wrapper");
    }
    state_wrapper->result = result;  // Owning result
    state_wrapper->state = state;    // Borrowed from result

    // No parent to protect - sync state is document-independent
    SEXP ext_ptr = PROTECT(R_MakeExternalPtr(state_wrapper, R_NilValue, R_NilValue));
    R_RegisterCFinalizer(ext_ptr, am_syncstate_finalizer);

    Rf_classgets(ext_ptr, Rf_mkString("am_syncstate"));

    UNPROTECT(1);
    return ext_ptr;
}

/**
 * Generate a sync message to send to a peer.
 *
 * Wraps AMgenerateSyncMessage(doc, sync_state).
 *
 * @param doc_ptr External pointer to am_doc
 * @param sync_state_ptr External pointer to am_syncstate
 * @return Raw vector containing sync message, or NULL if no message to send
 */
SEXP C_am_sync_encode(SEXP doc_ptr, SEXP sync_state_ptr) {
    AMdoc *doc = get_doc(doc_ptr);

    AMsyncState *state = get_syncstate(sync_state_ptr);

    AMresult *result = AMgenerateSyncMessage(doc, state);
    CHECK_RESULT(result, AM_VAL_TYPE_VOID);

    AMitem *item = AMresultItem(result);
    if (!item) {
        AMresultFree(result);
        Rf_error("AMgenerateSyncMessage returned NULL item");
    }

    AMvalType type = AMitemValType(item);

    if (type == AM_VAL_TYPE_VOID) {
        // No message to send - sync complete
        AMresultFree(result);
        return R_NilValue;
    }

    if (type != AM_VAL_TYPE_SYNC_MESSAGE) {
        AMresultFree(result);
        Rf_error("Unexpected result type from AMgenerateSyncMessage: %d", type);
    }

    AMsyncMessage const *msg = NULL;
    AMitemToSyncMessage(item, &msg);

    AMresult *encode_result = AMsyncMessageEncode(msg);
    CHECK_RESULT(encode_result, AM_VAL_TYPE_BYTES);

    AMitem *encode_item = AMresultItem(encode_result);
    AMbyteSpan bytes;
    AMitemToBytes(encode_item, &bytes);

    SEXP r_bytes = PROTECT(Rf_allocVector(RAWSXP, bytes.count));
    memcpy(RAW(r_bytes), bytes.src, bytes.count);

    AMresultFree(encode_result);
    AMresultFree(result);
    UNPROTECT(1);
    return r_bytes;
}

/**
 * Receive and apply a sync message from a peer.
 *
 * Wraps AMreceiveSyncMessage(doc, sync_state, message).
 *
 * @param doc_ptr External pointer to am_doc
 * @param sync_state_ptr External pointer to am_syncstate
 * @param message Raw vector containing encoded sync message
 * @return The document pointer (invisibly, for chaining)
 */
SEXP C_am_sync_decode(SEXP doc_ptr, SEXP sync_state_ptr, SEXP message) {
    AMdoc *doc = get_doc(doc_ptr);

    AMsyncState *state = get_syncstate(sync_state_ptr);

    if (TYPEOF(message) != RAWSXP) {
        Rf_error("message must be a raw vector");
    }

    AMresult *decode_result = AMsyncMessageDecode(RAW(message), (size_t) XLENGTH(message));
    CHECK_RESULT(decode_result, AM_VAL_TYPE_SYNC_MESSAGE);

    AMitem *decode_item = AMresultItem(decode_result);
    AMsyncMessage const *msg = NULL;
    AMitemToSyncMessage(decode_item, &msg);

    AMresult *result = AMreceiveSyncMessage(doc, state, msg);
    CHECK_RESULT(result, AM_VAL_TYPE_VOID);

    AMresultFree(result);
    AMresultFree(decode_result);
    return doc_ptr;
}

// Change Tracking and History Functions -------------------------------------

/**
 * Get the current heads (latest change hashes) of a document.
 *
 * Wraps AMgetHeads(doc).
 *
 * @param doc_ptr External pointer to am_doc
 * @return List of raw vectors (change hashes)
 */
SEXP C_am_get_heads(SEXP doc_ptr) {
    AMdoc *doc = get_doc(doc_ptr);

    AMresult *result = AMgetHeads(doc);

    if (AMresultStatus(result) != AM_STATUS_OK) {
        CHECK_RESULT(result, AM_VAL_TYPE_CHANGE_HASH);
    }

    AMitems items = AMresultItems(result);
    size_t count = AMitemsSize(&items);

    if (count == 0) {
        AMresultFree(result);
        return Rf_allocVector(VECSXP, 0);
    }

    SEXP heads_list = PROTECT(Rf_allocVector(VECSXP, count));

    for (size_t i = 0; i < count; i++) {
        AMitem *item = AMitemsNext(&items, 1);
        if (!item) break;

        AMbyteSpan hash;
        AMitemToChangeHash(item, &hash);

        SEXP r_hash = Rf_allocVector(RAWSXP, hash.count);
        memcpy(RAW(r_hash), hash.src, hash.count);
        SET_VECTOR_ELT(heads_list, i, r_hash);
    }

    AMresultFree(result);
    UNPROTECT(1);
    return heads_list;
}

/**
 * Get changes since specified heads (or all changes if heads is NULL).
 *
 * Wraps AMgetChanges(doc, heads).
 *
 * @param doc_ptr External pointer to am_doc
 * @param heads List of raw vectors (change hashes), or NULL for all changes
 * @return List of am_change objects
 */
SEXP C_am_get_changes(SEXP doc_ptr, SEXP heads) {
    AMdoc *doc = get_doc(doc_ptr);

    AMresult *result = NULL;

    if (heads == R_NilValue) {
        result = AMgetChanges(doc, NULL);
    } else {
        AMresult **head_results = NULL;
        size_t n_head_results = 0;
        AMresult *heads_result = convert_r_heads_to_amresult(heads, &head_results, &n_head_results);
        if (n_head_results == 0) {
            result = AMgetChanges(doc, NULL);
        } else if (n_head_results == 1) {
            AMitems heads_items = AMresultItems(heads_result);
            result = AMgetChanges(doc, &heads_items);
            AMresultFree(heads_result);
            free(head_results);
        } else {
            for (size_t i = 0; i < n_head_results; i++) {
                AMresultFree(head_results[i]);
            }
            free(head_results);
            Rf_error("multiple heads are not supported; commit first to produce a single head");
        }
    }

    if (AMresultStatus(result) != AM_STATUS_OK) {
        CHECK_RESULT(result, AM_VAL_TYPE_CHANGE);
    }

    AMitems items = AMresultItems(result);
    size_t count = AMitemsSize(&items);

    if (count == 0) {
        AMresultFree(result);
        return Rf_allocVector(VECSXP, 0);
    }

    // Wrap the AMresult as a parent ext_ptr to keep it alive
    SEXP parent_ptr = PROTECT(R_MakeExternalPtr(result, R_NilValue, R_NilValue));
    R_RegisterCFinalizer(parent_ptr, am_result_finalizer);

    SEXP changes_list = PROTECT(Rf_allocVector(VECSXP, count));

    for (size_t i = 0; i < count; i++) {
        AMitem *item = AMitemsNext(&items, 1);
        if (!item) break;

        AMchange *change = NULL;
        AMitemToChange(item, &change);

        SEXP change_sexp = PROTECT(wrap_am_change_borrowed(change, parent_ptr));
        SET_VECTOR_ELT(changes_list, i, change_sexp);
        UNPROTECT(1);
    }

    UNPROTECT(2);
    return changes_list;
}

/**
 * Apply changes from another peer to this document.
 *
 * Uses AMloadIncremental() to apply each change.
 *
 * @param doc_ptr External pointer to am_doc
 * @param changes List of am_change objects
 * @return The document pointer (invisibly, for chaining)
 */
SEXP C_am_apply_changes(SEXP doc_ptr, SEXP changes) {
    AMdoc *doc = get_doc(doc_ptr);

    if (TYPEOF(changes) != VECSXP) {
        Rf_error("changes must be a list");
    }

    R_xlen_t n_changes = XLENGTH(changes);
    if (n_changes == 0) {
        return doc_ptr;
    }

    for (R_xlen_t i = 0; i < n_changes; i++) {
        SEXP element = VECTOR_ELT(changes, i);
        AMchange *change = get_change(element);

        AMbyteSpan span = AMchangeRawBytes(change);

        AMresult *result = AMloadIncremental(doc, span.src, span.count);

        if (AMresultStatus(result) != AM_STATUS_OK) {
            AMbyteSpan error_span = AMresultError(result);
            size_t msg_size = error_span.count < MAX_ERROR_MSG_SIZE ?
                              error_span.count : MAX_ERROR_MSG_SIZE;
            char error_msg[MAX_ERROR_MSG_SIZE + 1];
            memcpy(error_msg, error_span.src, msg_size);
            error_msg[msg_size] = '\0';

            AMresultFree(result);
            Rf_error("Failed to apply change at index %lld: %s", (long long) i, error_msg);
        }

        AMresultFree(result);
    }

    return doc_ptr;
}

// v1.2 Sync Operations -------------------------------------------------------

/**
 * Get missing dependencies for specified heads.
 *
 * @param doc_ptr External pointer to am_doc
 * @param heads List of change hashes (raw vectors), or NULL
 * @return List of raw vectors (change hashes of missing dependencies)
 */
SEXP C_am_get_missing_deps(SEXP doc_ptr, SEXP heads) {
    AMdoc *doc = get_doc(doc_ptr);

    AMitems heads_items;
    AMresult *heads_result = NULL;
    AMitems *heads_ptr = resolve_heads(heads, &heads_items, &heads_result);

    AMresult *result = AMgetMissingDeps(doc, heads_ptr);
    if (heads_result) AMresultFree(heads_result);

    if (AMresultStatus(result) != AM_STATUS_OK) {
        CHECK_RESULT(result, AM_VAL_TYPE_CHANGE_HASH);
    }

    AMitems items = AMresultItems(result);
    size_t count = AMitemsSize(&items);

    if (count == 0) {
        AMresultFree(result);
        return Rf_allocVector(VECSXP, 0);
    }

    SEXP deps_list = PROTECT(Rf_allocVector(VECSXP, count));

    for (size_t i = 0; i < count; i++) {
        AMitem *item = AMitemsNext(&items, 1);
        if (!item) break;

        AMbyteSpan hash;
        AMitemToChangeHash(item, &hash);

        SEXP r_hash = Rf_allocVector(RAWSXP, hash.count);
        memcpy(RAW(r_hash), hash.src, hash.count);
        SET_VECTOR_ELT(deps_list, i, r_hash);
    }

    AMresultFree(result);
    UNPROTECT(1);
    return deps_list;
}

/**
 * Encode a sync state to bytes.
 *
 * @param sync_state_ptr External pointer to am_syncstate
 * @return Raw vector containing the serialized sync state
 */
SEXP C_am_sync_state_encode(SEXP sync_state_ptr) {
    AMsyncState *state = get_syncstate(sync_state_ptr);

    AMresult *result = AMsyncStateEncode(state);
    CHECK_RESULT(result, AM_VAL_TYPE_BYTES);

    AMitem *item = AMresultItem(result);
    AMbyteSpan bytes;
    AMitemToBytes(item, &bytes);

    SEXP r_bytes = PROTECT(Rf_allocVector(RAWSXP, bytes.count));
    memcpy(RAW(r_bytes), bytes.src, bytes.count);

    AMresultFree(result);
    UNPROTECT(1);
    return r_bytes;
}

/**
 * Decode a sync state from bytes.
 *
 * @param data Raw vector containing serialized sync state
 * @return External pointer to am_syncstate
 */
SEXP C_am_sync_state_decode(SEXP data) {
    if (TYPEOF(data) != RAWSXP) {
        Rf_error("data must be a raw vector");
    }

    AMresult *result = AMsyncStateDecode(RAW(data), (size_t) XLENGTH(data));
    CHECK_RESULT(result, AM_VAL_TYPE_SYNC_STATE);

    AMitem *item = AMresultItem(result);
    AMsyncState *state = NULL;
    AMitemToSyncState(item, &state);

    am_syncstate *state_wrapper = malloc(sizeof(am_syncstate));
    if (!state_wrapper) {
        AMresultFree(result);
        Rf_error("Failed to allocate memory for sync state wrapper");
    }
    state_wrapper->result = result;
    state_wrapper->state = state;

    SEXP ext_ptr = PROTECT(R_MakeExternalPtr(state_wrapper, R_NilValue, R_NilValue));
    R_RegisterCFinalizer(ext_ptr, am_syncstate_finalizer);

    Rf_classgets(ext_ptr, Rf_mkString("am_syncstate"));

    UNPROTECT(1);
    return ext_ptr;
}
