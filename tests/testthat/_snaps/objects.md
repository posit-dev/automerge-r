# am_uint64() warns for precision loss

    Code
      am_uint64(2^54)
    Condition
      Warning in `am_uint64()`:
      Value exceeds 2^53; precision may be lost
    Output
      <Automerge uint64: 18014398509481984 >

# print.am_uint64 displays value correctly

    Code
      print(am_uint64(12345))
    Output
      <Automerge uint64: 12345 >

---

    Code
      print(am_uint64(0))
    Output
      <Automerge uint64: 0 >

---

    Code
      print(am_uint64(2^50))
    Output
      <Automerge uint64: 1125899906842624 >

# am_put with invalid am_uint64 errors

    Code
      am_put(doc, AM_ROOT, "bad", bad_uint)
    Condition
      Error in `am_put()`:
      ! am_uint64 must be a scalar numeric

---

    Code
      am_put(doc, AM_ROOT, "bad", bad_uint2)
    Condition
      Error in `am_put()`:
      ! am_uint64 must be a scalar numeric

# am_get warns for uint64 exceeding 2^53

    Code
      am_get(doc, AM_ROOT, "big")
    Condition
      Warning in `am_get()`:
      uint64 value exceeds 2^53; precision may be lost
    Output
      <Automerge uint64: 18014398509481984 >

# am_values warns for uint64 exceeding 2^53

    Code
      am_values(doc, AM_ROOT)
    Condition
      Warning in `am_values()`:
      uint64 value exceeds 2^53; precision may be lost
    Output
      [[1]]
      <Automerge uint64: 18014398509481984 >
      

