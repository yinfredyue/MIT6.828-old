## Lecture 5

### sytem call design
CPL: current priviledge level  
- How to make a system call?
   - Should the user be able to set `CPL=0` and make a system call?     
      Of course not. OS loses control.  
   - Some combined operation to set `CPL=0`, but jump directly to kernel code?   
      Bad. User might jump to somewhere we do not want it to.  
   - x86 solution:   
      A combined instruction, `INT`, that sets `CPL` and jumps.     
      There are only a few permissible kernel entry points ("vectors"), that would jump to the kernel.  
      `INT` instruction sets CPL=0 and jumps to an entry point, but user code can't otherwise modify CPL or jump anywhere else in kernel.    
      System call return sets `CPL=3` before returning to user code also a combined instruction (can't separately set CPL and jmp)
   - Result: well-defined notion of user vs kernel  
      Either CPL=3 and executing user code, or CPL=0 and executing from entry point in kernel code.


### Case study

#### system call `write`
Go to `sh.asm`, search `write`, you see
```
00000d32 <write>:
SYSCALL(write)
     d32:	b8 10 00 00 00       	mov    $0x10,%eax
     d37:	cd 40                	int    $0x40
     d39:	c3                   	ret    
```
Thus, go to `Homeworks/xv6-public`, start `qemu`, and `break *0xd32`.  
```
(gdb) b *0x00000d32
Breakpoint 1 at 0xd32
(gdb) c
Continuing.
[Switching to Thread 2]
[  1b: d32]    0xee2:	je     0xfee

Thread 2 hit Breakpoint 1, 0x00000d32 in ?? ()
```

#### `INT`: software interrupt/go to interrupt handler
```
(gdb) ni
[  1b: d37]    0xee7:	add    %al,0x25f8(%bp,%di)
0x00000d37 in ?? ()
(gdb) disas 0x00000d32, 0x00000d3a
Dump of assembler code from 0xd32 to 0xd3a:
   0x00000d32:	mov    $0x10,%ax        <-- 0x10: syscall No. for write
   0x00000d35:	add    %al,(%bx,%si)    <-- this line does not exist in sh.asm,
                                           do not know why it appears here.
=> 0x00000d37:	int    $0x40            <-- INT instruction, kernel entry
                                            0x40 refers to the entry in
                                            the vector. 0x40 is decimal 64. 
                                            Jump to vector64.
   0x00000d39:	ret
End of assembler dump.
(gdb) i r
eax            0x10	16
ecx            0x24	36
edx            0x0	0
ebx            0x24	36
esp            0x3f4c	0x3f4c          <- %esp, %eip in user space. 
ebp            0x3f98	0x3f98
esi            0x11b9	4537
edi            0x0	0
eip            0xd37	0xd37
eflags         0x216	[ PF AF IF ]
cs             0x1b	27                  <- Bottom 2 bits of %cs is CPL.
                                           CPL = 0x11 = 3 => user mode. 
ss             0x23	35
ds             0x23	35
es             0x23	35
fs             0x0	0
gs             0x0	0
(gdb) x/4x $esp
0x3f4c:	0x00000ea5	0x00000002	0x00003f7a	0x00000001
            ^           ^           ^           ^-------- count
            |           |           |
    return address      fd      buffer on stack

===> write(2, 0x3f7a, 1)

(gdb) x/c 0x00003f7a
0x3f7a:	36 '$'
(gdb) x/s 0x00003f7a
0x3f7a:	"$" <-- This is the terminal prompt of the shell
```

#### Interrupt handler vector
```
(gdb) disas 0x00000d32, 0x00000d3a
Dump of assembler code from 0xd32 to 0xd3a:
   0x00000d32:	mov    $0x10,%ax
   0x00000d35:	add    %al,(%bx,%si)
=> 0x00000d37:	int    $0x40
   0x00000d39:	ret    
End of assembler dump.
(gdb) si
The target architecture is assumed to be i386
=> 0x80105f09 <vector64+2>:	push   $0x40
vector64 () at vectors.S:320
320	  pushl $64
(gdb) disas vector64
Dump of assembler code for function vector64:
   0x80105d37 <+0>:	push   $0x0
=> 0x80105d39 <+2>:	push   $0x40
   0x80105d3b <+4>:	jmp    0x8010562a <alltraps>
(gdb) i r
eax            0x10	16
ecx            0x24	36
edx            0x0	0
ebx            0x24	36
esp            0x8dffefe8	0x8dffefe8  <- high address, kernel stack
ebp            0x3f98	0x3f98
esi            0x11b9	4537
edi            0x0	0
eip            0x80105d39	0x80105d39 <vector64+2> <- high address
eflags         0x216	[ PF AF IF ]
cs             0x8	8       <-- CRL = 0, kernel mode
ss             0x10	16
ds             0x23	35
es             0x23	35
fs             0x0	0
gs             0x0	0
```     
The entry point to the kernel is a kernel-supplied vector, so user program cannot jump to random places in the kernel. 

Inspect the kernel stack:
```
(gdb) x/6wx $esp
                %err        %eip        %cs         %eflags
0x8dffefe8:	0x00000000	0x00000d39	0x0000001b	0x00000216
0x8dffeff8:	0x00003f4c	0x00000023
                %esp        %ss
```
These are saved registers saved by `INT`: err, eip, cs, eflags, esp, ss. They are saved because they would be overwritten by INT.  

`INT`'s job:  
- switched to current process's kernel stack (change %esp)
- saved some user registers on kernel stack
- set CPL=0
- start executing at kernel-supplied "vector" (`jmp <alltraps>`)

Where did `%esp` come from?   
Ans: Kernel told h/w what kernel stack to use when creating process.  

#### Trap into kernel mode, Save remaining user registers
```
# trapasm.S 

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
  pushl %es
  pushl %fs
  pushl %gs
  pushal    <-- pushal pushes 8 registers: eax .. edi
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
  movw %ax, %ds
  movw %ax, %es

  # Call trap(tf), where tf=%esp
  pushl %esp
  call trap
  addl $4, %esp
```
The kernel stack would look like:  
```
ss              <-- 
esp
eflags
cs
eip
-----           <-- INT called
err             <-- saved in vectors.S
trapno
ds              <-- saved in trapasm.S
es
fs
gs
eax..edi
```

*Why save user registers on the kernel stack, instead of the user stack?*

#### Invoke interrupt handler in the handler vector in `trap()`
Then calls `trap(tf)`, defined in `trap.c`. Note that `T_SYSCALL` is a macro defined in `traps.h`:
```
#define T_SYSCALL       64      // system call
```

#### `trapret`
Restoring user registers:
```
(gdb) finish
Run till exit from #0  trap (tf=0x8dffefa0) at trap.c:38
=> 0x8010563f <alltraps+21>:	add    $0x4,%esp
alltraps () at trapasm.S:21
21	  addl $4, %esp
(gdb) disas alltraps 
Dump of assembler code for function alltraps:
   0x8010562a <+0>:	    push   %ds
   0x8010562b <+1>:	    push   %es
   0x8010562c <+2>:	    push   %fs
   0x8010562e <+4>:	    push   %gs
   0x80105630 <+6>:	    pusha  
   0x80105631 <+7>:	    mov    $0x10,%ax
   0x80105635 <+11>:	mov    %eax,%ds
   0x80105637 <+13>:	mov    %eax,%es
   0x80105639 <+15>:	push   %esp
   0x8010563a <+16>:	call   0x80105700 <trap>
=> 0x8010563f <+21>:	add    $0x4,%esp
End of assembler dump.
(gdb) i r
eax            0x0	0
ecx            0x801128e0	-2146359072
edx            0x1	1
ebx            0x24	36
esp            0x8dffef9c	0x8dffef9c  <-- At high address, kernel mode.
                                               Registers have been overwritten by kernel code.
ebp            0x3f98	0x3f98
esi            0x11b9	4537
edi            0x0	0
eip            0x8010563f	0x8010563f <alltraps+21>
eflags         0x46	[ PF ZF ]
cs             0x8	8                   <-- CRL = 0, kernel mode
ss             0x10	16
ds             0x10	16
es             0x10	16
fs             0x0	0
gs             0x0	0
(gdb) si 7
=> 0x80105642 <trapret>:	popa   
trapret () at trapasm.S:26
26	  popal
(gdb) disas trapret 
Dump of assembler code for function trapret:
   0x80105642 <+0>:	    popa   
   0x80105643 <+1>:	    pop    %gs
   0x80105645 <+3>:	    pop    %fs
   0x80105647 <+5>:	    pop    %es
   0x80105648 <+6>:	    pop    %ds
   0x80105649 <+7>:	    add    $0x8,%esp
=> 0x8010564c <+10>:	iret   
   0x8010564d <+11>:	xchg   %ax,%ax
   0x8010564f <+13>:	nop
End of assembler dump.
(gdb) i r
eax            0x1	1
ecx            0x24	36
edx            0x0	0
ebx            0x24	36
esp            0x8dffefec	0x8dffefec
ebp            0x3f98	0x3f98
esi            0x11b9	4537
edi            0x0	0
eip            0x8010564c	0x8010564c <trapret+10>
eflags         0x282	[ SF IF ]
cs             0x8	8
ss             0x10	16
ds             0x23	35
es             0x23	35
fs             0x0	0
gs             0x0	0
```
Most registers hold restored user values, eax has write() return value of 1, esp, eip, cs still have kernel values.
```
(gdb) x/5x $esp
0x8dffefec:	0x00000d39	0x0000001b	0x00000216	0x00003f4c
0x8dffeffc:	0x00000023
Exactly the same as previously.
```

#### `IRET`
IRET pops those user registers from the stack and then re-enters user space with CPL=3.  
```
(gdb) si
The target architecture is assumed to be i8086
[  1b: d39]    0xee9:	clc    
0x00000d39 in ?? ()
(gdb) i r
eax            0x1	1
ecx            0x24	36
edx            0x0	0
ebx            0x24	36
esp            0x3f4c	0x3f4c
ebp            0x3f98	0x3f98
esi            0x11b9	4537
edi            0x0	0
eip            0xd39	0xd39
eflags         0x216	[ PF AF IF ]
cs             0x1b	27
ss             0x23	35
ds             0x23	35
es             0x23	35
fs             0x0	0
gs             0x0	0
```

#### After reading Chapter 3 of xv6 book
Process of printing the `$ ` prompt in kernel:
- `getcmd` in `sh.c` calls `printf` (defined `prinf.c`), which calls `putc`. `putc` calls `write` system call.
- `write` system call is invoked, assembly code in `sh.asm`. 
   - Store **system call No.** `0x10` into %eax.
   - call `INT $0x40`. `0x40` is the **trap No.** for system call.
- `INT`(Saving registers done by the hardware)
   - Save %esp and %ss (for user mode) in CPU-internal registers, *if in user mode*.
   - Load %esp and %ss from task segment descriptor (%esp and %ss used for kernel mode).
   - Push %ss, push %esp.
   - Push %cs, %eip.
   - Set %cs and %eip to the values in the descriptor.
   - Invoke an entry to the interrupt handler vector, `vector.S`.
- vector entry. 
   - Push error code, if not pushed when `INT` is called.
   - Push trap No.
   - Jump to `alltraps`, which is the entry point for all traps into kernel mode.
- `alltraps` in `trapasm.S`
   - Push %ds, %es, %fs, %gs to stack.
   - Push 8 general-registers to stack.  
      Now we have completed the hardware part of the trap frame. And we finish the trapframe at the top of the stack.
   - Hardware (Processor) sets correct value of %cs, %ss.
   - `alltraps` sets correct value of %ds, %es.
   - Push argument to `trap`, `%esp` == pointer to trap frame, onto stack.
   - Call `trap`.
- Enter `trap()` defined in `trap.c`
   - `tf->trapno == T_SYSCALL` is true, so

      ```C
      ...
      if(tf->trapno == T_SYSCALL){
         if(myproc()->killed)
            exit();
         myproc()->tf = tf;
         syscall();
         if(myproc()->killed)
            exit();
         return;
      }
      ...
      ```
   - `syscall` defined in `syscall.c`:
      ```C
      void
      syscall(void)
      {
         int num;
         struct proc *curproc = myproc();

         num = curproc->tf->eax;
         if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
            curproc->tf->eax = syscalls[num]();
            // cprintf("[%s -> %d]\n", (syscall_names[num]), curproc->tf->eax);
         } else {
            cprintf("%d %s: unknown sys call %d\n", curproc->pid, curproc->name, num);
            curproc->tf->eax = -1;
         }
      }
      ``` 
      - `curproc->tf->eax` is the syscall number.
      - The return value of the system call is also stored in `curproc->tf->eax`.

- Return back to `trapasm.S`, execute `trapret`
   - Pop general registers from kernel stack.
   - Pop %ds, %es, %fs, %gs from stack.
   - Deallocate space for `error_code` and `trapNo` on the stack.
   - Pop more user-registers from stack, including `%eip`.
   - Resume execution from the address stored in `%eip`.