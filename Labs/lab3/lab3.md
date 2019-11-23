## Lab 3

### Before start
After merging conflict, you may found that: code that already passed checking in Lab 2 no longer checks and the error message says that
`kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;` gets `invalid kva 00000000`. Print out `kerg_pgdir` and you see that `memset(kern_pgdir, 0, PGSIZE);` sets the value of `kern_pgdir` to `0`!  

Solution:
https://zhuanlan.zhihu.com/p/46838542

### 