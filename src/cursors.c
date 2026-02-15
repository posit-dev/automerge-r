#include "automerge.h"

// Cursor Support -------------------------------------------------------------

/**
 * Create a cursor at a position in a text object.
 *
 * R signature: am_cursor(obj, position)
 *
 * @param obj_ptr External pointer to AMobjId (must be text object)
 * @param position R integer (0-based position)
 * @return External pointer to AMcursor wrapped as am_cursor S3 class
 */
SEXP C_am_cursor(SEXP obj_ptr, SEXP position, SEXP heads) {
    SEXP doc_ptr = get_doc_from_objid(obj_ptr);
    AMdoc *doc = get_doc(doc_ptr);

    const AMobjId *obj_id = get_objid(obj_ptr);

    if (TYPEOF(position) != INTSXP && TYPEOF(position) != REALSXP) {
        Rf_error("position must be numeric");
    }
    if (XLENGTH(position) != 1) {
        Rf_error("position must be a scalar");
    }
    int r_pos = Rf_asInteger(position);
    if (r_pos < 0) {
        Rf_error("position must be non-negative (uses 0-based indexing)");
    }
    size_t c_pos = (size_t) r_pos;

    AMresult *result = NULL;
    if (heads == R_NilValue) {
        result = AMgetCursor(doc, obj_id, c_pos, NULL);
    } else {
        AMresult **head_results = NULL;
        size_t n_head_results = 0;
        AMresult *heads_result = convert_r_heads_to_amresult(heads, &head_results, &n_head_results);
        if (n_head_results == 0) {
            result = AMgetCursor(doc, obj_id, c_pos, NULL);
        } else if (n_head_results == 1) {
            AMitems heads_items = AMresultItems(heads_result);
            result = AMgetCursor(doc, obj_id, c_pos, &heads_items);
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

    CHECK_RESULT(result, AM_VAL_TYPE_CURSOR);

    AMitem *item = AMresultItem(result);
    AMcursor const *cursor = NULL;
    AMitemToCursor(item, &cursor);

    // Store obj_ptr in prot field so am_cursor_position can retrieve it
    SEXP cursor_ptr = PROTECT(R_MakeExternalPtr(result, R_NilValue, obj_ptr));
    R_RegisterCFinalizer(cursor_ptr, am_result_finalizer);

    Rf_classgets(cursor_ptr, Rf_mkString("am_cursor"));

    UNPROTECT(1);
    return cursor_ptr;
}

/**
 * Get the position of a cursor in a text object.
 *
 * R signature: am_cursor_position(cursor)
 *
 * @param cursor_ptr External pointer to AMresult containing cursor
 * @return R integer (0-based position)
 */
SEXP C_am_cursor_position(SEXP cursor_ptr, SEXP heads) {
    if (TYPEOF(cursor_ptr) != EXTPTRSXP) {
        Rf_error("cursor must be an external pointer (am_cursor object)");
    }

    SEXP obj_ptr = R_ExternalPtrProtected(cursor_ptr);
    if (obj_ptr == R_NilValue) {
        Rf_error("Invalid cursor: no associated text object");
    }

    SEXP doc_ptr = get_doc_from_objid(obj_ptr);
    AMdoc *doc = get_doc(doc_ptr);

    const AMobjId *obj_id = get_objid(obj_ptr);

    AMresult *cursor_result = (AMresult *) R_ExternalPtrAddr(cursor_ptr);
    if (!cursor_result) {
        Rf_error("Invalid cursor pointer (NULL or freed)");
    }

    AMitem *cursor_item = AMresultItem(cursor_result);
    AMcursor const *cursor = NULL;
    AMitemToCursor(cursor_item, &cursor);

    AMresult *result = NULL;
    if (heads == R_NilValue) {
        result = AMgetCursorPosition(doc, obj_id, cursor, NULL);
    } else {
        AMresult **head_results = NULL;
        size_t n_head_results = 0;
        AMresult *heads_result = convert_r_heads_to_amresult(heads, &head_results, &n_head_results);
        if (n_head_results == 0) {
            result = AMgetCursorPosition(doc, obj_id, cursor, NULL);
        } else if (n_head_results == 1) {
            AMitems heads_items = AMresultItems(heads_result);
            result = AMgetCursorPosition(doc, obj_id, cursor, &heads_items);
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

    CHECK_RESULT(result, AM_VAL_TYPE_UINT);

    AMitem *item = AMresultItem(result);
    uint64_t c_pos;
    AMitemToUint(item, &c_pos);

    if (c_pos > INT_MAX) {
        AMresultFree(result);
        Rf_error("Position too large to represent as R integer");
    }
    int r_pos = (int) c_pos;

    AMresultFree(result);

    return Rf_ScalarInteger(r_pos);
}

// Cursor Serialization -------------------------------------------------------

/**
 * Serialize a cursor to bytes.
 *
 * @param cursor_ptr External pointer to AMresult containing cursor
 * @return Raw vector containing the serialized cursor
 */
SEXP C_am_cursor_to_bytes(SEXP cursor_ptr) {
    if (TYPEOF(cursor_ptr) != EXTPTRSXP) {
        Rf_error("cursor must be an am_cursor object");
    }

    AMresult *cursor_result = (AMresult *) R_ExternalPtrAddr(cursor_ptr);
    if (!cursor_result) {
        Rf_error("Invalid cursor pointer (NULL or freed)");
    }

    AMitem *cursor_item = AMresultItem(cursor_result);
    AMcursor const *cursor = NULL;
    AMitemToCursor(cursor_item, &cursor);

    AMbyteSpan bytes = AMcursorBytes(cursor);

    SEXP r_bytes = PROTECT(Rf_allocVector(RAWSXP, bytes.count));
    memcpy(RAW(r_bytes), bytes.src, bytes.count);

    UNPROTECT(1);
    return r_bytes;
}

/**
 * Deserialize a cursor from bytes.
 *
 * @param bytes Raw vector containing serialized cursor
 * @param obj_ptr External pointer to AMobjId (text object for association)
 * @return External pointer to cursor with class "am_cursor"
 */
SEXP C_am_cursor_from_bytes(SEXP bytes, SEXP obj_ptr) {
    if (TYPEOF(bytes) != RAWSXP) {
        Rf_error("bytes must be a raw vector");
    }
    if (TYPEOF(obj_ptr) != EXTPTRSXP) {
        Rf_error("obj must be a text object");
    }

    AMresult *result = AMcursorFromBytes(RAW(bytes), (size_t) XLENGTH(bytes));
    CHECK_RESULT(result, AM_VAL_TYPE_CURSOR);

    SEXP cursor_ptr = PROTECT(R_MakeExternalPtr(result, R_NilValue, obj_ptr));
    R_RegisterCFinalizer(cursor_ptr, am_result_finalizer);
    Rf_classgets(cursor_ptr, Rf_mkString("am_cursor"));

    UNPROTECT(1);
    return cursor_ptr;
}

/**
 * Serialize a cursor to a string representation.
 *
 * @param cursor_ptr External pointer to AMresult containing cursor
 * @return Character string
 */
SEXP C_am_cursor_to_string(SEXP cursor_ptr) {
    if (TYPEOF(cursor_ptr) != EXTPTRSXP) {
        Rf_error("cursor must be an am_cursor object");
    }

    AMresult *cursor_result = (AMresult *) R_ExternalPtrAddr(cursor_ptr);
    if (!cursor_result) {
        Rf_error("Invalid cursor pointer (NULL or freed)");
    }

    AMitem *cursor_item = AMresultItem(cursor_result);
    AMcursor const *cursor = NULL;
    AMitemToCursor(cursor_item, &cursor);

    AMbyteSpan str = AMcursorStr(cursor);

    return Rf_ScalarString(Rf_mkCharLenCE((const char *) str.src, str.count, CE_UTF8));
}

/**
 * Deserialize a cursor from a string representation.
 *
 * @param str Character string containing serialized cursor
 * @param obj_ptr External pointer to AMobjId (text object for association)
 * @return External pointer to cursor with class "am_cursor"
 */
SEXP C_am_cursor_from_string(SEXP str, SEXP obj_ptr) {
    if (TYPEOF(str) != STRSXP || XLENGTH(str) != 1) {
        Rf_error("str must be a single character string");
    }
    if (TYPEOF(obj_ptr) != EXTPTRSXP) {
        Rf_error("obj must be a text object");
    }

    const char *c_str = CHAR(STRING_ELT(str, 0));
    AMbyteSpan span = {.src = (uint8_t const *) c_str, .count = strlen(c_str)};

    AMresult *result = AMcursorFromStr(span);
    CHECK_RESULT(result, AM_VAL_TYPE_CURSOR);

    SEXP cursor_ptr = PROTECT(R_MakeExternalPtr(result, R_NilValue, obj_ptr));
    R_RegisterCFinalizer(cursor_ptr, am_result_finalizer);
    Rf_classgets(cursor_ptr, Rf_mkString("am_cursor"));

    UNPROTECT(1);
    return cursor_ptr;
}

/**
 * Test equality of two cursors.
 *
 * @param cursor1_ptr External pointer to first cursor
 * @param cursor2_ptr External pointer to second cursor
 * @return Logical scalar
 */
SEXP C_am_cursor_equal(SEXP cursor1_ptr, SEXP cursor2_ptr) {
    if (TYPEOF(cursor1_ptr) != EXTPTRSXP) {
        Rf_error("cursor1 must be an am_cursor object");
    }
    if (TYPEOF(cursor2_ptr) != EXTPTRSXP) {
        Rf_error("cursor2 must be an am_cursor object");
    }

    AMresult *result1 = (AMresult *) R_ExternalPtrAddr(cursor1_ptr);
    AMresult *result2 = (AMresult *) R_ExternalPtrAddr(cursor2_ptr);
    if (!result1) Rf_error("Invalid cursor1 pointer (NULL or freed)");
    if (!result2) Rf_error("Invalid cursor2 pointer (NULL or freed)");

    AMitem *item1 = AMresultItem(result1);
    AMitem *item2 = AMresultItem(result2);

    AMcursor const *cursor1 = NULL;
    AMcursor const *cursor2 = NULL;
    AMitemToCursor(item1, &cursor1);
    AMitemToCursor(item2, &cursor2);

    bool equal = AMcursorEqual(cursor1, cursor2);

    return Rf_ScalarLogical(equal);
}

// Mark Support ---------------------------------------------------------------

// Forward declaration
static SEXP amitem_to_r_value(AMitem *item);

/**
 * Helper: Convert single mark to R list.
 * Returns an unprotected R list (all internal allocations are cleaned up).
 */
static SEXP convert_mark_to_r_list(AMmark const *mark, size_t index) {
    AMbyteSpan name_span = AMmarkName(mark);
    size_t c_start = AMmarkStart(mark);
    size_t c_end = AMmarkEnd(mark);

    AMresult *value_result = AMmarkValue(mark);
    if (!value_result) {
        Rf_error("Failed to get mark value at index %zu", index);
    }

    AMitem *value_item = AMresultItem(value_result);

    const char *names[] = {"name", "value", "start", "end", ""};
    SEXP mark_list = PROTECT(Rf_mkNamed(VECSXP, names));
    SEXP name = Rf_mkCharLenCE((char *) name_span.src, name_span.count, CE_UTF8);
    SET_VECTOR_ELT(mark_list, 0, Rf_ScalarString(name));
    SET_VECTOR_ELT(mark_list, 1, amitem_to_r_value(value_item));
    SET_VECTOR_ELT(mark_list, 2, Rf_ScalarInteger((int)c_start));
    SET_VECTOR_ELT(mark_list, 3, Rf_ScalarInteger((int)c_end));

    AMresultFree(value_result);
    UNPROTECT(1);

    return mark_list;
}

/**
 * Implementation for getting marks with optional position filtering.
 *
 * @param obj_ptr External pointer to AMobjId (must be text object)
 * @param filter_position If >= 0, filter marks to include only those at this position.
 *                        If < 0, return all marks (no filtering).
 * @return R list of marks
 */
static SEXP C_am_marks_impl(SEXP obj_ptr, int filter_position, SEXP heads) {
    SEXP doc_ptr = get_doc_from_objid(obj_ptr);
    AMdoc *doc = get_doc(doc_ptr);

    const AMobjId *obj_id = get_objid(obj_ptr);

    AMresult *result = NULL;
    if (heads == R_NilValue) {
        result = AMmarks(doc, obj_id, NULL);
    } else {
        AMresult **head_results = NULL;
        size_t n_head_results = 0;
        AMresult *heads_result = convert_r_heads_to_amresult(heads, &head_results, &n_head_results);
        if (n_head_results == 0) {
            result = AMmarks(doc, obj_id, NULL);
        } else if (n_head_results == 1) {
            AMitems heads_items = AMresultItems(heads_result);
            result = AMmarks(doc, obj_id, &heads_items);
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
    CHECK_RESULT(result, AM_VAL_TYPE_VOID);

    AMitems items = AMresultItems(result);
    size_t total_count = AMitemsSize(&items);

    bool filtering = filter_position >= 0;
    size_t c_pos = filtering ? (size_t)filter_position : 0;

    // If filtering, need to count matches first
    size_t output_count = total_count;
    if (filtering) {
        output_count = 0;
        AMitems items_copy = AMresultItems(result);
        for (size_t i = 0; i < total_count; i++) {
            AMitem *item = AMitemsNext(&items_copy, 1);
            if (!item) break;

            AMmark const *mark = NULL;
            AMitemToMark(item, &mark);

            size_t c_start = AMmarkStart(mark);
            size_t c_end = AMmarkEnd(mark);

            // Mark range is [start, end) - includes start, excludes end
            if (c_start <= c_pos && c_pos < c_end) {
                output_count++;
            }
        }
    }

    SEXP marks_list = PROTECT(Rf_allocVector(VECSXP, output_count));

    size_t output_index = 0;
    for (size_t i = 0; i < total_count; i++) {
        AMitem *item = AMitemsNext(&items, 1);

        AMmark const *mark = NULL;
        AMitemToMark(item, &mark);

        if (filtering) {
            size_t c_start = AMmarkStart(mark);
            size_t c_end = AMmarkEnd(mark);

            // Mark range is [start, end) - includes start, excludes end
            if (!(c_start <= c_pos && c_pos < c_end)) {
                continue;  // Skip marks that don't include the position
            }
        }

        SEXP mark_list = convert_mark_to_r_list(mark, i);
        SET_VECTOR_ELT(marks_list, output_index, mark_list);

        output_index++;
    }

    AMresultFree(result);
    UNPROTECT(1);
    return marks_list;
}

/**
 * Helper: Convert R expand string to AMmarkExpand enum.
 */
static AMmarkExpand r_expand_to_c(SEXP expand) {
    if (TYPEOF(expand) != STRSXP || Rf_xlength(expand) != 1) {
        Rf_error("expand must be a single character string");
    }

    const char *expand_str = CHAR(STRING_ELT(expand, 0));

    if (strcmp(expand_str, "none") == 0) {
        return AM_MARK_EXPAND_NONE;
    } else if (strcmp(expand_str, "before") == 0) {
        return AM_MARK_EXPAND_BEFORE;
    } else if (strcmp(expand_str, "after") == 0) {
        return AM_MARK_EXPAND_AFTER;
    } else if (strcmp(expand_str, "both") == 0) {
        return AM_MARK_EXPAND_BOTH;
    } else {
        Rf_error("Invalid expand value: must be \"none\", \"before\", \"after\", or \"both\"");
    }
}

/**
 * Helper: Convert R value to AMitem for mark value.
 */
static AMresult* r_value_to_amitem(SEXP value) {
    // Check S3 classes BEFORE generic TYPEOF checks
    if (value == R_NilValue) {
        return AMitemFromNull();
    } else if (Rf_inherits(value, "POSIXct")) {
        if (Rf_xlength(value) != 1) {
            Rf_error("Mark value must be scalar");
        }
        double seconds = REAL(value)[0];
        int64_t milliseconds = (int64_t) (seconds * 1000.0);
        return AMitemFromTimestamp(milliseconds);
    } else if (Rf_inherits(value, "am_counter")) {
        if (TYPEOF(value) != INTSXP || Rf_xlength(value) != 1) {
            Rf_error("Counter must be a scalar integer");
        }
        int64_t val = (int64_t) INTEGER(value)[0];
        return AMitemFromCounter(val);
    } else if (Rf_inherits(value, "am_uint64")) {
        if (TYPEOF(value) != REALSXP || Rf_xlength(value) != 1) {
            Rf_error("am_uint64 must be a scalar numeric");
        }
        uint64_t val = (uint64_t) REAL(value)[0];
        return AMitemFromUint(val);
    } else if (TYPEOF(value) == LGLSXP && Rf_xlength(value) == 1) {
        bool val = (bool) LOGICAL(value)[0];
        return AMitemFromBool(val);
    } else if (TYPEOF(value) == INTSXP && Rf_xlength(value) == 1) {
        int64_t val = (int64_t) INTEGER(value)[0];
        return AMitemFromInt(val);
    } else if (TYPEOF(value) == REALSXP && Rf_xlength(value) == 1) {
        double val = REAL(value)[0];
        return AMitemFromF64(val);
    } else if (TYPEOF(value) == STRSXP && Rf_xlength(value) == 1) {
        const char *str = CHAR(STRING_ELT(value, 0));
        AMbyteSpan span = {.src = (uint8_t const *) str, .count = strlen(str)};
        return AMitemFromStr(span);
    } else if (TYPEOF(value) == RAWSXP) {
        return AMitemFromBytes(RAW(value), (size_t) Rf_xlength(value));
    } else {
        Rf_error("Unsupported mark value type");
    }
}

/**
 * Helper: Convert AMitem to R value for mark value.
 */
static SEXP amitem_to_r_value(AMitem *item) {
    AMvalType type = AMitemValType(item);

    switch (type) {
        case AM_VAL_TYPE_NULL:
            return R_NilValue;
        case AM_VAL_TYPE_BOOL: {
            bool val;
            AMitemToBool(item, &val);
            return Rf_ScalarLogical(val);
        }
        case AM_VAL_TYPE_INT: {
            int64_t val;
            AMitemToInt(item, &val);
            if (val < INT_MIN || val > INT_MAX) {
                Rf_warning("Mark value integer out of R integer range, converting to double");
                return Rf_ScalarReal((double) val);
            }
            return Rf_ScalarInteger((int) val);
        }
        case AM_VAL_TYPE_UINT: {
            uint64_t val;
            AMitemToUint(item, &val);
            if (val > (1ULL << 53)) {
                Rf_warning("uint64 value exceeds 2^53; precision may be lost");
            }
            SEXP result = PROTECT(Rf_ScalarReal((double) val));
            Rf_classgets(result, Rf_mkString("am_uint64"));
            UNPROTECT(1);
            return result;
        }
        case AM_VAL_TYPE_F64: {
            double val;
            AMitemToF64(item, &val);
            return Rf_ScalarReal(val);
        }
        case AM_VAL_TYPE_STR: {
            AMbyteSpan span;
            AMitemToStr(item, &span);
            return Rf_ScalarString(Rf_mkCharLenCE((char *) span.src, span.count, CE_UTF8));
        }
        case AM_VAL_TYPE_BYTES: {
            AMbyteSpan span;
            AMitemToBytes(item, &span);
            SEXP raw = PROTECT(Rf_allocVector(RAWSXP, span.count));
            memcpy(RAW(raw), span.src, span.count);
            UNPROTECT(1);
            return raw;
        }
        case AM_VAL_TYPE_TIMESTAMP: {
            int64_t val;
            // Try AMitemToTimestamp first, then fall back to AMitemToInt
            if (!AMitemToTimestamp(item, &val)) {
                if (!AMitemToInt(item, &val)) {
                    Rf_error("Failed to extract timestamp from mark value");
                }
            }
            double seconds = (double) val / 1000.0;
            SEXP result = PROTECT(Rf_ScalarReal(seconds));
            SEXP class_vec = Rf_allocVector(STRSXP, 2);
            Rf_classgets(result, class_vec);
            SET_STRING_ELT(class_vec, 0, Rf_mkChar("POSIXct"));
            SET_STRING_ELT(class_vec, 1, Rf_mkChar("POSIXt"));
            UNPROTECT(1);
            return result;
        }
        case AM_VAL_TYPE_COUNTER: {
            int64_t val;
            // For counters, try both AMitemToInt and AMitemToCounter
            if (!AMitemToCounter(item, &val)) {
                // Fallback to AMitemToInt
                if (!AMitemToInt(item, &val)) {
                    Rf_error("Failed to extract counter from mark value");
                }
            }
            if (val < INT_MIN || val > INT_MAX) {
                Rf_warning("Counter value out of R integer range, converting to double");
                return Rf_ScalarReal((double) val);
            }
            SEXP result = PROTECT(Rf_ScalarInteger((int) val));
            Rf_classgets(result, Rf_mkString("am_counter"));
            UNPROTECT(1);
            return result;
        }
        default:
            Rf_error("Unsupported mark value type: %d", type);
    }
}

/**
 * Create a mark on a text range.
 *
 * R signature: am_mark(obj, start, end, name, value, expand = "none")
 *
 * @param obj_ptr External pointer to AMobjId (must be text object)
 * @param start R integer (1-based start position, inclusive)
 * @param end R integer (1-based end position, exclusive)
 * @param name R character string (mark name)
 * @param value R value (mark value - various types supported)
 * @param expand R character string (expand mode: "none", "before", "after", "both")
 * @return The text object (invisibly)
 */
SEXP C_am_mark(SEXP obj_ptr, SEXP start, SEXP end,
               SEXP name, SEXP value, SEXP expand) {
    SEXP doc_ptr = get_doc_from_objid(obj_ptr);
    AMdoc *doc = get_doc(doc_ptr);

    const AMobjId *obj_id = get_objid(obj_ptr);

    // Validate start position (0-based indexing)
    if (TYPEOF(start) != INTSXP && TYPEOF(start) != REALSXP) {
        Rf_error("start must be numeric");
    }
    if (Rf_xlength(start) != 1) {
        Rf_error("start must be a scalar");
    }
    int r_start = Rf_asInteger(start);
    if (r_start < 0) {
        Rf_error("start must be non-negative (uses 0-based indexing)");
    }
    size_t c_start = (size_t) r_start;  // Direct use, 0-based

    // Validate end position (0-based indexing)
    if (TYPEOF(end) != INTSXP && TYPEOF(end) != REALSXP) {
        Rf_error("end must be numeric");
    }
    if (Rf_xlength(end) != 1) {
        Rf_error("end must be a scalar");
    }
    int r_end = Rf_asInteger(end);
    if (r_end < 0) {
        Rf_error("end must be non-negative (uses 0-based indexing)");
    }
    size_t c_end = (size_t) r_end;  // Direct use, 0-based

    if (c_end <= c_start) {
        Rf_error("end must be greater than start");
    }

    if (TYPEOF(name) != STRSXP || Rf_xlength(name) != 1) {
        Rf_error("name must be a single character string");
    }
    const char *name_str = CHAR(STRING_ELT(name, 0));
    AMbyteSpan name_span = {.src = (uint8_t const *) name_str, .count = strlen(name_str)};

    AMmarkExpand expand_mode = r_expand_to_c(expand);

    AMresult *value_result = r_value_to_amitem(value);
    if (!value_result) {
        Rf_error("Failed to convert mark value to AMitem");
    }

    AMitem *value_item = AMresultItem(value_result);

    AMresult *result = AMmarkCreate(doc, obj_id, c_start, c_end, expand_mode,
                                     name_span, value_item);

    AMresultFree(value_result);

    CHECK_RESULT(result, AM_VAL_TYPE_VOID);
    AMresultFree(result);

    return obj_ptr;
}

/**
 * Get all marks in a text object.
 *
 * R signature: am_marks(obj)
 *
 * @param obj_ptr External pointer to AMobjId (must be text object)
 * @return R list of marks, each mark is a list with: name, value, start, end
 */
SEXP C_am_marks(SEXP obj_ptr, SEXP heads) {
    return C_am_marks_impl(obj_ptr, -1, heads);  // -1 = no filtering
}

/**
 * Get marks at a specific position in a text object.
 *
 * R signature: am_marks_at(obj, position)
 *
 * @param obj_ptr External pointer to AMobjId (must be text object)
 * @param position R integer (0-based position)
 * @return R list of marks that include the position, each mark is a list with: name, value, start, end
 */
SEXP C_am_marks_at(SEXP obj_ptr, SEXP position, SEXP heads) {
    if (TYPEOF(position) != INTSXP && TYPEOF(position) != REALSXP) {
        Rf_error("position must be numeric");
    }
    if (XLENGTH(position) != 1) {
        Rf_error("position must be a scalar");
    }
    int r_pos = Rf_asInteger(position);
    if (r_pos < 0) {
        Rf_error("position must be non-negative (uses 0-based indexing)");
    }

    return C_am_marks_impl(obj_ptr, r_pos, heads);
}

// v1.2 Mark Operations -------------------------------------------------------

/**
 * Clear/remove marks from a text range.
 *
 * @param obj_ptr External pointer to AMobjId (must be text object)
 * @param start R integer (0-based start position)
 * @param end R integer (0-based end position)
 * @param name R character string (mark name)
 * @param expand R character string (expand mode)
 * @return The text object (invisibly)
 */
SEXP C_am_mark_clear(SEXP obj_ptr, SEXP start, SEXP end,
                      SEXP name, SEXP expand) {
    SEXP doc_ptr = get_doc_from_objid(obj_ptr);
    AMdoc *doc = get_doc(doc_ptr);

    const AMobjId *obj_id = get_objid(obj_ptr);

    if (TYPEOF(start) != INTSXP && TYPEOF(start) != REALSXP) {
        Rf_error("start must be numeric");
    }
    if (Rf_xlength(start) != 1) {
        Rf_error("start must be a scalar");
    }
    int r_start = Rf_asInteger(start);
    if (r_start < 0) {
        Rf_error("start must be non-negative (uses 0-based indexing)");
    }
    size_t c_start = (size_t) r_start;

    if (TYPEOF(end) != INTSXP && TYPEOF(end) != REALSXP) {
        Rf_error("end must be numeric");
    }
    if (Rf_xlength(end) != 1) {
        Rf_error("end must be a scalar");
    }
    int r_end = Rf_asInteger(end);
    if (r_end < 0) {
        Rf_error("end must be non-negative (uses 0-based indexing)");
    }
    size_t c_end = (size_t) r_end;

    if (c_end <= c_start) {
        Rf_error("end must be greater than start");
    }

    if (TYPEOF(name) != STRSXP || Rf_xlength(name) != 1) {
        Rf_error("name must be a single character string");
    }
    const char *name_str = CHAR(STRING_ELT(name, 0));
    AMbyteSpan name_span = {.src = (uint8_t const *) name_str, .count = strlen(name_str)};

    AMmarkExpand expand_mode = r_expand_to_c(expand);

    AMresult *result = AMmarkClear(doc, obj_id, c_start, c_end, expand_mode, name_span);
    CHECK_RESULT(result, AM_VAL_TYPE_VOID);
    AMresultFree(result);

    return obj_ptr;
}
