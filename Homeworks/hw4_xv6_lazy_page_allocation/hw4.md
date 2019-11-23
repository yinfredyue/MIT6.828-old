## Homework 4 xv6 lazy page allocation

### Part One
`sysproc.c`:
```C
int
sys_sbrk(void)
{
  int addr;
  int n;

  if(argint(0, &n) < 0)
    return -1;
  addr = myproc()->sz;
  
  // HW: xv6 lazy page allocation. Part One.
  // if(growproc(n) < 0)
  //   return -1;
  myproc()->sz += n;
  
  return addr;
}
```

Output:
```
$ echo hi
pid 3 sh: trap 14 err 6 on cpu 0 eip 0x112c addr 0x4004--kill proc
```

### Part Two
Major code in `trap.c`:
```C
default:
  if(myproc() == 0 || (tf->cs&3) == 0){
    // In kernel, it must be our mistake.
    cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
            tf->trapno, cpuid(), tf->eip, rcr2());
    panic("trap");
  }

  // In user space, assume process misbehaved.

  // HW 4: xv6 lazy page allocation.
  // Task:
  // Map a newly-allocated page of physical memory at the faulting address, 
  // and then return back to user space to let the process resume execution.
  if (tf->trapno == T_PGFLT) {
    cprintf("Page fault!\n");
    uint va = PGROUNDDOWN(rcr2());  // Aligned faulting virtual address

    // Allocate a new page in physical memory
    char* new_page = kalloc();
    if (new_page) {
      if (mappages(myproc()->pgdir, (char*)va, PGSIZE, V2P(new_page), PTE_W|PTE_U) >= 0) {
        // page mapping succeed. 
        break;
      } else {
        // page mapping fail.
        cprintf("mapppages() error\n");
        kfree(new_page);
      }
    } else {
      cprintf("kalloc() error\n");
    }
  }
  
  cprintf("pid %d %s: trap %d err %d on cpu %d "
          "eip 0x%x addr 0x%x--kill proc\n",
          myproc()->pid, myproc()->name, tf->trapno,
          tf->err, cpuid(), tf->eip, rcr2());
  myproc()->killed = 1;
```
Output:
```
$ echo hi
Page fault!
Page fault!
hi
```