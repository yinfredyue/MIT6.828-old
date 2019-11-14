Notes when reading webpate for Lab 1.

### Brennan's Guide to Inline Assembly
Link: http://www.delorie.com/djgpp/doc/brennan/brennan_att_inline_djgpp.html  

Only `The Syntax` section is required by the lab sheet. You may skip the content below in this note.  

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
From CMU 15-213 `rec04.pdf`.  

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

`[f000:e05b]    0xfe05b: cmpl   $0x0, %cs:0x6ac8`. Compare 0 with the the value stored at memory location represented by `cs:0x6ac8` (the `segment:offset` notation). 


- real mode
https://en.wikipedia.org/wiki/Real_mode#:~:targetText=Real%20mode%2C%20also%20called%20real,O%20addresses%20and%20peripheral%20hardware.  
Real mode, also called real address mode, is an operating mode of all x86-compatible CPUs. Real mode is characterized by a 20-bit segmented memory address space (giving exactly 1 MiB of addressable memory) and unlimited direct software access to all addressable memory, I/O addresses and peripheral hardware. Real mode provides no support for memory protection, multitasking, or code privilege levels.  
In real mode (the mode that PC starts off in), address translation works according to the formula with `(segment:offset)` address: `physical address = 16 * segment + offset`. 

- ROM BIOS Setup 
https://qiita.com/kagurazakakotori/items/b092fc0dbe3c3ec09e8e  
https://zhuanlan.zhihu.com/p/36926462  
This is also described in detail in the xv6 book appendix B.


- Protection mode  
At this point you only have to understand that translation of segmented addresses (segment:offset pairs) into physical addresses happens differently in protected mode, and that after the transition offsets are 32 bits instead of 16.

- Reading `boot.S` and `main.c`  
https://yangbolong.github.io/2017/02/12/lab1/  
https://blackdragonf.github.io/2017/12/09/MIT6-828%E6%93%8D%E4%BD%9C%E7%B3%BB%E7%BB%9F%E5%B7%A5%E7%A8%8BLab1-Booting-a-PC%E5%AE%9E%E9%AA%8C%E6%8A%A5%E5%91%8A/
https://zhuanlan.zhihu.com/p/36926462

### Exercise 3
- At what point does the processor start executing 32-bit code? What exactly causes the switch from 16- to 32-bit mode?  

   Use gdb to trace through `obj/boot/boot.asm`. Set a break point at address `0x7c00` with `b *0x7c00`. Then use `c` to reach the break point. And then use `x/[n]i` to inspect instruction. The first tens of lines are very similar to `boot.S`. By reading the comment in `boot.S`, you know 32-bit protection mode is enabled at `movl    %eax, %cr0`, where the `%cr0` register is set. In gdb, you see the code at `0x7c2a:	mov    %eax,%cr0`.  
   However, the xv6 book appendix B would tell your that it is the next jump instruction `ljmp    $PROT_MODE_CSEG, $protcseg` that cause the switch effectively. 

- What is the last instruction of the boot loader executed, and what is the first instruction of the kernel it just loaded?  

   Reading `boot.S`, you see it calls function `bootmain` in `main.c`. So you easily guess the last instruction of boot loader should be the assembly code of last instruction of `bootmain` function in `main.c`.   
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

   Note: this quetion is a bit tricky around the command `call *0x10018`. Look at the assembly code in gdb carefully, and you would notice that some `call` command is `call 0x----`, but this one has an `*` before the address. The asterisk means go to the address stored at `0x10018`. What makes this even more confusing is the way you specify break point in gdb: `break function` and `break *address`: https://ftp.gnu.org/old-gnu/Manuals/gdb/html_node/gdb_28.html. The notation used by gdb has nothing to do with the notation used in assembly code at all! Keep this in mind!

- Where is the first instruction of the kernel?  
From the last question, you know the first instruction is located at `0x1000c`.  

- How does the boot loader decide how many sectors it must read in order to fetch the entire kernel from disk? Where does it find this information?
In `main.c`, `ph = (struct Proghdr *) ((uint8_t *) ELFHDR + ELFHDR->e_phoff); eph = ph + ELFHDR->e_phnum;`.  

### Exercise 4
Easy exercise on C pointers. Detailed explanation: https://qiita.com/kagurazakakotori/items/b092fc0dbe3c3ec09e8e  

### ELF Format
Read the content on ELF format very carefully.  

### Exercise 5
Did not fully understand. Of course dismatching the link address and load address would cause problem.  

### Exercise 6
When BIOS starts, memory location starting from `0x100000` are not used and the content at that address is all 0's. When boot loader enters the kernel, there are some contents are address `0x100000`. Clearly this is because the kernel is loaded into the memory. This is also explained in xv6 book: `The memory from 0xa0000 to 0x100000 is typically littered with device memory regions, and the xv6 kernel expects to be placed at 0x100000`.

### Exercise 7
Kernel code is usually linked and executed at a *high* virtual address, in order to leave the lower part of the virtual memory space to the user programs. However, many machines do not have enough physical memory and thus virtual memory is introduced.  
This switch from directly using physical memory address to using virtual memory address is achieved by setting the `CP0_PG` flag in `kern/entry.S`. Once `CR0_PG` is set, memory references are virtual addresses that get translated by the virtual memory hardware to physical addresses.  
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
(gdb) x/10i 0x10000c
=> 0x10000c:	movw   $0x1234,0x472
   0x100015:	mov    $0x112000,%eax
   0x10001a:	mov    %eax,%cr3
   0x10001d:	mov    %cr0,%eax
   0x100020:	or     $0x80010001,%eax 
   0x100025:	mov    %eax,%cr0
   0x100028:	mov    $0xf010002f,%eax
   0x10002d:	jmp    *%eax
   0x10002f:	mov    $0x0,%ebp
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

        The first problem is where to put the code? Recall that when qemu is started, there are some output in the window and what you just fixed is somewhere that uses `%o` format. Search through the file, you should see the function is `i386_init` in `kern/init.c`. 

        Copy the code into the function, `make`, and open gdb again. (Note that putting the code at the start of `i386_init` function causes error when starting the qume. Maybe it's because some setup work, like `cons_init()`, needs to be done. Putting the code before the `while` loop and it works.) Then
        ```
        (gdb) info function i386_init
        All functions matching regular expression "i386_init":

        File kern/init.c:
        void i386_init(void);
        (gdb) break i386_init
        Breakpoint 1 at 0xf01000a6: file kern/init.c, line 24.
        (gdb) c
        Continuing.
        The target architecture is assumed to be i386
        => 0xf01000a6 <i386_init>:	push   %ebp

        Breakpoint 1, i386_init () at kern/init.c:24
        24	{
        ``` 
        As you are inside a function, it is much easier to step through the code as you can use `disas function`. Use knowledge from gcc x86 calling convention, function prologue/epilogue to analyze the assembly.
        ```
        // Note: this is the assembly code where the code in inserted at the beginning of 
        // the i386_init function. However, the analysis is the same.

        (gdb) disas i386_init
        Dump of assembler code for function i386_init:
        =>  0xf01000a6 <+0>:	push   %ebp             // function prologue
            0xf01000a7 <+1>:	mov    %esp,%ebp
            0xf01000a9 <+3>:	push   %ebx             // Push callee-saved register %ebx
            0xf01000aa <+4>:	sub    $0x4,%esp        // Allocate 4 bytes on stack
            0xf01000ad <+7>:	call   0xf01001d1 <__x86.get_pc_thunk.bx>  
            // __x86.get_pc_thunk.bx function: https://stackoverflow.com/q/6679846/9057530
            // The address of next instruction becomes the value of %ebx
            0xf01000b2 <+12>:	add    $0x11256,%ebx    // (*1)
            0xf01000b8 <+18>:	push   $0x4             // pushing arguments on stack
            0xf01000ba <+20>:	push   $0x3             // Note: under 32-bit, pushing
            0xf01000bc <+22>:	push   $0x1             // immediate always push 4 bytes
            0xf01000be <+24>:	lea    -0xf891(%ebx),%eax   // (*2)
            0xf01000c4 <+30>:	push   %eax                 // (*3): (*1~3) should be 1st arg
            0xf01000c5 <+31>:	call   0xf0100a5e <cprintf> 
            0xf01000ca <+36>:	add    $0xc,%esp
            0xf01000cd <+39>:	mov    $0xf0113060,%edx
            0xf01000d3 <+45>:	mov    $0xf01136a0,%eax
            0xf01000d9 <+51>:	sub    %edx,%eax
            0xf01000db <+53>:	push   %eax
            0xf01000dc <+54>:	push   $0x0
            0xf01000de <+56>:	push   %edx
            0xf01000df <+57>:	call   0xf01015f2 <memset>
            0xf01000e4 <+62>:	call   0xf0100626 <cons_init>
            0xf01000e9 <+67>:	add    $0x8,%esp
            0xf01000ec <+70>:	push   $0x1aac
            0xf01000f1 <+75>:	lea    -0xf87f(%ebx),%eax
            0xf01000f7 <+81>:	push   %eax
            0xf01000f8 <+82>:	call   0xf0100a5e <cprintf>
            0xf01000fd <+87>:	movl   $0x5,(%esp)
            0xf0100104 <+94>:	call   0xf0100040 <test_backtrace>
            0xf0100109 <+99>:	add    $0x10,%esp
            0xf010010c <+102>:	sub    $0xc,%esp
            0xf010010f <+105>:	push   $0x0
            0xf0100111 <+107>:	call   0xf01008a2 <monitor>
            0xf0100116 <+112>:	add    $0x10,%esp
            0xf0100119 <+115>:	jmp    0xf010010c <i386_init+102>
        End of assembler dump.
        (gdb) b *0xf01000c5
        Breakpoint 2 at 0xf01000c5: file kern/init.c, line 27.
        (gdb) c
        Continuing.
        => 0xf01000c5 <i386_init+31>:	call   0xf0100a5e <cprintf>

        Breakpoint 2, 0xf01000c5 in i386_init () at kern/init.c:27
        27		cprintf("x %d, y %x, z %d\n", x, y, z);
        (gdb) x/s $eax
        0xf0101a77:	"x %d, y %x, z %d\n"
        (gdb) si
        => 0xf0100a5e <cprintf>:	push   %ebp
        cprintf (fmt=0xf0101a77 "x %d, y %x, z %d\n") at kern/printf.c:27
        27	{
        (gdb) disas cprintf
        Dump of assembler code for function cprintf:
        =>  0xf0100a5e <+0>:	push   %ebp         // function prologue
            0xf0100a5f <+1>:	mov    %esp,%ebp
            0xf0100a61 <+3>:	sub    $0x10,%esp   // allocate 16 bytes
            0xf0100a64 <+6>:	lea    0xc(%ebp),%eax  // %eax = (%ebp + 12) = 2nd arg to cprintf
            0xf0100a67 <+9>:	push   %eax         // push 2nd arg to vcprintf, ap = %eax
            0xf0100a68 <+10>:	pushl  0x8(%ebp)    // push 1st arg to vcprintf, fmt
            0xf0100a6b <+13>:	call   0xf0100a27 <vcprintf>
            0xf0100a70 <+18>:	leave               // function epilogue
            0xf0100a71 <+19>:	ret    
        End of assembler dump.
        (gdb) ni 2
        => 0xf0100a61 <cprintf+3>:	sub    $0x10,%esp
        0xf0100a61	27	{
        (gdb) disas cprintf
        Dump of assembler code for function cprintf:
            0xf0100a5e <+0>:	push   %ebp
            0xf0100a5f <+1>:	mov    %esp,%ebp
        =>  0xf0100a61 <+3>:	sub    $0x10,%esp
            0xf0100a64 <+6>:	lea    0xc(%ebp),%eax
            0xf0100a67 <+9>:	push   %eax
            0xf0100a68 <+10>:	pushl  0x8(%ebp)
            0xf0100a6b <+13>:	call   0xf0100a27 <vcprintf>
            0xf0100a70 <+18>:	leave  
            0xf0100a71 <+19>:	ret    
        End of assembler dump.
        (gdb) x/d $ebp+0xc
        0xf010ffe4:	1
        (gdb) x/d $ebp+0x10
        0xf010ffe8:	3
        (gdb) x/d $ebp+0x14
        0xf010ffec:	4
        ```
        Be careful that: `pushl  0x8(%ebp)` means push `mem[Reg[%ebp] + 0x8]`, so the pushed value is actually `*(%ebp + 0x8)`.
        ```
        (gdb) x/a 0xf010ffd8+0x8
        0xf010ffe0:	0xf0101a77
        (gdb) x/s 0xf0101a77
        0xf0101a77:	"x %d, y %x, z %d\n"
        (gdb) x/s *(0xf010ffd8+0x8)
        0xf0101a77:	"x %d, y %x, z %d\n"
        (gdb) x fmt
        0xf0101a77:	"x %d, y %x, z %d\n"
        (gdb) x ap  
        No symbol "ap" in current context. // Do not know why this happens.
        ```
        gdb keeps giving "No symobl" error when trying to inspect `ap`, the 2nd argument, but we konw it is an `va_list`. You may also check the answer in this link: https://qiita.com/kagurazakakotori/items/b092fc0dbe3c3ec09e8e#exercise-8.  
    - List (in order of execution) each call to `cons_putc`, `va_arg`, and `vcprintf`. For `cons_putc`, list its argument as well. For `va_arg`, list what ap points to before and after the call. For `vcprintf` list the values of its two arguments.  
        - `cons_putc` is defined in `console.c`. `va_arg` is a macro defined in `stdarg.h`: `#define va_arg(ap, type) __builtin_va_arg(ap, type)`. `vcprintf` is defined in `print.c`.  
        - The relationship, `->` means "calls": `cprintf -> [vcprintf] -> vprintfmt -> putch, [va_arg] -> cputchar -> [cons_putc]`.
        - For `vcprintf`:
            ```
            // Calling vcprintf in cprintf
            (gdb) disas cprintf 
            Dump of assembler code for function cprintf:
                0xf0100a5e <+0>:	push   %ebp
                0xf0100a5f <+1>:	mov    %esp,%ebp
                0xf0100a61 <+3>:	sub    $0x10,%esp
                0xf0100a64 <+6>:	lea    0xc(%ebp),%eax
                0xf0100a67 <+9>:	push   %eax
                0xf0100a68 <+10>:	pushl  0x8(%ebp)
            =>  0xf0100a6b <+13>:	call   0xf0100a27 <vcprintf>
                0xf0100a70 <+18>:	leave  
                0xf0100a71 <+19>:	ret    
            End of assembler dump.
            (gdb) x /a  $ebp
            0xf010ffc8:	0xf010fff8
            (gdb) x /s *(0xf010ffc8 + 0x8)
            0xf0101a77:	"x %d, y %x, z %d\n"
            (gdb) x/s $eax
            0xf010ffd4:	"\001"

            // When vcprintf is called:
            // fmt = 0xf0101a77 "x %d, y %x, z %d\n"
            // ap = 0xf010ffd4	"\001"

            // Then vcprintf calls printfmt
            // Then printfmt calls putch, va_arg
            // putch calls cputchar
            // cputchar calls cons_putc
            ``` 
        - For `cons_putc`:
            ```
            (gdb) b cons_putc 
            Breakpoint 5 at 0xf0100385: file kern/console.c, line 70.
            (gdb) c
            Continuing.
            => 0xf0100385 <cons_putc+23>:	mov    $0x0,%esi

            Breakpoint 5, cons_putc (c=120) at kern/console.c:70
            70		for (i = 0;

            // keeps using `continue`/`c`, then you the whole sequence.
            c_value     ascii_char
            120         'x'
            32          ' '
            49          '1' 
            44          ','
            32          ' '
            121         'y'
            32          ' '
            51          '3'
            44          ','
            32          ' '
            122         'z'
            32          ' '
            52          '4'
            10          `\n`
            Which constructs: "x 1, y 3, z 4\n"
            ```
        - For `va_arg`:  
            `va_arg` is defined as a macro and we get set breakpoint to it. Then we find that in `printfmt.c`, both `getint` and `getuint` use this macro.  
            The exact execution detail is not explored. Read https://www.jianshu.com/p/84f62a05a7e6 and https://qiita.com/kagurazakakotori/items/b092fc0dbe3c3ec09e8e#exercise-8 to get the idea. 

4. Run the following code.
   ```C
   unsigned int i = 0x00646c72;
   cprintf("H%x Wo%s", 57616, &i);
   ```
    - What is the output? Explain how this output is arrived at in the step-by-step manner of the previous exercise.  
    
        Function execution is similar to the code above. `%s` is matched in the switch statement in `vprintfmt` in `printfmt.c`. The output is `He110 World`.  

    - The output depends on that fact that the x86 is little-endian. If the x86 were instead big-endian what would you set i to in order to yield the same output? Would you need to change `57616` to a different value?  
        - big/little endian revisited  
            - when multi-byte data is put into memory, it is written to the lower memory address before going to higher address.  
            - Read the [link](https://www.webopedia.com/TERM/B/big_endian.html).  
                Big endian: the most significant bit is stored first, i.e., in the lowest address.
                Little endian: the least significant bit is stored first, i.e., in the lowest address.  
        - In our case, `unsigned int i = 0x00646c72`. Refer to the ASCII table, `0x00`: `\0`, `0x64`: `d`, `0x6c`: `l`, `0x72`: `o`. By convention, x86 architecture uses little-endian and `0x72` is stored first and `0x00` is stored last. The value is stored as:
            ```
            4                   0
            +----+----+----+----+
            | 00 | 64 | 6c | 72 |
            +----+----+----+----+
            ```
        - If changed to big -endian, then should be changed to `0x726c6400`. For `57616`, though it is stored differently on under different endian, they are fetched to be the same and does not need to change.


5. In the following code, what is going to be printed after 'y='? (note: the answer is not a specific value.) Why does this happen?
    ```
    cprintf("x=%d y=%d", 3);
    ```
    The result is undefined. 

6. Let's say that GCC changed its calling convention so that it pushed arguments on the stack in declaration order, so that the last argument is pushed last. How would you have to change cprintf or its interface so that it would still be possible to pass it a variable number of arguments?  

    Reverse the order of input arguments in the C code.  




