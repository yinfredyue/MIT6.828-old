## xv6 booting mechanism


```
Memory layout
0x00000000:0x80000000 -- user addresses below KERNBASE
0x80000000:0x80100000 -- map low 1MB devices (for kernel)
0x80100000:?          -- kernel instructions/data
(0x80000000:0x8E000000 -- 224 MB of DRAM mapped here)
0xFE000000:0x00000000 -- more memory-mapped devices at high address
```
- Entry point at `start` in `bootblock.asm`, kernel code loaded at memory `0x7c00`. `start` calls `bootmain`.
- `bootmain`: `call *0x10018`, which is function `entry()`.
- `entry()` is in `kernel.asm`, call `main()` in `main.c`.
- `entrypgdir` used at boot time is defined in `main.c`.
- What `main()` does to setup the kernel part of virtual address is similar to Lab 2. 
    - `kinit1()`: free memory in [end, 4MB).
    - `kvmalloc()`: setup page directory, map regions, and 
                switch to new page table.
    - `kinit2()`: free memory in [4MB, PHYSTOP).

- Take a look at `growproc`() and `allocuvm`().
- `userinit()` and `mpmain()` sets to kernel to run `initcode.S`, which runs `init.c`, which runs `sh.c`. 