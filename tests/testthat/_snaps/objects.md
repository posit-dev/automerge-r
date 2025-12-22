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

