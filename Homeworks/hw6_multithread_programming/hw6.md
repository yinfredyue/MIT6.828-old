## Homework 5 Multithread programming
- Why are there missing keys with 2 or more threads, but not with 1 thread? Identify a sequence of events that can lead to keys missing for 2 threads.  

    `get` would not have synchronization issue as it does not write to the shared data structure. `put`, which inserts entry into the hash table, suffers synchronization. A possible situation when 2 threads are executing `put`:  
    Suppose thread 1 (T1) tries to put the `k1`-th key, thread 2 (T2) tries to put `k2`-th key, and `keys[k1] % NBUCKETS == keys[k2] % NBUCKETS = i`. So they would be in the same bucket.
    ```
            T1                          T2
        put(keys[k1], v1)       put(keys[k2], v2)
            |                           |
    insert(keys[k1], v1,        insert(keys[k2], v2,
        &table[i], table[i])        &table[i], table[i])
            |                           |
        *p = e                      *p = e
    ```
    Suppose `insert` are called at the same time, and thus 2 threads see the same address for `&table[i]` and the same object for `table[i]`. Thus, when executing `insert`:
    ```C
    static void
    insert(int key, int value, struct entry **p, struct entry *n) {
        struct entry *e = malloc(sizeof(struct entry));
        e->key = key;
        e->value = value;
        e->next = n;

        *p = e;
    }
    ```
    Two `struct entry`s are created, but only one gets put at the head of the bucket:
    ```
    +---------+ <------------------------- new_table[i] ??
    |keys[k1] |
    +---------+
    |   v1    |
    +---------+
    |  next   |--> old_table[i]
    +---------+         ^
                        |
    +---------+         |
    |keys[k2] |         |
    +---------+         |
    |   v2    |         |
    +---------+         |
    |  next   |---------+
    +---------+ <------------------------- new_table[i] ??
    ```
    
- To avoid this sequence of events, insert lock and unlock statements in put and get so that the number of keys missing is always 0. Test your code first with 1 thread, then test it with 2 threads. Is it correct (i.e. have you eliminated missing keys?)? Is the two-threaded version faster than the single-threaded version? Modify your code so that get operations run in parallel while maintaining correctness. (Hint: are the locks in get necessary for correctness in this application?) 
    
    Of course lock is not required for `get` but necessary for `put`. So we mainly put lock around `insert`:
    ```C
    static void put(int key, int value) {
        int i = key % NBUCKET;
        
        pthread_mutex_lock(&lock);
        insert(key, value, &table[i], table[i]);
        pthread_mutex_unlock(&lock);
    }
    ```
    Output for table lock:
    ```console
    $ ./ph 1                                                 
    0: put time = 0.013025
    0: get time = 10.292560
    0: 0 keys missing
    completion time = 10.337660
    $ ./ph 2
    0: put time = 0.016728
    1: put time = 0.021675
    1: get time = 10.406915
    1: 0 keys missing
    0: get time = 10.407231
    0: 0 keys missing
    completion time = 10.630444
    ```

- Modify your code so that some put operations run in parallel while maintaining correctness. (Hint: would a lock per bucket work?)
    Per-bucket lock, faster:
    ```console
    $ ./ph 2
    0: put time = 0.024664
    1: put time = 0.025263
    0: get time = 9.612301
    0: 0 keys missing
    1: get time = 9.612354
    1: 0 keys missing
    completion time = 9.733351
    ```