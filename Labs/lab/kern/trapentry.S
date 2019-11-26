/* See COPYRIGHT for copyright information. */

#include <inc/mmu.h>
#include <inc/memlayout.h>
#include <inc/trap.h>



###################################################################
# exceptions/interrupts
###################################################################

/* TRAPHANDLER defines a globally-visible function for handling a trap.
 * It pushes a trap number onto the stack, then jumps to _alltraps.
 * Use TRAPHANDLER for traps where the CPU automatically pushes an error code.
 *
 * You shouldn't call a TRAPHANDLER function from C, but you may
 * need to _declare_ one in C (for instance, to get a function pointer
 * during IDT setup).  You can declare the function with
 *   void NAME();
 * where NAME is the argument passed to TRAPHANDLER.
 */
#define TRAPHANDLER(name, num)						\
	.globl name;		/* define global symbol for 'name' */	\
	.type name, @function;	/* symbol type is function */		\
	.align 2;		/* align function definition */		\
	name:			/* function starts here */		\
	pushl $(num);							\
	jmp _alltraps

/* Use TRAPHANDLER_NOEC for traps where the CPU doesn't push an error code.
 * It pushes a 0 in place of the error code, so the trap frame has the same
 * format in either case.
 */
#define TRAPHANDLER_NOEC(name, num)					\
	.globl name;							\
	.type name, @function;						\
	.align 2;							\
	name:								\
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps

/*
 * YY: How to use the two macros provided?
 * Think about how the predecessor would do with the macro: text substitution!
 * So if you write: TRAPHANDLER_NOEC(myEntryPtName, myEntryPtNum), you get assembly
 * code like:
 *
 * .globl myEntryPtName
 * .type myEntryPtName, @function
 * .align 2
 * myEntryPtName:
 * pushl $0
 * pushl $(myEntryPtNum)
 * jmp _alltraps
 * 
 * This is exactly the code you need to define a function! ".globl name" makes 
 * this label (code location) visible to the entire file, ".type" and ".align" 
 * specifies the type and alignment of the assembly code. Then "name:" starts the
 * definition of the function in assembly code! 
 * https://en.wikibooks.org/wiki/X86_Assembly/GAS_Syntax
 */

.text
/* 
 * Consult: https://pdos.csail.mit.edu/6.828/2018/readings/i386/s09_10.htm so 
 * you know the error code behavior of each exception.
 */

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(DIVIDE, T_DIVIDE)
TRAPHANDLER_NOEC(DEBUG, T_DEBUG)
TRAPHANDLER(NMI, T_NMI)
TRAPHANDLER_NOEC(BRKPT, T_BRKPT)
TRAPHANDLER_NOEC(OFLOW, T_OFLOW)
TRAPHANDLER_NOEC(BOUND, T_BOUND)
TRAPHANDLER_NOEC(ILLOP, T_ILLOP)
TRAPHANDLER_NOEC(DEVICE, T_DEVICE)
TRAPHANDLER(DBLFLT, T_DBLFLT)
TRAPHANDLER(TSS, T_TSS)
TRAPHANDLER(SEGNP, T_SEGNP)
TRAPHANDLER(STACK, T_STACK)
TRAPHANDLER(GPFLT, T_GPFLT)
TRAPHANDLER(PGFLT, T_PGFLT)
TRAPHANDLER_NOEC(FPERR, T_FPERR)
TRAPHANDLER(ALIGN, T_ALIGN)
TRAPHANDLER(MCHK, T_MCHK)
TRAPHANDLER(SIMDERR, T_SIMDERR)
TRAPHANDLER_NOEC(SYSCALL, T_SYSCALL)
TRAPHANDLER_NOEC(DEFAULT, T_DEFAULT)

/*
 * Lab 3: Your code here for _alltraps
 */
.globl _alltraps
_alltraps:
  # Continue building trap frame.
  # Before entering _alltraps, ss, esp, eflags, cs, eip, error code and trapNo 
  # has already been pushed to the kernel stack. Check struct Trapframe, the
  # remaining register: ds, es and struct PushRegs.
  # pushal handles struct PushRegs. 
  pushl %ds
  pushl %es
  pushal

  # Set up %ds, %es, 16-bit register! Use movw.
  # Seems that you cannot move directly into %ds or %es, use %ax.
  movw $GD_KD, %ax
  movw %ax, %ds
  movw %ax, %es

  # Call trap(tf), where tf=%esp
  pushl %esp
  call trap     # Enter kernel code
