#include "automerge.h"

// Change Wrapping Helpers -----------------------------------------------------

/**
 * Wrap an owned AMresult* containing a single change as an am_change object.
 * Uses am_change_data struct to manage the AMresult* lifetime.
 *
 * @param result AMresult* containing a single AM_VAL_TYPE_CHANGE (ownership transferred)
 * @return SEXP external pointer with class "am_change"
 */
SEXP wrap_am_change_owned(AMresult *result) {
    AMitem *item = AMresultItem(result);
    AMchange *ch = NULL;
    AMitemToChange(item, &ch);

    am_change_data *data = malloc(sizeof(am_change_data));
    if (!data) {
        AMresultFree(result);
        Rf_error("Failed to allocate memory for am_change wrapper");
    }
    data->result = result;
    data->change = ch;

    SEXP ext_ptr = PROTECT(R_MakeExternalPtr(data, R_NilValue, R_NilValue));
    R_RegisterCFinalizer(ext_ptr, am_change_finalizer);
    Rf_classgets(ext_ptr, Rf_mkString("am_change"));

    UNPROTECT(1);
    return ext_ptr;
}

/**
 * Wrap a borrowed AMchange* as an am_change object.
 * Stores AMchange* directly as the ext_ptr address (no struct allocation).
 * The parent AMresult is kept alive via the external pointer protection chain.
 *
 * @param ch Borrowed AMchange* pointer
 * @param parent_result_ptr External pointer to the parent AMresult (keeps it alive)
 * @return SEXP external pointer with class "am_change"
 */
SEXP wrap_am_change_borrowed(AMchange *ch, SEXP parent_result_ptr) {
    SEXP ext_ptr = PROTECT(R_MakeExternalPtr(ch, R_NilValue, parent_result_ptr));
    R_RegisterCFinalizer(ext_ptr, am_change_finalizer);
    Rf_classgets(ext_ptr, Rf_mkString("am_change"));

    UNPROTECT(1);
    return ext_ptr;
}

// Change Introspection Functions ----------------------------------------------

/**
 * Get AMchange* from an am_change external pointer.
 * Handles both owned (struct-based, prot == R_NilValue) and
 * borrowed (direct AMchange*, prot != R_NilValue) layouts.
 */
AMchange *get_change(SEXP change_ptr) {
    if (TYPEOF(change_ptr) != EXTPTRSXP) {
        Rf_error("change must be an am_change object (use am_change_from_bytes() first)");
    }
    if (R_ExternalPtrProtected(change_ptr) == R_NilValue) {
        am_change_data *data = (am_change_data *) R_ExternalPtrAddr(change_ptr);
        if (!data || !data->change) {
            Rf_error("Invalid am_change pointer (NULL or freed)");
        }
        return data->change;
    }
    AMchange *ch = (AMchange *) R_ExternalPtrAddr(change_ptr);
    if (!ch) {
        Rf_error("Invalid am_change pointer (NULL or freed)");
    }
    return ch;
}

/**
 * Get the hash of a change.
 *
 * @param change_ptr External pointer (am_change)
 * @return Raw vector (32 bytes) containing the change hash
 */
SEXP C_am_change_hash(SEXP change_ptr) {
    AMchange *ch = get_change(change_ptr);
    AMbyteSpan hash = AMchangeHash(ch);

    SEXP r_hash = PROTECT(Rf_allocVector(RAWSXP, hash.count));
    memcpy(RAW(r_hash), hash.src, hash.count);

    UNPROTECT(1);
    return r_hash;
}

/**
 * Get the commit message of a change.
 *
 * @param change_ptr External pointer (am_change)
 * @return Character string or NULL if no message
 */
SEXP C_am_change_message(SEXP change_ptr) {
    AMchange *ch = get_change(change_ptr);
    AMbyteSpan msg = AMchangeMessage(ch);

    if (msg.src == NULL || msg.count == 0) {
        return R_NilValue;
    }
    return Rf_ScalarString(Rf_mkCharLenCE((const char *) msg.src, msg.count, CE_UTF8));
}

/**
 * Get the timestamp of a change.
 *
 * @param change_ptr External pointer (am_change)
 * @return POSIXct timestamp
 */
SEXP C_am_change_time(SEXP change_ptr) {
    AMchange *ch = get_change(change_ptr);
    int64_t millis = AMchangeTime(ch);

    double seconds = (double) millis / 1000.0;
    SEXP r_time = PROTECT(Rf_ScalarReal(seconds));
    SEXP class_vec = Rf_allocVector(STRSXP, 2);
    Rf_classgets(r_time, class_vec);
    SET_STRING_ELT(class_vec, 0, Rf_mkChar("POSIXct"));
    SET_STRING_ELT(class_vec, 1, Rf_mkChar("POSIXt"));

    UNPROTECT(1);
    return r_time;
}

/**
 * Get the actor ID of a change.
 *
 * @param change_ptr External pointer (am_change)
 * @return Raw vector containing the actor ID bytes
 */
SEXP C_am_change_actor_id(SEXP change_ptr) {
    AMchange *ch = get_change(change_ptr);

    AMresult *actor_result = AMchangeActorId(ch);
    CHECK_RESULT(actor_result, AM_VAL_TYPE_ACTOR_ID);

    AMitem *actor_item = AMresultItem(actor_result);
    AMactorId const *actor_id = NULL;
    AMitemToActorId(actor_item, &actor_id);

    AMbyteSpan bytes = AMactorIdBytes(actor_id);

    SEXP r_bytes = PROTECT(Rf_allocVector(RAWSXP, bytes.count));
    memcpy(RAW(r_bytes), bytes.src, bytes.count);

    AMresultFree(actor_result);
    UNPROTECT(1);
    return r_bytes;
}

/**
 * Get the sequence number of a change.
 *
 * @param change_ptr External pointer (am_change)
 * @return Double (u64 can exceed R integer range)
 */
SEXP C_am_change_seq(SEXP change_ptr) {
    AMchange *ch = get_change(change_ptr);
    uint64_t seq = AMchangeSeq(ch);
    return Rf_ScalarReal((double) seq);
}

/**
 * Get the dependencies (parent change hashes) of a change.
 *
 * @param change_ptr External pointer (am_change)
 * @return List of raw vectors (change hashes)
 */
SEXP C_am_change_deps(SEXP change_ptr) {
    AMchange *ch = get_change(change_ptr);

    AMresult *deps_result = AMchangeDeps(ch);

    if (AMresultStatus(deps_result) != AM_STATUS_OK) {
        CHECK_RESULT(deps_result, AM_VAL_TYPE_CHANGE_HASH);
    }

    AMitems items = AMresultItems(deps_result);
    size_t count = AMitemsSize(&items);

    SEXP deps_list = PROTECT(Rf_allocVector(VECSXP, count));

    for (size_t i = 0; i < count; i++) {
        AMitem *dep_item = AMitemsNext(&items, 1);
        if (!dep_item) break;

        AMbyteSpan hash;
        AMitemToChangeHash(dep_item, &hash);

        SEXP r_hash = Rf_allocVector(RAWSXP, hash.count);
        memcpy(RAW(r_hash), hash.src, hash.count);
        SET_VECTOR_ELT(deps_list, i, r_hash);
    }

    AMresultFree(deps_result);
    UNPROTECT(1);
    return deps_list;
}

/**
 * Deserialize a change from raw bytes into an am_change object.
 *
 * @param bytes Raw vector containing serialized change
 * @return External pointer with class "am_change"
 */
SEXP C_am_change_from_bytes(SEXP bytes) {
    if (TYPEOF(bytes) != RAWSXP) {
        Rf_error("bytes must be a raw vector");
    }

    AMresult *result = AMchangeFromBytes(RAW(bytes), (size_t) XLENGTH(bytes));
    CHECK_RESULT(result, AM_VAL_TYPE_CHANGE);

    return wrap_am_change_owned(result);
}

/**
 * Serialize a change to raw bytes.
 *
 * @param change_ptr External pointer (am_change)
 * @return Raw vector containing the serialized change
 */
SEXP C_am_change_to_bytes(SEXP change_ptr) {
    AMchange *ch = get_change(change_ptr);
    AMbyteSpan bytes = AMchangeRawBytes(ch);

    SEXP r_bytes = PROTECT(Rf_allocVector(RAWSXP, bytes.count));
    memcpy(RAW(r_bytes), bytes.src, bytes.count);

    UNPROTECT(1);
    return r_bytes;
}

/**
 * Get the number of operations in a change.
 *
 * @param change_ptr External pointer (am_change)
 * @return Integer (number of operations)
 */
SEXP C_am_change_size(SEXP change_ptr) {
    AMchange *ch = get_change(change_ptr);
    size_t size = AMchangeSize(ch);
    return size > INT_MAX ?
        Rf_ScalarReal((double) size) :
        Rf_ScalarInteger((int) size);
}

// v1.2 Change Operations -----------------------------------------------------

/**
 * Load a document as a sequence of individual changes.
 *
 * @param data Raw vector containing serialized document
 * @return List of am_change objects
 */
SEXP C_am_load_changes(SEXP data) {
    if (TYPEOF(data) != RAWSXP) {
        Rf_error("data must be a raw vector");
    }

    AMresult *result = AMchangeLoadDocument(RAW(data), (size_t) XLENGTH(data));

    if (AMresultStatus(result) != AM_STATUS_OK) {
        CHECK_RESULT(result, AM_VAL_TYPE_CHANGE);
    }

    AMitems items = AMresultItems(result);
    size_t count = AMitemsSize(&items);

    if (count == 0) {
        AMresultFree(result);
        return Rf_allocVector(VECSXP, 0);
    }

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
