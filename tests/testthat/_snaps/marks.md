# am_mark with invalid am_uint64 errors

    Code
      am_mark(text_obj, 0, 5, "bad", bad_uint)
    Condition
      Error in `am_mark()`:
      ! am_uint64 must be a scalar numeric

---

    Code
      am_mark(text_obj, 0, 5, "bad", bad_uint2)
    Condition
      Error in `am_mark()`:
      ! am_uint64 must be a scalar numeric

# am_marks warns for uint64 exceeding 2^53

    Code
      am_marks(text_obj)
    Condition
      Warning in `am_marks()`:
      uint64 value exceeds 2^53; precision may be lost
    Output
      [[1]]
      [[1]]$name
      [1] "big"
      
      [[1]]$value
      <Automerge uint64: 18014398509481984 >
      
      [[1]]$start
      [1] 0
      
      [[1]]$end
      [1] 5
      
      

# am_marks_at warns for uint64 exceeding 2^53

    Code
      am_marks_at(text_obj, 2)
    Condition
      Warning in `am_marks_at()`:
      uint64 value exceeds 2^53; precision may be lost
    Output
      [[1]]
      [[1]]$name
      [1] "big"
      
      [[1]]$value
      <Automerge uint64: 18014398509481984 >
      
      [[1]]$start
      [1] 0
      
      [[1]]$end
      [1] 5
      
      

