## Chapter 5 Memory Management
```
Logical address -- segmentation --> linear address 
Linear address -- paging --> physical address

If paging disabled:
logical address -> physical address

If paging enabled:
logical address -> linear address -> physical address

Logical address == Virtual address
```
In x86, segmenting is always enabled. Virtual address (or logical address) consists a 15-bit selector from segment register and a 32-bit offset.

