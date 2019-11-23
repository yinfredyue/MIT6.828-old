## Lecture 8

### 1. Reading xv6 book Chapter 3
#### System call, exception and interrupt
In xv6, system call, exception and interrupts are handled by a single hardware mechanism. On x86, a program invokes a system call by generating an interrupt using the `INT` instruction. Exception also generates interrupt. Thus, if the system can handle interruptes, then it can handle system call and exceptions as well.  

#### What happens when `INT n` is executed, revisited
- Find the n's descriptor from the interrupte descriptor table (IDT)  
- Check that CPL (from %cs) is smaller than DPL (descriptor privilege level).  
- If switching mode, push %ss and %esp onto kernel stack.  
- Push %eflags, %cs, %eip.  
- Set %cs, %eip to the value in the descriptor

#### Code: Assembly trap handler
x86 allows 256 different interrupt handlers.   
- 0-31: software exception (division by zero, invalid memory access).  
- 32-63: hardware interrupt.
- 64: system call interrupt.

`main.c`, `main()` calls `tvinit()` to set up entries in IDT with `SETGATE`. The entry for system call is handled differently.  

When changing from user mode to kernel mode, the kernel should use kernel stack instead of user stack as the user stack could have been corrupted. Xv6 program the hardware to switch stack on trap, by setting up a task segment descriptor from which the hardware loads a stack segment selector and a new value for %esp.  

When a trap happens, the hardware does the following. If the processor was executing in user mode, push %ss and %esp to the kernel stack and load new value for %ss and %esp from the task segment descriptor. If the processor was executing in kernel mode, none of the above happens. Then it pushes %eflags, %cs and %eip registers. For some traps, the error code is also pushed to the kernel stack. The processor then loads %eip and %cs from the relevant IDT entry.  

At IDT entry point, push error code if the processor has not, and push the interrupt number. Then jump to `alltraps`.  

`Alltraps` saves more registers to the kernel stack. At this points, all the values that have been pushed onto the kernel stack completes a `struct trapframe`. The trapframe contains all necessary information to restore the user mode registers and resume user program when the trap return. In `userinit`, a similar trapframe is construcuted by hand.  

After finish saving user-mode registers, `alltraps` can setup the processor to run kernel C code. The processor set the selectors %cs and %ss before entering the handler; `alltraps` sets %ds and %es. Then `alltraps` pushes the %esp to the kernel stack as argument and the handler `trap` is called. After `trap` returns, registers are restored and `iret` jumps to user space.  

#### Code: C trap handler
`Trap` uses `tf->trapno` to determine the trap No. If the trap is `T_SYSCALL`, then `syscall` is invoked. Then `trap` checks for hardware interrupt. If the interrupt is not a system call nor a hardware interrupt, xv6 assumes it to be illegal behavior.

#### Code: system calls
For system call, `trap` invokes `syscall()`.  
The n-th argument to the system call can be found with helper functions `argint`, `argptr`, `argstr` and `argfd`, at `%esp + 4 + 4 * n`.  
The system call implementations are typically wrappers: they decode the arguments and call the real implementations.

#### Code: Interrupt
IO APIC and LAPIC.

### Drivers

### 2. Lecture note

#### HW5 CPU alarm solution

#### Interrupt and concurrency
Interrupt and polling.