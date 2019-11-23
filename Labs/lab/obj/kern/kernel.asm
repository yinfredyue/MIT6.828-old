
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4                   	.byte 0xe4

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 d0 18 00       	mov    $0x18d000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 a0 11 f0       	mov    $0xf011a000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/trap.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	57                   	push   %edi
f0100044:	56                   	push   %esi
f0100045:	53                   	push   %ebx
f0100046:	83 ec 10             	sub    $0x10,%esp
f0100049:	e8 4b 01 00 00       	call   f0100199 <__x86.get_pc_thunk.bx>
f010004e:	81 c3 d2 bf 08 00    	add    $0x8bfd2,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100054:	c7 c7 10 f0 18 f0    	mov    $0xf018f010,%edi
f010005a:	c7 c6 00 e1 18 f0    	mov    $0xf018e100,%esi
f0100060:	89 f8                	mov    %edi,%eax
f0100062:	29 f0                	sub    %esi,%eax
f0100064:	50                   	push   %eax
f0100065:	6a 00                	push   $0x0
f0100067:	56                   	push   %esi
f0100068:	e8 9a 4c 00 00       	call   f0104d07 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f010006d:	e8 7c 05 00 00       	call   f01005ee <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	68 ac 1a 00 00       	push   $0x1aac
f010007a:	8d 83 40 91 f7 ff    	lea    -0x86ec0(%ebx),%eax
f0100080:	50                   	push   %eax
f0100081:	e8 d2 3b 00 00       	call   f0103c58 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100086:	e8 d9 14 00 00       	call   f0101564 <mem_init>

	// Lab3 linker script debug
	cprintf("edata: 0x%08x\n", edata);
f010008b:	83 c4 08             	add    $0x8,%esp
f010008e:	56                   	push   %esi
f010008f:	8d 83 5b 91 f7 ff    	lea    -0x86ea5(%ebx),%eax
f0100095:	50                   	push   %eax
f0100096:	e8 bd 3b 00 00       	call   f0103c58 <cprintf>
	cprintf("end: 0x%08x\n", end);
f010009b:	83 c4 08             	add    $0x8,%esp
f010009e:	57                   	push   %edi
f010009f:	8d 83 6a 91 f7 ff    	lea    -0x86e96(%ebx),%eax
f01000a5:	50                   	push   %eax
f01000a6:	e8 ad 3b 00 00       	call   f0103c58 <cprintf>

	// Lab 3 user environment initialization functions
	env_init();
f01000ab:	e8 93 34 00 00       	call   f0103543 <env_init>
	trap_init();
f01000b0:	e8 56 3c 00 00       	call   f0103d0b <trap_init>
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
f01000b5:	83 c4 08             	add    $0x8,%esp
f01000b8:	6a 00                	push   $0x0
f01000ba:	ff b3 f4 ff ff ff    	pushl  -0xc(%ebx)
f01000c0:	e8 79 36 00 00       	call   f010373e <env_create>
	cprintf("ENV_CREATE done!\n");
f01000c5:	8d 83 77 91 f7 ff    	lea    -0x86e89(%ebx),%eax
f01000cb:	89 04 24             	mov    %eax,(%esp)
f01000ce:	e8 85 3b 00 00       	call   f0103c58 <cprintf>
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000d3:	83 c4 04             	add    $0x4,%esp
f01000d6:	c7 c0 48 e3 18 f0    	mov    $0xf018e348,%eax
f01000dc:	ff 30                	pushl  (%eax)
f01000de:	e8 75 3a 00 00       	call   f0103b58 <env_run>

f01000e3 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e3:	55                   	push   %ebp
f01000e4:	89 e5                	mov    %esp,%ebp
f01000e6:	57                   	push   %edi
f01000e7:	56                   	push   %esi
f01000e8:	53                   	push   %ebx
f01000e9:	83 ec 0c             	sub    $0xc,%esp
f01000ec:	e8 a8 00 00 00       	call   f0100199 <__x86.get_pc_thunk.bx>
f01000f1:	81 c3 2f bf 08 00    	add    $0x8bf2f,%ebx
f01000f7:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f01000fa:	c7 c0 00 f0 18 f0    	mov    $0xf018f000,%eax
f0100100:	83 38 00             	cmpl   $0x0,(%eax)
f0100103:	74 0f                	je     f0100114 <_panic+0x31>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100105:	83 ec 0c             	sub    $0xc,%esp
f0100108:	6a 00                	push   $0x0
f010010a:	e8 71 08 00 00       	call   f0100980 <monitor>
f010010f:	83 c4 10             	add    $0x10,%esp
f0100112:	eb f1                	jmp    f0100105 <_panic+0x22>
	panicstr = fmt;
f0100114:	89 38                	mov    %edi,(%eax)
	asm volatile("cli; cld");
f0100116:	fa                   	cli    
f0100117:	fc                   	cld    
	va_start(ap, fmt);
f0100118:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
f010011b:	83 ec 04             	sub    $0x4,%esp
f010011e:	ff 75 0c             	pushl  0xc(%ebp)
f0100121:	ff 75 08             	pushl  0x8(%ebp)
f0100124:	8d 83 89 91 f7 ff    	lea    -0x86e77(%ebx),%eax
f010012a:	50                   	push   %eax
f010012b:	e8 28 3b 00 00       	call   f0103c58 <cprintf>
	vcprintf(fmt, ap);
f0100130:	83 c4 08             	add    $0x8,%esp
f0100133:	56                   	push   %esi
f0100134:	57                   	push   %edi
f0100135:	e8 e7 3a 00 00       	call   f0103c21 <vcprintf>
	cprintf("\n");
f010013a:	8d 83 61 99 f7 ff    	lea    -0x8669f(%ebx),%eax
f0100140:	89 04 24             	mov    %eax,(%esp)
f0100143:	e8 10 3b 00 00       	call   f0103c58 <cprintf>
f0100148:	83 c4 10             	add    $0x10,%esp
f010014b:	eb b8                	jmp    f0100105 <_panic+0x22>

f010014d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010014d:	55                   	push   %ebp
f010014e:	89 e5                	mov    %esp,%ebp
f0100150:	56                   	push   %esi
f0100151:	53                   	push   %ebx
f0100152:	e8 42 00 00 00       	call   f0100199 <__x86.get_pc_thunk.bx>
f0100157:	81 c3 c9 be 08 00    	add    $0x8bec9,%ebx
	va_list ap;

	va_start(ap, fmt);
f010015d:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f0100160:	83 ec 04             	sub    $0x4,%esp
f0100163:	ff 75 0c             	pushl  0xc(%ebp)
f0100166:	ff 75 08             	pushl  0x8(%ebp)
f0100169:	8d 83 a1 91 f7 ff    	lea    -0x86e5f(%ebx),%eax
f010016f:	50                   	push   %eax
f0100170:	e8 e3 3a 00 00       	call   f0103c58 <cprintf>
	vcprintf(fmt, ap);
f0100175:	83 c4 08             	add    $0x8,%esp
f0100178:	56                   	push   %esi
f0100179:	ff 75 10             	pushl  0x10(%ebp)
f010017c:	e8 a0 3a 00 00       	call   f0103c21 <vcprintf>
	cprintf("\n");
f0100181:	8d 83 61 99 f7 ff    	lea    -0x8669f(%ebx),%eax
f0100187:	89 04 24             	mov    %eax,(%esp)
f010018a:	e8 c9 3a 00 00       	call   f0103c58 <cprintf>
	va_end(ap);
}
f010018f:	83 c4 10             	add    $0x10,%esp
f0100192:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100195:	5b                   	pop    %ebx
f0100196:	5e                   	pop    %esi
f0100197:	5d                   	pop    %ebp
f0100198:	c3                   	ret    

f0100199 <__x86.get_pc_thunk.bx>:
f0100199:	8b 1c 24             	mov    (%esp),%ebx
f010019c:	c3                   	ret    

f010019d <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010019d:	55                   	push   %ebp
f010019e:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a0:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001a5:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001a6:	a8 01                	test   $0x1,%al
f01001a8:	74 0b                	je     f01001b5 <serial_proc_data+0x18>
f01001aa:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001af:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001b0:	0f b6 c0             	movzbl %al,%eax
}
f01001b3:	5d                   	pop    %ebp
f01001b4:	c3                   	ret    
		return -1;
f01001b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01001ba:	eb f7                	jmp    f01001b3 <serial_proc_data+0x16>

f01001bc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001bc:	55                   	push   %ebp
f01001bd:	89 e5                	mov    %esp,%ebp
f01001bf:	56                   	push   %esi
f01001c0:	53                   	push   %ebx
f01001c1:	e8 d3 ff ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f01001c6:	81 c3 5a be 08 00    	add    $0x8be5a,%ebx
f01001cc:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
f01001ce:	ff d6                	call   *%esi
f01001d0:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001d3:	74 2e                	je     f0100203 <cons_intr+0x47>
		if (c == 0)
f01001d5:	85 c0                	test   %eax,%eax
f01001d7:	74 f5                	je     f01001ce <cons_intr+0x12>
			continue;
		cons.buf[cons.wpos++] = c;
f01001d9:	8b 8b 04 23 00 00    	mov    0x2304(%ebx),%ecx
f01001df:	8d 51 01             	lea    0x1(%ecx),%edx
f01001e2:	89 93 04 23 00 00    	mov    %edx,0x2304(%ebx)
f01001e8:	88 84 0b 00 21 00 00 	mov    %al,0x2100(%ebx,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f01001ef:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001f5:	75 d7                	jne    f01001ce <cons_intr+0x12>
			cons.wpos = 0;
f01001f7:	c7 83 04 23 00 00 00 	movl   $0x0,0x2304(%ebx)
f01001fe:	00 00 00 
f0100201:	eb cb                	jmp    f01001ce <cons_intr+0x12>
	}
}
f0100203:	5b                   	pop    %ebx
f0100204:	5e                   	pop    %esi
f0100205:	5d                   	pop    %ebp
f0100206:	c3                   	ret    

f0100207 <kbd_proc_data>:
{
f0100207:	55                   	push   %ebp
f0100208:	89 e5                	mov    %esp,%ebp
f010020a:	56                   	push   %esi
f010020b:	53                   	push   %ebx
f010020c:	e8 88 ff ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f0100211:	81 c3 0f be 08 00    	add    $0x8be0f,%ebx
f0100217:	ba 64 00 00 00       	mov    $0x64,%edx
f010021c:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f010021d:	a8 01                	test   $0x1,%al
f010021f:	0f 84 06 01 00 00    	je     f010032b <kbd_proc_data+0x124>
	if (stat & KBS_TERR)
f0100225:	a8 20                	test   $0x20,%al
f0100227:	0f 85 05 01 00 00    	jne    f0100332 <kbd_proc_data+0x12b>
f010022d:	ba 60 00 00 00       	mov    $0x60,%edx
f0100232:	ec                   	in     (%dx),%al
f0100233:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f0100235:	3c e0                	cmp    $0xe0,%al
f0100237:	0f 84 93 00 00 00    	je     f01002d0 <kbd_proc_data+0xc9>
	} else if (data & 0x80) {
f010023d:	84 c0                	test   %al,%al
f010023f:	0f 88 a0 00 00 00    	js     f01002e5 <kbd_proc_data+0xde>
	} else if (shift & E0ESC) {
f0100245:	8b 8b e0 20 00 00    	mov    0x20e0(%ebx),%ecx
f010024b:	f6 c1 40             	test   $0x40,%cl
f010024e:	74 0e                	je     f010025e <kbd_proc_data+0x57>
		data |= 0x80;
f0100250:	83 c8 80             	or     $0xffffff80,%eax
f0100253:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100255:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100258:	89 8b e0 20 00 00    	mov    %ecx,0x20e0(%ebx)
	shift |= shiftcode[data];
f010025e:	0f b6 d2             	movzbl %dl,%edx
f0100261:	0f b6 84 13 00 93 f7 	movzbl -0x86d00(%ebx,%edx,1),%eax
f0100268:	ff 
f0100269:	0b 83 e0 20 00 00    	or     0x20e0(%ebx),%eax
	shift ^= togglecode[data];
f010026f:	0f b6 8c 13 00 92 f7 	movzbl -0x86e00(%ebx,%edx,1),%ecx
f0100276:	ff 
f0100277:	31 c8                	xor    %ecx,%eax
f0100279:	89 83 e0 20 00 00    	mov    %eax,0x20e0(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f010027f:	89 c1                	mov    %eax,%ecx
f0100281:	83 e1 03             	and    $0x3,%ecx
f0100284:	8b 8c 8b 00 20 00 00 	mov    0x2000(%ebx,%ecx,4),%ecx
f010028b:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010028f:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
f0100292:	a8 08                	test   $0x8,%al
f0100294:	74 0d                	je     f01002a3 <kbd_proc_data+0x9c>
		if ('a' <= c && c <= 'z')
f0100296:	89 f2                	mov    %esi,%edx
f0100298:	8d 4e 9f             	lea    -0x61(%esi),%ecx
f010029b:	83 f9 19             	cmp    $0x19,%ecx
f010029e:	77 7a                	ja     f010031a <kbd_proc_data+0x113>
			c += 'A' - 'a';
f01002a0:	83 ee 20             	sub    $0x20,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002a3:	f7 d0                	not    %eax
f01002a5:	a8 06                	test   $0x6,%al
f01002a7:	75 33                	jne    f01002dc <kbd_proc_data+0xd5>
f01002a9:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
f01002af:	75 2b                	jne    f01002dc <kbd_proc_data+0xd5>
		cprintf("Rebooting!\n");
f01002b1:	83 ec 0c             	sub    $0xc,%esp
f01002b4:	8d 83 bb 91 f7 ff    	lea    -0x86e45(%ebx),%eax
f01002ba:	50                   	push   %eax
f01002bb:	e8 98 39 00 00       	call   f0103c58 <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002c0:	b8 03 00 00 00       	mov    $0x3,%eax
f01002c5:	ba 92 00 00 00       	mov    $0x92,%edx
f01002ca:	ee                   	out    %al,(%dx)
f01002cb:	83 c4 10             	add    $0x10,%esp
f01002ce:	eb 0c                	jmp    f01002dc <kbd_proc_data+0xd5>
		shift |= E0ESC;
f01002d0:	83 8b e0 20 00 00 40 	orl    $0x40,0x20e0(%ebx)
		return 0;
f01002d7:	be 00 00 00 00       	mov    $0x0,%esi
}
f01002dc:	89 f0                	mov    %esi,%eax
f01002de:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01002e1:	5b                   	pop    %ebx
f01002e2:	5e                   	pop    %esi
f01002e3:	5d                   	pop    %ebp
f01002e4:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f01002e5:	8b 8b e0 20 00 00    	mov    0x20e0(%ebx),%ecx
f01002eb:	89 ce                	mov    %ecx,%esi
f01002ed:	83 e6 40             	and    $0x40,%esi
f01002f0:	83 e0 7f             	and    $0x7f,%eax
f01002f3:	85 f6                	test   %esi,%esi
f01002f5:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01002f8:	0f b6 d2             	movzbl %dl,%edx
f01002fb:	0f b6 84 13 00 93 f7 	movzbl -0x86d00(%ebx,%edx,1),%eax
f0100302:	ff 
f0100303:	83 c8 40             	or     $0x40,%eax
f0100306:	0f b6 c0             	movzbl %al,%eax
f0100309:	f7 d0                	not    %eax
f010030b:	21 c8                	and    %ecx,%eax
f010030d:	89 83 e0 20 00 00    	mov    %eax,0x20e0(%ebx)
		return 0;
f0100313:	be 00 00 00 00       	mov    $0x0,%esi
f0100318:	eb c2                	jmp    f01002dc <kbd_proc_data+0xd5>
		else if ('A' <= c && c <= 'Z')
f010031a:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f010031d:	8d 4e 20             	lea    0x20(%esi),%ecx
f0100320:	83 fa 1a             	cmp    $0x1a,%edx
f0100323:	0f 42 f1             	cmovb  %ecx,%esi
f0100326:	e9 78 ff ff ff       	jmp    f01002a3 <kbd_proc_data+0x9c>
		return -1;
f010032b:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0100330:	eb aa                	jmp    f01002dc <kbd_proc_data+0xd5>
		return -1;
f0100332:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0100337:	eb a3                	jmp    f01002dc <kbd_proc_data+0xd5>

f0100339 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100339:	55                   	push   %ebp
f010033a:	89 e5                	mov    %esp,%ebp
f010033c:	57                   	push   %edi
f010033d:	56                   	push   %esi
f010033e:	53                   	push   %ebx
f010033f:	83 ec 1c             	sub    $0x1c,%esp
f0100342:	e8 52 fe ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f0100347:	81 c3 d9 bc 08 00    	add    $0x8bcd9,%ebx
f010034d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0;
f0100350:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100355:	bf fd 03 00 00       	mov    $0x3fd,%edi
f010035a:	b9 84 00 00 00       	mov    $0x84,%ecx
f010035f:	eb 09                	jmp    f010036a <cons_putc+0x31>
f0100361:	89 ca                	mov    %ecx,%edx
f0100363:	ec                   	in     (%dx),%al
f0100364:	ec                   	in     (%dx),%al
f0100365:	ec                   	in     (%dx),%al
f0100366:	ec                   	in     (%dx),%al
	     i++)
f0100367:	83 c6 01             	add    $0x1,%esi
f010036a:	89 fa                	mov    %edi,%edx
f010036c:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010036d:	a8 20                	test   $0x20,%al
f010036f:	75 08                	jne    f0100379 <cons_putc+0x40>
f0100371:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f0100377:	7e e8                	jle    f0100361 <cons_putc+0x28>
	outb(COM1 + COM_TX, c);
f0100379:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010037c:	89 f8                	mov    %edi,%eax
f010037e:	88 45 e3             	mov    %al,-0x1d(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100381:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100386:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100387:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010038c:	bf 79 03 00 00       	mov    $0x379,%edi
f0100391:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100396:	eb 09                	jmp    f01003a1 <cons_putc+0x68>
f0100398:	89 ca                	mov    %ecx,%edx
f010039a:	ec                   	in     (%dx),%al
f010039b:	ec                   	in     (%dx),%al
f010039c:	ec                   	in     (%dx),%al
f010039d:	ec                   	in     (%dx),%al
f010039e:	83 c6 01             	add    $0x1,%esi
f01003a1:	89 fa                	mov    %edi,%edx
f01003a3:	ec                   	in     (%dx),%al
f01003a4:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f01003aa:	7f 04                	jg     f01003b0 <cons_putc+0x77>
f01003ac:	84 c0                	test   %al,%al
f01003ae:	79 e8                	jns    f0100398 <cons_putc+0x5f>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003b0:	ba 78 03 00 00       	mov    $0x378,%edx
f01003b5:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f01003b9:	ee                   	out    %al,(%dx)
f01003ba:	ba 7a 03 00 00       	mov    $0x37a,%edx
f01003bf:	b8 0d 00 00 00       	mov    $0xd,%eax
f01003c4:	ee                   	out    %al,(%dx)
f01003c5:	b8 08 00 00 00       	mov    $0x8,%eax
f01003ca:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f01003cb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01003ce:	89 fa                	mov    %edi,%edx
f01003d0:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f01003d6:	89 f8                	mov    %edi,%eax
f01003d8:	80 cc 07             	or     $0x7,%ah
f01003db:	85 d2                	test   %edx,%edx
f01003dd:	0f 45 c7             	cmovne %edi,%eax
f01003e0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch (c & 0xff) {
f01003e3:	0f b6 c0             	movzbl %al,%eax
f01003e6:	83 f8 09             	cmp    $0x9,%eax
f01003e9:	0f 84 b9 00 00 00    	je     f01004a8 <cons_putc+0x16f>
f01003ef:	83 f8 09             	cmp    $0x9,%eax
f01003f2:	7e 74                	jle    f0100468 <cons_putc+0x12f>
f01003f4:	83 f8 0a             	cmp    $0xa,%eax
f01003f7:	0f 84 9e 00 00 00    	je     f010049b <cons_putc+0x162>
f01003fd:	83 f8 0d             	cmp    $0xd,%eax
f0100400:	0f 85 d9 00 00 00    	jne    f01004df <cons_putc+0x1a6>
		crt_pos -= (crt_pos % CRT_COLS);
f0100406:	0f b7 83 08 23 00 00 	movzwl 0x2308(%ebx),%eax
f010040d:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100413:	c1 e8 16             	shr    $0x16,%eax
f0100416:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100419:	c1 e0 04             	shl    $0x4,%eax
f010041c:	66 89 83 08 23 00 00 	mov    %ax,0x2308(%ebx)
	if (crt_pos >= CRT_SIZE) {
f0100423:	66 81 bb 08 23 00 00 	cmpw   $0x7cf,0x2308(%ebx)
f010042a:	cf 07 
f010042c:	0f 87 d4 00 00 00    	ja     f0100506 <cons_putc+0x1cd>
	outb(addr_6845, 14);
f0100432:	8b 8b 10 23 00 00    	mov    0x2310(%ebx),%ecx
f0100438:	b8 0e 00 00 00       	mov    $0xe,%eax
f010043d:	89 ca                	mov    %ecx,%edx
f010043f:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100440:	0f b7 9b 08 23 00 00 	movzwl 0x2308(%ebx),%ebx
f0100447:	8d 71 01             	lea    0x1(%ecx),%esi
f010044a:	89 d8                	mov    %ebx,%eax
f010044c:	66 c1 e8 08          	shr    $0x8,%ax
f0100450:	89 f2                	mov    %esi,%edx
f0100452:	ee                   	out    %al,(%dx)
f0100453:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100458:	89 ca                	mov    %ecx,%edx
f010045a:	ee                   	out    %al,(%dx)
f010045b:	89 d8                	mov    %ebx,%eax
f010045d:	89 f2                	mov    %esi,%edx
f010045f:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100460:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100463:	5b                   	pop    %ebx
f0100464:	5e                   	pop    %esi
f0100465:	5f                   	pop    %edi
f0100466:	5d                   	pop    %ebp
f0100467:	c3                   	ret    
	switch (c & 0xff) {
f0100468:	83 f8 08             	cmp    $0x8,%eax
f010046b:	75 72                	jne    f01004df <cons_putc+0x1a6>
		if (crt_pos > 0) {
f010046d:	0f b7 83 08 23 00 00 	movzwl 0x2308(%ebx),%eax
f0100474:	66 85 c0             	test   %ax,%ax
f0100477:	74 b9                	je     f0100432 <cons_putc+0xf9>
			crt_pos--;
f0100479:	83 e8 01             	sub    $0x1,%eax
f010047c:	66 89 83 08 23 00 00 	mov    %ax,0x2308(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100483:	0f b7 c0             	movzwl %ax,%eax
f0100486:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f010048a:	b2 00                	mov    $0x0,%dl
f010048c:	83 ca 20             	or     $0x20,%edx
f010048f:	8b 8b 0c 23 00 00    	mov    0x230c(%ebx),%ecx
f0100495:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f0100499:	eb 88                	jmp    f0100423 <cons_putc+0xea>
		crt_pos += CRT_COLS;
f010049b:	66 83 83 08 23 00 00 	addw   $0x50,0x2308(%ebx)
f01004a2:	50 
f01004a3:	e9 5e ff ff ff       	jmp    f0100406 <cons_putc+0xcd>
		cons_putc(' ');
f01004a8:	b8 20 00 00 00       	mov    $0x20,%eax
f01004ad:	e8 87 fe ff ff       	call   f0100339 <cons_putc>
		cons_putc(' ');
f01004b2:	b8 20 00 00 00       	mov    $0x20,%eax
f01004b7:	e8 7d fe ff ff       	call   f0100339 <cons_putc>
		cons_putc(' ');
f01004bc:	b8 20 00 00 00       	mov    $0x20,%eax
f01004c1:	e8 73 fe ff ff       	call   f0100339 <cons_putc>
		cons_putc(' ');
f01004c6:	b8 20 00 00 00       	mov    $0x20,%eax
f01004cb:	e8 69 fe ff ff       	call   f0100339 <cons_putc>
		cons_putc(' ');
f01004d0:	b8 20 00 00 00       	mov    $0x20,%eax
f01004d5:	e8 5f fe ff ff       	call   f0100339 <cons_putc>
f01004da:	e9 44 ff ff ff       	jmp    f0100423 <cons_putc+0xea>
		crt_buf[crt_pos++] = c;		/* write the character */
f01004df:	0f b7 83 08 23 00 00 	movzwl 0x2308(%ebx),%eax
f01004e6:	8d 50 01             	lea    0x1(%eax),%edx
f01004e9:	66 89 93 08 23 00 00 	mov    %dx,0x2308(%ebx)
f01004f0:	0f b7 c0             	movzwl %ax,%eax
f01004f3:	8b 93 0c 23 00 00    	mov    0x230c(%ebx),%edx
f01004f9:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f01004fd:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100501:	e9 1d ff ff ff       	jmp    f0100423 <cons_putc+0xea>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100506:	8b 83 0c 23 00 00    	mov    0x230c(%ebx),%eax
f010050c:	83 ec 04             	sub    $0x4,%esp
f010050f:	68 00 0f 00 00       	push   $0xf00
f0100514:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010051a:	52                   	push   %edx
f010051b:	50                   	push   %eax
f010051c:	e8 33 48 00 00       	call   f0104d54 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f0100521:	8b 93 0c 23 00 00    	mov    0x230c(%ebx),%edx
f0100527:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f010052d:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100533:	83 c4 10             	add    $0x10,%esp
f0100536:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010053b:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010053e:	39 d0                	cmp    %edx,%eax
f0100540:	75 f4                	jne    f0100536 <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
f0100542:	66 83 ab 08 23 00 00 	subw   $0x50,0x2308(%ebx)
f0100549:	50 
f010054a:	e9 e3 fe ff ff       	jmp    f0100432 <cons_putc+0xf9>

f010054f <serial_intr>:
{
f010054f:	e8 e7 01 00 00       	call   f010073b <__x86.get_pc_thunk.ax>
f0100554:	05 cc ba 08 00       	add    $0x8bacc,%eax
	if (serial_exists)
f0100559:	80 b8 14 23 00 00 00 	cmpb   $0x0,0x2314(%eax)
f0100560:	75 02                	jne    f0100564 <serial_intr+0x15>
f0100562:	f3 c3                	repz ret 
{
f0100564:	55                   	push   %ebp
f0100565:	89 e5                	mov    %esp,%ebp
f0100567:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f010056a:	8d 80 7d 41 f7 ff    	lea    -0x8be83(%eax),%eax
f0100570:	e8 47 fc ff ff       	call   f01001bc <cons_intr>
}
f0100575:	c9                   	leave  
f0100576:	c3                   	ret    

f0100577 <kbd_intr>:
{
f0100577:	55                   	push   %ebp
f0100578:	89 e5                	mov    %esp,%ebp
f010057a:	83 ec 08             	sub    $0x8,%esp
f010057d:	e8 b9 01 00 00       	call   f010073b <__x86.get_pc_thunk.ax>
f0100582:	05 9e ba 08 00       	add    $0x8ba9e,%eax
	cons_intr(kbd_proc_data);
f0100587:	8d 80 e7 41 f7 ff    	lea    -0x8be19(%eax),%eax
f010058d:	e8 2a fc ff ff       	call   f01001bc <cons_intr>
}
f0100592:	c9                   	leave  
f0100593:	c3                   	ret    

f0100594 <cons_getc>:
{
f0100594:	55                   	push   %ebp
f0100595:	89 e5                	mov    %esp,%ebp
f0100597:	53                   	push   %ebx
f0100598:	83 ec 04             	sub    $0x4,%esp
f010059b:	e8 f9 fb ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f01005a0:	81 c3 80 ba 08 00    	add    $0x8ba80,%ebx
	serial_intr();
f01005a6:	e8 a4 ff ff ff       	call   f010054f <serial_intr>
	kbd_intr();
f01005ab:	e8 c7 ff ff ff       	call   f0100577 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f01005b0:	8b 93 00 23 00 00    	mov    0x2300(%ebx),%edx
	return 0;
f01005b6:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f01005bb:	3b 93 04 23 00 00    	cmp    0x2304(%ebx),%edx
f01005c1:	74 19                	je     f01005dc <cons_getc+0x48>
		c = cons.buf[cons.rpos++];
f01005c3:	8d 4a 01             	lea    0x1(%edx),%ecx
f01005c6:	89 8b 00 23 00 00    	mov    %ecx,0x2300(%ebx)
f01005cc:	0f b6 84 13 00 21 00 	movzbl 0x2100(%ebx,%edx,1),%eax
f01005d3:	00 
		if (cons.rpos == CONSBUFSIZE)
f01005d4:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01005da:	74 06                	je     f01005e2 <cons_getc+0x4e>
}
f01005dc:	83 c4 04             	add    $0x4,%esp
f01005df:	5b                   	pop    %ebx
f01005e0:	5d                   	pop    %ebp
f01005e1:	c3                   	ret    
			cons.rpos = 0;
f01005e2:	c7 83 00 23 00 00 00 	movl   $0x0,0x2300(%ebx)
f01005e9:	00 00 00 
f01005ec:	eb ee                	jmp    f01005dc <cons_getc+0x48>

f01005ee <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f01005ee:	55                   	push   %ebp
f01005ef:	89 e5                	mov    %esp,%ebp
f01005f1:	57                   	push   %edi
f01005f2:	56                   	push   %esi
f01005f3:	53                   	push   %ebx
f01005f4:	83 ec 1c             	sub    $0x1c,%esp
f01005f7:	e8 9d fb ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f01005fc:	81 c3 24 ba 08 00    	add    $0x8ba24,%ebx
	was = *cp;
f0100602:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100609:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100610:	5a a5 
	if (*cp != 0xA55A) {
f0100612:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100619:	66 3d 5a a5          	cmp    $0xa55a,%ax
f010061d:	0f 84 bc 00 00 00    	je     f01006df <cons_init+0xf1>
		addr_6845 = MONO_BASE;
f0100623:	c7 83 10 23 00 00 b4 	movl   $0x3b4,0x2310(%ebx)
f010062a:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010062d:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f0100634:	8b bb 10 23 00 00    	mov    0x2310(%ebx),%edi
f010063a:	b8 0e 00 00 00       	mov    $0xe,%eax
f010063f:	89 fa                	mov    %edi,%edx
f0100641:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100642:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100645:	89 ca                	mov    %ecx,%edx
f0100647:	ec                   	in     (%dx),%al
f0100648:	0f b6 f0             	movzbl %al,%esi
f010064b:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010064e:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100653:	89 fa                	mov    %edi,%edx
f0100655:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100656:	89 ca                	mov    %ecx,%edx
f0100658:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f0100659:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010065c:	89 bb 0c 23 00 00    	mov    %edi,0x230c(%ebx)
	pos |= inb(addr_6845 + 1);
f0100662:	0f b6 c0             	movzbl %al,%eax
f0100665:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f0100667:	66 89 b3 08 23 00 00 	mov    %si,0x2308(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010066e:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100673:	89 c8                	mov    %ecx,%eax
f0100675:	ba fa 03 00 00       	mov    $0x3fa,%edx
f010067a:	ee                   	out    %al,(%dx)
f010067b:	bf fb 03 00 00       	mov    $0x3fb,%edi
f0100680:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100685:	89 fa                	mov    %edi,%edx
f0100687:	ee                   	out    %al,(%dx)
f0100688:	b8 0c 00 00 00       	mov    $0xc,%eax
f010068d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100692:	ee                   	out    %al,(%dx)
f0100693:	be f9 03 00 00       	mov    $0x3f9,%esi
f0100698:	89 c8                	mov    %ecx,%eax
f010069a:	89 f2                	mov    %esi,%edx
f010069c:	ee                   	out    %al,(%dx)
f010069d:	b8 03 00 00 00       	mov    $0x3,%eax
f01006a2:	89 fa                	mov    %edi,%edx
f01006a4:	ee                   	out    %al,(%dx)
f01006a5:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01006aa:	89 c8                	mov    %ecx,%eax
f01006ac:	ee                   	out    %al,(%dx)
f01006ad:	b8 01 00 00 00       	mov    $0x1,%eax
f01006b2:	89 f2                	mov    %esi,%edx
f01006b4:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006b5:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01006ba:	ec                   	in     (%dx),%al
f01006bb:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01006bd:	3c ff                	cmp    $0xff,%al
f01006bf:	0f 95 83 14 23 00 00 	setne  0x2314(%ebx)
f01006c6:	ba fa 03 00 00       	mov    $0x3fa,%edx
f01006cb:	ec                   	in     (%dx),%al
f01006cc:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01006d1:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01006d2:	80 f9 ff             	cmp    $0xff,%cl
f01006d5:	74 25                	je     f01006fc <cons_init+0x10e>
		cprintf("Serial port does not exist!\n");
}
f01006d7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01006da:	5b                   	pop    %ebx
f01006db:	5e                   	pop    %esi
f01006dc:	5f                   	pop    %edi
f01006dd:	5d                   	pop    %ebp
f01006de:	c3                   	ret    
		*cp = was;
f01006df:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01006e6:	c7 83 10 23 00 00 d4 	movl   $0x3d4,0x2310(%ebx)
f01006ed:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006f0:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f01006f7:	e9 38 ff ff ff       	jmp    f0100634 <cons_init+0x46>
		cprintf("Serial port does not exist!\n");
f01006fc:	83 ec 0c             	sub    $0xc,%esp
f01006ff:	8d 83 c7 91 f7 ff    	lea    -0x86e39(%ebx),%eax
f0100705:	50                   	push   %eax
f0100706:	e8 4d 35 00 00       	call   f0103c58 <cprintf>
f010070b:	83 c4 10             	add    $0x10,%esp
}
f010070e:	eb c7                	jmp    f01006d7 <cons_init+0xe9>

f0100710 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100710:	55                   	push   %ebp
f0100711:	89 e5                	mov    %esp,%ebp
f0100713:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100716:	8b 45 08             	mov    0x8(%ebp),%eax
f0100719:	e8 1b fc ff ff       	call   f0100339 <cons_putc>
}
f010071e:	c9                   	leave  
f010071f:	c3                   	ret    

f0100720 <getchar>:

int
getchar(void)
{
f0100720:	55                   	push   %ebp
f0100721:	89 e5                	mov    %esp,%ebp
f0100723:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100726:	e8 69 fe ff ff       	call   f0100594 <cons_getc>
f010072b:	85 c0                	test   %eax,%eax
f010072d:	74 f7                	je     f0100726 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010072f:	c9                   	leave  
f0100730:	c3                   	ret    

f0100731 <iscons>:

int
iscons(int fdnum)
{
f0100731:	55                   	push   %ebp
f0100732:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100734:	b8 01 00 00 00       	mov    $0x1,%eax
f0100739:	5d                   	pop    %ebp
f010073a:	c3                   	ret    

f010073b <__x86.get_pc_thunk.ax>:
f010073b:	8b 04 24             	mov    (%esp),%eax
f010073e:	c3                   	ret    

f010073f <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010073f:	55                   	push   %ebp
f0100740:	89 e5                	mov    %esp,%ebp
f0100742:	56                   	push   %esi
f0100743:	53                   	push   %ebx
f0100744:	e8 50 fa ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f0100749:	81 c3 d7 b8 08 00    	add    $0x8b8d7,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010074f:	83 ec 04             	sub    $0x4,%esp
f0100752:	8d 83 00 94 f7 ff    	lea    -0x86c00(%ebx),%eax
f0100758:	50                   	push   %eax
f0100759:	8d 83 1e 94 f7 ff    	lea    -0x86be2(%ebx),%eax
f010075f:	50                   	push   %eax
f0100760:	8d b3 23 94 f7 ff    	lea    -0x86bdd(%ebx),%esi
f0100766:	56                   	push   %esi
f0100767:	e8 ec 34 00 00       	call   f0103c58 <cprintf>
f010076c:	83 c4 0c             	add    $0xc,%esp
f010076f:	8d 83 dc 94 f7 ff    	lea    -0x86b24(%ebx),%eax
f0100775:	50                   	push   %eax
f0100776:	8d 83 2c 94 f7 ff    	lea    -0x86bd4(%ebx),%eax
f010077c:	50                   	push   %eax
f010077d:	56                   	push   %esi
f010077e:	e8 d5 34 00 00       	call   f0103c58 <cprintf>
f0100783:	83 c4 0c             	add    $0xc,%esp
f0100786:	8d 83 04 95 f7 ff    	lea    -0x86afc(%ebx),%eax
f010078c:	50                   	push   %eax
f010078d:	8d 83 35 94 f7 ff    	lea    -0x86bcb(%ebx),%eax
f0100793:	50                   	push   %eax
f0100794:	56                   	push   %esi
f0100795:	e8 be 34 00 00       	call   f0103c58 <cprintf>
	return 0;
}
f010079a:	b8 00 00 00 00       	mov    $0x0,%eax
f010079f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01007a2:	5b                   	pop    %ebx
f01007a3:	5e                   	pop    %esi
f01007a4:	5d                   	pop    %ebp
f01007a5:	c3                   	ret    

f01007a6 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007a6:	55                   	push   %ebp
f01007a7:	89 e5                	mov    %esp,%ebp
f01007a9:	57                   	push   %edi
f01007aa:	56                   	push   %esi
f01007ab:	53                   	push   %ebx
f01007ac:	83 ec 18             	sub    $0x18,%esp
f01007af:	e8 e5 f9 ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f01007b4:	81 c3 6c b8 08 00    	add    $0x8b86c,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007ba:	8d 83 3f 94 f7 ff    	lea    -0x86bc1(%ebx),%eax
f01007c0:	50                   	push   %eax
f01007c1:	e8 92 34 00 00       	call   f0103c58 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007c6:	83 c4 08             	add    $0x8,%esp
f01007c9:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f01007cf:	8d 83 38 95 f7 ff    	lea    -0x86ac8(%ebx),%eax
f01007d5:	50                   	push   %eax
f01007d6:	e8 7d 34 00 00       	call   f0103c58 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007db:	83 c4 0c             	add    $0xc,%esp
f01007de:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f01007e4:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f01007ea:	50                   	push   %eax
f01007eb:	57                   	push   %edi
f01007ec:	8d 83 60 95 f7 ff    	lea    -0x86aa0(%ebx),%eax
f01007f2:	50                   	push   %eax
f01007f3:	e8 60 34 00 00       	call   f0103c58 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007f8:	83 c4 0c             	add    $0xc,%esp
f01007fb:	c7 c0 49 51 10 f0    	mov    $0xf0105149,%eax
f0100801:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100807:	52                   	push   %edx
f0100808:	50                   	push   %eax
f0100809:	8d 83 84 95 f7 ff    	lea    -0x86a7c(%ebx),%eax
f010080f:	50                   	push   %eax
f0100810:	e8 43 34 00 00       	call   f0103c58 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100815:	83 c4 0c             	add    $0xc,%esp
f0100818:	c7 c0 00 e1 18 f0    	mov    $0xf018e100,%eax
f010081e:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100824:	52                   	push   %edx
f0100825:	50                   	push   %eax
f0100826:	8d 83 a8 95 f7 ff    	lea    -0x86a58(%ebx),%eax
f010082c:	50                   	push   %eax
f010082d:	e8 26 34 00 00       	call   f0103c58 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100832:	83 c4 0c             	add    $0xc,%esp
f0100835:	c7 c6 10 f0 18 f0    	mov    $0xf018f010,%esi
f010083b:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f0100841:	50                   	push   %eax
f0100842:	56                   	push   %esi
f0100843:	8d 83 cc 95 f7 ff    	lea    -0x86a34(%ebx),%eax
f0100849:	50                   	push   %eax
f010084a:	e8 09 34 00 00       	call   f0103c58 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f010084f:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100852:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f0100858:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f010085a:	c1 fe 0a             	sar    $0xa,%esi
f010085d:	56                   	push   %esi
f010085e:	8d 83 f0 95 f7 ff    	lea    -0x86a10(%ebx),%eax
f0100864:	50                   	push   %eax
f0100865:	e8 ee 33 00 00       	call   f0103c58 <cprintf>
	return 0;
}
f010086a:	b8 00 00 00 00       	mov    $0x0,%eax
f010086f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100872:	5b                   	pop    %ebx
f0100873:	5e                   	pop    %esi
f0100874:	5f                   	pop    %edi
f0100875:	5d                   	pop    %ebp
f0100876:	c3                   	ret    

f0100877 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100877:	55                   	push   %ebp
f0100878:	89 e5                	mov    %esp,%ebp
f010087a:	57                   	push   %edi
f010087b:	56                   	push   %esi
f010087c:	53                   	push   %ebx
f010087d:	83 ec 58             	sub    $0x58,%esp
f0100880:	e8 14 f9 ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f0100885:	81 c3 9b b7 08 00    	add    $0x8b79b,%ebx
	cprintf("Stack backtrace:\n");
f010088b:	8d 83 58 94 f7 ff    	lea    -0x86ba8(%ebx),%eax
f0100891:	50                   	push   %eax
f0100892:	e8 c1 33 00 00       	call   f0103c58 <cprintf>

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100897:	89 ef                	mov    %ebp,%edi
	int* curr_ebp = (int *) read_ebp();
f0100899:	83 c4 10             	add    $0x10,%esp
		// is already the last function in the call stack, and
		// thus you print the info and return.

		eip = (uint32_t) *(curr_ebp + 1);

		cprintf("  ebp %08x eip %08x ", curr_ebp, eip);
f010089c:	8d 83 6a 94 f7 ff    	lea    -0x86b96(%ebx),%eax
f01008a2:	89 45 b8             	mov    %eax,-0x48(%ebp)
		cprintf("args");
f01008a5:	8d 83 7f 94 f7 ff    	lea    -0x86b81(%ebx),%eax
f01008ab:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		prev_ebp = (int *) *curr_ebp;
f01008ae:	8b 07                	mov    (%edi),%eax
f01008b0:	89 45 c0             	mov    %eax,-0x40(%ebp)
		eip = (uint32_t) *(curr_ebp + 1);
f01008b3:	8b 47 04             	mov    0x4(%edi),%eax
f01008b6:	89 45 bc             	mov    %eax,-0x44(%ebp)
		cprintf("  ebp %08x eip %08x ", curr_ebp, eip);
f01008b9:	83 ec 04             	sub    $0x4,%esp
f01008bc:	50                   	push   %eax
f01008bd:	57                   	push   %edi
f01008be:	ff 75 b8             	pushl  -0x48(%ebp)
f01008c1:	e8 92 33 00 00       	call   f0103c58 <cprintf>
		cprintf("args");
f01008c6:	83 c4 04             	add    $0x4,%esp
f01008c9:	ff 75 b4             	pushl  -0x4c(%ebp)
f01008cc:	e8 87 33 00 00       	call   f0103c58 <cprintf>
		int *arg_p = curr_ebp + 2;
f01008d1:	8d 77 08             	lea    0x8(%edi),%esi
f01008d4:	8d 47 1c             	lea    0x1c(%edi),%eax
f01008d7:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f01008da:	83 c4 10             	add    $0x10,%esp
		for (int i = 0; i < 5; ++i) {
			cprintf(" %08x", *arg_p);
f01008dd:	8d bb 84 94 f7 ff    	lea    -0x86b7c(%ebx),%edi
f01008e3:	83 ec 08             	sub    $0x8,%esp
f01008e6:	ff 36                	pushl  (%esi)
f01008e8:	57                   	push   %edi
f01008e9:	e8 6a 33 00 00       	call   f0103c58 <cprintf>
			++arg_p;
f01008ee:	83 c6 04             	add    $0x4,%esi
		for (int i = 0; i < 5; ++i) {
f01008f1:	83 c4 10             	add    $0x10,%esp
f01008f4:	39 75 c4             	cmp    %esi,-0x3c(%ebp)
f01008f7:	75 ea                	jne    f01008e3 <mon_backtrace+0x6c>
		}

		cprintf("\n");
f01008f9:	83 ec 0c             	sub    $0xc,%esp
f01008fc:	8d 83 61 99 f7 ff    	lea    -0x8669f(%ebx),%eax
f0100902:	50                   	push   %eax
f0100903:	e8 50 33 00 00       	call   f0103c58 <cprintf>

		// debugging info
		struct Eipdebuginfo info;
		debuginfo_eip(eip, &info);
f0100908:	83 c4 08             	add    $0x8,%esp
f010090b:	8d 45 d0             	lea    -0x30(%ebp),%eax
f010090e:	50                   	push   %eax
f010090f:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0100912:	57                   	push   %edi
f0100913:	e8 e6 38 00 00       	call   f01041fe <debuginfo_eip>
		cprintf("        ");
f0100918:	8d 83 8a 94 f7 ff    	lea    -0x86b76(%ebx),%eax
f010091e:	89 04 24             	mov    %eax,(%esp)
f0100921:	e8 32 33 00 00       	call   f0103c58 <cprintf>
		cprintf("%s:%d: ", info.eip_file, info.eip_line);
f0100926:	83 c4 0c             	add    $0xc,%esp
f0100929:	ff 75 d4             	pushl  -0x2c(%ebp)
f010092c:	ff 75 d0             	pushl  -0x30(%ebp)
f010092f:	8d 83 99 91 f7 ff    	lea    -0x86e67(%ebx),%eax
f0100935:	50                   	push   %eax
f0100936:	e8 1d 33 00 00       	call   f0103c58 <cprintf>
		cprintf("%.*s", info.eip_fn_namelen, info.eip_fn_name);
f010093b:	83 c4 0c             	add    $0xc,%esp
f010093e:	ff 75 d8             	pushl  -0x28(%ebp)
f0100941:	ff 75 dc             	pushl  -0x24(%ebp)
f0100944:	8d 83 93 94 f7 ff    	lea    -0x86b6d(%ebx),%eax
f010094a:	50                   	push   %eax
f010094b:	e8 08 33 00 00       	call   f0103c58 <cprintf>
		cprintf("+%d\n", eip - (uint32_t)info.eip_fn_addr);
f0100950:	83 c4 08             	add    $0x8,%esp
f0100953:	89 f8                	mov    %edi,%eax
f0100955:	2b 45 e0             	sub    -0x20(%ebp),%eax
f0100958:	50                   	push   %eax
f0100959:	8d 83 98 94 f7 ff    	lea    -0x86b68(%ebx),%eax
f010095f:	50                   	push   %eax
f0100960:	e8 f3 32 00 00       	call   f0103c58 <cprintf>

		// Check ending
		if (prev_ebp == 0) {
f0100965:	83 c4 10             	add    $0x10,%esp
f0100968:	8b 7d c0             	mov    -0x40(%ebp),%edi
f010096b:	85 ff                	test   %edi,%edi
f010096d:	0f 85 3b ff ff ff    	jne    f01008ae <mon_backtrace+0x37>
		} else {
			curr_ebp = prev_ebp;
		}
	}
	return 0;
}
f0100973:	b8 00 00 00 00       	mov    $0x0,%eax
f0100978:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010097b:	5b                   	pop    %ebx
f010097c:	5e                   	pop    %esi
f010097d:	5f                   	pop    %edi
f010097e:	5d                   	pop    %ebp
f010097f:	c3                   	ret    

f0100980 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100980:	55                   	push   %ebp
f0100981:	89 e5                	mov    %esp,%ebp
f0100983:	57                   	push   %edi
f0100984:	56                   	push   %esi
f0100985:	53                   	push   %ebx
f0100986:	83 ec 68             	sub    $0x68,%esp
f0100989:	e8 0b f8 ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f010098e:	81 c3 92 b6 08 00    	add    $0x8b692,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100994:	8d 83 1c 96 f7 ff    	lea    -0x869e4(%ebx),%eax
f010099a:	50                   	push   %eax
f010099b:	e8 b8 32 00 00       	call   f0103c58 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01009a0:	8d 83 40 96 f7 ff    	lea    -0x869c0(%ebx),%eax
f01009a6:	89 04 24             	mov    %eax,(%esp)
f01009a9:	e8 aa 32 00 00       	call   f0103c58 <cprintf>

	if (tf != NULL)
f01009ae:	83 c4 10             	add    $0x10,%esp
f01009b1:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01009b5:	74 0e                	je     f01009c5 <monitor+0x45>
		print_trapframe(tf);
f01009b7:	83 ec 0c             	sub    $0xc,%esp
f01009ba:	ff 75 08             	pushl  0x8(%ebp)
f01009bd:	e8 ff 33 00 00       	call   f0103dc1 <print_trapframe>
f01009c2:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f01009c5:	8d bb a1 94 f7 ff    	lea    -0x86b5f(%ebx),%edi
f01009cb:	eb 4a                	jmp    f0100a17 <monitor+0x97>
f01009cd:	83 ec 08             	sub    $0x8,%esp
f01009d0:	0f be c0             	movsbl %al,%eax
f01009d3:	50                   	push   %eax
f01009d4:	57                   	push   %edi
f01009d5:	e8 f0 42 00 00       	call   f0104cca <strchr>
f01009da:	83 c4 10             	add    $0x10,%esp
f01009dd:	85 c0                	test   %eax,%eax
f01009df:	74 08                	je     f01009e9 <monitor+0x69>
			*buf++ = 0;
f01009e1:	c6 06 00             	movb   $0x0,(%esi)
f01009e4:	8d 76 01             	lea    0x1(%esi),%esi
f01009e7:	eb 76                	jmp    f0100a5f <monitor+0xdf>
		if (*buf == 0)
f01009e9:	80 3e 00             	cmpb   $0x0,(%esi)
f01009ec:	74 7c                	je     f0100a6a <monitor+0xea>
		if (argc == MAXARGS-1) {
f01009ee:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f01009f2:	74 0f                	je     f0100a03 <monitor+0x83>
		argv[argc++] = buf;
f01009f4:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01009f7:	8d 48 01             	lea    0x1(%eax),%ecx
f01009fa:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f01009fd:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
f0100a01:	eb 41                	jmp    f0100a44 <monitor+0xc4>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100a03:	83 ec 08             	sub    $0x8,%esp
f0100a06:	6a 10                	push   $0x10
f0100a08:	8d 83 a6 94 f7 ff    	lea    -0x86b5a(%ebx),%eax
f0100a0e:	50                   	push   %eax
f0100a0f:	e8 44 32 00 00       	call   f0103c58 <cprintf>
f0100a14:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100a17:	8d 83 9d 94 f7 ff    	lea    -0x86b63(%ebx),%eax
f0100a1d:	89 c6                	mov    %eax,%esi
f0100a1f:	83 ec 0c             	sub    $0xc,%esp
f0100a22:	56                   	push   %esi
f0100a23:	e8 6a 40 00 00       	call   f0104a92 <readline>
		if (buf != NULL)
f0100a28:	83 c4 10             	add    $0x10,%esp
f0100a2b:	85 c0                	test   %eax,%eax
f0100a2d:	74 f0                	je     f0100a1f <monitor+0x9f>
f0100a2f:	89 c6                	mov    %eax,%esi
	argv[argc] = 0;
f0100a31:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100a38:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f0100a3f:	eb 1e                	jmp    f0100a5f <monitor+0xdf>
			buf++;
f0100a41:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a44:	0f b6 06             	movzbl (%esi),%eax
f0100a47:	84 c0                	test   %al,%al
f0100a49:	74 14                	je     f0100a5f <monitor+0xdf>
f0100a4b:	83 ec 08             	sub    $0x8,%esp
f0100a4e:	0f be c0             	movsbl %al,%eax
f0100a51:	50                   	push   %eax
f0100a52:	57                   	push   %edi
f0100a53:	e8 72 42 00 00       	call   f0104cca <strchr>
f0100a58:	83 c4 10             	add    $0x10,%esp
f0100a5b:	85 c0                	test   %eax,%eax
f0100a5d:	74 e2                	je     f0100a41 <monitor+0xc1>
		while (*buf && strchr(WHITESPACE, *buf))
f0100a5f:	0f b6 06             	movzbl (%esi),%eax
f0100a62:	84 c0                	test   %al,%al
f0100a64:	0f 85 63 ff ff ff    	jne    f01009cd <monitor+0x4d>
	argv[argc] = 0;
f0100a6a:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100a6d:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f0100a74:	00 
	if (argc == 0)
f0100a75:	85 c0                	test   %eax,%eax
f0100a77:	74 9e                	je     f0100a17 <monitor+0x97>
f0100a79:	8d b3 20 20 00 00    	lea    0x2020(%ebx),%esi
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a7f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a84:	89 7d a0             	mov    %edi,-0x60(%ebp)
f0100a87:	89 c7                	mov    %eax,%edi
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a89:	83 ec 08             	sub    $0x8,%esp
f0100a8c:	ff 36                	pushl  (%esi)
f0100a8e:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a91:	e8 d6 41 00 00       	call   f0104c6c <strcmp>
f0100a96:	83 c4 10             	add    $0x10,%esp
f0100a99:	85 c0                	test   %eax,%eax
f0100a9b:	74 28                	je     f0100ac5 <monitor+0x145>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a9d:	83 c7 01             	add    $0x1,%edi
f0100aa0:	83 c6 0c             	add    $0xc,%esi
f0100aa3:	83 ff 03             	cmp    $0x3,%edi
f0100aa6:	75 e1                	jne    f0100a89 <monitor+0x109>
f0100aa8:	8b 7d a0             	mov    -0x60(%ebp),%edi
	cprintf("Unknown command '%s'\n", argv[0]);
f0100aab:	83 ec 08             	sub    $0x8,%esp
f0100aae:	ff 75 a8             	pushl  -0x58(%ebp)
f0100ab1:	8d 83 c3 94 f7 ff    	lea    -0x86b3d(%ebx),%eax
f0100ab7:	50                   	push   %eax
f0100ab8:	e8 9b 31 00 00       	call   f0103c58 <cprintf>
f0100abd:	83 c4 10             	add    $0x10,%esp
f0100ac0:	e9 52 ff ff ff       	jmp    f0100a17 <monitor+0x97>
f0100ac5:	89 f8                	mov    %edi,%eax
f0100ac7:	8b 7d a0             	mov    -0x60(%ebp),%edi
			return commands[i].func(argc, argv, tf);
f0100aca:	83 ec 04             	sub    $0x4,%esp
f0100acd:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100ad0:	ff 75 08             	pushl  0x8(%ebp)
f0100ad3:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100ad6:	52                   	push   %edx
f0100ad7:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100ada:	ff 94 83 28 20 00 00 	call   *0x2028(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100ae1:	83 c4 10             	add    $0x10,%esp
f0100ae4:	85 c0                	test   %eax,%eax
f0100ae6:	0f 89 2b ff ff ff    	jns    f0100a17 <monitor+0x97>
				break;
	}
}
f0100aec:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100aef:	5b                   	pop    %ebx
f0100af0:	5e                   	pop    %esi
f0100af1:	5f                   	pop    %edi
f0100af2:	5d                   	pop    %ebp
f0100af3:	c3                   	ret    

f0100af4 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100af4:	55                   	push   %ebp
f0100af5:	89 e5                	mov    %esp,%ebp
f0100af7:	57                   	push   %edi
f0100af8:	56                   	push   %esi
f0100af9:	53                   	push   %ebx
f0100afa:	83 ec 18             	sub    $0x18,%esp
f0100afd:	e8 97 f6 ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f0100b02:	81 c3 1e b5 08 00    	add    $0x8b51e,%ebx
f0100b08:	89 c7                	mov    %eax,%edi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100b0a:	50                   	push   %eax
f0100b0b:	e8 c1 30 00 00       	call   f0103bd1 <mc146818_read>
f0100b10:	89 c6                	mov    %eax,%esi
f0100b12:	83 c7 01             	add    $0x1,%edi
f0100b15:	89 3c 24             	mov    %edi,(%esp)
f0100b18:	e8 b4 30 00 00       	call   f0103bd1 <mc146818_read>
f0100b1d:	c1 e0 08             	shl    $0x8,%eax
f0100b20:	09 f0                	or     %esi,%eax
}
f0100b22:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100b25:	5b                   	pop    %ebx
f0100b26:	5e                   	pop    %esi
f0100b27:	5f                   	pop    %edi
f0100b28:	5d                   	pop    %ebp
f0100b29:	c3                   	ret    

f0100b2a <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100b2a:	55                   	push   %ebp
f0100b2b:	89 e5                	mov    %esp,%ebp
f0100b2d:	53                   	push   %ebx
f0100b2e:	83 ec 04             	sub    $0x4,%esp
f0100b31:	e8 63 f6 ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f0100b36:	81 c3 ea b4 08 00    	add    $0x8b4ea,%ebx
f0100b3c:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100b3e:	83 bb 18 23 00 00 00 	cmpl   $0x0,0x2318(%ebx)
f0100b45:	74 27                	je     f0100b6e <boot_alloc+0x44>
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	/* Check within 4MB Limit. Mentioned in Lab1. */
	if ((uint32_t)(nextfree + ROUNDUP(n, PGSIZE)) <= 0x400000 + KERNBASE) {
f0100b47:	8b 83 18 23 00 00    	mov    0x2318(%ebx),%eax
f0100b4d:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f0100b53:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b59:	01 c2                	add    %eax,%edx
f0100b5b:	81 fa 00 00 40 f0    	cmp    $0xf0400000,%edx
f0100b61:	77 23                	ja     f0100b86 <boot_alloc+0x5c>
		if (n >= 0) {
			result = nextfree;
			nextfree += ROUNDUP(n, PGSIZE);
f0100b63:	89 93 18 23 00 00    	mov    %edx,0x2318(%ebx)
	} else {
		panic("Exceed 4MB Limit");
	}

	return NULL;
}
f0100b69:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100b6c:	c9                   	leave  
f0100b6d:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100b6e:	c7 c0 10 f0 18 f0    	mov    $0xf018f010,%eax
f0100b74:	05 ff 0f 00 00       	add    $0xfff,%eax
f0100b79:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b7e:	89 83 18 23 00 00    	mov    %eax,0x2318(%ebx)
f0100b84:	eb c1                	jmp    f0100b47 <boot_alloc+0x1d>
		panic("Exceed 4MB Limit");
f0100b86:	83 ec 04             	sub    $0x4,%esp
f0100b89:	8d 83 65 96 f7 ff    	lea    -0x8699b(%ebx),%eax
f0100b8f:	50                   	push   %eax
f0100b90:	6a 75                	push   $0x75
f0100b92:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0100b98:	50                   	push   %eax
f0100b99:	e8 45 f5 ff ff       	call   f01000e3 <_panic>

f0100b9e <check_va2pa>:
// defined by the page directory 'pgdir'.  The hardware normally performs
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100b9e:	55                   	push   %ebp
f0100b9f:	89 e5                	mov    %esp,%ebp
f0100ba1:	56                   	push   %esi
f0100ba2:	53                   	push   %ebx
f0100ba3:	e8 de 27 00 00       	call   f0103386 <__x86.get_pc_thunk.cx>
f0100ba8:	81 c1 78 b4 08 00    	add    $0x8b478,%ecx
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100bae:	89 d3                	mov    %edx,%ebx
f0100bb0:	c1 eb 16             	shr    $0x16,%ebx
	if (!(*pgdir & PTE_P))
f0100bb3:	8b 04 98             	mov    (%eax,%ebx,4),%eax
f0100bb6:	a8 01                	test   $0x1,%al
f0100bb8:	74 5a                	je     f0100c14 <check_va2pa+0x76>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100bba:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bbf:	89 c6                	mov    %eax,%esi
f0100bc1:	c1 ee 0c             	shr    $0xc,%esi
f0100bc4:	c7 c3 04 f0 18 f0    	mov    $0xf018f004,%ebx
f0100bca:	3b 33                	cmp    (%ebx),%esi
f0100bcc:	73 2b                	jae    f0100bf9 <check_va2pa+0x5b>
	if (!(p[PTX(va)] & PTE_P))
f0100bce:	c1 ea 0c             	shr    $0xc,%edx
f0100bd1:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100bd7:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100bde:	89 c2                	mov    %eax,%edx
f0100be0:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100be3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100be8:	85 d2                	test   %edx,%edx
f0100bea:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100bef:	0f 44 c2             	cmove  %edx,%eax
}
f0100bf2:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100bf5:	5b                   	pop    %ebx
f0100bf6:	5e                   	pop    %esi
f0100bf7:	5d                   	pop    %ebp
f0100bf8:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bf9:	50                   	push   %eax
f0100bfa:	8d 81 94 99 f7 ff    	lea    -0x8666c(%ecx),%eax
f0100c00:	50                   	push   %eax
f0100c01:	68 86 03 00 00       	push   $0x386
f0100c06:	8d 81 76 96 f7 ff    	lea    -0x8698a(%ecx),%eax
f0100c0c:	50                   	push   %eax
f0100c0d:	89 cb                	mov    %ecx,%ebx
f0100c0f:	e8 cf f4 ff ff       	call   f01000e3 <_panic>
		return ~0;
f0100c14:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100c19:	eb d7                	jmp    f0100bf2 <check_va2pa+0x54>

f0100c1b <check_page_free_list>:
{
f0100c1b:	55                   	push   %ebp
f0100c1c:	89 e5                	mov    %esp,%ebp
f0100c1e:	57                   	push   %edi
f0100c1f:	56                   	push   %esi
f0100c20:	53                   	push   %ebx
f0100c21:	83 ec 3c             	sub    $0x3c,%esp
f0100c24:	e8 61 27 00 00       	call   f010338a <__x86.get_pc_thunk.di>
f0100c29:	81 c7 f7 b3 08 00    	add    $0x8b3f7,%edi
f0100c2f:	89 7d c4             	mov    %edi,-0x3c(%ebp)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c32:	84 c0                	test   %al,%al
f0100c34:	0f 85 dd 02 00 00    	jne    f0100f17 <check_page_free_list+0x2fc>
	if (!page_free_list)
f0100c3a:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100c3d:	83 b8 1c 23 00 00 00 	cmpl   $0x0,0x231c(%eax)
f0100c44:	74 0c                	je     f0100c52 <check_page_free_list+0x37>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c46:	c7 45 d4 00 04 00 00 	movl   $0x400,-0x2c(%ebp)
f0100c4d:	e9 2f 03 00 00       	jmp    f0100f81 <check_page_free_list+0x366>
		panic("'page_free_list' is a null pointer!");
f0100c52:	83 ec 04             	sub    $0x4,%esp
f0100c55:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c58:	8d 83 b8 99 f7 ff    	lea    -0x86648(%ebx),%eax
f0100c5e:	50                   	push   %eax
f0100c5f:	68 c3 02 00 00       	push   $0x2c3
f0100c64:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0100c6a:	50                   	push   %eax
f0100c6b:	e8 73 f4 ff ff       	call   f01000e3 <_panic>
f0100c70:	50                   	push   %eax
f0100c71:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c74:	8d 83 94 99 f7 ff    	lea    -0x8666c(%ebx),%eax
f0100c7a:	50                   	push   %eax
f0100c7b:	6a 56                	push   $0x56
f0100c7d:	8d 83 82 96 f7 ff    	lea    -0x8697e(%ebx),%eax
f0100c83:	50                   	push   %eax
f0100c84:	e8 5a f4 ff ff       	call   f01000e3 <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c89:	8b 36                	mov    (%esi),%esi
f0100c8b:	85 f6                	test   %esi,%esi
f0100c8d:	74 40                	je     f0100ccf <check_page_free_list+0xb4>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c8f:	89 f0                	mov    %esi,%eax
f0100c91:	2b 07                	sub    (%edi),%eax
f0100c93:	c1 f8 03             	sar    $0x3,%eax
f0100c96:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100c99:	89 c2                	mov    %eax,%edx
f0100c9b:	c1 ea 16             	shr    $0x16,%edx
f0100c9e:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100ca1:	73 e6                	jae    f0100c89 <check_page_free_list+0x6e>
	if (PGNUM(pa) >= npages)
f0100ca3:	89 c2                	mov    %eax,%edx
f0100ca5:	c1 ea 0c             	shr    $0xc,%edx
f0100ca8:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100cab:	3b 11                	cmp    (%ecx),%edx
f0100cad:	73 c1                	jae    f0100c70 <check_page_free_list+0x55>
			memset(page2kva(pp), 0x97, 128);
f0100caf:	83 ec 04             	sub    $0x4,%esp
f0100cb2:	68 80 00 00 00       	push   $0x80
f0100cb7:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100cbc:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100cc1:	50                   	push   %eax
f0100cc2:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100cc5:	e8 3d 40 00 00       	call   f0104d07 <memset>
f0100cca:	83 c4 10             	add    $0x10,%esp
f0100ccd:	eb ba                	jmp    f0100c89 <check_page_free_list+0x6e>
	first_free_page = (char *) boot_alloc(0);
f0100ccf:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cd4:	e8 51 fe ff ff       	call   f0100b2a <boot_alloc>
f0100cd9:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100cdc:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100cdf:	8b 97 1c 23 00 00    	mov    0x231c(%edi),%edx
		assert(pp >= pages);
f0100ce5:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0100ceb:	8b 08                	mov    (%eax),%ecx
		assert(pp < pages + npages);
f0100ced:	c7 c0 04 f0 18 f0    	mov    $0xf018f004,%eax
f0100cf3:	8b 00                	mov    (%eax),%eax
f0100cf5:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100cf8:	8d 1c c1             	lea    (%ecx,%eax,8),%ebx
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100cfb:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f0100cfe:	bf 00 00 00 00       	mov    $0x0,%edi
f0100d03:	89 75 d0             	mov    %esi,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d06:	e9 08 01 00 00       	jmp    f0100e13 <check_page_free_list+0x1f8>
		assert(pp >= pages);
f0100d0b:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d0e:	8d 83 90 96 f7 ff    	lea    -0x86970(%ebx),%eax
f0100d14:	50                   	push   %eax
f0100d15:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0100d1b:	50                   	push   %eax
f0100d1c:	68 dd 02 00 00       	push   $0x2dd
f0100d21:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0100d27:	50                   	push   %eax
f0100d28:	e8 b6 f3 ff ff       	call   f01000e3 <_panic>
		assert(pp < pages + npages);
f0100d2d:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d30:	8d 83 b1 96 f7 ff    	lea    -0x8694f(%ebx),%eax
f0100d36:	50                   	push   %eax
f0100d37:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0100d3d:	50                   	push   %eax
f0100d3e:	68 de 02 00 00       	push   $0x2de
f0100d43:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0100d49:	50                   	push   %eax
f0100d4a:	e8 94 f3 ff ff       	call   f01000e3 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d4f:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d52:	8d 83 dc 99 f7 ff    	lea    -0x86624(%ebx),%eax
f0100d58:	50                   	push   %eax
f0100d59:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0100d5f:	50                   	push   %eax
f0100d60:	68 df 02 00 00       	push   $0x2df
f0100d65:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0100d6b:	50                   	push   %eax
f0100d6c:	e8 72 f3 ff ff       	call   f01000e3 <_panic>
		assert(page2pa(pp) != 0);
f0100d71:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d74:	8d 83 c5 96 f7 ff    	lea    -0x8693b(%ebx),%eax
f0100d7a:	50                   	push   %eax
f0100d7b:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0100d81:	50                   	push   %eax
f0100d82:	68 e2 02 00 00       	push   $0x2e2
f0100d87:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0100d8d:	50                   	push   %eax
f0100d8e:	e8 50 f3 ff ff       	call   f01000e3 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d93:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d96:	8d 83 d6 96 f7 ff    	lea    -0x8692a(%ebx),%eax
f0100d9c:	50                   	push   %eax
f0100d9d:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0100da3:	50                   	push   %eax
f0100da4:	68 e3 02 00 00       	push   $0x2e3
f0100da9:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0100daf:	50                   	push   %eax
f0100db0:	e8 2e f3 ff ff       	call   f01000e3 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100db5:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100db8:	8d 83 10 9a f7 ff    	lea    -0x865f0(%ebx),%eax
f0100dbe:	50                   	push   %eax
f0100dbf:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0100dc5:	50                   	push   %eax
f0100dc6:	68 e4 02 00 00       	push   $0x2e4
f0100dcb:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0100dd1:	50                   	push   %eax
f0100dd2:	e8 0c f3 ff ff       	call   f01000e3 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100dd7:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100dda:	8d 83 ef 96 f7 ff    	lea    -0x86911(%ebx),%eax
f0100de0:	50                   	push   %eax
f0100de1:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0100de7:	50                   	push   %eax
f0100de8:	68 e5 02 00 00       	push   $0x2e5
f0100ded:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0100df3:	50                   	push   %eax
f0100df4:	e8 ea f2 ff ff       	call   f01000e3 <_panic>
	if (PGNUM(pa) >= npages)
f0100df9:	89 c6                	mov    %eax,%esi
f0100dfb:	c1 ee 0c             	shr    $0xc,%esi
f0100dfe:	39 75 cc             	cmp    %esi,-0x34(%ebp)
f0100e01:	76 70                	jbe    f0100e73 <check_page_free_list+0x258>
	return (void *)(pa + KERNBASE);
f0100e03:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e08:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100e0b:	77 7f                	ja     f0100e8c <check_page_free_list+0x271>
			++nfree_extmem;
f0100e0d:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100e11:	8b 12                	mov    (%edx),%edx
f0100e13:	85 d2                	test   %edx,%edx
f0100e15:	0f 84 93 00 00 00    	je     f0100eae <check_page_free_list+0x293>
		assert(pp >= pages);
f0100e1b:	39 d1                	cmp    %edx,%ecx
f0100e1d:	0f 87 e8 fe ff ff    	ja     f0100d0b <check_page_free_list+0xf0>
		assert(pp < pages + npages);
f0100e23:	39 d3                	cmp    %edx,%ebx
f0100e25:	0f 86 02 ff ff ff    	jbe    f0100d2d <check_page_free_list+0x112>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100e2b:	89 d0                	mov    %edx,%eax
f0100e2d:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100e30:	a8 07                	test   $0x7,%al
f0100e32:	0f 85 17 ff ff ff    	jne    f0100d4f <check_page_free_list+0x134>
	return (pp - pages) << PGSHIFT;
f0100e38:	c1 f8 03             	sar    $0x3,%eax
f0100e3b:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f0100e3e:	85 c0                	test   %eax,%eax
f0100e40:	0f 84 2b ff ff ff    	je     f0100d71 <check_page_free_list+0x156>
		assert(page2pa(pp) != IOPHYSMEM);
f0100e46:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100e4b:	0f 84 42 ff ff ff    	je     f0100d93 <check_page_free_list+0x178>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100e51:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100e56:	0f 84 59 ff ff ff    	je     f0100db5 <check_page_free_list+0x19a>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100e5c:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100e61:	0f 84 70 ff ff ff    	je     f0100dd7 <check_page_free_list+0x1bc>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e67:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100e6c:	77 8b                	ja     f0100df9 <check_page_free_list+0x1de>
			++nfree_basemem;
f0100e6e:	83 c7 01             	add    $0x1,%edi
f0100e71:	eb 9e                	jmp    f0100e11 <check_page_free_list+0x1f6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e73:	50                   	push   %eax
f0100e74:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e77:	8d 83 94 99 f7 ff    	lea    -0x8666c(%ebx),%eax
f0100e7d:	50                   	push   %eax
f0100e7e:	6a 56                	push   $0x56
f0100e80:	8d 83 82 96 f7 ff    	lea    -0x8697e(%ebx),%eax
f0100e86:	50                   	push   %eax
f0100e87:	e8 57 f2 ff ff       	call   f01000e3 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e8c:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e8f:	8d 83 34 9a f7 ff    	lea    -0x865cc(%ebx),%eax
f0100e95:	50                   	push   %eax
f0100e96:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0100e9c:	50                   	push   %eax
f0100e9d:	68 e6 02 00 00       	push   $0x2e6
f0100ea2:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0100ea8:	50                   	push   %eax
f0100ea9:	e8 35 f2 ff ff       	call   f01000e3 <_panic>
f0100eae:	8b 75 d0             	mov    -0x30(%ebp),%esi
	assert(nfree_basemem > 0);
f0100eb1:	85 ff                	test   %edi,%edi
f0100eb3:	7e 1e                	jle    f0100ed3 <check_page_free_list+0x2b8>
	assert(nfree_extmem > 0);
f0100eb5:	85 f6                	test   %esi,%esi
f0100eb7:	7e 3c                	jle    f0100ef5 <check_page_free_list+0x2da>
	cprintf("check_page_free_list() succeeded!\n");
f0100eb9:	83 ec 0c             	sub    $0xc,%esp
f0100ebc:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100ebf:	8d 83 7c 9a f7 ff    	lea    -0x86584(%ebx),%eax
f0100ec5:	50                   	push   %eax
f0100ec6:	e8 8d 2d 00 00       	call   f0103c58 <cprintf>
}
f0100ecb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ece:	5b                   	pop    %ebx
f0100ecf:	5e                   	pop    %esi
f0100ed0:	5f                   	pop    %edi
f0100ed1:	5d                   	pop    %ebp
f0100ed2:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100ed3:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100ed6:	8d 83 09 97 f7 ff    	lea    -0x868f7(%ebx),%eax
f0100edc:	50                   	push   %eax
f0100edd:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0100ee3:	50                   	push   %eax
f0100ee4:	68 ee 02 00 00       	push   $0x2ee
f0100ee9:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0100eef:	50                   	push   %eax
f0100ef0:	e8 ee f1 ff ff       	call   f01000e3 <_panic>
	assert(nfree_extmem > 0);
f0100ef5:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100ef8:	8d 83 1b 97 f7 ff    	lea    -0x868e5(%ebx),%eax
f0100efe:	50                   	push   %eax
f0100eff:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0100f05:	50                   	push   %eax
f0100f06:	68 ef 02 00 00       	push   $0x2ef
f0100f0b:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0100f11:	50                   	push   %eax
f0100f12:	e8 cc f1 ff ff       	call   f01000e3 <_panic>
	if (!page_free_list)
f0100f17:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100f1a:	8b 80 1c 23 00 00    	mov    0x231c(%eax),%eax
f0100f20:	85 c0                	test   %eax,%eax
f0100f22:	0f 84 2a fd ff ff    	je     f0100c52 <check_page_free_list+0x37>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100f28:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100f2b:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100f2e:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100f31:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100f34:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100f37:	c7 c3 0c f0 18 f0    	mov    $0xf018f00c,%ebx
f0100f3d:	89 c2                	mov    %eax,%edx
f0100f3f:	2b 13                	sub    (%ebx),%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100f41:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100f47:	0f 95 c2             	setne  %dl
f0100f4a:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100f4d:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100f51:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100f53:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100f57:	8b 00                	mov    (%eax),%eax
f0100f59:	85 c0                	test   %eax,%eax
f0100f5b:	75 e0                	jne    f0100f3d <check_page_free_list+0x322>
		*tp[1] = 0;
f0100f5d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100f60:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100f66:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100f69:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f6c:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100f6e:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100f71:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100f74:	89 87 1c 23 00 00    	mov    %eax,0x231c(%edi)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100f7a:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100f81:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100f84:	8b b0 1c 23 00 00    	mov    0x231c(%eax),%esi
f0100f8a:	c7 c7 0c f0 18 f0    	mov    $0xf018f00c,%edi
	if (PGNUM(pa) >= npages)
f0100f90:	c7 c0 04 f0 18 f0    	mov    $0xf018f004,%eax
f0100f96:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100f99:	e9 ed fc ff ff       	jmp    f0100c8b <check_page_free_list+0x70>

f0100f9e <page_init>:
{
f0100f9e:	55                   	push   %ebp
f0100f9f:	89 e5                	mov    %esp,%ebp
f0100fa1:	57                   	push   %edi
f0100fa2:	56                   	push   %esi
f0100fa3:	53                   	push   %ebx
f0100fa4:	83 ec 1c             	sub    $0x1c,%esp
f0100fa7:	e8 de 23 00 00       	call   f010338a <__x86.get_pc_thunk.di>
f0100fac:	81 c7 74 b0 08 00    	add    $0x8b074,%edi
f0100fb2:	89 fe                	mov    %edi,%esi
f0100fb4:	89 7d e4             	mov    %edi,-0x1c(%ebp)
	pages[0].pp_ref = 1;
f0100fb7:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0100fbd:	8b 00                	mov    (%eax),%eax
f0100fbf:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	pages[0].pp_link = NULL;
f0100fc5:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	for(i = 1; i < npages_basemem; ++i) {
f0100fcb:	8b bf 20 23 00 00    	mov    0x2320(%edi),%edi
f0100fd1:	8b 8e 1c 23 00 00    	mov    0x231c(%esi),%ecx
f0100fd7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fdc:	bb 01 00 00 00       	mov    $0x1,%ebx
		pages[i].pp_ref = 0;
f0100fe1:	c7 c6 0c f0 18 f0    	mov    $0xf018f00c,%esi
	for(i = 1; i < npages_basemem; ++i) {
f0100fe7:	eb 1f                	jmp    f0101008 <page_init+0x6a>
		pages[i].pp_ref = 0;
f0100fe9:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
f0100ff0:	89 c2                	mov    %eax,%edx
f0100ff2:	03 16                	add    (%esi),%edx
f0100ff4:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
		pages[i].pp_link = page_free_list;
f0100ffa:	89 0a                	mov    %ecx,(%edx)
	for(i = 1; i < npages_basemem; ++i) {
f0100ffc:	83 c3 01             	add    $0x1,%ebx
		page_free_list = &pages[i];
f0100fff:	03 06                	add    (%esi),%eax
f0101001:	89 c1                	mov    %eax,%ecx
f0101003:	b8 01 00 00 00       	mov    $0x1,%eax
	for(i = 1; i < npages_basemem; ++i) {
f0101008:	39 df                	cmp    %ebx,%edi
f010100a:	77 dd                	ja     f0100fe9 <page_init+0x4b>
f010100c:	84 c0                	test   %al,%al
f010100e:	75 12                	jne    f0101022 <page_init+0x84>
f0101010:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
		pages[i].pp_ref = 1;
f0101017:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010101a:	c7 c1 0c f0 18 f0    	mov    $0xf018f00c,%ecx
f0101020:	eb 21                	jmp    f0101043 <page_init+0xa5>
f0101022:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101025:	89 88 1c 23 00 00    	mov    %ecx,0x231c(%eax)
f010102b:	eb e3                	jmp    f0101010 <page_init+0x72>
f010102d:	89 c2                	mov    %eax,%edx
f010102f:	03 11                	add    (%ecx),%edx
f0101031:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
		pages[i].pp_link = NULL;
f0101037:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
	for(; i < EXTPHYSMEM / PGSIZE; ++i) {
f010103d:	83 c3 01             	add    $0x1,%ebx
f0101040:	83 c0 08             	add    $0x8,%eax
f0101043:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f0101049:	76 e2                	jbe    f010102d <page_init+0x8f>
	char* first_free_page = (char *)PADDR(boot_alloc(0));
f010104b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101050:	e8 d5 fa ff ff       	call   f0100b2a <boot_alloc>
	if ((uint32_t)kva < KERNBASE)
f0101055:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010105a:	76 1a                	jbe    f0101076 <page_init+0xd8>
	return (physaddr_t)kva - KERNBASE;
f010105c:	05 00 00 00 10       	add    $0x10000000,%eax
	for(; i < (uint32_t)first_free_page / PGSIZE; ++i) {
f0101061:	c1 e8 0c             	shr    $0xc,%eax
f0101064:	8d 14 dd 00 00 00 00 	lea    0x0(,%ebx,8),%edx
		pages[i].pp_ref = 1;
f010106b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010106e:	c7 c6 0c f0 18 f0    	mov    $0xf018f00c,%esi
	for(; i < (uint32_t)first_free_page / PGSIZE; ++i) {
f0101074:	eb 32                	jmp    f01010a8 <page_init+0x10a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101076:	50                   	push   %eax
f0101077:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010107a:	8d 83 a0 9a f7 ff    	lea    -0x86560(%ebx),%eax
f0101080:	50                   	push   %eax
f0101081:	68 4b 01 00 00       	push   $0x14b
f0101086:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f010108c:	50                   	push   %eax
f010108d:	e8 51 f0 ff ff       	call   f01000e3 <_panic>
		pages[i].pp_ref = 1;
f0101092:	89 d1                	mov    %edx,%ecx
f0101094:	03 0e                	add    (%esi),%ecx
f0101096:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
		pages[i].pp_link = NULL;
f010109c:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	for(; i < (uint32_t)first_free_page / PGSIZE; ++i) {
f01010a2:	83 c3 01             	add    $0x1,%ebx
f01010a5:	83 c2 08             	add    $0x8,%edx
f01010a8:	39 d8                	cmp    %ebx,%eax
f01010aa:	77 e6                	ja     f0101092 <page_init+0xf4>
f01010ac:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01010af:	8b 8e 1c 23 00 00    	mov    0x231c(%esi),%ecx
f01010b5:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
f01010bc:	ba 00 00 00 00       	mov    $0x0,%edx
	for(; i < npages; ++i) {
f01010c1:	c7 c7 04 f0 18 f0    	mov    $0xf018f004,%edi
		pages[i].pp_ref = 0;
f01010c7:	c7 c6 0c f0 18 f0    	mov    $0xf018f00c,%esi
f01010cd:	eb 1b                	jmp    f01010ea <page_init+0x14c>
f01010cf:	89 c2                	mov    %eax,%edx
f01010d1:	03 16                	add    (%esi),%edx
f01010d3:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
		pages[i].pp_link = page_free_list;
f01010d9:	89 0a                	mov    %ecx,(%edx)
		page_free_list = &pages[i];
f01010db:	89 c1                	mov    %eax,%ecx
f01010dd:	03 0e                	add    (%esi),%ecx
	for(; i < npages; ++i) {
f01010df:	83 c3 01             	add    $0x1,%ebx
f01010e2:	83 c0 08             	add    $0x8,%eax
f01010e5:	ba 01 00 00 00       	mov    $0x1,%edx
f01010ea:	39 1f                	cmp    %ebx,(%edi)
f01010ec:	77 e1                	ja     f01010cf <page_init+0x131>
f01010ee:	84 d2                	test   %dl,%dl
f01010f0:	75 08                	jne    f01010fa <page_init+0x15c>
}
f01010f2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01010f5:	5b                   	pop    %ebx
f01010f6:	5e                   	pop    %esi
f01010f7:	5f                   	pop    %edi
f01010f8:	5d                   	pop    %ebp
f01010f9:	c3                   	ret    
f01010fa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01010fd:	89 88 1c 23 00 00    	mov    %ecx,0x231c(%eax)
f0101103:	eb ed                	jmp    f01010f2 <page_init+0x154>

f0101105 <page_alloc>:
{
f0101105:	55                   	push   %ebp
f0101106:	89 e5                	mov    %esp,%ebp
f0101108:	56                   	push   %esi
f0101109:	53                   	push   %ebx
f010110a:	e8 8a f0 ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f010110f:	81 c3 11 af 08 00    	add    $0x8af11,%ebx
	if (page_free_list) {
f0101115:	8b b3 1c 23 00 00    	mov    0x231c(%ebx),%esi
f010111b:	85 f6                	test   %esi,%esi
f010111d:	74 1a                	je     f0101139 <page_alloc+0x34>
		page_free_list = page_free_list->pp_link;
f010111f:	8b 06                	mov    (%esi),%eax
f0101121:	89 83 1c 23 00 00    	mov    %eax,0x231c(%ebx)
		res->pp_ref = 0;
f0101127:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)
		res->pp_link = NULL;	// Important
f010112d:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
		if (alloc_flags & ALLOC_ZERO) {
f0101133:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0101137:	75 09                	jne    f0101142 <page_alloc+0x3d>
}
f0101139:	89 f0                	mov    %esi,%eax
f010113b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010113e:	5b                   	pop    %ebx
f010113f:	5e                   	pop    %esi
f0101140:	5d                   	pop    %ebp
f0101141:	c3                   	ret    
	return (pp - pages) << PGSHIFT;
f0101142:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0101148:	89 f2                	mov    %esi,%edx
f010114a:	2b 10                	sub    (%eax),%edx
f010114c:	89 d0                	mov    %edx,%eax
f010114e:	c1 f8 03             	sar    $0x3,%eax
f0101151:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101154:	89 c1                	mov    %eax,%ecx
f0101156:	c1 e9 0c             	shr    $0xc,%ecx
f0101159:	c7 c2 04 f0 18 f0    	mov    $0xf018f004,%edx
f010115f:	3b 0a                	cmp    (%edx),%ecx
f0101161:	73 1a                	jae    f010117d <page_alloc+0x78>
			memset(page2kva(res), '\0', PGSIZE);
f0101163:	83 ec 04             	sub    $0x4,%esp
f0101166:	68 00 10 00 00       	push   $0x1000
f010116b:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f010116d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101172:	50                   	push   %eax
f0101173:	e8 8f 3b 00 00       	call   f0104d07 <memset>
f0101178:	83 c4 10             	add    $0x10,%esp
f010117b:	eb bc                	jmp    f0101139 <page_alloc+0x34>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010117d:	50                   	push   %eax
f010117e:	8d 83 94 99 f7 ff    	lea    -0x8666c(%ebx),%eax
f0101184:	50                   	push   %eax
f0101185:	6a 56                	push   $0x56
f0101187:	8d 83 82 96 f7 ff    	lea    -0x8697e(%ebx),%eax
f010118d:	50                   	push   %eax
f010118e:	e8 50 ef ff ff       	call   f01000e3 <_panic>

f0101193 <page_free>:
{
f0101193:	55                   	push   %ebp
f0101194:	89 e5                	mov    %esp,%ebp
f0101196:	53                   	push   %ebx
f0101197:	83 ec 04             	sub    $0x4,%esp
f010119a:	e8 fa ef ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f010119f:	81 c3 81 ae 08 00    	add    $0x8ae81,%ebx
f01011a5:	8b 45 08             	mov    0x8(%ebp),%eax
	if (pp->pp_ref != 0) {
f01011a8:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f01011ad:	75 18                	jne    f01011c7 <page_free+0x34>
	} else if (pp->pp_link != NULL) {
f01011af:	83 38 00             	cmpl   $0x0,(%eax)
f01011b2:	75 2e                	jne    f01011e2 <page_free+0x4f>
		pp->pp_link = page_free_list;
f01011b4:	8b 8b 1c 23 00 00    	mov    0x231c(%ebx),%ecx
f01011ba:	89 08                	mov    %ecx,(%eax)
		page_free_list = pp;
f01011bc:	89 83 1c 23 00 00    	mov    %eax,0x231c(%ebx)
}
f01011c2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01011c5:	c9                   	leave  
f01011c6:	c3                   	ret    
		panic("Nonzero pp_ref");
f01011c7:	83 ec 04             	sub    $0x4,%esp
f01011ca:	8d 83 2c 97 f7 ff    	lea    -0x868d4(%ebx),%eax
f01011d0:	50                   	push   %eax
f01011d1:	68 83 01 00 00       	push   $0x183
f01011d6:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f01011dc:	50                   	push   %eax
f01011dd:	e8 01 ef ff ff       	call   f01000e3 <_panic>
		panic("pp_link is not NULL");
f01011e2:	83 ec 04             	sub    $0x4,%esp
f01011e5:	8d 83 3b 97 f7 ff    	lea    -0x868c5(%ebx),%eax
f01011eb:	50                   	push   %eax
f01011ec:	68 85 01 00 00       	push   $0x185
f01011f1:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f01011f7:	50                   	push   %eax
f01011f8:	e8 e6 ee ff ff       	call   f01000e3 <_panic>

f01011fd <page_decref>:
{
f01011fd:	55                   	push   %ebp
f01011fe:	89 e5                	mov    %esp,%ebp
f0101200:	83 ec 08             	sub    $0x8,%esp
f0101203:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101206:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f010120a:	83 e8 01             	sub    $0x1,%eax
f010120d:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101211:	66 85 c0             	test   %ax,%ax
f0101214:	74 02                	je     f0101218 <page_decref+0x1b>
}
f0101216:	c9                   	leave  
f0101217:	c3                   	ret    
		page_free(pp);
f0101218:	83 ec 0c             	sub    $0xc,%esp
f010121b:	52                   	push   %edx
f010121c:	e8 72 ff ff ff       	call   f0101193 <page_free>
f0101221:	83 c4 10             	add    $0x10,%esp
}
f0101224:	eb f0                	jmp    f0101216 <page_decref+0x19>

f0101226 <pgdir_walk>:
{
f0101226:	55                   	push   %ebp
f0101227:	89 e5                	mov    %esp,%ebp
f0101229:	57                   	push   %edi
f010122a:	56                   	push   %esi
f010122b:	53                   	push   %ebx
f010122c:	83 ec 1c             	sub    $0x1c,%esp
f010122f:	e8 65 ef ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f0101234:	81 c3 ec ad 08 00    	add    $0x8adec,%ebx
	uintptr_t pg_va = (uintptr_t) ROUNDDOWN(va, PGSIZE);
f010123a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010123d:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	pgtbl_idx = PTX(pg_va);
f0101243:	89 f0                	mov    %esi,%eax
f0101245:	c1 e8 0c             	shr    $0xc,%eax
f0101248:	25 ff 03 00 00       	and    $0x3ff,%eax
f010124d:	89 c7                	mov    %eax,%edi
	pgdir_idx = PDX(pg_va);
f010124f:	c1 ee 16             	shr    $0x16,%esi
	if (pgdir[pgdir_idx] & PTE_P) {	// The page table is present
f0101252:	c1 e6 02             	shl    $0x2,%esi
f0101255:	03 75 08             	add    0x8(%ebp),%esi
f0101258:	8b 06                	mov    (%esi),%eax
f010125a:	a8 01                	test   $0x1,%al
f010125c:	74 3d                	je     f010129b <pgdir_walk+0x75>
		pgtable = KADDR(PTE_ADDR(pgdir[pgdir_idx]));
f010125e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101263:	89 c2                	mov    %eax,%edx
f0101265:	c1 ea 0c             	shr    $0xc,%edx
f0101268:	c7 c1 04 f0 18 f0    	mov    $0xf018f004,%ecx
f010126e:	39 11                	cmp    %edx,(%ecx)
f0101270:	76 10                	jbe    f0101282 <pgdir_walk+0x5c>
	return (void *)(pa + KERNBASE);
f0101272:	2d 00 00 00 10       	sub    $0x10000000,%eax
	return &(pgtable[pgtbl_idx]);
f0101277:	8d 04 b8             	lea    (%eax,%edi,4),%eax
}
f010127a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010127d:	5b                   	pop    %ebx
f010127e:	5e                   	pop    %esi
f010127f:	5f                   	pop    %edi
f0101280:	5d                   	pop    %ebp
f0101281:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101282:	50                   	push   %eax
f0101283:	8d 83 94 99 f7 ff    	lea    -0x8666c(%ebx),%eax
f0101289:	50                   	push   %eax
f010128a:	68 c9 01 00 00       	push   $0x1c9
f010128f:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0101295:	50                   	push   %eax
f0101296:	e8 48 ee ff ff       	call   f01000e3 <_panic>
		if (!create || (pginfo_ptr = page_alloc(1)) == NULL) {
f010129b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010129f:	74 76                	je     f0101317 <pgdir_walk+0xf1>
f01012a1:	83 ec 0c             	sub    $0xc,%esp
f01012a4:	6a 01                	push   $0x1
f01012a6:	e8 5a fe ff ff       	call   f0101105 <page_alloc>
f01012ab:	83 c4 10             	add    $0x10,%esp
f01012ae:	85 c0                	test   %eax,%eax
f01012b0:	74 6f                	je     f0101321 <pgdir_walk+0xfb>
		pginfo_ptr->pp_ref = 1;
f01012b2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01012b5:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
		memset(pgdir + pgdir_idx, 0, sizeof(pde_t));
f01012bb:	83 ec 04             	sub    $0x4,%esp
f01012be:	6a 04                	push   $0x4
f01012c0:	6a 00                	push   $0x0
f01012c2:	56                   	push   %esi
f01012c3:	e8 3f 3a 00 00       	call   f0104d07 <memset>
	return (pp - pages) << PGSHIFT;
f01012c8:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f01012ce:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01012d1:	2b 08                	sub    (%eax),%ecx
f01012d3:	89 c8                	mov    %ecx,%eax
f01012d5:	c1 f8 03             	sar    $0x3,%eax
f01012d8:	c1 e0 0c             	shl    $0xc,%eax
		pgdir[pgdir_idx] = pgtable_phyaddr | PTE_P | PTE_W | PTE_U;	
f01012db:	89 c2                	mov    %eax,%edx
f01012dd:	83 ca 07             	or     $0x7,%edx
f01012e0:	89 16                	mov    %edx,(%esi)
	if (PGNUM(pa) >= npages)
f01012e2:	89 c1                	mov    %eax,%ecx
f01012e4:	c1 e9 0c             	shr    $0xc,%ecx
f01012e7:	83 c4 10             	add    $0x10,%esp
f01012ea:	c7 c2 04 f0 18 f0    	mov    $0xf018f004,%edx
f01012f0:	3b 0a                	cmp    (%edx),%ecx
f01012f2:	73 0a                	jae    f01012fe <pgdir_walk+0xd8>
	return (void *)(pa + KERNBASE);
f01012f4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01012f9:	e9 79 ff ff ff       	jmp    f0101277 <pgdir_walk+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01012fe:	50                   	push   %eax
f01012ff:	8d 83 94 99 f7 ff    	lea    -0x8666c(%ebx),%eax
f0101305:	50                   	push   %eax
f0101306:	68 db 01 00 00       	push   $0x1db
f010130b:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0101311:	50                   	push   %eax
f0101312:	e8 cc ed ff ff       	call   f01000e3 <_panic>
			return NULL;
f0101317:	b8 00 00 00 00       	mov    $0x0,%eax
f010131c:	e9 59 ff ff ff       	jmp    f010127a <pgdir_walk+0x54>
f0101321:	b8 00 00 00 00       	mov    $0x0,%eax
f0101326:	e9 4f ff ff ff       	jmp    f010127a <pgdir_walk+0x54>

f010132b <boot_map_region>:
{
f010132b:	55                   	push   %ebp
f010132c:	89 e5                	mov    %esp,%ebp
f010132e:	57                   	push   %edi
f010132f:	56                   	push   %esi
f0101330:	53                   	push   %ebx
f0101331:	83 ec 1c             	sub    $0x1c,%esp
f0101334:	e8 51 20 00 00       	call   f010338a <__x86.get_pc_thunk.di>
f0101339:	81 c7 e7 ac 08 00    	add    $0x8ace7,%edi
f010133f:	89 7d d8             	mov    %edi,-0x28(%ebp)
f0101342:	89 45 e0             	mov    %eax,-0x20(%ebp)
	end = va + size;
f0101345:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
f0101348:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	vir_p = va;
f010134b:	89 d3                	mov    %edx,%ebx
f010134d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101350:	29 d7                	sub    %edx,%edi
		*pte_p = phy_p | perm | PTE_P;
f0101352:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101355:	83 c8 01             	or     $0x1,%eax
f0101358:	89 45 dc             	mov    %eax,-0x24(%ebp)
f010135b:	8d 34 1f             	lea    (%edi,%ebx,1),%esi
		if (vir_p == end) {
f010135e:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0101361:	74 63                	je     f01013c6 <boot_map_region+0x9b>
		if ((pte_p = pgdir_walk(pgdir, (void *)vir_p, 1)) == NULL) {
f0101363:	83 ec 04             	sub    $0x4,%esp
f0101366:	6a 01                	push   $0x1
f0101368:	53                   	push   %ebx
f0101369:	ff 75 e0             	pushl  -0x20(%ebp)
f010136c:	e8 b5 fe ff ff       	call   f0101226 <pgdir_walk>
f0101371:	83 c4 10             	add    $0x10,%esp
f0101374:	85 c0                	test   %eax,%eax
f0101376:	74 12                	je     f010138a <boot_map_region+0x5f>
		if (*pte_p & PTE_P) {	// PTE already exist
f0101378:	f6 00 01             	testb  $0x1,(%eax)
f010137b:	75 2b                	jne    f01013a8 <boot_map_region+0x7d>
		*pte_p = phy_p | perm | PTE_P;
f010137d:	0b 75 dc             	or     -0x24(%ebp),%esi
f0101380:	89 30                	mov    %esi,(%eax)
		vir_p += PGSIZE;
f0101382:	81 c3 00 10 00 00    	add    $0x1000,%ebx
		if (vir_p == end) {
f0101388:	eb d1                	jmp    f010135b <boot_map_region+0x30>
			panic("pgdir_walk error");
f010138a:	83 ec 04             	sub    $0x4,%esp
f010138d:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0101390:	8d 83 4f 97 f7 ff    	lea    -0x868b1(%ebx),%eax
f0101396:	50                   	push   %eax
f0101397:	68 fd 01 00 00       	push   $0x1fd
f010139c:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f01013a2:	50                   	push   %eax
f01013a3:	e8 3b ed ff ff       	call   f01000e3 <_panic>
			panic("remap");
f01013a8:	83 ec 04             	sub    $0x4,%esp
f01013ab:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01013ae:	8d 83 60 97 f7 ff    	lea    -0x868a0(%ebx),%eax
f01013b4:	50                   	push   %eax
f01013b5:	68 02 02 00 00       	push   $0x202
f01013ba:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f01013c0:	50                   	push   %eax
f01013c1:	e8 1d ed ff ff       	call   f01000e3 <_panic>
}
f01013c6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01013c9:	5b                   	pop    %ebx
f01013ca:	5e                   	pop    %esi
f01013cb:	5f                   	pop    %edi
f01013cc:	5d                   	pop    %ebp
f01013cd:	c3                   	ret    

f01013ce <page_lookup>:
{
f01013ce:	55                   	push   %ebp
f01013cf:	89 e5                	mov    %esp,%ebp
f01013d1:	56                   	push   %esi
f01013d2:	53                   	push   %ebx
f01013d3:	e8 c1 ed ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f01013d8:	81 c3 48 ac 08 00    	add    $0x8ac48,%ebx
f01013de:	8b 75 10             	mov    0x10(%ebp),%esi
	pte_t *ret = pgdir_walk(pgdir, va, 0);
f01013e1:	83 ec 04             	sub    $0x4,%esp
f01013e4:	6a 00                	push   $0x0
f01013e6:	ff 75 0c             	pushl  0xc(%ebp)
f01013e9:	ff 75 08             	pushl  0x8(%ebp)
f01013ec:	e8 35 fe ff ff       	call   f0101226 <pgdir_walk>
	if (pte_store != 0) {
f01013f1:	83 c4 10             	add    $0x10,%esp
f01013f4:	85 f6                	test   %esi,%esi
f01013f6:	74 02                	je     f01013fa <page_lookup+0x2c>
		*pte_store = ret;
f01013f8:	89 06                	mov    %eax,(%esi)
	if (ret && (*ret & PTE_P)) {
f01013fa:	85 c0                	test   %eax,%eax
f01013fc:	74 3d                	je     f010143b <page_lookup+0x6d>
f01013fe:	8b 00                	mov    (%eax),%eax
f0101400:	a8 01                	test   $0x1,%al
f0101402:	74 3e                	je     f0101442 <page_lookup+0x74>
f0101404:	c1 e8 0c             	shr    $0xc,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101407:	c7 c2 04 f0 18 f0    	mov    $0xf018f004,%edx
f010140d:	39 02                	cmp    %eax,(%edx)
f010140f:	76 12                	jbe    f0101423 <page_lookup+0x55>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f0101411:	c7 c2 0c f0 18 f0    	mov    $0xf018f00c,%edx
f0101417:	8b 12                	mov    (%edx),%edx
f0101419:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f010141c:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010141f:	5b                   	pop    %ebx
f0101420:	5e                   	pop    %esi
f0101421:	5d                   	pop    %ebp
f0101422:	c3                   	ret    
		panic("pa2page called with invalid pa");
f0101423:	83 ec 04             	sub    $0x4,%esp
f0101426:	8d 83 c4 9a f7 ff    	lea    -0x8653c(%ebx),%eax
f010142c:	50                   	push   %eax
f010142d:	6a 4f                	push   $0x4f
f010142f:	8d 83 82 96 f7 ff    	lea    -0x8697e(%ebx),%eax
f0101435:	50                   	push   %eax
f0101436:	e8 a8 ec ff ff       	call   f01000e3 <_panic>
		return NULL;
f010143b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101440:	eb da                	jmp    f010141c <page_lookup+0x4e>
f0101442:	b8 00 00 00 00       	mov    $0x0,%eax
f0101447:	eb d3                	jmp    f010141c <page_lookup+0x4e>

f0101449 <page_remove>:
{
f0101449:	55                   	push   %ebp
f010144a:	89 e5                	mov    %esp,%ebp
f010144c:	56                   	push   %esi
f010144d:	53                   	push   %ebx
f010144e:	83 ec 14             	sub    $0x14,%esp
f0101451:	e8 43 ed ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f0101456:	81 c3 ca ab 08 00    	add    $0x8abca,%ebx
f010145c:	8b 75 0c             	mov    0xc(%ebp),%esi
	struct PageInfo *pginfo_p = page_lookup(pgdir, va, &pte_p);
f010145f:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101462:	50                   	push   %eax
f0101463:	56                   	push   %esi
f0101464:	ff 75 08             	pushl  0x8(%ebp)
f0101467:	e8 62 ff ff ff       	call   f01013ce <page_lookup>
	if (pginfo_p) { // The virtual address is mapped
f010146c:	83 c4 10             	add    $0x10,%esp
f010146f:	85 c0                	test   %eax,%eax
f0101471:	74 26                	je     f0101499 <page_remove+0x50>
		page_decref(pginfo_p);
f0101473:	83 ec 0c             	sub    $0xc,%esp
f0101476:	50                   	push   %eax
f0101477:	e8 81 fd ff ff       	call   f01011fd <page_decref>
		if (pte_p) {
f010147c:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010147f:	83 c4 10             	add    $0x10,%esp
f0101482:	85 c0                	test   %eax,%eax
f0101484:	74 13                	je     f0101499 <page_remove+0x50>
			memset(pte_p, 0, sizeof(pte_t));
f0101486:	83 ec 04             	sub    $0x4,%esp
f0101489:	6a 04                	push   $0x4
f010148b:	6a 00                	push   $0x0
f010148d:	50                   	push   %eax
f010148e:	e8 74 38 00 00       	call   f0104d07 <memset>
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101493:	0f 01 3e             	invlpg (%esi)
f0101496:	83 c4 10             	add    $0x10,%esp
}
f0101499:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010149c:	5b                   	pop    %ebx
f010149d:	5e                   	pop    %esi
f010149e:	5d                   	pop    %ebp
f010149f:	c3                   	ret    

f01014a0 <page_insert>:
{
f01014a0:	55                   	push   %ebp
f01014a1:	89 e5                	mov    %esp,%ebp
f01014a3:	57                   	push   %edi
f01014a4:	56                   	push   %esi
f01014a5:	53                   	push   %ebx
f01014a6:	83 ec 10             	sub    $0x10,%esp
f01014a9:	e8 dc 1e 00 00       	call   f010338a <__x86.get_pc_thunk.di>
f01014ae:	81 c7 72 ab 08 00    	add    $0x8ab72,%edi
f01014b4:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t *pte_p = pgdir_walk(pgdir, va, 0); // NULL only if page table doesn't exist
f01014b7:	6a 00                	push   $0x0
f01014b9:	ff 75 10             	pushl  0x10(%ebp)
f01014bc:	ff 75 08             	pushl  0x8(%ebp)
f01014bf:	e8 62 fd ff ff       	call   f0101226 <pgdir_walk>
	if (pte_p) {
f01014c4:	83 c4 10             	add    $0x10,%esp
f01014c7:	85 c0                	test   %eax,%eax
f01014c9:	74 79                	je     f0101544 <page_insert+0xa4>
f01014cb:	89 c3                	mov    %eax,%ebx
		if (*pte_p & PTE_P) {
f01014cd:	8b 00                	mov    (%eax),%eax
f01014cf:	a8 01                	test   $0x1,%al
f01014d1:	74 2c                	je     f01014ff <page_insert+0x5f>
			if (PTE_ADDR(*pte_p) == page2pa(pp)) {	
f01014d3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	return (pp - pages) << PGSHIFT;
f01014d8:	c7 c2 0c f0 18 f0    	mov    $0xf018f00c,%edx
f01014de:	89 f1                	mov    %esi,%ecx
f01014e0:	2b 0a                	sub    (%edx),%ecx
f01014e2:	89 ca                	mov    %ecx,%edx
f01014e4:	c1 fa 03             	sar    $0x3,%edx
f01014e7:	c1 e2 0c             	shl    $0xc,%edx
f01014ea:	39 d0                	cmp    %edx,%eax
f01014ec:	74 45                	je     f0101533 <page_insert+0x93>
				page_remove(pgdir, va);
f01014ee:	83 ec 08             	sub    $0x8,%esp
f01014f1:	ff 75 10             	pushl  0x10(%ebp)
f01014f4:	ff 75 08             	pushl  0x8(%ebp)
f01014f7:	e8 4d ff ff ff       	call   f0101449 <page_remove>
f01014fc:	83 c4 10             	add    $0x10,%esp
f01014ff:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0101505:	89 f1                	mov    %esi,%ecx
f0101507:	2b 08                	sub    (%eax),%ecx
f0101509:	89 c8                	mov    %ecx,%eax
f010150b:	c1 f8 03             	sar    $0x3,%eax
f010150e:	c1 e0 0c             	shl    $0xc,%eax
	*pte_p = page2pa(pp) | perm | PTE_P;
f0101511:	8b 55 14             	mov    0x14(%ebp),%edx
f0101514:	83 ca 01             	or     $0x1,%edx
f0101517:	09 d0                	or     %edx,%eax
f0101519:	89 03                	mov    %eax,(%ebx)
	++(pp->pp_ref);
f010151b:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
f0101520:	8b 45 10             	mov    0x10(%ebp),%eax
f0101523:	0f 01 38             	invlpg (%eax)
	return 0;
f0101526:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010152b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010152e:	5b                   	pop    %ebx
f010152f:	5e                   	pop    %esi
f0101530:	5f                   	pop    %edi
f0101531:	5d                   	pop    %ebp
f0101532:	c3                   	ret    
				*pte_p = page2pa(pp) | perm | PTE_P;
f0101533:	8b 55 14             	mov    0x14(%ebp),%edx
f0101536:	83 ca 01             	or     $0x1,%edx
f0101539:	09 d0                	or     %edx,%eax
f010153b:	89 03                	mov    %eax,(%ebx)
				return 0;
f010153d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101542:	eb e7                	jmp    f010152b <page_insert+0x8b>
		if ((pte_p = pgdir_walk(pgdir, va, 1)) == NULL) { // Try create page table
f0101544:	83 ec 04             	sub    $0x4,%esp
f0101547:	6a 01                	push   $0x1
f0101549:	ff 75 10             	pushl  0x10(%ebp)
f010154c:	ff 75 08             	pushl  0x8(%ebp)
f010154f:	e8 d2 fc ff ff       	call   f0101226 <pgdir_walk>
f0101554:	89 c3                	mov    %eax,%ebx
f0101556:	83 c4 10             	add    $0x10,%esp
f0101559:	85 c0                	test   %eax,%eax
f010155b:	75 a2                	jne    f01014ff <page_insert+0x5f>
			return -E_NO_MEM;
f010155d:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0101562:	eb c7                	jmp    f010152b <page_insert+0x8b>

f0101564 <mem_init>:
{
f0101564:	55                   	push   %ebp
f0101565:	89 e5                	mov    %esp,%ebp
f0101567:	57                   	push   %edi
f0101568:	56                   	push   %esi
f0101569:	53                   	push   %ebx
f010156a:	83 ec 3c             	sub    $0x3c,%esp
f010156d:	e8 c9 f1 ff ff       	call   f010073b <__x86.get_pc_thunk.ax>
f0101572:	05 ae aa 08 00       	add    $0x8aaae,%eax
f0101577:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	basemem = nvram_read(NVRAM_BASELO);
f010157a:	b8 15 00 00 00       	mov    $0x15,%eax
f010157f:	e8 70 f5 ff ff       	call   f0100af4 <nvram_read>
f0101584:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0101586:	b8 17 00 00 00       	mov    $0x17,%eax
f010158b:	e8 64 f5 ff ff       	call   f0100af4 <nvram_read>
f0101590:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101592:	b8 34 00 00 00       	mov    $0x34,%eax
f0101597:	e8 58 f5 ff ff       	call   f0100af4 <nvram_read>
f010159c:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f010159f:	85 c0                	test   %eax,%eax
f01015a1:	0f 85 f3 00 00 00    	jne    f010169a <mem_init+0x136>
		totalmem = 1 * 1024 + extmem;
f01015a7:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01015ad:	85 f6                	test   %esi,%esi
f01015af:	0f 44 c3             	cmove  %ebx,%eax
	npages = totalmem / (PGSIZE / 1024);	// npages = 32768
f01015b2:	89 c1                	mov    %eax,%ecx
f01015b4:	c1 e9 02             	shr    $0x2,%ecx
f01015b7:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01015ba:	c7 c2 04 f0 18 f0    	mov    $0xf018f004,%edx
f01015c0:	89 0a                	mov    %ecx,(%edx)
	npages_basemem = basemem / (PGSIZE / 1024);
f01015c2:	89 da                	mov    %ebx,%edx
f01015c4:	c1 ea 02             	shr    $0x2,%edx
f01015c7:	89 97 20 23 00 00    	mov    %edx,0x2320(%edi)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01015cd:	89 c2                	mov    %eax,%edx
f01015cf:	29 da                	sub    %ebx,%edx
f01015d1:	52                   	push   %edx
f01015d2:	53                   	push   %ebx
f01015d3:	50                   	push   %eax
f01015d4:	8d 87 e4 9a f7 ff    	lea    -0x8651c(%edi),%eax
f01015da:	50                   	push   %eax
f01015db:	89 fb                	mov    %edi,%ebx
f01015dd:	e8 76 26 00 00       	call   f0103c58 <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01015e2:	b8 00 10 00 00       	mov    $0x1000,%eax
f01015e7:	e8 3e f5 ff ff       	call   f0100b2a <boot_alloc>
f01015ec:	c7 c6 08 f0 18 f0    	mov    $0xf018f008,%esi
f01015f2:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);
f01015f4:	83 c4 0c             	add    $0xc,%esp
f01015f7:	68 00 10 00 00       	push   $0x1000
f01015fc:	6a 00                	push   $0x0
f01015fe:	50                   	push   %eax
f01015ff:	e8 03 37 00 00       	call   f0104d07 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101604:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f0101606:	83 c4 10             	add    $0x10,%esp
f0101609:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010160e:	0f 86 90 00 00 00    	jbe    f01016a4 <mem_init+0x140>
	return (physaddr_t)kva - KERNBASE;
f0101614:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010161a:	83 ca 05             	or     $0x5,%edx
f010161d:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = boot_alloc(npages * sizeof(struct PageInfo));
f0101623:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101626:	c7 c3 04 f0 18 f0    	mov    $0xf018f004,%ebx
f010162c:	8b 03                	mov    (%ebx),%eax
f010162e:	c1 e0 03             	shl    $0x3,%eax
f0101631:	e8 f4 f4 ff ff       	call   f0100b2a <boot_alloc>
f0101636:	c7 c6 0c f0 18 f0    	mov    $0xf018f00c,%esi
f010163c:	89 06                	mov    %eax,(%esi)
	memset(pages, 0, npages * sizeof(struct PageInfo));
f010163e:	83 ec 04             	sub    $0x4,%esp
f0101641:	8b 13                	mov    (%ebx),%edx
f0101643:	c1 e2 03             	shl    $0x3,%edx
f0101646:	52                   	push   %edx
f0101647:	6a 00                	push   $0x0
f0101649:	50                   	push   %eax
f010164a:	89 fb                	mov    %edi,%ebx
f010164c:	e8 b6 36 00 00       	call   f0104d07 <memset>
	envs = boot_alloc(NENV * sizeof(struct Env));
f0101651:	b8 00 80 01 00       	mov    $0x18000,%eax
f0101656:	e8 cf f4 ff ff       	call   f0100b2a <boot_alloc>
f010165b:	c7 c2 48 e3 18 f0    	mov    $0xf018e348,%edx
f0101661:	89 02                	mov    %eax,(%edx)
	memset(envs, 0, NENV * sizeof(struct Env));
f0101663:	83 c4 0c             	add    $0xc,%esp
f0101666:	68 00 80 01 00       	push   $0x18000
f010166b:	6a 00                	push   $0x0
f010166d:	50                   	push   %eax
f010166e:	e8 94 36 00 00       	call   f0104d07 <memset>
	page_init();
f0101673:	e8 26 f9 ff ff       	call   f0100f9e <page_init>
	check_page_free_list(1);
f0101678:	b8 01 00 00 00       	mov    $0x1,%eax
f010167d:	e8 99 f5 ff ff       	call   f0100c1b <check_page_free_list>
	if (!pages)
f0101682:	83 c4 10             	add    $0x10,%esp
f0101685:	83 3e 00             	cmpl   $0x0,(%esi)
f0101688:	74 36                	je     f01016c0 <mem_init+0x15c>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010168a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010168d:	8b 80 1c 23 00 00    	mov    0x231c(%eax),%eax
f0101693:	be 00 00 00 00       	mov    $0x0,%esi
f0101698:	eb 49                	jmp    f01016e3 <mem_init+0x17f>
		totalmem = 16 * 1024 + ext16mem;
f010169a:	05 00 40 00 00       	add    $0x4000,%eax
f010169f:	e9 0e ff ff ff       	jmp    f01015b2 <mem_init+0x4e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01016a4:	50                   	push   %eax
f01016a5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01016a8:	8d 83 a0 9a f7 ff    	lea    -0x86560(%ebx),%eax
f01016ae:	50                   	push   %eax
f01016af:	68 99 00 00 00       	push   $0x99
f01016b4:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f01016ba:	50                   	push   %eax
f01016bb:	e8 23 ea ff ff       	call   f01000e3 <_panic>
		panic("'pages' is a null pointer!");
f01016c0:	83 ec 04             	sub    $0x4,%esp
f01016c3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01016c6:	8d 83 66 97 f7 ff    	lea    -0x8689a(%ebx),%eax
f01016cc:	50                   	push   %eax
f01016cd:	68 02 03 00 00       	push   $0x302
f01016d2:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f01016d8:	50                   	push   %eax
f01016d9:	e8 05 ea ff ff       	call   f01000e3 <_panic>
		++nfree;
f01016de:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01016e1:	8b 00                	mov    (%eax),%eax
f01016e3:	85 c0                	test   %eax,%eax
f01016e5:	75 f7                	jne    f01016de <mem_init+0x17a>
	assert((pp0 = page_alloc(0)));
f01016e7:	83 ec 0c             	sub    $0xc,%esp
f01016ea:	6a 00                	push   $0x0
f01016ec:	e8 14 fa ff ff       	call   f0101105 <page_alloc>
f01016f1:	89 c3                	mov    %eax,%ebx
f01016f3:	83 c4 10             	add    $0x10,%esp
f01016f6:	85 c0                	test   %eax,%eax
f01016f8:	0f 84 3b 02 00 00    	je     f0101939 <mem_init+0x3d5>
	assert((pp1 = page_alloc(0)));
f01016fe:	83 ec 0c             	sub    $0xc,%esp
f0101701:	6a 00                	push   $0x0
f0101703:	e8 fd f9 ff ff       	call   f0101105 <page_alloc>
f0101708:	89 c7                	mov    %eax,%edi
f010170a:	83 c4 10             	add    $0x10,%esp
f010170d:	85 c0                	test   %eax,%eax
f010170f:	0f 84 46 02 00 00    	je     f010195b <mem_init+0x3f7>
	assert((pp2 = page_alloc(0)));
f0101715:	83 ec 0c             	sub    $0xc,%esp
f0101718:	6a 00                	push   $0x0
f010171a:	e8 e6 f9 ff ff       	call   f0101105 <page_alloc>
f010171f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101722:	83 c4 10             	add    $0x10,%esp
f0101725:	85 c0                	test   %eax,%eax
f0101727:	0f 84 50 02 00 00    	je     f010197d <mem_init+0x419>
	assert(pp1 && pp1 != pp0);
f010172d:	39 fb                	cmp    %edi,%ebx
f010172f:	0f 84 6a 02 00 00    	je     f010199f <mem_init+0x43b>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101735:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101738:	39 c7                	cmp    %eax,%edi
f010173a:	0f 84 81 02 00 00    	je     f01019c1 <mem_init+0x45d>
f0101740:	39 c3                	cmp    %eax,%ebx
f0101742:	0f 84 79 02 00 00    	je     f01019c1 <mem_init+0x45d>
	return (pp - pages) << PGSHIFT;
f0101748:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010174b:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0101751:	8b 08                	mov    (%eax),%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101753:	c7 c0 04 f0 18 f0    	mov    $0xf018f004,%eax
f0101759:	8b 10                	mov    (%eax),%edx
f010175b:	c1 e2 0c             	shl    $0xc,%edx
f010175e:	89 d8                	mov    %ebx,%eax
f0101760:	29 c8                	sub    %ecx,%eax
f0101762:	c1 f8 03             	sar    $0x3,%eax
f0101765:	c1 e0 0c             	shl    $0xc,%eax
f0101768:	39 d0                	cmp    %edx,%eax
f010176a:	0f 83 73 02 00 00    	jae    f01019e3 <mem_init+0x47f>
f0101770:	89 f8                	mov    %edi,%eax
f0101772:	29 c8                	sub    %ecx,%eax
f0101774:	c1 f8 03             	sar    $0x3,%eax
f0101777:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f010177a:	39 c2                	cmp    %eax,%edx
f010177c:	0f 86 83 02 00 00    	jbe    f0101a05 <mem_init+0x4a1>
f0101782:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101785:	29 c8                	sub    %ecx,%eax
f0101787:	c1 f8 03             	sar    $0x3,%eax
f010178a:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f010178d:	39 c2                	cmp    %eax,%edx
f010178f:	0f 86 92 02 00 00    	jbe    f0101a27 <mem_init+0x4c3>
	fl = page_free_list;
f0101795:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101798:	8b 88 1c 23 00 00    	mov    0x231c(%eax),%ecx
f010179e:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f01017a1:	c7 80 1c 23 00 00 00 	movl   $0x0,0x231c(%eax)
f01017a8:	00 00 00 
	assert(!page_alloc(0));
f01017ab:	83 ec 0c             	sub    $0xc,%esp
f01017ae:	6a 00                	push   $0x0
f01017b0:	e8 50 f9 ff ff       	call   f0101105 <page_alloc>
f01017b5:	83 c4 10             	add    $0x10,%esp
f01017b8:	85 c0                	test   %eax,%eax
f01017ba:	0f 85 89 02 00 00    	jne    f0101a49 <mem_init+0x4e5>
	page_free(pp0);
f01017c0:	83 ec 0c             	sub    $0xc,%esp
f01017c3:	53                   	push   %ebx
f01017c4:	e8 ca f9 ff ff       	call   f0101193 <page_free>
	page_free(pp1);
f01017c9:	89 3c 24             	mov    %edi,(%esp)
f01017cc:	e8 c2 f9 ff ff       	call   f0101193 <page_free>
	page_free(pp2);
f01017d1:	83 c4 04             	add    $0x4,%esp
f01017d4:	ff 75 d0             	pushl  -0x30(%ebp)
f01017d7:	e8 b7 f9 ff ff       	call   f0101193 <page_free>
	assert((pp0 = page_alloc(0)));
f01017dc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017e3:	e8 1d f9 ff ff       	call   f0101105 <page_alloc>
f01017e8:	89 c7                	mov    %eax,%edi
f01017ea:	83 c4 10             	add    $0x10,%esp
f01017ed:	85 c0                	test   %eax,%eax
f01017ef:	0f 84 76 02 00 00    	je     f0101a6b <mem_init+0x507>
	assert((pp1 = page_alloc(0)));
f01017f5:	83 ec 0c             	sub    $0xc,%esp
f01017f8:	6a 00                	push   $0x0
f01017fa:	e8 06 f9 ff ff       	call   f0101105 <page_alloc>
f01017ff:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101802:	83 c4 10             	add    $0x10,%esp
f0101805:	85 c0                	test   %eax,%eax
f0101807:	0f 84 80 02 00 00    	je     f0101a8d <mem_init+0x529>
	assert((pp2 = page_alloc(0)));
f010180d:	83 ec 0c             	sub    $0xc,%esp
f0101810:	6a 00                	push   $0x0
f0101812:	e8 ee f8 ff ff       	call   f0101105 <page_alloc>
f0101817:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010181a:	83 c4 10             	add    $0x10,%esp
f010181d:	85 c0                	test   %eax,%eax
f010181f:	0f 84 8a 02 00 00    	je     f0101aaf <mem_init+0x54b>
	assert(pp1 && pp1 != pp0);
f0101825:	3b 7d d0             	cmp    -0x30(%ebp),%edi
f0101828:	0f 84 a3 02 00 00    	je     f0101ad1 <mem_init+0x56d>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010182e:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101831:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101834:	0f 84 b9 02 00 00    	je     f0101af3 <mem_init+0x58f>
f010183a:	39 c7                	cmp    %eax,%edi
f010183c:	0f 84 b1 02 00 00    	je     f0101af3 <mem_init+0x58f>
	assert(!page_alloc(0));
f0101842:	83 ec 0c             	sub    $0xc,%esp
f0101845:	6a 00                	push   $0x0
f0101847:	e8 b9 f8 ff ff       	call   f0101105 <page_alloc>
f010184c:	83 c4 10             	add    $0x10,%esp
f010184f:	85 c0                	test   %eax,%eax
f0101851:	0f 85 be 02 00 00    	jne    f0101b15 <mem_init+0x5b1>
f0101857:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010185a:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0101860:	89 f9                	mov    %edi,%ecx
f0101862:	2b 08                	sub    (%eax),%ecx
f0101864:	89 c8                	mov    %ecx,%eax
f0101866:	c1 f8 03             	sar    $0x3,%eax
f0101869:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f010186c:	89 c1                	mov    %eax,%ecx
f010186e:	c1 e9 0c             	shr    $0xc,%ecx
f0101871:	c7 c2 04 f0 18 f0    	mov    $0xf018f004,%edx
f0101877:	3b 0a                	cmp    (%edx),%ecx
f0101879:	0f 83 b8 02 00 00    	jae    f0101b37 <mem_init+0x5d3>
	memset(page2kva(pp0), 1, PGSIZE);
f010187f:	83 ec 04             	sub    $0x4,%esp
f0101882:	68 00 10 00 00       	push   $0x1000
f0101887:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0101889:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010188e:	50                   	push   %eax
f010188f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101892:	e8 70 34 00 00       	call   f0104d07 <memset>
	page_free(pp0);
f0101897:	89 3c 24             	mov    %edi,(%esp)
f010189a:	e8 f4 f8 ff ff       	call   f0101193 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010189f:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01018a6:	e8 5a f8 ff ff       	call   f0101105 <page_alloc>
f01018ab:	83 c4 10             	add    $0x10,%esp
f01018ae:	85 c0                	test   %eax,%eax
f01018b0:	0f 84 97 02 00 00    	je     f0101b4d <mem_init+0x5e9>
	assert(pp && pp0 == pp);
f01018b6:	39 c7                	cmp    %eax,%edi
f01018b8:	0f 85 b1 02 00 00    	jne    f0101b6f <mem_init+0x60b>
	return (pp - pages) << PGSHIFT;
f01018be:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018c1:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f01018c7:	89 fa                	mov    %edi,%edx
f01018c9:	2b 10                	sub    (%eax),%edx
f01018cb:	c1 fa 03             	sar    $0x3,%edx
f01018ce:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01018d1:	89 d1                	mov    %edx,%ecx
f01018d3:	c1 e9 0c             	shr    $0xc,%ecx
f01018d6:	c7 c0 04 f0 18 f0    	mov    $0xf018f004,%eax
f01018dc:	3b 08                	cmp    (%eax),%ecx
f01018de:	0f 83 ad 02 00 00    	jae    f0101b91 <mem_init+0x62d>
	return (void *)(pa + KERNBASE);
f01018e4:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f01018ea:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f01018f0:	80 38 00             	cmpb   $0x0,(%eax)
f01018f3:	0f 85 ae 02 00 00    	jne    f0101ba7 <mem_init+0x643>
f01018f9:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f01018fc:	39 d0                	cmp    %edx,%eax
f01018fe:	75 f0                	jne    f01018f0 <mem_init+0x38c>
	page_free_list = fl;
f0101900:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101903:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0101906:	89 8b 1c 23 00 00    	mov    %ecx,0x231c(%ebx)
	page_free(pp0);
f010190c:	83 ec 0c             	sub    $0xc,%esp
f010190f:	57                   	push   %edi
f0101910:	e8 7e f8 ff ff       	call   f0101193 <page_free>
	page_free(pp1);
f0101915:	83 c4 04             	add    $0x4,%esp
f0101918:	ff 75 d0             	pushl  -0x30(%ebp)
f010191b:	e8 73 f8 ff ff       	call   f0101193 <page_free>
	page_free(pp2);
f0101920:	83 c4 04             	add    $0x4,%esp
f0101923:	ff 75 cc             	pushl  -0x34(%ebp)
f0101926:	e8 68 f8 ff ff       	call   f0101193 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010192b:	8b 83 1c 23 00 00    	mov    0x231c(%ebx),%eax
f0101931:	83 c4 10             	add    $0x10,%esp
f0101934:	e9 95 02 00 00       	jmp    f0101bce <mem_init+0x66a>
	assert((pp0 = page_alloc(0)));
f0101939:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010193c:	8d 83 81 97 f7 ff    	lea    -0x8687f(%ebx),%eax
f0101942:	50                   	push   %eax
f0101943:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0101949:	50                   	push   %eax
f010194a:	68 0a 03 00 00       	push   $0x30a
f010194f:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0101955:	50                   	push   %eax
f0101956:	e8 88 e7 ff ff       	call   f01000e3 <_panic>
	assert((pp1 = page_alloc(0)));
f010195b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010195e:	8d 83 97 97 f7 ff    	lea    -0x86869(%ebx),%eax
f0101964:	50                   	push   %eax
f0101965:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f010196b:	50                   	push   %eax
f010196c:	68 0b 03 00 00       	push   $0x30b
f0101971:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0101977:	50                   	push   %eax
f0101978:	e8 66 e7 ff ff       	call   f01000e3 <_panic>
	assert((pp2 = page_alloc(0)));
f010197d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101980:	8d 83 ad 97 f7 ff    	lea    -0x86853(%ebx),%eax
f0101986:	50                   	push   %eax
f0101987:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f010198d:	50                   	push   %eax
f010198e:	68 0c 03 00 00       	push   $0x30c
f0101993:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0101999:	50                   	push   %eax
f010199a:	e8 44 e7 ff ff       	call   f01000e3 <_panic>
	assert(pp1 && pp1 != pp0);
f010199f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01019a2:	8d 83 c3 97 f7 ff    	lea    -0x8683d(%ebx),%eax
f01019a8:	50                   	push   %eax
f01019a9:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f01019af:	50                   	push   %eax
f01019b0:	68 0f 03 00 00       	push   $0x30f
f01019b5:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f01019bb:	50                   	push   %eax
f01019bc:	e8 22 e7 ff ff       	call   f01000e3 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01019c1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01019c4:	8d 83 20 9b f7 ff    	lea    -0x864e0(%ebx),%eax
f01019ca:	50                   	push   %eax
f01019cb:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f01019d1:	50                   	push   %eax
f01019d2:	68 10 03 00 00       	push   $0x310
f01019d7:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f01019dd:	50                   	push   %eax
f01019de:	e8 00 e7 ff ff       	call   f01000e3 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f01019e3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01019e6:	8d 83 d5 97 f7 ff    	lea    -0x8682b(%ebx),%eax
f01019ec:	50                   	push   %eax
f01019ed:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f01019f3:	50                   	push   %eax
f01019f4:	68 11 03 00 00       	push   $0x311
f01019f9:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f01019ff:	50                   	push   %eax
f0101a00:	e8 de e6 ff ff       	call   f01000e3 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101a05:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101a08:	8d 83 f2 97 f7 ff    	lea    -0x8680e(%ebx),%eax
f0101a0e:	50                   	push   %eax
f0101a0f:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0101a15:	50                   	push   %eax
f0101a16:	68 12 03 00 00       	push   $0x312
f0101a1b:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0101a21:	50                   	push   %eax
f0101a22:	e8 bc e6 ff ff       	call   f01000e3 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101a27:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101a2a:	8d 83 0f 98 f7 ff    	lea    -0x867f1(%ebx),%eax
f0101a30:	50                   	push   %eax
f0101a31:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0101a37:	50                   	push   %eax
f0101a38:	68 13 03 00 00       	push   $0x313
f0101a3d:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0101a43:	50                   	push   %eax
f0101a44:	e8 9a e6 ff ff       	call   f01000e3 <_panic>
	assert(!page_alloc(0));
f0101a49:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101a4c:	8d 83 2c 98 f7 ff    	lea    -0x867d4(%ebx),%eax
f0101a52:	50                   	push   %eax
f0101a53:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0101a59:	50                   	push   %eax
f0101a5a:	68 1a 03 00 00       	push   $0x31a
f0101a5f:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0101a65:	50                   	push   %eax
f0101a66:	e8 78 e6 ff ff       	call   f01000e3 <_panic>
	assert((pp0 = page_alloc(0)));
f0101a6b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101a6e:	8d 83 81 97 f7 ff    	lea    -0x8687f(%ebx),%eax
f0101a74:	50                   	push   %eax
f0101a75:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0101a7b:	50                   	push   %eax
f0101a7c:	68 21 03 00 00       	push   $0x321
f0101a81:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0101a87:	50                   	push   %eax
f0101a88:	e8 56 e6 ff ff       	call   f01000e3 <_panic>
	assert((pp1 = page_alloc(0)));
f0101a8d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101a90:	8d 83 97 97 f7 ff    	lea    -0x86869(%ebx),%eax
f0101a96:	50                   	push   %eax
f0101a97:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0101a9d:	50                   	push   %eax
f0101a9e:	68 22 03 00 00       	push   $0x322
f0101aa3:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0101aa9:	50                   	push   %eax
f0101aaa:	e8 34 e6 ff ff       	call   f01000e3 <_panic>
	assert((pp2 = page_alloc(0)));
f0101aaf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101ab2:	8d 83 ad 97 f7 ff    	lea    -0x86853(%ebx),%eax
f0101ab8:	50                   	push   %eax
f0101ab9:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0101abf:	50                   	push   %eax
f0101ac0:	68 23 03 00 00       	push   $0x323
f0101ac5:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0101acb:	50                   	push   %eax
f0101acc:	e8 12 e6 ff ff       	call   f01000e3 <_panic>
	assert(pp1 && pp1 != pp0);
f0101ad1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101ad4:	8d 83 c3 97 f7 ff    	lea    -0x8683d(%ebx),%eax
f0101ada:	50                   	push   %eax
f0101adb:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0101ae1:	50                   	push   %eax
f0101ae2:	68 25 03 00 00       	push   $0x325
f0101ae7:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0101aed:	50                   	push   %eax
f0101aee:	e8 f0 e5 ff ff       	call   f01000e3 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101af3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101af6:	8d 83 20 9b f7 ff    	lea    -0x864e0(%ebx),%eax
f0101afc:	50                   	push   %eax
f0101afd:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0101b03:	50                   	push   %eax
f0101b04:	68 26 03 00 00       	push   $0x326
f0101b09:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0101b0f:	50                   	push   %eax
f0101b10:	e8 ce e5 ff ff       	call   f01000e3 <_panic>
	assert(!page_alloc(0));
f0101b15:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101b18:	8d 83 2c 98 f7 ff    	lea    -0x867d4(%ebx),%eax
f0101b1e:	50                   	push   %eax
f0101b1f:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0101b25:	50                   	push   %eax
f0101b26:	68 27 03 00 00       	push   $0x327
f0101b2b:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0101b31:	50                   	push   %eax
f0101b32:	e8 ac e5 ff ff       	call   f01000e3 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101b37:	50                   	push   %eax
f0101b38:	8d 83 94 99 f7 ff    	lea    -0x8666c(%ebx),%eax
f0101b3e:	50                   	push   %eax
f0101b3f:	6a 56                	push   $0x56
f0101b41:	8d 83 82 96 f7 ff    	lea    -0x8697e(%ebx),%eax
f0101b47:	50                   	push   %eax
f0101b48:	e8 96 e5 ff ff       	call   f01000e3 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101b4d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101b50:	8d 83 3b 98 f7 ff    	lea    -0x867c5(%ebx),%eax
f0101b56:	50                   	push   %eax
f0101b57:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0101b5d:	50                   	push   %eax
f0101b5e:	68 2c 03 00 00       	push   $0x32c
f0101b63:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0101b69:	50                   	push   %eax
f0101b6a:	e8 74 e5 ff ff       	call   f01000e3 <_panic>
	assert(pp && pp0 == pp);
f0101b6f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101b72:	8d 83 59 98 f7 ff    	lea    -0x867a7(%ebx),%eax
f0101b78:	50                   	push   %eax
f0101b79:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0101b7f:	50                   	push   %eax
f0101b80:	68 2d 03 00 00       	push   $0x32d
f0101b85:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0101b8b:	50                   	push   %eax
f0101b8c:	e8 52 e5 ff ff       	call   f01000e3 <_panic>
f0101b91:	52                   	push   %edx
f0101b92:	8d 83 94 99 f7 ff    	lea    -0x8666c(%ebx),%eax
f0101b98:	50                   	push   %eax
f0101b99:	6a 56                	push   $0x56
f0101b9b:	8d 83 82 96 f7 ff    	lea    -0x8697e(%ebx),%eax
f0101ba1:	50                   	push   %eax
f0101ba2:	e8 3c e5 ff ff       	call   f01000e3 <_panic>
		assert(c[i] == 0);
f0101ba7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101baa:	8d 83 69 98 f7 ff    	lea    -0x86797(%ebx),%eax
f0101bb0:	50                   	push   %eax
f0101bb1:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0101bb7:	50                   	push   %eax
f0101bb8:	68 30 03 00 00       	push   $0x330
f0101bbd:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0101bc3:	50                   	push   %eax
f0101bc4:	e8 1a e5 ff ff       	call   f01000e3 <_panic>
		--nfree;
f0101bc9:	83 ee 01             	sub    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101bcc:	8b 00                	mov    (%eax),%eax
f0101bce:	85 c0                	test   %eax,%eax
f0101bd0:	75 f7                	jne    f0101bc9 <mem_init+0x665>
	assert(nfree == 0);
f0101bd2:	85 f6                	test   %esi,%esi
f0101bd4:	0f 85 6f 08 00 00    	jne    f0102449 <mem_init+0xee5>
	cprintf("check_page_alloc() succeeded!\n");
f0101bda:	83 ec 0c             	sub    $0xc,%esp
f0101bdd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101be0:	8d 83 40 9b f7 ff    	lea    -0x864c0(%ebx),%eax
f0101be6:	50                   	push   %eax
f0101be7:	e8 6c 20 00 00       	call   f0103c58 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101bec:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101bf3:	e8 0d f5 ff ff       	call   f0101105 <page_alloc>
f0101bf8:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101bfb:	83 c4 10             	add    $0x10,%esp
f0101bfe:	85 c0                	test   %eax,%eax
f0101c00:	0f 84 65 08 00 00    	je     f010246b <mem_init+0xf07>
	assert((pp1 = page_alloc(0)));
f0101c06:	83 ec 0c             	sub    $0xc,%esp
f0101c09:	6a 00                	push   $0x0
f0101c0b:	e8 f5 f4 ff ff       	call   f0101105 <page_alloc>
f0101c10:	89 c7                	mov    %eax,%edi
f0101c12:	83 c4 10             	add    $0x10,%esp
f0101c15:	85 c0                	test   %eax,%eax
f0101c17:	0f 84 70 08 00 00    	je     f010248d <mem_init+0xf29>
	assert((pp2 = page_alloc(0)));
f0101c1d:	83 ec 0c             	sub    $0xc,%esp
f0101c20:	6a 00                	push   $0x0
f0101c22:	e8 de f4 ff ff       	call   f0101105 <page_alloc>
f0101c27:	89 c6                	mov    %eax,%esi
f0101c29:	83 c4 10             	add    $0x10,%esp
f0101c2c:	85 c0                	test   %eax,%eax
f0101c2e:	0f 84 7b 08 00 00    	je     f01024af <mem_init+0xf4b>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101c34:	39 7d d0             	cmp    %edi,-0x30(%ebp)
f0101c37:	0f 84 94 08 00 00    	je     f01024d1 <mem_init+0xf6d>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101c3d:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101c40:	0f 84 ad 08 00 00    	je     f01024f3 <mem_init+0xf8f>
f0101c46:	39 c7                	cmp    %eax,%edi
f0101c48:	0f 84 a5 08 00 00    	je     f01024f3 <mem_init+0xf8f>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101c4e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c51:	8b 88 1c 23 00 00    	mov    0x231c(%eax),%ecx
f0101c57:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f0101c5a:	c7 80 1c 23 00 00 00 	movl   $0x0,0x231c(%eax)
f0101c61:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101c64:	83 ec 0c             	sub    $0xc,%esp
f0101c67:	6a 00                	push   $0x0
f0101c69:	e8 97 f4 ff ff       	call   f0101105 <page_alloc>
f0101c6e:	83 c4 10             	add    $0x10,%esp
f0101c71:	85 c0                	test   %eax,%eax
f0101c73:	0f 85 9c 08 00 00    	jne    f0102515 <mem_init+0xfb1>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101c79:	83 ec 04             	sub    $0x4,%esp
f0101c7c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101c7f:	50                   	push   %eax
f0101c80:	6a 00                	push   $0x0
f0101c82:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c85:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f0101c8b:	ff 30                	pushl  (%eax)
f0101c8d:	e8 3c f7 ff ff       	call   f01013ce <page_lookup>
f0101c92:	83 c4 10             	add    $0x10,%esp
f0101c95:	85 c0                	test   %eax,%eax
f0101c97:	0f 85 9a 08 00 00    	jne    f0102537 <mem_init+0xfd3>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101c9d:	6a 02                	push   $0x2
f0101c9f:	6a 00                	push   $0x0
f0101ca1:	57                   	push   %edi
f0101ca2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ca5:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f0101cab:	ff 30                	pushl  (%eax)
f0101cad:	e8 ee f7 ff ff       	call   f01014a0 <page_insert>
f0101cb2:	83 c4 10             	add    $0x10,%esp
f0101cb5:	85 c0                	test   %eax,%eax
f0101cb7:	0f 89 9c 08 00 00    	jns    f0102559 <mem_init+0xff5>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101cbd:	83 ec 0c             	sub    $0xc,%esp
f0101cc0:	ff 75 d0             	pushl  -0x30(%ebp)
f0101cc3:	e8 cb f4 ff ff       	call   f0101193 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101cc8:	6a 02                	push   $0x2
f0101cca:	6a 00                	push   $0x0
f0101ccc:	57                   	push   %edi
f0101ccd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101cd0:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f0101cd6:	ff 30                	pushl  (%eax)
f0101cd8:	e8 c3 f7 ff ff       	call   f01014a0 <page_insert>
f0101cdd:	83 c4 20             	add    $0x20,%esp
f0101ce0:	85 c0                	test   %eax,%eax
f0101ce2:	0f 85 93 08 00 00    	jne    f010257b <mem_init+0x1017>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101ce8:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101ceb:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f0101cf1:	8b 18                	mov    (%eax),%ebx
	return (pp - pages) << PGSHIFT;
f0101cf3:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0101cf9:	8b 08                	mov    (%eax),%ecx
f0101cfb:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0101cfe:	8b 13                	mov    (%ebx),%edx
f0101d00:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101d06:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101d09:	29 c8                	sub    %ecx,%eax
f0101d0b:	c1 f8 03             	sar    $0x3,%eax
f0101d0e:	c1 e0 0c             	shl    $0xc,%eax
f0101d11:	39 c2                	cmp    %eax,%edx
f0101d13:	0f 85 84 08 00 00    	jne    f010259d <mem_init+0x1039>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101d19:	ba 00 00 00 00       	mov    $0x0,%edx
f0101d1e:	89 d8                	mov    %ebx,%eax
f0101d20:	e8 79 ee ff ff       	call   f0100b9e <check_va2pa>
f0101d25:	89 fa                	mov    %edi,%edx
f0101d27:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101d2a:	c1 fa 03             	sar    $0x3,%edx
f0101d2d:	c1 e2 0c             	shl    $0xc,%edx
f0101d30:	39 d0                	cmp    %edx,%eax
f0101d32:	0f 85 87 08 00 00    	jne    f01025bf <mem_init+0x105b>
	assert(pp1->pp_ref == 1);
f0101d38:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101d3d:	0f 85 9e 08 00 00    	jne    f01025e1 <mem_init+0x107d>
	assert(pp0->pp_ref == 1);
f0101d43:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101d46:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101d4b:	0f 85 b2 08 00 00    	jne    f0102603 <mem_init+0x109f>

	// should be able to map pp2 at PGSIZE because 
	// pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101d51:	6a 02                	push   $0x2
f0101d53:	68 00 10 00 00       	push   $0x1000
f0101d58:	56                   	push   %esi
f0101d59:	53                   	push   %ebx
f0101d5a:	e8 41 f7 ff ff       	call   f01014a0 <page_insert>
f0101d5f:	83 c4 10             	add    $0x10,%esp
f0101d62:	85 c0                	test   %eax,%eax
f0101d64:	0f 85 bb 08 00 00    	jne    f0102625 <mem_init+0x10c1>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101d6a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d6f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101d72:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f0101d78:	8b 00                	mov    (%eax),%eax
f0101d7a:	e8 1f ee ff ff       	call   f0100b9e <check_va2pa>
f0101d7f:	c7 c2 0c f0 18 f0    	mov    $0xf018f00c,%edx
f0101d85:	89 f1                	mov    %esi,%ecx
f0101d87:	2b 0a                	sub    (%edx),%ecx
f0101d89:	89 ca                	mov    %ecx,%edx
f0101d8b:	c1 fa 03             	sar    $0x3,%edx
f0101d8e:	c1 e2 0c             	shl    $0xc,%edx
f0101d91:	39 d0                	cmp    %edx,%eax
f0101d93:	0f 85 ae 08 00 00    	jne    f0102647 <mem_init+0x10e3>
	assert(pp2->pp_ref == 1);
f0101d99:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d9e:	0f 85 c5 08 00 00    	jne    f0102669 <mem_init+0x1105>

	// should be no free memory
	assert(!page_alloc(0));
f0101da4:	83 ec 0c             	sub    $0xc,%esp
f0101da7:	6a 00                	push   $0x0
f0101da9:	e8 57 f3 ff ff       	call   f0101105 <page_alloc>
f0101dae:	83 c4 10             	add    $0x10,%esp
f0101db1:	85 c0                	test   %eax,%eax
f0101db3:	0f 85 d2 08 00 00    	jne    f010268b <mem_init+0x1127>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101db9:	6a 02                	push   $0x2
f0101dbb:	68 00 10 00 00       	push   $0x1000
f0101dc0:	56                   	push   %esi
f0101dc1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101dc4:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f0101dca:	ff 30                	pushl  (%eax)
f0101dcc:	e8 cf f6 ff ff       	call   f01014a0 <page_insert>
f0101dd1:	83 c4 10             	add    $0x10,%esp
f0101dd4:	85 c0                	test   %eax,%eax
f0101dd6:	0f 85 d1 08 00 00    	jne    f01026ad <mem_init+0x1149>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ddc:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101de1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101de4:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f0101dea:	8b 00                	mov    (%eax),%eax
f0101dec:	e8 ad ed ff ff       	call   f0100b9e <check_va2pa>
f0101df1:	c7 c2 0c f0 18 f0    	mov    $0xf018f00c,%edx
f0101df7:	89 f1                	mov    %esi,%ecx
f0101df9:	2b 0a                	sub    (%edx),%ecx
f0101dfb:	89 ca                	mov    %ecx,%edx
f0101dfd:	c1 fa 03             	sar    $0x3,%edx
f0101e00:	c1 e2 0c             	shl    $0xc,%edx
f0101e03:	39 d0                	cmp    %edx,%eax
f0101e05:	0f 85 c4 08 00 00    	jne    f01026cf <mem_init+0x116b>
	assert(pp2->pp_ref == 1);
f0101e0b:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e10:	0f 85 db 08 00 00    	jne    f01026f1 <mem_init+0x118d>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101e16:	83 ec 0c             	sub    $0xc,%esp
f0101e19:	6a 00                	push   $0x0
f0101e1b:	e8 e5 f2 ff ff       	call   f0101105 <page_alloc>
f0101e20:	83 c4 10             	add    $0x10,%esp
f0101e23:	85 c0                	test   %eax,%eax
f0101e25:	0f 85 e8 08 00 00    	jne    f0102713 <mem_init+0x11af>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101e2b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101e2e:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f0101e34:	8b 10                	mov    (%eax),%edx
f0101e36:	8b 02                	mov    (%edx),%eax
f0101e38:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101e3d:	89 c3                	mov    %eax,%ebx
f0101e3f:	c1 eb 0c             	shr    $0xc,%ebx
f0101e42:	c7 c1 04 f0 18 f0    	mov    $0xf018f004,%ecx
f0101e48:	3b 19                	cmp    (%ecx),%ebx
f0101e4a:	0f 83 e5 08 00 00    	jae    f0102735 <mem_init+0x11d1>
	return (void *)(pa + KERNBASE);
f0101e50:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101e55:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101e58:	83 ec 04             	sub    $0x4,%esp
f0101e5b:	6a 00                	push   $0x0
f0101e5d:	68 00 10 00 00       	push   $0x1000
f0101e62:	52                   	push   %edx
f0101e63:	e8 be f3 ff ff       	call   f0101226 <pgdir_walk>
f0101e68:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101e6b:	8d 51 04             	lea    0x4(%ecx),%edx
f0101e6e:	83 c4 10             	add    $0x10,%esp
f0101e71:	39 d0                	cmp    %edx,%eax
f0101e73:	0f 85 d8 08 00 00    	jne    f0102751 <mem_init+0x11ed>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101e79:	6a 06                	push   $0x6
f0101e7b:	68 00 10 00 00       	push   $0x1000
f0101e80:	56                   	push   %esi
f0101e81:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e84:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f0101e8a:	ff 30                	pushl  (%eax)
f0101e8c:	e8 0f f6 ff ff       	call   f01014a0 <page_insert>
f0101e91:	83 c4 10             	add    $0x10,%esp
f0101e94:	85 c0                	test   %eax,%eax
f0101e96:	0f 85 d7 08 00 00    	jne    f0102773 <mem_init+0x120f>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101e9c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e9f:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f0101ea5:	8b 18                	mov    (%eax),%ebx
f0101ea7:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101eac:	89 d8                	mov    %ebx,%eax
f0101eae:	e8 eb ec ff ff       	call   f0100b9e <check_va2pa>
	return (pp - pages) << PGSHIFT;
f0101eb3:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101eb6:	c7 c2 0c f0 18 f0    	mov    $0xf018f00c,%edx
f0101ebc:	89 f1                	mov    %esi,%ecx
f0101ebe:	2b 0a                	sub    (%edx),%ecx
f0101ec0:	89 ca                	mov    %ecx,%edx
f0101ec2:	c1 fa 03             	sar    $0x3,%edx
f0101ec5:	c1 e2 0c             	shl    $0xc,%edx
f0101ec8:	39 d0                	cmp    %edx,%eax
f0101eca:	0f 85 c5 08 00 00    	jne    f0102795 <mem_init+0x1231>
	assert(pp2->pp_ref == 1);
f0101ed0:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ed5:	0f 85 dc 08 00 00    	jne    f01027b7 <mem_init+0x1253>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101edb:	83 ec 04             	sub    $0x4,%esp
f0101ede:	6a 00                	push   $0x0
f0101ee0:	68 00 10 00 00       	push   $0x1000
f0101ee5:	53                   	push   %ebx
f0101ee6:	e8 3b f3 ff ff       	call   f0101226 <pgdir_walk>
f0101eeb:	83 c4 10             	add    $0x10,%esp
f0101eee:	f6 00 04             	testb  $0x4,(%eax)
f0101ef1:	0f 84 e2 08 00 00    	je     f01027d9 <mem_init+0x1275>
	assert(kern_pgdir[0] & PTE_U);
f0101ef7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101efa:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f0101f00:	8b 00                	mov    (%eax),%eax
f0101f02:	f6 00 04             	testb  $0x4,(%eax)
f0101f05:	0f 84 f0 08 00 00    	je     f01027fb <mem_init+0x1297>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101f0b:	6a 02                	push   $0x2
f0101f0d:	68 00 10 00 00       	push   $0x1000
f0101f12:	56                   	push   %esi
f0101f13:	50                   	push   %eax
f0101f14:	e8 87 f5 ff ff       	call   f01014a0 <page_insert>
f0101f19:	83 c4 10             	add    $0x10,%esp
f0101f1c:	85 c0                	test   %eax,%eax
f0101f1e:	0f 85 f9 08 00 00    	jne    f010281d <mem_init+0x12b9>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101f24:	83 ec 04             	sub    $0x4,%esp
f0101f27:	6a 00                	push   $0x0
f0101f29:	68 00 10 00 00       	push   $0x1000
f0101f2e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f31:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f0101f37:	ff 30                	pushl  (%eax)
f0101f39:	e8 e8 f2 ff ff       	call   f0101226 <pgdir_walk>
f0101f3e:	83 c4 10             	add    $0x10,%esp
f0101f41:	f6 00 02             	testb  $0x2,(%eax)
f0101f44:	0f 84 f5 08 00 00    	je     f010283f <mem_init+0x12db>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101f4a:	83 ec 04             	sub    $0x4,%esp
f0101f4d:	6a 00                	push   $0x0
f0101f4f:	68 00 10 00 00       	push   $0x1000
f0101f54:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f57:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f0101f5d:	ff 30                	pushl  (%eax)
f0101f5f:	e8 c2 f2 ff ff       	call   f0101226 <pgdir_walk>
f0101f64:	83 c4 10             	add    $0x10,%esp
f0101f67:	f6 00 04             	testb  $0x4,(%eax)
f0101f6a:	0f 85 f1 08 00 00    	jne    f0102861 <mem_init+0x12fd>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101f70:	6a 02                	push   $0x2
f0101f72:	68 00 00 40 00       	push   $0x400000
f0101f77:	ff 75 d0             	pushl  -0x30(%ebp)
f0101f7a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f7d:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f0101f83:	ff 30                	pushl  (%eax)
f0101f85:	e8 16 f5 ff ff       	call   f01014a0 <page_insert>
f0101f8a:	83 c4 10             	add    $0x10,%esp
f0101f8d:	85 c0                	test   %eax,%eax
f0101f8f:	0f 89 ee 08 00 00    	jns    f0102883 <mem_init+0x131f>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101f95:	6a 02                	push   $0x2
f0101f97:	68 00 10 00 00       	push   $0x1000
f0101f9c:	57                   	push   %edi
f0101f9d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fa0:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f0101fa6:	ff 30                	pushl  (%eax)
f0101fa8:	e8 f3 f4 ff ff       	call   f01014a0 <page_insert>
f0101fad:	83 c4 10             	add    $0x10,%esp
f0101fb0:	85 c0                	test   %eax,%eax
f0101fb2:	0f 85 ed 08 00 00    	jne    f01028a5 <mem_init+0x1341>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101fb8:	83 ec 04             	sub    $0x4,%esp
f0101fbb:	6a 00                	push   $0x0
f0101fbd:	68 00 10 00 00       	push   $0x1000
f0101fc2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fc5:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f0101fcb:	ff 30                	pushl  (%eax)
f0101fcd:	e8 54 f2 ff ff       	call   f0101226 <pgdir_walk>
f0101fd2:	83 c4 10             	add    $0x10,%esp
f0101fd5:	f6 00 04             	testb  $0x4,(%eax)
f0101fd8:	0f 85 e9 08 00 00    	jne    f01028c7 <mem_init+0x1363>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101fde:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fe1:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f0101fe7:	8b 18                	mov    (%eax),%ebx
f0101fe9:	ba 00 00 00 00       	mov    $0x0,%edx
f0101fee:	89 d8                	mov    %ebx,%eax
f0101ff0:	e8 a9 eb ff ff       	call   f0100b9e <check_va2pa>
f0101ff5:	89 c2                	mov    %eax,%edx
f0101ff7:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101ffa:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101ffd:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0102003:	89 f9                	mov    %edi,%ecx
f0102005:	2b 08                	sub    (%eax),%ecx
f0102007:	89 c8                	mov    %ecx,%eax
f0102009:	c1 f8 03             	sar    $0x3,%eax
f010200c:	c1 e0 0c             	shl    $0xc,%eax
f010200f:	39 c2                	cmp    %eax,%edx
f0102011:	0f 85 d2 08 00 00    	jne    f01028e9 <mem_init+0x1385>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102017:	ba 00 10 00 00       	mov    $0x1000,%edx
f010201c:	89 d8                	mov    %ebx,%eax
f010201e:	e8 7b eb ff ff       	call   f0100b9e <check_va2pa>
f0102023:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0102026:	0f 85 df 08 00 00    	jne    f010290b <mem_init+0x13a7>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f010202c:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0102031:	0f 85 f6 08 00 00    	jne    f010292d <mem_init+0x13c9>
	assert(pp2->pp_ref == 0);
f0102037:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010203c:	0f 85 0d 09 00 00    	jne    f010294f <mem_init+0x13eb>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102042:	83 ec 0c             	sub    $0xc,%esp
f0102045:	6a 00                	push   $0x0
f0102047:	e8 b9 f0 ff ff       	call   f0101105 <page_alloc>
f010204c:	83 c4 10             	add    $0x10,%esp
f010204f:	39 c6                	cmp    %eax,%esi
f0102051:	0f 85 1a 09 00 00    	jne    f0102971 <mem_init+0x140d>
f0102057:	85 c0                	test   %eax,%eax
f0102059:	0f 84 12 09 00 00    	je     f0102971 <mem_init+0x140d>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f010205f:	83 ec 08             	sub    $0x8,%esp
f0102062:	6a 00                	push   $0x0
f0102064:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102067:	c7 c3 08 f0 18 f0    	mov    $0xf018f008,%ebx
f010206d:	ff 33                	pushl  (%ebx)
f010206f:	e8 d5 f3 ff ff       	call   f0101449 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102074:	8b 1b                	mov    (%ebx),%ebx
f0102076:	ba 00 00 00 00       	mov    $0x0,%edx
f010207b:	89 d8                	mov    %ebx,%eax
f010207d:	e8 1c eb ff ff       	call   f0100b9e <check_va2pa>
f0102082:	83 c4 10             	add    $0x10,%esp
f0102085:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102088:	0f 85 05 09 00 00    	jne    f0102993 <mem_init+0x142f>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010208e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102093:	89 d8                	mov    %ebx,%eax
f0102095:	e8 04 eb ff ff       	call   f0100b9e <check_va2pa>
f010209a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010209d:	c7 c2 0c f0 18 f0    	mov    $0xf018f00c,%edx
f01020a3:	89 f9                	mov    %edi,%ecx
f01020a5:	2b 0a                	sub    (%edx),%ecx
f01020a7:	89 ca                	mov    %ecx,%edx
f01020a9:	c1 fa 03             	sar    $0x3,%edx
f01020ac:	c1 e2 0c             	shl    $0xc,%edx
f01020af:	39 d0                	cmp    %edx,%eax
f01020b1:	0f 85 fe 08 00 00    	jne    f01029b5 <mem_init+0x1451>
	assert(pp1->pp_ref == 1);
f01020b7:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01020bc:	0f 85 15 09 00 00    	jne    f01029d7 <mem_init+0x1473>
	assert(pp2->pp_ref == 0);
f01020c2:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01020c7:	0f 85 2c 09 00 00    	jne    f01029f9 <mem_init+0x1495>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f01020cd:	6a 00                	push   $0x0
f01020cf:	68 00 10 00 00       	push   $0x1000
f01020d4:	57                   	push   %edi
f01020d5:	53                   	push   %ebx
f01020d6:	e8 c5 f3 ff ff       	call   f01014a0 <page_insert>
f01020db:	83 c4 10             	add    $0x10,%esp
f01020de:	85 c0                	test   %eax,%eax
f01020e0:	0f 85 35 09 00 00    	jne    f0102a1b <mem_init+0x14b7>
	assert(pp1->pp_ref);
f01020e6:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01020eb:	0f 84 4c 09 00 00    	je     f0102a3d <mem_init+0x14d9>
	assert(pp1->pp_link == NULL);
f01020f1:	83 3f 00             	cmpl   $0x0,(%edi)
f01020f4:	0f 85 65 09 00 00    	jne    f0102a5f <mem_init+0x14fb>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01020fa:	83 ec 08             	sub    $0x8,%esp
f01020fd:	68 00 10 00 00       	push   $0x1000
f0102102:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102105:	c7 c3 08 f0 18 f0    	mov    $0xf018f008,%ebx
f010210b:	ff 33                	pushl  (%ebx)
f010210d:	e8 37 f3 ff ff       	call   f0101449 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102112:	8b 1b                	mov    (%ebx),%ebx
f0102114:	ba 00 00 00 00       	mov    $0x0,%edx
f0102119:	89 d8                	mov    %ebx,%eax
f010211b:	e8 7e ea ff ff       	call   f0100b9e <check_va2pa>
f0102120:	83 c4 10             	add    $0x10,%esp
f0102123:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102126:	0f 85 55 09 00 00    	jne    f0102a81 <mem_init+0x151d>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010212c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102131:	89 d8                	mov    %ebx,%eax
f0102133:	e8 66 ea ff ff       	call   f0100b9e <check_va2pa>
f0102138:	83 f8 ff             	cmp    $0xffffffff,%eax
f010213b:	0f 85 62 09 00 00    	jne    f0102aa3 <mem_init+0x153f>
	assert(pp1->pp_ref == 0);
f0102141:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102146:	0f 85 79 09 00 00    	jne    f0102ac5 <mem_init+0x1561>
	assert(pp2->pp_ref == 0);
f010214c:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102151:	0f 85 90 09 00 00    	jne    f0102ae7 <mem_init+0x1583>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102157:	83 ec 0c             	sub    $0xc,%esp
f010215a:	6a 00                	push   $0x0
f010215c:	e8 a4 ef ff ff       	call   f0101105 <page_alloc>
f0102161:	83 c4 10             	add    $0x10,%esp
f0102164:	85 c0                	test   %eax,%eax
f0102166:	0f 84 9d 09 00 00    	je     f0102b09 <mem_init+0x15a5>
f010216c:	39 c7                	cmp    %eax,%edi
f010216e:	0f 85 95 09 00 00    	jne    f0102b09 <mem_init+0x15a5>

	// should be no free memory
	assert(!page_alloc(0));
f0102174:	83 ec 0c             	sub    $0xc,%esp
f0102177:	6a 00                	push   $0x0
f0102179:	e8 87 ef ff ff       	call   f0101105 <page_alloc>
f010217e:	83 c4 10             	add    $0x10,%esp
f0102181:	85 c0                	test   %eax,%eax
f0102183:	0f 85 a2 09 00 00    	jne    f0102b2b <mem_init+0x15c7>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102189:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010218c:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f0102192:	8b 08                	mov    (%eax),%ecx
f0102194:	8b 11                	mov    (%ecx),%edx
f0102196:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010219c:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f01021a2:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f01021a5:	2b 18                	sub    (%eax),%ebx
f01021a7:	89 d8                	mov    %ebx,%eax
f01021a9:	c1 f8 03             	sar    $0x3,%eax
f01021ac:	c1 e0 0c             	shl    $0xc,%eax
f01021af:	39 c2                	cmp    %eax,%edx
f01021b1:	0f 85 96 09 00 00    	jne    f0102b4d <mem_init+0x15e9>
	kern_pgdir[0] = 0;
f01021b7:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01021bd:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01021c0:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01021c5:	0f 85 a4 09 00 00    	jne    f0102b6f <mem_init+0x160b>
	pp0->pp_ref = 0;
f01021cb:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01021ce:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01021d4:	83 ec 0c             	sub    $0xc,%esp
f01021d7:	50                   	push   %eax
f01021d8:	e8 b6 ef ff ff       	call   f0101193 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01021dd:	83 c4 0c             	add    $0xc,%esp
f01021e0:	6a 01                	push   $0x1
f01021e2:	68 00 10 40 00       	push   $0x401000
f01021e7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021ea:	c7 c3 08 f0 18 f0    	mov    $0xf018f008,%ebx
f01021f0:	ff 33                	pushl  (%ebx)
f01021f2:	e8 2f f0 ff ff       	call   f0101226 <pgdir_walk>
f01021f7:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01021fa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01021fd:	8b 1b                	mov    (%ebx),%ebx
f01021ff:	8b 53 04             	mov    0x4(%ebx),%edx
f0102202:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f0102208:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010220b:	c7 c1 04 f0 18 f0    	mov    $0xf018f004,%ecx
f0102211:	8b 09                	mov    (%ecx),%ecx
f0102213:	89 d0                	mov    %edx,%eax
f0102215:	c1 e8 0c             	shr    $0xc,%eax
f0102218:	83 c4 10             	add    $0x10,%esp
f010221b:	39 c8                	cmp    %ecx,%eax
f010221d:	0f 83 6e 09 00 00    	jae    f0102b91 <mem_init+0x162d>
	assert(ptep == ptep1 + PTX(va));
f0102223:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0102229:	39 55 cc             	cmp    %edx,-0x34(%ebp)
f010222c:	0f 85 7b 09 00 00    	jne    f0102bad <mem_init+0x1649>
	kern_pgdir[PDX(va)] = 0;
f0102232:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	pp0->pp_ref = 0;
f0102239:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f010223c:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return (pp - pages) << PGSHIFT;
f0102242:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102245:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f010224b:	2b 18                	sub    (%eax),%ebx
f010224d:	89 d8                	mov    %ebx,%eax
f010224f:	c1 f8 03             	sar    $0x3,%eax
f0102252:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102255:	89 c2                	mov    %eax,%edx
f0102257:	c1 ea 0c             	shr    $0xc,%edx
f010225a:	39 d1                	cmp    %edx,%ecx
f010225c:	0f 86 6d 09 00 00    	jbe    f0102bcf <mem_init+0x166b>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102262:	83 ec 04             	sub    $0x4,%esp
f0102265:	68 00 10 00 00       	push   $0x1000
f010226a:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f010226f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102274:	50                   	push   %eax
f0102275:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102278:	e8 8a 2a 00 00       	call   f0104d07 <memset>
	page_free(pp0);
f010227d:	83 c4 04             	add    $0x4,%esp
f0102280:	ff 75 d0             	pushl  -0x30(%ebp)
f0102283:	e8 0b ef ff ff       	call   f0101193 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102288:	83 c4 0c             	add    $0xc,%esp
f010228b:	6a 01                	push   $0x1
f010228d:	6a 00                	push   $0x0
f010228f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102292:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f0102298:	ff 30                	pushl  (%eax)
f010229a:	e8 87 ef ff ff       	call   f0101226 <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f010229f:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f01022a5:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01022a8:	2b 10                	sub    (%eax),%edx
f01022aa:	c1 fa 03             	sar    $0x3,%edx
f01022ad:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01022b0:	89 d1                	mov    %edx,%ecx
f01022b2:	c1 e9 0c             	shr    $0xc,%ecx
f01022b5:	83 c4 10             	add    $0x10,%esp
f01022b8:	c7 c0 04 f0 18 f0    	mov    $0xf018f004,%eax
f01022be:	3b 08                	cmp    (%eax),%ecx
f01022c0:	0f 83 22 09 00 00    	jae    f0102be8 <mem_init+0x1684>
	return (void *)(pa + KERNBASE);
f01022c6:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01022cc:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01022cf:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01022d5:	f6 00 01             	testb  $0x1,(%eax)
f01022d8:	0f 85 23 09 00 00    	jne    f0102c01 <mem_init+0x169d>
f01022de:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f01022e1:	39 d0                	cmp    %edx,%eax
f01022e3:	75 f0                	jne    f01022d5 <mem_init+0xd71>
	kern_pgdir[0] = 0;
f01022e5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022e8:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f01022ee:	8b 00                	mov    (%eax),%eax
f01022f0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01022f6:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01022f9:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01022ff:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0102302:	89 93 1c 23 00 00    	mov    %edx,0x231c(%ebx)

	// free the pages we took
	page_free(pp0);
f0102308:	83 ec 0c             	sub    $0xc,%esp
f010230b:	50                   	push   %eax
f010230c:	e8 82 ee ff ff       	call   f0101193 <page_free>
	page_free(pp1);
f0102311:	89 3c 24             	mov    %edi,(%esp)
f0102314:	e8 7a ee ff ff       	call   f0101193 <page_free>
	page_free(pp2);
f0102319:	89 34 24             	mov    %esi,(%esp)
f010231c:	e8 72 ee ff ff       	call   f0101193 <page_free>

	cprintf("check_page() succeeded!\n");
f0102321:	8d 83 4a 99 f7 ff    	lea    -0x866b6(%ebx),%eax
f0102327:	89 04 24             	mov    %eax,(%esp)
f010232a:	e8 29 19 00 00       	call   f0103c58 <cprintf>
	boot_map_region(kern_pgdir, 
f010232f:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0102335:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102337:	83 c4 10             	add    $0x10,%esp
f010233a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010233f:	0f 86 de 08 00 00    	jbe    f0102c23 <mem_init+0x16bf>
					ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE), 
f0102345:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102348:	c7 c2 04 f0 18 f0    	mov    $0xf018f004,%edx
f010234e:	8b 12                	mov    (%edx),%edx
f0102350:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
	boot_map_region(kern_pgdir, 
f0102357:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f010235d:	83 ec 08             	sub    $0x8,%esp
f0102360:	6a 05                	push   $0x5
	return (physaddr_t)kva - KERNBASE;
f0102362:	05 00 00 00 10       	add    $0x10000000,%eax
f0102367:	50                   	push   %eax
f0102368:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010236d:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f0102373:	8b 00                	mov    (%eax),%eax
f0102375:	e8 b1 ef ff ff       	call   f010132b <boot_map_region>
	boot_map_region(kern_pgdir,
f010237a:	c7 c0 48 e3 18 f0    	mov    $0xf018e348,%eax
f0102380:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102382:	83 c4 10             	add    $0x10,%esp
f0102385:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010238a:	0f 86 af 08 00 00    	jbe    f0102c3f <mem_init+0x16db>
f0102390:	83 ec 08             	sub    $0x8,%esp
f0102393:	6a 05                	push   $0x5
	return (physaddr_t)kva - KERNBASE;
f0102395:	05 00 00 00 10       	add    $0x10000000,%eax
f010239a:	50                   	push   %eax
f010239b:	b9 00 80 01 00       	mov    $0x18000,%ecx
f01023a0:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f01023a5:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f01023a8:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f01023ae:	8b 00                	mov    (%eax),%eax
f01023b0:	e8 76 ef ff ff       	call   f010132b <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f01023b5:	c7 c0 00 20 11 f0    	mov    $0xf0112000,%eax
f01023bb:	89 45 c8             	mov    %eax,-0x38(%ebp)
f01023be:	83 c4 10             	add    $0x10,%esp
f01023c1:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01023c6:	0f 86 8f 08 00 00    	jbe    f0102c5b <mem_init+0x16f7>
	boot_map_region(kern_pgdir,
f01023cc:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01023cf:	c7 c3 08 f0 18 f0    	mov    $0xf018f008,%ebx
f01023d5:	83 ec 08             	sub    $0x8,%esp
f01023d8:	6a 03                	push   $0x3
	return (physaddr_t)kva - KERNBASE;
f01023da:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01023dd:	05 00 00 00 10       	add    $0x10000000,%eax
f01023e2:	50                   	push   %eax
f01023e3:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01023e8:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01023ed:	8b 03                	mov    (%ebx),%eax
f01023ef:	e8 37 ef ff ff       	call   f010132b <boot_map_region>
	boot_map_region(kern_pgdir,
f01023f4:	83 c4 08             	add    $0x8,%esp
f01023f7:	6a 03                	push   $0x3
f01023f9:	6a 00                	push   $0x0
f01023fb:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102400:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102405:	8b 03                	mov    (%ebx),%eax
f0102407:	e8 1f ef ff ff       	call   f010132b <boot_map_region>
	pgdir = kern_pgdir;
f010240c:	8b 33                	mov    (%ebx),%esi
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010240e:	c7 c0 04 f0 18 f0    	mov    $0xf018f004,%eax
f0102414:	8b 00                	mov    (%eax),%eax
f0102416:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0102419:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102420:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102425:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102428:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f010242e:	8b 00                	mov    (%eax),%eax
f0102430:	89 45 c0             	mov    %eax,-0x40(%ebp)
	if ((uint32_t)kva < KERNBASE)
f0102433:	89 45 cc             	mov    %eax,-0x34(%ebp)
	return (physaddr_t)kva - KERNBASE;
f0102436:	8d b8 00 00 00 10    	lea    0x10000000(%eax),%edi
f010243c:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < n; i += PGSIZE)
f010243f:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102444:	e9 57 08 00 00       	jmp    f0102ca0 <mem_init+0x173c>
	assert(nfree == 0);
f0102449:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010244c:	8d 83 73 98 f7 ff    	lea    -0x8678d(%ebx),%eax
f0102452:	50                   	push   %eax
f0102453:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102459:	50                   	push   %eax
f010245a:	68 3d 03 00 00       	push   $0x33d
f010245f:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102465:	50                   	push   %eax
f0102466:	e8 78 dc ff ff       	call   f01000e3 <_panic>
	assert((pp0 = page_alloc(0)));
f010246b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010246e:	8d 83 81 97 f7 ff    	lea    -0x8687f(%ebx),%eax
f0102474:	50                   	push   %eax
f0102475:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f010247b:	50                   	push   %eax
f010247c:	68 9a 03 00 00       	push   $0x39a
f0102481:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102487:	50                   	push   %eax
f0102488:	e8 56 dc ff ff       	call   f01000e3 <_panic>
	assert((pp1 = page_alloc(0)));
f010248d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102490:	8d 83 97 97 f7 ff    	lea    -0x86869(%ebx),%eax
f0102496:	50                   	push   %eax
f0102497:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f010249d:	50                   	push   %eax
f010249e:	68 9b 03 00 00       	push   $0x39b
f01024a3:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f01024a9:	50                   	push   %eax
f01024aa:	e8 34 dc ff ff       	call   f01000e3 <_panic>
	assert((pp2 = page_alloc(0)));
f01024af:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024b2:	8d 83 ad 97 f7 ff    	lea    -0x86853(%ebx),%eax
f01024b8:	50                   	push   %eax
f01024b9:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f01024bf:	50                   	push   %eax
f01024c0:	68 9c 03 00 00       	push   $0x39c
f01024c5:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f01024cb:	50                   	push   %eax
f01024cc:	e8 12 dc ff ff       	call   f01000e3 <_panic>
	assert(pp1 && pp1 != pp0);
f01024d1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024d4:	8d 83 c3 97 f7 ff    	lea    -0x8683d(%ebx),%eax
f01024da:	50                   	push   %eax
f01024db:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f01024e1:	50                   	push   %eax
f01024e2:	68 9f 03 00 00       	push   $0x39f
f01024e7:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f01024ed:	50                   	push   %eax
f01024ee:	e8 f0 db ff ff       	call   f01000e3 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01024f3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024f6:	8d 83 20 9b f7 ff    	lea    -0x864e0(%ebx),%eax
f01024fc:	50                   	push   %eax
f01024fd:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102503:	50                   	push   %eax
f0102504:	68 a0 03 00 00       	push   $0x3a0
f0102509:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f010250f:	50                   	push   %eax
f0102510:	e8 ce db ff ff       	call   f01000e3 <_panic>
	assert(!page_alloc(0));
f0102515:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102518:	8d 83 2c 98 f7 ff    	lea    -0x867d4(%ebx),%eax
f010251e:	50                   	push   %eax
f010251f:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102525:	50                   	push   %eax
f0102526:	68 a7 03 00 00       	push   $0x3a7
f010252b:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102531:	50                   	push   %eax
f0102532:	e8 ac db ff ff       	call   f01000e3 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0102537:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010253a:	8d 83 60 9b f7 ff    	lea    -0x864a0(%ebx),%eax
f0102540:	50                   	push   %eax
f0102541:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102547:	50                   	push   %eax
f0102548:	68 aa 03 00 00       	push   $0x3aa
f010254d:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102553:	50                   	push   %eax
f0102554:	e8 8a db ff ff       	call   f01000e3 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0102559:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010255c:	8d 83 98 9b f7 ff    	lea    -0x86468(%ebx),%eax
f0102562:	50                   	push   %eax
f0102563:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102569:	50                   	push   %eax
f010256a:	68 ad 03 00 00       	push   $0x3ad
f010256f:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102575:	50                   	push   %eax
f0102576:	e8 68 db ff ff       	call   f01000e3 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010257b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010257e:	8d 83 c8 9b f7 ff    	lea    -0x86438(%ebx),%eax
f0102584:	50                   	push   %eax
f0102585:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f010258b:	50                   	push   %eax
f010258c:	68 b1 03 00 00       	push   $0x3b1
f0102591:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102597:	50                   	push   %eax
f0102598:	e8 46 db ff ff       	call   f01000e3 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010259d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025a0:	8d 83 f8 9b f7 ff    	lea    -0x86408(%ebx),%eax
f01025a6:	50                   	push   %eax
f01025a7:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f01025ad:	50                   	push   %eax
f01025ae:	68 b2 03 00 00       	push   $0x3b2
f01025b3:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f01025b9:	50                   	push   %eax
f01025ba:	e8 24 db ff ff       	call   f01000e3 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01025bf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025c2:	8d 83 20 9c f7 ff    	lea    -0x863e0(%ebx),%eax
f01025c8:	50                   	push   %eax
f01025c9:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f01025cf:	50                   	push   %eax
f01025d0:	68 b3 03 00 00       	push   $0x3b3
f01025d5:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f01025db:	50                   	push   %eax
f01025dc:	e8 02 db ff ff       	call   f01000e3 <_panic>
	assert(pp1->pp_ref == 1);
f01025e1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025e4:	8d 83 7e 98 f7 ff    	lea    -0x86782(%ebx),%eax
f01025ea:	50                   	push   %eax
f01025eb:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f01025f1:	50                   	push   %eax
f01025f2:	68 b4 03 00 00       	push   $0x3b4
f01025f7:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f01025fd:	50                   	push   %eax
f01025fe:	e8 e0 da ff ff       	call   f01000e3 <_panic>
	assert(pp0->pp_ref == 1);
f0102603:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102606:	8d 83 8f 98 f7 ff    	lea    -0x86771(%ebx),%eax
f010260c:	50                   	push   %eax
f010260d:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102613:	50                   	push   %eax
f0102614:	68 b5 03 00 00       	push   $0x3b5
f0102619:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f010261f:	50                   	push   %eax
f0102620:	e8 be da ff ff       	call   f01000e3 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102625:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102628:	8d 83 50 9c f7 ff    	lea    -0x863b0(%ebx),%eax
f010262e:	50                   	push   %eax
f010262f:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102635:	50                   	push   %eax
f0102636:	68 b9 03 00 00       	push   $0x3b9
f010263b:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102641:	50                   	push   %eax
f0102642:	e8 9c da ff ff       	call   f01000e3 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102647:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010264a:	8d 83 8c 9c f7 ff    	lea    -0x86374(%ebx),%eax
f0102650:	50                   	push   %eax
f0102651:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102657:	50                   	push   %eax
f0102658:	68 ba 03 00 00       	push   $0x3ba
f010265d:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102663:	50                   	push   %eax
f0102664:	e8 7a da ff ff       	call   f01000e3 <_panic>
	assert(pp2->pp_ref == 1);
f0102669:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010266c:	8d 83 a0 98 f7 ff    	lea    -0x86760(%ebx),%eax
f0102672:	50                   	push   %eax
f0102673:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102679:	50                   	push   %eax
f010267a:	68 bb 03 00 00       	push   $0x3bb
f010267f:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102685:	50                   	push   %eax
f0102686:	e8 58 da ff ff       	call   f01000e3 <_panic>
	assert(!page_alloc(0));
f010268b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010268e:	8d 83 2c 98 f7 ff    	lea    -0x867d4(%ebx),%eax
f0102694:	50                   	push   %eax
f0102695:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f010269b:	50                   	push   %eax
f010269c:	68 be 03 00 00       	push   $0x3be
f01026a1:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f01026a7:	50                   	push   %eax
f01026a8:	e8 36 da ff ff       	call   f01000e3 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01026ad:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026b0:	8d 83 50 9c f7 ff    	lea    -0x863b0(%ebx),%eax
f01026b6:	50                   	push   %eax
f01026b7:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f01026bd:	50                   	push   %eax
f01026be:	68 c1 03 00 00       	push   $0x3c1
f01026c3:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f01026c9:	50                   	push   %eax
f01026ca:	e8 14 da ff ff       	call   f01000e3 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01026cf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026d2:	8d 83 8c 9c f7 ff    	lea    -0x86374(%ebx),%eax
f01026d8:	50                   	push   %eax
f01026d9:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f01026df:	50                   	push   %eax
f01026e0:	68 c2 03 00 00       	push   $0x3c2
f01026e5:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f01026eb:	50                   	push   %eax
f01026ec:	e8 f2 d9 ff ff       	call   f01000e3 <_panic>
	assert(pp2->pp_ref == 1);
f01026f1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026f4:	8d 83 a0 98 f7 ff    	lea    -0x86760(%ebx),%eax
f01026fa:	50                   	push   %eax
f01026fb:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102701:	50                   	push   %eax
f0102702:	68 c3 03 00 00       	push   $0x3c3
f0102707:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f010270d:	50                   	push   %eax
f010270e:	e8 d0 d9 ff ff       	call   f01000e3 <_panic>
	assert(!page_alloc(0));
f0102713:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102716:	8d 83 2c 98 f7 ff    	lea    -0x867d4(%ebx),%eax
f010271c:	50                   	push   %eax
f010271d:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102723:	50                   	push   %eax
f0102724:	68 c7 03 00 00       	push   $0x3c7
f0102729:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f010272f:	50                   	push   %eax
f0102730:	e8 ae d9 ff ff       	call   f01000e3 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102735:	50                   	push   %eax
f0102736:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102739:	8d 83 94 99 f7 ff    	lea    -0x8666c(%ebx),%eax
f010273f:	50                   	push   %eax
f0102740:	68 ca 03 00 00       	push   $0x3ca
f0102745:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f010274b:	50                   	push   %eax
f010274c:	e8 92 d9 ff ff       	call   f01000e3 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102751:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102754:	8d 83 bc 9c f7 ff    	lea    -0x86344(%ebx),%eax
f010275a:	50                   	push   %eax
f010275b:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102761:	50                   	push   %eax
f0102762:	68 cb 03 00 00       	push   $0x3cb
f0102767:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f010276d:	50                   	push   %eax
f010276e:	e8 70 d9 ff ff       	call   f01000e3 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102773:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102776:	8d 83 fc 9c f7 ff    	lea    -0x86304(%ebx),%eax
f010277c:	50                   	push   %eax
f010277d:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102783:	50                   	push   %eax
f0102784:	68 ce 03 00 00       	push   $0x3ce
f0102789:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f010278f:	50                   	push   %eax
f0102790:	e8 4e d9 ff ff       	call   f01000e3 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102795:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102798:	8d 83 8c 9c f7 ff    	lea    -0x86374(%ebx),%eax
f010279e:	50                   	push   %eax
f010279f:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f01027a5:	50                   	push   %eax
f01027a6:	68 cf 03 00 00       	push   $0x3cf
f01027ab:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f01027b1:	50                   	push   %eax
f01027b2:	e8 2c d9 ff ff       	call   f01000e3 <_panic>
	assert(pp2->pp_ref == 1);
f01027b7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027ba:	8d 83 a0 98 f7 ff    	lea    -0x86760(%ebx),%eax
f01027c0:	50                   	push   %eax
f01027c1:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f01027c7:	50                   	push   %eax
f01027c8:	68 d0 03 00 00       	push   $0x3d0
f01027cd:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f01027d3:	50                   	push   %eax
f01027d4:	e8 0a d9 ff ff       	call   f01000e3 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01027d9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027dc:	8d 83 3c 9d f7 ff    	lea    -0x862c4(%ebx),%eax
f01027e2:	50                   	push   %eax
f01027e3:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f01027e9:	50                   	push   %eax
f01027ea:	68 d1 03 00 00       	push   $0x3d1
f01027ef:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f01027f5:	50                   	push   %eax
f01027f6:	e8 e8 d8 ff ff       	call   f01000e3 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01027fb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027fe:	8d 83 b1 98 f7 ff    	lea    -0x8674f(%ebx),%eax
f0102804:	50                   	push   %eax
f0102805:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f010280b:	50                   	push   %eax
f010280c:	68 d2 03 00 00       	push   $0x3d2
f0102811:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102817:	50                   	push   %eax
f0102818:	e8 c6 d8 ff ff       	call   f01000e3 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010281d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102820:	8d 83 50 9c f7 ff    	lea    -0x863b0(%ebx),%eax
f0102826:	50                   	push   %eax
f0102827:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f010282d:	50                   	push   %eax
f010282e:	68 d5 03 00 00       	push   $0x3d5
f0102833:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102839:	50                   	push   %eax
f010283a:	e8 a4 d8 ff ff       	call   f01000e3 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f010283f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102842:	8d 83 70 9d f7 ff    	lea    -0x86290(%ebx),%eax
f0102848:	50                   	push   %eax
f0102849:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f010284f:	50                   	push   %eax
f0102850:	68 d6 03 00 00       	push   $0x3d6
f0102855:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f010285b:	50                   	push   %eax
f010285c:	e8 82 d8 ff ff       	call   f01000e3 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102861:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102864:	8d 83 a4 9d f7 ff    	lea    -0x8625c(%ebx),%eax
f010286a:	50                   	push   %eax
f010286b:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102871:	50                   	push   %eax
f0102872:	68 d7 03 00 00       	push   $0x3d7
f0102877:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f010287d:	50                   	push   %eax
f010287e:	e8 60 d8 ff ff       	call   f01000e3 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102883:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102886:	8d 83 dc 9d f7 ff    	lea    -0x86224(%ebx),%eax
f010288c:	50                   	push   %eax
f010288d:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102893:	50                   	push   %eax
f0102894:	68 da 03 00 00       	push   $0x3da
f0102899:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f010289f:	50                   	push   %eax
f01028a0:	e8 3e d8 ff ff       	call   f01000e3 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f01028a5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028a8:	8d 83 14 9e f7 ff    	lea    -0x861ec(%ebx),%eax
f01028ae:	50                   	push   %eax
f01028af:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f01028b5:	50                   	push   %eax
f01028b6:	68 dd 03 00 00       	push   $0x3dd
f01028bb:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f01028c1:	50                   	push   %eax
f01028c2:	e8 1c d8 ff ff       	call   f01000e3 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01028c7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028ca:	8d 83 a4 9d f7 ff    	lea    -0x8625c(%ebx),%eax
f01028d0:	50                   	push   %eax
f01028d1:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f01028d7:	50                   	push   %eax
f01028d8:	68 de 03 00 00       	push   $0x3de
f01028dd:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f01028e3:	50                   	push   %eax
f01028e4:	e8 fa d7 ff ff       	call   f01000e3 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01028e9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028ec:	8d 83 50 9e f7 ff    	lea    -0x861b0(%ebx),%eax
f01028f2:	50                   	push   %eax
f01028f3:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f01028f9:	50                   	push   %eax
f01028fa:	68 e1 03 00 00       	push   $0x3e1
f01028ff:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102905:	50                   	push   %eax
f0102906:	e8 d8 d7 ff ff       	call   f01000e3 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010290b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010290e:	8d 83 7c 9e f7 ff    	lea    -0x86184(%ebx),%eax
f0102914:	50                   	push   %eax
f0102915:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f010291b:	50                   	push   %eax
f010291c:	68 e2 03 00 00       	push   $0x3e2
f0102921:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102927:	50                   	push   %eax
f0102928:	e8 b6 d7 ff ff       	call   f01000e3 <_panic>
	assert(pp1->pp_ref == 2);
f010292d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102930:	8d 83 c7 98 f7 ff    	lea    -0x86739(%ebx),%eax
f0102936:	50                   	push   %eax
f0102937:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f010293d:	50                   	push   %eax
f010293e:	68 e4 03 00 00       	push   $0x3e4
f0102943:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102949:	50                   	push   %eax
f010294a:	e8 94 d7 ff ff       	call   f01000e3 <_panic>
	assert(pp2->pp_ref == 0);
f010294f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102952:	8d 83 d8 98 f7 ff    	lea    -0x86728(%ebx),%eax
f0102958:	50                   	push   %eax
f0102959:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f010295f:	50                   	push   %eax
f0102960:	68 e5 03 00 00       	push   $0x3e5
f0102965:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f010296b:	50                   	push   %eax
f010296c:	e8 72 d7 ff ff       	call   f01000e3 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f0102971:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102974:	8d 83 ac 9e f7 ff    	lea    -0x86154(%ebx),%eax
f010297a:	50                   	push   %eax
f010297b:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102981:	50                   	push   %eax
f0102982:	68 e8 03 00 00       	push   $0x3e8
f0102987:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f010298d:	50                   	push   %eax
f010298e:	e8 50 d7 ff ff       	call   f01000e3 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102993:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102996:	8d 83 d0 9e f7 ff    	lea    -0x86130(%ebx),%eax
f010299c:	50                   	push   %eax
f010299d:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f01029a3:	50                   	push   %eax
f01029a4:	68 ec 03 00 00       	push   $0x3ec
f01029a9:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f01029af:	50                   	push   %eax
f01029b0:	e8 2e d7 ff ff       	call   f01000e3 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01029b5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029b8:	8d 83 7c 9e f7 ff    	lea    -0x86184(%ebx),%eax
f01029be:	50                   	push   %eax
f01029bf:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f01029c5:	50                   	push   %eax
f01029c6:	68 ed 03 00 00       	push   $0x3ed
f01029cb:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f01029d1:	50                   	push   %eax
f01029d2:	e8 0c d7 ff ff       	call   f01000e3 <_panic>
	assert(pp1->pp_ref == 1);
f01029d7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029da:	8d 83 7e 98 f7 ff    	lea    -0x86782(%ebx),%eax
f01029e0:	50                   	push   %eax
f01029e1:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f01029e7:	50                   	push   %eax
f01029e8:	68 ee 03 00 00       	push   $0x3ee
f01029ed:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f01029f3:	50                   	push   %eax
f01029f4:	e8 ea d6 ff ff       	call   f01000e3 <_panic>
	assert(pp2->pp_ref == 0);
f01029f9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029fc:	8d 83 d8 98 f7 ff    	lea    -0x86728(%ebx),%eax
f0102a02:	50                   	push   %eax
f0102a03:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102a09:	50                   	push   %eax
f0102a0a:	68 ef 03 00 00       	push   $0x3ef
f0102a0f:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102a15:	50                   	push   %eax
f0102a16:	e8 c8 d6 ff ff       	call   f01000e3 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102a1b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a1e:	8d 83 f4 9e f7 ff    	lea    -0x8610c(%ebx),%eax
f0102a24:	50                   	push   %eax
f0102a25:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102a2b:	50                   	push   %eax
f0102a2c:	68 f2 03 00 00       	push   $0x3f2
f0102a31:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102a37:	50                   	push   %eax
f0102a38:	e8 a6 d6 ff ff       	call   f01000e3 <_panic>
	assert(pp1->pp_ref);
f0102a3d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a40:	8d 83 e9 98 f7 ff    	lea    -0x86717(%ebx),%eax
f0102a46:	50                   	push   %eax
f0102a47:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102a4d:	50                   	push   %eax
f0102a4e:	68 f3 03 00 00       	push   $0x3f3
f0102a53:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102a59:	50                   	push   %eax
f0102a5a:	e8 84 d6 ff ff       	call   f01000e3 <_panic>
	assert(pp1->pp_link == NULL);
f0102a5f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a62:	8d 83 f5 98 f7 ff    	lea    -0x8670b(%ebx),%eax
f0102a68:	50                   	push   %eax
f0102a69:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102a6f:	50                   	push   %eax
f0102a70:	68 f4 03 00 00       	push   $0x3f4
f0102a75:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102a7b:	50                   	push   %eax
f0102a7c:	e8 62 d6 ff ff       	call   f01000e3 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102a81:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a84:	8d 83 d0 9e f7 ff    	lea    -0x86130(%ebx),%eax
f0102a8a:	50                   	push   %eax
f0102a8b:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102a91:	50                   	push   %eax
f0102a92:	68 f8 03 00 00       	push   $0x3f8
f0102a97:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102a9d:	50                   	push   %eax
f0102a9e:	e8 40 d6 ff ff       	call   f01000e3 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102aa3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102aa6:	8d 83 2c 9f f7 ff    	lea    -0x860d4(%ebx),%eax
f0102aac:	50                   	push   %eax
f0102aad:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102ab3:	50                   	push   %eax
f0102ab4:	68 f9 03 00 00       	push   $0x3f9
f0102ab9:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102abf:	50                   	push   %eax
f0102ac0:	e8 1e d6 ff ff       	call   f01000e3 <_panic>
	assert(pp1->pp_ref == 0);
f0102ac5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ac8:	8d 83 0a 99 f7 ff    	lea    -0x866f6(%ebx),%eax
f0102ace:	50                   	push   %eax
f0102acf:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102ad5:	50                   	push   %eax
f0102ad6:	68 fa 03 00 00       	push   $0x3fa
f0102adb:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102ae1:	50                   	push   %eax
f0102ae2:	e8 fc d5 ff ff       	call   f01000e3 <_panic>
	assert(pp2->pp_ref == 0);
f0102ae7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102aea:	8d 83 d8 98 f7 ff    	lea    -0x86728(%ebx),%eax
f0102af0:	50                   	push   %eax
f0102af1:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102af7:	50                   	push   %eax
f0102af8:	68 fb 03 00 00       	push   $0x3fb
f0102afd:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102b03:	50                   	push   %eax
f0102b04:	e8 da d5 ff ff       	call   f01000e3 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f0102b09:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b0c:	8d 83 54 9f f7 ff    	lea    -0x860ac(%ebx),%eax
f0102b12:	50                   	push   %eax
f0102b13:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102b19:	50                   	push   %eax
f0102b1a:	68 fe 03 00 00       	push   $0x3fe
f0102b1f:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102b25:	50                   	push   %eax
f0102b26:	e8 b8 d5 ff ff       	call   f01000e3 <_panic>
	assert(!page_alloc(0));
f0102b2b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b2e:	8d 83 2c 98 f7 ff    	lea    -0x867d4(%ebx),%eax
f0102b34:	50                   	push   %eax
f0102b35:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102b3b:	50                   	push   %eax
f0102b3c:	68 01 04 00 00       	push   $0x401
f0102b41:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102b47:	50                   	push   %eax
f0102b48:	e8 96 d5 ff ff       	call   f01000e3 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102b4d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b50:	8d 83 f8 9b f7 ff    	lea    -0x86408(%ebx),%eax
f0102b56:	50                   	push   %eax
f0102b57:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102b5d:	50                   	push   %eax
f0102b5e:	68 04 04 00 00       	push   $0x404
f0102b63:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102b69:	50                   	push   %eax
f0102b6a:	e8 74 d5 ff ff       	call   f01000e3 <_panic>
	assert(pp0->pp_ref == 1);
f0102b6f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b72:	8d 83 8f 98 f7 ff    	lea    -0x86771(%ebx),%eax
f0102b78:	50                   	push   %eax
f0102b79:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102b7f:	50                   	push   %eax
f0102b80:	68 06 04 00 00       	push   $0x406
f0102b85:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102b8b:	50                   	push   %eax
f0102b8c:	e8 52 d5 ff ff       	call   f01000e3 <_panic>
f0102b91:	52                   	push   %edx
f0102b92:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b95:	8d 83 94 99 f7 ff    	lea    -0x8666c(%ebx),%eax
f0102b9b:	50                   	push   %eax
f0102b9c:	68 0d 04 00 00       	push   $0x40d
f0102ba1:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102ba7:	50                   	push   %eax
f0102ba8:	e8 36 d5 ff ff       	call   f01000e3 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102bad:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102bb0:	8d 83 1b 99 f7 ff    	lea    -0x866e5(%ebx),%eax
f0102bb6:	50                   	push   %eax
f0102bb7:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102bbd:	50                   	push   %eax
f0102bbe:	68 0e 04 00 00       	push   $0x40e
f0102bc3:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102bc9:	50                   	push   %eax
f0102bca:	e8 14 d5 ff ff       	call   f01000e3 <_panic>
f0102bcf:	50                   	push   %eax
f0102bd0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102bd3:	8d 83 94 99 f7 ff    	lea    -0x8666c(%ebx),%eax
f0102bd9:	50                   	push   %eax
f0102bda:	6a 56                	push   $0x56
f0102bdc:	8d 83 82 96 f7 ff    	lea    -0x8697e(%ebx),%eax
f0102be2:	50                   	push   %eax
f0102be3:	e8 fb d4 ff ff       	call   f01000e3 <_panic>
f0102be8:	52                   	push   %edx
f0102be9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102bec:	8d 83 94 99 f7 ff    	lea    -0x8666c(%ebx),%eax
f0102bf2:	50                   	push   %eax
f0102bf3:	6a 56                	push   $0x56
f0102bf5:	8d 83 82 96 f7 ff    	lea    -0x8697e(%ebx),%eax
f0102bfb:	50                   	push   %eax
f0102bfc:	e8 e2 d4 ff ff       	call   f01000e3 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f0102c01:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c04:	8d 83 33 99 f7 ff    	lea    -0x866cd(%ebx),%eax
f0102c0a:	50                   	push   %eax
f0102c0b:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102c11:	50                   	push   %eax
f0102c12:	68 18 04 00 00       	push   $0x418
f0102c17:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102c1d:	50                   	push   %eax
f0102c1e:	e8 c0 d4 ff ff       	call   f01000e3 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c23:	50                   	push   %eax
f0102c24:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c27:	8d 83 a0 9a f7 ff    	lea    -0x86560(%ebx),%eax
f0102c2d:	50                   	push   %eax
f0102c2e:	68 c4 00 00 00       	push   $0xc4
f0102c33:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102c39:	50                   	push   %eax
f0102c3a:	e8 a4 d4 ff ff       	call   f01000e3 <_panic>
f0102c3f:	50                   	push   %eax
f0102c40:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c43:	8d 83 a0 9a f7 ff    	lea    -0x86560(%ebx),%eax
f0102c49:	50                   	push   %eax
f0102c4a:	68 d1 00 00 00       	push   $0xd1
f0102c4f:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102c55:	50                   	push   %eax
f0102c56:	e8 88 d4 ff ff       	call   f01000e3 <_panic>
f0102c5b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c5e:	ff b3 fc ff ff ff    	pushl  -0x4(%ebx)
f0102c64:	8d 83 a0 9a f7 ff    	lea    -0x86560(%ebx),%eax
f0102c6a:	50                   	push   %eax
f0102c6b:	68 e2 00 00 00       	push   $0xe2
f0102c70:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102c76:	50                   	push   %eax
f0102c77:	e8 67 d4 ff ff       	call   f01000e3 <_panic>
f0102c7c:	ff 75 c0             	pushl  -0x40(%ebp)
f0102c7f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c82:	8d 83 a0 9a f7 ff    	lea    -0x86560(%ebx),%eax
f0102c88:	50                   	push   %eax
f0102c89:	68 55 03 00 00       	push   $0x355
f0102c8e:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102c94:	50                   	push   %eax
f0102c95:	e8 49 d4 ff ff       	call   f01000e3 <_panic>
	for (i = 0; i < n; i += PGSIZE)
f0102c9a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102ca0:	39 5d d0             	cmp    %ebx,-0x30(%ebp)
f0102ca3:	76 3f                	jbe    f0102ce4 <mem_init+0x1780>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102ca5:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102cab:	89 f0                	mov    %esi,%eax
f0102cad:	e8 ec de ff ff       	call   f0100b9e <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f0102cb2:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f0102cb9:	76 c1                	jbe    f0102c7c <mem_init+0x1718>
f0102cbb:	8d 14 3b             	lea    (%ebx,%edi,1),%edx
f0102cbe:	39 d0                	cmp    %edx,%eax
f0102cc0:	74 d8                	je     f0102c9a <mem_init+0x1736>
f0102cc2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102cc5:	8d 83 78 9f f7 ff    	lea    -0x86088(%ebx),%eax
f0102ccb:	50                   	push   %eax
f0102ccc:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102cd2:	50                   	push   %eax
f0102cd3:	68 55 03 00 00       	push   $0x355
f0102cd8:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102cde:	50                   	push   %eax
f0102cdf:	e8 ff d3 ff ff       	call   f01000e3 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102ce4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ce7:	c7 c0 48 e3 18 f0    	mov    $0xf018e348,%eax
f0102ced:	8b 00                	mov    (%eax),%eax
f0102cef:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102cf2:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102cf5:	bf 00 00 c0 ee       	mov    $0xeec00000,%edi
f0102cfa:	8d 98 00 00 40 21    	lea    0x21400000(%eax),%ebx
f0102d00:	89 fa                	mov    %edi,%edx
f0102d02:	89 f0                	mov    %esi,%eax
f0102d04:	e8 95 de ff ff       	call   f0100b9e <check_va2pa>
f0102d09:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102d10:	76 3d                	jbe    f0102d4f <mem_init+0x17eb>
f0102d12:	8d 14 3b             	lea    (%ebx,%edi,1),%edx
f0102d15:	39 d0                	cmp    %edx,%eax
f0102d17:	75 54                	jne    f0102d6d <mem_init+0x1809>
f0102d19:	81 c7 00 10 00 00    	add    $0x1000,%edi
	for (i = 0; i < n; i += PGSIZE)
f0102d1f:	81 ff 00 80 c1 ee    	cmp    $0xeec18000,%edi
f0102d25:	75 d9                	jne    f0102d00 <mem_init+0x179c>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102d27:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102d2a:	c1 e7 0c             	shl    $0xc,%edi
f0102d2d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102d32:	39 fb                	cmp    %edi,%ebx
f0102d34:	73 7b                	jae    f0102db1 <mem_init+0x184d>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102d36:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102d3c:	89 f0                	mov    %esi,%eax
f0102d3e:	e8 5b de ff ff       	call   f0100b9e <check_va2pa>
f0102d43:	39 c3                	cmp    %eax,%ebx
f0102d45:	75 48                	jne    f0102d8f <mem_init+0x182b>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102d47:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102d4d:	eb e3                	jmp    f0102d32 <mem_init+0x17ce>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d4f:	ff 75 cc             	pushl  -0x34(%ebp)
f0102d52:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d55:	8d 83 a0 9a f7 ff    	lea    -0x86560(%ebx),%eax
f0102d5b:	50                   	push   %eax
f0102d5c:	68 5a 03 00 00       	push   $0x35a
f0102d61:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102d67:	50                   	push   %eax
f0102d68:	e8 76 d3 ff ff       	call   f01000e3 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102d6d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d70:	8d 83 ac 9f f7 ff    	lea    -0x86054(%ebx),%eax
f0102d76:	50                   	push   %eax
f0102d77:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102d7d:	50                   	push   %eax
f0102d7e:	68 5a 03 00 00       	push   $0x35a
f0102d83:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102d89:	50                   	push   %eax
f0102d8a:	e8 54 d3 ff ff       	call   f01000e3 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102d8f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d92:	8d 83 e0 9f f7 ff    	lea    -0x86020(%ebx),%eax
f0102d98:	50                   	push   %eax
f0102d99:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102d9f:	50                   	push   %eax
f0102da0:	68 5e 03 00 00       	push   $0x35e
f0102da5:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102dab:	50                   	push   %eax
f0102dac:	e8 32 d3 ff ff       	call   f01000e3 <_panic>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102db1:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102db6:	8b 7d c8             	mov    -0x38(%ebp),%edi
f0102db9:	81 c7 00 80 00 20    	add    $0x20008000,%edi
f0102dbf:	89 da                	mov    %ebx,%edx
f0102dc1:	89 f0                	mov    %esi,%eax
f0102dc3:	e8 d6 dd ff ff       	call   f0100b9e <check_va2pa>
f0102dc8:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
f0102dcb:	39 c2                	cmp    %eax,%edx
f0102dcd:	75 26                	jne    f0102df5 <mem_init+0x1891>
f0102dcf:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102dd5:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102ddb:	75 e2                	jne    f0102dbf <mem_init+0x185b>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102ddd:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102de2:	89 f0                	mov    %esi,%eax
f0102de4:	e8 b5 dd ff ff       	call   f0100b9e <check_va2pa>
f0102de9:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102dec:	75 29                	jne    f0102e17 <mem_init+0x18b3>
	for (i = 0; i < NPDENTRIES; i++) {
f0102dee:	b8 00 00 00 00       	mov    $0x0,%eax
f0102df3:	eb 6d                	jmp    f0102e62 <mem_init+0x18fe>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102df5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102df8:	8d 83 08 a0 f7 ff    	lea    -0x85ff8(%ebx),%eax
f0102dfe:	50                   	push   %eax
f0102dff:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102e05:	50                   	push   %eax
f0102e06:	68 62 03 00 00       	push   $0x362
f0102e0b:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102e11:	50                   	push   %eax
f0102e12:	e8 cc d2 ff ff       	call   f01000e3 <_panic>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102e17:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e1a:	8d 83 50 a0 f7 ff    	lea    -0x85fb0(%ebx),%eax
f0102e20:	50                   	push   %eax
f0102e21:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102e27:	50                   	push   %eax
f0102e28:	68 63 03 00 00       	push   $0x363
f0102e2d:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102e33:	50                   	push   %eax
f0102e34:	e8 aa d2 ff ff       	call   f01000e3 <_panic>
			assert(pgdir[i] & PTE_P);
f0102e39:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102e3d:	74 52                	je     f0102e91 <mem_init+0x192d>
	for (i = 0; i < NPDENTRIES; i++) {
f0102e3f:	83 c0 01             	add    $0x1,%eax
f0102e42:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102e47:	0f 87 bb 00 00 00    	ja     f0102f08 <mem_init+0x19a4>
		switch (i) {
f0102e4d:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102e52:	72 0e                	jb     f0102e62 <mem_init+0x18fe>
f0102e54:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102e59:	76 de                	jbe    f0102e39 <mem_init+0x18d5>
f0102e5b:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102e60:	74 d7                	je     f0102e39 <mem_init+0x18d5>
			if (i >= PDX(KERNBASE)) {
f0102e62:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102e67:	77 4a                	ja     f0102eb3 <mem_init+0x194f>
				assert(pgdir[i] == 0);
f0102e69:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102e6d:	74 d0                	je     f0102e3f <mem_init+0x18db>
f0102e6f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e72:	8d 83 85 99 f7 ff    	lea    -0x8667b(%ebx),%eax
f0102e78:	50                   	push   %eax
f0102e79:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102e7f:	50                   	push   %eax
f0102e80:	68 73 03 00 00       	push   $0x373
f0102e85:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102e8b:	50                   	push   %eax
f0102e8c:	e8 52 d2 ff ff       	call   f01000e3 <_panic>
			assert(pgdir[i] & PTE_P);
f0102e91:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e94:	8d 83 63 99 f7 ff    	lea    -0x8669d(%ebx),%eax
f0102e9a:	50                   	push   %eax
f0102e9b:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102ea1:	50                   	push   %eax
f0102ea2:	68 6c 03 00 00       	push   $0x36c
f0102ea7:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102ead:	50                   	push   %eax
f0102eae:	e8 30 d2 ff ff       	call   f01000e3 <_panic>
				assert(pgdir[i] & PTE_P);
f0102eb3:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102eb6:	f6 c2 01             	test   $0x1,%dl
f0102eb9:	74 2b                	je     f0102ee6 <mem_init+0x1982>
				assert(pgdir[i] & PTE_W);
f0102ebb:	f6 c2 02             	test   $0x2,%dl
f0102ebe:	0f 85 7b ff ff ff    	jne    f0102e3f <mem_init+0x18db>
f0102ec4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ec7:	8d 83 74 99 f7 ff    	lea    -0x8668c(%ebx),%eax
f0102ecd:	50                   	push   %eax
f0102ece:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102ed4:	50                   	push   %eax
f0102ed5:	68 71 03 00 00       	push   $0x371
f0102eda:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102ee0:	50                   	push   %eax
f0102ee1:	e8 fd d1 ff ff       	call   f01000e3 <_panic>
				assert(pgdir[i] & PTE_P);
f0102ee6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ee9:	8d 83 63 99 f7 ff    	lea    -0x8669d(%ebx),%eax
f0102eef:	50                   	push   %eax
f0102ef0:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0102ef6:	50                   	push   %eax
f0102ef7:	68 70 03 00 00       	push   $0x370
f0102efc:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0102f02:	50                   	push   %eax
f0102f03:	e8 db d1 ff ff       	call   f01000e3 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102f08:	83 ec 0c             	sub    $0xc,%esp
f0102f0b:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0102f0e:	8d 86 80 a0 f7 ff    	lea    -0x85f80(%esi),%eax
f0102f14:	50                   	push   %eax
f0102f15:	89 f3                	mov    %esi,%ebx
f0102f17:	e8 3c 0d 00 00       	call   f0103c58 <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102f1c:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f0102f22:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102f24:	83 c4 10             	add    $0x10,%esp
f0102f27:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102f2c:	0f 86 44 02 00 00    	jbe    f0103176 <mem_init+0x1c12>
	return (physaddr_t)kva - KERNBASE;
f0102f32:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102f37:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102f3a:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f3f:	e8 d7 dc ff ff       	call   f0100c1b <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102f44:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102f47:	83 e0 f3             	and    $0xfffffff3,%eax
f0102f4a:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102f4f:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102f52:	83 ec 0c             	sub    $0xc,%esp
f0102f55:	6a 00                	push   $0x0
f0102f57:	e8 a9 e1 ff ff       	call   f0101105 <page_alloc>
f0102f5c:	89 c6                	mov    %eax,%esi
f0102f5e:	83 c4 10             	add    $0x10,%esp
f0102f61:	85 c0                	test   %eax,%eax
f0102f63:	0f 84 29 02 00 00    	je     f0103192 <mem_init+0x1c2e>
	assert((pp1 = page_alloc(0)));
f0102f69:	83 ec 0c             	sub    $0xc,%esp
f0102f6c:	6a 00                	push   $0x0
f0102f6e:	e8 92 e1 ff ff       	call   f0101105 <page_alloc>
f0102f73:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102f76:	83 c4 10             	add    $0x10,%esp
f0102f79:	85 c0                	test   %eax,%eax
f0102f7b:	0f 84 33 02 00 00    	je     f01031b4 <mem_init+0x1c50>
	assert((pp2 = page_alloc(0)));
f0102f81:	83 ec 0c             	sub    $0xc,%esp
f0102f84:	6a 00                	push   $0x0
f0102f86:	e8 7a e1 ff ff       	call   f0101105 <page_alloc>
f0102f8b:	89 c7                	mov    %eax,%edi
f0102f8d:	83 c4 10             	add    $0x10,%esp
f0102f90:	85 c0                	test   %eax,%eax
f0102f92:	0f 84 3e 02 00 00    	je     f01031d6 <mem_init+0x1c72>
	page_free(pp0);
f0102f98:	83 ec 0c             	sub    $0xc,%esp
f0102f9b:	56                   	push   %esi
f0102f9c:	e8 f2 e1 ff ff       	call   f0101193 <page_free>
	return (pp - pages) << PGSHIFT;
f0102fa1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102fa4:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0102faa:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102fad:	2b 08                	sub    (%eax),%ecx
f0102faf:	89 c8                	mov    %ecx,%eax
f0102fb1:	c1 f8 03             	sar    $0x3,%eax
f0102fb4:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102fb7:	89 c1                	mov    %eax,%ecx
f0102fb9:	c1 e9 0c             	shr    $0xc,%ecx
f0102fbc:	83 c4 10             	add    $0x10,%esp
f0102fbf:	c7 c2 04 f0 18 f0    	mov    $0xf018f004,%edx
f0102fc5:	3b 0a                	cmp    (%edx),%ecx
f0102fc7:	0f 83 2b 02 00 00    	jae    f01031f8 <mem_init+0x1c94>
	memset(page2kva(pp1), 1, PGSIZE);
f0102fcd:	83 ec 04             	sub    $0x4,%esp
f0102fd0:	68 00 10 00 00       	push   $0x1000
f0102fd5:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102fd7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102fdc:	50                   	push   %eax
f0102fdd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102fe0:	e8 22 1d 00 00       	call   f0104d07 <memset>
	return (pp - pages) << PGSHIFT;
f0102fe5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102fe8:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0102fee:	89 f9                	mov    %edi,%ecx
f0102ff0:	2b 08                	sub    (%eax),%ecx
f0102ff2:	89 c8                	mov    %ecx,%eax
f0102ff4:	c1 f8 03             	sar    $0x3,%eax
f0102ff7:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102ffa:	89 c1                	mov    %eax,%ecx
f0102ffc:	c1 e9 0c             	shr    $0xc,%ecx
f0102fff:	83 c4 10             	add    $0x10,%esp
f0103002:	c7 c2 04 f0 18 f0    	mov    $0xf018f004,%edx
f0103008:	3b 0a                	cmp    (%edx),%ecx
f010300a:	0f 83 fe 01 00 00    	jae    f010320e <mem_init+0x1caa>
	memset(page2kva(pp2), 2, PGSIZE);
f0103010:	83 ec 04             	sub    $0x4,%esp
f0103013:	68 00 10 00 00       	push   $0x1000
f0103018:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f010301a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010301f:	50                   	push   %eax
f0103020:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103023:	e8 df 1c 00 00       	call   f0104d07 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0103028:	6a 02                	push   $0x2
f010302a:	68 00 10 00 00       	push   $0x1000
f010302f:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0103032:	53                   	push   %ebx
f0103033:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103036:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f010303c:	ff 30                	pushl  (%eax)
f010303e:	e8 5d e4 ff ff       	call   f01014a0 <page_insert>
	assert(pp1->pp_ref == 1);
f0103043:	83 c4 20             	add    $0x20,%esp
f0103046:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010304b:	0f 85 d3 01 00 00    	jne    f0103224 <mem_init+0x1cc0>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0103051:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0103058:	01 01 01 
f010305b:	0f 85 e5 01 00 00    	jne    f0103246 <mem_init+0x1ce2>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0103061:	6a 02                	push   $0x2
f0103063:	68 00 10 00 00       	push   $0x1000
f0103068:	57                   	push   %edi
f0103069:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010306c:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f0103072:	ff 30                	pushl  (%eax)
f0103074:	e8 27 e4 ff ff       	call   f01014a0 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0103079:	83 c4 10             	add    $0x10,%esp
f010307c:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0103083:	02 02 02 
f0103086:	0f 85 dc 01 00 00    	jne    f0103268 <mem_init+0x1d04>
	assert(pp2->pp_ref == 1);
f010308c:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0103091:	0f 85 f3 01 00 00    	jne    f010328a <mem_init+0x1d26>
	assert(pp1->pp_ref == 0);
f0103097:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010309a:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f010309f:	0f 85 07 02 00 00    	jne    f01032ac <mem_init+0x1d48>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01030a5:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01030ac:	03 03 03 
	return (pp - pages) << PGSHIFT;
f01030af:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01030b2:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f01030b8:	89 f9                	mov    %edi,%ecx
f01030ba:	2b 08                	sub    (%eax),%ecx
f01030bc:	89 c8                	mov    %ecx,%eax
f01030be:	c1 f8 03             	sar    $0x3,%eax
f01030c1:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01030c4:	89 c1                	mov    %eax,%ecx
f01030c6:	c1 e9 0c             	shr    $0xc,%ecx
f01030c9:	c7 c2 04 f0 18 f0    	mov    $0xf018f004,%edx
f01030cf:	3b 0a                	cmp    (%edx),%ecx
f01030d1:	0f 83 f7 01 00 00    	jae    f01032ce <mem_init+0x1d6a>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01030d7:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01030de:	03 03 03 
f01030e1:	0f 85 fd 01 00 00    	jne    f01032e4 <mem_init+0x1d80>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01030e7:	83 ec 08             	sub    $0x8,%esp
f01030ea:	68 00 10 00 00       	push   $0x1000
f01030ef:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01030f2:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f01030f8:	ff 30                	pushl  (%eax)
f01030fa:	e8 4a e3 ff ff       	call   f0101449 <page_remove>
	assert(pp2->pp_ref == 0);
f01030ff:	83 c4 10             	add    $0x10,%esp
f0103102:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0103107:	0f 85 f9 01 00 00    	jne    f0103306 <mem_init+0x1da2>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010310d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103110:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f0103116:	8b 08                	mov    (%eax),%ecx
f0103118:	8b 11                	mov    (%ecx),%edx
f010311a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0103120:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f0103126:	89 f7                	mov    %esi,%edi
f0103128:	2b 38                	sub    (%eax),%edi
f010312a:	89 f8                	mov    %edi,%eax
f010312c:	c1 f8 03             	sar    $0x3,%eax
f010312f:	c1 e0 0c             	shl    $0xc,%eax
f0103132:	39 c2                	cmp    %eax,%edx
f0103134:	0f 85 ee 01 00 00    	jne    f0103328 <mem_init+0x1dc4>
	kern_pgdir[0] = 0;
f010313a:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0103140:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0103145:	0f 85 ff 01 00 00    	jne    f010334a <mem_init+0x1de6>
	pp0->pp_ref = 0;
f010314b:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0103151:	83 ec 0c             	sub    $0xc,%esp
f0103154:	56                   	push   %esi
f0103155:	e8 39 e0 ff ff       	call   f0101193 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f010315a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010315d:	8d 83 14 a1 f7 ff    	lea    -0x85eec(%ebx),%eax
f0103163:	89 04 24             	mov    %eax,(%esp)
f0103166:	e8 ed 0a 00 00       	call   f0103c58 <cprintf>
}
f010316b:	83 c4 10             	add    $0x10,%esp
f010316e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103171:	5b                   	pop    %ebx
f0103172:	5e                   	pop    %esi
f0103173:	5f                   	pop    %edi
f0103174:	5d                   	pop    %ebp
f0103175:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103176:	50                   	push   %eax
f0103177:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010317a:	8d 83 a0 9a f7 ff    	lea    -0x86560(%ebx),%eax
f0103180:	50                   	push   %eax
f0103181:	68 fe 00 00 00       	push   $0xfe
f0103186:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f010318c:	50                   	push   %eax
f010318d:	e8 51 cf ff ff       	call   f01000e3 <_panic>
	assert((pp0 = page_alloc(0)));
f0103192:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103195:	8d 83 81 97 f7 ff    	lea    -0x8687f(%ebx),%eax
f010319b:	50                   	push   %eax
f010319c:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f01031a2:	50                   	push   %eax
f01031a3:	68 33 04 00 00       	push   $0x433
f01031a8:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f01031ae:	50                   	push   %eax
f01031af:	e8 2f cf ff ff       	call   f01000e3 <_panic>
	assert((pp1 = page_alloc(0)));
f01031b4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01031b7:	8d 83 97 97 f7 ff    	lea    -0x86869(%ebx),%eax
f01031bd:	50                   	push   %eax
f01031be:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f01031c4:	50                   	push   %eax
f01031c5:	68 34 04 00 00       	push   $0x434
f01031ca:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f01031d0:	50                   	push   %eax
f01031d1:	e8 0d cf ff ff       	call   f01000e3 <_panic>
	assert((pp2 = page_alloc(0)));
f01031d6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01031d9:	8d 83 ad 97 f7 ff    	lea    -0x86853(%ebx),%eax
f01031df:	50                   	push   %eax
f01031e0:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f01031e6:	50                   	push   %eax
f01031e7:	68 35 04 00 00       	push   $0x435
f01031ec:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f01031f2:	50                   	push   %eax
f01031f3:	e8 eb ce ff ff       	call   f01000e3 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01031f8:	50                   	push   %eax
f01031f9:	8d 83 94 99 f7 ff    	lea    -0x8666c(%ebx),%eax
f01031ff:	50                   	push   %eax
f0103200:	6a 56                	push   $0x56
f0103202:	8d 83 82 96 f7 ff    	lea    -0x8697e(%ebx),%eax
f0103208:	50                   	push   %eax
f0103209:	e8 d5 ce ff ff       	call   f01000e3 <_panic>
f010320e:	50                   	push   %eax
f010320f:	8d 83 94 99 f7 ff    	lea    -0x8666c(%ebx),%eax
f0103215:	50                   	push   %eax
f0103216:	6a 56                	push   $0x56
f0103218:	8d 83 82 96 f7 ff    	lea    -0x8697e(%ebx),%eax
f010321e:	50                   	push   %eax
f010321f:	e8 bf ce ff ff       	call   f01000e3 <_panic>
	assert(pp1->pp_ref == 1);
f0103224:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103227:	8d 83 7e 98 f7 ff    	lea    -0x86782(%ebx),%eax
f010322d:	50                   	push   %eax
f010322e:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0103234:	50                   	push   %eax
f0103235:	68 3a 04 00 00       	push   $0x43a
f010323a:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0103240:	50                   	push   %eax
f0103241:	e8 9d ce ff ff       	call   f01000e3 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0103246:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103249:	8d 83 a0 a0 f7 ff    	lea    -0x85f60(%ebx),%eax
f010324f:	50                   	push   %eax
f0103250:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0103256:	50                   	push   %eax
f0103257:	68 3b 04 00 00       	push   $0x43b
f010325c:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0103262:	50                   	push   %eax
f0103263:	e8 7b ce ff ff       	call   f01000e3 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0103268:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010326b:	8d 83 c4 a0 f7 ff    	lea    -0x85f3c(%ebx),%eax
f0103271:	50                   	push   %eax
f0103272:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0103278:	50                   	push   %eax
f0103279:	68 3d 04 00 00       	push   $0x43d
f010327e:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0103284:	50                   	push   %eax
f0103285:	e8 59 ce ff ff       	call   f01000e3 <_panic>
	assert(pp2->pp_ref == 1);
f010328a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010328d:	8d 83 a0 98 f7 ff    	lea    -0x86760(%ebx),%eax
f0103293:	50                   	push   %eax
f0103294:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f010329a:	50                   	push   %eax
f010329b:	68 3e 04 00 00       	push   $0x43e
f01032a0:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f01032a6:	50                   	push   %eax
f01032a7:	e8 37 ce ff ff       	call   f01000e3 <_panic>
	assert(pp1->pp_ref == 0);
f01032ac:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01032af:	8d 83 0a 99 f7 ff    	lea    -0x866f6(%ebx),%eax
f01032b5:	50                   	push   %eax
f01032b6:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f01032bc:	50                   	push   %eax
f01032bd:	68 3f 04 00 00       	push   $0x43f
f01032c2:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f01032c8:	50                   	push   %eax
f01032c9:	e8 15 ce ff ff       	call   f01000e3 <_panic>
f01032ce:	50                   	push   %eax
f01032cf:	8d 83 94 99 f7 ff    	lea    -0x8666c(%ebx),%eax
f01032d5:	50                   	push   %eax
f01032d6:	6a 56                	push   $0x56
f01032d8:	8d 83 82 96 f7 ff    	lea    -0x8697e(%ebx),%eax
f01032de:	50                   	push   %eax
f01032df:	e8 ff cd ff ff       	call   f01000e3 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01032e4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01032e7:	8d 83 e8 a0 f7 ff    	lea    -0x85f18(%ebx),%eax
f01032ed:	50                   	push   %eax
f01032ee:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f01032f4:	50                   	push   %eax
f01032f5:	68 41 04 00 00       	push   $0x441
f01032fa:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0103300:	50                   	push   %eax
f0103301:	e8 dd cd ff ff       	call   f01000e3 <_panic>
	assert(pp2->pp_ref == 0);
f0103306:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103309:	8d 83 d8 98 f7 ff    	lea    -0x86728(%ebx),%eax
f010330f:	50                   	push   %eax
f0103310:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0103316:	50                   	push   %eax
f0103317:	68 43 04 00 00       	push   $0x443
f010331c:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0103322:	50                   	push   %eax
f0103323:	e8 bb cd ff ff       	call   f01000e3 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0103328:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010332b:	8d 83 f8 9b f7 ff    	lea    -0x86408(%ebx),%eax
f0103331:	50                   	push   %eax
f0103332:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0103338:	50                   	push   %eax
f0103339:	68 46 04 00 00       	push   $0x446
f010333e:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0103344:	50                   	push   %eax
f0103345:	e8 99 cd ff ff       	call   f01000e3 <_panic>
	assert(pp0->pp_ref == 1);
f010334a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010334d:	8d 83 8f 98 f7 ff    	lea    -0x86771(%ebx),%eax
f0103353:	50                   	push   %eax
f0103354:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f010335a:	50                   	push   %eax
f010335b:	68 48 04 00 00       	push   $0x448
f0103360:	8d 83 76 96 f7 ff    	lea    -0x8698a(%ebx),%eax
f0103366:	50                   	push   %eax
f0103367:	e8 77 cd ff ff       	call   f01000e3 <_panic>

f010336c <tlb_invalidate>:
{
f010336c:	55                   	push   %ebp
f010336d:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010336f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103372:	0f 01 38             	invlpg (%eax)
}
f0103375:	5d                   	pop    %ebp
f0103376:	c3                   	ret    

f0103377 <user_mem_check>:
{
f0103377:	55                   	push   %ebp
f0103378:	89 e5                	mov    %esp,%ebp
}
f010337a:	b8 00 00 00 00       	mov    $0x0,%eax
f010337f:	5d                   	pop    %ebp
f0103380:	c3                   	ret    

f0103381 <user_mem_assert>:
{
f0103381:	55                   	push   %ebp
f0103382:	89 e5                	mov    %esp,%ebp
}
f0103384:	5d                   	pop    %ebp
f0103385:	c3                   	ret    

f0103386 <__x86.get_pc_thunk.cx>:
f0103386:	8b 0c 24             	mov    (%esp),%ecx
f0103389:	c3                   	ret    

f010338a <__x86.get_pc_thunk.di>:
f010338a:	8b 3c 24             	mov    (%esp),%edi
f010338d:	c3                   	ret    

f010338e <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f010338e:	55                   	push   %ebp
f010338f:	89 e5                	mov    %esp,%ebp
f0103391:	57                   	push   %edi
f0103392:	56                   	push   %esi
f0103393:	53                   	push   %ebx
f0103394:	83 ec 1c             	sub    $0x1c,%esp
f0103397:	e8 fd cd ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f010339c:	81 c3 84 8c 08 00    	add    $0x88c84,%ebx
f01033a2:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)

	// Corner case: e equals to NULL
	if(e == 0)
f01033a5:	85 c0                	test   %eax,%eax
f01033a7:	74 5f                	je     f0103408 <region_alloc+0x7a>
f01033a9:	89 c7                	mov    %eax,%edi
		panic("The struct Env could not be NULL");
	// corner case: len equals to 0
	if(len == 0)
f01033ab:	85 c9                	test   %ecx,%ecx
f01033ad:	0f 84 c1 00 00 00    	je     f0103474 <region_alloc+0xe6>
		return;

	uintptr_t start = (uintptr_t)ROUNDDOWN(va, PGSIZE);
f01033b3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01033b6:	89 c6                	mov    %eax,%esi
f01033b8:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	uintptr_t end = (uintptr_t)ROUNDUP(va + len, PGSIZE);
f01033be:	8d 84 08 ff 0f 00 00 	lea    0xfff(%eax,%ecx,1),%eax
f01033c5:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01033ca:	89 45 e0             	mov    %eax,-0x20(%ebp)
	if(start > end)
f01033cd:	39 c6                	cmp    %eax,%esi
f01033cf:	77 52                	ja     f0103423 <region_alloc+0x95>
	{
		panic("The va_end is too large, and exceeds 32 bit RAM Limit");
	}
	for(uintptr_t vaddr = start; vaddr < end; vaddr += PGSIZE) {
f01033d1:	3b 75 e0             	cmp    -0x20(%ebp),%esi
f01033d4:	0f 83 9a 00 00 00    	jae    f0103474 <region_alloc+0xe6>
		struct PageInfo* pginfo_p = page_alloc(0);
f01033da:	83 ec 0c             	sub    $0xc,%esp
f01033dd:	6a 00                	push   $0x0
f01033df:	e8 21 dd ff ff       	call   f0101105 <page_alloc>
		if (pginfo_p == NULL) {
f01033e4:	83 c4 10             	add    $0x10,%esp
f01033e7:	85 c0                	test   %eax,%eax
f01033e9:	74 53                	je     f010343e <region_alloc+0xb0>
			panic("page_alloc: Cannot allocate physical page");
		}
		if (page_insert(e->env_pgdir, pginfo_p, va, PTE_P | PTE_U | PTE_W) < 0) {
f01033eb:	6a 07                	push   $0x7
f01033ed:	ff 75 e4             	pushl  -0x1c(%ebp)
f01033f0:	50                   	push   %eax
f01033f1:	ff 77 5c             	pushl  0x5c(%edi)
f01033f4:	e8 a7 e0 ff ff       	call   f01014a0 <page_insert>
f01033f9:	83 c4 10             	add    $0x10,%esp
f01033fc:	85 c0                	test   %eax,%eax
f01033fe:	78 59                	js     f0103459 <region_alloc+0xcb>
	for(uintptr_t vaddr = start; vaddr < end; vaddr += PGSIZE) {
f0103400:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0103406:	eb c9                	jmp    f01033d1 <region_alloc+0x43>
		panic("The struct Env could not be NULL");
f0103408:	83 ec 04             	sub    $0x4,%esp
f010340b:	8d 83 40 a1 f7 ff    	lea    -0x85ec0(%ebx),%eax
f0103411:	50                   	push   %eax
f0103412:	68 2b 01 00 00       	push   $0x12b
f0103417:	8d 83 fe a1 f7 ff    	lea    -0x85e02(%ebx),%eax
f010341d:	50                   	push   %eax
f010341e:	e8 c0 cc ff ff       	call   f01000e3 <_panic>
		panic("The va_end is too large, and exceeds 32 bit RAM Limit");
f0103423:	83 ec 04             	sub    $0x4,%esp
f0103426:	8d 83 64 a1 f7 ff    	lea    -0x85e9c(%ebx),%eax
f010342c:	50                   	push   %eax
f010342d:	68 34 01 00 00       	push   $0x134
f0103432:	8d 83 fe a1 f7 ff    	lea    -0x85e02(%ebx),%eax
f0103438:	50                   	push   %eax
f0103439:	e8 a5 cc ff ff       	call   f01000e3 <_panic>
			panic("page_alloc: Cannot allocate physical page");
f010343e:	83 ec 04             	sub    $0x4,%esp
f0103441:	8d 83 9c a1 f7 ff    	lea    -0x85e64(%ebx),%eax
f0103447:	50                   	push   %eax
f0103448:	68 39 01 00 00       	push   $0x139
f010344d:	8d 83 fe a1 f7 ff    	lea    -0x85e02(%ebx),%eax
f0103453:	50                   	push   %eax
f0103454:	e8 8a cc ff ff       	call   f01000e3 <_panic>
			panic("page insertion failed.");
f0103459:	83 ec 04             	sub    $0x4,%esp
f010345c:	8d 83 09 a2 f7 ff    	lea    -0x85df7(%ebx),%eax
f0103462:	50                   	push   %eax
f0103463:	68 3c 01 00 00       	push   $0x13c
f0103468:	8d 83 fe a1 f7 ff    	lea    -0x85e02(%ebx),%eax
f010346e:	50                   	push   %eax
f010346f:	e8 6f cc ff ff       	call   f01000e3 <_panic>
		}
	}
}
f0103474:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103477:	5b                   	pop    %ebx
f0103478:	5e                   	pop    %esi
f0103479:	5f                   	pop    %edi
f010347a:	5d                   	pop    %ebp
f010347b:	c3                   	ret    

f010347c <envid2env>:
{
f010347c:	55                   	push   %ebp
f010347d:	89 e5                	mov    %esp,%ebp
f010347f:	53                   	push   %ebx
f0103480:	e8 01 ff ff ff       	call   f0103386 <__x86.get_pc_thunk.cx>
f0103485:	81 c1 9b 8b 08 00    	add    $0x88b9b,%ecx
f010348b:	8b 55 08             	mov    0x8(%ebp),%edx
f010348e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	if (envid == 0) {
f0103491:	85 d2                	test   %edx,%edx
f0103493:	74 41                	je     f01034d6 <envid2env+0x5a>
	e = &envs[ENVX(envid)];
f0103495:	89 d0                	mov    %edx,%eax
f0103497:	25 ff 03 00 00       	and    $0x3ff,%eax
f010349c:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010349f:	c1 e0 05             	shl    $0x5,%eax
f01034a2:	03 81 28 23 00 00    	add    0x2328(%ecx),%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f01034a8:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f01034ac:	74 3a                	je     f01034e8 <envid2env+0x6c>
f01034ae:	39 50 48             	cmp    %edx,0x48(%eax)
f01034b1:	75 35                	jne    f01034e8 <envid2env+0x6c>
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f01034b3:	84 db                	test   %bl,%bl
f01034b5:	74 12                	je     f01034c9 <envid2env+0x4d>
f01034b7:	8b 91 24 23 00 00    	mov    0x2324(%ecx),%edx
f01034bd:	39 c2                	cmp    %eax,%edx
f01034bf:	74 08                	je     f01034c9 <envid2env+0x4d>
f01034c1:	8b 5a 48             	mov    0x48(%edx),%ebx
f01034c4:	39 58 4c             	cmp    %ebx,0x4c(%eax)
f01034c7:	75 2f                	jne    f01034f8 <envid2env+0x7c>
	*env_store = e;
f01034c9:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01034cc:	89 03                	mov    %eax,(%ebx)
	return 0;
f01034ce:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01034d3:	5b                   	pop    %ebx
f01034d4:	5d                   	pop    %ebp
f01034d5:	c3                   	ret    
		*env_store = curenv;
f01034d6:	8b 81 24 23 00 00    	mov    0x2324(%ecx),%eax
f01034dc:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01034df:	89 01                	mov    %eax,(%ecx)
		return 0;
f01034e1:	b8 00 00 00 00       	mov    $0x0,%eax
f01034e6:	eb eb                	jmp    f01034d3 <envid2env+0x57>
		*env_store = 0;
f01034e8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01034eb:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f01034f1:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f01034f6:	eb db                	jmp    f01034d3 <envid2env+0x57>
		*env_store = 0;
f01034f8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01034fb:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103501:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103506:	eb cb                	jmp    f01034d3 <envid2env+0x57>

f0103508 <env_init_percpu>:
{
f0103508:	55                   	push   %ebp
f0103509:	89 e5                	mov    %esp,%ebp
f010350b:	e8 2b d2 ff ff       	call   f010073b <__x86.get_pc_thunk.ax>
f0103510:	05 10 8b 08 00       	add    $0x88b10,%eax
	asm volatile("lgdt (%0)" : : "r" (p));
f0103515:	8d 80 e0 1f 00 00    	lea    0x1fe0(%eax),%eax
f010351b:	0f 01 10             	lgdtl  (%eax)
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f010351e:	b8 23 00 00 00       	mov    $0x23,%eax
f0103523:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f0103525:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f0103527:	b8 10 00 00 00       	mov    $0x10,%eax
f010352c:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f010352e:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f0103530:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f0103532:	ea 39 35 10 f0 08 00 	ljmp   $0x8,$0xf0103539
	asm volatile("lldt %0" : : "r" (sel));
f0103539:	b8 00 00 00 00       	mov    $0x0,%eax
f010353e:	0f 00 d0             	lldt   %ax
}
f0103541:	5d                   	pop    %ebp
f0103542:	c3                   	ret    

f0103543 <env_init>:
{
f0103543:	55                   	push   %ebp
f0103544:	89 e5                	mov    %esp,%ebp
f0103546:	57                   	push   %edi
f0103547:	56                   	push   %esi
f0103548:	53                   	push   %ebx
f0103549:	e8 7f 06 00 00       	call   f0103bcd <__x86.get_pc_thunk.si>
f010354e:	81 c6 d2 8a 08 00    	add    $0x88ad2,%esi
		(envs + i)->env_status = ENV_FREE;
f0103554:	8b be 28 23 00 00    	mov    0x2328(%esi),%edi
f010355a:	8b 96 2c 23 00 00    	mov    0x232c(%esi),%edx
f0103560:	8d 87 a0 7f 01 00    	lea    0x17fa0(%edi),%eax
f0103566:	8d 5f a0             	lea    -0x60(%edi),%ebx
f0103569:	89 c1                	mov    %eax,%ecx
f010356b:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		(envs + i)->env_id = 0;
f0103572:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		(envs + i)->env_link = env_free_list;
f0103579:	89 50 44             	mov    %edx,0x44(%eax)
f010357c:	83 e8 60             	sub    $0x60,%eax
		env_free_list = (envs + i);
f010357f:	89 ca                	mov    %ecx,%edx
	for(int i = NENV - 1; i >= 0; --i) {
f0103581:	39 d8                	cmp    %ebx,%eax
f0103583:	75 e4                	jne    f0103569 <env_init+0x26>
f0103585:	89 be 2c 23 00 00    	mov    %edi,0x232c(%esi)
	env_init_percpu();
f010358b:	e8 78 ff ff ff       	call   f0103508 <env_init_percpu>
}
f0103590:	5b                   	pop    %ebx
f0103591:	5e                   	pop    %esi
f0103592:	5f                   	pop    %edi
f0103593:	5d                   	pop    %ebp
f0103594:	c3                   	ret    

f0103595 <env_alloc>:
{
f0103595:	55                   	push   %ebp
f0103596:	89 e5                	mov    %esp,%ebp
f0103598:	57                   	push   %edi
f0103599:	56                   	push   %esi
f010359a:	53                   	push   %ebx
f010359b:	83 ec 0c             	sub    $0xc,%esp
f010359e:	e8 f6 cb ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f01035a3:	81 c3 7d 8a 08 00    	add    $0x88a7d,%ebx
	if (!(e = env_free_list))
f01035a9:	8b b3 2c 23 00 00    	mov    0x232c(%ebx),%esi
f01035af:	85 f6                	test   %esi,%esi
f01035b1:	0f 84 79 01 00 00    	je     f0103730 <env_alloc+0x19b>
	if (!(p = page_alloc(ALLOC_ZERO)))
f01035b7:	83 ec 0c             	sub    $0xc,%esp
f01035ba:	6a 01                	push   $0x1
f01035bc:	e8 44 db ff ff       	call   f0101105 <page_alloc>
f01035c1:	89 c7                	mov    %eax,%edi
f01035c3:	83 c4 10             	add    $0x10,%esp
f01035c6:	85 c0                	test   %eax,%eax
f01035c8:	0f 84 69 01 00 00    	je     f0103737 <env_alloc+0x1a2>
	return (pp - pages) << PGSHIFT;
f01035ce:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f01035d4:	89 f9                	mov    %edi,%ecx
f01035d6:	2b 08                	sub    (%eax),%ecx
f01035d8:	89 c8                	mov    %ecx,%eax
f01035da:	c1 f8 03             	sar    $0x3,%eax
f01035dd:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f01035e0:	89 c1                	mov    %eax,%ecx
f01035e2:	c1 e9 0c             	shr    $0xc,%ecx
f01035e5:	c7 c2 04 f0 18 f0    	mov    $0xf018f004,%edx
f01035eb:	3b 0a                	cmp    (%edx),%ecx
f01035ed:	0f 83 0e 01 00 00    	jae    f0103701 <env_alloc+0x16c>
	return (void *)(pa + KERNBASE);
f01035f3:	2d 00 00 00 10       	sub    $0x10000000,%eax
	e->env_pgdir = (pde_t *)page2kva(p);
f01035f8:	89 46 5c             	mov    %eax,0x5c(%esi)
	memset(e->env_pgdir, 0, PGSIZE);
f01035fb:	83 ec 04             	sub    $0x4,%esp
f01035fe:	68 00 10 00 00       	push   $0x1000
f0103603:	6a 00                	push   $0x0
f0103605:	50                   	push   %eax
f0103606:	e8 fc 16 00 00       	call   f0104d07 <memset>
	p->pp_ref += 1;
f010360b:	66 83 47 04 01       	addw   $0x1,0x4(%edi)
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
f0103610:	83 c4 0c             	add    $0xc,%esp
f0103613:	68 00 10 00 00       	push   $0x1000
f0103618:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f010361e:	ff 30                	pushl  (%eax)
f0103620:	ff 76 5c             	pushl  0x5c(%esi)
f0103623:	e8 94 17 00 00       	call   f0104dbc <memcpy>
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0103628:	8b 46 5c             	mov    0x5c(%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f010362b:	83 c4 10             	add    $0x10,%esp
f010362e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103633:	0f 86 de 00 00 00    	jbe    f0103717 <env_alloc+0x182>
	return (physaddr_t)kva - KERNBASE;
f0103639:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010363f:	83 ca 05             	or     $0x5,%edx
f0103642:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0103648:	8b 46 48             	mov    0x48(%esi),%eax
f010364b:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0103650:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0103655:	ba 00 10 00 00       	mov    $0x1000,%edx
f010365a:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f010365d:	89 f2                	mov    %esi,%edx
f010365f:	2b 93 28 23 00 00    	sub    0x2328(%ebx),%edx
f0103665:	c1 fa 05             	sar    $0x5,%edx
f0103668:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f010366e:	09 d0                	or     %edx,%eax
f0103670:	89 46 48             	mov    %eax,0x48(%esi)
	e->env_parent_id = parent_id;
f0103673:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103676:	89 46 4c             	mov    %eax,0x4c(%esi)
	e->env_type = ENV_TYPE_USER;
f0103679:	c7 46 50 00 00 00 00 	movl   $0x0,0x50(%esi)
	e->env_status = ENV_RUNNABLE;
f0103680:	c7 46 54 02 00 00 00 	movl   $0x2,0x54(%esi)
	e->env_runs = 0;
f0103687:	c7 46 58 00 00 00 00 	movl   $0x0,0x58(%esi)
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f010368e:	83 ec 04             	sub    $0x4,%esp
f0103691:	6a 44                	push   $0x44
f0103693:	6a 00                	push   $0x0
f0103695:	56                   	push   %esi
f0103696:	e8 6c 16 00 00       	call   f0104d07 <memset>
	e->env_tf.tf_ds = GD_UD | 3;
f010369b:	66 c7 46 24 23 00    	movw   $0x23,0x24(%esi)
	e->env_tf.tf_es = GD_UD | 3;
f01036a1:	66 c7 46 20 23 00    	movw   $0x23,0x20(%esi)
	e->env_tf.tf_ss = GD_UD | 3;
f01036a7:	66 c7 46 40 23 00    	movw   $0x23,0x40(%esi)
	e->env_tf.tf_esp = USTACKTOP;
f01036ad:	c7 46 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%esi)
	e->env_tf.tf_cs = GD_UT | 3;
f01036b4:	66 c7 46 34 1b 00    	movw   $0x1b,0x34(%esi)
	env_free_list = e->env_link;
f01036ba:	8b 46 44             	mov    0x44(%esi),%eax
f01036bd:	89 83 2c 23 00 00    	mov    %eax,0x232c(%ebx)
	*newenv_store = e;
f01036c3:	8b 45 08             	mov    0x8(%ebp),%eax
f01036c6:	89 30                	mov    %esi,(%eax)
	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01036c8:	8b 4e 48             	mov    0x48(%esi),%ecx
f01036cb:	8b 83 24 23 00 00    	mov    0x2324(%ebx),%eax
f01036d1:	83 c4 10             	add    $0x10,%esp
f01036d4:	ba 00 00 00 00       	mov    $0x0,%edx
f01036d9:	85 c0                	test   %eax,%eax
f01036db:	74 03                	je     f01036e0 <env_alloc+0x14b>
f01036dd:	8b 50 48             	mov    0x48(%eax),%edx
f01036e0:	83 ec 04             	sub    $0x4,%esp
f01036e3:	51                   	push   %ecx
f01036e4:	52                   	push   %edx
f01036e5:	8d 83 20 a2 f7 ff    	lea    -0x85de0(%ebx),%eax
f01036eb:	50                   	push   %eax
f01036ec:	e8 67 05 00 00       	call   f0103c58 <cprintf>
	return 0;
f01036f1:	83 c4 10             	add    $0x10,%esp
f01036f4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01036f9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01036fc:	5b                   	pop    %ebx
f01036fd:	5e                   	pop    %esi
f01036fe:	5f                   	pop    %edi
f01036ff:	5d                   	pop    %ebp
f0103700:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103701:	50                   	push   %eax
f0103702:	8d 83 94 99 f7 ff    	lea    -0x8666c(%ebx),%eax
f0103708:	50                   	push   %eax
f0103709:	6a 56                	push   $0x56
f010370b:	8d 83 82 96 f7 ff    	lea    -0x8697e(%ebx),%eax
f0103711:	50                   	push   %eax
f0103712:	e8 cc c9 ff ff       	call   f01000e3 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103717:	50                   	push   %eax
f0103718:	8d 83 a0 9a f7 ff    	lea    -0x86560(%ebx),%eax
f010371e:	50                   	push   %eax
f010371f:	68 d4 00 00 00       	push   $0xd4
f0103724:	8d 83 fe a1 f7 ff    	lea    -0x85e02(%ebx),%eax
f010372a:	50                   	push   %eax
f010372b:	e8 b3 c9 ff ff       	call   f01000e3 <_panic>
		return -E_NO_FREE_ENV;
f0103730:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103735:	eb c2                	jmp    f01036f9 <env_alloc+0x164>
		return -E_NO_MEM;
f0103737:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f010373c:	eb bb                	jmp    f01036f9 <env_alloc+0x164>

f010373e <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f010373e:	55                   	push   %ebp
f010373f:	89 e5                	mov    %esp,%ebp
f0103741:	57                   	push   %edi
f0103742:	56                   	push   %esi
f0103743:	53                   	push   %ebx
f0103744:	83 ec 2c             	sub    $0x2c,%esp
f0103747:	e8 4d ca ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f010374c:	81 c3 d4 88 08 00    	add    $0x888d4,%ebx
	// LAB 3: Your code here.
	if (env_free_list == NULL) {
f0103752:	83 bb 2c 23 00 00 00 	cmpl   $0x0,0x232c(%ebx)
f0103759:	74 64                	je     f01037bf <env_create+0x81>
		panic("No more free env");
		return;
	}

	struct Env *curr_env;
	if (env_alloc(&curr_env, 0) < 0) {
f010375b:	83 ec 08             	sub    $0x8,%esp
f010375e:	6a 00                	push   $0x0
f0103760:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0103763:	50                   	push   %eax
f0103764:	e8 2c fe ff ff       	call   f0103595 <env_alloc>
f0103769:	83 c4 10             	add    $0x10,%esp
f010376c:	85 c0                	test   %eax,%eax
f010376e:	78 6a                	js     f01037da <env_create+0x9c>
		panic("Cannot allocate new env");
	}

	cprintf("load_icode called!\n");
f0103770:	83 ec 0c             	sub    $0xc,%esp
f0103773:	8d 83 5e a2 f7 ff    	lea    -0x85da2(%ebx),%eax
f0103779:	50                   	push   %eax
f010377a:	e8 d9 04 00 00       	call   f0103c58 <cprintf>
	load_icode(curr_env, binary);
f010377f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103782:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	if (elf->e_magic != ELF_MAGIC) {
f0103785:	83 c4 10             	add    $0x10,%esp
f0103788:	8b 45 08             	mov    0x8(%ebp),%eax
f010378b:	81 38 7f 45 4c 46    	cmpl   $0x464c457f,(%eax)
f0103791:	75 62                	jne    f01037f5 <env_create+0xb7>
	lcr3(PADDR(e->env_pgdir));
f0103793:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103796:	8b 40 5c             	mov    0x5c(%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0103799:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010379e:	76 70                	jbe    f0103810 <env_create+0xd2>
	return (physaddr_t)kva - KERNBASE;
f01037a0:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01037a5:	0f 22 d8             	mov    %eax,%cr3
	struct Proghdr* ph = (struct Proghdr*)((uint32_t)binary + elf->e_phoff);
f01037a8:	8b 45 08             	mov    0x8(%ebp),%eax
f01037ab:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01037ae:	89 c6                	mov    %eax,%esi
f01037b0:	03 70 1c             	add    0x1c(%eax),%esi
	struct Proghdr* eph = ph + ((struct Elf*)binary)->e_phnum;
f01037b3:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
f01037b7:	c1 e0 05             	shl    $0x5,%eax
f01037ba:	8d 3c 06             	lea    (%esi,%eax,1),%edi
f01037bd:	eb 6d                	jmp    f010382c <env_create+0xee>
		panic("No more free env");
f01037bf:	83 ec 04             	sub    $0x4,%esp
f01037c2:	8d 83 35 a2 f7 ff    	lea    -0x85dcb(%ebx),%eax
f01037c8:	50                   	push   %eax
f01037c9:	68 d4 01 00 00       	push   $0x1d4
f01037ce:	8d 83 fe a1 f7 ff    	lea    -0x85e02(%ebx),%eax
f01037d4:	50                   	push   %eax
f01037d5:	e8 09 c9 ff ff       	call   f01000e3 <_panic>
		panic("Cannot allocate new env");
f01037da:	83 ec 04             	sub    $0x4,%esp
f01037dd:	8d 83 46 a2 f7 ff    	lea    -0x85dba(%ebx),%eax
f01037e3:	50                   	push   %eax
f01037e4:	68 da 01 00 00       	push   $0x1da
f01037e9:	8d 83 fe a1 f7 ff    	lea    -0x85e02(%ebx),%eax
f01037ef:	50                   	push   %eax
f01037f0:	e8 ee c8 ff ff       	call   f01000e3 <_panic>
		panic("Not ELF format");
f01037f5:	83 ec 04             	sub    $0x4,%esp
f01037f8:	8d 83 72 a2 f7 ff    	lea    -0x85d8e(%ebx),%eax
f01037fe:	50                   	push   %eax
f01037ff:	68 79 01 00 00       	push   $0x179
f0103804:	8d 83 fe a1 f7 ff    	lea    -0x85e02(%ebx),%eax
f010380a:	50                   	push   %eax
f010380b:	e8 d3 c8 ff ff       	call   f01000e3 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103810:	50                   	push   %eax
f0103811:	8d 83 a0 9a f7 ff    	lea    -0x86560(%ebx),%eax
f0103817:	50                   	push   %eax
f0103818:	68 82 01 00 00       	push   $0x182
f010381d:	8d 83 fe a1 f7 ff    	lea    -0x85e02(%ebx),%eax
f0103823:	50                   	push   %eax
f0103824:	e8 ba c8 ff ff       	call   f01000e3 <_panic>
	for(; ph < eph; ph++) {
f0103829:	83 c6 20             	add    $0x20,%esi
f010382c:	39 f7                	cmp    %esi,%edi
f010382e:	76 42                	jbe    f0103872 <env_create+0x134>
		if (ph->p_type == ELF_PROG_LOAD) {
f0103830:	83 3e 01             	cmpl   $0x1,(%esi)
f0103833:	75 f4                	jne    f0103829 <env_create+0xeb>
			va = (uint32_t)binary + ph->p_offset;
f0103835:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0103838:	03 46 04             	add    0x4(%esi),%eax
f010383b:	89 45 d0             	mov    %eax,-0x30(%ebp)
            region_alloc(e, (void *)ph->p_va, ph->p_memsz);
f010383e:	8b 4e 14             	mov    0x14(%esi),%ecx
f0103841:	8b 56 08             	mov    0x8(%esi),%edx
f0103844:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103847:	e8 42 fb ff ff       	call   f010338e <region_alloc>
            memset((void*)ph->p_va, 0, ph->p_memsz);
f010384c:	83 ec 04             	sub    $0x4,%esp
f010384f:	ff 76 14             	pushl  0x14(%esi)
f0103852:	6a 00                	push   $0x0
f0103854:	ff 76 08             	pushl  0x8(%esi)
f0103857:	e8 ab 14 00 00       	call   f0104d07 <memset>
            memcpy((void*)ph->p_va, (void*)va, ph->p_filesz);
f010385c:	83 c4 0c             	add    $0xc,%esp
f010385f:	ff 76 10             	pushl  0x10(%esi)
f0103862:	ff 75 d0             	pushl  -0x30(%ebp)
f0103865:	ff 76 08             	pushl  0x8(%esi)
f0103868:	e8 4f 15 00 00       	call   f0104dbc <memcpy>
f010386d:	83 c4 10             	add    $0x10,%esp
f0103870:	eb b7                	jmp    f0103829 <env_create+0xeb>
	region_alloc(e, (void*)(USTACKTOP - PGSIZE), PGSIZE);
f0103872:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0103877:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f010387c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010387f:	e8 0a fb ff ff       	call   f010338e <region_alloc>
	lcr3(PADDR(kern_pgdir));
f0103884:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f010388a:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f010388c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103891:	76 37                	jbe    f01038ca <env_create+0x18c>
	return (physaddr_t)kva - KERNBASE;
f0103893:	05 00 00 00 10       	add    $0x10000000,%eax
f0103898:	0f 22 d8             	mov    %eax,%cr3
	e->env_tf.tf_eip = elf->e_entry;
f010389b:	8b 45 08             	mov    0x8(%ebp),%eax
f010389e:	8b 40 18             	mov    0x18(%eax),%eax
f01038a1:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01038a4:	89 41 30             	mov    %eax,0x30(%ecx)
	cprintf("load_icode done!\n");
f01038a7:	83 ec 0c             	sub    $0xc,%esp
f01038aa:	8d 83 81 a2 f7 ff    	lea    -0x85d7f(%ebx),%eax
f01038b0:	50                   	push   %eax
f01038b1:	e8 a2 03 00 00       	call   f0103c58 <cprintf>
	curr_env->env_type = type;
f01038b6:	8b 55 0c             	mov    0xc(%ebp),%edx
f01038b9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01038bc:	89 50 50             	mov    %edx,0x50(%eax)
}
f01038bf:	83 c4 10             	add    $0x10,%esp
f01038c2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01038c5:	5b                   	pop    %ebx
f01038c6:	5e                   	pop    %esi
f01038c7:	5f                   	pop    %edi
f01038c8:	5d                   	pop    %ebp
f01038c9:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01038ca:	50                   	push   %eax
f01038cb:	8d 83 a0 9a f7 ff    	lea    -0x86560(%ebx),%eax
f01038d1:	50                   	push   %eax
f01038d2:	68 99 01 00 00       	push   $0x199
f01038d7:	8d 83 fe a1 f7 ff    	lea    -0x85e02(%ebx),%eax
f01038dd:	50                   	push   %eax
f01038de:	e8 00 c8 ff ff       	call   f01000e3 <_panic>

f01038e3 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01038e3:	55                   	push   %ebp
f01038e4:	89 e5                	mov    %esp,%ebp
f01038e6:	57                   	push   %edi
f01038e7:	56                   	push   %esi
f01038e8:	53                   	push   %ebx
f01038e9:	83 ec 2c             	sub    $0x2c,%esp
f01038ec:	e8 a8 c8 ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f01038f1:	81 c3 2f 87 08 00    	add    $0x8872f,%ebx
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01038f7:	8b 93 24 23 00 00    	mov    0x2324(%ebx),%edx
f01038fd:	3b 55 08             	cmp    0x8(%ebp),%edx
f0103900:	75 17                	jne    f0103919 <env_free+0x36>
		lcr3(PADDR(kern_pgdir));
f0103902:	c7 c0 08 f0 18 f0    	mov    $0xf018f008,%eax
f0103908:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f010390a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010390f:	76 46                	jbe    f0103957 <env_free+0x74>
	return (physaddr_t)kva - KERNBASE;
f0103911:	05 00 00 00 10       	add    $0x10000000,%eax
f0103916:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103919:	8b 45 08             	mov    0x8(%ebp),%eax
f010391c:	8b 48 48             	mov    0x48(%eax),%ecx
f010391f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103924:	85 d2                	test   %edx,%edx
f0103926:	74 03                	je     f010392b <env_free+0x48>
f0103928:	8b 42 48             	mov    0x48(%edx),%eax
f010392b:	83 ec 04             	sub    $0x4,%esp
f010392e:	51                   	push   %ecx
f010392f:	50                   	push   %eax
f0103930:	8d 83 93 a2 f7 ff    	lea    -0x85d6d(%ebx),%eax
f0103936:	50                   	push   %eax
f0103937:	e8 1c 03 00 00       	call   f0103c58 <cprintf>
f010393c:	83 c4 10             	add    $0x10,%esp
f010393f:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	if (PGNUM(pa) >= npages)
f0103946:	c7 c0 04 f0 18 f0    	mov    $0xf018f004,%eax
f010394c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	if (PGNUM(pa) >= npages)
f010394f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103952:	e9 9f 00 00 00       	jmp    f01039f6 <env_free+0x113>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103957:	50                   	push   %eax
f0103958:	8d 83 a0 9a f7 ff    	lea    -0x86560(%ebx),%eax
f010395e:	50                   	push   %eax
f010395f:	68 f1 01 00 00       	push   $0x1f1
f0103964:	8d 83 fe a1 f7 ff    	lea    -0x85e02(%ebx),%eax
f010396a:	50                   	push   %eax
f010396b:	e8 73 c7 ff ff       	call   f01000e3 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103970:	50                   	push   %eax
f0103971:	8d 83 94 99 f7 ff    	lea    -0x8666c(%ebx),%eax
f0103977:	50                   	push   %eax
f0103978:	68 00 02 00 00       	push   $0x200
f010397d:	8d 83 fe a1 f7 ff    	lea    -0x85e02(%ebx),%eax
f0103983:	50                   	push   %eax
f0103984:	e8 5a c7 ff ff       	call   f01000e3 <_panic>
f0103989:	83 c6 04             	add    $0x4,%esi
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010398c:	39 fe                	cmp    %edi,%esi
f010398e:	74 24                	je     f01039b4 <env_free+0xd1>
			if (pt[pteno] & PTE_P)
f0103990:	f6 06 01             	testb  $0x1,(%esi)
f0103993:	74 f4                	je     f0103989 <env_free+0xa6>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103995:	83 ec 08             	sub    $0x8,%esp
f0103998:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010399b:	01 f0                	add    %esi,%eax
f010399d:	c1 e0 0a             	shl    $0xa,%eax
f01039a0:	0b 45 e4             	or     -0x1c(%ebp),%eax
f01039a3:	50                   	push   %eax
f01039a4:	8b 45 08             	mov    0x8(%ebp),%eax
f01039a7:	ff 70 5c             	pushl  0x5c(%eax)
f01039aa:	e8 9a da ff ff       	call   f0101449 <page_remove>
f01039af:	83 c4 10             	add    $0x10,%esp
f01039b2:	eb d5                	jmp    f0103989 <env_free+0xa6>
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f01039b4:	8b 45 08             	mov    0x8(%ebp),%eax
f01039b7:	8b 40 5c             	mov    0x5c(%eax),%eax
f01039ba:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01039bd:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
	if (PGNUM(pa) >= npages)
f01039c4:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01039c7:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01039ca:	3b 10                	cmp    (%eax),%edx
f01039cc:	73 6f                	jae    f0103a3d <env_free+0x15a>
		page_decref(pa2page(pa));
f01039ce:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f01039d1:	c7 c0 0c f0 18 f0    	mov    $0xf018f00c,%eax
f01039d7:	8b 00                	mov    (%eax),%eax
f01039d9:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01039dc:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f01039df:	50                   	push   %eax
f01039e0:	e8 18 d8 ff ff       	call   f01011fd <page_decref>
f01039e5:	83 c4 10             	add    $0x10,%esp
f01039e8:	83 45 dc 04          	addl   $0x4,-0x24(%ebp)
f01039ec:	8b 45 dc             	mov    -0x24(%ebp),%eax
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01039ef:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f01039f4:	74 5f                	je     f0103a55 <env_free+0x172>
		if (!(e->env_pgdir[pdeno] & PTE_P))
f01039f6:	8b 45 08             	mov    0x8(%ebp),%eax
f01039f9:	8b 40 5c             	mov    0x5c(%eax),%eax
f01039fc:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01039ff:	8b 04 10             	mov    (%eax,%edx,1),%eax
f0103a02:	a8 01                	test   $0x1,%al
f0103a04:	74 e2                	je     f01039e8 <env_free+0x105>
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103a06:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0103a0b:	89 c2                	mov    %eax,%edx
f0103a0d:	c1 ea 0c             	shr    $0xc,%edx
f0103a10:	89 55 d8             	mov    %edx,-0x28(%ebp)
f0103a13:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0103a16:	39 11                	cmp    %edx,(%ecx)
f0103a18:	0f 86 52 ff ff ff    	jbe    f0103970 <env_free+0x8d>
	return (void *)(pa + KERNBASE);
f0103a1e:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103a24:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103a27:	c1 e2 14             	shl    $0x14,%edx
f0103a2a:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103a2d:	8d b8 00 10 00 f0    	lea    -0xffff000(%eax),%edi
f0103a33:	f7 d8                	neg    %eax
f0103a35:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103a38:	e9 53 ff ff ff       	jmp    f0103990 <env_free+0xad>
		panic("pa2page called with invalid pa");
f0103a3d:	83 ec 04             	sub    $0x4,%esp
f0103a40:	8d 83 c4 9a f7 ff    	lea    -0x8653c(%ebx),%eax
f0103a46:	50                   	push   %eax
f0103a47:	6a 4f                	push   $0x4f
f0103a49:	8d 83 82 96 f7 ff    	lea    -0x8697e(%ebx),%eax
f0103a4f:	50                   	push   %eax
f0103a50:	e8 8e c6 ff ff       	call   f01000e3 <_panic>
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103a55:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a58:	8b 40 5c             	mov    0x5c(%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0103a5b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103a60:	76 57                	jbe    f0103ab9 <env_free+0x1d6>
	e->env_pgdir = 0;
f0103a62:	8b 55 08             	mov    0x8(%ebp),%edx
f0103a65:	c7 42 5c 00 00 00 00 	movl   $0x0,0x5c(%edx)
	return (physaddr_t)kva - KERNBASE;
f0103a6c:	05 00 00 00 10       	add    $0x10000000,%eax
	if (PGNUM(pa) >= npages)
f0103a71:	c1 e8 0c             	shr    $0xc,%eax
f0103a74:	c7 c2 04 f0 18 f0    	mov    $0xf018f004,%edx
f0103a7a:	3b 02                	cmp    (%edx),%eax
f0103a7c:	73 54                	jae    f0103ad2 <env_free+0x1ef>
	page_decref(pa2page(pa));
f0103a7e:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0103a81:	c7 c2 0c f0 18 f0    	mov    $0xf018f00c,%edx
f0103a87:	8b 12                	mov    (%edx),%edx
f0103a89:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0103a8c:	50                   	push   %eax
f0103a8d:	e8 6b d7 ff ff       	call   f01011fd <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103a92:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a95:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
	e->env_link = env_free_list;
f0103a9c:	8b 83 2c 23 00 00    	mov    0x232c(%ebx),%eax
f0103aa2:	8b 55 08             	mov    0x8(%ebp),%edx
f0103aa5:	89 42 44             	mov    %eax,0x44(%edx)
	env_free_list = e;
f0103aa8:	89 93 2c 23 00 00    	mov    %edx,0x232c(%ebx)
}
f0103aae:	83 c4 10             	add    $0x10,%esp
f0103ab1:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103ab4:	5b                   	pop    %ebx
f0103ab5:	5e                   	pop    %esi
f0103ab6:	5f                   	pop    %edi
f0103ab7:	5d                   	pop    %ebp
f0103ab8:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103ab9:	50                   	push   %eax
f0103aba:	8d 83 a0 9a f7 ff    	lea    -0x86560(%ebx),%eax
f0103ac0:	50                   	push   %eax
f0103ac1:	68 0e 02 00 00       	push   $0x20e
f0103ac6:	8d 83 fe a1 f7 ff    	lea    -0x85e02(%ebx),%eax
f0103acc:	50                   	push   %eax
f0103acd:	e8 11 c6 ff ff       	call   f01000e3 <_panic>
		panic("pa2page called with invalid pa");
f0103ad2:	83 ec 04             	sub    $0x4,%esp
f0103ad5:	8d 83 c4 9a f7 ff    	lea    -0x8653c(%ebx),%eax
f0103adb:	50                   	push   %eax
f0103adc:	6a 4f                	push   $0x4f
f0103ade:	8d 83 82 96 f7 ff    	lea    -0x8697e(%ebx),%eax
f0103ae4:	50                   	push   %eax
f0103ae5:	e8 f9 c5 ff ff       	call   f01000e3 <_panic>

f0103aea <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0103aea:	55                   	push   %ebp
f0103aeb:	89 e5                	mov    %esp,%ebp
f0103aed:	53                   	push   %ebx
f0103aee:	83 ec 10             	sub    $0x10,%esp
f0103af1:	e8 a3 c6 ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f0103af6:	81 c3 2a 85 08 00    	add    $0x8852a,%ebx
	env_free(e);
f0103afc:	ff 75 08             	pushl  0x8(%ebp)
f0103aff:	e8 df fd ff ff       	call   f01038e3 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0103b04:	8d 83 c8 a1 f7 ff    	lea    -0x85e38(%ebx),%eax
f0103b0a:	89 04 24             	mov    %eax,(%esp)
f0103b0d:	e8 46 01 00 00       	call   f0103c58 <cprintf>
f0103b12:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0103b15:	83 ec 0c             	sub    $0xc,%esp
f0103b18:	6a 00                	push   $0x0
f0103b1a:	e8 61 ce ff ff       	call   f0100980 <monitor>
f0103b1f:	83 c4 10             	add    $0x10,%esp
f0103b22:	eb f1                	jmp    f0103b15 <env_destroy+0x2b>

f0103b24 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103b24:	55                   	push   %ebp
f0103b25:	89 e5                	mov    %esp,%ebp
f0103b27:	53                   	push   %ebx
f0103b28:	83 ec 08             	sub    $0x8,%esp
f0103b2b:	e8 69 c6 ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f0103b30:	81 c3 f0 84 08 00    	add    $0x884f0,%ebx
	asm volatile(
f0103b36:	8b 65 08             	mov    0x8(%ebp),%esp
f0103b39:	61                   	popa   
f0103b3a:	07                   	pop    %es
f0103b3b:	1f                   	pop    %ds
f0103b3c:	83 c4 08             	add    $0x8,%esp
f0103b3f:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103b40:	8d 83 a9 a2 f7 ff    	lea    -0x85d57(%ebx),%eax
f0103b46:	50                   	push   %eax
f0103b47:	68 37 02 00 00       	push   $0x237
f0103b4c:	8d 83 fe a1 f7 ff    	lea    -0x85e02(%ebx),%eax
f0103b52:	50                   	push   %eax
f0103b53:	e8 8b c5 ff ff       	call   f01000e3 <_panic>

f0103b58 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103b58:	55                   	push   %ebp
f0103b59:	89 e5                	mov    %esp,%ebp
f0103b5b:	53                   	push   %ebx
f0103b5c:	83 ec 04             	sub    $0x4,%esp
f0103b5f:	e8 35 c6 ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f0103b64:	81 c3 bc 84 08 00    	add    $0x884bc,%ebx
f0103b6a:	8b 45 08             	mov    0x8(%ebp),%eax
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if (curenv != NULL) {
f0103b6d:	8b 93 24 23 00 00    	mov    0x2324(%ebx),%edx
f0103b73:	85 d2                	test   %edx,%edx
f0103b75:	74 06                	je     f0103b7d <env_run+0x25>
		if (curenv->env_status == ENV_RUNNING) {
f0103b77:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0103b7b:	74 35                	je     f0103bb2 <env_run+0x5a>
			curenv->env_status = ENV_RUNNABLE;
		}
	}
	curenv = e;
f0103b7d:	89 83 24 23 00 00    	mov    %eax,0x2324(%ebx)
	curenv->env_status = ENV_RUNNING;
f0103b83:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs += 1;
f0103b8a:	83 40 58 01          	addl   $0x1,0x58(%eax)

	lcr3(PADDR((e->env_pgdir)));
f0103b8e:	8b 50 5c             	mov    0x5c(%eax),%edx
	if ((uint32_t)kva < KERNBASE)
f0103b91:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0103b97:	77 22                	ja     f0103bbb <env_run+0x63>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103b99:	52                   	push   %edx
f0103b9a:	8d 83 a0 9a f7 ff    	lea    -0x86560(%ebx),%eax
f0103ba0:	50                   	push   %eax
f0103ba1:	68 5e 02 00 00       	push   $0x25e
f0103ba6:	8d 83 fe a1 f7 ff    	lea    -0x85e02(%ebx),%eax
f0103bac:	50                   	push   %eax
f0103bad:	e8 31 c5 ff ff       	call   f01000e3 <_panic>
			curenv->env_status = ENV_RUNNABLE;
f0103bb2:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
f0103bb9:	eb c2                	jmp    f0103b7d <env_run+0x25>
	return (physaddr_t)kva - KERNBASE;
f0103bbb:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0103bc1:	0f 22 da             	mov    %edx,%cr3
	env_pop_tf(&(e->env_tf));
f0103bc4:	83 ec 0c             	sub    $0xc,%esp
f0103bc7:	50                   	push   %eax
f0103bc8:	e8 57 ff ff ff       	call   f0103b24 <env_pop_tf>

f0103bcd <__x86.get_pc_thunk.si>:
f0103bcd:	8b 34 24             	mov    (%esp),%esi
f0103bd0:	c3                   	ret    

f0103bd1 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103bd1:	55                   	push   %ebp
f0103bd2:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103bd4:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bd7:	ba 70 00 00 00       	mov    $0x70,%edx
f0103bdc:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103bdd:	ba 71 00 00 00       	mov    $0x71,%edx
f0103be2:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103be3:	0f b6 c0             	movzbl %al,%eax
}
f0103be6:	5d                   	pop    %ebp
f0103be7:	c3                   	ret    

f0103be8 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103be8:	55                   	push   %ebp
f0103be9:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103beb:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bee:	ba 70 00 00 00       	mov    $0x70,%edx
f0103bf3:	ee                   	out    %al,(%dx)
f0103bf4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103bf7:	ba 71 00 00 00       	mov    $0x71,%edx
f0103bfc:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103bfd:	5d                   	pop    %ebp
f0103bfe:	c3                   	ret    

f0103bff <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103bff:	55                   	push   %ebp
f0103c00:	89 e5                	mov    %esp,%ebp
f0103c02:	53                   	push   %ebx
f0103c03:	83 ec 10             	sub    $0x10,%esp
f0103c06:	e8 8e c5 ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f0103c0b:	81 c3 15 84 08 00    	add    $0x88415,%ebx
	cputchar(ch);
f0103c11:	ff 75 08             	pushl  0x8(%ebp)
f0103c14:	e8 f7 ca ff ff       	call   f0100710 <cputchar>
	*cnt++;
}
f0103c19:	83 c4 10             	add    $0x10,%esp
f0103c1c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103c1f:	c9                   	leave  
f0103c20:	c3                   	ret    

f0103c21 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103c21:	55                   	push   %ebp
f0103c22:	89 e5                	mov    %esp,%ebp
f0103c24:	53                   	push   %ebx
f0103c25:	83 ec 14             	sub    $0x14,%esp
f0103c28:	e8 6c c5 ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f0103c2d:	81 c3 f3 83 08 00    	add    $0x883f3,%ebx
	int cnt = 0;
f0103c33:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103c3a:	ff 75 0c             	pushl  0xc(%ebp)
f0103c3d:	ff 75 08             	pushl  0x8(%ebp)
f0103c40:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103c43:	50                   	push   %eax
f0103c44:	8d 83 df 7b f7 ff    	lea    -0x88421(%ebx),%eax
f0103c4a:	50                   	push   %eax
f0103c4b:	e8 37 09 00 00       	call   f0104587 <vprintfmt>
	return cnt;
}
f0103c50:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103c53:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103c56:	c9                   	leave  
f0103c57:	c3                   	ret    

f0103c58 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103c58:	55                   	push   %ebp
f0103c59:	89 e5                	mov    %esp,%ebp
f0103c5b:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103c5e:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103c61:	50                   	push   %eax
f0103c62:	ff 75 08             	pushl  0x8(%ebp)
f0103c65:	e8 b7 ff ff ff       	call   f0103c21 <vcprintf>
	va_end(ap);

	return cnt;
}
f0103c6a:	c9                   	leave  
f0103c6b:	c3                   	ret    

f0103c6c <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103c6c:	55                   	push   %ebp
f0103c6d:	89 e5                	mov    %esp,%ebp
f0103c6f:	57                   	push   %edi
f0103c70:	56                   	push   %esi
f0103c71:	53                   	push   %ebx
f0103c72:	83 ec 04             	sub    $0x4,%esp
f0103c75:	e8 1f c5 ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f0103c7a:	81 c3 a6 83 08 00    	add    $0x883a6,%ebx
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0103c80:	c7 83 64 2b 00 00 00 	movl   $0xf0000000,0x2b64(%ebx)
f0103c87:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0103c8a:	66 c7 83 68 2b 00 00 	movw   $0x10,0x2b68(%ebx)
f0103c91:	10 00 
	ts.ts_iomb = sizeof(struct Taskstate);
f0103c93:	66 c7 83 c6 2b 00 00 	movw   $0x68,0x2bc6(%ebx)
f0103c9a:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0103c9c:	c7 c0 00 b3 11 f0    	mov    $0xf011b300,%eax
f0103ca2:	66 c7 40 28 67 00    	movw   $0x67,0x28(%eax)
f0103ca8:	8d b3 60 2b 00 00    	lea    0x2b60(%ebx),%esi
f0103cae:	66 89 70 2a          	mov    %si,0x2a(%eax)
f0103cb2:	89 f2                	mov    %esi,%edx
f0103cb4:	c1 ea 10             	shr    $0x10,%edx
f0103cb7:	88 50 2c             	mov    %dl,0x2c(%eax)
f0103cba:	0f b6 50 2d          	movzbl 0x2d(%eax),%edx
f0103cbe:	83 e2 f0             	and    $0xfffffff0,%edx
f0103cc1:	83 ca 09             	or     $0x9,%edx
f0103cc4:	83 e2 9f             	and    $0xffffff9f,%edx
f0103cc7:	83 ca 80             	or     $0xffffff80,%edx
f0103cca:	88 55 f3             	mov    %dl,-0xd(%ebp)
f0103ccd:	88 50 2d             	mov    %dl,0x2d(%eax)
f0103cd0:	0f b6 48 2e          	movzbl 0x2e(%eax),%ecx
f0103cd4:	83 e1 c0             	and    $0xffffffc0,%ecx
f0103cd7:	83 c9 40             	or     $0x40,%ecx
f0103cda:	83 e1 7f             	and    $0x7f,%ecx
f0103cdd:	88 48 2e             	mov    %cl,0x2e(%eax)
f0103ce0:	c1 ee 18             	shr    $0x18,%esi
f0103ce3:	89 f1                	mov    %esi,%ecx
f0103ce5:	88 48 2f             	mov    %cl,0x2f(%eax)
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0103ce8:	0f b6 55 f3          	movzbl -0xd(%ebp),%edx
f0103cec:	83 e2 ef             	and    $0xffffffef,%edx
f0103cef:	88 50 2d             	mov    %dl,0x2d(%eax)
	asm volatile("ltr %0" : : "r" (sel));
f0103cf2:	b8 28 00 00 00       	mov    $0x28,%eax
f0103cf7:	0f 00 d8             	ltr    %ax
	asm volatile("lidt (%0)" : : "r" (p));
f0103cfa:	8d 83 e8 1f 00 00    	lea    0x1fe8(%ebx),%eax
f0103d00:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0103d03:	83 c4 04             	add    $0x4,%esp
f0103d06:	5b                   	pop    %ebx
f0103d07:	5e                   	pop    %esi
f0103d08:	5f                   	pop    %edi
f0103d09:	5d                   	pop    %ebp
f0103d0a:	c3                   	ret    

f0103d0b <trap_init>:
{
f0103d0b:	55                   	push   %ebp
f0103d0c:	89 e5                	mov    %esp,%ebp
	trap_init_percpu();
f0103d0e:	e8 59 ff ff ff       	call   f0103c6c <trap_init_percpu>
}
f0103d13:	5d                   	pop    %ebp
f0103d14:	c3                   	ret    

f0103d15 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103d15:	55                   	push   %ebp
f0103d16:	89 e5                	mov    %esp,%ebp
f0103d18:	56                   	push   %esi
f0103d19:	53                   	push   %ebx
f0103d1a:	e8 7a c4 ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f0103d1f:	81 c3 01 83 08 00    	add    $0x88301,%ebx
f0103d25:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103d28:	83 ec 08             	sub    $0x8,%esp
f0103d2b:	ff 36                	pushl  (%esi)
f0103d2d:	8d 83 b5 a2 f7 ff    	lea    -0x85d4b(%ebx),%eax
f0103d33:	50                   	push   %eax
f0103d34:	e8 1f ff ff ff       	call   f0103c58 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103d39:	83 c4 08             	add    $0x8,%esp
f0103d3c:	ff 76 04             	pushl  0x4(%esi)
f0103d3f:	8d 83 c4 a2 f7 ff    	lea    -0x85d3c(%ebx),%eax
f0103d45:	50                   	push   %eax
f0103d46:	e8 0d ff ff ff       	call   f0103c58 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103d4b:	83 c4 08             	add    $0x8,%esp
f0103d4e:	ff 76 08             	pushl  0x8(%esi)
f0103d51:	8d 83 d3 a2 f7 ff    	lea    -0x85d2d(%ebx),%eax
f0103d57:	50                   	push   %eax
f0103d58:	e8 fb fe ff ff       	call   f0103c58 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103d5d:	83 c4 08             	add    $0x8,%esp
f0103d60:	ff 76 0c             	pushl  0xc(%esi)
f0103d63:	8d 83 e2 a2 f7 ff    	lea    -0x85d1e(%ebx),%eax
f0103d69:	50                   	push   %eax
f0103d6a:	e8 e9 fe ff ff       	call   f0103c58 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103d6f:	83 c4 08             	add    $0x8,%esp
f0103d72:	ff 76 10             	pushl  0x10(%esi)
f0103d75:	8d 83 f1 a2 f7 ff    	lea    -0x85d0f(%ebx),%eax
f0103d7b:	50                   	push   %eax
f0103d7c:	e8 d7 fe ff ff       	call   f0103c58 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103d81:	83 c4 08             	add    $0x8,%esp
f0103d84:	ff 76 14             	pushl  0x14(%esi)
f0103d87:	8d 83 00 a3 f7 ff    	lea    -0x85d00(%ebx),%eax
f0103d8d:	50                   	push   %eax
f0103d8e:	e8 c5 fe ff ff       	call   f0103c58 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103d93:	83 c4 08             	add    $0x8,%esp
f0103d96:	ff 76 18             	pushl  0x18(%esi)
f0103d99:	8d 83 0f a3 f7 ff    	lea    -0x85cf1(%ebx),%eax
f0103d9f:	50                   	push   %eax
f0103da0:	e8 b3 fe ff ff       	call   f0103c58 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103da5:	83 c4 08             	add    $0x8,%esp
f0103da8:	ff 76 1c             	pushl  0x1c(%esi)
f0103dab:	8d 83 1e a3 f7 ff    	lea    -0x85ce2(%ebx),%eax
f0103db1:	50                   	push   %eax
f0103db2:	e8 a1 fe ff ff       	call   f0103c58 <cprintf>
}
f0103db7:	83 c4 10             	add    $0x10,%esp
f0103dba:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103dbd:	5b                   	pop    %ebx
f0103dbe:	5e                   	pop    %esi
f0103dbf:	5d                   	pop    %ebp
f0103dc0:	c3                   	ret    

f0103dc1 <print_trapframe>:
{
f0103dc1:	55                   	push   %ebp
f0103dc2:	89 e5                	mov    %esp,%ebp
f0103dc4:	57                   	push   %edi
f0103dc5:	56                   	push   %esi
f0103dc6:	53                   	push   %ebx
f0103dc7:	83 ec 14             	sub    $0x14,%esp
f0103dca:	e8 ca c3 ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f0103dcf:	81 c3 51 82 08 00    	add    $0x88251,%ebx
f0103dd5:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("TRAP frame at %p\n", tf);
f0103dd8:	56                   	push   %esi
f0103dd9:	8d 83 54 a4 f7 ff    	lea    -0x85bac(%ebx),%eax
f0103ddf:	50                   	push   %eax
f0103de0:	e8 73 fe ff ff       	call   f0103c58 <cprintf>
	print_regs(&tf->tf_regs);
f0103de5:	89 34 24             	mov    %esi,(%esp)
f0103de8:	e8 28 ff ff ff       	call   f0103d15 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103ded:	83 c4 08             	add    $0x8,%esp
f0103df0:	0f b7 46 20          	movzwl 0x20(%esi),%eax
f0103df4:	50                   	push   %eax
f0103df5:	8d 83 6f a3 f7 ff    	lea    -0x85c91(%ebx),%eax
f0103dfb:	50                   	push   %eax
f0103dfc:	e8 57 fe ff ff       	call   f0103c58 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103e01:	83 c4 08             	add    $0x8,%esp
f0103e04:	0f b7 46 24          	movzwl 0x24(%esi),%eax
f0103e08:	50                   	push   %eax
f0103e09:	8d 83 82 a3 f7 ff    	lea    -0x85c7e(%ebx),%eax
f0103e0f:	50                   	push   %eax
f0103e10:	e8 43 fe ff ff       	call   f0103c58 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103e15:	8b 56 28             	mov    0x28(%esi),%edx
	if (trapno < ARRAY_SIZE(excnames))
f0103e18:	83 c4 10             	add    $0x10,%esp
f0103e1b:	83 fa 13             	cmp    $0x13,%edx
f0103e1e:	0f 86 e9 00 00 00    	jbe    f0103f0d <print_trapframe+0x14c>
	return "(unknown trap)";
f0103e24:	83 fa 30             	cmp    $0x30,%edx
f0103e27:	8d 83 2d a3 f7 ff    	lea    -0x85cd3(%ebx),%eax
f0103e2d:	8d 8b 39 a3 f7 ff    	lea    -0x85cc7(%ebx),%ecx
f0103e33:	0f 45 c1             	cmovne %ecx,%eax
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103e36:	83 ec 04             	sub    $0x4,%esp
f0103e39:	50                   	push   %eax
f0103e3a:	52                   	push   %edx
f0103e3b:	8d 83 95 a3 f7 ff    	lea    -0x85c6b(%ebx),%eax
f0103e41:	50                   	push   %eax
f0103e42:	e8 11 fe ff ff       	call   f0103c58 <cprintf>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103e47:	83 c4 10             	add    $0x10,%esp
f0103e4a:	39 b3 40 2b 00 00    	cmp    %esi,0x2b40(%ebx)
f0103e50:	0f 84 c3 00 00 00    	je     f0103f19 <print_trapframe+0x158>
	cprintf("  err  0x%08x", tf->tf_err);
f0103e56:	83 ec 08             	sub    $0x8,%esp
f0103e59:	ff 76 2c             	pushl  0x2c(%esi)
f0103e5c:	8d 83 b6 a3 f7 ff    	lea    -0x85c4a(%ebx),%eax
f0103e62:	50                   	push   %eax
f0103e63:	e8 f0 fd ff ff       	call   f0103c58 <cprintf>
	if (tf->tf_trapno == T_PGFLT)
f0103e68:	83 c4 10             	add    $0x10,%esp
f0103e6b:	83 7e 28 0e          	cmpl   $0xe,0x28(%esi)
f0103e6f:	0f 85 c9 00 00 00    	jne    f0103f3e <print_trapframe+0x17d>
			tf->tf_err & 1 ? "protection" : "not-present");
f0103e75:	8b 46 2c             	mov    0x2c(%esi),%eax
		cprintf(" [%s, %s, %s]\n",
f0103e78:	89 c2                	mov    %eax,%edx
f0103e7a:	83 e2 01             	and    $0x1,%edx
f0103e7d:	8d 8b 48 a3 f7 ff    	lea    -0x85cb8(%ebx),%ecx
f0103e83:	8d 93 53 a3 f7 ff    	lea    -0x85cad(%ebx),%edx
f0103e89:	0f 44 ca             	cmove  %edx,%ecx
f0103e8c:	89 c2                	mov    %eax,%edx
f0103e8e:	83 e2 02             	and    $0x2,%edx
f0103e91:	8d 93 5f a3 f7 ff    	lea    -0x85ca1(%ebx),%edx
f0103e97:	8d bb 65 a3 f7 ff    	lea    -0x85c9b(%ebx),%edi
f0103e9d:	0f 44 d7             	cmove  %edi,%edx
f0103ea0:	83 e0 04             	and    $0x4,%eax
f0103ea3:	8d 83 6a a3 f7 ff    	lea    -0x85c96(%ebx),%eax
f0103ea9:	8d bb 7f a4 f7 ff    	lea    -0x85b81(%ebx),%edi
f0103eaf:	0f 44 c7             	cmove  %edi,%eax
f0103eb2:	51                   	push   %ecx
f0103eb3:	52                   	push   %edx
f0103eb4:	50                   	push   %eax
f0103eb5:	8d 83 c4 a3 f7 ff    	lea    -0x85c3c(%ebx),%eax
f0103ebb:	50                   	push   %eax
f0103ebc:	e8 97 fd ff ff       	call   f0103c58 <cprintf>
f0103ec1:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103ec4:	83 ec 08             	sub    $0x8,%esp
f0103ec7:	ff 76 30             	pushl  0x30(%esi)
f0103eca:	8d 83 d3 a3 f7 ff    	lea    -0x85c2d(%ebx),%eax
f0103ed0:	50                   	push   %eax
f0103ed1:	e8 82 fd ff ff       	call   f0103c58 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103ed6:	83 c4 08             	add    $0x8,%esp
f0103ed9:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103edd:	50                   	push   %eax
f0103ede:	8d 83 e2 a3 f7 ff    	lea    -0x85c1e(%ebx),%eax
f0103ee4:	50                   	push   %eax
f0103ee5:	e8 6e fd ff ff       	call   f0103c58 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103eea:	83 c4 08             	add    $0x8,%esp
f0103eed:	ff 76 38             	pushl  0x38(%esi)
f0103ef0:	8d 83 f5 a3 f7 ff    	lea    -0x85c0b(%ebx),%eax
f0103ef6:	50                   	push   %eax
f0103ef7:	e8 5c fd ff ff       	call   f0103c58 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103efc:	83 c4 10             	add    $0x10,%esp
f0103eff:	f6 46 34 03          	testb  $0x3,0x34(%esi)
f0103f03:	75 50                	jne    f0103f55 <print_trapframe+0x194>
}
f0103f05:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103f08:	5b                   	pop    %ebx
f0103f09:	5e                   	pop    %esi
f0103f0a:	5f                   	pop    %edi
f0103f0b:	5d                   	pop    %ebp
f0103f0c:	c3                   	ret    
		return excnames[trapno];
f0103f0d:	8b 84 93 60 20 00 00 	mov    0x2060(%ebx,%edx,4),%eax
f0103f14:	e9 1d ff ff ff       	jmp    f0103e36 <print_trapframe+0x75>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103f19:	83 7e 28 0e          	cmpl   $0xe,0x28(%esi)
f0103f1d:	0f 85 33 ff ff ff    	jne    f0103e56 <print_trapframe+0x95>
	asm volatile("movl %%cr2,%0" : "=r" (val));
f0103f23:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103f26:	83 ec 08             	sub    $0x8,%esp
f0103f29:	50                   	push   %eax
f0103f2a:	8d 83 a7 a3 f7 ff    	lea    -0x85c59(%ebx),%eax
f0103f30:	50                   	push   %eax
f0103f31:	e8 22 fd ff ff       	call   f0103c58 <cprintf>
f0103f36:	83 c4 10             	add    $0x10,%esp
f0103f39:	e9 18 ff ff ff       	jmp    f0103e56 <print_trapframe+0x95>
		cprintf("\n");
f0103f3e:	83 ec 0c             	sub    $0xc,%esp
f0103f41:	8d 83 61 99 f7 ff    	lea    -0x8669f(%ebx),%eax
f0103f47:	50                   	push   %eax
f0103f48:	e8 0b fd ff ff       	call   f0103c58 <cprintf>
f0103f4d:	83 c4 10             	add    $0x10,%esp
f0103f50:	e9 6f ff ff ff       	jmp    f0103ec4 <print_trapframe+0x103>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103f55:	83 ec 08             	sub    $0x8,%esp
f0103f58:	ff 76 3c             	pushl  0x3c(%esi)
f0103f5b:	8d 83 04 a4 f7 ff    	lea    -0x85bfc(%ebx),%eax
f0103f61:	50                   	push   %eax
f0103f62:	e8 f1 fc ff ff       	call   f0103c58 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103f67:	83 c4 08             	add    $0x8,%esp
f0103f6a:	0f b7 46 40          	movzwl 0x40(%esi),%eax
f0103f6e:	50                   	push   %eax
f0103f6f:	8d 83 13 a4 f7 ff    	lea    -0x85bed(%ebx),%eax
f0103f75:	50                   	push   %eax
f0103f76:	e8 dd fc ff ff       	call   f0103c58 <cprintf>
f0103f7b:	83 c4 10             	add    $0x10,%esp
}
f0103f7e:	eb 85                	jmp    f0103f05 <print_trapframe+0x144>

f0103f80 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103f80:	55                   	push   %ebp
f0103f81:	89 e5                	mov    %esp,%ebp
f0103f83:	57                   	push   %edi
f0103f84:	56                   	push   %esi
f0103f85:	53                   	push   %ebx
f0103f86:	83 ec 0c             	sub    $0xc,%esp
f0103f89:	e8 0b c2 ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f0103f8e:	81 c3 92 80 08 00    	add    $0x88092,%ebx
f0103f94:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103f97:	fc                   	cld    
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0103f98:	9c                   	pushf  
f0103f99:	58                   	pop    %eax

	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103f9a:	f6 c4 02             	test   $0x2,%ah
f0103f9d:	74 1f                	je     f0103fbe <trap+0x3e>
f0103f9f:	8d 83 26 a4 f7 ff    	lea    -0x85bda(%ebx),%eax
f0103fa5:	50                   	push   %eax
f0103fa6:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0103fac:	50                   	push   %eax
f0103fad:	68 a8 00 00 00       	push   $0xa8
f0103fb2:	8d 83 3f a4 f7 ff    	lea    -0x85bc1(%ebx),%eax
f0103fb8:	50                   	push   %eax
f0103fb9:	e8 25 c1 ff ff       	call   f01000e3 <_panic>

	cprintf("Incoming TRAP frame at %p\n", tf);
f0103fbe:	83 ec 08             	sub    $0x8,%esp
f0103fc1:	56                   	push   %esi
f0103fc2:	8d 83 4b a4 f7 ff    	lea    -0x85bb5(%ebx),%eax
f0103fc8:	50                   	push   %eax
f0103fc9:	e8 8a fc ff ff       	call   f0103c58 <cprintf>

	if ((tf->tf_cs & 3) == 3) {
f0103fce:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103fd2:	83 e0 03             	and    $0x3,%eax
f0103fd5:	83 c4 10             	add    $0x10,%esp
f0103fd8:	66 83 f8 03          	cmp    $0x3,%ax
f0103fdc:	75 1d                	jne    f0103ffb <trap+0x7b>
		// Trapped from user mode.
		assert(curenv);
f0103fde:	c7 c0 44 e3 18 f0    	mov    $0xf018e344,%eax
f0103fe4:	8b 00                	mov    (%eax),%eax
f0103fe6:	85 c0                	test   %eax,%eax
f0103fe8:	74 68                	je     f0104052 <trap+0xd2>

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103fea:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103fef:	89 c7                	mov    %eax,%edi
f0103ff1:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103ff3:	c7 c0 44 e3 18 f0    	mov    $0xf018e344,%eax
f0103ff9:	8b 30                	mov    (%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103ffb:	89 b3 40 2b 00 00    	mov    %esi,0x2b40(%ebx)
	print_trapframe(tf);
f0104001:	83 ec 0c             	sub    $0xc,%esp
f0104004:	56                   	push   %esi
f0104005:	e8 b7 fd ff ff       	call   f0103dc1 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f010400a:	83 c4 10             	add    $0x10,%esp
f010400d:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0104012:	74 5d                	je     f0104071 <trap+0xf1>
		env_destroy(curenv);
f0104014:	83 ec 0c             	sub    $0xc,%esp
f0104017:	c7 c6 44 e3 18 f0    	mov    $0xf018e344,%esi
f010401d:	ff 36                	pushl  (%esi)
f010401f:	e8 c6 fa ff ff       	call   f0103aea <env_destroy>

	// Dispatch based on what type of trap occurred
	trap_dispatch(tf);

	// Return to the current environment, which should be running.
	assert(curenv && curenv->env_status == ENV_RUNNING);
f0104024:	8b 06                	mov    (%esi),%eax
f0104026:	83 c4 10             	add    $0x10,%esp
f0104029:	85 c0                	test   %eax,%eax
f010402b:	74 06                	je     f0104033 <trap+0xb3>
f010402d:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0104031:	74 59                	je     f010408c <trap+0x10c>
f0104033:	8d 83 cc a5 f7 ff    	lea    -0x85a34(%ebx),%eax
f0104039:	50                   	push   %eax
f010403a:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f0104040:	50                   	push   %eax
f0104041:	68 c0 00 00 00       	push   $0xc0
f0104046:	8d 83 3f a4 f7 ff    	lea    -0x85bc1(%ebx),%eax
f010404c:	50                   	push   %eax
f010404d:	e8 91 c0 ff ff       	call   f01000e3 <_panic>
		assert(curenv);
f0104052:	8d 83 66 a4 f7 ff    	lea    -0x85b9a(%ebx),%eax
f0104058:	50                   	push   %eax
f0104059:	8d 83 9c 96 f7 ff    	lea    -0x86964(%ebx),%eax
f010405f:	50                   	push   %eax
f0104060:	68 ae 00 00 00       	push   $0xae
f0104065:	8d 83 3f a4 f7 ff    	lea    -0x85bc1(%ebx),%eax
f010406b:	50                   	push   %eax
f010406c:	e8 72 c0 ff ff       	call   f01000e3 <_panic>
		panic("unhandled trap in kernel");
f0104071:	83 ec 04             	sub    $0x4,%esp
f0104074:	8d 83 6d a4 f7 ff    	lea    -0x85b93(%ebx),%eax
f010407a:	50                   	push   %eax
f010407b:	68 97 00 00 00       	push   $0x97
f0104080:	8d 83 3f a4 f7 ff    	lea    -0x85bc1(%ebx),%eax
f0104086:	50                   	push   %eax
f0104087:	e8 57 c0 ff ff       	call   f01000e3 <_panic>
	env_run(curenv);
f010408c:	83 ec 0c             	sub    $0xc,%esp
f010408f:	50                   	push   %eax
f0104090:	e8 c3 fa ff ff       	call   f0103b58 <env_run>

f0104095 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0104095:	55                   	push   %ebp
f0104096:	89 e5                	mov    %esp,%ebp
f0104098:	57                   	push   %edi
f0104099:	56                   	push   %esi
f010409a:	53                   	push   %ebx
f010409b:	83 ec 0c             	sub    $0xc,%esp
f010409e:	e8 f6 c0 ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f01040a3:	81 c3 7d 7f 08 00    	add    $0x87f7d,%ebx
f01040a9:	8b 7d 08             	mov    0x8(%ebp),%edi
	asm volatile("movl %%cr2,%0" : "=r" (val));
f01040ac:	0f 20 d0             	mov    %cr2,%eax

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01040af:	ff 77 30             	pushl  0x30(%edi)
f01040b2:	50                   	push   %eax
f01040b3:	c7 c6 44 e3 18 f0    	mov    $0xf018e344,%esi
f01040b9:	8b 06                	mov    (%esi),%eax
f01040bb:	ff 70 48             	pushl  0x48(%eax)
f01040be:	8d 83 f8 a5 f7 ff    	lea    -0x85a08(%ebx),%eax
f01040c4:	50                   	push   %eax
f01040c5:	e8 8e fb ff ff       	call   f0103c58 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f01040ca:	89 3c 24             	mov    %edi,(%esp)
f01040cd:	e8 ef fc ff ff       	call   f0103dc1 <print_trapframe>
	env_destroy(curenv);
f01040d2:	83 c4 04             	add    $0x4,%esp
f01040d5:	ff 36                	pushl  (%esi)
f01040d7:	e8 0e fa ff ff       	call   f0103aea <env_destroy>
}
f01040dc:	83 c4 10             	add    $0x10,%esp
f01040df:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01040e2:	5b                   	pop    %ebx
f01040e3:	5e                   	pop    %esi
f01040e4:	5f                   	pop    %edi
f01040e5:	5d                   	pop    %ebp
f01040e6:	c3                   	ret    

f01040e7 <syscall>:
f01040e7:	55                   	push   %ebp
f01040e8:	89 e5                	mov    %esp,%ebp
f01040ea:	53                   	push   %ebx
f01040eb:	83 ec 08             	sub    $0x8,%esp
f01040ee:	e8 a6 c0 ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f01040f3:	81 c3 2d 7f 08 00    	add    $0x87f2d,%ebx
f01040f9:	8d 83 1c a6 f7 ff    	lea    -0x859e4(%ebx),%eax
f01040ff:	50                   	push   %eax
f0104100:	6a 49                	push   $0x49
f0104102:	8d 83 34 a6 f7 ff    	lea    -0x859cc(%ebx),%eax
f0104108:	50                   	push   %eax
f0104109:	e8 d5 bf ff ff       	call   f01000e3 <_panic>

f010410e <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010410e:	55                   	push   %ebp
f010410f:	89 e5                	mov    %esp,%ebp
f0104111:	57                   	push   %edi
f0104112:	56                   	push   %esi
f0104113:	53                   	push   %ebx
f0104114:	83 ec 14             	sub    $0x14,%esp
f0104117:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010411a:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010411d:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104120:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104123:	8b 32                	mov    (%edx),%esi
f0104125:	8b 01                	mov    (%ecx),%eax
f0104127:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010412a:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104131:	eb 2f                	jmp    f0104162 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0104133:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0104136:	39 c6                	cmp    %eax,%esi
f0104138:	7f 49                	jg     f0104183 <stab_binsearch+0x75>
f010413a:	0f b6 0a             	movzbl (%edx),%ecx
f010413d:	83 ea 0c             	sub    $0xc,%edx
f0104140:	39 f9                	cmp    %edi,%ecx
f0104142:	75 ef                	jne    f0104133 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0104144:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104147:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010414a:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f010414e:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0104151:	73 35                	jae    f0104188 <stab_binsearch+0x7a>
			*region_left = m;
f0104153:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104156:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0104158:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f010415b:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0104162:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0104165:	7f 4e                	jg     f01041b5 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0104167:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010416a:	01 f0                	add    %esi,%eax
f010416c:	89 c3                	mov    %eax,%ebx
f010416e:	c1 eb 1f             	shr    $0x1f,%ebx
f0104171:	01 c3                	add    %eax,%ebx
f0104173:	d1 fb                	sar    %ebx
f0104175:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0104178:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010417b:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f010417f:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0104181:	eb b3                	jmp    f0104136 <stab_binsearch+0x28>
			l = true_m + 1;
f0104183:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0104186:	eb da                	jmp    f0104162 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0104188:	3b 55 0c             	cmp    0xc(%ebp),%edx
f010418b:	76 14                	jbe    f01041a1 <stab_binsearch+0x93>
			*region_right = m - 1;
f010418d:	83 e8 01             	sub    $0x1,%eax
f0104190:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104193:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104196:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0104198:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010419f:	eb c1                	jmp    f0104162 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01041a1:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01041a4:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f01041a6:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01041aa:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f01041ac:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01041b3:	eb ad                	jmp    f0104162 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f01041b5:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01041b9:	74 16                	je     f01041d1 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01041bb:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01041be:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01041c0:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01041c3:	8b 0e                	mov    (%esi),%ecx
f01041c5:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01041c8:	8b 75 ec             	mov    -0x14(%ebp),%esi
f01041cb:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f01041cf:	eb 12                	jmp    f01041e3 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f01041d1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01041d4:	8b 00                	mov    (%eax),%eax
f01041d6:	83 e8 01             	sub    $0x1,%eax
f01041d9:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01041dc:	89 07                	mov    %eax,(%edi)
f01041de:	eb 16                	jmp    f01041f6 <stab_binsearch+0xe8>
		     l--)
f01041e0:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f01041e3:	39 c1                	cmp    %eax,%ecx
f01041e5:	7d 0a                	jge    f01041f1 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f01041e7:	0f b6 1a             	movzbl (%edx),%ebx
f01041ea:	83 ea 0c             	sub    $0xc,%edx
f01041ed:	39 fb                	cmp    %edi,%ebx
f01041ef:	75 ef                	jne    f01041e0 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f01041f1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01041f4:	89 07                	mov    %eax,(%edi)
	}
}
f01041f6:	83 c4 14             	add    $0x14,%esp
f01041f9:	5b                   	pop    %ebx
f01041fa:	5e                   	pop    %esi
f01041fb:	5f                   	pop    %edi
f01041fc:	5d                   	pop    %ebp
f01041fd:	c3                   	ret    

f01041fe <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01041fe:	55                   	push   %ebp
f01041ff:	89 e5                	mov    %esp,%ebp
f0104201:	57                   	push   %edi
f0104202:	56                   	push   %esi
f0104203:	53                   	push   %ebx
f0104204:	83 ec 4c             	sub    $0x4c,%esp
f0104207:	e8 7e f1 ff ff       	call   f010338a <__x86.get_pc_thunk.di>
f010420c:	81 c7 14 7e 08 00    	add    $0x87e14,%edi
f0104212:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104215:	8d 87 43 a6 f7 ff    	lea    -0x859bd(%edi),%eax
f010421b:	89 06                	mov    %eax,(%esi)
	info->eip_line = 0;
f010421d:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0104224:	89 46 08             	mov    %eax,0x8(%esi)
	info->eip_fn_namelen = 9;
f0104227:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f010422e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104231:	89 46 10             	mov    %eax,0x10(%esi)
	info->eip_fn_narg = 0;
f0104234:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010423b:	3d ff ff 7f ef       	cmp    $0xef7fffff,%eax
f0104240:	0f 87 2c 01 00 00    	ja     f0104372 <debuginfo_eip+0x174>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f0104246:	a1 00 00 20 00       	mov    0x200000,%eax
f010424b:	89 45 b8             	mov    %eax,-0x48(%ebp)
		stab_end = usd->stab_end;
f010424e:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f0104253:	8b 1d 08 00 20 00    	mov    0x200008,%ebx
f0104259:	89 5d b4             	mov    %ebx,-0x4c(%ebp)
		stabstr_end = usd->stabstr_end;
f010425c:	8b 1d 0c 00 20 00    	mov    0x20000c,%ebx
f0104262:	89 5d bc             	mov    %ebx,-0x44(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104265:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0104268:	39 4d b4             	cmp    %ecx,-0x4c(%ebp)
f010426b:	0f 83 e9 01 00 00    	jae    f010445a <debuginfo_eip+0x25c>
f0104271:	80 79 ff 00          	cmpb   $0x0,-0x1(%ecx)
f0104275:	0f 85 e6 01 00 00    	jne    f0104461 <debuginfo_eip+0x263>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010427b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0104282:	8b 5d b8             	mov    -0x48(%ebp),%ebx
f0104285:	29 d8                	sub    %ebx,%eax
f0104287:	c1 f8 02             	sar    $0x2,%eax
f010428a:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0104290:	83 e8 01             	sub    $0x1,%eax
f0104293:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0104296:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0104299:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010429c:	ff 75 08             	pushl  0x8(%ebp)
f010429f:	6a 64                	push   $0x64
f01042a1:	89 d8                	mov    %ebx,%eax
f01042a3:	e8 66 fe ff ff       	call   f010410e <stab_binsearch>
	if (lfile == 0)
f01042a8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01042ab:	83 c4 08             	add    $0x8,%esp
f01042ae:	85 c0                	test   %eax,%eax
f01042b0:	0f 84 b2 01 00 00    	je     f0104468 <debuginfo_eip+0x26a>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01042b6:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01042b9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01042bc:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01042bf:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01042c2:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01042c5:	ff 75 08             	pushl  0x8(%ebp)
f01042c8:	6a 24                	push   $0x24
f01042ca:	89 d8                	mov    %ebx,%eax
f01042cc:	e8 3d fe ff ff       	call   f010410e <stab_binsearch>

	if (lfun <= rfun) {
f01042d1:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01042d4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01042d7:	83 c4 08             	add    $0x8,%esp
f01042da:	39 d0                	cmp    %edx,%eax
f01042dc:	0f 8f b6 00 00 00    	jg     f0104398 <debuginfo_eip+0x19a>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01042e2:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f01042e5:	8d 1c 8b             	lea    (%ebx,%ecx,4),%ebx
f01042e8:	89 5d c4             	mov    %ebx,-0x3c(%ebp)
f01042eb:	8b 0b                	mov    (%ebx),%ecx
f01042ed:	89 cb                	mov    %ecx,%ebx
f01042ef:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f01042f2:	2b 4d b4             	sub    -0x4c(%ebp),%ecx
f01042f5:	39 cb                	cmp    %ecx,%ebx
f01042f7:	73 06                	jae    f01042ff <debuginfo_eip+0x101>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01042f9:	03 5d b4             	add    -0x4c(%ebp),%ebx
f01042fc:	89 5e 08             	mov    %ebx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f01042ff:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0104302:	8b 4b 08             	mov    0x8(%ebx),%ecx
f0104305:	89 4e 10             	mov    %ecx,0x10(%esi)
		addr -= info->eip_fn_addr;
f0104308:	29 4d 08             	sub    %ecx,0x8(%ebp)
		// Search within the function definition for the line number.
		lline = lfun;
f010430b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f010430e:	89 55 d0             	mov    %edx,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0104311:	83 ec 08             	sub    $0x8,%esp
f0104314:	6a 3a                	push   $0x3a
f0104316:	ff 76 08             	pushl  0x8(%esi)
f0104319:	89 fb                	mov    %edi,%ebx
f010431b:	e8 cb 09 00 00       	call   f0104ceb <strfind>
f0104320:	2b 46 08             	sub    0x8(%esi),%eax
f0104323:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0104326:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0104329:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f010432c:	83 c4 08             	add    $0x8,%esp
f010432f:	ff 75 08             	pushl  0x8(%ebp)
f0104332:	6a 44                	push   $0x44
f0104334:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0104337:	89 f8                	mov    %edi,%eax
f0104339:	e8 d0 fd ff ff       	call   f010410e <stab_binsearch>
	if (lline <= rline) {
f010433e:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0104341:	83 c4 10             	add    $0x10,%esp
f0104344:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0104347:	0f 8f 22 01 00 00    	jg     f010446f <debuginfo_eip+0x271>
        info->eip_line = stabs[lline].n_desc;
f010434d:	89 d0                	mov    %edx,%eax
f010434f:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104352:	c1 e2 02             	shl    $0x2,%edx
f0104355:	0f b7 4c 17 06       	movzwl 0x6(%edi,%edx,1),%ecx
f010435a:	89 4e 04             	mov    %ecx,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010435d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104360:	8d 54 17 04          	lea    0x4(%edi,%edx,1),%edx
f0104364:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0104368:	bf 01 00 00 00       	mov    $0x1,%edi
f010436d:	89 75 0c             	mov    %esi,0xc(%ebp)
f0104370:	eb 48                	jmp    f01043ba <debuginfo_eip+0x1bc>
		stabstr_end = __STABSTR_END__;
f0104372:	c7 c0 7f 1a 11 f0    	mov    $0xf0111a7f,%eax
f0104378:	89 45 bc             	mov    %eax,-0x44(%ebp)
		stabstr = __STABSTR_BEGIN__;
f010437b:	c7 c0 d9 ef 10 f0    	mov    $0xf010efd9,%eax
f0104381:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		stab_end = __STAB_END__;
f0104384:	c7 c0 d8 ef 10 f0    	mov    $0xf010efd8,%eax
		stabs = __STAB_BEGIN__;
f010438a:	c7 c3 60 68 10 f0    	mov    $0xf0106860,%ebx
f0104390:	89 5d b8             	mov    %ebx,-0x48(%ebp)
f0104393:	e9 cd fe ff ff       	jmp    f0104265 <debuginfo_eip+0x67>
		info->eip_fn_addr = addr;
f0104398:	8b 45 08             	mov    0x8(%ebp),%eax
f010439b:	89 46 10             	mov    %eax,0x10(%esi)
		lline = lfile;
f010439e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01043a1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01043a4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01043a7:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01043aa:	e9 62 ff ff ff       	jmp    f0104311 <debuginfo_eip+0x113>
f01043af:	83 e8 01             	sub    $0x1,%eax
f01043b2:	83 ea 0c             	sub    $0xc,%edx
f01043b5:	89 f9                	mov    %edi,%ecx
f01043b7:	88 4d c4             	mov    %cl,-0x3c(%ebp)
f01043ba:	89 45 c0             	mov    %eax,-0x40(%ebp)
	while (lline >= lfile
f01043bd:	39 c3                	cmp    %eax,%ebx
f01043bf:	7f 24                	jg     f01043e5 <debuginfo_eip+0x1e7>
	       && stabs[lline].n_type != N_SOL
f01043c1:	0f b6 0a             	movzbl (%edx),%ecx
f01043c4:	80 f9 84             	cmp    $0x84,%cl
f01043c7:	74 46                	je     f010440f <debuginfo_eip+0x211>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01043c9:	80 f9 64             	cmp    $0x64,%cl
f01043cc:	75 e1                	jne    f01043af <debuginfo_eip+0x1b1>
f01043ce:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f01043d2:	74 db                	je     f01043af <debuginfo_eip+0x1b1>
f01043d4:	8b 75 0c             	mov    0xc(%ebp),%esi
f01043d7:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f01043db:	74 3b                	je     f0104418 <debuginfo_eip+0x21a>
f01043dd:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01043e0:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01043e3:	eb 33                	jmp    f0104418 <debuginfo_eip+0x21a>
f01043e5:	8b 75 0c             	mov    0xc(%ebp),%esi
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01043e8:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01043eb:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01043ee:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f01043f3:	39 da                	cmp    %ebx,%edx
f01043f5:	0f 8d 80 00 00 00    	jge    f010447b <debuginfo_eip+0x27d>
		for (lline = lfun + 1;
f01043fb:	83 c2 01             	add    $0x1,%edx
f01043fe:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104401:	89 d0                	mov    %edx,%eax
f0104403:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104406:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0104409:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
f010440d:	eb 32                	jmp    f0104441 <debuginfo_eip+0x243>
f010440f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104412:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0104416:	75 1d                	jne    f0104435 <debuginfo_eip+0x237>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0104418:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010441b:	8b 7d b8             	mov    -0x48(%ebp),%edi
f010441e:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0104421:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104424:	8b 7d b4             	mov    -0x4c(%ebp),%edi
f0104427:	29 f8                	sub    %edi,%eax
f0104429:	39 c2                	cmp    %eax,%edx
f010442b:	73 bb                	jae    f01043e8 <debuginfo_eip+0x1ea>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010442d:	89 f8                	mov    %edi,%eax
f010442f:	01 d0                	add    %edx,%eax
f0104431:	89 06                	mov    %eax,(%esi)
f0104433:	eb b3                	jmp    f01043e8 <debuginfo_eip+0x1ea>
f0104435:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0104438:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010443b:	eb db                	jmp    f0104418 <debuginfo_eip+0x21a>
			info->eip_fn_narg++;
f010443d:	83 46 14 01          	addl   $0x1,0x14(%esi)
		for (lline = lfun + 1;
f0104441:	39 c3                	cmp    %eax,%ebx
f0104443:	7e 31                	jle    f0104476 <debuginfo_eip+0x278>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104445:	0f b6 0a             	movzbl (%edx),%ecx
f0104448:	83 c0 01             	add    $0x1,%eax
f010444b:	83 c2 0c             	add    $0xc,%edx
f010444e:	80 f9 a0             	cmp    $0xa0,%cl
f0104451:	74 ea                	je     f010443d <debuginfo_eip+0x23f>
	return 0;
f0104453:	b8 00 00 00 00       	mov    $0x0,%eax
f0104458:	eb 21                	jmp    f010447b <debuginfo_eip+0x27d>
		return -1;
f010445a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010445f:	eb 1a                	jmp    f010447b <debuginfo_eip+0x27d>
f0104461:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104466:	eb 13                	jmp    f010447b <debuginfo_eip+0x27d>
		return -1;
f0104468:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010446d:	eb 0c                	jmp    f010447b <debuginfo_eip+0x27d>
        return -1;
f010446f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104474:	eb 05                	jmp    f010447b <debuginfo_eip+0x27d>
	return 0;
f0104476:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010447b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010447e:	5b                   	pop    %ebx
f010447f:	5e                   	pop    %esi
f0104480:	5f                   	pop    %edi
f0104481:	5d                   	pop    %ebp
f0104482:	c3                   	ret    

f0104483 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104483:	55                   	push   %ebp
f0104484:	89 e5                	mov    %esp,%ebp
f0104486:	57                   	push   %edi
f0104487:	56                   	push   %esi
f0104488:	53                   	push   %ebx
f0104489:	83 ec 2c             	sub    $0x2c,%esp
f010448c:	e8 f5 ee ff ff       	call   f0103386 <__x86.get_pc_thunk.cx>
f0104491:	81 c1 8f 7b 08 00    	add    $0x87b8f,%ecx
f0104497:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f010449a:	89 c7                	mov    %eax,%edi
f010449c:	89 d6                	mov    %edx,%esi
f010449e:	8b 45 08             	mov    0x8(%ebp),%eax
f01044a1:	8b 55 0c             	mov    0xc(%ebp),%edx
f01044a4:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01044a7:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01044aa:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01044ad:	bb 00 00 00 00       	mov    $0x0,%ebx
f01044b2:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f01044b5:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f01044b8:	39 d3                	cmp    %edx,%ebx
f01044ba:	72 09                	jb     f01044c5 <printnum+0x42>
f01044bc:	39 45 10             	cmp    %eax,0x10(%ebp)
f01044bf:	0f 87 83 00 00 00    	ja     f0104548 <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01044c5:	83 ec 0c             	sub    $0xc,%esp
f01044c8:	ff 75 18             	pushl  0x18(%ebp)
f01044cb:	8b 45 14             	mov    0x14(%ebp),%eax
f01044ce:	8d 58 ff             	lea    -0x1(%eax),%ebx
f01044d1:	53                   	push   %ebx
f01044d2:	ff 75 10             	pushl  0x10(%ebp)
f01044d5:	83 ec 08             	sub    $0x8,%esp
f01044d8:	ff 75 dc             	pushl  -0x24(%ebp)
f01044db:	ff 75 d8             	pushl  -0x28(%ebp)
f01044de:	ff 75 d4             	pushl  -0x2c(%ebp)
f01044e1:	ff 75 d0             	pushl  -0x30(%ebp)
f01044e4:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01044e7:	e8 24 0a 00 00       	call   f0104f10 <__udivdi3>
f01044ec:	83 c4 18             	add    $0x18,%esp
f01044ef:	52                   	push   %edx
f01044f0:	50                   	push   %eax
f01044f1:	89 f2                	mov    %esi,%edx
f01044f3:	89 f8                	mov    %edi,%eax
f01044f5:	e8 89 ff ff ff       	call   f0104483 <printnum>
f01044fa:	83 c4 20             	add    $0x20,%esp
f01044fd:	eb 13                	jmp    f0104512 <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01044ff:	83 ec 08             	sub    $0x8,%esp
f0104502:	56                   	push   %esi
f0104503:	ff 75 18             	pushl  0x18(%ebp)
f0104506:	ff d7                	call   *%edi
f0104508:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f010450b:	83 eb 01             	sub    $0x1,%ebx
f010450e:	85 db                	test   %ebx,%ebx
f0104510:	7f ed                	jg     f01044ff <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104512:	83 ec 08             	sub    $0x8,%esp
f0104515:	56                   	push   %esi
f0104516:	83 ec 04             	sub    $0x4,%esp
f0104519:	ff 75 dc             	pushl  -0x24(%ebp)
f010451c:	ff 75 d8             	pushl  -0x28(%ebp)
f010451f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0104522:	ff 75 d0             	pushl  -0x30(%ebp)
f0104525:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104528:	89 f3                	mov    %esi,%ebx
f010452a:	e8 01 0b 00 00       	call   f0105030 <__umoddi3>
f010452f:	83 c4 14             	add    $0x14,%esp
f0104532:	0f be 84 06 4d a6 f7 	movsbl -0x859b3(%esi,%eax,1),%eax
f0104539:	ff 
f010453a:	50                   	push   %eax
f010453b:	ff d7                	call   *%edi
}
f010453d:	83 c4 10             	add    $0x10,%esp
f0104540:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104543:	5b                   	pop    %ebx
f0104544:	5e                   	pop    %esi
f0104545:	5f                   	pop    %edi
f0104546:	5d                   	pop    %ebp
f0104547:	c3                   	ret    
f0104548:	8b 5d 14             	mov    0x14(%ebp),%ebx
f010454b:	eb be                	jmp    f010450b <printnum+0x88>

f010454d <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f010454d:	55                   	push   %ebp
f010454e:	89 e5                	mov    %esp,%ebp
f0104550:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104553:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104557:	8b 10                	mov    (%eax),%edx
f0104559:	3b 50 04             	cmp    0x4(%eax),%edx
f010455c:	73 0a                	jae    f0104568 <sprintputch+0x1b>
		*b->buf++ = ch;
f010455e:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104561:	89 08                	mov    %ecx,(%eax)
f0104563:	8b 45 08             	mov    0x8(%ebp),%eax
f0104566:	88 02                	mov    %al,(%edx)
}
f0104568:	5d                   	pop    %ebp
f0104569:	c3                   	ret    

f010456a <printfmt>:
{
f010456a:	55                   	push   %ebp
f010456b:	89 e5                	mov    %esp,%ebp
f010456d:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0104570:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104573:	50                   	push   %eax
f0104574:	ff 75 10             	pushl  0x10(%ebp)
f0104577:	ff 75 0c             	pushl  0xc(%ebp)
f010457a:	ff 75 08             	pushl  0x8(%ebp)
f010457d:	e8 05 00 00 00       	call   f0104587 <vprintfmt>
}
f0104582:	83 c4 10             	add    $0x10,%esp
f0104585:	c9                   	leave  
f0104586:	c3                   	ret    

f0104587 <vprintfmt>:
{
f0104587:	55                   	push   %ebp
f0104588:	89 e5                	mov    %esp,%ebp
f010458a:	57                   	push   %edi
f010458b:	56                   	push   %esi
f010458c:	53                   	push   %ebx
f010458d:	83 ec 2c             	sub    $0x2c,%esp
f0104590:	e8 04 bc ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f0104595:	81 c3 8b 7a 08 00    	add    $0x87a8b,%ebx
f010459b:	8b 75 0c             	mov    0xc(%ebp),%esi
f010459e:	8b 7d 10             	mov    0x10(%ebp),%edi
f01045a1:	e9 63 03 00 00       	jmp    f0104909 <.L34+0x40>
		padc = ' ';
f01045a6:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f01045aa:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f01045b1:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
		width = -1;
f01045b8:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f01045bf:	b9 00 00 00 00       	mov    $0x0,%ecx
f01045c4:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01045c7:	8d 47 01             	lea    0x1(%edi),%eax
f01045ca:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01045cd:	0f b6 17             	movzbl (%edi),%edx
f01045d0:	8d 42 dd             	lea    -0x23(%edx),%eax
f01045d3:	3c 55                	cmp    $0x55,%al
f01045d5:	0f 87 15 04 00 00    	ja     f01049f0 <.L22>
f01045db:	0f b6 c0             	movzbl %al,%eax
f01045de:	89 d9                	mov    %ebx,%ecx
f01045e0:	03 8c 83 d8 a6 f7 ff 	add    -0x85928(%ebx,%eax,4),%ecx
f01045e7:	ff e1                	jmp    *%ecx

f01045e9 <.L70>:
f01045e9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f01045ec:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f01045f0:	eb d5                	jmp    f01045c7 <vprintfmt+0x40>

f01045f2 <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f01045f2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f01045f5:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f01045f9:	eb cc                	jmp    f01045c7 <vprintfmt+0x40>

f01045fb <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f01045fb:	0f b6 d2             	movzbl %dl,%edx
f01045fe:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0104601:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f0104606:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0104609:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f010460d:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0104610:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0104613:	83 f9 09             	cmp    $0x9,%ecx
f0104616:	77 55                	ja     f010466d <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f0104618:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f010461b:	eb e9                	jmp    f0104606 <.L29+0xb>

f010461d <.L26>:
			precision = va_arg(ap, int);
f010461d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104620:	8b 00                	mov    (%eax),%eax
f0104622:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0104625:	8b 45 14             	mov    0x14(%ebp),%eax
f0104628:	8d 40 04             	lea    0x4(%eax),%eax
f010462b:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010462e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0104631:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104635:	79 90                	jns    f01045c7 <vprintfmt+0x40>
				width = precision, precision = -1;
f0104637:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010463a:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010463d:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f0104644:	eb 81                	jmp    f01045c7 <vprintfmt+0x40>

f0104646 <.L27>:
f0104646:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104649:	85 c0                	test   %eax,%eax
f010464b:	ba 00 00 00 00       	mov    $0x0,%edx
f0104650:	0f 49 d0             	cmovns %eax,%edx
f0104653:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0104656:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104659:	e9 69 ff ff ff       	jmp    f01045c7 <vprintfmt+0x40>

f010465e <.L23>:
f010465e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0104661:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0104668:	e9 5a ff ff ff       	jmp    f01045c7 <vprintfmt+0x40>
f010466d:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0104670:	eb bf                	jmp    f0104631 <.L26+0x14>

f0104672 <.L33>:
			lflag++;
f0104672:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0104676:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0104679:	e9 49 ff ff ff       	jmp    f01045c7 <vprintfmt+0x40>

f010467e <.L30>:
			putch(va_arg(ap, int), putdat);
f010467e:	8b 45 14             	mov    0x14(%ebp),%eax
f0104681:	8d 78 04             	lea    0x4(%eax),%edi
f0104684:	83 ec 08             	sub    $0x8,%esp
f0104687:	56                   	push   %esi
f0104688:	ff 30                	pushl  (%eax)
f010468a:	ff 55 08             	call   *0x8(%ebp)
			break;
f010468d:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0104690:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0104693:	e9 6e 02 00 00       	jmp    f0104906 <.L34+0x3d>

f0104698 <.L32>:
			err = va_arg(ap, int);
f0104698:	8b 45 14             	mov    0x14(%ebp),%eax
f010469b:	8d 78 04             	lea    0x4(%eax),%edi
f010469e:	8b 00                	mov    (%eax),%eax
f01046a0:	99                   	cltd   
f01046a1:	31 d0                	xor    %edx,%eax
f01046a3:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01046a5:	83 f8 06             	cmp    $0x6,%eax
f01046a8:	7f 27                	jg     f01046d1 <.L32+0x39>
f01046aa:	8b 94 83 b0 20 00 00 	mov    0x20b0(%ebx,%eax,4),%edx
f01046b1:	85 d2                	test   %edx,%edx
f01046b3:	74 1c                	je     f01046d1 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f01046b5:	52                   	push   %edx
f01046b6:	8d 83 ae 96 f7 ff    	lea    -0x86952(%ebx),%eax
f01046bc:	50                   	push   %eax
f01046bd:	56                   	push   %esi
f01046be:	ff 75 08             	pushl  0x8(%ebp)
f01046c1:	e8 a4 fe ff ff       	call   f010456a <printfmt>
f01046c6:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01046c9:	89 7d 14             	mov    %edi,0x14(%ebp)
f01046cc:	e9 35 02 00 00       	jmp    f0104906 <.L34+0x3d>
				printfmt(putch, putdat, "error %d", err);
f01046d1:	50                   	push   %eax
f01046d2:	8d 83 65 a6 f7 ff    	lea    -0x8599b(%ebx),%eax
f01046d8:	50                   	push   %eax
f01046d9:	56                   	push   %esi
f01046da:	ff 75 08             	pushl  0x8(%ebp)
f01046dd:	e8 88 fe ff ff       	call   f010456a <printfmt>
f01046e2:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01046e5:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f01046e8:	e9 19 02 00 00       	jmp    f0104906 <.L34+0x3d>

f01046ed <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f01046ed:	8b 45 14             	mov    0x14(%ebp),%eax
f01046f0:	83 c0 04             	add    $0x4,%eax
f01046f3:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01046f6:	8b 45 14             	mov    0x14(%ebp),%eax
f01046f9:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01046fb:	85 ff                	test   %edi,%edi
f01046fd:	8d 83 5e a6 f7 ff    	lea    -0x859a2(%ebx),%eax
f0104703:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0104706:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010470a:	0f 8e b5 00 00 00    	jle    f01047c5 <.L36+0xd8>
f0104710:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0104714:	75 08                	jne    f010471e <.L36+0x31>
f0104716:	89 75 0c             	mov    %esi,0xc(%ebp)
f0104719:	8b 75 cc             	mov    -0x34(%ebp),%esi
f010471c:	eb 6d                	jmp    f010478b <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f010471e:	83 ec 08             	sub    $0x8,%esp
f0104721:	ff 75 cc             	pushl  -0x34(%ebp)
f0104724:	57                   	push   %edi
f0104725:	e8 7d 04 00 00       	call   f0104ba7 <strnlen>
f010472a:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010472d:	29 c2                	sub    %eax,%edx
f010472f:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0104732:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0104735:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0104739:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010473c:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010473f:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0104741:	eb 10                	jmp    f0104753 <.L36+0x66>
					putch(padc, putdat);
f0104743:	83 ec 08             	sub    $0x8,%esp
f0104746:	56                   	push   %esi
f0104747:	ff 75 e0             	pushl  -0x20(%ebp)
f010474a:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f010474d:	83 ef 01             	sub    $0x1,%edi
f0104750:	83 c4 10             	add    $0x10,%esp
f0104753:	85 ff                	test   %edi,%edi
f0104755:	7f ec                	jg     f0104743 <.L36+0x56>
f0104757:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010475a:	8b 55 c8             	mov    -0x38(%ebp),%edx
f010475d:	85 d2                	test   %edx,%edx
f010475f:	b8 00 00 00 00       	mov    $0x0,%eax
f0104764:	0f 49 c2             	cmovns %edx,%eax
f0104767:	29 c2                	sub    %eax,%edx
f0104769:	89 55 e0             	mov    %edx,-0x20(%ebp)
f010476c:	89 75 0c             	mov    %esi,0xc(%ebp)
f010476f:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0104772:	eb 17                	jmp    f010478b <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f0104774:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104778:	75 30                	jne    f01047aa <.L36+0xbd>
					putch(ch, putdat);
f010477a:	83 ec 08             	sub    $0x8,%esp
f010477d:	ff 75 0c             	pushl  0xc(%ebp)
f0104780:	50                   	push   %eax
f0104781:	ff 55 08             	call   *0x8(%ebp)
f0104784:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104787:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f010478b:	83 c7 01             	add    $0x1,%edi
f010478e:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0104792:	0f be c2             	movsbl %dl,%eax
f0104795:	85 c0                	test   %eax,%eax
f0104797:	74 52                	je     f01047eb <.L36+0xfe>
f0104799:	85 f6                	test   %esi,%esi
f010479b:	78 d7                	js     f0104774 <.L36+0x87>
f010479d:	83 ee 01             	sub    $0x1,%esi
f01047a0:	79 d2                	jns    f0104774 <.L36+0x87>
f01047a2:	8b 75 0c             	mov    0xc(%ebp),%esi
f01047a5:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01047a8:	eb 32                	jmp    f01047dc <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f01047aa:	0f be d2             	movsbl %dl,%edx
f01047ad:	83 ea 20             	sub    $0x20,%edx
f01047b0:	83 fa 5e             	cmp    $0x5e,%edx
f01047b3:	76 c5                	jbe    f010477a <.L36+0x8d>
					putch('?', putdat);
f01047b5:	83 ec 08             	sub    $0x8,%esp
f01047b8:	ff 75 0c             	pushl  0xc(%ebp)
f01047bb:	6a 3f                	push   $0x3f
f01047bd:	ff 55 08             	call   *0x8(%ebp)
f01047c0:	83 c4 10             	add    $0x10,%esp
f01047c3:	eb c2                	jmp    f0104787 <.L36+0x9a>
f01047c5:	89 75 0c             	mov    %esi,0xc(%ebp)
f01047c8:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01047cb:	eb be                	jmp    f010478b <.L36+0x9e>
				putch(' ', putdat);
f01047cd:	83 ec 08             	sub    $0x8,%esp
f01047d0:	56                   	push   %esi
f01047d1:	6a 20                	push   $0x20
f01047d3:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f01047d6:	83 ef 01             	sub    $0x1,%edi
f01047d9:	83 c4 10             	add    $0x10,%esp
f01047dc:	85 ff                	test   %edi,%edi
f01047de:	7f ed                	jg     f01047cd <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f01047e0:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01047e3:	89 45 14             	mov    %eax,0x14(%ebp)
f01047e6:	e9 1b 01 00 00       	jmp    f0104906 <.L34+0x3d>
f01047eb:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01047ee:	8b 75 0c             	mov    0xc(%ebp),%esi
f01047f1:	eb e9                	jmp    f01047dc <.L36+0xef>

f01047f3 <.L31>:
f01047f3:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01047f6:	83 f9 01             	cmp    $0x1,%ecx
f01047f9:	7e 40                	jle    f010483b <.L31+0x48>
		return va_arg(*ap, long long);
f01047fb:	8b 45 14             	mov    0x14(%ebp),%eax
f01047fe:	8b 50 04             	mov    0x4(%eax),%edx
f0104801:	8b 00                	mov    (%eax),%eax
f0104803:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104806:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104809:	8b 45 14             	mov    0x14(%ebp),%eax
f010480c:	8d 40 08             	lea    0x8(%eax),%eax
f010480f:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0104812:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104816:	79 55                	jns    f010486d <.L31+0x7a>
				putch('-', putdat);
f0104818:	83 ec 08             	sub    $0x8,%esp
f010481b:	56                   	push   %esi
f010481c:	6a 2d                	push   $0x2d
f010481e:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0104821:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104824:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0104827:	f7 da                	neg    %edx
f0104829:	83 d1 00             	adc    $0x0,%ecx
f010482c:	f7 d9                	neg    %ecx
f010482e:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0104831:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104836:	e9 b0 00 00 00       	jmp    f01048eb <.L34+0x22>
	else if (lflag)
f010483b:	85 c9                	test   %ecx,%ecx
f010483d:	75 17                	jne    f0104856 <.L31+0x63>
		return va_arg(*ap, int);
f010483f:	8b 45 14             	mov    0x14(%ebp),%eax
f0104842:	8b 00                	mov    (%eax),%eax
f0104844:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104847:	99                   	cltd   
f0104848:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010484b:	8b 45 14             	mov    0x14(%ebp),%eax
f010484e:	8d 40 04             	lea    0x4(%eax),%eax
f0104851:	89 45 14             	mov    %eax,0x14(%ebp)
f0104854:	eb bc                	jmp    f0104812 <.L31+0x1f>
		return va_arg(*ap, long);
f0104856:	8b 45 14             	mov    0x14(%ebp),%eax
f0104859:	8b 00                	mov    (%eax),%eax
f010485b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010485e:	99                   	cltd   
f010485f:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104862:	8b 45 14             	mov    0x14(%ebp),%eax
f0104865:	8d 40 04             	lea    0x4(%eax),%eax
f0104868:	89 45 14             	mov    %eax,0x14(%ebp)
f010486b:	eb a5                	jmp    f0104812 <.L31+0x1f>
			num = getint(&ap, lflag);
f010486d:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104870:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0104873:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104878:	eb 71                	jmp    f01048eb <.L34+0x22>

f010487a <.L37>:
f010487a:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f010487d:	83 f9 01             	cmp    $0x1,%ecx
f0104880:	7e 15                	jle    f0104897 <.L37+0x1d>
		return va_arg(*ap, unsigned long long);
f0104882:	8b 45 14             	mov    0x14(%ebp),%eax
f0104885:	8b 10                	mov    (%eax),%edx
f0104887:	8b 48 04             	mov    0x4(%eax),%ecx
f010488a:	8d 40 08             	lea    0x8(%eax),%eax
f010488d:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0104890:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104895:	eb 54                	jmp    f01048eb <.L34+0x22>
	else if (lflag)
f0104897:	85 c9                	test   %ecx,%ecx
f0104899:	75 17                	jne    f01048b2 <.L37+0x38>
		return va_arg(*ap, unsigned int);
f010489b:	8b 45 14             	mov    0x14(%ebp),%eax
f010489e:	8b 10                	mov    (%eax),%edx
f01048a0:	b9 00 00 00 00       	mov    $0x0,%ecx
f01048a5:	8d 40 04             	lea    0x4(%eax),%eax
f01048a8:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01048ab:	b8 0a 00 00 00       	mov    $0xa,%eax
f01048b0:	eb 39                	jmp    f01048eb <.L34+0x22>
		return va_arg(*ap, unsigned long);
f01048b2:	8b 45 14             	mov    0x14(%ebp),%eax
f01048b5:	8b 10                	mov    (%eax),%edx
f01048b7:	b9 00 00 00 00       	mov    $0x0,%ecx
f01048bc:	8d 40 04             	lea    0x4(%eax),%eax
f01048bf:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01048c2:	b8 0a 00 00 00       	mov    $0xa,%eax
f01048c7:	eb 22                	jmp    f01048eb <.L34+0x22>

f01048c9 <.L34>:
f01048c9:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01048cc:	83 f9 01             	cmp    $0x1,%ecx
f01048cf:	7e 5d                	jle    f010492e <.L34+0x65>
		return va_arg(*ap, long long);
f01048d1:	8b 45 14             	mov    0x14(%ebp),%eax
f01048d4:	8b 50 04             	mov    0x4(%eax),%edx
f01048d7:	8b 00                	mov    (%eax),%eax
f01048d9:	8b 4d 14             	mov    0x14(%ebp),%ecx
f01048dc:	8d 49 08             	lea    0x8(%ecx),%ecx
f01048df:	89 4d 14             	mov    %ecx,0x14(%ebp)
			num = getint(&ap, lflag);
f01048e2:	89 d1                	mov    %edx,%ecx
f01048e4:	89 c2                	mov    %eax,%edx
			base = 8;
f01048e6:	b8 08 00 00 00       	mov    $0x8,%eax
			printnum(putch, putdat, num, base, width, padc);
f01048eb:	83 ec 0c             	sub    $0xc,%esp
f01048ee:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01048f2:	57                   	push   %edi
f01048f3:	ff 75 e0             	pushl  -0x20(%ebp)
f01048f6:	50                   	push   %eax
f01048f7:	51                   	push   %ecx
f01048f8:	52                   	push   %edx
f01048f9:	89 f2                	mov    %esi,%edx
f01048fb:	8b 45 08             	mov    0x8(%ebp),%eax
f01048fe:	e8 80 fb ff ff       	call   f0104483 <printnum>
			break;
f0104903:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0104906:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104909:	83 c7 01             	add    $0x1,%edi
f010490c:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104910:	83 f8 25             	cmp    $0x25,%eax
f0104913:	0f 84 8d fc ff ff    	je     f01045a6 <vprintfmt+0x1f>
			if (ch == '\0')
f0104919:	85 c0                	test   %eax,%eax
f010491b:	0f 84 f0 00 00 00    	je     f0104a11 <.L22+0x21>
			putch(ch, putdat);
f0104921:	83 ec 08             	sub    $0x8,%esp
f0104924:	56                   	push   %esi
f0104925:	50                   	push   %eax
f0104926:	ff 55 08             	call   *0x8(%ebp)
f0104929:	83 c4 10             	add    $0x10,%esp
f010492c:	eb db                	jmp    f0104909 <.L34+0x40>
	else if (lflag)
f010492e:	85 c9                	test   %ecx,%ecx
f0104930:	75 13                	jne    f0104945 <.L34+0x7c>
		return va_arg(*ap, int);
f0104932:	8b 45 14             	mov    0x14(%ebp),%eax
f0104935:	8b 10                	mov    (%eax),%edx
f0104937:	89 d0                	mov    %edx,%eax
f0104939:	99                   	cltd   
f010493a:	8b 4d 14             	mov    0x14(%ebp),%ecx
f010493d:	8d 49 04             	lea    0x4(%ecx),%ecx
f0104940:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0104943:	eb 9d                	jmp    f01048e2 <.L34+0x19>
		return va_arg(*ap, long);
f0104945:	8b 45 14             	mov    0x14(%ebp),%eax
f0104948:	8b 10                	mov    (%eax),%edx
f010494a:	89 d0                	mov    %edx,%eax
f010494c:	99                   	cltd   
f010494d:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0104950:	8d 49 04             	lea    0x4(%ecx),%ecx
f0104953:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0104956:	eb 8a                	jmp    f01048e2 <.L34+0x19>

f0104958 <.L35>:
			putch('0', putdat);
f0104958:	83 ec 08             	sub    $0x8,%esp
f010495b:	56                   	push   %esi
f010495c:	6a 30                	push   $0x30
f010495e:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0104961:	83 c4 08             	add    $0x8,%esp
f0104964:	56                   	push   %esi
f0104965:	6a 78                	push   $0x78
f0104967:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f010496a:	8b 45 14             	mov    0x14(%ebp),%eax
f010496d:	8b 10                	mov    (%eax),%edx
f010496f:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0104974:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0104977:	8d 40 04             	lea    0x4(%eax),%eax
f010497a:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010497d:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0104982:	e9 64 ff ff ff       	jmp    f01048eb <.L34+0x22>

f0104987 <.L38>:
f0104987:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f010498a:	83 f9 01             	cmp    $0x1,%ecx
f010498d:	7e 18                	jle    f01049a7 <.L38+0x20>
		return va_arg(*ap, unsigned long long);
f010498f:	8b 45 14             	mov    0x14(%ebp),%eax
f0104992:	8b 10                	mov    (%eax),%edx
f0104994:	8b 48 04             	mov    0x4(%eax),%ecx
f0104997:	8d 40 08             	lea    0x8(%eax),%eax
f010499a:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010499d:	b8 10 00 00 00       	mov    $0x10,%eax
f01049a2:	e9 44 ff ff ff       	jmp    f01048eb <.L34+0x22>
	else if (lflag)
f01049a7:	85 c9                	test   %ecx,%ecx
f01049a9:	75 1a                	jne    f01049c5 <.L38+0x3e>
		return va_arg(*ap, unsigned int);
f01049ab:	8b 45 14             	mov    0x14(%ebp),%eax
f01049ae:	8b 10                	mov    (%eax),%edx
f01049b0:	b9 00 00 00 00       	mov    $0x0,%ecx
f01049b5:	8d 40 04             	lea    0x4(%eax),%eax
f01049b8:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01049bb:	b8 10 00 00 00       	mov    $0x10,%eax
f01049c0:	e9 26 ff ff ff       	jmp    f01048eb <.L34+0x22>
		return va_arg(*ap, unsigned long);
f01049c5:	8b 45 14             	mov    0x14(%ebp),%eax
f01049c8:	8b 10                	mov    (%eax),%edx
f01049ca:	b9 00 00 00 00       	mov    $0x0,%ecx
f01049cf:	8d 40 04             	lea    0x4(%eax),%eax
f01049d2:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01049d5:	b8 10 00 00 00       	mov    $0x10,%eax
f01049da:	e9 0c ff ff ff       	jmp    f01048eb <.L34+0x22>

f01049df <.L25>:
			putch(ch, putdat);
f01049df:	83 ec 08             	sub    $0x8,%esp
f01049e2:	56                   	push   %esi
f01049e3:	6a 25                	push   $0x25
f01049e5:	ff 55 08             	call   *0x8(%ebp)
			break;
f01049e8:	83 c4 10             	add    $0x10,%esp
f01049eb:	e9 16 ff ff ff       	jmp    f0104906 <.L34+0x3d>

f01049f0 <.L22>:
			putch('%', putdat);
f01049f0:	83 ec 08             	sub    $0x8,%esp
f01049f3:	56                   	push   %esi
f01049f4:	6a 25                	push   $0x25
f01049f6:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01049f9:	83 c4 10             	add    $0x10,%esp
f01049fc:	89 f8                	mov    %edi,%eax
f01049fe:	eb 03                	jmp    f0104a03 <.L22+0x13>
f0104a00:	83 e8 01             	sub    $0x1,%eax
f0104a03:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0104a07:	75 f7                	jne    f0104a00 <.L22+0x10>
f0104a09:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104a0c:	e9 f5 fe ff ff       	jmp    f0104906 <.L34+0x3d>
}
f0104a11:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104a14:	5b                   	pop    %ebx
f0104a15:	5e                   	pop    %esi
f0104a16:	5f                   	pop    %edi
f0104a17:	5d                   	pop    %ebp
f0104a18:	c3                   	ret    

f0104a19 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104a19:	55                   	push   %ebp
f0104a1a:	89 e5                	mov    %esp,%ebp
f0104a1c:	53                   	push   %ebx
f0104a1d:	83 ec 14             	sub    $0x14,%esp
f0104a20:	e8 74 b7 ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f0104a25:	81 c3 fb 75 08 00    	add    $0x875fb,%ebx
f0104a2b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a2e:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104a31:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104a34:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104a38:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104a3b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104a42:	85 c0                	test   %eax,%eax
f0104a44:	74 2b                	je     f0104a71 <vsnprintf+0x58>
f0104a46:	85 d2                	test   %edx,%edx
f0104a48:	7e 27                	jle    f0104a71 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104a4a:	ff 75 14             	pushl  0x14(%ebp)
f0104a4d:	ff 75 10             	pushl  0x10(%ebp)
f0104a50:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104a53:	50                   	push   %eax
f0104a54:	8d 83 2d 85 f7 ff    	lea    -0x87ad3(%ebx),%eax
f0104a5a:	50                   	push   %eax
f0104a5b:	e8 27 fb ff ff       	call   f0104587 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104a60:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104a63:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104a66:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104a69:	83 c4 10             	add    $0x10,%esp
}
f0104a6c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104a6f:	c9                   	leave  
f0104a70:	c3                   	ret    
		return -E_INVAL;
f0104a71:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104a76:	eb f4                	jmp    f0104a6c <vsnprintf+0x53>

f0104a78 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104a78:	55                   	push   %ebp
f0104a79:	89 e5                	mov    %esp,%ebp
f0104a7b:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104a7e:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104a81:	50                   	push   %eax
f0104a82:	ff 75 10             	pushl  0x10(%ebp)
f0104a85:	ff 75 0c             	pushl  0xc(%ebp)
f0104a88:	ff 75 08             	pushl  0x8(%ebp)
f0104a8b:	e8 89 ff ff ff       	call   f0104a19 <vsnprintf>
	va_end(ap);

	return rc;
}
f0104a90:	c9                   	leave  
f0104a91:	c3                   	ret    

f0104a92 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104a92:	55                   	push   %ebp
f0104a93:	89 e5                	mov    %esp,%ebp
f0104a95:	57                   	push   %edi
f0104a96:	56                   	push   %esi
f0104a97:	53                   	push   %ebx
f0104a98:	83 ec 1c             	sub    $0x1c,%esp
f0104a9b:	e8 f9 b6 ff ff       	call   f0100199 <__x86.get_pc_thunk.bx>
f0104aa0:	81 c3 80 75 08 00    	add    $0x87580,%ebx
f0104aa6:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104aa9:	85 c0                	test   %eax,%eax
f0104aab:	74 13                	je     f0104ac0 <readline+0x2e>
		cprintf("%s", prompt);
f0104aad:	83 ec 08             	sub    $0x8,%esp
f0104ab0:	50                   	push   %eax
f0104ab1:	8d 83 ae 96 f7 ff    	lea    -0x86952(%ebx),%eax
f0104ab7:	50                   	push   %eax
f0104ab8:	e8 9b f1 ff ff       	call   f0103c58 <cprintf>
f0104abd:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104ac0:	83 ec 0c             	sub    $0xc,%esp
f0104ac3:	6a 00                	push   $0x0
f0104ac5:	e8 67 bc ff ff       	call   f0100731 <iscons>
f0104aca:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104acd:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0104ad0:	bf 00 00 00 00       	mov    $0x0,%edi
f0104ad5:	eb 46                	jmp    f0104b1d <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0104ad7:	83 ec 08             	sub    $0x8,%esp
f0104ada:	50                   	push   %eax
f0104adb:	8d 83 30 a8 f7 ff    	lea    -0x857d0(%ebx),%eax
f0104ae1:	50                   	push   %eax
f0104ae2:	e8 71 f1 ff ff       	call   f0103c58 <cprintf>
			return NULL;
f0104ae7:	83 c4 10             	add    $0x10,%esp
f0104aea:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0104aef:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104af2:	5b                   	pop    %ebx
f0104af3:	5e                   	pop    %esi
f0104af4:	5f                   	pop    %edi
f0104af5:	5d                   	pop    %ebp
f0104af6:	c3                   	ret    
			if (echoing)
f0104af7:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104afb:	75 05                	jne    f0104b02 <readline+0x70>
			i--;
f0104afd:	83 ef 01             	sub    $0x1,%edi
f0104b00:	eb 1b                	jmp    f0104b1d <readline+0x8b>
				cputchar('\b');
f0104b02:	83 ec 0c             	sub    $0xc,%esp
f0104b05:	6a 08                	push   $0x8
f0104b07:	e8 04 bc ff ff       	call   f0100710 <cputchar>
f0104b0c:	83 c4 10             	add    $0x10,%esp
f0104b0f:	eb ec                	jmp    f0104afd <readline+0x6b>
			buf[i++] = c;
f0104b11:	89 f0                	mov    %esi,%eax
f0104b13:	88 84 3b e0 2b 00 00 	mov    %al,0x2be0(%ebx,%edi,1)
f0104b1a:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0104b1d:	e8 fe bb ff ff       	call   f0100720 <getchar>
f0104b22:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0104b24:	85 c0                	test   %eax,%eax
f0104b26:	78 af                	js     f0104ad7 <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104b28:	83 f8 08             	cmp    $0x8,%eax
f0104b2b:	0f 94 c2             	sete   %dl
f0104b2e:	83 f8 7f             	cmp    $0x7f,%eax
f0104b31:	0f 94 c0             	sete   %al
f0104b34:	08 c2                	or     %al,%dl
f0104b36:	74 04                	je     f0104b3c <readline+0xaa>
f0104b38:	85 ff                	test   %edi,%edi
f0104b3a:	7f bb                	jg     f0104af7 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104b3c:	83 fe 1f             	cmp    $0x1f,%esi
f0104b3f:	7e 1c                	jle    f0104b5d <readline+0xcb>
f0104b41:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0104b47:	7f 14                	jg     f0104b5d <readline+0xcb>
			if (echoing)
f0104b49:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104b4d:	74 c2                	je     f0104b11 <readline+0x7f>
				cputchar(c);
f0104b4f:	83 ec 0c             	sub    $0xc,%esp
f0104b52:	56                   	push   %esi
f0104b53:	e8 b8 bb ff ff       	call   f0100710 <cputchar>
f0104b58:	83 c4 10             	add    $0x10,%esp
f0104b5b:	eb b4                	jmp    f0104b11 <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f0104b5d:	83 fe 0a             	cmp    $0xa,%esi
f0104b60:	74 05                	je     f0104b67 <readline+0xd5>
f0104b62:	83 fe 0d             	cmp    $0xd,%esi
f0104b65:	75 b6                	jne    f0104b1d <readline+0x8b>
			if (echoing)
f0104b67:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104b6b:	75 13                	jne    f0104b80 <readline+0xee>
			buf[i] = 0;
f0104b6d:	c6 84 3b e0 2b 00 00 	movb   $0x0,0x2be0(%ebx,%edi,1)
f0104b74:	00 
			return buf;
f0104b75:	8d 83 e0 2b 00 00    	lea    0x2be0(%ebx),%eax
f0104b7b:	e9 6f ff ff ff       	jmp    f0104aef <readline+0x5d>
				cputchar('\n');
f0104b80:	83 ec 0c             	sub    $0xc,%esp
f0104b83:	6a 0a                	push   $0xa
f0104b85:	e8 86 bb ff ff       	call   f0100710 <cputchar>
f0104b8a:	83 c4 10             	add    $0x10,%esp
f0104b8d:	eb de                	jmp    f0104b6d <readline+0xdb>

f0104b8f <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104b8f:	55                   	push   %ebp
f0104b90:	89 e5                	mov    %esp,%ebp
f0104b92:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104b95:	b8 00 00 00 00       	mov    $0x0,%eax
f0104b9a:	eb 03                	jmp    f0104b9f <strlen+0x10>
		n++;
f0104b9c:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0104b9f:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104ba3:	75 f7                	jne    f0104b9c <strlen+0xd>
	return n;
}
f0104ba5:	5d                   	pop    %ebp
f0104ba6:	c3                   	ret    

f0104ba7 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104ba7:	55                   	push   %ebp
f0104ba8:	89 e5                	mov    %esp,%ebp
f0104baa:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104bad:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104bb0:	b8 00 00 00 00       	mov    $0x0,%eax
f0104bb5:	eb 03                	jmp    f0104bba <strnlen+0x13>
		n++;
f0104bb7:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104bba:	39 d0                	cmp    %edx,%eax
f0104bbc:	74 06                	je     f0104bc4 <strnlen+0x1d>
f0104bbe:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0104bc2:	75 f3                	jne    f0104bb7 <strnlen+0x10>
	return n;
}
f0104bc4:	5d                   	pop    %ebp
f0104bc5:	c3                   	ret    

f0104bc6 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104bc6:	55                   	push   %ebp
f0104bc7:	89 e5                	mov    %esp,%ebp
f0104bc9:	53                   	push   %ebx
f0104bca:	8b 45 08             	mov    0x8(%ebp),%eax
f0104bcd:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104bd0:	89 c2                	mov    %eax,%edx
f0104bd2:	83 c1 01             	add    $0x1,%ecx
f0104bd5:	83 c2 01             	add    $0x1,%edx
f0104bd8:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104bdc:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104bdf:	84 db                	test   %bl,%bl
f0104be1:	75 ef                	jne    f0104bd2 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104be3:	5b                   	pop    %ebx
f0104be4:	5d                   	pop    %ebp
f0104be5:	c3                   	ret    

f0104be6 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104be6:	55                   	push   %ebp
f0104be7:	89 e5                	mov    %esp,%ebp
f0104be9:	53                   	push   %ebx
f0104bea:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104bed:	53                   	push   %ebx
f0104bee:	e8 9c ff ff ff       	call   f0104b8f <strlen>
f0104bf3:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0104bf6:	ff 75 0c             	pushl  0xc(%ebp)
f0104bf9:	01 d8                	add    %ebx,%eax
f0104bfb:	50                   	push   %eax
f0104bfc:	e8 c5 ff ff ff       	call   f0104bc6 <strcpy>
	return dst;
}
f0104c01:	89 d8                	mov    %ebx,%eax
f0104c03:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104c06:	c9                   	leave  
f0104c07:	c3                   	ret    

f0104c08 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104c08:	55                   	push   %ebp
f0104c09:	89 e5                	mov    %esp,%ebp
f0104c0b:	56                   	push   %esi
f0104c0c:	53                   	push   %ebx
f0104c0d:	8b 75 08             	mov    0x8(%ebp),%esi
f0104c10:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104c13:	89 f3                	mov    %esi,%ebx
f0104c15:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104c18:	89 f2                	mov    %esi,%edx
f0104c1a:	eb 0f                	jmp    f0104c2b <strncpy+0x23>
		*dst++ = *src;
f0104c1c:	83 c2 01             	add    $0x1,%edx
f0104c1f:	0f b6 01             	movzbl (%ecx),%eax
f0104c22:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104c25:	80 39 01             	cmpb   $0x1,(%ecx)
f0104c28:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0104c2b:	39 da                	cmp    %ebx,%edx
f0104c2d:	75 ed                	jne    f0104c1c <strncpy+0x14>
	}
	return ret;
}
f0104c2f:	89 f0                	mov    %esi,%eax
f0104c31:	5b                   	pop    %ebx
f0104c32:	5e                   	pop    %esi
f0104c33:	5d                   	pop    %ebp
f0104c34:	c3                   	ret    

f0104c35 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104c35:	55                   	push   %ebp
f0104c36:	89 e5                	mov    %esp,%ebp
f0104c38:	56                   	push   %esi
f0104c39:	53                   	push   %ebx
f0104c3a:	8b 75 08             	mov    0x8(%ebp),%esi
f0104c3d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104c40:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104c43:	89 f0                	mov    %esi,%eax
f0104c45:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104c49:	85 c9                	test   %ecx,%ecx
f0104c4b:	75 0b                	jne    f0104c58 <strlcpy+0x23>
f0104c4d:	eb 17                	jmp    f0104c66 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104c4f:	83 c2 01             	add    $0x1,%edx
f0104c52:	83 c0 01             	add    $0x1,%eax
f0104c55:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0104c58:	39 d8                	cmp    %ebx,%eax
f0104c5a:	74 07                	je     f0104c63 <strlcpy+0x2e>
f0104c5c:	0f b6 0a             	movzbl (%edx),%ecx
f0104c5f:	84 c9                	test   %cl,%cl
f0104c61:	75 ec                	jne    f0104c4f <strlcpy+0x1a>
		*dst = '\0';
f0104c63:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104c66:	29 f0                	sub    %esi,%eax
}
f0104c68:	5b                   	pop    %ebx
f0104c69:	5e                   	pop    %esi
f0104c6a:	5d                   	pop    %ebp
f0104c6b:	c3                   	ret    

f0104c6c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104c6c:	55                   	push   %ebp
f0104c6d:	89 e5                	mov    %esp,%ebp
f0104c6f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104c72:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104c75:	eb 06                	jmp    f0104c7d <strcmp+0x11>
		p++, q++;
f0104c77:	83 c1 01             	add    $0x1,%ecx
f0104c7a:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0104c7d:	0f b6 01             	movzbl (%ecx),%eax
f0104c80:	84 c0                	test   %al,%al
f0104c82:	74 04                	je     f0104c88 <strcmp+0x1c>
f0104c84:	3a 02                	cmp    (%edx),%al
f0104c86:	74 ef                	je     f0104c77 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104c88:	0f b6 c0             	movzbl %al,%eax
f0104c8b:	0f b6 12             	movzbl (%edx),%edx
f0104c8e:	29 d0                	sub    %edx,%eax
}
f0104c90:	5d                   	pop    %ebp
f0104c91:	c3                   	ret    

f0104c92 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104c92:	55                   	push   %ebp
f0104c93:	89 e5                	mov    %esp,%ebp
f0104c95:	53                   	push   %ebx
f0104c96:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c99:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104c9c:	89 c3                	mov    %eax,%ebx
f0104c9e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104ca1:	eb 06                	jmp    f0104ca9 <strncmp+0x17>
		n--, p++, q++;
f0104ca3:	83 c0 01             	add    $0x1,%eax
f0104ca6:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0104ca9:	39 d8                	cmp    %ebx,%eax
f0104cab:	74 16                	je     f0104cc3 <strncmp+0x31>
f0104cad:	0f b6 08             	movzbl (%eax),%ecx
f0104cb0:	84 c9                	test   %cl,%cl
f0104cb2:	74 04                	je     f0104cb8 <strncmp+0x26>
f0104cb4:	3a 0a                	cmp    (%edx),%cl
f0104cb6:	74 eb                	je     f0104ca3 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104cb8:	0f b6 00             	movzbl (%eax),%eax
f0104cbb:	0f b6 12             	movzbl (%edx),%edx
f0104cbe:	29 d0                	sub    %edx,%eax
}
f0104cc0:	5b                   	pop    %ebx
f0104cc1:	5d                   	pop    %ebp
f0104cc2:	c3                   	ret    
		return 0;
f0104cc3:	b8 00 00 00 00       	mov    $0x0,%eax
f0104cc8:	eb f6                	jmp    f0104cc0 <strncmp+0x2e>

f0104cca <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0104cca:	55                   	push   %ebp
f0104ccb:	89 e5                	mov    %esp,%ebp
f0104ccd:	8b 45 08             	mov    0x8(%ebp),%eax
f0104cd0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104cd4:	0f b6 10             	movzbl (%eax),%edx
f0104cd7:	84 d2                	test   %dl,%dl
f0104cd9:	74 09                	je     f0104ce4 <strchr+0x1a>
		if (*s == c)
f0104cdb:	38 ca                	cmp    %cl,%dl
f0104cdd:	74 0a                	je     f0104ce9 <strchr+0x1f>
	for (; *s; s++)
f0104cdf:	83 c0 01             	add    $0x1,%eax
f0104ce2:	eb f0                	jmp    f0104cd4 <strchr+0xa>
			return (char *) s;
	return 0;
f0104ce4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104ce9:	5d                   	pop    %ebp
f0104cea:	c3                   	ret    

f0104ceb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0104ceb:	55                   	push   %ebp
f0104cec:	89 e5                	mov    %esp,%ebp
f0104cee:	8b 45 08             	mov    0x8(%ebp),%eax
f0104cf1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104cf5:	eb 03                	jmp    f0104cfa <strfind+0xf>
f0104cf7:	83 c0 01             	add    $0x1,%eax
f0104cfa:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0104cfd:	38 ca                	cmp    %cl,%dl
f0104cff:	74 04                	je     f0104d05 <strfind+0x1a>
f0104d01:	84 d2                	test   %dl,%dl
f0104d03:	75 f2                	jne    f0104cf7 <strfind+0xc>
			break;
	return (char *) s;
}
f0104d05:	5d                   	pop    %ebp
f0104d06:	c3                   	ret    

f0104d07 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104d07:	55                   	push   %ebp
f0104d08:	89 e5                	mov    %esp,%ebp
f0104d0a:	57                   	push   %edi
f0104d0b:	56                   	push   %esi
f0104d0c:	53                   	push   %ebx
f0104d0d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104d10:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104d13:	85 c9                	test   %ecx,%ecx
f0104d15:	74 13                	je     f0104d2a <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0104d17:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104d1d:	75 05                	jne    f0104d24 <memset+0x1d>
f0104d1f:	f6 c1 03             	test   $0x3,%cl
f0104d22:	74 0d                	je     f0104d31 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104d24:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104d27:	fc                   	cld    
f0104d28:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0104d2a:	89 f8                	mov    %edi,%eax
f0104d2c:	5b                   	pop    %ebx
f0104d2d:	5e                   	pop    %esi
f0104d2e:	5f                   	pop    %edi
f0104d2f:	5d                   	pop    %ebp
f0104d30:	c3                   	ret    
		c &= 0xFF;
f0104d31:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0104d35:	89 d3                	mov    %edx,%ebx
f0104d37:	c1 e3 08             	shl    $0x8,%ebx
f0104d3a:	89 d0                	mov    %edx,%eax
f0104d3c:	c1 e0 18             	shl    $0x18,%eax
f0104d3f:	89 d6                	mov    %edx,%esi
f0104d41:	c1 e6 10             	shl    $0x10,%esi
f0104d44:	09 f0                	or     %esi,%eax
f0104d46:	09 c2                	or     %eax,%edx
f0104d48:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0104d4a:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0104d4d:	89 d0                	mov    %edx,%eax
f0104d4f:	fc                   	cld    
f0104d50:	f3 ab                	rep stos %eax,%es:(%edi)
f0104d52:	eb d6                	jmp    f0104d2a <memset+0x23>

f0104d54 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104d54:	55                   	push   %ebp
f0104d55:	89 e5                	mov    %esp,%ebp
f0104d57:	57                   	push   %edi
f0104d58:	56                   	push   %esi
f0104d59:	8b 45 08             	mov    0x8(%ebp),%eax
f0104d5c:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104d5f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104d62:	39 c6                	cmp    %eax,%esi
f0104d64:	73 35                	jae    f0104d9b <memmove+0x47>
f0104d66:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104d69:	39 c2                	cmp    %eax,%edx
f0104d6b:	76 2e                	jbe    f0104d9b <memmove+0x47>
		s += n;
		d += n;
f0104d6d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104d70:	89 d6                	mov    %edx,%esi
f0104d72:	09 fe                	or     %edi,%esi
f0104d74:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104d7a:	74 0c                	je     f0104d88 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0104d7c:	83 ef 01             	sub    $0x1,%edi
f0104d7f:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0104d82:	fd                   	std    
f0104d83:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104d85:	fc                   	cld    
f0104d86:	eb 21                	jmp    f0104da9 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104d88:	f6 c1 03             	test   $0x3,%cl
f0104d8b:	75 ef                	jne    f0104d7c <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0104d8d:	83 ef 04             	sub    $0x4,%edi
f0104d90:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104d93:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0104d96:	fd                   	std    
f0104d97:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104d99:	eb ea                	jmp    f0104d85 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104d9b:	89 f2                	mov    %esi,%edx
f0104d9d:	09 c2                	or     %eax,%edx
f0104d9f:	f6 c2 03             	test   $0x3,%dl
f0104da2:	74 09                	je     f0104dad <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104da4:	89 c7                	mov    %eax,%edi
f0104da6:	fc                   	cld    
f0104da7:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104da9:	5e                   	pop    %esi
f0104daa:	5f                   	pop    %edi
f0104dab:	5d                   	pop    %ebp
f0104dac:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104dad:	f6 c1 03             	test   $0x3,%cl
f0104db0:	75 f2                	jne    f0104da4 <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0104db2:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0104db5:	89 c7                	mov    %eax,%edi
f0104db7:	fc                   	cld    
f0104db8:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104dba:	eb ed                	jmp    f0104da9 <memmove+0x55>

f0104dbc <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104dbc:	55                   	push   %ebp
f0104dbd:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0104dbf:	ff 75 10             	pushl  0x10(%ebp)
f0104dc2:	ff 75 0c             	pushl  0xc(%ebp)
f0104dc5:	ff 75 08             	pushl  0x8(%ebp)
f0104dc8:	e8 87 ff ff ff       	call   f0104d54 <memmove>
}
f0104dcd:	c9                   	leave  
f0104dce:	c3                   	ret    

f0104dcf <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104dcf:	55                   	push   %ebp
f0104dd0:	89 e5                	mov    %esp,%ebp
f0104dd2:	56                   	push   %esi
f0104dd3:	53                   	push   %ebx
f0104dd4:	8b 45 08             	mov    0x8(%ebp),%eax
f0104dd7:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104dda:	89 c6                	mov    %eax,%esi
f0104ddc:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104ddf:	39 f0                	cmp    %esi,%eax
f0104de1:	74 1c                	je     f0104dff <memcmp+0x30>
		if (*s1 != *s2)
f0104de3:	0f b6 08             	movzbl (%eax),%ecx
f0104de6:	0f b6 1a             	movzbl (%edx),%ebx
f0104de9:	38 d9                	cmp    %bl,%cl
f0104deb:	75 08                	jne    f0104df5 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0104ded:	83 c0 01             	add    $0x1,%eax
f0104df0:	83 c2 01             	add    $0x1,%edx
f0104df3:	eb ea                	jmp    f0104ddf <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0104df5:	0f b6 c1             	movzbl %cl,%eax
f0104df8:	0f b6 db             	movzbl %bl,%ebx
f0104dfb:	29 d8                	sub    %ebx,%eax
f0104dfd:	eb 05                	jmp    f0104e04 <memcmp+0x35>
	}

	return 0;
f0104dff:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104e04:	5b                   	pop    %ebx
f0104e05:	5e                   	pop    %esi
f0104e06:	5d                   	pop    %ebp
f0104e07:	c3                   	ret    

f0104e08 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0104e08:	55                   	push   %ebp
f0104e09:	89 e5                	mov    %esp,%ebp
f0104e0b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e0e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0104e11:	89 c2                	mov    %eax,%edx
f0104e13:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0104e16:	39 d0                	cmp    %edx,%eax
f0104e18:	73 09                	jae    f0104e23 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104e1a:	38 08                	cmp    %cl,(%eax)
f0104e1c:	74 05                	je     f0104e23 <memfind+0x1b>
	for (; s < ends; s++)
f0104e1e:	83 c0 01             	add    $0x1,%eax
f0104e21:	eb f3                	jmp    f0104e16 <memfind+0xe>
			break;
	return (void *) s;
}
f0104e23:	5d                   	pop    %ebp
f0104e24:	c3                   	ret    

f0104e25 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104e25:	55                   	push   %ebp
f0104e26:	89 e5                	mov    %esp,%ebp
f0104e28:	57                   	push   %edi
f0104e29:	56                   	push   %esi
f0104e2a:	53                   	push   %ebx
f0104e2b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104e2e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104e31:	eb 03                	jmp    f0104e36 <strtol+0x11>
		s++;
f0104e33:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0104e36:	0f b6 01             	movzbl (%ecx),%eax
f0104e39:	3c 20                	cmp    $0x20,%al
f0104e3b:	74 f6                	je     f0104e33 <strtol+0xe>
f0104e3d:	3c 09                	cmp    $0x9,%al
f0104e3f:	74 f2                	je     f0104e33 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0104e41:	3c 2b                	cmp    $0x2b,%al
f0104e43:	74 2e                	je     f0104e73 <strtol+0x4e>
	int neg = 0;
f0104e45:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0104e4a:	3c 2d                	cmp    $0x2d,%al
f0104e4c:	74 2f                	je     f0104e7d <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104e4e:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0104e54:	75 05                	jne    f0104e5b <strtol+0x36>
f0104e56:	80 39 30             	cmpb   $0x30,(%ecx)
f0104e59:	74 2c                	je     f0104e87 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104e5b:	85 db                	test   %ebx,%ebx
f0104e5d:	75 0a                	jne    f0104e69 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104e5f:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f0104e64:	80 39 30             	cmpb   $0x30,(%ecx)
f0104e67:	74 28                	je     f0104e91 <strtol+0x6c>
		base = 10;
f0104e69:	b8 00 00 00 00       	mov    $0x0,%eax
f0104e6e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0104e71:	eb 50                	jmp    f0104ec3 <strtol+0x9e>
		s++;
f0104e73:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0104e76:	bf 00 00 00 00       	mov    $0x0,%edi
f0104e7b:	eb d1                	jmp    f0104e4e <strtol+0x29>
		s++, neg = 1;
f0104e7d:	83 c1 01             	add    $0x1,%ecx
f0104e80:	bf 01 00 00 00       	mov    $0x1,%edi
f0104e85:	eb c7                	jmp    f0104e4e <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104e87:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0104e8b:	74 0e                	je     f0104e9b <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0104e8d:	85 db                	test   %ebx,%ebx
f0104e8f:	75 d8                	jne    f0104e69 <strtol+0x44>
		s++, base = 8;
f0104e91:	83 c1 01             	add    $0x1,%ecx
f0104e94:	bb 08 00 00 00       	mov    $0x8,%ebx
f0104e99:	eb ce                	jmp    f0104e69 <strtol+0x44>
		s += 2, base = 16;
f0104e9b:	83 c1 02             	add    $0x2,%ecx
f0104e9e:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104ea3:	eb c4                	jmp    f0104e69 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0104ea5:	8d 72 9f             	lea    -0x61(%edx),%esi
f0104ea8:	89 f3                	mov    %esi,%ebx
f0104eaa:	80 fb 19             	cmp    $0x19,%bl
f0104ead:	77 29                	ja     f0104ed8 <strtol+0xb3>
			dig = *s - 'a' + 10;
f0104eaf:	0f be d2             	movsbl %dl,%edx
f0104eb2:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0104eb5:	3b 55 10             	cmp    0x10(%ebp),%edx
f0104eb8:	7d 30                	jge    f0104eea <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0104eba:	83 c1 01             	add    $0x1,%ecx
f0104ebd:	0f af 45 10          	imul   0x10(%ebp),%eax
f0104ec1:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0104ec3:	0f b6 11             	movzbl (%ecx),%edx
f0104ec6:	8d 72 d0             	lea    -0x30(%edx),%esi
f0104ec9:	89 f3                	mov    %esi,%ebx
f0104ecb:	80 fb 09             	cmp    $0x9,%bl
f0104ece:	77 d5                	ja     f0104ea5 <strtol+0x80>
			dig = *s - '0';
f0104ed0:	0f be d2             	movsbl %dl,%edx
f0104ed3:	83 ea 30             	sub    $0x30,%edx
f0104ed6:	eb dd                	jmp    f0104eb5 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0104ed8:	8d 72 bf             	lea    -0x41(%edx),%esi
f0104edb:	89 f3                	mov    %esi,%ebx
f0104edd:	80 fb 19             	cmp    $0x19,%bl
f0104ee0:	77 08                	ja     f0104eea <strtol+0xc5>
			dig = *s - 'A' + 10;
f0104ee2:	0f be d2             	movsbl %dl,%edx
f0104ee5:	83 ea 37             	sub    $0x37,%edx
f0104ee8:	eb cb                	jmp    f0104eb5 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0104eea:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104eee:	74 05                	je     f0104ef5 <strtol+0xd0>
		*endptr = (char *) s;
f0104ef0:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104ef3:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0104ef5:	89 c2                	mov    %eax,%edx
f0104ef7:	f7 da                	neg    %edx
f0104ef9:	85 ff                	test   %edi,%edi
f0104efb:	0f 45 c2             	cmovne %edx,%eax
}
f0104efe:	5b                   	pop    %ebx
f0104eff:	5e                   	pop    %esi
f0104f00:	5f                   	pop    %edi
f0104f01:	5d                   	pop    %ebp
f0104f02:	c3                   	ret    
f0104f03:	66 90                	xchg   %ax,%ax
f0104f05:	66 90                	xchg   %ax,%ax
f0104f07:	66 90                	xchg   %ax,%ax
f0104f09:	66 90                	xchg   %ax,%ax
f0104f0b:	66 90                	xchg   %ax,%ax
f0104f0d:	66 90                	xchg   %ax,%ax
f0104f0f:	90                   	nop

f0104f10 <__udivdi3>:
f0104f10:	55                   	push   %ebp
f0104f11:	57                   	push   %edi
f0104f12:	56                   	push   %esi
f0104f13:	53                   	push   %ebx
f0104f14:	83 ec 1c             	sub    $0x1c,%esp
f0104f17:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f0104f1b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f0104f1f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0104f23:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0104f27:	85 d2                	test   %edx,%edx
f0104f29:	75 35                	jne    f0104f60 <__udivdi3+0x50>
f0104f2b:	39 f3                	cmp    %esi,%ebx
f0104f2d:	0f 87 bd 00 00 00    	ja     f0104ff0 <__udivdi3+0xe0>
f0104f33:	85 db                	test   %ebx,%ebx
f0104f35:	89 d9                	mov    %ebx,%ecx
f0104f37:	75 0b                	jne    f0104f44 <__udivdi3+0x34>
f0104f39:	b8 01 00 00 00       	mov    $0x1,%eax
f0104f3e:	31 d2                	xor    %edx,%edx
f0104f40:	f7 f3                	div    %ebx
f0104f42:	89 c1                	mov    %eax,%ecx
f0104f44:	31 d2                	xor    %edx,%edx
f0104f46:	89 f0                	mov    %esi,%eax
f0104f48:	f7 f1                	div    %ecx
f0104f4a:	89 c6                	mov    %eax,%esi
f0104f4c:	89 e8                	mov    %ebp,%eax
f0104f4e:	89 f7                	mov    %esi,%edi
f0104f50:	f7 f1                	div    %ecx
f0104f52:	89 fa                	mov    %edi,%edx
f0104f54:	83 c4 1c             	add    $0x1c,%esp
f0104f57:	5b                   	pop    %ebx
f0104f58:	5e                   	pop    %esi
f0104f59:	5f                   	pop    %edi
f0104f5a:	5d                   	pop    %ebp
f0104f5b:	c3                   	ret    
f0104f5c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104f60:	39 f2                	cmp    %esi,%edx
f0104f62:	77 7c                	ja     f0104fe0 <__udivdi3+0xd0>
f0104f64:	0f bd fa             	bsr    %edx,%edi
f0104f67:	83 f7 1f             	xor    $0x1f,%edi
f0104f6a:	0f 84 98 00 00 00    	je     f0105008 <__udivdi3+0xf8>
f0104f70:	89 f9                	mov    %edi,%ecx
f0104f72:	b8 20 00 00 00       	mov    $0x20,%eax
f0104f77:	29 f8                	sub    %edi,%eax
f0104f79:	d3 e2                	shl    %cl,%edx
f0104f7b:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104f7f:	89 c1                	mov    %eax,%ecx
f0104f81:	89 da                	mov    %ebx,%edx
f0104f83:	d3 ea                	shr    %cl,%edx
f0104f85:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0104f89:	09 d1                	or     %edx,%ecx
f0104f8b:	89 f2                	mov    %esi,%edx
f0104f8d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104f91:	89 f9                	mov    %edi,%ecx
f0104f93:	d3 e3                	shl    %cl,%ebx
f0104f95:	89 c1                	mov    %eax,%ecx
f0104f97:	d3 ea                	shr    %cl,%edx
f0104f99:	89 f9                	mov    %edi,%ecx
f0104f9b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0104f9f:	d3 e6                	shl    %cl,%esi
f0104fa1:	89 eb                	mov    %ebp,%ebx
f0104fa3:	89 c1                	mov    %eax,%ecx
f0104fa5:	d3 eb                	shr    %cl,%ebx
f0104fa7:	09 de                	or     %ebx,%esi
f0104fa9:	89 f0                	mov    %esi,%eax
f0104fab:	f7 74 24 08          	divl   0x8(%esp)
f0104faf:	89 d6                	mov    %edx,%esi
f0104fb1:	89 c3                	mov    %eax,%ebx
f0104fb3:	f7 64 24 0c          	mull   0xc(%esp)
f0104fb7:	39 d6                	cmp    %edx,%esi
f0104fb9:	72 0c                	jb     f0104fc7 <__udivdi3+0xb7>
f0104fbb:	89 f9                	mov    %edi,%ecx
f0104fbd:	d3 e5                	shl    %cl,%ebp
f0104fbf:	39 c5                	cmp    %eax,%ebp
f0104fc1:	73 5d                	jae    f0105020 <__udivdi3+0x110>
f0104fc3:	39 d6                	cmp    %edx,%esi
f0104fc5:	75 59                	jne    f0105020 <__udivdi3+0x110>
f0104fc7:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0104fca:	31 ff                	xor    %edi,%edi
f0104fcc:	89 fa                	mov    %edi,%edx
f0104fce:	83 c4 1c             	add    $0x1c,%esp
f0104fd1:	5b                   	pop    %ebx
f0104fd2:	5e                   	pop    %esi
f0104fd3:	5f                   	pop    %edi
f0104fd4:	5d                   	pop    %ebp
f0104fd5:	c3                   	ret    
f0104fd6:	8d 76 00             	lea    0x0(%esi),%esi
f0104fd9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0104fe0:	31 ff                	xor    %edi,%edi
f0104fe2:	31 c0                	xor    %eax,%eax
f0104fe4:	89 fa                	mov    %edi,%edx
f0104fe6:	83 c4 1c             	add    $0x1c,%esp
f0104fe9:	5b                   	pop    %ebx
f0104fea:	5e                   	pop    %esi
f0104feb:	5f                   	pop    %edi
f0104fec:	5d                   	pop    %ebp
f0104fed:	c3                   	ret    
f0104fee:	66 90                	xchg   %ax,%ax
f0104ff0:	31 ff                	xor    %edi,%edi
f0104ff2:	89 e8                	mov    %ebp,%eax
f0104ff4:	89 f2                	mov    %esi,%edx
f0104ff6:	f7 f3                	div    %ebx
f0104ff8:	89 fa                	mov    %edi,%edx
f0104ffa:	83 c4 1c             	add    $0x1c,%esp
f0104ffd:	5b                   	pop    %ebx
f0104ffe:	5e                   	pop    %esi
f0104fff:	5f                   	pop    %edi
f0105000:	5d                   	pop    %ebp
f0105001:	c3                   	ret    
f0105002:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105008:	39 f2                	cmp    %esi,%edx
f010500a:	72 06                	jb     f0105012 <__udivdi3+0x102>
f010500c:	31 c0                	xor    %eax,%eax
f010500e:	39 eb                	cmp    %ebp,%ebx
f0105010:	77 d2                	ja     f0104fe4 <__udivdi3+0xd4>
f0105012:	b8 01 00 00 00       	mov    $0x1,%eax
f0105017:	eb cb                	jmp    f0104fe4 <__udivdi3+0xd4>
f0105019:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105020:	89 d8                	mov    %ebx,%eax
f0105022:	31 ff                	xor    %edi,%edi
f0105024:	eb be                	jmp    f0104fe4 <__udivdi3+0xd4>
f0105026:	66 90                	xchg   %ax,%ax
f0105028:	66 90                	xchg   %ax,%ax
f010502a:	66 90                	xchg   %ax,%ax
f010502c:	66 90                	xchg   %ax,%ax
f010502e:	66 90                	xchg   %ax,%ax

f0105030 <__umoddi3>:
f0105030:	55                   	push   %ebp
f0105031:	57                   	push   %edi
f0105032:	56                   	push   %esi
f0105033:	53                   	push   %ebx
f0105034:	83 ec 1c             	sub    $0x1c,%esp
f0105037:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f010503b:	8b 74 24 30          	mov    0x30(%esp),%esi
f010503f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0105043:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105047:	85 ed                	test   %ebp,%ebp
f0105049:	89 f0                	mov    %esi,%eax
f010504b:	89 da                	mov    %ebx,%edx
f010504d:	75 19                	jne    f0105068 <__umoddi3+0x38>
f010504f:	39 df                	cmp    %ebx,%edi
f0105051:	0f 86 b1 00 00 00    	jbe    f0105108 <__umoddi3+0xd8>
f0105057:	f7 f7                	div    %edi
f0105059:	89 d0                	mov    %edx,%eax
f010505b:	31 d2                	xor    %edx,%edx
f010505d:	83 c4 1c             	add    $0x1c,%esp
f0105060:	5b                   	pop    %ebx
f0105061:	5e                   	pop    %esi
f0105062:	5f                   	pop    %edi
f0105063:	5d                   	pop    %ebp
f0105064:	c3                   	ret    
f0105065:	8d 76 00             	lea    0x0(%esi),%esi
f0105068:	39 dd                	cmp    %ebx,%ebp
f010506a:	77 f1                	ja     f010505d <__umoddi3+0x2d>
f010506c:	0f bd cd             	bsr    %ebp,%ecx
f010506f:	83 f1 1f             	xor    $0x1f,%ecx
f0105072:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0105076:	0f 84 b4 00 00 00    	je     f0105130 <__umoddi3+0x100>
f010507c:	b8 20 00 00 00       	mov    $0x20,%eax
f0105081:	89 c2                	mov    %eax,%edx
f0105083:	8b 44 24 04          	mov    0x4(%esp),%eax
f0105087:	29 c2                	sub    %eax,%edx
f0105089:	89 c1                	mov    %eax,%ecx
f010508b:	89 f8                	mov    %edi,%eax
f010508d:	d3 e5                	shl    %cl,%ebp
f010508f:	89 d1                	mov    %edx,%ecx
f0105091:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0105095:	d3 e8                	shr    %cl,%eax
f0105097:	09 c5                	or     %eax,%ebp
f0105099:	8b 44 24 04          	mov    0x4(%esp),%eax
f010509d:	89 c1                	mov    %eax,%ecx
f010509f:	d3 e7                	shl    %cl,%edi
f01050a1:	89 d1                	mov    %edx,%ecx
f01050a3:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01050a7:	89 df                	mov    %ebx,%edi
f01050a9:	d3 ef                	shr    %cl,%edi
f01050ab:	89 c1                	mov    %eax,%ecx
f01050ad:	89 f0                	mov    %esi,%eax
f01050af:	d3 e3                	shl    %cl,%ebx
f01050b1:	89 d1                	mov    %edx,%ecx
f01050b3:	89 fa                	mov    %edi,%edx
f01050b5:	d3 e8                	shr    %cl,%eax
f01050b7:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01050bc:	09 d8                	or     %ebx,%eax
f01050be:	f7 f5                	div    %ebp
f01050c0:	d3 e6                	shl    %cl,%esi
f01050c2:	89 d1                	mov    %edx,%ecx
f01050c4:	f7 64 24 08          	mull   0x8(%esp)
f01050c8:	39 d1                	cmp    %edx,%ecx
f01050ca:	89 c3                	mov    %eax,%ebx
f01050cc:	89 d7                	mov    %edx,%edi
f01050ce:	72 06                	jb     f01050d6 <__umoddi3+0xa6>
f01050d0:	75 0e                	jne    f01050e0 <__umoddi3+0xb0>
f01050d2:	39 c6                	cmp    %eax,%esi
f01050d4:	73 0a                	jae    f01050e0 <__umoddi3+0xb0>
f01050d6:	2b 44 24 08          	sub    0x8(%esp),%eax
f01050da:	19 ea                	sbb    %ebp,%edx
f01050dc:	89 d7                	mov    %edx,%edi
f01050de:	89 c3                	mov    %eax,%ebx
f01050e0:	89 ca                	mov    %ecx,%edx
f01050e2:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f01050e7:	29 de                	sub    %ebx,%esi
f01050e9:	19 fa                	sbb    %edi,%edx
f01050eb:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f01050ef:	89 d0                	mov    %edx,%eax
f01050f1:	d3 e0                	shl    %cl,%eax
f01050f3:	89 d9                	mov    %ebx,%ecx
f01050f5:	d3 ee                	shr    %cl,%esi
f01050f7:	d3 ea                	shr    %cl,%edx
f01050f9:	09 f0                	or     %esi,%eax
f01050fb:	83 c4 1c             	add    $0x1c,%esp
f01050fe:	5b                   	pop    %ebx
f01050ff:	5e                   	pop    %esi
f0105100:	5f                   	pop    %edi
f0105101:	5d                   	pop    %ebp
f0105102:	c3                   	ret    
f0105103:	90                   	nop
f0105104:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105108:	85 ff                	test   %edi,%edi
f010510a:	89 f9                	mov    %edi,%ecx
f010510c:	75 0b                	jne    f0105119 <__umoddi3+0xe9>
f010510e:	b8 01 00 00 00       	mov    $0x1,%eax
f0105113:	31 d2                	xor    %edx,%edx
f0105115:	f7 f7                	div    %edi
f0105117:	89 c1                	mov    %eax,%ecx
f0105119:	89 d8                	mov    %ebx,%eax
f010511b:	31 d2                	xor    %edx,%edx
f010511d:	f7 f1                	div    %ecx
f010511f:	89 f0                	mov    %esi,%eax
f0105121:	f7 f1                	div    %ecx
f0105123:	e9 31 ff ff ff       	jmp    f0105059 <__umoddi3+0x29>
f0105128:	90                   	nop
f0105129:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105130:	39 dd                	cmp    %ebx,%ebp
f0105132:	72 08                	jb     f010513c <__umoddi3+0x10c>
f0105134:	39 f7                	cmp    %esi,%edi
f0105136:	0f 87 21 ff ff ff    	ja     f010505d <__umoddi3+0x2d>
f010513c:	89 da                	mov    %ebx,%edx
f010513e:	89 f0                	mov    %esi,%eax
f0105140:	29 f8                	sub    %edi,%eax
f0105142:	19 ea                	sbb    %ebp,%edx
f0105144:	e9 14 ff ff ff       	jmp    f010505d <__umoddi3+0x2d>
