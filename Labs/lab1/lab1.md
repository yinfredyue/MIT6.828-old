Notes when reading webpate for Lab 1.

### Brennan's Guide to Inline Assembly
http://www.delorie.com/djgpp/doc/brennan/brennan_att_inline_djgpp.html  
Word size in x86 architecture:  
https://stackoverflow.com/a/20273175/9057530  
https://en.wikibooks.org/wiki/X86_Assembly/GAS_Syntax    

Inline Assembly:  
https://wiki.osdev.org/Inline_Assembly

Direction flag:
https://en.wikipedia.org/wiki/Direction_flag#:~:targetText=The%20direction%20flag%20is%20a,on%20all%20x86%2Dcompatible%20CPUs.  

`cli`:  
https://c9x.me/x86/html/file_module_x86_id_29.html

`rep`:  
https://docs.oracle.com/cd/E19455-01/806-3773/instructionset-64/index.html  
https://www.aldeid.com/wiki/X86-assembly/Instructions/rep  

`stos`:  
https://www.felixcloutier.com/x86/stos:stosb:stosw:stosd:stosq  

`leal`:  
https://stackoverflow.com/questions/11212444/what-does-the-leal-assembly-instruction-do

A great explanation on extended asm:  
https://www.ibiblio.org/gferg/ldp/GCC-Inline-Assembly-HOWTO.html#s5 (Read the `Extended Asm` section very carefully).    
Operand-constrait:  
https://gcc.gnu.org/onlinedocs/gcc-4.7.2/gcc/Extended-Asm.html#Extended-Asm

### GDB commands
From CMU 15-213 rec04.pdf.  

- break `<location>`  
Stop execution at function name or address  
Reset breakpoints when restarting gdb 
- run `<args>`
Run program with args `<args>`
- disas `<fun>`, but not dis
- stepi(si) / nexti(ni)  
Steps would step into function calls.  
Next would not enter function.
- info registers  
Print hex values in every register
- print (/x or /d) $eax  
Print hex or decimal contents of %eax  
- x `$register`, x `0xaddress`   
Prints what’s in the register / at the given address  
By default, prints one word (4 bytes)  
Specify format: /s, /[num][size][format]  
`x/8a 0x15213`  
`x/4wd 0xdeadbeef`  

`cmpl`: The `cmpl` instruction compares the contents of general-purpose register (GPR) RA with the contents of GPR RB as unsigned integers and sets one of the bits in Condition Register Field BF.  
http://ps-2.kev009.com/wisclibrary/aix52/usr/share/man/info/en_US/a_doc_lib/aixassem/alangref/cmpl.htm  
https://stackoverflow.com/a/24118885/9057530  

`[f000:e05b]    0xfe05b: cmpl   $0x0, %cs:0x6ac8`. Compare 0 with the the value stored at memory location represented by `cs:0x6ac8` (the `segment:offset` notation). 


- real mode
https://en.wikipedia.org/wiki/Real_mode#:~:targetText=Real%20mode%2C%20also%20called%20real,O%20addresses%20and%20peripheral%20hardware.  
Real mode, also called real address mode, is an operating mode of all x86-compatible CPUs. Real mode is characterized by a 20-bit segmented memory address space (giving exactly 1 MiB of addressable memory) and unlimited direct software access to all addressable memory, I/O addresses and peripheral hardware. Real mode provides no support for memory protection, multitasking, or code privilege levels.  
In real mode (the mode that PC starts off in), address translation works according to the formula with `(segment:offset)` address: `physical address = 16 * segment + offset`. 

- ROM BIOS Setup 
https://qiita.com/kagurazakakotori/items/b092fc0dbe3c3ec09e8e  
https://zhuanlan.zhihu.com/p/36926462  


- Protection mode  
At this point you only have to understand that translation of segmented addresses (segment:offset pairs) into physical addresses happens differently in protected mode, and that after the transition offsets are 32 bits instead of 16.

- Reading `boot.S` and `main.c`  
https://yangbolong.github.io/2017/02/12/lab1/  
https://blackdragonf.github.io/2017/12/09/MIT6-828%E6%93%8D%E4%BD%9C%E7%B3%BB%E7%BB%9F%E5%B7%A5%E7%A8%8BLab1-Booting-a-PC%E5%AE%9E%E9%AA%8C%E6%8A%A5%E5%91%8A/
https://zhuanlan.zhihu.com/p/36926462

### Exercise 3
- At what point does the processor start executing 32-bit code? What exactly causes the switch from 16- to 32-bit mode?  

   Use gdb to trace through `obj/boot/boot.asm`. Set a break point at address `0x7c00` with `b *0x7c00`. Then use `c` to reach the break point. And then use `x/[n]i` to inspect instruction. The first tens of times are very similar to `boot.S`. By reading the comment in `boot.S`, you know switching to 32-bit protection mode happens at `movl    %eax, %cr0`, where the `%cr0` register is set. In gdb, you see the code at `0x7c2a:	mov    %eax,%cr0`.

- What is the last instruction of the boot loader executed, and what is the first instruction of the kernel it just loaded?  

   Reading `boot.S`, you see it calls function `bootmain` in `main.c`. So you easily guess the last instruction of boot loader should be the assembly code of last instruction in `main.c`.   
   In `boot.asm`, you see `00007d15 <bootmmain>`. The function end at `7d6b:	ff 15 18 00 01 00    	call   *0x10018`. Set a breakpoint at that command `b *0x7d6b` and `c`. Then we get:
   ```
   (gdb) b *0x7d6b
   Breakpoint 2 at 0x7d6b
   (gdb) c
   Continuing.
   The target architecture is assumed to be i386
   => 0x7d6b:	call   *0x10018
   ```
   So the last instruction of the boot loader is `call   *0x10018`, and the first instruciton of the loaded kernel the code located at **the address stored at (!!)** `0x10018`.  

   https://www.jianshu.com/p/84f62a05a7e6 Use `x/8x 0x10018` to inspect the content at `0x10018`, we get:
   ```
   (gdb) x/8x 0x10000
   0x10000:	0x464c457f	0x00010101	0x00000000	0x00000000
   0x10010:	0x00030002	0x00000001	0x0010000c	0x00000034
   ```
   So the value stored at `0x10018` is `0x0010000c`, this is the address of our next instruction. Use `x/i 0x10000c` to inpect, we get:
   ```
   (gdb) x/i 0x10000c
      0x10000c:	movw   $0x1234,0x472
   ```
   This is the first instruction of the loaded kernel.

   Note: this quetion is a bit tricky around the command `call *0x10018`. Look at the assembly code in gdb carefully, and you would notice that some `call` command is `call 0x----`, but this one has an `*`. So the asterisk means go to the address stored at `0x10018`. What makes this even more confusing is the way you specify break point in gdb: `break function` and `break *address`: https://ftp.gnu.org/old-gnu/Manuals/gdb/html_node/gdb_28.html. The notation used by gdb has nothing to do with the notation used in assembly code at all! Keep this in mind! `

- Where is the first instruction of the kernel?  
From the last question, you know the first instruction is located at `0x10018`.  

- How does the boot loader decide how many sectors it must read in order to fetch the entire kernel from disk? Where does it find this information?
In `main.c`, `ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff); eph = ph + ELFHDR->e_phnum;`.  

### Exercise 4
Easy exercise on C pointers. Detailed explanation: https://qiita.com/kagurazakakotori/items/b092fc0dbe3c3ec09e8e  

### ELF Format
Read the content on ELF format very carefully.  

### Exercise 5
Did not fully understand. Of course dismatching the link address and load address would cause problem.  

### Exercise 6
When BIOS starts, memory location starting from `0x100000` are not used and the content at that address is all 0's. When boot loader enters the kernel, there are some contents are address `0x100000`. Clearly this is because the kernel is loaded into the memory.  

### Exercise 7
Virtual memory is introduced at this point. Kernel code is usually linked and executed at a *high* virtual address, in order to leave the lower part of the virtual memory space to the user programs. However, many machines do not have enough physical memory and thus virtual memory is introduced.  
This switch from directly using physical memory address to using virtual memory address is achieved by setting the `CP0_PG` flag in `kern/entry.S`. Once CR0_PG is set, memory references are virtual addresses that get translated by the virtual memory hardware to physical addresses.  
At this point, only 4MB are mapped: virtual addresses in the range `0xf0000000` through `0xf0400000` are mapped to physical addresses `0x00000000` through `0x00400000`. Virtual addresses `0x00000000` through `0x00400000` are ALSO mapped to physical addresses `0x00000000` through `0x00400000`. Any virtual address that is not in one of these two ranges will cause a hardware exception which, since we haven't set up interrupt handling yet, will cause QEMU to dump the machine state and exit.

In `entry.S`, there is this code snippet:
```
movl	$(RELOC(entry_pgdir)), %eax
movl	%eax, %cr3

# Turn on paging.
movl	%cr0, %eax
orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
movl	%eax, %cr0   <-- set the flag
```
Restart the emulator, remembering that the start of the kernel code is stored at address `*0x10080 == 0x10000c`. So `b *0x10000c`, `c`, and then
```
(gdb) x/30i 0x10000c
=> 0x10000c:	movw   $0x1234,0x472
   0x100015:	mov    $0x112000,%eax
   0x10001a:	mov    %eax,%cr3
   0x10001d:	mov    %cr0,%eax
   0x100020:	or     $0x80010001,%eax 
   0x100025:	mov    %eax,%cr0
   0x100028:	mov    $0xf010002f,%eax
   0x10002d:	jmp    *%eax
   0x10002f:	mov    $0x0,%ebp
   0x100034:	mov    $0xf0110000,%esp
```
Compare with `entry.S`, we know that `0x100025:	mov    %eax,%cr0` is the line that sets the `CR0_PG` flag. `b *0x100025`, `c`. At this point, we examine the memory address before and after executing this line:
```
(gdb) x/4x 0x100000
0x100000:	0x1badb002	0x00000000	0xe4524ffe	0x7205c766
(gdb) x/4x 0xf0100000
0xf0100000 <_start+4026531828>:	0x00000000	0x00000000	0x00000000	0x00000000
(gdb) ni
=> 0x100028:	mov    $0xf010002f,%eax
0x00100028 in ?? ()
(gdb) x/4x 0xf0100000
0xf0100000 <_start+4026531828>:	0x1badb002	0x00000000	0xe4524ffe	0x7205c766
(gdb) x/4x 0x100000
0x100000:	0x1badb002	0x00000000	0xe4524ffe	0x7205c766
```
Before setting `CR0_PG`, `0x100000` and `0xf0100000` have different content. After `CR0_PG` is set, `0x00100000` and `0xf0100000` (different virtual memory addresses) maps to the same physical memory address and the result is the same.  

If this mapping is disabled, the instruction `0x10002d:	jmp    *%eax` would fail, because it accesses address `0xf010002f`, which should have been mapped to a physical address.  

### Exercise 8
- We have omitted a small fragment of code - the code necessary to print octal numbers using patterns of the form "%o". Find and fill in this code fragment.  

   Not a hard problem. Locate the code and consult the code within the same function, you easily get the solution:
   ```C
   case 'o':
			// Code by YY
			num = getint(&ap, lflag);
			base = 8;
			goto number;
   ```

1. Explain the interface between printf.c and console.c. Specifically, what function does console.c export? How is this function used by printf.c?
As stated in the comment in `printf.c` and `console.c`, `cputchar()` is provided by `console.c` and used by `printf.c`. Thus the underlying import and export are not fully understood.  

2. Explain the following from console.c:
   ```C
   if (crt_pos >= CRT_SIZE) {
      int i;
      memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
      for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
         crt_buf[i] = 0x0700 | ' ';
         crt_pos -= CRT_COLS;
      }
   ```
   Reading the function `cga_putc` carefully and guessing the meaning of `crt_buf`, `crt_pos`, `CRT_SIZE`, `CRT_COL`, this function is probably move all lines one row above when the console is full. About the constant `0x0700`, highly likely that the high order bits are controlling the FG and BG color of the text (https://stackoverflow.com/a/43221581/9057530).  

For the following questions you might wish to consult the notes for **Lecture 2**. These notes cover GCC's calling convention on the x86.  

3. Trace the execution of the following code step-by-step:
   ```C
   int x = 1, y = 3, z = 4;
   cprintf("x %d, y %x, z %d\n", x, y, z);
   ```
   - In the call to cprintf(), to what does fmt point? To what does ap point?
   - List (in order of execution) each call to cons_putc, va_arg, and vcprintf. For cons_putc, list its argument as well. For va_arg, list what ap points to before and after the call. For vcprintf list the values of its two arguments.  

4. Run the following code.
   ```C
   unsigned int i = 0x00646c72;
   cprintf("H%x Wo%s", 57616, &i);
   ```
What is the output? Explain how this output is arrived at in the step-by-step manner of the previous exercise. Here's an ASCII table that maps bytes to characters.
The output depends on that fact that the x86 is little-endian. If the x86 were instead big-endian what would you set i to in order to yield the same output? Would you need to change 57616 to a different value?

Here's a description of little- and big-endian and a more whimsical description.

In the following code, what is going to be printed after 'y='? (note: the answer is not a specific value.) Why does this happen?
    cprintf("x=%d y=%d", 3);
Let's say that GCC changed its calling convention so that it pushed arguments on the stack in declaration order, so that the last argument is pushed last. How would you have to change cprintf or its interface so that it would still be possible to pass it a variable number of arguments?






