#include "automerge.h"

// Document Lifecycle Functions ------------------------------------------------

/**
 * Close an Automerge document and free its resources.
 *
 * This function explicitly frees the document's memory rather than waiting
 * for garbage collection. After calling this function, the document pointer
 * becomes invalid and should not be used.
 *
 * @param doc_ptr External pointer to am_doc
 * @return R_NilValue (invisibly)
 */
SEXP C_am_close(SEXP doc_ptr) {
    if (TYPEOF(doc_ptr) != EXTPTRSXP) {
        Rf_error("Expected external pointer for document");
    }

    am_doc *doc_wrapper = (am_doc *) R_ExternalPtrAddr(doc_ptr);
    if (doc_wrapper) {
        if (doc_wrapper->result) {
            AMresultFree(doc_wrapper->result);
            doc_wrapper->result = NULL;
        }
        doc_wrapper->doc = NULL;
        free(doc_wrapper);
    }
    R_ClearExternalPtr(doc_ptr);

    return R_NilValue;
}

/**
 * Create a new Automerge document.
 *
 * @param actor_id R object: NULL for random actor ID, character hex string,
 *                 or raw bytes
 * @return External pointer to am_doc structure (with class "am_doc")
 */
SEXP C_am_create(SEXP actor_id) {
    AMresult *result = NULL;

    if (actor_id == R_NilValue) {
        // NULL generates random actor ID
        result = AMcreate(NULL);
    } else if (TYPEOF(actor_id) == STRSXP && XLENGTH(actor_id) == 1) {
        const char *hex_str = CHAR(STRING_ELT(actor_id, 0));
        AMbyteSpan hex_span = {.src = (uint8_t const *) hex_str, .count = strlen(hex_str)};
        AMresult *actor_result = AMactorIdFromStr(hex_span);
        CHECK_RESULT(actor_result, AM_VAL_TYPE_ACTOR_ID);

        AMitem *actor_item = AMresultItem(actor_result);
        AMactorId const *actor = NULL;
        AMitemToActorId(actor_item, &actor);

        result = AMcreate(actor);
        AMresultFree(actor_result);
    } else if (TYPEOF(actor_id) == RAWSXP) {
        AMresult *actor_result = AMactorIdFromBytes(RAW(actor_id), (size_t) XLENGTH(actor_id));
        CHECK_RESULT(actor_result, AM_VAL_TYPE_ACTOR_ID);

        AMitem *actor_item = AMresultItem(actor_result);
        AMactorId const *actor = NULL;
        AMitemToActorId(actor_item, &actor);

        result = AMcreate(actor);
        AMresultFree(actor_result);
    } else {
        Rf_error("actor_id must be NULL, a character string (hex), or raw bytes");
    }

    CHECK_RESULT(result, AM_VAL_TYPE_DOC);

    AMitem *item = AMresultItem(result);
    AMdoc *doc = NULL;
    AMitemToDoc(item, &doc);

    am_doc *doc_wrapper = malloc(sizeof(am_doc));
    if (!doc_wrapper) {
        AMresultFree(result);
        Rf_error("Failed to allocate memory for document wrapper");
    }
    doc_wrapper->result = result;  // Owning result
    doc_wrapper->doc = doc;        // Borrowed from result

    SEXP ext_ptr = PROTECT(R_MakeExternalPtr(doc_wrapper, R_NilValue, R_NilValue));
    R_RegisterCFinalizer(ext_ptr, am_doc_finalizer);

    SEXP class = Rf_allocVector(STRSXP, 2);
    Rf_classgets(ext_ptr, class);
    SET_STRING_ELT(class, 0, Rf_mkChar("am_doc"));
    SET_STRING_ELT(class, 1, Rf_mkChar("automerge"));

    UNPROTECT(1);
    return ext_ptr;
}

/**
 * Save an Automerge document to binary format.
 *
 * @param doc_ptr External pointer to am_doc
 * @return Raw vector containing the serialized document
 */
SEXP C_am_save(SEXP doc_ptr) {
    AMdoc *doc = get_doc(doc_ptr);

    AMresult *result = AMsave(doc);
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
 * Load an Automerge document from binary format.
 *
 * @param data Raw vector containing serialized document
 * @return External pointer to am_doc structure
 */
SEXP C_am_load(SEXP data) {
    if (TYPEOF(data) != RAWSXP) {
        Rf_error("data must be a raw vector");
    }

    AMresult *result = AMload(RAW(data), (size_t) XLENGTH(data));
    CHECK_RESULT(result, AM_VAL_TYPE_DOC);

    AMitem *item = AMresultItem(result);
    AMdoc *doc = NULL;
    AMitemToDoc(item, &doc);

    am_doc *doc_wrapper = malloc(sizeof(am_doc));
    if (!doc_wrapper) {
        AMresultFree(result);
        Rf_error("Failed to allocate memory for document wrapper");
    }
    doc_wrapper->result = result;
    doc_wrapper->doc = doc;

    SEXP ext_ptr = PROTECT(R_MakeExternalPtr(doc_wrapper, R_NilValue, R_NilValue));
    R_RegisterCFinalizer(ext_ptr, am_doc_finalizer);

    SEXP class = Rf_allocVector(STRSXP, 2);
    Rf_classgets(ext_ptr, class);
    SET_STRING_ELT(class, 0, Rf_mkChar("am_doc"));
    SET_STRING_ELT(class, 1, Rf_mkChar("automerge"));

    UNPROTECT(1);
    return ext_ptr;
}

/**
 * Helper: Convert R list of change hashes to AMitems struct.
 *
 * Takes an R list of raw vectors (change hashes) and creates the necessary
 * AMresult objects, then extracts AMitems for use with C API functions.
 *
 * @param heads_list R list of raw vectors (change hashes)
 * @param results_out Output parameter: array of AMresult pointers to keep alive
 * @param n_results Output parameter: number of results in array
 * @return AMresult containing change hash items (must be freed by caller)
 */
AMresult* convert_r_heads_to_amresult(SEXP heads_list, AMresult ***results_out, size_t *n_results) {
    if (TYPEOF(heads_list) != VECSXP) {
        Rf_error("heads must be NULL or a list of raw vectors");
    }

    R_xlen_t n_heads = XLENGTH(heads_list);
    if (n_heads == 0) {
        *results_out = NULL;
        *n_results = 0;
        return NULL;
    }

    AMresult **results = malloc(n_heads * sizeof(AMresult *));
    if (!results) {
        Rf_error("Failed to allocate memory for change hash results");
    }

    for (R_xlen_t i = 0; i < n_heads; i++) {
        SEXP r_hash = VECTOR_ELT(heads_list, i);
        if (TYPEOF(r_hash) != RAWSXP) {
            for (R_xlen_t j = 0; j < i; j++) {
                AMresultFree(results[j]);
            }
            free(results);
            Rf_error("All heads must be raw vectors (change hashes)");
        }

        AMbyteSpan hash_span = {
            .src = RAW(r_hash),
            .count = (size_t) XLENGTH(r_hash)
        };

        results[i] = AMitemFromChangeHash(hash_span);
        if (!results[i] || AMresultStatus(results[i]) != AM_STATUS_OK) {
            for (R_xlen_t j = 0; j <= i; j++) {
                if (results[j]) AMresultFree(results[j]);
            }
            free(results);
            Rf_error("Invalid change hash at index %lld", (long long) i);
        }
    }

    *results_out = results;
    *n_results = (size_t) n_heads;

    return results[0];
}

/**
 * Resolve an R heads list to an AMitems pointer for C API calls.
 *
 * Converts an R list of change hashes to the AMitems* pointer expected by
 * automerge-c API functions. The caller must free *heads_result_out after
 * the API call completes.
 *
 * @param heads R list of raw vectors, or R_NilValue for current heads
 * @param heads_items_out Caller-allocated AMitems storage (populated on success)
 * @param heads_result_out Set to AMresult* that caller must free, or NULL
 * @return Pointer to heads_items_out if heads provided, or NULL for current heads
 */
AMitems* resolve_heads(SEXP heads, AMitems *heads_items_out, AMresult **heads_result_out) {
    *heads_result_out = NULL;

    if (heads == R_NilValue) {
        return NULL;
    }

    AMresult **head_results = NULL;
    size_t n_head_results = 0;
    AMresult *heads_result = convert_r_heads_to_amresult(heads, &head_results, &n_head_results);

    if (n_head_results == 0) {
        return NULL;
    } else if (n_head_results == 1) {
        *heads_items_out = AMresultItems(heads_result);
        *heads_result_out = heads_result;
        free(head_results);
        return heads_items_out;
    } else {
        for (size_t i = 0; i < n_head_results; i++) {
            AMresultFree(head_results[i]);
        }
        free(head_results);
        Rf_error("multiple heads are not supported; commit first to produce a single head");
    }
}

/**
 * Fork an Automerge document at current or specified heads.
 *
 * @param doc_ptr External pointer to am_doc
 * @param heads R object: NULL for current heads, or list of change hashes (raw vectors)
 * @return External pointer to forked am_doc
 */
SEXP C_am_fork(SEXP doc_ptr, SEXP heads) {
    AMdoc *doc = get_doc(doc_ptr);

    AMresult *result = NULL;
    AMresult **head_results = NULL;
    size_t n_head_results = 0;

    if (heads == R_NilValue || (TYPEOF(heads) == VECSXP && XLENGTH(heads) == 0)) {
        result = AMfork(doc, NULL);
    } else {
        AMresult *heads_result = convert_r_heads_to_amresult(heads, &head_results, &n_head_results);

        if (n_head_results == 0) {
            result = AMfork(doc, NULL);
        } else if (heads_result && n_head_results == 1) {
            AMitems heads_items = AMresultItems(heads_result);
            result = AMfork(doc, &heads_items);

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

    CHECK_RESULT(result, AM_VAL_TYPE_DOC);

    AMitem *item = AMresultItem(result);
    AMdoc *forked_doc = NULL;
    AMitemToDoc(item, &forked_doc);

    am_doc *doc_wrapper = malloc(sizeof(am_doc));
    if (!doc_wrapper) {
        AMresultFree(result);
        Rf_error("Failed to allocate memory for forked document wrapper");
    }
    doc_wrapper->result = result;
    doc_wrapper->doc = forked_doc;

    SEXP ext_ptr = PROTECT(R_MakeExternalPtr(doc_wrapper, R_NilValue, R_NilValue));
    R_RegisterCFinalizer(ext_ptr, am_doc_finalizer);

    SEXP class = Rf_allocVector(STRSXP, 2);
    Rf_classgets(ext_ptr, class);
    SET_STRING_ELT(class, 0, Rf_mkChar("am_doc"));
    SET_STRING_ELT(class, 1, Rf_mkChar("automerge"));

    UNPROTECT(1);
    return ext_ptr;
}

/**
 * Merge changes from another document.
 *
 * @param doc_ptr External pointer to am_doc (target document)
 * @param other_ptr External pointer to am_doc (source document)
 * @return The target document pointer (for chaining)
 */
SEXP C_am_merge(SEXP doc_ptr, SEXP other_ptr) {
    AMdoc *doc = get_doc(doc_ptr);
    AMdoc *other_doc = get_doc(other_ptr);

    AMresult *result = AMmerge(doc, other_doc);

    // AMmerge returns heads if changes were merged, or empty if no new changes
    CHECK_RESULT(result, AM_VAL_TYPE_VOID);

    AMresultFree(result);
    return doc_ptr;
}

/**
 * Get the actor ID of a document.
 *
 * @param doc_ptr External pointer to am_doc
 * @return Raw vector containing actor ID bytes
 */
SEXP C_am_get_actor(SEXP doc_ptr) {
    AMdoc *doc = get_doc(doc_ptr);

    AMresult *result = AMgetActorId(doc);
    CHECK_RESULT(result, AM_VAL_TYPE_ACTOR_ID);

    AMitem *item = AMresultItem(result);
    AMactorId const *actor_id = NULL;
    AMitemToActorId(item, &actor_id);

    AMbyteSpan bytes = AMactorIdBytes(actor_id);

    SEXP r_bytes = PROTECT(Rf_allocVector(RAWSXP, bytes.count));
    memcpy(RAW(r_bytes), bytes.src, bytes.count);

    AMresultFree(result);
    UNPROTECT(1);
    return r_bytes;
}

/**
 * Get the actor ID as hex string.
 *
 * @param doc_ptr External pointer to am_doc
 * @return Character string containing hex-encoded actor ID
 */
SEXP C_am_get_actor_hex(SEXP doc_ptr) {
    AMdoc *doc = get_doc(doc_ptr);

    AMresult *result = AMgetActorId(doc);
    CHECK_RESULT(result, AM_VAL_TYPE_ACTOR_ID);

    AMitem *item = AMresultItem(result);
    AMactorId const *actor_id = NULL;
    AMitemToActorId(item, &actor_id);

    AMbyteSpan hex_str = AMactorIdStr(actor_id);

    SEXP r_str = Rf_ScalarString(Rf_mkCharLenCE((const char*) hex_str.src, hex_str.count, CE_UTF8));

    AMresultFree(result);
    return r_str;
}

/**
 * Set the actor ID of a document.
 *
 * @param doc_ptr External pointer to am_doc
 * @param actor_id R object: NULL for random, character hex string, or raw bytes
 * @return The document pointer (for chaining)
 */
SEXP C_am_set_actor(SEXP doc_ptr, SEXP actor_id) {
    AMdoc *doc = get_doc(doc_ptr);

    AMresult *actor_result = NULL;
    AMresult *put_result = NULL;
    AMactorId const *actor = NULL;

    if (actor_id == R_NilValue) {
        // NULL generates random actor ID
        actor_result = AMactorIdInit();
        CHECK_RESULT(actor_result, AM_VAL_TYPE_ACTOR_ID);
        AMitem *actor_item = AMresultItem(actor_result);
        AMitemToActorId(actor_item, &actor);
    } else if (TYPEOF(actor_id) == STRSXP && XLENGTH(actor_id) == 1) {
        const char *hex_str = CHAR(STRING_ELT(actor_id, 0));
        AMbyteSpan hex_span = {.src = (uint8_t const *) hex_str, .count = strlen(hex_str)};
        actor_result = AMactorIdFromStr(hex_span);
        CHECK_RESULT(actor_result, AM_VAL_TYPE_ACTOR_ID);
        AMitem *actor_item = AMresultItem(actor_result);
        AMitemToActorId(actor_item, &actor);
    } else if (TYPEOF(actor_id) == RAWSXP) {
        actor_result = AMactorIdFromBytes(RAW(actor_id), (size_t) XLENGTH(actor_id));
        CHECK_RESULT(actor_result, AM_VAL_TYPE_ACTOR_ID);
        AMitem *actor_item = AMresultItem(actor_result);
        AMitemToActorId(actor_item, &actor);
    } else {
        Rf_error("actor_id must be NULL, a character string (hex), or raw bytes");
    }

    put_result = AMsetActorId(doc, actor);

    AMresultFree(put_result);
    AMresultFree(actor_result);
    return doc_ptr;
}

/**
 * Commit pending changes with optional message and timestamp.
 *
 * @param doc_ptr External pointer to am_doc
 * @param message Character string commit message (or NULL)
 * @param time POSIXct timestamp (or NULL for current time)
 * @return The document pointer (for chaining)
 */
SEXP C_am_commit(SEXP doc_ptr, SEXP message, SEXP time) {
    AMdoc *doc = get_doc(doc_ptr);

    AMbyteSpan msg_span = {.src = NULL, .count = 0};
    if (message != R_NilValue) {
        if (TYPEOF(message) != STRSXP || XLENGTH(message) != 1) {
            Rf_error("message must be NULL or a single character string");
        }
        const char *msg_str = CHAR(STRING_ELT(message, 0));
        msg_span.src = (uint8_t const *) msg_str;
        msg_span.count = strlen(msg_str);
    }

    int64_t timestamp = 0;
    if (time != R_NilValue) {
        if (!Rf_inherits(time, "POSIXct") || Rf_xlength(time) != 1) {
            Rf_error("time must be NULL or a scalar POSIXct object");
        }
        double seconds = REAL(time)[0];
        timestamp = (int64_t) (seconds * 1000.0);
    }

    AMresult *result = AMcommit(doc, msg_span, time == R_NilValue ? NULL : &timestamp);

    // AMcommit returns VOID if there were no pending operations,
    // or CHANGE_HASH if changes were committed
    CHECK_RESULT(result, AM_VAL_TYPE_VOID);

    AMresultFree(result);
    return doc_ptr;
}

/**
 * Roll back pending operations in the current transaction.
 *
 * @param doc_ptr External pointer to am_doc
 * @return The document pointer (for chaining)
 */
SEXP C_am_rollback(SEXP doc_ptr) {
    AMdoc *doc = get_doc(doc_ptr);

    AMrollback(doc);

    return doc_ptr;
}

// Historical Query and Advanced Fork/Merge Functions (Phase 6) ---------------

/**
 * Get the last change made by the local actor.
 *
 * Returns the most recent change created by this document's actor,
 * or NULL if no local changes have been made.
 *
 * @param doc_ptr External pointer to am_doc
 * @return am_change object, or NULL if none
 */
SEXP C_am_get_last_local_change(SEXP doc_ptr) {
    AMdoc *doc = get_doc(doc_ptr);

    AMresult *result = AMgetLastLocalChange(doc);

    AMstatus status = AMresultStatus(result);
    if (status != AM_STATUS_OK) {
        AMresultFree(result);
        return R_NilValue;
    }

    AMitems items = AMresultItems(result);
    size_t count = AMitemsSize(&items);

    if (count == 0) {
        AMresultFree(result);
        return R_NilValue;
    }

    AMitem *item = AMitemsNext(&items, 1);
    if (!item) {
        AMresultFree(result);
        return R_NilValue;
    }

    // Check if it's actually a change (not void)
    AMchange *change = NULL;
    if (!AMitemToChange(item, &change) || !change) {
        AMresultFree(result);
        return R_NilValue;
    }

    return wrap_am_change_owned(result);
}

/**
 * Get a specific change by its hash.
 *
 * @param doc_ptr External pointer to am_doc
 * @param hash Raw vector containing the change hash (32 bytes)
 * @return am_change object, or NULL if not found
 */
SEXP C_am_get_change_by_hash(SEXP doc_ptr, SEXP hash) {
    AMdoc *doc = get_doc(doc_ptr);

    if (TYPEOF(hash) != RAWSXP) {
        Rf_error("hash must be a raw vector");
    }

    size_t hash_len = (size_t) XLENGTH(hash);
    if (hash_len != 32) {  // AM_CHANGE_HASH_SIZE
        Rf_error("Change hash must be exactly 32 bytes");
    }

    AMresult *result = AMgetChangeByHash(doc, RAW(hash), hash_len);

    AMstatus status = AMresultStatus(result);
    if (status != AM_STATUS_OK) {
        AMresultFree(result);
        return R_NilValue;
    }

    AMitems items = AMresultItems(result);
    size_t count = AMitemsSize(&items);

    if (count == 0) {
        AMresultFree(result);
        return R_NilValue;
    }

    AMitem *item = AMitemsNext(&items, 1);
    if (!item) {
        AMresultFree(result);
        return R_NilValue;
    }

    AMchange *change = NULL;
    if (!AMitemToChange(item, &change) || !change) {
        AMresultFree(result);
        return R_NilValue;
    }

    return wrap_am_change_owned(result);
}

/**
 * Get changes in doc2 that are not in doc1.
 *
 * Compares two documents and returns the changes that exist in doc2
 * but not in doc1. Useful for determining what changes need to be
 * applied to bring doc1 up to date with doc2.
 *
 * @param doc1_ptr External pointer to am_doc (base document)
 * @param doc2_ptr External pointer to am_doc (comparison document)
 * @return List of am_change objects
 */
SEXP C_am_get_changes_added(SEXP doc1_ptr, SEXP doc2_ptr) {
    AMdoc *doc1 = get_doc(doc1_ptr);
    AMdoc *doc2 = get_doc(doc2_ptr);

    AMresult *result = AMgetChangesAdded(doc1, doc2);

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

// v1.2 Document Operations ---------------------------------------------------

/**
 * Clone an Automerge document (deep copy).
 *
 * @param doc_ptr External pointer to am_doc
 * @return External pointer to new independent am_doc
 */
SEXP C_am_clone(SEXP doc_ptr) {
    AMdoc *doc = get_doc(doc_ptr);

    AMresult *result = AMclone(doc);
    CHECK_RESULT(result, AM_VAL_TYPE_DOC);

    AMitem *item = AMresultItem(result);
    AMdoc *cloned_doc = NULL;
    AMitemToDoc(item, &cloned_doc);

    am_doc *doc_wrapper = malloc(sizeof(am_doc));
    if (!doc_wrapper) {
        AMresultFree(result);
        Rf_error("Failed to allocate memory for cloned document wrapper");
    }
    doc_wrapper->result = result;
    doc_wrapper->doc = cloned_doc;

    SEXP ext_ptr = PROTECT(R_MakeExternalPtr(doc_wrapper, R_NilValue, R_NilValue));
    R_RegisterCFinalizer(ext_ptr, am_doc_finalizer);

    SEXP class = Rf_allocVector(STRSXP, 2);
    Rf_classgets(ext_ptr, class);
    SET_STRING_ELT(class, 0, Rf_mkChar("am_doc"));
    SET_STRING_ELT(class, 1, Rf_mkChar("automerge"));

    UNPROTECT(1);
    return ext_ptr;
}

/**
 * Test if two documents are equal.
 *
 * @param doc1_ptr External pointer to am_doc
 * @param doc2_ptr External pointer to am_doc
 * @return Logical scalar (TRUE/FALSE)
 */
SEXP C_am_equal(SEXP doc1_ptr, SEXP doc2_ptr) {
    AMdoc *doc1 = get_doc(doc1_ptr);
    AMdoc *doc2 = get_doc(doc2_ptr);

    bool equal = AMequal(doc1, doc2);

    return Rf_ScalarLogical(equal);
}

/**
 * Get the number of pending operations.
 *
 * @param doc_ptr External pointer to am_doc
 * @return Integer scalar
 */
SEXP C_am_pending_ops(SEXP doc_ptr) {
    AMdoc *doc = get_doc(doc_ptr);

    size_t count = AMpendingOps(doc);

    if (count > INT_MAX) {
        return Rf_ScalarReal((double) count);
    }
    return Rf_ScalarInteger((int) count);
}

/**
 * Create an empty change (merge commit).
 *
 * @param doc_ptr External pointer to am_doc
 * @param message Character string commit message (or NULL)
 * @param time POSIXct timestamp (or NULL)
 * @return The document pointer (invisibly)
 */
SEXP C_am_commit_empty(SEXP doc_ptr, SEXP message, SEXP time) {
    AMdoc *doc = get_doc(doc_ptr);

    AMbyteSpan msg_span = {.src = NULL, .count = 0};
    if (message != R_NilValue) {
        if (TYPEOF(message) != STRSXP || XLENGTH(message) != 1) {
            Rf_error("message must be NULL or a single character string");
        }
        const char *msg_str = CHAR(STRING_ELT(message, 0));
        msg_span.src = (uint8_t const *) msg_str;
        msg_span.count = strlen(msg_str);
    }

    int64_t timestamp = 0;
    if (time != R_NilValue) {
        if (!Rf_inherits(time, "POSIXct") || Rf_xlength(time) != 1) {
            Rf_error("time must be NULL or a scalar POSIXct object");
        }
        double seconds = REAL(time)[0];
        timestamp = (int64_t) (seconds * 1000.0);
    }

    AMresult *result = AMemptyChange(doc, msg_span, time == R_NilValue ? NULL : &timestamp);
    CHECK_RESULT(result, AM_VAL_TYPE_CHANGE_HASH);

    AMresultFree(result);
    return doc_ptr;
}

/**
 * Save incremental changes since last save.
 *
 * @param doc_ptr External pointer to am_doc
 * @return Raw vector of incremental changes
 */
SEXP C_am_save_incremental(SEXP doc_ptr) {
    AMdoc *doc = get_doc(doc_ptr);

    AMresult *result = AMsaveIncremental(doc);
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
 * Load incremental changes into a document.
 *
 * @param doc_ptr External pointer to am_doc
 * @param data Raw vector of incremental changes
 * @return Number of operations applied (numeric scalar)
 */
SEXP C_am_load_incremental(SEXP doc_ptr, SEXP data) {
    AMdoc *doc = get_doc(doc_ptr);

    if (TYPEOF(data) != RAWSXP) {
        Rf_error("data must be a raw vector");
    }

    AMresult *result = AMloadIncremental(doc, RAW(data), (size_t) XLENGTH(data));
    CHECK_RESULT(result, AM_VAL_TYPE_UINT);

    AMitem *item = AMresultItem(result);
    uint64_t count;
    AMitemToUint(item, &count);

    AMresultFree(result);
    return Rf_ScalarReal((double) count);
}
