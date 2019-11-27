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

- Let's see what happens if we turn on interrupts while holding the ide lock. In `iderw` in `ide.c`, add a call to `sti()` after the `acquire()`, and a call to `cli()` just before the `release()`. Rebuild the kernel and boot it in QEMU. Chances are the kernel will panic soon after boot; try booting QEMU a few times if it doesn't. Explain in a few sentences why the kernel panicked. You may find it useful to look up the stack trace (the sequence of %eip values printed by panic) in the kernel.asm listing.  

    Check solution at: https://github.com/batmanW1/6.828-1/blob/master/hw7/solution.md

- Explain in a few sentences why the kernel didn't panic. Why do `file_table_lock` and `ide_lock` have different behavior in this respect?  

    Check solution at: https://github.com/batmanW1/6.828-1/blob/master/hw7/solution.md

- Why does `release()` clear `lk->pcs[0]` and `lk->cpu` before clearing `lk->locked`? Why not wait until after?  

    Race condition. In order to preserve the locking invariant.