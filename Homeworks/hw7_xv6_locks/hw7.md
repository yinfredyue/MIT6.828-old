## HW 7 xv6 locks

### Don't do this
Make sure you understand what would happen if the xv6 kernel executed the following code snippet:
```C
struct spinlock lk;
initlock(&lk, "test lock");
acquire(&lk);
acquire(&lk);
```
Explain in one sentence what happens.

- Original startup output:
    ```
    ...
    cpu1: starting 1
    cpu0: starting 0
    sb: size 1000 nblocks 941 ninodes 200 nlog 30 logstart 2 inodestart 32 bmap start 58
    ...
    ```


- `mpmain` is the last function in `main()` in `main.c`, put the code above into the function.
    ```C
    // Common CPU setup code.
    static void
    mpmain(void)
    {
        cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
        idtinit();       // load idt register
        xchg(&(mycpu()->started), 1); // tell startothers() we're up

        struct spinlock lk;
        initlock(&lk, "test lock");
        acquire(&lk);
        acquire(&lk);

        scheduler();     // start running processes
    }
    ```
    New output:
    ```
    ...
    cpu1: starting 1
    lapicid 1: panic: acquire
    80104431 80102e9a 80102eba 705a 0 0 0 0 0 0
    ```

    Definition for `acquire`:
    ```C
    void
    acquire(struct spinlock *lk)
    {
        pushcli(); // disable interrupts to avoid deadlock.
        if(holding(lk))
            panic("acquire");

        // The xchg is atomic.
        while(xchg(&lk->locked, 1) != 0)
            ;

        // Tell the C compiler and the processor to not move loads or stores
        // past this point, to ensure that the critical section's memory
        // references happen after the lock is acquired.
        __sync_synchronize();

        // Record info about lock acquisition for debugging.
        lk->cpu = mycpu();
        getcallerpcs(&lk, lk->pcs);
    }
    ```
    Clearly, `holding(lk)` evaluates to true and the kernel panics.

From xv6 book: 
> Spin-locks are used in xv6. Interrupts can cause concurrency even on a single processor: if interrupts are enabled, kernel code can be stopped at any moment to run an interrupt handler instead. Suppose an interrupt happens when the kernel code is holding a lock, and the interrupt handler needs to acquire the lock. Then the system deadlocks.  
> To avoid the situation, if a spin-lock is used by an interrupt handler, then the kernel code should never hold that lock with that interrupt enabled. In xv6, when a processor enters a critical section protected by a spin-lock, xv6 ensures that all interrupts are disabled on the processor.  
> Thus, it is important for `acquire` to call `pushcli` before `xchg` that might acquire the lock, and for `release` to call `popcli` only after `xchg`.  

- Let's see what happens if we turn on interrupts while holding the ide lock. In `iderw` in `ide.c`, add a call to `sti()` after the `acquire()`, and a call to `cli()` just before the `release()`. Rebuild the kernel and boot it in QEMU. Chances are the kernel will panic soon after boot; try booting QEMU a few times if it doesn't. Explain in a few sentences why the kernel panicked. You may find it useful to look up the stack trace (the sequence of %eip values printed by panic) in the `kernel.asm` listing.  
    
    You need to do this exercise in virtual machine but not WSL.  
    Before adding the code:
    ```
    cpu1: starting 1
    cpu0: starting 0
    sb: size 1000 nblocks 941 ninodes 200 nlog 30 logstart 2 inodestart 32 bmap start 58
    init: starting sh
    $ 
    ```
    After adding the code, different situations could happen.  

    - Situation 1
        ```
        cpu1: starting 1
        cpu0: starting 0
        sb: size 1000 nblocks 941 ninodes 200 nlog 30 logstart 2 inodestart 32 bmap start 58
        init: starting sh
        lapicid 1: panic: acquire
        80104421 801020a3 801059ed 8010570f 80100183 801019ea 80100a5e 801053c0 80104899 801058fd
        ```
        Read traceback with `kernel.asm`, note that %eip is the address of **next** instruction, not the current instruction.  
        We can see the panic comes from `panic` in `acquire`, called from `acquire(&idelock)` in `ideintr`, the interrupt handler, called in `trap.c/trap`  

        ```
        trap => syscall => exec => readi => bread => iderw => trap.c/trap => ideintr() => acquire(&idelock) => panic
        ```
        After printing out `init: starting sh`, `init` calls `exec`, which calls `readi`, which calls `bread`, which calls `iderw`, which calls `acquire` but still enables interrupt. Then interrupt occurs and interrupt handler takes on, tries to acquire lock, but in the same process and `holding` evaluates to `true` and `acquire` would panic.

    - Situation 2
        ``` 
        cpu1: starting 1
        cpu0: starting 0
        sb: size 1000 nblocks 941 ninodes 200 nlog 30 logstart 2 inodestart 32 bmap start 58
        lapicid 1: panic: acquire
        80104421 801020a3 801059ed 8010570f 80100183 801019ea 80101bf2 80101d5b 80101f03 80100a37
        ```
        ```
        panic <= acquire <= ideintr <= trap <= iderw <= bread <= readi <= dirlookup <= namex <= namei
        ```
        `exec.c/exec: if((ip = namei(path)) == 0)`, calls `namex`, calls `dirlookup`, calls `readi`, which calls `bread`, which calls `iderw`, which calls `acquire` but still enables interrupt. Then interrupt occurs and interrupt handler takes on, tries to acquire lock, but in the same process and `holding` evaluates to `true` and `acquire` would panic.

    - Situation 3
        ```
        cpu1: starting 1
        cpu0: starting 0
        lapicid 0: panic: sched locks
        80103c01 80103d72 80105923 8010570f 80100183 80101465 801014df 80103714 80105712 0
        ```
        ```
        panic <= sched <= yield <= trap <= _alltraps <= iderw <= bread <= readsb <= iinit <= forkret
        ```
        While executing `iderw`, after lock has been acquired, with interrupt enabled, timer interrupt goes off, `trap` called, force yielding CPU by `yield`. `yield` acquires `ptable.lock` and calls `sched`. However, `sched` assumes that only one lock should be held when being called by checking `if(mycpu()->ncli != 1)` and panics if not. 

        This is also explained by solution at: https://github.com/batmanW1/6.828-1/blob/master/hw7/solution.md

- Explain in a few sentences why the kernel didn't panic. Why do `file_table_lock` and `ide_lock` have different behavior in this respect?  

    Check solution at: https://github.com/batmanW1/6.828-1/blob/master/hw7/solution.md

- Why does `release()` clear `lk->pcs[0]` and `lk->cpu` before clearing `lk->locked`? Why not wait until after?  

    Race condition. In order to avoid inconsistent state.