# Lab 4 Preemptive Multitasking

## Part A: Multiprocessor Support and Cooperative Multitasking
### Exercise 1
```C
//
// Reserve size bytes in the MMIO region and map [pa,pa+size) at this
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
	// Where to start the next region.  Initially, this is the
	// beginning of the MMIO region.  Because this is static, its
	// value will be preserved between calls to mmio_map_region
	// (just like nextfree in boot_alloc).
	static uintptr_t base = MMIOBASE;

	// Reserve size bytes of virtual memory starting at base and
	// map physical pages [pa,pa+size) to virtual addresses
	// [base,base+size).  Since this is device memory and not
	// regular DRAM, you'll have to tell the CPU that it isn't
	// safe to cache access to this memory.  Luckily, the page
	// tables provide bits for this purpose; simply create the
	// mapping with PTE_PCD|PTE_PWT (cache-disable and
	// write-through) in addition to PTE_W.  (If you're interested
	// in more details on this, see section 10.5 of IA32 volume
	// 3A.)
	//
	// Be sure to round size up to a multiple of PGSIZE and to
	// handle if this reservation would overflow MMIOLIM (it's
	// okay to simply panic if this happens).
	//
	// Hint: The staff solution uses boot_map_region.
	//
	// Your code here:
	uintptr_t size_r;	// Rounded size

	size_r = ROUNDUP(size, PGSIZE);
	boot_map_region(kern_pgdir, base, size_r, pa, PTE_PCD | PTE_PWT | PTE_W | PTE_P);

	void *ret = (void *)base;
	base += size_r;

	return ret;
}
```

### Exercise 2
In `pmap.c: page_init()`, change the mapping for base memory to:
```C
    /* Base memory (First 640KB) */
	size_t i;
	for(i = 1; i < npages_basemem; ++i) {
		if (i == MPENTRY_PADDR / PGSIZE) { // AP booting code region
			pages[i].pp_ref = 1;
			pages[i].pp_link = NULL;
			continue;
		}

		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
```
Control flow: `i386_init()` calls `boot_aps()`, which sets up each processor by copying the code in `mpentry.S` to `KADDR(MPENTRY_PADDR)` and tell the cput to start execute the from that location, thus `mpentry.S` is executed for each CPU. `mpentry.S` does similar work as in `boot/boot.S` and calls `mp_main()` in `init.c`, which does initialization work and then yield the cpu, so that user processes can be scheduled.

### Question
1. Compare `kern/mpentry.S` side by side with `boot/boot.S` (Not `kern/entry.S`!). Bearing in mind that `kern/mpentry.S` is compiled and linked to run above `KERNBASE` just like everything else in the kernel, what is the purpose of macro `MPBOOTPHYS`? Why is it necessary in `kern/mpentry.S` but not in `boot/boot.S`? In other words, what could go wrong if it were omitted in `kern/mpentry.S`?  
    Hint: recall the differences between the link address and the load address that we have discussed in Lab 1.

    The purpose of macro `MPBOOTPHYS` is to convert virtual address to physical address.  
    In `boot.S`, link address is identical to load address and paging is not enabled yet, thus no need for conversion.  
    On the other hand, as part of the kernel code, `mpentry.S` is loaded at address above `KERNBASE`, but `paging` is not enabled yet in `mpentry.S` and we should get its physical address with macro `MPBOOTPHYS`.

### Exercise 3
Remember to unmap `bootstack` and use `PADDR(percpu_kstacks[i])`.
```C
static void
mem_init_mp(void)
{
	// Map per-CPU stacks starting at KSTACKTOP, for up to 'NCPU' CPUs.
	//
	// For CPU i, use the physical memory that 'percpu_kstacks[i]' refers
	// to as its kernel stack. CPU i's kernel stack grows down from virtual
	// address kstacktop_i = KSTACKTOP - i * (KSTKSIZE + KSTKGAP), and is
	// divided into two pieces, just like the single stack you set up in
	// mem_init:
	//     * [kstacktop_i - KSTKSIZE, kstacktop_i)
	//          -- backed by physical memory
	//     * [kstacktop_i - (KSTKSIZE + KSTKGAP), kstacktop_i - KSTKSIZE)
	//          -- not backed; so if the kernel overflows its stack,
	//             it will fault rather than overwrite another CPU's stack.
	//             Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	//
	// LAB 4: Your code here:

	/**
	 * Actually in Lab2 mem_init, we have mapped the region 
	 * [KSTKTOP - PTSIZE, KSTKTOP];
	 * [KSTKTOP - PTSIZE, KSTKTOP - KSTKSIZE]: invalid;
	 * [KSTKTOP - KSTKSIZE, KSTKTOP]: bootstack.
	 * Guessing: now that we have finish booting, we overwrite this region to
	 * be the kernel stack of each CPUs. Bootstack would no longer be used.
	*/

	/* Need to unmap space for bootstack previously. */
	// uintptr_t unmap_va_start, unmap_va_end, va;
	// unmap_va_start = ROUNDDOWN(KSTACKTOP - (KSTKSIZE + KSTKGAP), PGSIZE);
	// unmap_va_end = ROUNDUP(KSTACKTOP, PGSIZE);
	// for(va = unmap_va_start; va < unmap_va_end; va += PGSIZE) {
	// 	page_remove(kern_pgdir, (void *)va);
	// }

	for(int i = 0; i < NCPU; ++i) {
		uintptr_t kstacktop_i = KSTACKTOP - i * (KSTKSIZE + KSTKGAP);
		boot_map_region(kern_pgdir, 
						kstacktop_i - KSTKSIZE,
						ROUNDUP(KSTKSIZE, PGSIZE),
						PADDR(percpu_kstacks[i]),
						PTE_P | PTE_W);
	}
}
```

However, the output is:
```
...
check_page_free_list() succeeded!
check_page_alloc() succeeded!
check_page() succeeded!
kernel panic on CPU 0 at kern/pmap.c:605: remap
...
```
Reason: we are mapping CPU 0's kernel stack to the same virtual address where is previously mapped for `bootstack`. In Lab2, we make `boot_map_region` to disallow `remap`, so we should unmap. However, unmap would not pass `check_page_free_list` (for reason, refer to comment in `boot_map_region()`).  
Actually, disallowing remap is not a behavior required by Lab2, I wrote it previously to simulate xv6. Thus, we relax the constraint by commenting out the check for remap and we do not need to unmap.  

Output:
```
check_page_free_list() succeeded!
check_page_alloc() succeeded!
check_page() succeeded!
check_kern_pgdir() succeeded!
check_page_free_list() succeeded!
check_page_installed_pgdir() succeeded!
SMP: CPU 0 found 1 CPU(s)
enabled interrupts: 1 2
...
```
All memory checks passed.

### Exercise 4
```C
void
trap_init_percpu(void)
{
	// The example code here sets up the Task State Segment (TSS) and
	// the TSS descriptor for CPU 0. But it is incorrect if we are
	// running on other CPUs because each CPU has its own kernel stack.
	// Fix the code so that it works for all CPUs.
	//
	// Hints:
	//   - The macro "thiscpu" always refers to the current CPU's
	//     struct CpuInfo;
	//   - The ID of the current CPU is given by cpunum() or
	//     thiscpu->cpu_id;
	//   - Use "thiscpu->cpu_ts" as the TSS for the current CPU,
	//     rather than the global "ts" variable;
	//   - Use gdt[(GD_TSS0 >> 3) + i] for CPU i's TSS descriptor;
	//   - You mapped the per-CPU kernel stacks in mem_init_mp()
	//   - Initialize cpu_ts.ts_iomb to prevent unauthorized environments
	//     from doing IO (0 is not the correct value!)
	//
	// ltr sets a 'busy' flag in the TSS selector, so if you
	// accidentally load the same TSS on more than one CPU, you'll
	// get a triple fault.  If you set up an individual CPU's TSS
	// wrong, you may not get a fault until you try to return from
	// user space on that CPU.
	//
	// LAB 4: Your code here:

	int id = cpunum();
	uintptr_t stacktop = KSTACKTOP - id * (KSTKSIZE + KSTKGAP);

	/* TSS */
	thiscpu->cpu_ts.ts_esp0 = stacktop;
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
	thiscpu->cpu_ts.ts_iomb = sizeof(struct Taskstate);

	/* TSS descriptor in GDT */
	gdt[(GD_TSS0 >> 3) + id] = SEG16(STS_T32A, 
									(uint32_t) (&(thiscpu->cpu_ts)),
									sizeof(struct Taskstate) - 1, 
									0);
	gdt[(GD_TSS0 >> 3) + id].sd_s = 0;

	/* TSS selector */
	ltr(GD_TSS0 + (cpunum() << 3));

	/* Load the IDT */
	lidt(&idt_pd);
}
```
`ltr(GD_TSS0 + (cpunum() << 3));` is copied from MYK's answer.  

### Question
2. It seems that using the big kernel lock guarantees that only one CPU can run the kernel code at a time. Why do we still need separate kernel stacks for each CPU? Describe a scenario in which using a shared kernel stack will go wrong, even with the protection of the big kernel lock.  

	Consider when user code makes system call with `INT` instruction, going through: `INT -> trapentry.S -> trap()`. Before entering `trap()`, some register values would have already been pushed to the stack. However, the big kernel lock is not required until in `trap()`. Thus, if multiple CPUs are sharing a kernel stack, the values pushed onto the kernel stack before acquiring the lock would mess up.  

### Exercise 5
Easy. Follow the instruction.

### Exercise 6
The hardest part is implementing the round-robin algorithm, though the algorithm seems straight. Possible bugs:
- Forget to check for `curenv` being NULL. Cause page fault in kernel mode.  
- Forget to set `curenc->env_status` to `ENV_RUNNABLE`.
- Forget to do the searching with round back, including `curenv`.
```C
void
sched_yield(void)
{
	struct Env *idle;

	/* Locate current environment */
	int currenv_idx = -1;
	if (curenv) {
		curenv->env_status = ENV_RUNNABLE;
		for(int i = 0; i < NENV; ++i) {
			if (envs[i].env_id == curenv->env_id) {
				currenv_idx = i;
				break;
			}
		}
	}
	
	/* Start searching for runnable environment */
	for(int i = currenv_idx + 1, cnt = 0; cnt < NENV; i = (i + 1) % NENV, ++cnt) {
		if (envs[i].env_status == ENV_RUNNABLE) {
			env_run(&(envs[i]));
		}
	}

	// sched_halt never returns
	sched_halt();
}
```

Remaining parts are easy, just follow the instruction.  
Final output should be:
```
$ make qemu-nox CPUS=4
...
check_page_free_list() succeeded!
check_page_alloc() succeeded!
check_page() succeeded!
check_kern_pgdir() succeeded!
check_page_free_list() succeeded!
check_page_installed_pgdir() succeeded!
SMP: CPU 0 found 4 CPU(s)
enabled interrupts: 1 2
SMP: CPU 1 starting
SMP: CPU 2 starting
SMP: CPU 3 starting
[00000000] new env 00001000
[00000000] new env 00001001
[00000000] new env 00001002
Hello, I am environment 00001001.
Hello, I am environment 00001002.
Hello, I am environment 00001000.
Back in environment 00001001, iteration 0.
Back in environment 00001002, iteration 0.
Back in environment 00001000, iteration 0.
Back in environment 00001001, iteration 1.
Back in environment 00001002, iteration 1.
Back in environment 00001000, iteration 1.
Back in environment 00001001, iteration 2.
Back in environment 00001002, iteration 2.
Back in environment 00001000, iteration 2.
Back in environment 00001001, iteration 3.
Back in environment 00001002, iteration 3.
Back in environment 00001000, iteration 3.
Back in environment 00001001, iteration 4.
Back in environment 00001002, iteration 4.
Back in environment 00001000, iteration 4.
All done in environment 00001001.
All done in environment 00001002.
All done in environment 00001000.
[00001001] exiting gracefully
[00001001] free env 00001001
[00001002] exiting gracefully
[00001002] free env 00001002
[00001000] exiting gracefully
[00001000] free env 00001000
No runnable environments in the system!
Welcome to the JOS kernel monitor!
Type 'help' for a list of commands.
K>  
```

### Question
3. In your implementation of `env_run()` you should have called `lcr3()`. Before and after the call to `lcr3()`, your code makes references (at least it should) to the variable `e`, the argument to `env_run`. Upon loading the `%cr3` register, the addressing context used by the MMU is instantly changed. But a virtual address (namely `e`) has meaning relative to a given address context--the address context specifies the physical address to which the virtual address maps. Why can the pointer e be dereferenced both before and after the addressing switch?  

	Because `env_run` is kernel code and `e` is on kernel stack. Kernel stacks (actually the entire address space for kernel) have the same mapping in `kern_pgdir` and `e->env_pgdir`, and thus it can be referred to in the same way.

4. Whenever the kernel switches from one environment to another, it must ensure the old environment's registers are saved so they can be restored properly later. Why? Where does this happen?  

	Each processor has one single set of registers. To resume execution, they should be saved. In `trapEntry.S`.  


### Exercise 7
This part is long but not hard, given the detailed instruction. Run `make grade` and get full mark for Part A.

## Part B: Copy-on-Write Fork
TLDR: Implement `fork()` with COW, by **user-level page fault handling**.
> COW: on `fork()` the kernel would copy the address space ***mappings*** from the parent to the child instead of the contents of the mapped pages, and at the same time mark the now-shared pages read-only. When one of the two processes tries to write to one of these shared pages, the process takes a page fault. At this point, the Unix kernel realizes that the page was really a "virtual" or "copy-on-write" copy, and so it makes a new, private, writable copy of the page for the faulting process. In this way, the contents of individual pages aren't actually copied until they are actually written to. This optimization makes a `fork()` followed by an `exec()` in the child much cheaper.  
>
> You will implement a "proper" Unix-like `fork()` with copy-on-write, **as a user space library routine**. Implementing `fork()` and copy-on-write support in user space has the benefit that the kernel remains much simpler and thus more likely to be correct. It also lets individual user-mode programs define their own semantics for fork(). A program that wants a slightly different implementation (for example, the expensive always-copy version like dumbfork(), or one in which the parent and child actually share memory afterward) can easily provide its own.
>
> Copy-on-write is only one of many possible uses for user-level page fault handling. It's that page faults indicate when some action is needed. For example, most Unix kernels initially map only a single page in a new process's stack region, and allocate and map additional stack pages later "on demand" as the process's stack consumption increases and causes page faults on stack addresses that are not yet mapped. **A typical Unix kernel must keep track of what action to take when a page fault occurs in each region of a process's space**. For example, a fault in the stack region will typically allocate and map new page of physical memory. A fault in the program's BSS region will typically allocate a new page, fill it with zeroes, and map it. In systems with demand-paged executables, a fault in the text region will read the corresponding page of the binary off of disk and then map it.
>
>This is a lot of information for the kernel to keep track of. Instead of taking the traditional Unix approach, you will decide what to do about each page fault **in user space**, where bugs are less damaging. This design has the added benefit of allowing programs great flexibility in defining their memory regions; you'll use user-level page fault handling later for mapping and accessing files on a disk-based file system.

### Exercise 8
```C
static int
sys_env_set_pgfault_upcall(envid_t envid, void *func)
{
	// LAB 4: Your code here.
	struct Env *env_p;
	int err;

	if((err = envid2env(envid, &env_p, 1)) < 0)
		return err;

	env_p->env_pgfault_upcall = func;
	return 0;
}
```

> Previously, kernel handles exceptions generated in the user mode. When a page fault occurs in user mode (and we want user-level page fault handling), however, the kernel will restart the user environment running a designated user-level page fault handler on a different stack, namely the *user exception stack*. In essence, we will make the JOS kernel implement automatic "stack switching" on behalf of the user environment, in much the same way that the x86 processor already implements stack switching on behalf of JOS when transferring from user mode to kernel mode (user stack => kernel stack)!

### Exercise 9
A very inspiring exercise that strengthens the understanding of system call mechanism and switching stacks.  
```C
void
page_fault_handler(struct Trapframe *tf)
{
	uint32_t fault_va;

	// Read processor's CR2 register to find the faulting address
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if ((tf->tf_cs & 3) == 0) {
		panic("Page fault in kernel-mode!");
	}

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Call the environment's page fault upcall, if one exists.  Set up a
	// page fault stack frame on the user exception stack (below
	// UXSTACKTOP), then branch to curenv->env_pgfault_upcall.
	//
	// The page fault upcall might cause another page fault, in which case
	// we branch to the page fault upcall recursively, pushing another
	// page fault stack frame on top of the user exception stack.
	//
	// It is convenient for our code which returns from a page fault
	// (lib/pfentry.S) to have one word of scratch space at the top of the
	// trap-time stack; it allows us to more easily restore the eip/esp. In
	// the non-recursive case, we don't have to worry about this because
	// the top of the regular user stack is free.  In the recursive case,
	// this means we have to leave an extra word between the current top of
	// the exception stack and the new stack frame because the exception
	// stack _is_ the trap-time stack.
	//
	// If there's no page fault upcall, the environment didn't allocate a
	// page for its exception stack or can't write to it, or the exception
	// stack overflows, then destroy the environment that caused the fault.
	// Note that the grade script assumes you will first check for the page
	// fault upcall and print the "user fault va" message below if there is
	// none.  The remaining three checks can be combined into a single test.
	//
	// Hints:
	//   user_mem_assert() and env_run() are useful here.
	//   To change what the user environment runs, modify 'curenv->env_tf'
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.
	/**
	 * The implementation of thsi function requires a good understanding of the
	 * system call mechanism. You should understand:
	 * 1. Which stack is being used when this function is called? 
	 * Clearly, kernel stack is used and the parameter of this function, tf,
	 * passed from _alltraps, trap(), trap_dispatcher(), refers to the trapframe 
	 * on top of the kernel stack. 
	 * 2. How to invoke the user-level handler, and resume execution of the user
	 * code that causes the page fault?
	 * For system call, returning and switch stack is done by pushing/poping
	 * of trapframes. For system call, %esp and %eip are included into the
	 * trapframe, and when system call finishes and pops off the trapframe, the 
	 * value of %esp and %eip are updated, and resume executing user code.
	 * The idea here is similar.
	 * We call env_run() to invoke user-level handler, which would pop off 
	 * the current trapframe (tf, which is equivalent to curenv->env_tf). Thus, 
	 * we make tf->esp to point to user exception stack, make tf->eip to point 
	 * to user handler.
	 * When the user handler finishes, the trapframe we build on the exception 
	 * handler would be poped off. Thus, we just need to copy the values
	 * of the trapframe on the kernel stack, which is designed to return to user
	 * code.
	*/

	// Allocation of exception stack should be done by the user process, not
	// by the trap handler! The trap handler needs to check whether the user
	// exception stack has been allocated.
	if (curenv->env_pgfault_upcall != NULL){
		struct UTrapframe *utf_p;
		if (UXSTACKTOP - PGSIZE <= tf->tf_esp && tf->tf_esp <= UXSTACKTOP - 1) {
			utf_p = (struct UTrapframe *)tf->tf_esp - 4 - sizeof(struct UTrapframe);
		} else {
			utf_p = (struct UTrapframe *)UXSTACKTOP - sizeof(struct UTrapframe);
		}

		// Check if:
		// 1. the exception stack was allocated;
		// 2. granted writing permission;
		// 3. overflow happens.
		user_mem_assert(curenv, utf_p, sizeof(struct UTrapframe), PTE_W|PTE_U);

		// Build user trap frame on user exception stack
		utf_p->utf_esp = tf->tf_esp;
		utf_p->utf_eflags = tf->tf_eflags;
		utf_p->utf_eip = tf->tf_eip;
		utf_p->utf_regs = tf->tf_regs;
		utf_p->utf_err = tf->tf_err;
		utf_p->utf_fault_va = fault_va;

		tf->tf_eip = (uintptr_t)curenv->env_pgfault_upcall;
		tf->tf_esp = (uintptr_t)utf_p;

		env_run(curenv);
	}

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
	env_destroy(curenv);
}
```

### Exercise 10
Read `pgfault.c`:
```
// Rather than register the C page fault handler directly with the
// kernel as the page fault handler, we register the assembly language
// wrapper in pfentry.S, which in turns calls the registered C
// function.
```
Now that the actual handler has returned, we need to resume user code execution. We cannot use `jmp`, nor `ret` from exception stack (read the comment in `pfentry.S` to understand why).  

The way to do it is to push the trap-time `%eip`, stored in the user trap frame, to the user stack, restore general registers, switch to user stack, and call `ret`. `ret` would pop the top of the stack into `%eip` and the execution resumes.  

The mechanism does not seem complicated, but requires a thorough understanding of the gcc calling convention and shares the idea of system call mechanism.

I really like exercise 9 and 10 :), though it takes long for me to figure out how to do them.

### Exercise 11
Not hard. Follow the instruction. Remember that 0 means current environment as environment id.

Run make grade, you should see:
```
...
Part A score: 5/5

faultread: OK (4.1s) 
faultwrite: OK (2.5s) 
faultdie: OK (3.8s) 
faultregs: OK (2.3s) 
faultalloc: OK (4.7s) 
faultallocbad: OK (3.4s) 
faultnostack: OK (4.4s) 
faultbadhandler: OK (2.6s) 
faultevilhandler: OK (3.1s) 
forktree: FAIL (3.0s) 
    AssertionError: ...
           cs   0x----001b
           flag 0x00000086
           esp  0xeebfdf48
           ss   0x----0023
         qemu: terminating on signal 15 from pid 18850
    MISSING '....: I am .0.'
    MISSING '....: I am .1.'
    MISSING '....: I am .000.'
    MISSING '....: I am .100.'
    MISSING '....: I am .110.'
    MISSING '....: I am .111.'
    MISSING '....: I am .011.'
    MISSING '....: I am .001.'
    MISSING '.00001000. exiting gracefully'
    MISSING '.00001001. exiting gracefully'
    MISSING '.0000200.. exiting gracefully'
    MISSING '.0000200.. free env 0000200.'
    
    QEMU output saved to jos.out.forktree
Part B score: 45/50
```

### UVPT
#### 1-level page table
```
31						11			0
+-----------------------+-----------+
|          PTX          |   offset  |
+-----------------------+-----------+
\___________  __________/
			\/
	virtual page number

Page table index (PTX) could be considered the index/no of the virtual page.
```

#### 2-level page table
![2-level page table](https://pdos.csail.mit.edu/6.828/2018/labs/lab4/pagetables.png "2-level page table")
Traverse though 3 arrows and we arrive at the page.  
Address translation:
```
31		  	21			11			0
+-----------+-----------+-----------+
|   PDX		|   PTX     |   OFFSET  |
+-----------+-----------+-----------+
\____  ____/
	 \/
page table number
\___________  __________/
			\/
	virtual page number

pgdir = lcr3();
pgtbl = *(pgdir + 4 * PDX)
page = *(pgtbl + 4 * PTX)
```
We would use `PDX` to refer to the 10 most-significant bits, `PTX` to the middle 10 bits, and `OFFSET` to the 10 least-significant bits. We use `pgdir_idx`, `pgtbl_idx` and `offset` to refer to the actual values.


#### UVPT & UVPD
we can use the page directory as a page table to map our conceptual giant 2^22-byte page table (represented by 1024 pages) at some contiguous 2^22-byte range in the virtual address space, `[UVPT, UVPT - PTSIZE], PTSIZE = `. And we can ensure user processes can't modify their page tables by marking the PDE entry as read-only.

![UVPT](https://pdos.csail.mit.edu/6.828/2018/labs/lab4/vpt.png "UVPT")
If we put a pointer into the page directory that points back to itself at index V, as shown above, then we can play with the referencing using this 'no-op' pointer operation, as it essentially does nothing.  

Locate a page:
```
31		  	21			11			0
+-----------+-----------+-----------+
| pgdir_idx | pgtbl_idx |  offset   |
+-----------+-----------+-----------+
```

Locate a PTE:
```
31		  	21			11			0
+-----------+-----------+-----------+
|     V		| pgdir_idx | pgtbl_idx |
+-----------+-----------+-----------+
The first arrow leads us back at the page directory, the second arrows leads us to the page table, the third arrow leads us to the PTE.
```

Locate a page table:
```
31		  	21			11			0
+-----------+-----------+-----------+
|     V		|     V	 	| pgdir_idx |
+-----------+-----------+-----------+
The first and second arrows lead us back at the page directory, the third arrow leads us to the page table.
```

#### Mechanism explanation
`kern/env.c`: when the most significant 10 bits of UVPT is used as the page directory index, page table at `PADDR(e->env_pgdir)` would used. In other words, the page directory `e->env_pgdir` would used as a page table!
```C
e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
```
`lib/entry.S`
```as
.data
// Define the global symbols 'envs', 'pages', 'uvpt', and 'uvpd'
// so that they can be used in C as if they were ordinary global arrays.
	.globl envs
	.set envs, UENVS
	.globl pages
	.set pages, UPAGES
	.globl uvpt
	.set uvpt, UVPT
	.globl uvpd
	.set uvpd, (UVPT+(UVPT>>12)*4)
```
`memlayout.h`:
```
 *    UVPT      ---->  +------------------------------+ 0xef400000	
 *                     |          RO PAGES            | R-/R-  PTSIZE
 *    UPAGES    ---->  +------------------------------+ 0xef000000
```
All page tables, which would take 2^10(No. of page tables) * 2^10(No. of page entries in each page table) * 2^2 (size of each PTE) = 2^22 bytes space would be stored at `[UVPT - PTSIZE, UVPT]`. You can think of it as: all the 2nd-level page tables are concatenated together to form a huge table, like a 1-level one.

`UVPT` equals `1110 1111 0100 0000 ... 0000`. So `V` should be the first 10 most significant bits of UVPT, so V = `1110 1111 01` = `0x3BD`. Then `uvpt = UVPT = 0xef400000 = (0x3BD << 22) = (V << 22)`, in otherwords,
```
		31		  	21			11			0
		+-----------+-----------+-----------+
uvpt =	|     V		|	 0		| 	  0	 	|
		+-----------+-----------+-----------+
```
Thus, `uvpt[n]`, n being the index of the virtual page, to get the PTE of the page, as `uvpt[n] = *(uvpt + 4 * n) = *(uvpt + n << 2) = *(uvpt + (PDX << 10 | PTX) << 2) = *(uvpt + PDX << 12 + PTX << 2) = *(V << 22 | PDX << 12 | PTX << 2)`. Recall that in a normal virtual address, the first 20 most significant bits are the index of the virtual page.

Similarly, `uvpt = (UVPT+(UVPT>>12)*4) = UPVP + (UVPT >> 10) = (V << 22) | (V << 12)`. In other words:
```
		31		  	21			11			0
		+-----------+-----------+-----------+
uvpd =	|     V		|	  V		| 	  0	 	|
		+-----------+-----------+-----------+
```
You can use `uvpd[m]`, m being the page table number (which is equivalent to `pgdir_idx`) to get page directory entry.

In short, use `uvpt[PGNUM(va)]` to get the PTE. Use `uvpt[PDX(va)]` to get the PDE.

### Exercise 12
`fork` is complicated. Bugs can happen at:
1. The return value of `sys_exofork` should be checked to tell whether it is in child process or parent process.  
2. `thisenv` should be updated in the child process. Remember that you cannot use `envid2env`, but you can use `envs` and `sys_get_envid()`.  
3. Before calling `uvpt`, you should use `uvpd` to check if the page table is present.  
4. `fork()`: read the comment to understand why exception stack is not copied as COW.  

Run `make grade`, you get:
```
...
Part A score: 5/5

faultread: OK (4.1s) 
faultwrite: OK (2.5s) 
faultdie: OK (3.8s) 
faultregs: OK (2.3s) 
faultalloc: OK (4.7s) 
faultallocbad: OK (3.4s) 
faultnostack: OK (4.4s) 
faultbadhandler: OK (2.6s) 
faultevilhandler: OK (3.1s) 
forktree: OK (3.2s)
Part B score: 50/50
```

**Q & A**  
1. Why we need to mark pages in both child process and parent process as COW? What if we did not mark the pages in the parent process as COW? 

	If pages are not marked as COW in the parent process, then the parent process could directly write to the pages and the changes would be seen by the child process. In other words, the parent process could manipulate the pages of the child process.

2. In `duppage()`, why me mark page in child as COW, and then mark pages in the parent process? Why the order cannot be reversed?

	Suppose  we first mark pages in parent as COW. Before we mark pages in child as COW, the parent process writes to the page and thus a new page would be allocated, and this would be mapped to the child process and marked as COW. Up to now, everything is good. But notice Q1: suppose later the parent process writes to the new page again, this change would be experienced by the child process! Again, the parent is manipulating the child process!   

	If we mark the page in child before marking in parent, even if the parent process writes to the page

When first attempting this exercise, I did not see the words about UVPT in the lab sheet and thus wasted some time hacking. Then it took me several hours to understand how UVPT works, though effectively you just need to know using `uvpt[PGNUM(va)]` and `uvpd[PTX(va)]`:). I also spent some time figuring out that the return value of `sys_exofork` should be checked and I forget to use `envs` and `sys_get_envid` to update `thisenv` in the child process. In addition, initially I did not check `uvpd` before `uvpt`, and encounter page faults. Yes indeed, kernel code is hard to write, many unexpected bugs are possible and you need to be extremely careful!