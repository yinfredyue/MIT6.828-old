## Lec2

### Memory-mapped I/O  
Memory mapped I/O is a way to exchange data and instructions between a CPU and peripheral devices attached to it. Memory mapped IO is one where the processor and the IO device share the same memory location(memory),i.e.,the processor and IO devices are mapped using the memory address. Memory-mapped I/O uses the same address bus to address both memory and I/O devices, and the CPU instructions used are same for accessing the memory and also accessing devices.

### gcc calling conventions
- Stack grows downwards.
- Caller-saved and callee-saved registers.
    - Caller-saved: caller saves temporary values in its frame before making the call. Include: %eax, %ecx, %edx. 
    - Callee-saved: callee saves the temporary values in its frame before using the register. Callee restores them before returning to the caller. Include: %ebp, %ebx, %esi, %edi.  

Contract/Agreement between caller and callee on x86:  
- At entry to a function
    - `%eip` (instruction pointer) points to the first instruction of the function.  
    - `%esp + 4` points to the first argument to the function. 
    - `%esp` points at the return address.  
- After `ret` instruction  
    - caller-saved registers may be trashed (and the caller should restore it from stack), while callee-saved registers should contain the content before the call (the callee should restore the original value before return).  
    - %eax (and %edx, if return type is 64-bit), and %ecx could be trashed/modified.  
    - The arguments to the called function could have been trashed/modified.
    - %esp points at arguments pushed by caller.  
    - %eip points at the return address. 

GCC does more by convention: 
- The stack frame of each function is bounded by %esp (top of the stack) and %ebp (base pointer).  
- %esp can be made to extend/shrink the stack.  
- How %esp and %ebp works during function call & return.  
    Great explanation: https://stackoverflow.com/a/1395934/9057530, also cited below.  
    ```
    	       +------------+   |
		       | arg 2      |   \
		       +------------+    >- previous function's stack frame
		       | arg 1      |   /
		       +------------+   |
		       | ret %eip   |   /
		       +============+   
		       | saved %ebp |   \
		%ebp-> +------------+   |
		       |            |   |
		       |   local    |   \
		       | variables, |    >- current function's stack frame
		       |    etc.    |   /
		       |            |   |
		       |            |   |
		%esp-> +------------+   /
    ```
    ESP is the current stack pointer, which points to the top of the stack and will change any time anything is pushed or popped onto/off off the stack. EBP is a more convenient way for the compiler to keep track of a function's parameters and local variables than using the ESP directly, as ESP is varying but EBP is the same throughout one function call.

    Generally (this may vary for different compilers), all arguments to a function being called are pushed onto the stack by the calling function (usually in the reverse order that they're declared in the function prototype, which is case in our diagram: arg2 is pushed before arg1). Then the function is called, which pushes the return address, which is the address of the next instruction stored in EIP, onto the stack.

    Upon entry to the function, the old EBP value is pushed onto the stack and EBP is set to the value of ESP. Then the ESP is decremented  to allocate space for the local variables and temporaries. From that point on, during the execution of the function, arguments to the function are located on the stack at positive offsets from EBP (because they were pushed prior to the function call), and local variables are located at negative offsets from EBP. That's why the EBP is called the frame pointer, because it points to the center of the function call frame.

    Upon exit, all the function has to do is set ESP to the value of EBP (which deallocates local variables and exposes the EBP of the calling function on top of the stack), then pop the old EBP value from the stack into EBP, and then the function returns (popping the return address into EIP).

    Upon returning back to the calling function, it can then increment ESP in order to remove the function arguments it pushed onto the stack before calling the other function. At this point, the stack is back in the same state it was before invoking the called function

    In short:
    ```
    // When calling the function
    push arguments;
    call function;  // will push %eip (return address) to stack

    // Entry to the function: function prologue
    push %ebp;
    %ebp = %esp;

    // Function body
    Allocate space on stack for local variables

    // Return from function: function epilogue
    %esp = %ebp;  // free space + make %ebp of caller on stack top
    pop %ebp;     // pop the previous %ebp into %ebp
    ret;          // pop stack top, the return address, into %eip

    // Back at caller
    increment %esp;  // Free space for arguments

    // You may observe certain symmetry with funtion prologue and epilogue.
    ```
    You should see why %ebp can be used to walk through the stack frame of different functions: in each function call, it points to the starting address of the stack frame of the called function, but the content stored at that address is the %ebp of the calling function. (It seems hard to understand from this description, but it would be clear if you understand the diagram and the pseudo-code above.)  

    Example:
    - C code
        ``` C
        int main(void) { return f(8)+1; }
        int f(int x) { return g(x); }
        int g(int x) { return x+3; }
        ```
    - Assembly code
        ``` C
        _main:
					// prologue
			pushl %ebp
			movl %esp, %ebp

					// body
			pushl $8
			call _f   // push %eip to stack
			addl $1, %eax

					// epilogue
			movl %ebp, %esp
			popl %ebp
			ret      // pop %esp into %eip
		_f:
					// prologue
			pushl %ebp
			movl %esp, %ebp

					// body
			pushl 8(%esp)   // Pushing value of x onto stack.
                            // Check the diagram. The address
                            // of first argument is: 8 + %esp.
                            // A pointer is 4-byte in 32-bit system.
			call _g
            
					// epilogue
			movl %ebp, %esp
			popl %ebp
			ret

		_g:
					// prologue
			pushl %ebp
			movl %esp, %ebp

					// save %ebx, as %ebx is callee-saved
			pushl %ebx

					// body
			movl 8(%ebp), %ebx
			addl $3, %ebx
			movl %ebx, %eax

					// restore %ebx
			popl %ebx

					// epilogue
			movl %ebp, %esp
			popl %ebp
			ret
        ```
    
### Preprocessing, compiling, assembling, linking + loading
- Preprocessor takes C source code (ASCII text), expands #include and other macros, produces C source code
- Compiler takes C source code (ASCII text), produces assembly language (also ASCII text)
- Assembler takes assembly language (ASCII text), produces .o file (binary, machine-readable!)
- Linker takes multiple '.o's, produces a single program image (binary)
- Loader loads the program image into memory at run-time and starts it executing

### PC emulation  
- The QEMU emulator works by
    - doing exactly what a real PC would do,
    - only implemented in software rather than hardware!