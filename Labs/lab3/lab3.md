# Lab 3

## Before start
After merging conflict, you may found that: code that already passed checking in Lab 2 no longer checks and the error message says that
`kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;` gets `invalid kva 00000000`. Print out `kerg_pgdir` and you see that `memset(kern_pgdir, 0, PGSIZE);` sets the value of `kern_pgdir` to `0`!  

Solution:
https://zhuanlan.zhihu.com/p/46838542

# Part A
## Exercise 1
Very similar to code for `pages` in Lab2. 

```C
//////////////////////////////////////////////////////////////////////
// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
// LAB 3: Your code here.
envs = boot_alloc(NENV * sizeof(struct Env));
memset(envs, 0, NENV * sizeof(struct Env));

//////////////////////////////////////////////////////////////////////
// Map the 'envs' array read-only by the user at linear address UENVS
// (ie. perm = PTE_U | PTE_P).
// Permissions:
//    - the new image at UENVS  -- kernel R, user R
//    - envs itself -- kernel RW, user NONE
// LAB 3: Your code here.
boot_map_region(kern_pgdir,
                UENVS,
                ROUNDUP(NENV * sizeof(struct Env), PGSIZE),
                PADDR(envs),
                PTE_U | PTE_P);
```
## Exercise 2
Functions are managable and just follow the instructions provided in the comment and the lab sheet. Except for two below.  

Pay particular attention to the implementation and comments of `env_setup_vm` and `load_icode`.  
In `env_setup_vm`, we make `e->env_pgdir` as an exact copy from `kern_pgdir`.  
In `load_icode`, we switch to user environement, `e->env_pgdir`, to load the binary code into user environment, and switch back to kernel space.
```C
void 
env_init(void) {
	for(int i = NENV - 1; i >= 0; --i) {
		(envs + i)->env_status = ENV_FREE;
		(envs + i)->env_id = 0;
		(envs + i)->env_link = env_free_list;
		env_free_list = (envs + i);
	}

	env_init_percpu();
}

// Read comments and understand the difference between 
// correct solution and initial solution.
static int
env_setup_vm(struct Env *e)
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;

	e->env_pgdir = (pde_t *)page2kva(p);
	memset(e->env_pgdir, 0, PGSIZE);

	p->pp_ref += 1;
	// Use kern_pgdir as template.
	// Use memcpy to make direct copy. You can do the same thing
	// by making manual copy as below, but at this point, the kern_pgdir
	// contains exactly the things we want for a user environment:
	// kernal part [KERNBASE, 4GB], and the content in [UTOP, KERNBASE].
	// This is also mentioned in Lab2: you set up the kernel virtual address
	// space and if user program gets the exact same mapping.
	
	// Original solution:
	// uintptr_t start = ROUNDUP(UTOP, PGSIZE);
	// uintptr_t end = ROUNDUP((long long) 1 << 32, PGSIZE);
	// for(uintptr_t va = start; va < end; ) {
	// 	*(pgdir_walk(e->env_pgdir, (void *)va, 1)) = *(pgdir_walk(kern_pgdir, (void *)va, 0));
	// 	va += PGSIZE;
	// }
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE);

	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
	return 0;
}

static void
region_alloc(struct Env *e, void *va, size_t len)
{
	// Corner case: e equals to NULL
	if(e == 0)
		panic("The struct Env could not be NULL");
	// corner case: len equals to 0
	if(len == 0)
		return;

	uintptr_t start = (uintptr_t)ROUNDDOWN(va, PGSIZE);
	uintptr_t end = (uintptr_t)ROUNDUP(va + len, PGSIZE);

	for(uintptr_t vaddr = start; vaddr < end; vaddr += PGSIZE) {
		struct PageInfo* pginfo_p = page_alloc(0);
		if (pginfo_p == NULL)
			panic("Cannot allocate physical page");
		if (page_insert(e->env_pgdir, pginfo_p, (void *)vaddr, PTE_P | PTE_U | PTE_W) < 0) 
			panic("page insertion failed.");
	}
}

// Read comments and understand the difference between 
// correct solution and initial solution.
static void
load_icode(struct Env *e, uint8_t *binary)
{
	struct Elf * elf = (struct Elf *)binary;
	if (elf->e_magic != ELF_MAGIC) {
		panic("Not ELF format");
	}

	// The original comment: "Loading the segments is much simpler if you
	// can move data directly into the virtual addresses stored in the ELF
	// binary". 
	// Because previously we construct e->env_pgdir as an exact copy from 
	// kern_pgdir using memcpy, so e->env_pgdir also has mepping for binary! 
	// So we can directly switch to user space!

	// Switch to env_pgdir first, so we can use memset functions.
	// Do not forget to switch back!
	lcr3(PADDR(e->env_pgdir));

	// Load each segment from binary image to the corresponding va
	struct Proghdr* ph = (struct Proghdr*)((uint32_t)binary + elf->e_phoff);
	struct Proghdr* eph = ph + ((struct Elf*)binary)->e_phnum;

	uint32_t va;
	for(; ph < eph; ph++) {
		if (ph->p_type == ELF_PROG_LOAD) {
			va = (uint32_t)binary + ph->p_offset;
            region_alloc(e, (void *)ph->p_va, ph->p_memsz);
            memset((void*)ph->p_va, 0, ph->p_memsz);
            memcpy((void*)ph->p_va, (void*)va, ph->p_filesz);
        }
	}

	// Now map one page for the program's initial stack
	// at virtual address USTACKTOP - PGSIZE.

	// LAB 3: Your code here.
	region_alloc(e, (void*)(USTACKTOP - PGSIZE), PGSIZE);

	// switch back to kern_pgdir
	lcr3(PADDR(kern_pgdir));
	
	// Set the entry point
	e->env_tf.tf_eip = elf->e_entry;

	/*
	Initial solution: uint8_t *binary is mapped at a physical region
	in kern_pgdir. So just copy the content in kern_pgdir into 
	e->env_pgdir. This is copying the mapping essentially, but not the content.

	This is not a good solution, as you are only copying the table
	but not really the binary file.
	As mentioned in the lab sheet, the ELF binary file is embedded
	into the kernel space by the Makefile and what we should do is
	to copy the content into user environment.
	*/

	/*
	Initial solution:

	struct Proghdr *ph, *eph;
	ph = (struct Proghdr *) ((uint8_t *)binary + elf->e_phoff);
	eph = ph + ((struct Elf*)binary)->e_phnum;

	for(; ph < eph; ++ph) {
		if (ph->p_type == ELF_PROG_LOAD) {
			region_alloc(e, (void *)ph->p_va, ph->p_memsz);

			uintptr_t env_va_start, env_va_end, env_va, kern_va;
			env_va_start = (uintptr_t) ph->p_va;
			env_va_end = ROUNDUP((uintptr_t) (ph->p_va + ph->p_memsz), PGSIZE);
			kern_va = (uintptr_t)ph;
			for(env_va = env_va_start; env_va < env_va_end; ) {
				*pgdir_walk(e->env_pgdir, (void *)env_va, 1) = *pgdir_walk(kern_pgdir, (void *)kern_va, 0);
				env_va += PGSIZE;
				kern_va += PGSIZE;
			}
		} else {
			memset(ph, 0, ph->p_memsz);
		}
	}

	region_alloc(e, (void *)(USTACKTOP - PGSIZE), PGSIZE);
	e->env_tf.tf_eip = 0;
	*/
}

void
env_create(uint8_t *binary, enum EnvType type)
{
	if (env_free_list == NULL) {
		panic("No more free env");
		return;
	}

	struct Env *curr_env;
	if (env_alloc(&curr_env, 0) < 0)
		panic("Cannot allocate new env");

	load_icode(curr_env, binary);
	curr_env->env_type = type;
}

void
env_run(struct Env *e)
{
	if (curenv != NULL) {
		if (curenv->env_status == ENV_RUNNING) {
			curenv->env_status = ENV_RUNNABLE;
		}
	}
	curenv = e;
	curenv->env_status = ENV_RUNNING;
	curenv->env_runs += 1;

	lcr3(PADDR((e->env_pgdir)));
	env_pop_tf(&(e->env_tf));
}
```

## Exercise 3: 80386 Programmer's Manual
### Segmentation again (Section 5.1)  
```
logical address -> linear address -> physical address
                ^                 ^
                |                 |
                |                 |
Segmentation ---+                 +-- Paging     

Logical address = base + offset
    descriptor-----^
        ^
        |
indexed by selector
From decriptor table
--------------------------------------------------------------------------
Segmentation process

selector(16-bit)                   offset(32-bit)
    |   descriptor table            |
    |   +-----------+               |
    |   |           |               |
    |   +-----------+               |
    |   |   ....    |               |
    |   +-----------+  base         v
    +-> |descriptor |-----------> [+] ======> linear address         
        +-----------+  limit         
        |           |          
        +-----------+       
```
Each logical address has a selector portion, indicating the segment, and an offset portion, indicating the offset within that portion. 

1. Descriptor  
    A segment descriptor provides information about one segment. Including the base, limit, and bits representing different information. A descriptor occupies 8 bytes.
2. Descriptor table  
    An array of 8-byte descriptors. Global descriptor table (GDT) and local descriptor table (LDT).  
    The first entry of the GDT (INDEX=0) is not used.  
    The addresses of GDT and LDT are given by GDTR and LDTR registers.
3. Selector  
    A selector selects the descriptor used (GDT or LDT) and the index into the descriptor table.
4. Segment register  
    Descriptor table is stored in memory, so the CPU needs to consult the descriptor table every time it accesses memory. This is inefficient.  Segment register is used to store information in descriptor.  
    A segment register has a visible portion and an invisible portion. The visible portion is manipulated by the program as if they are 16-bit registers, and the visible portion is manipulated by the hardware(processor).  
    When the program loads the visible part of a segment register, which indicates the 16-bit segment descriptor, the processor automatically fetches the corresponding information from the descriptor table into the invisible part of the segment register.
5. CPL(current privilege level), DPL (descriptor privilege level), and RPL (requested provilege level).  
    https://stackoverflow.com/q/36617718  
    https://iambvk.wordpress.com/2007/10/10/notes-on-cpl-dpl-and-rpl-terms/

### Chapter 7 Multitask
- Difference bewteen GDT and LDT  
    GDT stores descriptors to system-wide segments, mainly used by kernel. Like TSS, for the kernel to manage tasks.  
    LDT stores descriptors to segments specific to the task. TSS should not be referenced in the LDT.  
    LDT is important when we separate the address space for multiple processes. There will be generally one LDT per user process that describes privately held memory, while GDT describes shared memory and kernel memory.  
    Descriptors to LDTs are stored in the GDT.  
    https://stackoverflow.com/q/34243432/9057530 

### Chapter 9 Exceptions and Interrupts
- Terms
    - interrupt or execption identifier (interrute id, 0 ~ 255)   
    - procedure (a method/function)    
    - task (a process)  

- Interrupt gate & Trap gate  
    - The Interrupt Gate is used to specify an *interrupt service routine*. When you do `INT 50` in assembly, the CPU looks up the 50th entry (located at 50 * 8) in the IDT. Then the Interrupt Gate's **selector** and **offset value** is loaded. The selector and offset is used to call the interrupt service routine.
    - Trap and Interrupt gates are similar, and their descriptors are structurally the same, they differ only in the "type" field. The difference is that for interrupt gates, interrupts are automatically disabled upon entry and reenabled upon IRET which restores the saved EFLAGS.
    - When an interrupt/exception occurs that corresponds to a Trap or Interrupt Gate, the CPU places the return info on the stack (EFLAGS, CS, EIP), so the interrupt handler can resume the interrupted code by IRET. Then, execution is transferred to the given `selector:offset` from the gate descriptor.

The interrupt descriptor table (IDT) associates each interrupt or exception identifier with a descriptor for the instructions/code that service the associated event.   
The IDT may reside anywhere in physical memory. The processor locates the IDT by means of the IDT register (IDTR).  
The IDT may contain any of three kinds of descriptor: 1) Task gates; 2) Interrupt gates; 3) Trap gates.  

- Interrupte/trap gate  
    Just as a `CALL` instruction can call either a procedure or a task, so an interrupt or exception can "call" an interrupt handler that is either a procedure or a task. When responding to an interrupt or exception, the processor uses the interrupt or exception identifier to index a descriptor in the IDT. If the processor indexes to an interrupt gate or trap gate, it invokes the handler in a manner similar to a `CALL` to a call gate. If the processor finds a task gate, it causes a task switch in a manner similar to a `CALL` to a task gate.  
    An interrupt gate or trap gate points indirectly to a procedure. The selector of the gate points to an executable-segment descriptor in either the GDT or the current LDT. The offset field of the gate points to the beginning of the interrupt or exception handling procedure.

    ![Interrupte/trap gate point to procedure](https://pdos.csail.mit.edu/6.828/2018/readings/i386/fig9-4.gif "Interrupte/trap gate point to procedure")

    The information pushed onto the stack is already discussed in Lecture 5 note.  

- Task gate
    A task gate in the IDT points indirectly to a taskThe selector of the gate points to a TSS descriptor in the GDT.

    ![task gate point to procedure](https://pdos.csail.mit.edu/6.828/2018/readings/i386/fig9-6.gif "task gate point to procedure")

## Basics of Protected Control Transfer
Exceptions and interrupts are "protected control transfers," which cause the processor to switch from user to kernel mode without giving the user code any opportunity to interfere.   

To provide protection:  
- Interrupte descriptor table (IDT)  
    The processor ensures that interrupts and exceptions can only cause the kernel to be entered at a few entry-points determined by the kernel itself.  
    The x86 allows up to 256 different interrupt or exception entry points, each with a different interrupt *vector*. **A vector is a number** between 0 and 255. A interrupt's vector is determined by the source of interrupt. The CPU uses the vector as an index into the processor's interrupt descriptor table (IDT). From the entry in IDT the processor loads:
    - the value for %EIP, pointing to the handler code in kernel.  
    - the value for %cs, including the privilege level.  
- The Task State Segment (TSS)  
    Note that the CPU uses vector to index into IDT to load proper value of %eip and %cs of the interrupte/exception handler. Before that, the processor needs to save the old processor state before the interrupt or exception occurred, such as the original values of EIP and CS before the processor invoked the exception handler, so that the exception handler can later restore that old state and resume execution. But this area for the old processor state must be protected from unprivileged user-mode code.  

    The old processor state would be stored on kernel stack. *Task state segment* specifies the segment selector and address of the kernel stack.  
- Entire process  
    When interrupt/exception happens, the processor switches to stack defined by the `SS0` and `ESP0` fields of the TSS, pushes SS, ESP, EFLAGS, CS, EIP, and an optional error code to the kernel stack. Then it loads the CS and EIP from the interrupt descriptor in IDT, and sets the ESP and SS to refer to the new stack.

- JOS specific  
    Although the TSS is large and can potentially serve a variety of purposes, JOS only uses it to define the kernel stack. Since "kernel mode" in JOS is privilege level 0 on the x86, the processor uses the `ESP0` and `SS0` fields of the TSS to define the kernel stack when entering kernel mode. JOS doesn't use any other TSS fields.

- Example   
    Take a look at the good example provided in the lab sheet.  

### Nested Exception and Interrupt
The processor can take exceptions and interrupts both from kernel and user mode. It is only when entering the kernel from user mode that the x86 processor automatically switches stacks before pushing its old register state onto the stack and invoking the appropriate exception handler through the IDT. If the processor is already in kernel mode when the interrupt or exception occurs, then the CPU just pushes remaining values on the same kernel stack. In this way, the kernel can gracefully handle *nested exceptions* caused by code within the kernel itself. 

If the processor is already in kernel mode and takes a nested exception, since it does not need to switch stacks, it does not save the old SS or ESP registers.  

There is one important caveat to the processor's nested exception capability. If the processor takes an exception while already in kernel mode, and cannot push its old state onto the kernel stack for any reason such as lack of stack space, then there is nothing the processor can do to recover, so it simply resets itself. Needless to say, the kernel should be designed so that this can't happen.  

## Exercise 4
Read the instruction very carefully when coding. Code in xv6 provides great illustration.  
Make sure you understand:  
- How to use macros `TRAPHANDLER` and `TRAPHANDLER_NOEC` to implement trap entry-points?  

    Hint: read comment in `trapEntry.S`. 
- How to write `_alltraps`?  

    Hint: read `trapasm.S` and instruction in lab sheet carefully.  
- How to write `trapinit` to set up IDT?  

    Hint: declare entry-points in `trap.c` and use `SET_GATE`. Read `trap.c` in xv6.  
- Does `trap()` return?   

    Hint: No!

## Challenge
Would be similar to what xv6 does. Requires too much hardcoding. Would do in the future if needed.

## Questions
1. What is the purpose of having an individual handler function for each exception/interrupt? (i.e., if all exceptions/interrupts were delivered to the same handler, what feature that exists in the current implementation could not be provided?)  

	First, some exceptions push the error code to the kernel stack while others do not. Separate handler function makes code less complicated. 

	Second, protection/isolation. For each standalone interrupt handler, we can define it whether can be triggered by a user program or not. For example, System call can be invoked by user while other exceptions should not.  
	
2. Did you have to do anything to make the `user/softint` program behave correctly? The grade script expects it to produce a general protection fault (trap 13), but softint's code says int $14. Why should this produce interrupt vector 13? What happens if the kernel actually allows softint's int $14 instruction to invoke the kernel's page fault handler (which is interrupt vector 14)?  

	Do not have to do anything. `SETGATE(idt[T_PGFLT], 0, GD_KT, PGFLT, 0);` in `trap.c` sets that page fault can only be generated by privilege level 0 but not the user code. Thus, general protection exception is generated.  

	If allowed, protection is lost. Can attack kernel.  

## Exercise 5
A very eassy exercise.
```C
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	switch (tf->tf_trapno) {
		case T_PGFLT:
			page_fault_handler(tf);
			break;
		default:
			break;
	}

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
	if (tf->tf_cs == GD_KT)
		panic("unhandled trap in kernel");
	else {
		env_destroy(curenv);
		return;
	}
}
```

## Exercise 6
Read the instruction very carefully. Need to turn `T_BRKPT` into a "primitive pseudo-system call that any user environment can use to invoke the JOS kernel monitor".

In `trapinit()`:
```C
SETGATE(idt[T_BRKPT], 1, GD_KT, BRKPT, 3);  // Lab3: Changed to a pseudo 
											// system call that can be 
											// invoked by any user code. 
```
In `trap_dispatch()`:
```C
static void
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	switch (tf->tf_trapno) {
		case T_PGFLT:
			page_fault_handler(tf);
			break;
		case T_BRKPT:
			monitor(tf);
			break;
		default:
			break;
	}

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
	if (tf->tf_cs == GD_KT)
		panic("unhandled trap in kernel");
	else {
		env_destroy(curenv);
		return;
	}
}
```

## Question 
3. The break point test case will either generate a break point exception or a general protection fault depending on how you initialized the break point entry in the IDT (i.e., your call to `SETGATE` from `trap_init`). Why? How do you need to set it up in order to get the breakpoint exception to work as specified above and what incorrect setup would cause it to trigger a general protection fault?  

	If the privilege level is enabled for user, then break point exception. Otherwise, a general protection fault. Code:  
	```C
	SETGATE(idt[T_BRKPT], 1, GD_KT, BRKPT, 3);
	```
	In correct code would set DPL to 0.
	
4. What do you think is the point of these mechanisms, particularly in light of what the user/softint test program does?  

	The kernel determines the protection level and interface to the user program.


## Exericse 7
This exercise is not hard as detailed instruction is given and we are already familar with the system call mechanism. The only tricky gotcha (wasted 3 hours on it) is in `trap_dispatch` in `trap.c`:
```C
static void
trap_dispatch(struct Trapframe *tf)
{
	cprintf("trap_dispatch called\n");

	// Handle processor exceptions.
	// LAB 3: Your code here.
	switch (tf->tf_trapno) {
		// You should "return" instead of "break"!
		case T_PGFLT:
			page_fault_handler(tf);
			return;
		case T_BRKPT:
			monitor(tf);
			return;
		case T_SYSCALL:
			tf->tf_regs.reg_eax = syscall(
				tf->tf_regs.reg_eax, 
				tf->tf_regs.reg_edx,
				tf->tf_regs.reg_ecx,
				tf->tf_regs.reg_ebx,
				tf->tf_regs.reg_edi,
				tf->tf_regs.reg_esi);
			return;

		default:
			break;
	}

	
	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);

	if (tf->tf_cs == GD_KT)
		panic("unhandled trap in kernel");
	else {
		env_destroy(curenv);
		return;
	}
}
```
Note that you in switch statement, you should use `return` instead of `break`! Otherwise the user environment(process) would be destroyed!

## Exercise 8
Again, detailed instruction is given but spend another 20 minutes debugging. The bug is from switch statement again :(  

In `kern/syscall.c`:
```C
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.
	int32_t res;

	switch (syscallno) {
		case SYS_cputs:
			sys_cputs((const char *)a1, a2);
			res = 0;
			break;
		case SYS_cgetc:
			res = sys_cgetc();
			break;
		case SYS_getenvid:
			res = sys_getenvid();
			break;
		case SYS_env_destroy:
			res = sys_env_destroy(a1);
			break;
		default:
			res = -E_INVAL;
	}
	return res;
}
```
Previously I forget to add `break` statements.

## Exercise 9 & 10
Panic when page fault in kernel mode.
```diff
--- a/kern/trap.c
+++ b/kern/trap.c
@@ -274,6 +274,9 @@ page_fault_handler(struct Trapframe *tf)
        // Handle kernel-mode page faults.
 
        // LAB 3: Your code here.
+       if ((tf->tf_cs & 3) == 0) {
+               panic("Page fault in kernel-mode!");
+       }
 
        // We've already handled kernel-mode exceptions, so if we get here,
        // the page fault happened in user mode.

```

Check pointers passed into system call from user code. 
```diff
--- a/kern/pmap.c
+++ b/kern/pmap.c
@@ -666,6 +666,33 @@ int
 user_mem_check(struct Env *env, const void *va, size_t len, int perm)
 {
        // LAB 3: Your code here.
+       pte_t *pte_p;
+       uintptr_t start, end, addr;
+       uintptr_t required_perm;
+
+       start = (uintptr_t)ROUNDDOWN(va, PGSIZE);
+       end = (uintptr_t)ROUNDUP(va + len, PGSIZE);
+
+       required_perm = perm | PTE_P | PTE_U;
+
+       for(addr = start; addr < end; addr += PGSIZE) {
+               // Check below ULIM
+               if (addr < ULIM) {
+                       // Check permission
+                       pte_p = pgdir_walk(env->env_pgdir, (void *)addr, 0);
+                       if (pte_p && *pte_p && (*pte_p & required_perm)) {
+                               continue;
+                       }
+               }
+
+               // Either above ULIM or no permission
+               if (addr < (uintptr_t)va) {
+                       user_mem_check_addr = (uintptr_t)va;
+               } else {
+                       user_mem_check_addr = addr;
+               }
+               return -E_FAULT;
+       }
 
        return 0;
 }

```

Sanity check for system call.
```diff
--- a/kern/syscall.c
+++ b/kern/syscall.c
@@ -21,6 +21,7 @@ sys_cputs(const char *s, size_t len)
        // Destroy the environment if not.
 
        // LAB 3: Your code here.
+       user_mem_assert(curenv, s, len, PTE_P);
 
        // Print the string supplied by the user.
        cprintf("%.*s", len, s);
```

Implement backtrace.
```diff
--- a/kern/kdebug.c
+++ b/kern/kdebug.c
@@ -142,6 +142,9 @@ debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
                // Make sure this memory is valid.
                // Return -1 if it is not.  Hint: Call user_mem_check.
                // LAB 3: Your code here.
+               if(user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_P | PTE_U) < 0) {
+                       return -1;
+               }
 
                stabs = usd->stabs;
                stab_end = usd->stab_end;
@@ -150,6 +153,12 @@ debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
 
                // Make sure the STABS and string table memory is valid.
                // LAB 3: Your code here.
+               if(user_mem_check(curenv, stabs, (stab_end - stabs) * sizeof(struct Stab), PTE_P | PTE_U) < 0) {
+                       return -1;
+               }
+               if(user_mem_check(curenv, stabstr, (stabstr_end - stabstr), PTE_P | PTE_U) < 0) {
+                       return - 1;
+               }
        }
```

Most of the code above are easy, given the detailed instruction. Just be careful about the logic in `user_mem_check`.  

> Finally, change `debuginfo_eip` in `kern/kdebug.c` to call `user_mem_check` on usd, stabs, and stabstr. If you now run `user/breakpoint`, you should be able to run `backtrace` from the kernel monitor and see the `backtrace` traverse into `lib/libmain.c` before the kernel panics with a page fault. What causes this page fault? You don't need to fix it, but you should understand why it happens.  

This is not easy. Check this answer: https://qiita.com/kagurazakakotori/items/334ab87a6eeb76711936  



