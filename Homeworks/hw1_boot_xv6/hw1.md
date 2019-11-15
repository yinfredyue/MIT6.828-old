## Homework 1

```
(gdb) i r
eax            0x0	0
ecx            0x0	0
edx            0x1f0	496         
ebx            0x10074	65652       
esp            0x7bdc	0x7bdc      
ebp            0x7bf8	0x7bf8      
esi            0x10074	65652
edi            0x0	0
eip            0x10000c	0x10000c    
eflags         0x46	[ PF ZF ]       
cs             0x8	8               
ss             0x10	16              
ds             0x10	16              
es             0x10	16              
fs             0x0	0
gs             0x0	0
(gdb) x/24x $esp
0x7bdc:	0x00007d8d	0x00000000	0x00000000	0x00000000
0x7bec:	0x00000000	0x00000000	0x00000000	0x00000000
0x7bfc:	0x00007c4d	0x8ec031fa	0x8ec08ed8	0xa864e4d0
0x7c0c:	0xb0fa7502	0xe464e6d1	0x7502a864	0xe6dfb0fa
0x7c1c:	0x16010f60	0x200f7c78	0xc88366c0	0xc0220f01
0x7c2c:	0x087c31ea	0x10b86600	0x8ed88e00	0x66d08ec0
```

### Step 1
From `bootblock.asm`, we see:
```
  # Set up the stack pointer and call into C.
  movl    $start, %esp
    7c43:	bc 00 7c 00 00       	mov    $0x7c00,%esp
  call    bootmain
    7c48:	e8 ee 00 00 00       	call   7d3b <bootmain>
```
So the stack grows from `0x7c00` towareds lower address. And you can also observe that `0x7c4d` should be the return address (if `bootmain` ever returns). So the effective stack should be:
```
(gdb) x/9x $esp
0x7bdc:	0x00007d8d	0x00000000	0x00000000	0x00000000
0x7bec:	0x00000000	0x00000000	0x00000000	0x00000000
0x7bfc:	0x00007c4d
```
Then we start tracing through the aseembly.

### Step 2
We know that boot loader would be loaded to `0x7c00`, while kernel code would be loaded to `0xA0000`. To trace through `bootmain` function, refer to `bootblock.asm` and see the address is `0x7d3b`.
```
(gdb) b *0x00007d3b
Breakpoint 2 at 0x7d3b
(gdb) c
Continuing.
=> 0x7d3b:	push   %ebp

Thread 1 hit Breakpoint 2, 0x00007d3b in ?? ()
```
From `bootblock.asm`: 
```
00007d3b <bootmain>:
{
    7d3b:	55                   	push   %ebp         // function prologue
    7d3c:	89 e5                	mov    %esp,%ebp
    7d3e:	57                   	push   %edi         // pushing callee-saved 
    7d3f:	56                   	push   %esi
    7d40:	53                   	push   %ebx
    7d41:	83 ec 0c             	sub    $0xc,%esp    // allocate 12 bytes
  readseg((uchar*)elf, 4096, 0);
    7d44:	6a 00                	push   $0x0             // pushing arguments
    7d46:	68 00 10 00 00       	push   $0x1000
    7d4b:	68 00 00 01 00       	push   $0x10000
    7d50:	e8 a3 ff ff ff       	call   7cf8 <readseg>
  if(elf->magic != ELF_MAGIC)
    7d55:	83 c4 0c             	add    $0xc,%esp        // free argument space after return
    7d58:	81 3d 00 00 01 00 7f 	cmpl   $0x464c457f,0x10000
    7d5f:	45 4c 46 
    7d62:	74 08                	je     7d6c <bootmain+0x31> // goto A
}
    7d64:	8d 65 f4             	lea    -0xc(%ebp),%esp  // goto C
                                                            // Free all stack space,
                                                            // except callee-saved.
    7d67:	5b                   	pop    %ebx             // Restore callee-saved
    7d68:	5e                   	pop    %esi
    7d69:	5f                   	pop    %edi
    7d6a:	5d                   	pop    %ebp
    7d6b:	c3                   	ret    
  ph = (struct proghdr*)((uchar*)elf + elf->phoff);
    7d6c:	a1 1c 00 01 00       	mov    0x1001c,%eax         // A
    7d71:	8d 98 00 00 01 00    	lea    0x10000(%eax),%ebx   
  eph = ph + elf->phnum;
    7d77:	0f b7 35 2c 00 01 00 	movzwl 0x1002c,%esi
    7d7e:	c1 e6 05             	shl    $0x5,%esi
    7d81:	01 de                	add    %ebx,%esi
  for(; ph < eph; ph++){
    7d83:	39 f3                	cmp    %esi,%ebx
    7d85:	72 0f                	jb     7d96 <bootmain+0x5b> // goto B
  entry();
    7d87:	ff 15 18 00 01 00    	call   *0x10018             // D
    7d8d:	eb d5                	jmp    7d64 <bootmain+0x29> // goto C
  for(; ph < eph; ph++){
    7d8f:	83 c3 20             	add    $0x20,%ebx
    7d92:	39 de                	cmp    %ebx,%esi
    7d94:	76 f1                	jbe    7d87 <bootmain+0x4c> // goto D
    pa = (uchar*)ph->paddr;
    7d96:	8b 7b 0c             	mov    0xc(%ebx),%edi       // B
    readseg(pa, ph->filesz, ph->off);
    7d99:	ff 73 04             	pushl  0x4(%ebx)            // push args
    7d9c:	ff 73 10             	pushl  0x10(%ebx)           
    7d9f:	57                   	push   %edi     
    7da0:	e8 53 ff ff ff       	call   7cf8 <readseg>
    if(ph->memsz > ph->filesz)
    7da5:	8b 4b 14             	mov    0x14(%ebx),%ecx
    7da8:	8b 43 10             	mov    0x10(%ebx),%eax
    7dab:	83 c4 0c             	add    $0xc,%esp            // free space for args 
    7dae:	39 c1                	cmp    %eax,%ecx
    7db0:	76 dd                	jbe    7d8f <bootmain+0x54>
      stosb(pa + ph->filesz, 0, ph->memsz - ph->filesz);
    7db2:	01 c7                	add    %eax,%edi
    7db4:	29 c1                	sub    %eax,%ecx
}
```
Some progress:
```
(gdb) disas 0x7d3b, 0x7db4
Dump of assembler code from 0x7d3b to 0x7db4:
   0x00007d3b:	push   %ebp
   0x00007d3c:	mov    %esp,%ebp
   0x00007d3e:	push   %edi
   0x00007d3f:	push   %esi
   0x00007d40:	push   %ebx
   0x00007d41:	sub    $0xc,%esp
   0x00007d44:	push   $0x0
   0x00007d46:	push   $0x1000
   0x00007d4b:	push   $0x10000
   0x00007d50:	call   0x7cf8
   0x00007d55:	add    $0xc,%esp
=> 0x00007d58:	cmpl   $0x464c457f,0x10000
   ...
End of assembler dump.
(gdb) x/8x $esp
0x7be0:	(0x00000000	0x00000000	0x00000000)	[0x00000000
0x7bf0:	0x00000000	0x00000000]	0x00000000	0x00007c4d
                                    ^
                                    |
                                    +------ "push %ebp", 
                                            as this is the first C function 
                                            called, original %ebp = 0.

[]: pushed callee-saved registers, with orignal value of 0x0.
(): "sub    $0xc,%esp"
```
Trace further, stack not changed: 
```
(gdb) disas 0x7d3b, 0x7db4
Dump of assembler code from 0x7d3b to 0x7db4:
   ...
=> 0x00007d99:	pushl  0x4(%ebx)
   0x00007d9c:	pushl  0x10(%ebx)
   0x00007d9f:	push   %edi
   0x00007da0:	call   0x7cf8
   0x00007da5:	mov    0x14(%ebx),%ecx
   0x00007da8:	mov    0x10(%ebx),%eax
   0x00007dab:	add    $0xc,%esp
   0x00007dae:	cmp    %eax,%ecx
   0x00007db0:	jbe    0x7d8f
   0x00007db2:	add    %eax,%edi
End of assembler dump.
(gdb) x/8x $esp
0x7be0:	0x00000000	0x00000000	0x00000000	0x00000000
0x7bf0:	0x00000000	0x00000000	0x00000000	0x00007c4d
```

```
(gdb) disas 0x7d3b, 0x7db4
Dump of assembler code from 0x7d3b to 0x7db4:
    ...
=> 0x00007dae:	cmp    %eax,%ecx
   0x00007db0:	jbe    0x7d8f
   0x00007db2:	add    %eax,%edi
End of assembler dump.
(gdb) x/15x $esp
0x7be0:	0x00000000	0x00000000	0x00000000	0x00000000
0x7bf0:	0x00000000	0x00000000	0x00000000	0x00007c4d
```
The stack would remain unchanged until reaching 
```
0x00007d87:	call   *0x10018
```
which is calling `entry()`, i.e., `_start`. Then the address of next instruction, i.e., `0x00007d8d`, is implicity pushed onto the stack as return address. Thus we have:
```
(gdb) x/9x $esp
0x7bdc:	0x00007d8d	0x00000000	0x00000000	0x00000000
0x7bec:	0x00000000	0x00000000	0x00000000	0x00000000
0x7bfc:	0x00007c4d
```


