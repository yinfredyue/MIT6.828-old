## HW5 CPU Alarm
A very important Homework! Requires a thorough understanding of the mechanisms invloved in system call and trap handler.  

Most of the code you write for this homework is very similar to HW3 system call, except the several lines in `trap.c`.  

Files modified:
```
Makefile   
proc.h     
syscall.c 
syscall.h  
sysproc.c  
trap.c    
user.h     
usys.S     
```
 
Make sure you read Chapter 3 of xv6 book carefully and fully understand the mechanisms involved in printing a prompt (`INT`, `handler entry`, `vector`, `alltraps`, `trap.c` kernel code, `trapret`).

`trap.c`:  

```C
case T_IRQ0 + IRQ_TIMER:  // hardware clock tick handler
    if(cpuid() == 0){
      acquire(&tickslock);
      ticks++;
      wakeup(&ticks);
      release(&tickslock);
    }
    
    // HW5 system alarm
    if(myproc() != 0 && (tf->cs & 3) == 3) {  
      // Ensure the process is running, in user space
      myproc()->passedticks += 1;
      // cprintf("%d\n", myproc()->passedticks);
      if (myproc()->passedticks == myproc()->alarmticks) {
        
        myproc()->passedticks = 0;
      
        // myproc()->alarmhandler();
        /**
         * Should not do so!
         * Reason:
         * 1. We can jump from kernel code to user code directly, because the 
         * kernel code is also mapped in the application address space. This is
         * convenient.
         * 2. But alarmhandler() is a user function, which should execute
         * in user mode and opearting on user stack. However here, when called,
         * the stack would not be switched to user stack -- the user code
         * execute on and can modify the kernel stack! This is horrible!
         * 3. The alarmhandler, periodic(), calls system call, write(). So INT
         * is invoked from within the kernel! What would happen?
         * 
         * INT traps into kernel, constructs the trapframe. And enters trap()
         * in trap.c again, syscall() is invoked to call sys_write(), reading
         * input argument with argint(), which calls fetchint()...
         * 
         * The problem! argint() calls fetchint, which uses 
         * ( myproc()->tf->esp) + 4 + 4*n ) as the address for argument. However,
         * we are invoking system call within the kernel mode, so %ss and %esp
         * are not pushed into the trapframe this time! What would be the value?
         * 
         * Anything that happens to be there! In this case the result is not
         * too bad, and you see the program does not crash but just does not
         * print out the expected string, probably because the input argument
         * does not pass the check and syscall just aborts. But you can image 
         * how bad things can go wrong.
         * 
         * In summary, the source of the problem is that, user code/function 
         * should not be invoked within the kernel mode! 
         * 
         * Correct method to invoke the user handler:
         * Switch to user mode (by returning from the kernel code), executes 
         * the handler, and resumes from where the user code is interrupted.
         * After return from kernel mode, user code resumes from tf->eip, so 
         * we should set tf->esp to be myproc()->alarmhander. But how to make
         * user resume where it was interrupted after the handler finishes?
         * 
         * Note that here we are directly setting the %eip, but not calling it
         * like a normal function using the `call` instruction. So we should 
         * construct the user stack to mimic the behavior of call. We just need
         * to push the address of the instrction to be resumed to the user stack.
         * And when `ret` is called in the handler, it pops the top of stack
         * into %eip to resume execution.
         */
        tf->esp -= 4;
        *(uint *)(tf->esp) = tf->eip;

        tf->eip = (uint)myproc()->alarmhandler;
      }
    }

    lapiceoi();
    
    break;
```

It is disturbing how close this came to working!  
- why can kernel code directly jump to user instructions?
- why can user instructions modify the kernel stack?
- why do system calls (INT) work from the kernel?  

None of these are intended properties of xv6! The x86 h/w does *not* directly provide isolation. x86 has many separate features (page table, INT, &c), so it's possible to configure these features to enforce isolation, but isolation is not the default!

### User mode check 
Checking `(tf->cs & 3) == 3` is also important, since %ss and %esp would not be pushed to the kernel stack because there is no stack switch. Thus, when executing `*(uint *)(tf->esp) = tf->eip;`, `tf->esp` points to gargage value.  
Interrupt could happen while in the kernel in xv6! (though not in JOS). 