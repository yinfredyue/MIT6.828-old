## Lab2
From this lab, you start building your JOS. It illustrates how you set up the upper part of the virtual address (kernel part) after booting the camera.  
You need to understand the following for this lab.  
1. What `entry.S` does:  
    - Set up `entry_pgdir` page table.  
        `Entry_pgdir` is the hand-written page table used at the start of booting, defined in `/kern/entrypgdir.c`. You can see how it maps virtual address `[0, 4M]` to physical address `[0, 4M]`, as well as `[KERNBASE, KERNBASE + 4M]` to physical address `[0, 4M]`. Store the address of `entry_pgdir` into `%cr3`.
    - Turn on paging.   
        By storing `CR0_PG` into `%cr0`.  
    - Reserve stack space in the `.data` segment, yielding symbol `bootstacktop` and `bootstack`.
    - Call `i386_init`.  
2. What should we do in `mem_init`.  
    - Note: since paging has been turned on, all C pointers or addresses are virtual addresses. Our goal is to use two-level page table instead of `entry_pgdir`. 
    - Allocate physical space for 4096-byte `pgdir` and `pages` (a list representing all physical frames), using `boot_alloc`. `boot_alloc` allocates physical memory from the 4MB space mapped by `entry_pgdir`. Set up `page_free_list` to represent free physical frames in `page_init()`.
    - Then we start building the two-level page table, with `boot_map_region()`. We need to map:
        - page table itself to `UPAGES` in virtual address.
        - kernel stack (at physical address `bootstack`) to `KSTKTOP - KSTKSIZE` in virtual address. 
        - Map all physical memory to `KERNBASE` in virtual address.  
    - Set `%cr3` to use `pgdir`, and set other flags.

**Q & A** 
- Why map 4MB in `entry_pgdir`?  

    4MB, `0xf0400000`, is enough include: `.text`, `.data`, `.bss` for kernel, 4096-byte `pgdir`, and the list of `struct PageInfo` at `pages`.  
    Effectively, kernel code and data is put to physical address `0x00100000` at booting time. In `mem_init`, the value of `end` before making any call to `boot_alloc` is `0xf011a000`. So:  

    `0x00100000` - `0x0011a000`: kernel code & data  
    `0x0011a000` - `0x00400000`: `pgdir` and `pages`.

- Do we have to consider `entry_pgdir` when building the new page table? 

    No. They are completely separated. Though it seems that the command of `info mem` and `info pg` in `qemu` uses the current page table, pointed to by `%cr3`.  

- In `boot_map_region`, we only fill in the page table. Do we have to make changes to `page_free_list`?  
    
    **No**. This can be confusing. At this point, all memory needed by the kernel have already been allocated in physical memory: code & data segments, `pgdir` and used page tables (which are allocated with `page_alloc`) and `pages`. So we would not call `page_alloc` to allocate any physical memory when mapping -- we do not need them!  

- What is `extern char end[]`?
    ```
    yy0125@yy0125:/media/sf_MIT6_828/Labs/lab$ objdump -h obj/kern/kernel

    obj/kern/kernel:     file format elf32-i386

    Sections:
    Idx Name          Size      VMA       LMA       File off  Algn
    0 .text         000042f9  f0100000  00100000  00001000  2**4
                    CONTENTS, ALLOC, LOAD, READONLY, CODE
    1 .rodata       00001198  f0104300  00104300  00005300  2**5
                    CONTENTS, ALLOC, LOAD, READONLY, DATA
    2 .stab         000069e5  f0105498  00105498  00006498  2**2
                    CONTENTS, ALLOC, LOAD, READONLY, DATA
    3 .stabstr      00001e63  f010be7d  0010be7d  0000ce7d  2**0
                    CONTENTS, ALLOC, LOAD, READONLY, DATA
    4 .data         00009300  f010e000  0010e000  0000f000  2**12
                    CONTENTS, ALLOC, LOAD, DATA
    5 .got          0000000c  f0117300  00117300  00018300  2**2
                    CONTENTS, ALLOC, LOAD, DATA
    6 .got.plt      0000000c  f011730c  0011730c  0001830c  2**2
                    CONTENTS, ALLOC, LOAD, DATA
    7 .data.rel.local 00001000  f0118000  00118000  00019000  2**12
                    CONTENTS, ALLOC, LOAD, DATA
    8 .data.rel.ro.local 00000060  f0119000  00119000  0001a000  2**5
                    CONTENTS, ALLOC, LOAD, DATA
    9 .bss          00000674  f0119060  00119060  0001a060  2**5
                    CONTENTS, ALLOC, LOAD, DATA
    10 .comment      0000002b  00000000  00000000  0001a6d4  2**0
                    CONTENTS, READONLY
    ```
    You see that `.comment` is not loaded into memory and thus `.bss` is the last section. Thus, `end`, which is the end of `.bss` section, is the first virtual address that is not used.

- Why JOS maps physical memory starting from `0x00000000` to virtual memory staring from `0xf0000000`?  
    A common operation JOS would do is to read/write to memory, knowing the physical address but not the virtual address. However, ever since paging is turned on in `entry.S`, all C pointers are in virtual address space. By mapping physical memory starting from `0x00000000` to virtual memory staring from `0xf0000000`, JOS would be able to directly operate a memory block in physical memory easily, by operating on the virtual address of `(KERNBASE + phy_addr)`. This is actually what `KADDR` does for us.

- `qemu` only detects 128MB = 2 ^ 27 bytes = 0x8000000.

### Questions
3. We have placed the kernel and user environment in the same address space. Why will user programs not be able to read or write the kernel's memory? What specific mechanisms protect the kernel memory?  

    Permission bit. User cannot access memory if `PTE_U` is not set.
4. What is the maximum amount of physical memory that this operating system can support? Why?  

    I read the following answers:  

    Answer1: `UPAGES` section is mapped from array of `struct PageInfo` and allows 4MB storage. Each `struct PageInfo` takes 8 byte so in total `(4MB / 8 byte) * 4 KB = 2 ^ 31 KB = 2 GB`.

    Answer2: 32-bit machine supporst 4GB physical memory.  

    Answer3: JOS allows 256MB for kernel code, which is mapped to the physical memory, thus 256MB.  

    *Analysis*  
    Answer1 is correct. In virtual address space, the space for kernel in virtual address maps to the bottom block of physical memory, where the kernel code can directly operate on (the reason is presented previously). In other words, kernel has total control on this part of the physical memory and no more.  
    Answer2 is clearly wrong. Number of bits determine the size of virtual address space.  
    Answer3 notices one of the limitations, but it is not the constraint here.

5. How much space overhead is there for managing memory, if we actually had the maximum amount of physical memory? How is this overhead broken down?  
    Overhead is unchanged for different amount of physical memory. It is determined by the size of the virtual address space. So 4MB for page table and 4KB for page directory, plus 8-byte * (256MB/4KB) = 32 KB. So in total = 4 MB + 36 KB = 4132 KB. 

6. Revisit the page table setup in `kern/entry.S` and `kern/entrypgdir.c`. Immediately after we turn on paging, EIP is still a low number (a little over 1MB). At what point do we transition to running at an `EIP` above `KERNBASE`? What makes it possible for us to continue executing at a low EIP between when we enable paging and when we begin running at an EIP above KERNBASE? Why is this transition necessary?  

    ```
    # Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
	movl	%eax, %cr3
	# Turn on paging.
	movl	%cr0, %eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
	movl	%eax, %cr0      <==  Paging enabled

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
	jmp	*%eax               <== %eip change to high address
    ```
    `movl %eax, %cr0` enables paging, but only after `jmp *%eax`, eip becomes at a high address. However, in the meanwhile, the execution continues fine because both `[0, 4MB]` and `[KERNBASE, KERNBASE + 4MB]` in virtual memory is mapped to the same block `[0, 4MB]` in physical memory and thus even though the value of `%esp` changes, they are reading at the same block of physical memory and the same set of instructions.  
    This transition is necessary is necesary because after the real paging table is set up, low address is virtual memory would not be mapped and the kernel would crash.  



    

    


