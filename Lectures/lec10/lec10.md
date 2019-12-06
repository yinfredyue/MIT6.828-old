# Lecture 10

## Discussion on HW 7
- What does `idelock` protect?  

    `idequeue`.

- What goes wrong with adding `sti`/`cli` in `iderw`?

    When an IDE interrupt goes off, trap would dispatch to `ideintr`, the interrupt handler. `ideintr` would try to acquire the `idelock`.   
    Suppose in `iderw` we re-enable interrupts after acquired the `idelock`, and the IDE interrupt goes off before we release the lock, `ideintr` tries to acquire the `idelock`, but finds out that the CPU is already holding the same lock(`holding()` returns true if the cpu is already holding the lock), and would panic.  

- What would happen if `acquire` does not do `holding()` and `panic()`?  

    While `iderw` is holding the `idelock`, IDE interrupt goes off, `ideintr` takes over and tries to acquire the `idelock`. But the lock is already held by `iderw` and thus the interrupt handler waits. Note that as `idelock` is a spin-lock, this execution just hangs!

- What happens to the interrupt in the original code? This means if we disable interrupt when acquiring the lock, and checks for reacquiring the same lock on the same CPU.  

    A little knowledge of how CPU detects interupts. There's a interrupt line the CPU that gets written to whenever an interrupt goes off. Before each instruction fetch/decode, CPU would lookup the interrupt and see if there's any interrupt that needs to be served. Disabling interrupt with `cli()` means the step of checking interrupt line is not performed, but the interrupt line is still written to when any interrupt goes off.  

    In the original `iderw`, we turn off interrupt, acquires lock, does whatever we need to do, release the lock and re-enables interrupt. Suppose during the time being, an IDE interrupt goes off. Then after enabling the interrupt, the CPU would look up the interrupt line and see it. We would not lose the interrupt.  

    One thing you should keep in mind is that: you can only retrieve the latest unserved interrupt, but you have no information about previous ones (if any) as it just gets overwritten. This is consistent with what you leared in CSAPP.     

- What if IDE interrupt had occured on a different core?  

    CPU 0 turns off interrupt on its own CPU, acquries `idelock` in `iderw`. Before CPU 0 releases the lock, an IDE interrupt goes off in CPU 1, calls `acquire`, `holding()` evaluates to true, and spin-waits for CPU 0 to releases the lock, which would eventually happens. This is the behavior we want.  

- `release` would not directly re-enable interrupts. `pushcli` and `popcli` keeps a count. Only re-enable interrupt when the count reaches zero.  


## Scheduling Goals
- Transparent to user process
- Preemptive for user process
- Preemptive for kernel, to improve responsive

## xv6 Design
- 1 user thread and 1 kernel thread per process
- 1 scheduler per CPU

Note that this means you cannot have multi-threaded user program in xv6.  

## xv6 context switch scheme
- User thread -> kernel thread, through system call or interrupt
- kernel thread -> scheduler thread, by cooperative yielding, `yield`  
- scheduler thread finds a RUNNABLE thread
- scheduler thread -> kernel thread
- kernel thread -> user thread  

You can examine the behavior from code. Tn `trap.c`, which handles system calls and interrupts. `trap()` calls `yield()`, which calls `sched()`. `sched` switches to scheduler thread by `swtch(&p->context, mycpu()->scheduler);`, and `scheduler()` gets executed. `scheduler` would finds a RUNNABLE thread and execute by `swtch(&(c->scheduler), p->context);`.  
What happens after that? `swtch` returns to the last line of `sched` in another kernel thread (read the part about co-routine in xv6 book). Then `sched` returns, `yield` returns, and `trap` returns, then `trapret` gets called, and the user thread gets resumed.  

### Aside
Finally, this completes the picture and answers the crazy, important question: why we save registers twice when switching between processes? Let's go through the entire process together, I am so excited :)!  
When a process makes a system call or gets timer interrupted, this is a trap operation as the kernel needs to take over. So you are saving trapframe on the kernel stack and `trap` would be called. One possibility of `trap()` is that `yield()` gets called. `yield()` calls `sched()`, which calls `swtch` to switch to the scheduler thread. As another kernel thread would be scheduled, the context of the original kernel thread must be saved for future resumption. `Swtch` saves the context, switches stack, restores the context by popping off the kernel stack, and return to the new kernel thread by `ret`. Now we need to return to the new user process: `sched` returns, `yield` returns, `trap` returns, `trapret` restores register values from the trapframe, and another use process is resumed!


## `swtch`
A `struct context` holds the saved registers of a non-executing **kernel thread**. In xv6, contexts are alwasy saved on top of the kernel stack. The %esp is effectively a pointer to the `struct context`.  

```C
struct context {
    uint edi;
    uint esi;
    uint ebx;
    uint ebp;
    uint eip;
};
```
When saved on the kernel stack, it should looks like:
```
|   ...     |
+-----------+
|   eip     |
+-----------+
|   ebp     |
+-----------+
|   ebx     |
+-----------+
|   esi     |
+-----------+
|   edi     | <-- %esp
+-----------+
```

Code for `swtch`:
```
# Context switch
#
#   void swtch(struct context **old, struct context *new);
# 
# Save the current registers on the stack, creating
# a struct context, and save its address in *old.
# Switch stacks to new and pop previously-saved registers.

.globl swtch
swtch:
  movl 4(%esp), %eax    # Move 1st argument, **old, into %eax
  movl 8(%esp), %edx    # Move 2nd argument, *new, into %edx

  # Save old callee-saved registers
  pushl %ebp
  pushl %ebx
  pushl %esi
  pushl %edi

  # Switch stacks
  movl %esp, (%eax)
  movl %edx, %esp

  # Load new callee-saved registers 
  popl %edi
  popl %esi
  popl %ebx
  popl %ebp
  ret
```
1. Why the context does not include registers like eax, ecx, edx?

    `swtch` would only be called in kernel code in a cooperative approach, in `yield()` or `scheduler()`, and all kernel code are following the gcc calling convention: caller-saved registers can be manipulated in any way, so they do not need to be saved.  

2. Why `swtch` does not save eip?

    %eip would be automatically pushed onto the kernel stack when the kernel thread makes a fucntion call. This is, again, part of the gcc calling convention.

3. How `swtch` works?

    When executing on the original kernel stack, registers are saved to construct a context. Then the stack is switched. On the new stack, the context of its caller is saved. Thus, restore the context with `popl`. Note that eip is implicitly restored with `ret`: it pops the top of the stack into eip.

4. `swtch` returns to another kernel thread, not to the original one!

    In the following code from `scheduler()`:
    ```C
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;

      c->proc = p;
      switchuvm(p);   // Switch to user address space by setting %cr3
      p->state = RUNNING;
      swtch(&(c->scheduler), p->context); // context switch
      switchkvm();  // Switch to kernel stack
      c->proc = 0;
    }
    ```
    `swtch` would switches to the RUNNABLE thread selected. The next line **of this thread**, `switchkvm();` would be executed when this thread is being selected again by the scheduler.  

5. Why does scheduler releases the lock after loop, and re-acquire it immediately?  

    So that the scheduler threads on other proceses can acquire `ptable.lock` and do the scheduling work.  

6. Why does scheduler briefly enables interrupt?

    Some processes are marked as SLEEPING but not RUNNABLE since they are waiting for I/O. Enable interrupts so devices could signal the completion and change the process's state from SLEEPING to RUNNABLE.  

7. Why `ptable.lock` are acquired in one thread but released in another thread?  

    Main idea: protect the invariant. Read xv6 book section *Code: Scheduling*. 

8. sched() and scheduler() are *co-routines*  
   Caller knows what it is swtch()ing to, callee knows where switch is coming from. So, yield() and scheduler() cooperate about `ptable.lock`. This is different from ordinary thread switching, where neither party knows which thread comes before/after.  

9. Is there pre-emptive scheduling of kernel threads? What if timer interrupt while executing in the kernel? What does kernel thread stack look like in that case?  

    In xv6, a kernel thread can be interrupted.  
    When a user thread makes a system call and switches to a kernel thread, the kernel thread looks like:
    ```
    |   ...     |
    +-----------+
    | trapframe |
    +-----------+
    ```
    When interrupt handler executes, some local variables reside on the stack:
    ```
    |   ...     |
    +-----------+
    | trapframe |
    +-----------+
    | local_vars|
    +-----------+
    ```
    Suppose now the kernel thread is interrupted, another trapframe would be pushed onto the kernel stack by hardware. Different from the one when switching from user mode to kernel mode, this trapframe would not include %esp and %ss.
    ```
    |   ...     |
    +-----------+
    | trapframe |
    +-----------+
    | local_vars|
    +-----------+
    | trapframe |
    +-----------+
    ```
    Again, local variables when executing in kernel mode:
    ```
    |   ...     |
    +-----------+
    | trapframe |
    +-----------+
    | local_vars|
    +-----------+
    | trapframe |
    +-----------+
    | local_vars|
    +-----------+
    ```
    And then `trap` calls `yield`, then `sched`, then `swtch`. `swtch` would push the context onto the kernel thread, and switches to the scheduler thread.  
    ```
    |   ...     |
    +-----------+
    | trapframe |
    +-----------+
    | local_vars|
    +-----------+
    | trapframe |
    +-----------+
    | local_vars|
    +-----------+
    | context   |
    +-----------+
    ```
Read the part on `swtch` on xv6 book very carefully. Very good explanation.

## Thread Cleanup
Check lecture note.  
`kill` marks the thread `p->killed = 1`, and `trap()` would calls `exit()`. `Exit()` would wake up any waiting parent, pass abandoned child to init, mark the current thread as ZOMBIE and calls `sched`, which switches to the scheduler. The scheduler would never tries to run this thread because its state is ZOMBIE.   

But where does the killed process's resources get freeed? Only in `wait()`. If the parent does not wait, then those ZOMBIE threads would be pass again to `init` and gets waited by `init`.