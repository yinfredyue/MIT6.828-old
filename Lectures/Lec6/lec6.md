## Lecture 6

`%cr3` stores the physical address of page directory. 


### Case study: xv6 address space setup (reading code)
```
0x00000000:0x80000000 -- user addresses below KERNBASE
0x80000000:0x80100000 -- map low 1MB devices (for kernel)
0x80100000:?          -- kernel instructions/data
(0x80000000:0x8E000000 -- 224 MB of DRAM mapped here)
0xFE000000:0x00000000 -- more memory-mapped devices at high address
```
```
- bootblock.asm(bootasm.S): bootmain() -> entry(): call *0x10018
- kernel.asm(entry.S) -> main.c: main().
- entrypgdir used at boot time is defined in main.c.
- What main() does to setup the kernel part of virtual address is 
similar to Lab 2. 
    kinit1(): free memory in [end, 4MB).
    kvmalloc(): setup page directory, map regions, and 
                switch to new page table.
    kini2(): free memory in [4MB, PHYSTOP).

- Take a look at growproc() and allocuvm().
```