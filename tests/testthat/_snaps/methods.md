# print() displays document info

    Code
      print(doc)
    Output
      <Automerge Document>
      Actor: <ACTOR_ID> 
      Root keys: 2 
      Keys: name, value 

# str() displays document structure

    Code
      str(doc)
    Output
      active: true
      age: 30
      name: "Alice"

# str() displays nested structures

    Code
      str(doc)
    Output
      user: {object}
        age: 25
        name: "Bob"

# str() respects max.level parameter

    Code
      str(doc, max.level = 3)
    Output
      level1: {object}
        level2: {object}
          level3: "deep"
    Code
      str(doc, max.level = 1)
    Output
      level1: {object}
        level2: {object}
          ...

# str() shows truncation indicator at max.level

    Code
      str(doc, max.level = 0)
    Output
      nested: {object}
        ...

# str() handles empty document

    Code
      str(doc)
    Output
      (empty)

# str() handles lists with many items

    Code
      str(doc)
    Output
      items: [list, length 10]
        [1]: integer 
        [2]: integer 
        [3]: integer 
        [4]: integer 
        [5]: integer 
        ... and 5 more items

# str() truncates long strings

    Code
      str(doc)
    Output
      long: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx..."

# str() handles list with character items

    Code
      str(doc)
    Output
      tags: [list, length 3]
        [1]: "alpha"
        [2]: "beta"
        [3]: "gamma"

# str() truncates long character items in lists

    Code
      str(doc)
    Output
      items: [list, length 1]
        [1]: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"...

# str() handles list with nested am_object items

    Code
      str(doc)
    Output
      users: [list, length 2]
        [1]: {object}
          age: 30
          name: "Alice"
        [2]: {object}
          age: 25
          name: "Bob"

# str() handles list with non-character, non-object items

    Code
      str(doc)
    Output
      numbers: [list, length 3]
        [1]: integer 
        [2]: integer 
        [3]: integer 

# str() respects max.level for nested objects in lists

    Code
      str(doc, max.level = 4)
    Output
      items: [list, length 1]
        [1]: {object}
          nested: {object}
            deep: "value"
    Code
      str(doc, max.level = 1)
    Output
      items: [list, length 1]
        [1]: {object}
          nested: {object}
            ...

# str() shows ellipsis for am_list at max.level

    Code
      str(doc, max.level = 1)
    Output
      data: {object}
        items: [list, length 3]
          ...

# str() displays raw bytes with class name

    Code
      str(doc)
    Output
      data: <raw>

# str() handles NULL values

    Code
      str(doc)
    Output
      empty: NULL

# print() displays am_object info (map)

    Code
      print(user)
    Output
      <Automerge Map>
      Length: 2 
      Keys: age, name

# print() displays am_object info (list)

    Code
      print(items)
    Output
      <Automerge List>
      Length: 3 

# print() displays am_object info (text)

    Code
      print(text_obj)
    Output
      <Automerge Text>
      Length: 13 characters
      Content: "Hello, world!" 

# print() handles very long text with truncation

    Code
      print(text_obj)
    Output
      <Automerge Text>
      Length: 100 characters
      Content: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa..." 

# print() displays map with many keys truncated

    Code
      print(map_obj)
    Output
      <Automerge Map>
      Length: 7 
      Keys: a, b, c, d, e, ...

# print() handles empty document

    Code
      print(doc)
    Output
      <Automerge Document>
      Actor: <ACTOR_ID> 
      Root keys: 0 

# print() handles document with many keys

    Code
      print(doc)
    Output
      <Automerge Document>
      Actor: <ACTOR_ID> 
      Root keys: 100 
      Keys: key1, key10, key100, key11, key12, key13, key14, key15, key16, key17, key18, key19, key2, key20, key21, key22, key23, key24, key25, key26, key27, key28, key29, key3, key30, key31, key32, key33, key34, key35, key36, key37, key38, key39, key4, key40, key41, key42, key43, key44, key45, key46, key47, key48, key49, key5, key50, key51, key52, key53, key54, key55, key56, key57, key58, key59, key6, key60, key61, key62, key63, key64, key65, key66, key67, key68, key69, key7, key70, key71, key72, key73, key74, key75, key76, key77, key78, key79, key8, key80, key81, key82, key83, key84, key85, key86, key87, key88, key89, key9, key90, key91, key92, key93, key94, key95, key96, key97, key98, key99 

# print() handles very long key names

    Code
      print(doc)
    Output
      <Automerge Document>
      Actor: <ACTOR_ID> 
      Root keys: 1 
      Keys: key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key_key 

# print.am_counter displays counter value

    Code
      print(counter)
    Output
      <Automerge Counter: 10 >

# print.am_object displays generic object message

    Code
      print(obj)
    Output
      <Automerge Object>

# print.am_cursor displays cursor info

    Code
      print(cursor)
    Output
      <Automerge Cursor>

# print.am_syncstate displays sync state info

    Code
      print(sync_state)
    Output
      <Automerge Sync State>

