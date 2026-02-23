#include "automerge.h"

// Forward declarations --------------------------------------------------------

static void populate_object_from_r_list(AMdoc *doc, const AMobjId *obj_id,
                                         SEXP r_list, AMresult *parent_result);

// Type Conversion Helpers -----------------------------------------------------

/**
 * Convert R value to appropriate AMmapPut* or AMlistPut* call.
 * Handles type dispatch for scalar values and recursive conversion.
 */
static AMresult *am_put_value(AMdoc *doc, const AMobjId *obj_id,
                               SEXP key_or_pos, bool is_map, SEXP value, bool force_insert) {
    bool insert = false;
    size_t pos = 0;
    AMbyteSpan key = {.src = NULL, .count = 0};

    if (is_map) {
        if (TYPEOF(key_or_pos) != STRSXP || XLENGTH(key_or_pos) != 1) {
            Rf_error("Map key must be a single character string");
        }
        const char* key_str = CHAR(STRING_ELT(key_or_pos, 0));
        key.src = (uint8_t const *) key_str;
        key.count = strlen(key_str);
    } else {
        if (TYPEOF(key_or_pos) == REALSXP || TYPEOF(key_or_pos) == INTSXP) {
            if (XLENGTH(key_or_pos) != 1) {
                Rf_error("List position must be a scalar");
            }
            int r_pos = Rf_asInteger(key_or_pos);
            if (r_pos < 1) {
                Rf_error("List position must be positive");
            }
            pos = (size_t) (r_pos - 1);
            insert = force_insert;
        } else if (TYPEOF(key_or_pos) == STRSXP && XLENGTH(key_or_pos) == 1) {
            const char* pos_str = CHAR(STRING_ELT(key_or_pos, 0));
            if (strcmp(pos_str, "end") == 0) {
                pos = SIZE_MAX;
                insert = true;
            } else {
                Rf_error("List position must be numeric or \"end\"");
            }
        } else {
            Rf_error("List position must be numeric or \"end\"");
        }
    }

    // Check S3 classes before generic TYPEOF checks (POSIXct is REALSXP, am_counter is INTSXP)
    if (value == R_NilValue) {
        return is_map ? AMmapPutNull(doc, obj_id, key) :
                       AMlistPutNull(doc, obj_id, pos, insert);
    } else if (Rf_inherits(value, "POSIXct")) {
        if (Rf_xlength(value) != 1) {
            Rf_error("Timestamp must be scalar");
        }
        double seconds = REAL(value)[0];
        int64_t milliseconds = (int64_t) (seconds * 1000.0);
        return is_map ? AMmapPutTimestamp(doc, obj_id, key, milliseconds) :
                       AMlistPutTimestamp(doc, obj_id, pos, insert, milliseconds);
    } else if (Rf_inherits(value, "am_counter")) {
        if (TYPEOF(value) != INTSXP || XLENGTH(value) != 1) {
            Rf_error("Counter must be a scalar integer");
        }
        int64_t val = (int64_t) INTEGER(value)[0];
        return is_map ? AMmapPutCounter(doc, obj_id, key, val) :
                       AMlistPutCounter(doc, obj_id, pos, insert, val);
    } else if (Rf_inherits(value, "am_uint64")) {
        if (TYPEOF(value) != REALSXP || XLENGTH(value) != 1) {
            Rf_error("am_uint64 must be a scalar numeric");
        }
        uint64_t val = (uint64_t) REAL(value)[0];
        return is_map ? AMmapPutUint(doc, obj_id, key, val) :
                       AMlistPutUint(doc, obj_id, pos, insert, val);
    } else if (Rf_inherits(value, "am_text_type")) {
        if (TYPEOF(value) != STRSXP || XLENGTH(value) != 1) {
            Rf_error("am_text must be a single character string");
        }

        AMresult *text_result = is_map ?
            AMmapPutObject(doc, obj_id, key, AM_OBJ_TYPE_TEXT) :
            AMlistPutObject(doc, obj_id, pos, insert, AM_OBJ_TYPE_TEXT);

        CHECK_RESULT(text_result, AM_VAL_TYPE_OBJ_TYPE);

        AMitem *text_item = AMresultItem(text_result);
        const AMobjId *text_obj = AMitemObjId(text_item);

        const char *initial = CHAR(STRING_ELT(value, 0));
        size_t initial_len = strlen(initial);

        if (initial_len > 0) {
            AMbyteSpan str_span = {.src = (uint8_t const *) initial, .count = initial_len};
            AMresult *splice_result = AMspliceText(doc, text_obj, 0, 0, str_span);
            if (AMresultStatus(splice_result) != AM_STATUS_OK) {
                AMresultFree(text_result);
                CHECK_RESULT(splice_result, AM_VAL_TYPE_VOID);
            }
            AMresultFree(splice_result);
        }

        return text_result;
    } else if (TYPEOF(value) == LGLSXP && XLENGTH(value) == 1) {
        bool val = (bool) LOGICAL(value)[0];
        return is_map ? AMmapPutBool(doc, obj_id, key, val) :
                       AMlistPutBool(doc, obj_id, pos, insert, val);
    } else if (TYPEOF(value) == INTSXP && XLENGTH(value) == 1) {
        int64_t val = (int64_t) INTEGER(value)[0];
        return is_map ? AMmapPutInt(doc, obj_id, key, val) :
                       AMlistPutInt(doc, obj_id, pos, insert, val);
    } else if (TYPEOF(value) == REALSXP && XLENGTH(value) == 1) {
        double val = REAL(value)[0];
        return is_map ? AMmapPutF64(doc, obj_id, key, val) :
                       AMlistPutF64(doc, obj_id, pos, insert, val);
    } else if (TYPEOF(value) == RAWSXP) {
        AMbyteSpan val = {.src = RAW(value), .count = (size_t) XLENGTH(value)};
        return is_map ? AMmapPutBytes(doc, obj_id, key, val) :
                       AMlistPutBytes(doc, obj_id, pos, insert, val);
    } else if (TYPEOF(value) == VECSXP) {
        AMobjType nested_type;

        if (Rf_inherits(value, "am_list_type")) {
            nested_type = AM_OBJ_TYPE_LIST;
        } else if (Rf_inherits(value, "am_map_type")) {
            nested_type = AM_OBJ_TYPE_MAP;
        } else {
            // Auto-detect: named list = map, unnamed list = list
            SEXP names = Rf_getAttrib(value, R_NamesSymbol);
            nested_type = (names == R_NilValue) ? AM_OBJ_TYPE_LIST : AM_OBJ_TYPE_MAP;
        }

        AMresult *obj_result = is_map ?
            AMmapPutObject(doc, obj_id, key, nested_type) :
            AMlistPutObject(doc, obj_id, pos, insert, nested_type);

        CHECK_RESULT(obj_result, AM_VAL_TYPE_OBJ_TYPE);

        AMitem *obj_item = AMresultItem(obj_result);
        const AMobjId *nested_obj = AMitemObjId(obj_item);
        populate_object_from_r_list(doc, nested_obj, value, obj_result);

        return obj_result;
    } else if (TYPEOF(value) == STRSXP && XLENGTH(value) == 1) {
        const char *str = CHAR(STRING_ELT(value, 0));

        if (Rf_inherits(value, "am_obj_type")) {
            if (strcmp(str, "list") == 0) {
                return is_map ? AMmapPutObject(doc, obj_id, key, AM_OBJ_TYPE_LIST) :
                               AMlistPutObject(doc, obj_id, pos, insert, AM_OBJ_TYPE_LIST);
            } else if (strcmp(str, "map") == 0) {
                return is_map ? AMmapPutObject(doc, obj_id, key, AM_OBJ_TYPE_MAP) :
                               AMlistPutObject(doc, obj_id, pos, insert, AM_OBJ_TYPE_MAP);
            } else if (strcmp(str, "text") == 0) {
                return is_map ? AMmapPutObject(doc, obj_id, key, AM_OBJ_TYPE_TEXT) :
                               AMlistPutObject(doc, obj_id, pos, insert, AM_OBJ_TYPE_TEXT);
            }
        }

        AMbyteSpan val = {.src = (uint8_t const *) str, .count = strlen(str)};
        return is_map ? AMmapPutStr(doc, obj_id, key, val) :
                       AMlistPutStr(doc, obj_id, pos, insert, val);
    }

    Rf_error("Unsupported value type for am_put()");
    return NULL;
}

/**
 * Recursively populate Automerge object from R list.
 *
 * This enables single-call nested object creation:
 *   am_put(doc, AM_ROOT, "user", list(name = "Bob", age = 25L,
 *                                     address = list(city = "NYC")))
 *
 * @param doc The Automerge document
 * @param obj_id The object to populate (must be a list or map)
 * @param r_list The R list with content
 * @param parent_result The AMresult* that owns this object (freed on error)
 */
static void populate_object_from_r_list(AMdoc *doc, const AMobjId *obj_id,
                                         SEXP r_list, AMresult *parent_result) {
    if (TYPEOF(r_list) != VECSXP) {
        if (parent_result) AMresultFree(parent_result);
        Rf_error("Expected R list for nested object population");
    }

    SEXP names;
    PROTECT(names = Rf_getAttrib(r_list, R_NamesSymbol));
    bool is_map = (names != R_NilValue);

    R_xlen_t n = Rf_xlength(r_list);

    for (R_xlen_t i = 0; i < n; i++) {
        SEXP elem = VECTOR_ELT(r_list, i);

        if (is_map) {
            SEXP key_sexp = PROTECT(Rf_ScalarString(STRING_ELT(names, i)));

            AMresult *result = am_put_value(doc, obj_id, key_sexp, true, elem, false);
            if (result) {
                if (AMresultStatus(result) != AM_STATUS_OK) {
                    if (parent_result) AMresultFree(parent_result);
                    CHECK_RESULT(result, AM_VAL_TYPE_VOID);
                }
                AMresultFree(result);
            }

            UNPROTECT(1);
        } else {
            SEXP end_marker = PROTECT(Rf_mkString("end"));

            AMresult *result = am_put_value(doc, obj_id, end_marker, false, elem, false);
            if (result) {
                if (AMresultStatus(result) != AM_STATUS_OK) {
                    if (parent_result) AMresultFree(parent_result);
                    CHECK_RESULT(result, AM_VAL_TYPE_VOID);
                }
                AMresultFree(result);
            }

            UNPROTECT(1);
        }
    }
    UNPROTECT(1);
}

/**
 * Convert AMitem to R value.
 * Handles type conversion from Automerge to R.
 */
static SEXP am_item_to_r(AMitem *item, SEXP parent_doc_sexp, SEXP parent_result_sexp) {
    AMvalType val_type = AMitemValType(item);
    SEXP result;

    switch (val_type) {
        case AM_VAL_TYPE_NULL:
            result = R_NilValue;
            break;

        case AM_VAL_TYPE_BOOL: {
            bool val;
            AMitemToBool(item, &val);
            result = Rf_ScalarLogical(val);
            break;
        }

        case AM_VAL_TYPE_INT: {
            int64_t val;
            AMitemToInt(item, &val);
            result = val > INT_MAX || val < INT_MIN ?
                Rf_ScalarReal((double) val):
                Rf_ScalarInteger((int) val);
            break;
        }

        case AM_VAL_TYPE_UINT: {
            uint64_t val;
            AMitemToUint(item, &val);
            if (val > (1ULL << 53)) {
                Rf_warning("uint64 value exceeds 2^53; precision may be lost");
            }
            result = PROTECT(Rf_ScalarReal((double) val));
            Rf_classgets(result, Rf_mkString("am_uint64"));
            UNPROTECT(1);
            break;
        }

        case AM_VAL_TYPE_F64: {
            double val;
            AMitemToF64(item, &val);
            result = Rf_ScalarReal(val);
            break;
        }

        case AM_VAL_TYPE_STR: {
            AMbyteSpan val;
            AMitemToStr(item, &val);
            result = Rf_ScalarString(Rf_mkCharLen((const char *) val.src, val.count));
            break;
        }

        case AM_VAL_TYPE_BYTES: {
            AMbyteSpan val;
            AMitemToBytes(item, &val);
            result = PROTECT(Rf_allocVector(RAWSXP, val.count));
            memcpy(RAW(result), val.src, val.count);
            UNPROTECT(1);
            break;
        }

        case AM_VAL_TYPE_TIMESTAMP: {
            int64_t val;
            AMitemToTimestamp(item, &val);
            // Convert milliseconds to seconds for POSIXct
            result = PROTECT(Rf_ScalarReal((double) val / 1000.0));

            SEXP classes = Rf_allocVector(STRSXP, 2);
            Rf_classgets(result, classes);
            SET_STRING_ELT(classes, 0, Rf_mkChar("POSIXct"));
            SET_STRING_ELT(classes, 1, Rf_mkChar("POSIXt"));

            UNPROTECT(1);
            break;
        }

        case AM_VAL_TYPE_COUNTER: {
            int64_t val;
            AMitemToCounter(item, &val);
            result = PROTECT(val > INT_MAX || val < INT_MIN ?
                Rf_ScalarReal((double) val):
                Rf_ScalarInteger((int) val));
            Rf_classgets(result, Rf_mkString("am_counter"));
            UNPROTECT(1);
            break;
        }

        case AM_VAL_TYPE_OBJ_TYPE: {
            AMobjId const *obj_id = AMitemObjId(item);
            result = am_wrap_nested_object(obj_id, parent_result_sexp);
            break;
        }

        default:
            Rf_error("Unsupported Automerge value type: %d", val_type);
            result = R_NilValue;
    }

    return result;
}

// Object Operations -----------------------------------------------------------

/**
 * Put a value into a map or list.
 *
 * @param doc_ptr External pointer to am_doc
 * @param obj_ptr External pointer to AMobjId (or NULL for root)
 * @param key_or_pos For maps: character key. For lists: numeric position or "end"
 * @param value R value to insert
 * @return The document pointer (for chaining)
 */
SEXP C_am_put(SEXP doc_ptr, SEXP obj_ptr, SEXP key_or_pos, SEXP value) {
    AMdoc *doc = get_doc(doc_ptr);
    const AMobjId *obj_id = get_objid(obj_ptr);

    bool is_map;
    if (obj_id == NULL) {
        // Root is always a map
        is_map = true;
    } else {
        AMobjType obj_type = AMobjObjType(doc, obj_id);
        is_map = (obj_type == AM_OBJ_TYPE_MAP);
    }

    // insert=false means replace for numeric positions
    AMresult *result = am_put_value(doc, obj_id, key_or_pos, is_map, value, false);

    CHECK_RESULT(result, AM_VAL_TYPE_VOID);

    AMresultFree(result);
    return doc_ptr;
}

/**
 * Get a value from a map or list.
 *
 * @param doc_ptr External pointer to am_doc
 * @param obj_ptr External pointer to AMobjId (or NULL for root)
 * @param key_or_pos For maps: character key. For lists: numeric position (1-based)
 * @return R value
 */
SEXP C_am_get(SEXP doc_ptr, SEXP obj_ptr, SEXP key_or_pos) {
    AMdoc *doc = get_doc(doc_ptr);
    const AMobjId *obj_id = get_objid(obj_ptr);

    AMresult *result;

    if (TYPEOF(key_or_pos) == STRSXP && XLENGTH(key_or_pos) == 1) {
        const char *key_str = CHAR(STRING_ELT(key_or_pos, 0));
        AMbyteSpan key = {.src = (uint8_t const *) key_str, .count = strlen(key_str)};
        result = AMmapGet(doc, obj_id, key, NULL);
    } else if (TYPEOF(key_or_pos) == REALSXP || TYPEOF(key_or_pos) == INTSXP) {
        if (XLENGTH(key_or_pos) != 1) {
            Rf_error("List position must be a scalar");
        }
        int r_pos = Rf_asInteger(key_or_pos);
        if (r_pos < 1) {
            return R_NilValue;
        }
        size_t pos = (size_t) (r_pos - 1);
        result = AMlistGet(doc, obj_id, pos, NULL);
    } else {
        Rf_error("Key must be a character string (map) or numeric (list)");
    }

    // For lists, out-of-bounds returns error but we want to return NULL
    if (AMresultStatus(result) != AM_STATUS_OK) {
        if (TYPEOF(key_or_pos) == REALSXP || TYPEOF(key_or_pos) == INTSXP) {
            AMresultFree(result);
            return R_NilValue;
        }
        CHECK_RESULT(result, AM_VAL_TYPE_VOID);
    }

    AMitem *item = AMresultItem(result);
    if (!item) {
        AMresultFree(result);
        return R_NilValue;
    }

    // VOID type means key/position doesn't exist
    AMvalType val_type = AMitemValType(item);
    if (val_type == AM_VAL_TYPE_DEFAULT || val_type == AM_VAL_TYPE_VOID) {
        AMresultFree(result);
        return R_NilValue;
    }

    SEXP result_sexp = PROTECT(wrap_am_result(result, doc_ptr));
    SEXP r_value = PROTECT(am_item_to_r(item, doc_ptr, result_sexp));

    UNPROTECT(2);
    return r_value;
}

/**
 * Delete a key from a map or position from a list.
 *
 * @param doc_ptr External pointer to am_doc
 * @param obj_ptr External pointer to AMobjId (or NULL for root)
 * @param key_or_pos For maps: character key. For lists: numeric position (1-based)
 * @return The document pointer (for chaining)
 */
SEXP C_am_delete(SEXP doc_ptr, SEXP obj_ptr, SEXP key_or_pos) {
    AMdoc *doc = get_doc(doc_ptr);
    const AMobjId *obj_id = get_objid(obj_ptr);

    AMresult *result;

    if (TYPEOF(key_or_pos) == STRSXP && XLENGTH(key_or_pos) == 1) {
        const char *key_str = CHAR(STRING_ELT(key_or_pos, 0));
        AMbyteSpan key = {.src = (uint8_t const *) key_str, .count = strlen(key_str)};
        result = AMmapDelete(doc, obj_id, key);
    } else if (TYPEOF(key_or_pos) == REALSXP || TYPEOF(key_or_pos) == INTSXP) {
        if (XLENGTH(key_or_pos) != 1) {
            Rf_error("List position must be a scalar");
        }
        int r_pos = Rf_asInteger(key_or_pos);
        if (r_pos < 1) {
            Rf_error("List position must be positive");
        }
        size_t pos = (size_t) (r_pos - 1);
        result = AMlistDelete(doc, obj_id, pos);
    } else {
        Rf_error("Key must be a character string (map) or numeric (list)");
    }

    CHECK_RESULT(result, AM_VAL_TYPE_VOID);

    AMresultFree(result);
    return doc_ptr;
}

/**
 * Get all keys from a map.
 *
 * @param doc_ptr External pointer to am_doc
 * @param obj_ptr External pointer to AMobjId (or NULL for root)
 * @return Character vector of keys
 */
SEXP C_am_keys(SEXP doc_ptr, SEXP obj_ptr) {
    AMdoc *doc = get_doc(doc_ptr);
    const AMobjId *obj_id = get_objid(obj_ptr);

    AMresult *result = AMkeys(doc, obj_id, NULL);
    CHECK_RESULT(result, AM_VAL_TYPE_VOID);

    AMitems items = AMresultItems(result);
    size_t count = 0;
    AMitem *item;
    while ((item = AMitemsNext(&items, 1)) != NULL) {
        count++;
    }

    SEXP keys = PROTECT(Rf_allocVector(STRSXP, count));

    items = AMresultItems(result);
    size_t i = 0;
    while ((item = AMitemsNext(&items, 1)) != NULL) {
        AMbyteSpan key_span;
        if (AMitemToStr(item, &key_span)) {
            SET_STRING_ELT(keys, i, Rf_mkCharLen((const char *) key_span.src, key_span.count));
            i++;
        }
    }

    AMresultFree(result);
    UNPROTECT(1);
    return keys;
}

/**
 * Get the length/size of a map or list.
 *
 * @param doc_ptr External pointer to am_doc
 * @param obj_ptr External pointer to AMobjId (or NULL for root)
 * @return Integer length
 */
SEXP C_am_length(SEXP doc_ptr, SEXP obj_ptr) {
    AMdoc *doc = get_doc(doc_ptr);
    const AMobjId *obj_id = get_objid(obj_ptr);

    size_t size = AMobjSize(doc, obj_id, NULL);  // NULL = current heads

    if (size > INT_MAX) {
        return Rf_ScalarReal((double) size);
    } else {
        SEXP result = PROTECT(Rf_allocVector(INTSXP, 1));
        INTEGER(result)[0] = (int) size;
        UNPROTECT(1);
        return result;
    }
}

/**
 * Insert a value into a list at a specific position.
 *
 * @param doc_ptr External pointer to am_doc
 * @param obj_ptr External pointer to AMobjId (must be a list)
 * @param pos Numeric position (1-based) or "end" string
 * @param value R value to insert
 * @return The document pointer (for chaining)
 */
SEXP C_am_insert(SEXP doc_ptr, SEXP obj_ptr, SEXP pos, SEXP value) {
    AMdoc *doc = get_doc(doc_ptr);
    const AMobjId *obj_id = get_objid(obj_ptr);

    AMobjType obj_type = AMobjObjType(doc, obj_id);
    if (obj_type != AM_OBJ_TYPE_LIST) {
        Rf_error("am_insert() can only be used on list objects");
    }

    // insert=true means insert/shift for numeric positions
    AMresult *result = am_put_value(doc, obj_id, pos, false, value, true);

    CHECK_RESULT(result, AM_VAL_TYPE_VOID);

    AMresultFree(result);
    return doc_ptr;
}

/**
 * Splice text in a text object.
 *
 * @param text_ptr External pointer to AMobjId (must be a text object)
 * @param pos Numeric position (0-based for text operations)
 * @param del_count Number of characters to delete
 * @param text Character string to insert
 * @return The text object pointer (for chaining)
 */
SEXP C_am_text_splice(SEXP text_ptr, SEXP pos, SEXP del_count, SEXP text) {
    SEXP doc_ptr = get_doc_from_objid(text_ptr);
    AMdoc *doc = get_doc(doc_ptr);
    const AMobjId *text_obj = get_objid(text_ptr);

    if (TYPEOF(pos) != INTSXP && TYPEOF(pos) != REALSXP) {
        Rf_error("pos must be numeric");
    }
    if (TYPEOF(del_count) != INTSXP && TYPEOF(del_count) != REALSXP) {
        Rf_error("del_count must be numeric");
    }
    if (TYPEOF(text) != STRSXP || XLENGTH(text) != 1) {
        Rf_error("text must be a single character string");
    }

    int r_pos = Rf_asInteger(pos);
    if (r_pos < 0) {
        Rf_error("pos must be non-negative");
    }
    int r_del = Rf_asInteger(del_count);
    if (r_del < 0) {
        Rf_error("del_count must be non-negative");
    }
    size_t pos_val = (size_t) r_pos;
    size_t del_val = (size_t) r_del;
    const char *text_str = CHAR(STRING_ELT(text, 0));

    AMbyteSpan text_span = {.src = (uint8_t const *) text_str, .count = strlen(text_str)};
    AMresult *result = AMspliceText(doc, text_obj, pos_val, del_val, text_span);

    CHECK_RESULT(result, AM_VAL_TYPE_VOID);

    AMresultFree(result);
    return text_ptr;  // Return text object for chaining
}

/**
 * Get the full text content from a text object.
 *
 * @param text_ptr External pointer to AMobjId (must be a text object)
 * @param heads Optional list of change hashes (or R_NilValue)
 * @return Character string with the full text content
 */
SEXP C_am_text_content(SEXP text_ptr, SEXP heads) {
    SEXP doc_ptr = get_doc_from_objid(text_ptr);
    AMdoc *doc = get_doc(doc_ptr);
    const AMobjId *text_obj = get_objid(text_ptr);

    AMitems heads_items;
    AMresult *heads_result = NULL;
    AMitems *heads_ptr = resolve_heads(heads, &heads_items, &heads_result);

    AMresult *result = AMtext(doc, text_obj, heads_ptr);
    if (heads_result) AMresultFree(heads_result);
    CHECK_RESULT(result, AM_VAL_TYPE_VOID);

    AMitem *item = AMresultItem(result);
    if (!item) {
        AMresultFree(result);
        return Rf_mkString("");
    }

    AMbyteSpan text_span;
    if (!AMitemToStr(item, &text_span)) {
        AMresultFree(result);
        Rf_error("Failed to extract text string");
    }

    SEXP text_sexp = Rf_ScalarString(Rf_mkCharLen((const char *) text_span.src, text_span.count));

    AMresultFree(result);
    return text_sexp;
}

/**
 * Get all values from a map or list.
 *
 * @param doc_ptr External pointer to am_doc
 * @param obj_ptr External pointer to AMobjId (or NULL for root)
 * @return R list of values
 */
SEXP C_am_values(SEXP doc_ptr, SEXP obj_ptr) {
    AMdoc *doc = get_doc(doc_ptr);
    const AMobjId *obj_id = get_objid(obj_ptr);

    AMobjType obj_type = obj_id ? AMobjObjType(doc, obj_id) : AM_OBJ_TYPE_MAP;
    bool is_list = (obj_type == AM_OBJ_TYPE_LIST);

    size_t count = AMobjSize(doc, obj_id, NULL);

    SEXP values = PROTECT(Rf_allocVector(VECSXP, count));

    if (is_list) {
        for (size_t i = 0; i < count; i++) {
            AMresult *result = AMlistGet(doc, obj_id, i, NULL);
            if (AMresultStatus(result) == AM_STATUS_OK) {
                AMitem *item = AMresultItem(result);
                if (item) {
                    SEXP result_sexp = PROTECT(wrap_am_result(result, doc_ptr));
                    SEXP r_value = PROTECT(am_item_to_r(item, doc_ptr, result_sexp));
                    SET_VECTOR_ELT(values, i, r_value);
                    UNPROTECT(2);
                } else {
                    AMresultFree(result);
                }
            } else {
                AMresultFree(result);
            }
        }
    } else {
        AMresult *keys_result = AMkeys(doc, obj_id, NULL);
        if (AMresultStatus(keys_result) != AM_STATUS_OK) {
            AMresultFree(keys_result);
            UNPROTECT(1);
            Rf_error("Failed to get keys");
        }

        AMitems key_items = AMresultItems(keys_result);
        AMitem *key_item;
        size_t i = 0;

        while ((key_item = AMitemsNext(&key_items, 1)) != NULL && i < count) {
            AMbyteSpan key_span;
            if (AMitemToStr(key_item, &key_span)) {
                AMresult *result = AMmapGet(doc, obj_id, key_span, NULL);
                if (AMresultStatus(result) == AM_STATUS_OK) {
                    AMitem *item = AMresultItem(result);
                    if (item) {
                        SEXP result_sexp = PROTECT(wrap_am_result(result, doc_ptr));
                        SEXP r_value = PROTECT(am_item_to_r(item, doc_ptr, result_sexp));
                        SET_VECTOR_ELT(values, i, r_value);
                        UNPROTECT(2);
                    } else {
                        AMresultFree(result);
                    }
                } else {
                    AMresultFree(result);
                }
                i++;
            }
        }

        AMresultFree(keys_result);
    }

    UNPROTECT(1);
    return values;
}

// UTF-8 Helpers for text_splice_diff -----------------------------------------

// Get byte size of UTF-8 code point from its first byte
static inline size_t utf8_char_bytes(unsigned char c) {
    if ((c & 0x80) == 0x00) return 1;  // 0xxxxxxx - ASCII
    if ((c & 0xE0) == 0xC0) return 2;  // 110xxxxx
    if ((c & 0xF0) == 0xE0) return 3;  // 1110xxxx
    if ((c & 0xF8) == 0xF0) return 4;  // 11110xxx
    return 1;  // Invalid byte, advance by 1
}

// Retreat pointer by one code point, return bytes retreated
static inline size_t utf8_prev(const char **p, const char *start) {
    if (*p <= start) return 0;
    const char *orig = *p;
    (*p)--;
    while (*p > start && (**p & 0xC0) == 0x80) (*p)--;
    return orig - *p;
}

/**
 * Compute diff and splice text in a single operation.
 *
 * This is an optimized function for collaborative editing that reads
 * the current text content, computes the minimal diff against new text,
 * and applies it directly, avoiding intermediate R object allocation.
 *
 * @param text_ptr External pointer to AMobjId (must be a text object)
 * @param new_sexp The new text content (single string)
 * @return R_NilValue (called for side effect)
 */
SEXP C_am_text_update(SEXP text_ptr, SEXP new_sexp) {
    if (TYPEOF(new_sexp) != STRSXP || XLENGTH(new_sexp) != 1)
        Rf_error("'new_text' must be a single string");

    SEXP new_elt = STRING_ELT(new_sexp, 0);
    if (new_elt == NA_STRING)
        Rf_error("NA strings not supported");

    SEXP doc_ptr = get_doc_from_objid(text_ptr);
    AMdoc *doc = get_doc(doc_ptr);
    const AMobjId *text_obj = get_objid(text_ptr);

    // Read current text content from the document
    AMresult *text_result = AMtext(doc, text_obj, NULL);
    CHECK_RESULT(text_result, AM_VAL_TYPE_VOID);

    AMitem *text_item = AMresultItem(text_result);
    AMbyteSpan old_span;
    AMitemToStr(text_item, &old_span);

    const char *old_str = (const char *) old_span.src;
    size_t old_bytes = old_span.count;
    const char *new_str = CHAR(new_elt);
    size_t new_bytes = strlen(new_str);

    // Fast path: identical strings
    if (old_bytes == new_bytes && memcmp(old_str, new_str, old_bytes) == 0) {
        AMresultFree(text_result);
        return R_NilValue;
    }

    const char *old_end = old_str + old_bytes;
    const char *new_end = new_str + new_bytes;

    // Find common prefix (count code points)
    const char *old_p = old_str;
    const char *new_p = new_str;
    size_t prefix_cp = 0;

    while (old_p < old_end && new_p < new_end) {
        size_t old_n = utf8_char_bytes((unsigned char)*old_p);
        size_t new_n = utf8_char_bytes((unsigned char)*new_p);

        if (old_p + old_n > old_end) old_n = old_end - old_p;
        if (new_p + new_n > new_end) new_n = new_end - new_p;

        if (old_n != new_n || memcmp(old_p, new_p, old_n) != 0)
            break;

        old_p += old_n;
        new_p += new_n;
        prefix_cp++;
    }

    size_t old_prefix_bytes = old_p - old_str;
    size_t new_prefix_bytes = new_p - new_str;

    // Find common suffix (working backwards)
    const char *old_suf = old_end;
    const char *new_suf = new_end;

    while (old_suf > old_str + old_prefix_bytes &&
           new_suf > new_str + new_prefix_bytes) {
        const char *old_prev = old_suf;
        const char *new_prev = new_suf;

        utf8_prev(&old_prev, old_str);
        utf8_prev(&new_prev, new_str);

        size_t old_n = old_suf - old_prev;
        size_t new_n = new_suf - new_prev;

        if (old_n != new_n || memcmp(old_prev, new_prev, old_n) != 0)
            break;

        old_suf = old_prev;
        new_suf = new_prev;
    }

    // Count code points to delete (between prefix and suffix in old string)
    size_t del_cp = 0;
    const char *p = old_str + old_prefix_bytes;
    while (p < old_suf) {
        size_t n = utf8_char_bytes((unsigned char)*p);
        if (p + n > old_suf) n = old_suf - p;
        p += n;
        del_cp++;
    }

    // Insertion: bytes between prefix and suffix in new string
    size_t ins_start = new_prefix_bytes;
    size_t ins_bytes = new_suf - (new_str + new_prefix_bytes);

    // Done reading old_str, free the text result before splicing
    AMresultFree(text_result);

    AMbyteSpan ins_span = {
        .src = (uint8_t const *)(new_str + ins_start),
        .count = ins_bytes
    };
    AMresult *result = AMspliceText(doc, text_obj, prefix_cp, del_cp, ins_span);

    CHECK_RESULT(result, AM_VAL_TYPE_VOID);
    AMresultFree(result);

    return R_NilValue;
}

/**
 * Increment a counter value
 *
 * @param doc_ptr External pointer to AMdoc
 * @param obj_ptr External pointer to AMobjId (or R_NilValue for AM_ROOT)
 * @param key_or_pos Character string (map) or integer position (list, 1-based)
 * @param delta Integer value to increment by (can be negative)
 * @return The document (invisibly)
 */
SEXP C_am_counter_increment(SEXP doc_ptr, SEXP obj_ptr, SEXP key_or_pos, SEXP delta) {
    AMdoc *doc = get_doc(doc_ptr);
    const AMobjId *obj_id = get_objid(obj_ptr);
    if (TYPEOF(delta) != INTSXP && TYPEOF(delta) != REALSXP) {
        Rf_error("Delta must be numeric");
    }
    if (XLENGTH(delta) != 1) {
        Rf_error("Delta must be scalar");
    }
    int64_t delta_val = (int64_t) Rf_asInteger(delta);

    AMobjType obj_type = obj_id ? AMobjObjType(doc, obj_id) : AM_OBJ_TYPE_MAP;
    bool is_map = (obj_type == AM_OBJ_TYPE_MAP);

    AMresult *result = NULL;

    if (is_map) {
        if (TYPEOF(key_or_pos) != STRSXP || XLENGTH(key_or_pos) != 1) {
            Rf_error("Map key must be a single character string");
        }
        const char *key_str = CHAR(STRING_ELT(key_or_pos, 0));
        AMbyteSpan key = {.src = (uint8_t const *)key_str, .count = strlen(key_str)};

        result = AMmapIncrement(doc, obj_id, key, delta_val);
    } else if (obj_type == AM_OBJ_TYPE_LIST) {
        if (TYPEOF(key_or_pos) != INTSXP && TYPEOF(key_or_pos) != REALSXP) {
            Rf_error("List position must be numeric");
        }
        if (XLENGTH(key_or_pos) != 1) {
            Rf_error("List position must be scalar");
        }

        // Convert from R's 1-based indexing to C's 0-based
        int r_pos = Rf_asInteger(key_or_pos);
        if (r_pos < 1) {
            Rf_error("List position must be >= 1 (R uses 1-based indexing)");
        }
        size_t pos = (size_t) (r_pos - 1);

        result = AMlistIncrement(doc, obj_id, pos, delta_val);
    } else {
        Rf_error("Cannot increment counter in text object");
    }

    CHECK_RESULT(result, AM_VAL_TYPE_VOID);
    AMresultFree(result);

    return doc_ptr;
}

// v1.2 Object Operations -----------------------------------------------------

/**
 * Get all conflicting values at a map key.
 *
 * @param doc_ptr External pointer to am_doc
 * @param obj_ptr External pointer to AMobjId (or NULL for root)
 * @param key Character string key
 * @param heads Optional list of change hashes (or NULL)
 * @return List of all values at the key (including conflicts)
 */
SEXP C_am_map_get_all(SEXP doc_ptr, SEXP obj_ptr, SEXP key, SEXP heads) {
    AMdoc *doc = get_doc(doc_ptr);
    const AMobjId *obj_id = get_objid(obj_ptr);

    if (TYPEOF(key) != STRSXP || XLENGTH(key) != 1) {
        Rf_error("key must be a single character string");
    }
    const char *key_str = CHAR(STRING_ELT(key, 0));
    AMbyteSpan key_span = {.src = (uint8_t const *) key_str, .count = strlen(key_str)};

    AMitems heads_items;
    AMresult *heads_result = NULL;
    AMitems *heads_ptr = resolve_heads(heads, &heads_items, &heads_result);

    AMresult *result = AMmapGetAll(doc, obj_id, key_span, heads_ptr);
    if (heads_result) AMresultFree(heads_result);

    if (AMresultStatus(result) != AM_STATUS_OK) {
        CHECK_RESULT(result, AM_VAL_TYPE_VOID);
    }

    AMitems items = AMresultItems(result);
    size_t count = AMitemsSize(&items);

    SEXP result_sexp = PROTECT(wrap_am_result(result, doc_ptr));
    SEXP list = PROTECT(Rf_allocVector(VECSXP, count));

    for (size_t i = 0; i < count; i++) {
        AMitem *item = AMitemsNext(&items, 1);
        if (!item) break;

        AMvalType val_type = AMitemValType(item);
        if (val_type == AM_VAL_TYPE_DEFAULT || val_type == AM_VAL_TYPE_VOID) {
            continue;
        }

        SEXP r_value = PROTECT(am_item_to_r(item, doc_ptr, result_sexp));
        SET_VECTOR_ELT(list, i, r_value);
        UNPROTECT(1);
    }

    UNPROTECT(2);
    return list;
}

/**
 * Get all conflicting values at a list position.
 *
 * @param doc_ptr External pointer to am_doc
 * @param obj_ptr External pointer to AMobjId
 * @param pos Numeric position (1-based)
 * @param heads Optional list of change hashes (or NULL)
 * @return List of all values at the position (including conflicts)
 */
SEXP C_am_list_get_all(SEXP doc_ptr, SEXP obj_ptr, SEXP pos, SEXP heads) {
    AMdoc *doc = get_doc(doc_ptr);
    const AMobjId *obj_id = get_objid(obj_ptr);

    if (TYPEOF(pos) != INTSXP && TYPEOF(pos) != REALSXP) {
        Rf_error("pos must be numeric");
    }
    if (XLENGTH(pos) != 1) {
        Rf_error("pos must be a scalar");
    }
    int r_pos = Rf_asInteger(pos);
    if (r_pos < 1) {
        Rf_error("pos must be >= 1 (R uses 1-based indexing)");
    }
    size_t c_pos = (size_t) (r_pos - 1);

    AMitems heads_items;
    AMresult *heads_result = NULL;
    AMitems *heads_ptr = resolve_heads(heads, &heads_items, &heads_result);

    AMresult *result = AMlistGetAll(doc, obj_id, c_pos, heads_ptr);
    if (heads_result) AMresultFree(heads_result);

    if (AMresultStatus(result) != AM_STATUS_OK) {
        CHECK_RESULT(result, AM_VAL_TYPE_VOID);
    }

    AMitems items = AMresultItems(result);
    size_t count = AMitemsSize(&items);

    SEXP result_sexp = PROTECT(wrap_am_result(result, doc_ptr));
    SEXP list = PROTECT(Rf_allocVector(VECSXP, count));

    for (size_t i = 0; i < count; i++) {
        AMitem *item = AMitemsNext(&items, 1);
        if (!item) break;

        AMvalType val_type = AMitemValType(item);
        if (val_type == AM_VAL_TYPE_DEFAULT || val_type == AM_VAL_TYPE_VOID) {
            continue;
        }

        SEXP r_value = PROTECT(am_item_to_r(item, doc_ptr, result_sexp));
        SET_VECTOR_ELT(list, i, r_value);
        UNPROTECT(1);
    }

    UNPROTECT(2);
    return list;
}

/**
 * Get a range of map items by key.
 *
 * @param doc_ptr External pointer to am_doc
 * @param obj_ptr External pointer to AMobjId (or NULL for root)
 * @param begin Character string start key (inclusive), "" for unbounded start
 * @param end Character string end key (inclusive), "" for unbounded end
 * @param heads Optional list of change hashes (or NULL)
 * @return Named list of values in the key range
 */
SEXP C_am_map_range(SEXP doc_ptr, SEXP obj_ptr, SEXP begin, SEXP end, SEXP heads) {
    AMdoc *doc = get_doc(doc_ptr);
    const AMobjId *obj_id = get_objid(obj_ptr);

    if (TYPEOF(begin) != STRSXP || XLENGTH(begin) != 1) {
        Rf_error("begin must be a single character string");
    }
    if (TYPEOF(end) != STRSXP || XLENGTH(end) != 1) {
        Rf_error("end must be a single character string");
    }

    const char *begin_str = CHAR(STRING_ELT(begin, 0));
    const char *end_str = CHAR(STRING_ELT(end, 0));
    size_t begin_len = strlen(begin_str);
    size_t end_len = strlen(end_str);

    AMbyteSpan begin_span;
    if (begin_len == 0) {
        begin_span = (AMbyteSpan){.src = NULL, .count = 0};
    } else {
        begin_span = (AMbyteSpan){.src = (uint8_t const *) begin_str, .count = begin_len};
    }

    AMbyteSpan end_span;
    if (end_len == 0) {
        end_span = (AMbyteSpan){.src = NULL, .count = 0};
    } else {
        // AMmapRange uses exclusive end, but R API exposes inclusive end.
        // Extend span by 1 byte to include the C string's null terminator,
        // which sorts after the key itself but before any key with a suffix
        // (e.g., "key\0" > "key" but "key\0" < "keyA"), making the range
        // effectively inclusive of the end key.
        end_span = (AMbyteSpan){.src = (uint8_t const *) end_str, .count = end_len + 1};
    }

    AMitems heads_items;
    AMresult *heads_result = NULL;
    AMitems *heads_ptr = resolve_heads(heads, &heads_items, &heads_result);

    AMresult *result = AMmapRange(doc, obj_id, begin_span, end_span, heads_ptr);
    if (heads_result) AMresultFree(heads_result);

    if (AMresultStatus(result) != AM_STATUS_OK) {
        CHECK_RESULT(result, AM_VAL_TYPE_VOID);
    }

    AMitems items = AMresultItems(result);
    size_t count = AMitemsSize(&items);

    SEXP result_sexp = PROTECT(wrap_am_result(result, doc_ptr));
    SEXP list = PROTECT(Rf_allocVector(VECSXP, count));
    SEXP names = PROTECT(Rf_allocVector(STRSXP, count));

    for (size_t i = 0; i < count; i++) {
        AMitem *item = AMitemsNext(&items, 1);
        if (!item) break;

        // Extract key
        AMbyteSpan key_span;
        if (AMitemKey(item, &key_span)) {
            SET_STRING_ELT(names, i, Rf_mkCharLen((const char *) key_span.src, key_span.count));
        }

        // Extract value
        AMvalType val_type = AMitemValType(item);
        if (val_type != AM_VAL_TYPE_DEFAULT && val_type != AM_VAL_TYPE_VOID) {
            SEXP r_value = PROTECT(am_item_to_r(item, doc_ptr, result_sexp));
            SET_VECTOR_ELT(list, i, r_value);
            UNPROTECT(1);
        }
    }

    Rf_setAttrib(list, R_NamesSymbol, names);
    UNPROTECT(3);
    return list;
}

/**
 * Get a range of list items.
 *
 * @param doc_ptr External pointer to am_doc
 * @param obj_ptr External pointer to AMobjId
 * @param begin Numeric start position (1-based, inclusive)
 * @param end Numeric end position (1-based, exclusive after conversion)
 * @param heads Optional list of change hashes (or NULL)
 * @return List of values in the range
 */
SEXP C_am_list_range(SEXP doc_ptr, SEXP obj_ptr, SEXP begin, SEXP end, SEXP heads) {
    AMdoc *doc = get_doc(doc_ptr);
    const AMobjId *obj_id = get_objid(obj_ptr);

    if (TYPEOF(begin) != INTSXP && TYPEOF(begin) != REALSXP) {
        Rf_error("begin must be numeric");
    }
    if (TYPEOF(end) != INTSXP && TYPEOF(end) != REALSXP) {
        Rf_error("end must be numeric");
    }
    if (XLENGTH(begin) != 1 || XLENGTH(end) != 1) {
        Rf_error("begin and end must be scalars");
    }

    int r_begin = Rf_asInteger(begin);
    int r_end = Rf_asInteger(end);
    if (r_begin < 1) {
        Rf_error("begin must be >= 1 (R uses 1-based indexing)");
    }
    if (r_end < 1) {
        Rf_error("end must be >= 1 (R uses 1-based indexing)");
    }
    size_t c_begin = (size_t) (r_begin - 1);
    size_t c_end = (size_t) r_end;  // Convert R 1-based inclusive to C 0-based exclusive

    AMitems heads_items;
    AMresult *heads_result = NULL;
    AMitems *heads_ptr = resolve_heads(heads, &heads_items, &heads_result);

    AMresult *result = AMlistRange(doc, obj_id, c_begin, c_end, heads_ptr);
    if (heads_result) AMresultFree(heads_result);

    if (AMresultStatus(result) != AM_STATUS_OK) {
        CHECK_RESULT(result, AM_VAL_TYPE_VOID);
    }

    AMitems items = AMresultItems(result);
    size_t count = AMitemsSize(&items);

    SEXP result_sexp = PROTECT(wrap_am_result(result, doc_ptr));
    SEXP list = PROTECT(Rf_allocVector(VECSXP, count));

    for (size_t i = 0; i < count; i++) {
        AMitem *item = AMitemsNext(&items, 1);
        if (!item) break;

        AMvalType val_type = AMitemValType(item);
        if (val_type != AM_VAL_TYPE_DEFAULT && val_type != AM_VAL_TYPE_VOID) {
            SEXP r_value = PROTECT(am_item_to_r(item, doc_ptr, result_sexp));
            SET_VECTOR_ELT(list, i, r_value);
            UNPROTECT(1);
        }
    }

    UNPROTECT(2);
    return list;
}

/**
 * Get full item details from an object.
 *
 * @param doc_ptr External pointer to am_doc
 * @param obj_ptr External pointer to AMobjId (or NULL for root)
 * @param heads Optional list of change hashes (or NULL)
 * @return List of lists, each with key (or index), value, and obj_id fields
 */
SEXP C_am_items(SEXP doc_ptr, SEXP obj_ptr, SEXP heads) {
    AMdoc *doc = get_doc(doc_ptr);
    const AMobjId *obj_id = get_objid(obj_ptr);

    AMitems heads_items;
    AMresult *heads_result = NULL;
    AMitems *heads_ptr = resolve_heads(heads, &heads_items, &heads_result);

    AMobjType obj_type = obj_id ? AMobjObjType(doc, obj_id) : AM_OBJ_TYPE_MAP;
    bool is_map = (obj_type == AM_OBJ_TYPE_MAP);

    AMresult *result;
    if (is_map) {
        AMbyteSpan null_span = {.src = NULL, .count = 0};
        result = AMmapRange(doc, obj_id, null_span, null_span, heads_ptr);
    } else {
        size_t size = AMobjSize(doc, obj_id, heads_ptr);
        result = AMlistRange(doc, obj_id, 0, size, heads_ptr);
    }
    if (heads_result) AMresultFree(heads_result);

    if (AMresultStatus(result) != AM_STATUS_OK) {
        CHECK_RESULT(result, AM_VAL_TYPE_VOID);
    }

    AMitems items = AMresultItems(result);
    size_t count = AMitemsSize(&items);

    SEXP result_sexp = PROTECT(wrap_am_result(result, doc_ptr));
    SEXP list = PROTECT(Rf_allocVector(VECSXP, count));

    for (size_t i = 0; i < count; i++) {
        AMitem *item = AMitemsNext(&items, 1);
        if (!item) break;

        const char *entry_names[] = {"key", "value", ""};
        SEXP entry = PROTECT(Rf_mkNamed(VECSXP, entry_names));

        // Key or index
        if (is_map) {
            AMbyteSpan key_span;
            if (AMitemKey(item, &key_span)) {
                SET_VECTOR_ELT(entry, 0, Rf_ScalarString(
                    Rf_mkCharLen((const char *) key_span.src, key_span.count)));
            }
        } else {
            SET_VECTOR_ELT(entry, 0, Rf_ScalarInteger((int)(i + 1)));
        }

        // Value
        AMvalType val_type = AMitemValType(item);
        if (val_type != AM_VAL_TYPE_DEFAULT && val_type != AM_VAL_TYPE_VOID) {
            SEXP r_value = PROTECT(am_item_to_r(item, doc_ptr, result_sexp));
            SET_VECTOR_ELT(entry, 1, r_value);
            UNPROTECT(1);
        }

        SET_VECTOR_ELT(list, i, entry);
        UNPROTECT(1);
    }

    UNPROTECT(2);
    return list;
}
