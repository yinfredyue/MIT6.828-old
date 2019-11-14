
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
f0100015:	b8 00 20 11 00       	mov    $0x112000,%eax
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
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 68 00 00 00       	call   f01000a6 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	56                   	push   %esi
f0100044:	53                   	push   %ebx
f0100045:	e8 84 01 00 00       	call   f01001ce <__x86.get_pc_thunk.bx>
f010004a:	81 c3 be 12 01 00    	add    $0x112be,%ebx
f0100050:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("entering test_backtrace %d\n", x);
f0100053:	83 ec 08             	sub    $0x8,%esp
f0100056:	56                   	push   %esi
f0100057:	8d 83 38 07 ff ff    	lea    -0xf8c8(%ebx),%eax
f010005d:	50                   	push   %eax
f010005e:	e8 f8 09 00 00       	call   f0100a5b <cprintf>
	if (x > 0)
f0100063:	83 c4 10             	add    $0x10,%esp
f0100066:	85 f6                	test   %esi,%esi
f0100068:	7f 2b                	jg     f0100095 <test_backtrace+0x55>
		test_backtrace(x-1);
	else
		mon_backtrace(0, 0, 0);
f010006a:	83 ec 04             	sub    $0x4,%esp
f010006d:	6a 00                	push   $0x0
f010006f:	6a 00                	push   $0x0
f0100071:	6a 00                	push   $0x0
f0100073:	e8 1d 08 00 00       	call   f0100895 <mon_backtrace>
f0100078:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007b:	83 ec 08             	sub    $0x8,%esp
f010007e:	56                   	push   %esi
f010007f:	8d 83 54 07 ff ff    	lea    -0xf8ac(%ebx),%eax
f0100085:	50                   	push   %eax
f0100086:	e8 d0 09 00 00       	call   f0100a5b <cprintf>
}
f010008b:	83 c4 10             	add    $0x10,%esp
f010008e:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100091:	5b                   	pop    %ebx
f0100092:	5e                   	pop    %esi
f0100093:	5d                   	pop    %ebp
f0100094:	c3                   	ret    
		test_backtrace(x-1);
f0100095:	83 ec 0c             	sub    $0xc,%esp
f0100098:	8d 46 ff             	lea    -0x1(%esi),%eax
f010009b:	50                   	push   %eax
f010009c:	e8 9f ff ff ff       	call   f0100040 <test_backtrace>
f01000a1:	83 c4 10             	add    $0x10,%esp
f01000a4:	eb d5                	jmp    f010007b <test_backtrace+0x3b>

f01000a6 <i386_init>:

void
i386_init(void)
{
f01000a6:	55                   	push   %ebp
f01000a7:	89 e5                	mov    %esp,%ebp
f01000a9:	53                   	push   %ebx
f01000aa:	83 ec 08             	sub    $0x8,%esp
f01000ad:	e8 1c 01 00 00       	call   f01001ce <__x86.get_pc_thunk.bx>
f01000b2:	81 c3 56 12 01 00    	add    $0x11256,%ebx
	extern char edata[], end[];
	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000b8:	c7 c2 60 30 11 f0    	mov    $0xf0113060,%edx
f01000be:	c7 c0 a0 36 11 f0    	mov    $0xf01136a0,%eax
f01000c4:	29 d0                	sub    %edx,%eax
f01000c6:	50                   	push   %eax
f01000c7:	6a 00                	push   $0x0
f01000c9:	52                   	push   %edx
f01000ca:	e8 20 15 00 00       	call   f01015ef <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000cf:	e8 4f 05 00 00       	call   f0100623 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000d4:	83 c4 08             	add    $0x8,%esp
f01000d7:	68 ac 1a 00 00       	push   $0x1aac
f01000dc:	8d 83 6f 07 ff ff    	lea    -0xf891(%ebx),%eax
f01000e2:	50                   	push   %eax
f01000e3:	e8 73 09 00 00       	call   f0100a5b <cprintf>

	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000e8:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000ef:	e8 4c ff ff ff       	call   f0100040 <test_backtrace>

	// Testing code for lab1 exercise 
	int x = 1, y = 3, z = 4;
	cprintf("x %d, y %x, z %d\n", x, y, z);
f01000f4:	6a 04                	push   $0x4
f01000f6:	6a 03                	push   $0x3
f01000f8:	6a 01                	push   $0x1
f01000fa:	8d 83 8a 07 ff ff    	lea    -0xf876(%ebx),%eax
f0100100:	50                   	push   %eax
f0100101:	e8 55 09 00 00       	call   f0100a5b <cprintf>
f0100106:	83 c4 20             	add    $0x20,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100109:	83 ec 0c             	sub    $0xc,%esp
f010010c:	6a 00                	push   $0x0
f010010e:	e8 8c 07 00 00       	call   f010089f <monitor>
f0100113:	83 c4 10             	add    $0x10,%esp
f0100116:	eb f1                	jmp    f0100109 <i386_init+0x63>

f0100118 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100118:	55                   	push   %ebp
f0100119:	89 e5                	mov    %esp,%ebp
f010011b:	57                   	push   %edi
f010011c:	56                   	push   %esi
f010011d:	53                   	push   %ebx
f010011e:	83 ec 0c             	sub    $0xc,%esp
f0100121:	e8 a8 00 00 00       	call   f01001ce <__x86.get_pc_thunk.bx>
f0100126:	81 c3 e2 11 01 00    	add    $0x111e2,%ebx
f010012c:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f010012f:	c7 c0 a4 36 11 f0    	mov    $0xf01136a4,%eax
f0100135:	83 38 00             	cmpl   $0x0,(%eax)
f0100138:	74 0f                	je     f0100149 <_panic+0x31>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010013a:	83 ec 0c             	sub    $0xc,%esp
f010013d:	6a 00                	push   $0x0
f010013f:	e8 5b 07 00 00       	call   f010089f <monitor>
f0100144:	83 c4 10             	add    $0x10,%esp
f0100147:	eb f1                	jmp    f010013a <_panic+0x22>
	panicstr = fmt;
f0100149:	89 38                	mov    %edi,(%eax)
	asm volatile("cli; cld");
f010014b:	fa                   	cli    
f010014c:	fc                   	cld    
	va_start(ap, fmt);
f010014d:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
f0100150:	83 ec 04             	sub    $0x4,%esp
f0100153:	ff 75 0c             	pushl  0xc(%ebp)
f0100156:	ff 75 08             	pushl  0x8(%ebp)
f0100159:	8d 83 9c 07 ff ff    	lea    -0xf864(%ebx),%eax
f010015f:	50                   	push   %eax
f0100160:	e8 f6 08 00 00       	call   f0100a5b <cprintf>
	vcprintf(fmt, ap);
f0100165:	83 c4 08             	add    $0x8,%esp
f0100168:	56                   	push   %esi
f0100169:	57                   	push   %edi
f010016a:	e8 b5 08 00 00       	call   f0100a24 <vcprintf>
	cprintf("\n");
f010016f:	8d 83 d8 07 ff ff    	lea    -0xf828(%ebx),%eax
f0100175:	89 04 24             	mov    %eax,(%esp)
f0100178:	e8 de 08 00 00       	call   f0100a5b <cprintf>
f010017d:	83 c4 10             	add    $0x10,%esp
f0100180:	eb b8                	jmp    f010013a <_panic+0x22>

f0100182 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100182:	55                   	push   %ebp
f0100183:	89 e5                	mov    %esp,%ebp
f0100185:	56                   	push   %esi
f0100186:	53                   	push   %ebx
f0100187:	e8 42 00 00 00       	call   f01001ce <__x86.get_pc_thunk.bx>
f010018c:	81 c3 7c 11 01 00    	add    $0x1117c,%ebx
	va_list ap;

	va_start(ap, fmt);
f0100192:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f0100195:	83 ec 04             	sub    $0x4,%esp
f0100198:	ff 75 0c             	pushl  0xc(%ebp)
f010019b:	ff 75 08             	pushl  0x8(%ebp)
f010019e:	8d 83 b4 07 ff ff    	lea    -0xf84c(%ebx),%eax
f01001a4:	50                   	push   %eax
f01001a5:	e8 b1 08 00 00       	call   f0100a5b <cprintf>
	vcprintf(fmt, ap);
f01001aa:	83 c4 08             	add    $0x8,%esp
f01001ad:	56                   	push   %esi
f01001ae:	ff 75 10             	pushl  0x10(%ebp)
f01001b1:	e8 6e 08 00 00       	call   f0100a24 <vcprintf>
	cprintf("\n");
f01001b6:	8d 83 d8 07 ff ff    	lea    -0xf828(%ebx),%eax
f01001bc:	89 04 24             	mov    %eax,(%esp)
f01001bf:	e8 97 08 00 00       	call   f0100a5b <cprintf>
	va_end(ap);
}
f01001c4:	83 c4 10             	add    $0x10,%esp
f01001c7:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01001ca:	5b                   	pop    %ebx
f01001cb:	5e                   	pop    %esi
f01001cc:	5d                   	pop    %ebp
f01001cd:	c3                   	ret    

f01001ce <__x86.get_pc_thunk.bx>:
f01001ce:	8b 1c 24             	mov    (%esp),%ebx
f01001d1:	c3                   	ret    

f01001d2 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001d2:	55                   	push   %ebp
f01001d3:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001d5:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001da:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001db:	a8 01                	test   $0x1,%al
f01001dd:	74 0b                	je     f01001ea <serial_proc_data+0x18>
f01001df:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001e4:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001e5:	0f b6 c0             	movzbl %al,%eax
}
f01001e8:	5d                   	pop    %ebp
f01001e9:	c3                   	ret    
		return -1;
f01001ea:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01001ef:	eb f7                	jmp    f01001e8 <serial_proc_data+0x16>

f01001f1 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001f1:	55                   	push   %ebp
f01001f2:	89 e5                	mov    %esp,%ebp
f01001f4:	56                   	push   %esi
f01001f5:	53                   	push   %ebx
f01001f6:	e8 d3 ff ff ff       	call   f01001ce <__x86.get_pc_thunk.bx>
f01001fb:	81 c3 0d 11 01 00    	add    $0x1110d,%ebx
f0100201:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
f0100203:	ff d6                	call   *%esi
f0100205:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100208:	74 2e                	je     f0100238 <cons_intr+0x47>
		if (c == 0)
f010020a:	85 c0                	test   %eax,%eax
f010020c:	74 f5                	je     f0100203 <cons_intr+0x12>
			continue;
		cons.buf[cons.wpos++] = c;
f010020e:	8b 8b 7c 1f 00 00    	mov    0x1f7c(%ebx),%ecx
f0100214:	8d 51 01             	lea    0x1(%ecx),%edx
f0100217:	89 93 7c 1f 00 00    	mov    %edx,0x1f7c(%ebx)
f010021d:	88 84 0b 78 1d 00 00 	mov    %al,0x1d78(%ebx,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f0100224:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010022a:	75 d7                	jne    f0100203 <cons_intr+0x12>
			cons.wpos = 0;
f010022c:	c7 83 7c 1f 00 00 00 	movl   $0x0,0x1f7c(%ebx)
f0100233:	00 00 00 
f0100236:	eb cb                	jmp    f0100203 <cons_intr+0x12>
	}
}
f0100238:	5b                   	pop    %ebx
f0100239:	5e                   	pop    %esi
f010023a:	5d                   	pop    %ebp
f010023b:	c3                   	ret    

f010023c <kbd_proc_data>:
{
f010023c:	55                   	push   %ebp
f010023d:	89 e5                	mov    %esp,%ebp
f010023f:	56                   	push   %esi
f0100240:	53                   	push   %ebx
f0100241:	e8 88 ff ff ff       	call   f01001ce <__x86.get_pc_thunk.bx>
f0100246:	81 c3 c2 10 01 00    	add    $0x110c2,%ebx
f010024c:	ba 64 00 00 00       	mov    $0x64,%edx
f0100251:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f0100252:	a8 01                	test   $0x1,%al
f0100254:	0f 84 06 01 00 00    	je     f0100360 <kbd_proc_data+0x124>
	if (stat & KBS_TERR)
f010025a:	a8 20                	test   $0x20,%al
f010025c:	0f 85 05 01 00 00    	jne    f0100367 <kbd_proc_data+0x12b>
f0100262:	ba 60 00 00 00       	mov    $0x60,%edx
f0100267:	ec                   	in     (%dx),%al
f0100268:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f010026a:	3c e0                	cmp    $0xe0,%al
f010026c:	0f 84 93 00 00 00    	je     f0100305 <kbd_proc_data+0xc9>
	} else if (data & 0x80) {
f0100272:	84 c0                	test   %al,%al
f0100274:	0f 88 a0 00 00 00    	js     f010031a <kbd_proc_data+0xde>
	} else if (shift & E0ESC) {
f010027a:	8b 8b 58 1d 00 00    	mov    0x1d58(%ebx),%ecx
f0100280:	f6 c1 40             	test   $0x40,%cl
f0100283:	74 0e                	je     f0100293 <kbd_proc_data+0x57>
		data |= 0x80;
f0100285:	83 c8 80             	or     $0xffffff80,%eax
f0100288:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010028a:	83 e1 bf             	and    $0xffffffbf,%ecx
f010028d:	89 8b 58 1d 00 00    	mov    %ecx,0x1d58(%ebx)
	shift |= shiftcode[data];
f0100293:	0f b6 d2             	movzbl %dl,%edx
f0100296:	0f b6 84 13 f8 08 ff 	movzbl -0xf708(%ebx,%edx,1),%eax
f010029d:	ff 
f010029e:	0b 83 58 1d 00 00    	or     0x1d58(%ebx),%eax
	shift ^= togglecode[data];
f01002a4:	0f b6 8c 13 f8 07 ff 	movzbl -0xf808(%ebx,%edx,1),%ecx
f01002ab:	ff 
f01002ac:	31 c8                	xor    %ecx,%eax
f01002ae:	89 83 58 1d 00 00    	mov    %eax,0x1d58(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f01002b4:	89 c1                	mov    %eax,%ecx
f01002b6:	83 e1 03             	and    $0x3,%ecx
f01002b9:	8b 8c 8b f8 1c 00 00 	mov    0x1cf8(%ebx,%ecx,4),%ecx
f01002c0:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002c4:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
f01002c7:	a8 08                	test   $0x8,%al
f01002c9:	74 0d                	je     f01002d8 <kbd_proc_data+0x9c>
		if ('a' <= c && c <= 'z')
f01002cb:	89 f2                	mov    %esi,%edx
f01002cd:	8d 4e 9f             	lea    -0x61(%esi),%ecx
f01002d0:	83 f9 19             	cmp    $0x19,%ecx
f01002d3:	77 7a                	ja     f010034f <kbd_proc_data+0x113>
			c += 'A' - 'a';
f01002d5:	83 ee 20             	sub    $0x20,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002d8:	f7 d0                	not    %eax
f01002da:	a8 06                	test   $0x6,%al
f01002dc:	75 33                	jne    f0100311 <kbd_proc_data+0xd5>
f01002de:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
f01002e4:	75 2b                	jne    f0100311 <kbd_proc_data+0xd5>
		cprintf("Rebooting!\n");
f01002e6:	83 ec 0c             	sub    $0xc,%esp
f01002e9:	8d 83 ce 07 ff ff    	lea    -0xf832(%ebx),%eax
f01002ef:	50                   	push   %eax
f01002f0:	e8 66 07 00 00       	call   f0100a5b <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01002f5:	b8 03 00 00 00       	mov    $0x3,%eax
f01002fa:	ba 92 00 00 00       	mov    $0x92,%edx
f01002ff:	ee                   	out    %al,(%dx)
f0100300:	83 c4 10             	add    $0x10,%esp
f0100303:	eb 0c                	jmp    f0100311 <kbd_proc_data+0xd5>
		shift |= E0ESC;
f0100305:	83 8b 58 1d 00 00 40 	orl    $0x40,0x1d58(%ebx)
		return 0;
f010030c:	be 00 00 00 00       	mov    $0x0,%esi
}
f0100311:	89 f0                	mov    %esi,%eax
f0100313:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100316:	5b                   	pop    %ebx
f0100317:	5e                   	pop    %esi
f0100318:	5d                   	pop    %ebp
f0100319:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f010031a:	8b 8b 58 1d 00 00    	mov    0x1d58(%ebx),%ecx
f0100320:	89 ce                	mov    %ecx,%esi
f0100322:	83 e6 40             	and    $0x40,%esi
f0100325:	83 e0 7f             	and    $0x7f,%eax
f0100328:	85 f6                	test   %esi,%esi
f010032a:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010032d:	0f b6 d2             	movzbl %dl,%edx
f0100330:	0f b6 84 13 f8 08 ff 	movzbl -0xf708(%ebx,%edx,1),%eax
f0100337:	ff 
f0100338:	83 c8 40             	or     $0x40,%eax
f010033b:	0f b6 c0             	movzbl %al,%eax
f010033e:	f7 d0                	not    %eax
f0100340:	21 c8                	and    %ecx,%eax
f0100342:	89 83 58 1d 00 00    	mov    %eax,0x1d58(%ebx)
		return 0;
f0100348:	be 00 00 00 00       	mov    $0x0,%esi
f010034d:	eb c2                	jmp    f0100311 <kbd_proc_data+0xd5>
		else if ('A' <= c && c <= 'Z')
f010034f:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100352:	8d 4e 20             	lea    0x20(%esi),%ecx
f0100355:	83 fa 1a             	cmp    $0x1a,%edx
f0100358:	0f 42 f1             	cmovb  %ecx,%esi
f010035b:	e9 78 ff ff ff       	jmp    f01002d8 <kbd_proc_data+0x9c>
		return -1;
f0100360:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0100365:	eb aa                	jmp    f0100311 <kbd_proc_data+0xd5>
		return -1;
f0100367:	be ff ff ff ff       	mov    $0xffffffff,%esi
f010036c:	eb a3                	jmp    f0100311 <kbd_proc_data+0xd5>

f010036e <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010036e:	55                   	push   %ebp
f010036f:	89 e5                	mov    %esp,%ebp
f0100371:	57                   	push   %edi
f0100372:	56                   	push   %esi
f0100373:	53                   	push   %ebx
f0100374:	83 ec 1c             	sub    $0x1c,%esp
f0100377:	e8 52 fe ff ff       	call   f01001ce <__x86.get_pc_thunk.bx>
f010037c:	81 c3 8c 0f 01 00    	add    $0x10f8c,%ebx
f0100382:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0;
f0100385:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010038a:	bf fd 03 00 00       	mov    $0x3fd,%edi
f010038f:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100394:	eb 09                	jmp    f010039f <cons_putc+0x31>
f0100396:	89 ca                	mov    %ecx,%edx
f0100398:	ec                   	in     (%dx),%al
f0100399:	ec                   	in     (%dx),%al
f010039a:	ec                   	in     (%dx),%al
f010039b:	ec                   	in     (%dx),%al
	     i++)
f010039c:	83 c6 01             	add    $0x1,%esi
f010039f:	89 fa                	mov    %edi,%edx
f01003a1:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01003a2:	a8 20                	test   $0x20,%al
f01003a4:	75 08                	jne    f01003ae <cons_putc+0x40>
f01003a6:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f01003ac:	7e e8                	jle    f0100396 <cons_putc+0x28>
	outb(COM1 + COM_TX, c);
f01003ae:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01003b1:	89 f8                	mov    %edi,%eax
f01003b3:	88 45 e3             	mov    %al,-0x1d(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003b6:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01003bb:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01003bc:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003c1:	bf 79 03 00 00       	mov    $0x379,%edi
f01003c6:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003cb:	eb 09                	jmp    f01003d6 <cons_putc+0x68>
f01003cd:	89 ca                	mov    %ecx,%edx
f01003cf:	ec                   	in     (%dx),%al
f01003d0:	ec                   	in     (%dx),%al
f01003d1:	ec                   	in     (%dx),%al
f01003d2:	ec                   	in     (%dx),%al
f01003d3:	83 c6 01             	add    $0x1,%esi
f01003d6:	89 fa                	mov    %edi,%edx
f01003d8:	ec                   	in     (%dx),%al
f01003d9:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f01003df:	7f 04                	jg     f01003e5 <cons_putc+0x77>
f01003e1:	84 c0                	test   %al,%al
f01003e3:	79 e8                	jns    f01003cd <cons_putc+0x5f>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003e5:	ba 78 03 00 00       	mov    $0x378,%edx
f01003ea:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f01003ee:	ee                   	out    %al,(%dx)
f01003ef:	ba 7a 03 00 00       	mov    $0x37a,%edx
f01003f4:	b8 0d 00 00 00       	mov    $0xd,%eax
f01003f9:	ee                   	out    %al,(%dx)
f01003fa:	b8 08 00 00 00       	mov    $0x8,%eax
f01003ff:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100400:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100403:	89 fa                	mov    %edi,%edx
f0100405:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010040b:	89 f8                	mov    %edi,%eax
f010040d:	80 cc 07             	or     $0x7,%ah
f0100410:	85 d2                	test   %edx,%edx
f0100412:	0f 45 c7             	cmovne %edi,%eax
f0100415:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch (c & 0xff) {
f0100418:	0f b6 c0             	movzbl %al,%eax
f010041b:	83 f8 09             	cmp    $0x9,%eax
f010041e:	0f 84 b9 00 00 00    	je     f01004dd <cons_putc+0x16f>
f0100424:	83 f8 09             	cmp    $0x9,%eax
f0100427:	7e 74                	jle    f010049d <cons_putc+0x12f>
f0100429:	83 f8 0a             	cmp    $0xa,%eax
f010042c:	0f 84 9e 00 00 00    	je     f01004d0 <cons_putc+0x162>
f0100432:	83 f8 0d             	cmp    $0xd,%eax
f0100435:	0f 85 d9 00 00 00    	jne    f0100514 <cons_putc+0x1a6>
		crt_pos -= (crt_pos % CRT_COLS);
f010043b:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f0100442:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100448:	c1 e8 16             	shr    $0x16,%eax
f010044b:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010044e:	c1 e0 04             	shl    $0x4,%eax
f0100451:	66 89 83 80 1f 00 00 	mov    %ax,0x1f80(%ebx)
	if (crt_pos >= CRT_SIZE) {
f0100458:	66 81 bb 80 1f 00 00 	cmpw   $0x7cf,0x1f80(%ebx)
f010045f:	cf 07 
f0100461:	0f 87 d4 00 00 00    	ja     f010053b <cons_putc+0x1cd>
	outb(addr_6845, 14);
f0100467:	8b 8b 88 1f 00 00    	mov    0x1f88(%ebx),%ecx
f010046d:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100472:	89 ca                	mov    %ecx,%edx
f0100474:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100475:	0f b7 9b 80 1f 00 00 	movzwl 0x1f80(%ebx),%ebx
f010047c:	8d 71 01             	lea    0x1(%ecx),%esi
f010047f:	89 d8                	mov    %ebx,%eax
f0100481:	66 c1 e8 08          	shr    $0x8,%ax
f0100485:	89 f2                	mov    %esi,%edx
f0100487:	ee                   	out    %al,(%dx)
f0100488:	b8 0f 00 00 00       	mov    $0xf,%eax
f010048d:	89 ca                	mov    %ecx,%edx
f010048f:	ee                   	out    %al,(%dx)
f0100490:	89 d8                	mov    %ebx,%eax
f0100492:	89 f2                	mov    %esi,%edx
f0100494:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100495:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100498:	5b                   	pop    %ebx
f0100499:	5e                   	pop    %esi
f010049a:	5f                   	pop    %edi
f010049b:	5d                   	pop    %ebp
f010049c:	c3                   	ret    
	switch (c & 0xff) {
f010049d:	83 f8 08             	cmp    $0x8,%eax
f01004a0:	75 72                	jne    f0100514 <cons_putc+0x1a6>
		if (crt_pos > 0) {
f01004a2:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f01004a9:	66 85 c0             	test   %ax,%ax
f01004ac:	74 b9                	je     f0100467 <cons_putc+0xf9>
			crt_pos--;
f01004ae:	83 e8 01             	sub    $0x1,%eax
f01004b1:	66 89 83 80 1f 00 00 	mov    %ax,0x1f80(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004b8:	0f b7 c0             	movzwl %ax,%eax
f01004bb:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f01004bf:	b2 00                	mov    $0x0,%dl
f01004c1:	83 ca 20             	or     $0x20,%edx
f01004c4:	8b 8b 84 1f 00 00    	mov    0x1f84(%ebx),%ecx
f01004ca:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f01004ce:	eb 88                	jmp    f0100458 <cons_putc+0xea>
		crt_pos += CRT_COLS;
f01004d0:	66 83 83 80 1f 00 00 	addw   $0x50,0x1f80(%ebx)
f01004d7:	50 
f01004d8:	e9 5e ff ff ff       	jmp    f010043b <cons_putc+0xcd>
		cons_putc(' ');
f01004dd:	b8 20 00 00 00       	mov    $0x20,%eax
f01004e2:	e8 87 fe ff ff       	call   f010036e <cons_putc>
		cons_putc(' ');
f01004e7:	b8 20 00 00 00       	mov    $0x20,%eax
f01004ec:	e8 7d fe ff ff       	call   f010036e <cons_putc>
		cons_putc(' ');
f01004f1:	b8 20 00 00 00       	mov    $0x20,%eax
f01004f6:	e8 73 fe ff ff       	call   f010036e <cons_putc>
		cons_putc(' ');
f01004fb:	b8 20 00 00 00       	mov    $0x20,%eax
f0100500:	e8 69 fe ff ff       	call   f010036e <cons_putc>
		cons_putc(' ');
f0100505:	b8 20 00 00 00       	mov    $0x20,%eax
f010050a:	e8 5f fe ff ff       	call   f010036e <cons_putc>
f010050f:	e9 44 ff ff ff       	jmp    f0100458 <cons_putc+0xea>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100514:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f010051b:	8d 50 01             	lea    0x1(%eax),%edx
f010051e:	66 89 93 80 1f 00 00 	mov    %dx,0x1f80(%ebx)
f0100525:	0f b7 c0             	movzwl %ax,%eax
f0100528:	8b 93 84 1f 00 00    	mov    0x1f84(%ebx),%edx
f010052e:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f0100532:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100536:	e9 1d ff ff ff       	jmp    f0100458 <cons_putc+0xea>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010053b:	8b 83 84 1f 00 00    	mov    0x1f84(%ebx),%eax
f0100541:	83 ec 04             	sub    $0x4,%esp
f0100544:	68 00 0f 00 00       	push   $0xf00
f0100549:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010054f:	52                   	push   %edx
f0100550:	50                   	push   %eax
f0100551:	e8 e6 10 00 00       	call   f010163c <memmove>
			crt_buf[i] = 0x0700 | ' ';
f0100556:	8b 93 84 1f 00 00    	mov    0x1f84(%ebx),%edx
f010055c:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100562:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100568:	83 c4 10             	add    $0x10,%esp
f010056b:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100570:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100573:	39 d0                	cmp    %edx,%eax
f0100575:	75 f4                	jne    f010056b <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
f0100577:	66 83 ab 80 1f 00 00 	subw   $0x50,0x1f80(%ebx)
f010057e:	50 
f010057f:	e9 e3 fe ff ff       	jmp    f0100467 <cons_putc+0xf9>

f0100584 <serial_intr>:
{
f0100584:	e8 e7 01 00 00       	call   f0100770 <__x86.get_pc_thunk.ax>
f0100589:	05 7f 0d 01 00       	add    $0x10d7f,%eax
	if (serial_exists)
f010058e:	80 b8 8c 1f 00 00 00 	cmpb   $0x0,0x1f8c(%eax)
f0100595:	75 02                	jne    f0100599 <serial_intr+0x15>
f0100597:	f3 c3                	repz ret 
{
f0100599:	55                   	push   %ebp
f010059a:	89 e5                	mov    %esp,%ebp
f010059c:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f010059f:	8d 80 ca ee fe ff    	lea    -0x11136(%eax),%eax
f01005a5:	e8 47 fc ff ff       	call   f01001f1 <cons_intr>
}
f01005aa:	c9                   	leave  
f01005ab:	c3                   	ret    

f01005ac <kbd_intr>:
{
f01005ac:	55                   	push   %ebp
f01005ad:	89 e5                	mov    %esp,%ebp
f01005af:	83 ec 08             	sub    $0x8,%esp
f01005b2:	e8 b9 01 00 00       	call   f0100770 <__x86.get_pc_thunk.ax>
f01005b7:	05 51 0d 01 00       	add    $0x10d51,%eax
	cons_intr(kbd_proc_data);
f01005bc:	8d 80 34 ef fe ff    	lea    -0x110cc(%eax),%eax
f01005c2:	e8 2a fc ff ff       	call   f01001f1 <cons_intr>
}
f01005c7:	c9                   	leave  
f01005c8:	c3                   	ret    

f01005c9 <cons_getc>:
{
f01005c9:	55                   	push   %ebp
f01005ca:	89 e5                	mov    %esp,%ebp
f01005cc:	53                   	push   %ebx
f01005cd:	83 ec 04             	sub    $0x4,%esp
f01005d0:	e8 f9 fb ff ff       	call   f01001ce <__x86.get_pc_thunk.bx>
f01005d5:	81 c3 33 0d 01 00    	add    $0x10d33,%ebx
	serial_intr();
f01005db:	e8 a4 ff ff ff       	call   f0100584 <serial_intr>
	kbd_intr();
f01005e0:	e8 c7 ff ff ff       	call   f01005ac <kbd_intr>
	if (cons.rpos != cons.wpos) {
f01005e5:	8b 93 78 1f 00 00    	mov    0x1f78(%ebx),%edx
	return 0;
f01005eb:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f01005f0:	3b 93 7c 1f 00 00    	cmp    0x1f7c(%ebx),%edx
f01005f6:	74 19                	je     f0100611 <cons_getc+0x48>
		c = cons.buf[cons.rpos++];
f01005f8:	8d 4a 01             	lea    0x1(%edx),%ecx
f01005fb:	89 8b 78 1f 00 00    	mov    %ecx,0x1f78(%ebx)
f0100601:	0f b6 84 13 78 1d 00 	movzbl 0x1d78(%ebx,%edx,1),%eax
f0100608:	00 
		if (cons.rpos == CONSBUFSIZE)
f0100609:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f010060f:	74 06                	je     f0100617 <cons_getc+0x4e>
}
f0100611:	83 c4 04             	add    $0x4,%esp
f0100614:	5b                   	pop    %ebx
f0100615:	5d                   	pop    %ebp
f0100616:	c3                   	ret    
			cons.rpos = 0;
f0100617:	c7 83 78 1f 00 00 00 	movl   $0x0,0x1f78(%ebx)
f010061e:	00 00 00 
f0100621:	eb ee                	jmp    f0100611 <cons_getc+0x48>

f0100623 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f0100623:	55                   	push   %ebp
f0100624:	89 e5                	mov    %esp,%ebp
f0100626:	57                   	push   %edi
f0100627:	56                   	push   %esi
f0100628:	53                   	push   %ebx
f0100629:	83 ec 1c             	sub    $0x1c,%esp
f010062c:	e8 9d fb ff ff       	call   f01001ce <__x86.get_pc_thunk.bx>
f0100631:	81 c3 d7 0c 01 00    	add    $0x10cd7,%ebx
	was = *cp;
f0100637:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010063e:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100645:	5a a5 
	if (*cp != 0xA55A) {
f0100647:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010064e:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100652:	0f 84 bc 00 00 00    	je     f0100714 <cons_init+0xf1>
		addr_6845 = MONO_BASE;
f0100658:	c7 83 88 1f 00 00 b4 	movl   $0x3b4,0x1f88(%ebx)
f010065f:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100662:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f0100669:	8b bb 88 1f 00 00    	mov    0x1f88(%ebx),%edi
f010066f:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100674:	89 fa                	mov    %edi,%edx
f0100676:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100677:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010067a:	89 ca                	mov    %ecx,%edx
f010067c:	ec                   	in     (%dx),%al
f010067d:	0f b6 f0             	movzbl %al,%esi
f0100680:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100683:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100688:	89 fa                	mov    %edi,%edx
f010068a:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010068b:	89 ca                	mov    %ecx,%edx
f010068d:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f010068e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100691:	89 bb 84 1f 00 00    	mov    %edi,0x1f84(%ebx)
	pos |= inb(addr_6845 + 1);
f0100697:	0f b6 c0             	movzbl %al,%eax
f010069a:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f010069c:	66 89 b3 80 1f 00 00 	mov    %si,0x1f80(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006a3:	b9 00 00 00 00       	mov    $0x0,%ecx
f01006a8:	89 c8                	mov    %ecx,%eax
f01006aa:	ba fa 03 00 00       	mov    $0x3fa,%edx
f01006af:	ee                   	out    %al,(%dx)
f01006b0:	bf fb 03 00 00       	mov    $0x3fb,%edi
f01006b5:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01006ba:	89 fa                	mov    %edi,%edx
f01006bc:	ee                   	out    %al,(%dx)
f01006bd:	b8 0c 00 00 00       	mov    $0xc,%eax
f01006c2:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01006c7:	ee                   	out    %al,(%dx)
f01006c8:	be f9 03 00 00       	mov    $0x3f9,%esi
f01006cd:	89 c8                	mov    %ecx,%eax
f01006cf:	89 f2                	mov    %esi,%edx
f01006d1:	ee                   	out    %al,(%dx)
f01006d2:	b8 03 00 00 00       	mov    $0x3,%eax
f01006d7:	89 fa                	mov    %edi,%edx
f01006d9:	ee                   	out    %al,(%dx)
f01006da:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01006df:	89 c8                	mov    %ecx,%eax
f01006e1:	ee                   	out    %al,(%dx)
f01006e2:	b8 01 00 00 00       	mov    $0x1,%eax
f01006e7:	89 f2                	mov    %esi,%edx
f01006e9:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006ea:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01006ef:	ec                   	in     (%dx),%al
f01006f0:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01006f2:	3c ff                	cmp    $0xff,%al
f01006f4:	0f 95 83 8c 1f 00 00 	setne  0x1f8c(%ebx)
f01006fb:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100700:	ec                   	in     (%dx),%al
f0100701:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100706:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100707:	80 f9 ff             	cmp    $0xff,%cl
f010070a:	74 25                	je     f0100731 <cons_init+0x10e>
		cprintf("Serial port does not exist!\n");
}
f010070c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010070f:	5b                   	pop    %ebx
f0100710:	5e                   	pop    %esi
f0100711:	5f                   	pop    %edi
f0100712:	5d                   	pop    %ebp
f0100713:	c3                   	ret    
		*cp = was;
f0100714:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010071b:	c7 83 88 1f 00 00 d4 	movl   $0x3d4,0x1f88(%ebx)
f0100722:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100725:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f010072c:	e9 38 ff ff ff       	jmp    f0100669 <cons_init+0x46>
		cprintf("Serial port does not exist!\n");
f0100731:	83 ec 0c             	sub    $0xc,%esp
f0100734:	8d 83 da 07 ff ff    	lea    -0xf826(%ebx),%eax
f010073a:	50                   	push   %eax
f010073b:	e8 1b 03 00 00       	call   f0100a5b <cprintf>
f0100740:	83 c4 10             	add    $0x10,%esp
}
f0100743:	eb c7                	jmp    f010070c <cons_init+0xe9>

f0100745 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100745:	55                   	push   %ebp
f0100746:	89 e5                	mov    %esp,%ebp
f0100748:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010074b:	8b 45 08             	mov    0x8(%ebp),%eax
f010074e:	e8 1b fc ff ff       	call   f010036e <cons_putc>
}
f0100753:	c9                   	leave  
f0100754:	c3                   	ret    

f0100755 <getchar>:

int
getchar(void)
{
f0100755:	55                   	push   %ebp
f0100756:	89 e5                	mov    %esp,%ebp
f0100758:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010075b:	e8 69 fe ff ff       	call   f01005c9 <cons_getc>
f0100760:	85 c0                	test   %eax,%eax
f0100762:	74 f7                	je     f010075b <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100764:	c9                   	leave  
f0100765:	c3                   	ret    

f0100766 <iscons>:

int
iscons(int fdnum)
{
f0100766:	55                   	push   %ebp
f0100767:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100769:	b8 01 00 00 00       	mov    $0x1,%eax
f010076e:	5d                   	pop    %ebp
f010076f:	c3                   	ret    

f0100770 <__x86.get_pc_thunk.ax>:
f0100770:	8b 04 24             	mov    (%esp),%eax
f0100773:	c3                   	ret    

f0100774 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100774:	55                   	push   %ebp
f0100775:	89 e5                	mov    %esp,%ebp
f0100777:	56                   	push   %esi
f0100778:	53                   	push   %ebx
f0100779:	e8 50 fa ff ff       	call   f01001ce <__x86.get_pc_thunk.bx>
f010077e:	81 c3 8a 0b 01 00    	add    $0x10b8a,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100784:	83 ec 04             	sub    $0x4,%esp
f0100787:	8d 83 f8 09 ff ff    	lea    -0xf608(%ebx),%eax
f010078d:	50                   	push   %eax
f010078e:	8d 83 16 0a ff ff    	lea    -0xf5ea(%ebx),%eax
f0100794:	50                   	push   %eax
f0100795:	8d b3 1b 0a ff ff    	lea    -0xf5e5(%ebx),%esi
f010079b:	56                   	push   %esi
f010079c:	e8 ba 02 00 00       	call   f0100a5b <cprintf>
f01007a1:	83 c4 0c             	add    $0xc,%esp
f01007a4:	8d 83 84 0a ff ff    	lea    -0xf57c(%ebx),%eax
f01007aa:	50                   	push   %eax
f01007ab:	8d 83 24 0a ff ff    	lea    -0xf5dc(%ebx),%eax
f01007b1:	50                   	push   %eax
f01007b2:	56                   	push   %esi
f01007b3:	e8 a3 02 00 00       	call   f0100a5b <cprintf>
	return 0;
}
f01007b8:	b8 00 00 00 00       	mov    $0x0,%eax
f01007bd:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01007c0:	5b                   	pop    %ebx
f01007c1:	5e                   	pop    %esi
f01007c2:	5d                   	pop    %ebp
f01007c3:	c3                   	ret    

f01007c4 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007c4:	55                   	push   %ebp
f01007c5:	89 e5                	mov    %esp,%ebp
f01007c7:	57                   	push   %edi
f01007c8:	56                   	push   %esi
f01007c9:	53                   	push   %ebx
f01007ca:	83 ec 18             	sub    $0x18,%esp
f01007cd:	e8 fc f9 ff ff       	call   f01001ce <__x86.get_pc_thunk.bx>
f01007d2:	81 c3 36 0b 01 00    	add    $0x10b36,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007d8:	8d 83 2d 0a ff ff    	lea    -0xf5d3(%ebx),%eax
f01007de:	50                   	push   %eax
f01007df:	e8 77 02 00 00       	call   f0100a5b <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007e4:	83 c4 08             	add    $0x8,%esp
f01007e7:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f01007ed:	8d 83 ac 0a ff ff    	lea    -0xf554(%ebx),%eax
f01007f3:	50                   	push   %eax
f01007f4:	e8 62 02 00 00       	call   f0100a5b <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007f9:	83 c4 0c             	add    $0xc,%esp
f01007fc:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f0100802:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f0100808:	50                   	push   %eax
f0100809:	57                   	push   %edi
f010080a:	8d 83 d4 0a ff ff    	lea    -0xf52c(%ebx),%eax
f0100810:	50                   	push   %eax
f0100811:	e8 45 02 00 00       	call   f0100a5b <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100816:	83 c4 0c             	add    $0xc,%esp
f0100819:	c7 c0 29 1a 10 f0    	mov    $0xf0101a29,%eax
f010081f:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100825:	52                   	push   %edx
f0100826:	50                   	push   %eax
f0100827:	8d 83 f8 0a ff ff    	lea    -0xf508(%ebx),%eax
f010082d:	50                   	push   %eax
f010082e:	e8 28 02 00 00       	call   f0100a5b <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100833:	83 c4 0c             	add    $0xc,%esp
f0100836:	c7 c0 60 30 11 f0    	mov    $0xf0113060,%eax
f010083c:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100842:	52                   	push   %edx
f0100843:	50                   	push   %eax
f0100844:	8d 83 1c 0b ff ff    	lea    -0xf4e4(%ebx),%eax
f010084a:	50                   	push   %eax
f010084b:	e8 0b 02 00 00       	call   f0100a5b <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100850:	83 c4 0c             	add    $0xc,%esp
f0100853:	c7 c6 a0 36 11 f0    	mov    $0xf01136a0,%esi
f0100859:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f010085f:	50                   	push   %eax
f0100860:	56                   	push   %esi
f0100861:	8d 83 40 0b ff ff    	lea    -0xf4c0(%ebx),%eax
f0100867:	50                   	push   %eax
f0100868:	e8 ee 01 00 00       	call   f0100a5b <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f010086d:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100870:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f0100876:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100878:	c1 fe 0a             	sar    $0xa,%esi
f010087b:	56                   	push   %esi
f010087c:	8d 83 64 0b ff ff    	lea    -0xf49c(%ebx),%eax
f0100882:	50                   	push   %eax
f0100883:	e8 d3 01 00 00       	call   f0100a5b <cprintf>
	return 0;
}
f0100888:	b8 00 00 00 00       	mov    $0x0,%eax
f010088d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100890:	5b                   	pop    %ebx
f0100891:	5e                   	pop    %esi
f0100892:	5f                   	pop    %edi
f0100893:	5d                   	pop    %ebp
f0100894:	c3                   	ret    

f0100895 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100895:	55                   	push   %ebp
f0100896:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f0100898:	b8 00 00 00 00       	mov    $0x0,%eax
f010089d:	5d                   	pop    %ebp
f010089e:	c3                   	ret    

f010089f <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010089f:	55                   	push   %ebp
f01008a0:	89 e5                	mov    %esp,%ebp
f01008a2:	57                   	push   %edi
f01008a3:	56                   	push   %esi
f01008a4:	53                   	push   %ebx
f01008a5:	83 ec 68             	sub    $0x68,%esp
f01008a8:	e8 21 f9 ff ff       	call   f01001ce <__x86.get_pc_thunk.bx>
f01008ad:	81 c3 5b 0a 01 00    	add    $0x10a5b,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01008b3:	8d 83 90 0b ff ff    	lea    -0xf470(%ebx),%eax
f01008b9:	50                   	push   %eax
f01008ba:	e8 9c 01 00 00       	call   f0100a5b <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01008bf:	8d 83 b4 0b ff ff    	lea    -0xf44c(%ebx),%eax
f01008c5:	89 04 24             	mov    %eax,(%esp)
f01008c8:	e8 8e 01 00 00       	call   f0100a5b <cprintf>
f01008cd:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f01008d0:	8d bb 4a 0a ff ff    	lea    -0xf5b6(%ebx),%edi
f01008d6:	eb 4a                	jmp    f0100922 <monitor+0x83>
f01008d8:	83 ec 08             	sub    $0x8,%esp
f01008db:	0f be c0             	movsbl %al,%eax
f01008de:	50                   	push   %eax
f01008df:	57                   	push   %edi
f01008e0:	e8 cd 0c 00 00       	call   f01015b2 <strchr>
f01008e5:	83 c4 10             	add    $0x10,%esp
f01008e8:	85 c0                	test   %eax,%eax
f01008ea:	74 08                	je     f01008f4 <monitor+0x55>
			*buf++ = 0;
f01008ec:	c6 06 00             	movb   $0x0,(%esi)
f01008ef:	8d 76 01             	lea    0x1(%esi),%esi
f01008f2:	eb 79                	jmp    f010096d <monitor+0xce>
		if (*buf == 0)
f01008f4:	80 3e 00             	cmpb   $0x0,(%esi)
f01008f7:	74 7f                	je     f0100978 <monitor+0xd9>
		if (argc == MAXARGS-1) {
f01008f9:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f01008fd:	74 0f                	je     f010090e <monitor+0x6f>
		argv[argc++] = buf;
f01008ff:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100902:	8d 48 01             	lea    0x1(%eax),%ecx
f0100905:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f0100908:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
f010090c:	eb 44                	jmp    f0100952 <monitor+0xb3>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010090e:	83 ec 08             	sub    $0x8,%esp
f0100911:	6a 10                	push   $0x10
f0100913:	8d 83 4f 0a ff ff    	lea    -0xf5b1(%ebx),%eax
f0100919:	50                   	push   %eax
f010091a:	e8 3c 01 00 00       	call   f0100a5b <cprintf>
f010091f:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100922:	8d 83 46 0a ff ff    	lea    -0xf5ba(%ebx),%eax
f0100928:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f010092b:	83 ec 0c             	sub    $0xc,%esp
f010092e:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100931:	e8 44 0a 00 00       	call   f010137a <readline>
f0100936:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f0100938:	83 c4 10             	add    $0x10,%esp
f010093b:	85 c0                	test   %eax,%eax
f010093d:	74 ec                	je     f010092b <monitor+0x8c>
	argv[argc] = 0;
f010093f:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100946:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f010094d:	eb 1e                	jmp    f010096d <monitor+0xce>
			buf++;
f010094f:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100952:	0f b6 06             	movzbl (%esi),%eax
f0100955:	84 c0                	test   %al,%al
f0100957:	74 14                	je     f010096d <monitor+0xce>
f0100959:	83 ec 08             	sub    $0x8,%esp
f010095c:	0f be c0             	movsbl %al,%eax
f010095f:	50                   	push   %eax
f0100960:	57                   	push   %edi
f0100961:	e8 4c 0c 00 00       	call   f01015b2 <strchr>
f0100966:	83 c4 10             	add    $0x10,%esp
f0100969:	85 c0                	test   %eax,%eax
f010096b:	74 e2                	je     f010094f <monitor+0xb0>
		while (*buf && strchr(WHITESPACE, *buf))
f010096d:	0f b6 06             	movzbl (%esi),%eax
f0100970:	84 c0                	test   %al,%al
f0100972:	0f 85 60 ff ff ff    	jne    f01008d8 <monitor+0x39>
	argv[argc] = 0;
f0100978:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f010097b:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f0100982:	00 
	if (argc == 0)
f0100983:	85 c0                	test   %eax,%eax
f0100985:	74 9b                	je     f0100922 <monitor+0x83>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100987:	83 ec 08             	sub    $0x8,%esp
f010098a:	8d 83 16 0a ff ff    	lea    -0xf5ea(%ebx),%eax
f0100990:	50                   	push   %eax
f0100991:	ff 75 a8             	pushl  -0x58(%ebp)
f0100994:	e8 bb 0b 00 00       	call   f0101554 <strcmp>
f0100999:	83 c4 10             	add    $0x10,%esp
f010099c:	85 c0                	test   %eax,%eax
f010099e:	74 38                	je     f01009d8 <monitor+0x139>
f01009a0:	83 ec 08             	sub    $0x8,%esp
f01009a3:	8d 83 24 0a ff ff    	lea    -0xf5dc(%ebx),%eax
f01009a9:	50                   	push   %eax
f01009aa:	ff 75 a8             	pushl  -0x58(%ebp)
f01009ad:	e8 a2 0b 00 00       	call   f0101554 <strcmp>
f01009b2:	83 c4 10             	add    $0x10,%esp
f01009b5:	85 c0                	test   %eax,%eax
f01009b7:	74 1a                	je     f01009d3 <monitor+0x134>
	cprintf("Unknown command '%s'\n", argv[0]);
f01009b9:	83 ec 08             	sub    $0x8,%esp
f01009bc:	ff 75 a8             	pushl  -0x58(%ebp)
f01009bf:	8d 83 6c 0a ff ff    	lea    -0xf594(%ebx),%eax
f01009c5:	50                   	push   %eax
f01009c6:	e8 90 00 00 00       	call   f0100a5b <cprintf>
f01009cb:	83 c4 10             	add    $0x10,%esp
f01009ce:	e9 4f ff ff ff       	jmp    f0100922 <monitor+0x83>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01009d3:	b8 01 00 00 00       	mov    $0x1,%eax
			return commands[i].func(argc, argv, tf);
f01009d8:	83 ec 04             	sub    $0x4,%esp
f01009db:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01009de:	ff 75 08             	pushl  0x8(%ebp)
f01009e1:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01009e4:	52                   	push   %edx
f01009e5:	ff 75 a4             	pushl  -0x5c(%ebp)
f01009e8:	ff 94 83 10 1d 00 00 	call   *0x1d10(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f01009ef:	83 c4 10             	add    $0x10,%esp
f01009f2:	85 c0                	test   %eax,%eax
f01009f4:	0f 89 28 ff ff ff    	jns    f0100922 <monitor+0x83>
				break;
	}
}
f01009fa:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01009fd:	5b                   	pop    %ebx
f01009fe:	5e                   	pop    %esi
f01009ff:	5f                   	pop    %edi
f0100a00:	5d                   	pop    %ebp
f0100a01:	c3                   	ret    

f0100a02 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100a02:	55                   	push   %ebp
f0100a03:	89 e5                	mov    %esp,%ebp
f0100a05:	53                   	push   %ebx
f0100a06:	83 ec 10             	sub    $0x10,%esp
f0100a09:	e8 c0 f7 ff ff       	call   f01001ce <__x86.get_pc_thunk.bx>
f0100a0e:	81 c3 fa 08 01 00    	add    $0x108fa,%ebx
	cputchar(ch);
f0100a14:	ff 75 08             	pushl  0x8(%ebp)
f0100a17:	e8 29 fd ff ff       	call   f0100745 <cputchar>
	*cnt++;
}
f0100a1c:	83 c4 10             	add    $0x10,%esp
f0100a1f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100a22:	c9                   	leave  
f0100a23:	c3                   	ret    

f0100a24 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100a24:	55                   	push   %ebp
f0100a25:	89 e5                	mov    %esp,%ebp
f0100a27:	53                   	push   %ebx
f0100a28:	83 ec 14             	sub    $0x14,%esp
f0100a2b:	e8 9e f7 ff ff       	call   f01001ce <__x86.get_pc_thunk.bx>
f0100a30:	81 c3 d8 08 01 00    	add    $0x108d8,%ebx
	int cnt = 0;
f0100a36:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100a3d:	ff 75 0c             	pushl  0xc(%ebp)
f0100a40:	ff 75 08             	pushl  0x8(%ebp)
f0100a43:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100a46:	50                   	push   %eax
f0100a47:	8d 83 fa f6 fe ff    	lea    -0x10906(%ebx),%eax
f0100a4d:	50                   	push   %eax
f0100a4e:	e8 1c 04 00 00       	call   f0100e6f <vprintfmt>
	return cnt;
}
f0100a53:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100a56:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100a59:	c9                   	leave  
f0100a5a:	c3                   	ret    

f0100a5b <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100a5b:	55                   	push   %ebp
f0100a5c:	89 e5                	mov    %esp,%ebp
f0100a5e:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100a61:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100a64:	50                   	push   %eax
f0100a65:	ff 75 08             	pushl  0x8(%ebp)
f0100a68:	e8 b7 ff ff ff       	call   f0100a24 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a6d:	c9                   	leave  
f0100a6e:	c3                   	ret    

f0100a6f <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a6f:	55                   	push   %ebp
f0100a70:	89 e5                	mov    %esp,%ebp
f0100a72:	57                   	push   %edi
f0100a73:	56                   	push   %esi
f0100a74:	53                   	push   %ebx
f0100a75:	83 ec 14             	sub    $0x14,%esp
f0100a78:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100a7b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100a7e:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100a81:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100a84:	8b 32                	mov    (%edx),%esi
f0100a86:	8b 01                	mov    (%ecx),%eax
f0100a88:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100a8b:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100a92:	eb 2f                	jmp    f0100ac3 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0100a94:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0100a97:	39 c6                	cmp    %eax,%esi
f0100a99:	7f 49                	jg     f0100ae4 <stab_binsearch+0x75>
f0100a9b:	0f b6 0a             	movzbl (%edx),%ecx
f0100a9e:	83 ea 0c             	sub    $0xc,%edx
f0100aa1:	39 f9                	cmp    %edi,%ecx
f0100aa3:	75 ef                	jne    f0100a94 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100aa5:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100aa8:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100aab:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100aaf:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100ab2:	73 35                	jae    f0100ae9 <stab_binsearch+0x7a>
			*region_left = m;
f0100ab4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100ab7:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0100ab9:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f0100abc:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0100ac3:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0100ac6:	7f 4e                	jg     f0100b16 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0100ac8:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100acb:	01 f0                	add    %esi,%eax
f0100acd:	89 c3                	mov    %eax,%ebx
f0100acf:	c1 eb 1f             	shr    $0x1f,%ebx
f0100ad2:	01 c3                	add    %eax,%ebx
f0100ad4:	d1 fb                	sar    %ebx
f0100ad6:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100ad9:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100adc:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0100ae0:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0100ae2:	eb b3                	jmp    f0100a97 <stab_binsearch+0x28>
			l = true_m + 1;
f0100ae4:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0100ae7:	eb da                	jmp    f0100ac3 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0100ae9:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100aec:	76 14                	jbe    f0100b02 <stab_binsearch+0x93>
			*region_right = m - 1;
f0100aee:	83 e8 01             	sub    $0x1,%eax
f0100af1:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100af4:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100af7:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0100af9:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100b00:	eb c1                	jmp    f0100ac3 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100b02:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100b05:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100b07:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100b0b:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f0100b0d:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100b14:	eb ad                	jmp    f0100ac3 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0100b16:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100b1a:	74 16                	je     f0100b32 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b1c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b1f:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100b21:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100b24:	8b 0e                	mov    (%esi),%ecx
f0100b26:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100b29:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100b2c:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f0100b30:	eb 12                	jmp    f0100b44 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0100b32:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b35:	8b 00                	mov    (%eax),%eax
f0100b37:	83 e8 01             	sub    $0x1,%eax
f0100b3a:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100b3d:	89 07                	mov    %eax,(%edi)
f0100b3f:	eb 16                	jmp    f0100b57 <stab_binsearch+0xe8>
		     l--)
f0100b41:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0100b44:	39 c1                	cmp    %eax,%ecx
f0100b46:	7d 0a                	jge    f0100b52 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0100b48:	0f b6 1a             	movzbl (%edx),%ebx
f0100b4b:	83 ea 0c             	sub    $0xc,%edx
f0100b4e:	39 fb                	cmp    %edi,%ebx
f0100b50:	75 ef                	jne    f0100b41 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f0100b52:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100b55:	89 07                	mov    %eax,(%edi)
	}
}
f0100b57:	83 c4 14             	add    $0x14,%esp
f0100b5a:	5b                   	pop    %ebx
f0100b5b:	5e                   	pop    %esi
f0100b5c:	5f                   	pop    %edi
f0100b5d:	5d                   	pop    %ebp
f0100b5e:	c3                   	ret    

f0100b5f <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100b5f:	55                   	push   %ebp
f0100b60:	89 e5                	mov    %esp,%ebp
f0100b62:	57                   	push   %edi
f0100b63:	56                   	push   %esi
f0100b64:	53                   	push   %ebx
f0100b65:	83 ec 2c             	sub    $0x2c,%esp
f0100b68:	e8 fa 01 00 00       	call   f0100d67 <__x86.get_pc_thunk.cx>
f0100b6d:	81 c1 9b 07 01 00    	add    $0x1079b,%ecx
f0100b73:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0100b76:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100b79:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100b7c:	8d 81 dc 0b ff ff    	lea    -0xf424(%ecx),%eax
f0100b82:	89 07                	mov    %eax,(%edi)
	info->eip_line = 0;
f0100b84:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f0100b8b:	89 47 08             	mov    %eax,0x8(%edi)
	info->eip_fn_namelen = 9;
f0100b8e:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f0100b95:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f0100b98:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100b9f:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0100ba5:	0f 86 f4 00 00 00    	jbe    f0100c9f <debuginfo_eip+0x140>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100bab:	c7 c0 d1 5c 10 f0    	mov    $0xf0105cd1,%eax
f0100bb1:	39 81 fc ff ff ff    	cmp    %eax,-0x4(%ecx)
f0100bb7:	0f 86 88 01 00 00    	jbe    f0100d45 <debuginfo_eip+0x1e6>
f0100bbd:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0100bc0:	c7 c0 18 76 10 f0    	mov    $0xf0107618,%eax
f0100bc6:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0100bca:	0f 85 7c 01 00 00    	jne    f0100d4c <debuginfo_eip+0x1ed>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100bd0:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100bd7:	c7 c0 00 21 10 f0    	mov    $0xf0102100,%eax
f0100bdd:	c7 c2 d0 5c 10 f0    	mov    $0xf0105cd0,%edx
f0100be3:	29 c2                	sub    %eax,%edx
f0100be5:	c1 fa 02             	sar    $0x2,%edx
f0100be8:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0100bee:	83 ea 01             	sub    $0x1,%edx
f0100bf1:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100bf4:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100bf7:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100bfa:	83 ec 08             	sub    $0x8,%esp
f0100bfd:	53                   	push   %ebx
f0100bfe:	6a 64                	push   $0x64
f0100c00:	e8 6a fe ff ff       	call   f0100a6f <stab_binsearch>
	if (lfile == 0)
f0100c05:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c08:	83 c4 10             	add    $0x10,%esp
f0100c0b:	85 c0                	test   %eax,%eax
f0100c0d:	0f 84 40 01 00 00    	je     f0100d53 <debuginfo_eip+0x1f4>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100c13:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100c16:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c19:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100c1c:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100c1f:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c22:	83 ec 08             	sub    $0x8,%esp
f0100c25:	53                   	push   %ebx
f0100c26:	6a 24                	push   $0x24
f0100c28:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0100c2b:	c7 c0 00 21 10 f0    	mov    $0xf0102100,%eax
f0100c31:	e8 39 fe ff ff       	call   f0100a6f <stab_binsearch>

	if (lfun <= rfun) {
f0100c36:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0100c39:	83 c4 10             	add    $0x10,%esp
f0100c3c:	3b 75 d8             	cmp    -0x28(%ebp),%esi
f0100c3f:	7f 79                	jg     f0100cba <debuginfo_eip+0x15b>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100c41:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100c44:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100c47:	c7 c2 00 21 10 f0    	mov    $0xf0102100,%edx
f0100c4d:	8d 0c 82             	lea    (%edx,%eax,4),%ecx
f0100c50:	8b 11                	mov    (%ecx),%edx
f0100c52:	c7 c0 18 76 10 f0    	mov    $0xf0107618,%eax
f0100c58:	81 e8 d1 5c 10 f0    	sub    $0xf0105cd1,%eax
f0100c5e:	39 c2                	cmp    %eax,%edx
f0100c60:	73 09                	jae    f0100c6b <debuginfo_eip+0x10c>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100c62:	81 c2 d1 5c 10 f0    	add    $0xf0105cd1,%edx
f0100c68:	89 57 08             	mov    %edx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c6b:	8b 41 08             	mov    0x8(%ecx),%eax
f0100c6e:	89 47 10             	mov    %eax,0x10(%edi)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c71:	83 ec 08             	sub    $0x8,%esp
f0100c74:	6a 3a                	push   $0x3a
f0100c76:	ff 77 08             	pushl  0x8(%edi)
f0100c79:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100c7c:	e8 52 09 00 00       	call   f01015d3 <strfind>
f0100c81:	2b 47 08             	sub    0x8(%edi),%eax
f0100c84:	89 47 0c             	mov    %eax,0xc(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100c87:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100c8a:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100c8d:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100c90:	c7 c2 00 21 10 f0    	mov    $0xf0102100,%edx
f0100c96:	8d 44 82 04          	lea    0x4(%edx,%eax,4),%eax
f0100c9a:	83 c4 10             	add    $0x10,%esp
f0100c9d:	eb 29                	jmp    f0100cc8 <debuginfo_eip+0x169>
  	        panic("User address");
f0100c9f:	83 ec 04             	sub    $0x4,%esp
f0100ca2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100ca5:	8d 83 e6 0b ff ff    	lea    -0xf41a(%ebx),%eax
f0100cab:	50                   	push   %eax
f0100cac:	6a 7f                	push   $0x7f
f0100cae:	8d 83 f3 0b ff ff    	lea    -0xf40d(%ebx),%eax
f0100cb4:	50                   	push   %eax
f0100cb5:	e8 5e f4 ff ff       	call   f0100118 <_panic>
		info->eip_fn_addr = addr;
f0100cba:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f0100cbd:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100cc0:	eb af                	jmp    f0100c71 <debuginfo_eip+0x112>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100cc2:	83 ee 01             	sub    $0x1,%esi
f0100cc5:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f0100cc8:	39 f3                	cmp    %esi,%ebx
f0100cca:	7f 3a                	jg     f0100d06 <debuginfo_eip+0x1a7>
	       && stabs[lline].n_type != N_SOL
f0100ccc:	0f b6 10             	movzbl (%eax),%edx
f0100ccf:	80 fa 84             	cmp    $0x84,%dl
f0100cd2:	74 0b                	je     f0100cdf <debuginfo_eip+0x180>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100cd4:	80 fa 64             	cmp    $0x64,%dl
f0100cd7:	75 e9                	jne    f0100cc2 <debuginfo_eip+0x163>
f0100cd9:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f0100cdd:	74 e3                	je     f0100cc2 <debuginfo_eip+0x163>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100cdf:	8d 14 76             	lea    (%esi,%esi,2),%edx
f0100ce2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100ce5:	c7 c0 00 21 10 f0    	mov    $0xf0102100,%eax
f0100ceb:	8b 14 90             	mov    (%eax,%edx,4),%edx
f0100cee:	c7 c0 18 76 10 f0    	mov    $0xf0107618,%eax
f0100cf4:	81 e8 d1 5c 10 f0    	sub    $0xf0105cd1,%eax
f0100cfa:	39 c2                	cmp    %eax,%edx
f0100cfc:	73 08                	jae    f0100d06 <debuginfo_eip+0x1a7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100cfe:	81 c2 d1 5c 10 f0    	add    $0xf0105cd1,%edx
f0100d04:	89 17                	mov    %edx,(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100d06:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100d09:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d0c:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0100d11:	39 cb                	cmp    %ecx,%ebx
f0100d13:	7d 4a                	jge    f0100d5f <debuginfo_eip+0x200>
		for (lline = lfun + 1;
f0100d15:	8d 53 01             	lea    0x1(%ebx),%edx
f0100d18:	8d 1c 5b             	lea    (%ebx,%ebx,2),%ebx
f0100d1b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d1e:	c7 c0 00 21 10 f0    	mov    $0xf0102100,%eax
f0100d24:	8d 44 98 10          	lea    0x10(%eax,%ebx,4),%eax
f0100d28:	eb 07                	jmp    f0100d31 <debuginfo_eip+0x1d2>
			info->eip_fn_narg++;
f0100d2a:	83 47 14 01          	addl   $0x1,0x14(%edi)
		     lline++)
f0100d2e:	83 c2 01             	add    $0x1,%edx
		for (lline = lfun + 1;
f0100d31:	39 d1                	cmp    %edx,%ecx
f0100d33:	74 25                	je     f0100d5a <debuginfo_eip+0x1fb>
f0100d35:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d38:	80 78 f4 a0          	cmpb   $0xa0,-0xc(%eax)
f0100d3c:	74 ec                	je     f0100d2a <debuginfo_eip+0x1cb>
	return 0;
f0100d3e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d43:	eb 1a                	jmp    f0100d5f <debuginfo_eip+0x200>
		return -1;
f0100d45:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d4a:	eb 13                	jmp    f0100d5f <debuginfo_eip+0x200>
f0100d4c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d51:	eb 0c                	jmp    f0100d5f <debuginfo_eip+0x200>
		return -1;
f0100d53:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d58:	eb 05                	jmp    f0100d5f <debuginfo_eip+0x200>
	return 0;
f0100d5a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100d5f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d62:	5b                   	pop    %ebx
f0100d63:	5e                   	pop    %esi
f0100d64:	5f                   	pop    %edi
f0100d65:	5d                   	pop    %ebp
f0100d66:	c3                   	ret    

f0100d67 <__x86.get_pc_thunk.cx>:
f0100d67:	8b 0c 24             	mov    (%esp),%ecx
f0100d6a:	c3                   	ret    

f0100d6b <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d6b:	55                   	push   %ebp
f0100d6c:	89 e5                	mov    %esp,%ebp
f0100d6e:	57                   	push   %edi
f0100d6f:	56                   	push   %esi
f0100d70:	53                   	push   %ebx
f0100d71:	83 ec 2c             	sub    $0x2c,%esp
f0100d74:	e8 ee ff ff ff       	call   f0100d67 <__x86.get_pc_thunk.cx>
f0100d79:	81 c1 8f 05 01 00    	add    $0x1058f,%ecx
f0100d7f:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100d82:	89 c7                	mov    %eax,%edi
f0100d84:	89 d6                	mov    %edx,%esi
f0100d86:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d89:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100d8c:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100d8f:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100d92:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100d95:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100d9a:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f0100d9d:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0100da0:	39 d3                	cmp    %edx,%ebx
f0100da2:	72 09                	jb     f0100dad <printnum+0x42>
f0100da4:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100da7:	0f 87 83 00 00 00    	ja     f0100e30 <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100dad:	83 ec 0c             	sub    $0xc,%esp
f0100db0:	ff 75 18             	pushl  0x18(%ebp)
f0100db3:	8b 45 14             	mov    0x14(%ebp),%eax
f0100db6:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100db9:	53                   	push   %ebx
f0100dba:	ff 75 10             	pushl  0x10(%ebp)
f0100dbd:	83 ec 08             	sub    $0x8,%esp
f0100dc0:	ff 75 dc             	pushl  -0x24(%ebp)
f0100dc3:	ff 75 d8             	pushl  -0x28(%ebp)
f0100dc6:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100dc9:	ff 75 d0             	pushl  -0x30(%ebp)
f0100dcc:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100dcf:	e8 1c 0a 00 00       	call   f01017f0 <__udivdi3>
f0100dd4:	83 c4 18             	add    $0x18,%esp
f0100dd7:	52                   	push   %edx
f0100dd8:	50                   	push   %eax
f0100dd9:	89 f2                	mov    %esi,%edx
f0100ddb:	89 f8                	mov    %edi,%eax
f0100ddd:	e8 89 ff ff ff       	call   f0100d6b <printnum>
f0100de2:	83 c4 20             	add    $0x20,%esp
f0100de5:	eb 13                	jmp    f0100dfa <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100de7:	83 ec 08             	sub    $0x8,%esp
f0100dea:	56                   	push   %esi
f0100deb:	ff 75 18             	pushl  0x18(%ebp)
f0100dee:	ff d7                	call   *%edi
f0100df0:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0100df3:	83 eb 01             	sub    $0x1,%ebx
f0100df6:	85 db                	test   %ebx,%ebx
f0100df8:	7f ed                	jg     f0100de7 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100dfa:	83 ec 08             	sub    $0x8,%esp
f0100dfd:	56                   	push   %esi
f0100dfe:	83 ec 04             	sub    $0x4,%esp
f0100e01:	ff 75 dc             	pushl  -0x24(%ebp)
f0100e04:	ff 75 d8             	pushl  -0x28(%ebp)
f0100e07:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100e0a:	ff 75 d0             	pushl  -0x30(%ebp)
f0100e0d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100e10:	89 f3                	mov    %esi,%ebx
f0100e12:	e8 f9 0a 00 00       	call   f0101910 <__umoddi3>
f0100e17:	83 c4 14             	add    $0x14,%esp
f0100e1a:	0f be 84 06 01 0c ff 	movsbl -0xf3ff(%esi,%eax,1),%eax
f0100e21:	ff 
f0100e22:	50                   	push   %eax
f0100e23:	ff d7                	call   *%edi
}
f0100e25:	83 c4 10             	add    $0x10,%esp
f0100e28:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e2b:	5b                   	pop    %ebx
f0100e2c:	5e                   	pop    %esi
f0100e2d:	5f                   	pop    %edi
f0100e2e:	5d                   	pop    %ebp
f0100e2f:	c3                   	ret    
f0100e30:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100e33:	eb be                	jmp    f0100df3 <printnum+0x88>

f0100e35 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e35:	55                   	push   %ebp
f0100e36:	89 e5                	mov    %esp,%ebp
f0100e38:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e3b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100e3f:	8b 10                	mov    (%eax),%edx
f0100e41:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e44:	73 0a                	jae    f0100e50 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100e46:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100e49:	89 08                	mov    %ecx,(%eax)
f0100e4b:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e4e:	88 02                	mov    %al,(%edx)
}
f0100e50:	5d                   	pop    %ebp
f0100e51:	c3                   	ret    

f0100e52 <printfmt>:
{
f0100e52:	55                   	push   %ebp
f0100e53:	89 e5                	mov    %esp,%ebp
f0100e55:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0100e58:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e5b:	50                   	push   %eax
f0100e5c:	ff 75 10             	pushl  0x10(%ebp)
f0100e5f:	ff 75 0c             	pushl  0xc(%ebp)
f0100e62:	ff 75 08             	pushl  0x8(%ebp)
f0100e65:	e8 05 00 00 00       	call   f0100e6f <vprintfmt>
}
f0100e6a:	83 c4 10             	add    $0x10,%esp
f0100e6d:	c9                   	leave  
f0100e6e:	c3                   	ret    

f0100e6f <vprintfmt>:
{
f0100e6f:	55                   	push   %ebp
f0100e70:	89 e5                	mov    %esp,%ebp
f0100e72:	57                   	push   %edi
f0100e73:	56                   	push   %esi
f0100e74:	53                   	push   %ebx
f0100e75:	83 ec 2c             	sub    $0x2c,%esp
f0100e78:	e8 51 f3 ff ff       	call   f01001ce <__x86.get_pc_thunk.bx>
f0100e7d:	81 c3 8b 04 01 00    	add    $0x1048b,%ebx
f0100e83:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100e86:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100e89:	e9 63 03 00 00       	jmp    f01011f1 <.L34+0x40>
		padc = ' ';
f0100e8e:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f0100e92:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0100e99:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
		width = -1;
f0100ea0:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0100ea7:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100eac:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100eaf:	8d 47 01             	lea    0x1(%edi),%eax
f0100eb2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100eb5:	0f b6 17             	movzbl (%edi),%edx
f0100eb8:	8d 42 dd             	lea    -0x23(%edx),%eax
f0100ebb:	3c 55                	cmp    $0x55,%al
f0100ebd:	0f 87 15 04 00 00    	ja     f01012d8 <.L22>
f0100ec3:	0f b6 c0             	movzbl %al,%eax
f0100ec6:	89 d9                	mov    %ebx,%ecx
f0100ec8:	03 8c 83 90 0c ff ff 	add    -0xf370(%ebx,%eax,4),%ecx
f0100ecf:	ff e1                	jmp    *%ecx

f0100ed1 <.L70>:
f0100ed1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0100ed4:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0100ed8:	eb d5                	jmp    f0100eaf <vprintfmt+0x40>

f0100eda <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f0100eda:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f0100edd:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100ee1:	eb cc                	jmp    f0100eaf <vprintfmt+0x40>

f0100ee3 <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f0100ee3:	0f b6 d2             	movzbl %dl,%edx
f0100ee6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0100ee9:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f0100eee:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100ef1:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0100ef5:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0100ef8:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0100efb:	83 f9 09             	cmp    $0x9,%ecx
f0100efe:	77 55                	ja     f0100f55 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f0100f00:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0100f03:	eb e9                	jmp    f0100eee <.L29+0xb>

f0100f05 <.L26>:
			precision = va_arg(ap, int);
f0100f05:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f08:	8b 00                	mov    (%eax),%eax
f0100f0a:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100f0d:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f10:	8d 40 04             	lea    0x4(%eax),%eax
f0100f13:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100f16:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0100f19:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100f1d:	79 90                	jns    f0100eaf <vprintfmt+0x40>
				width = precision, precision = -1;
f0100f1f:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0100f22:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f25:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f0100f2c:	eb 81                	jmp    f0100eaf <vprintfmt+0x40>

f0100f2e <.L27>:
f0100f2e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f31:	85 c0                	test   %eax,%eax
f0100f33:	ba 00 00 00 00       	mov    $0x0,%edx
f0100f38:	0f 49 d0             	cmovns %eax,%edx
f0100f3b:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100f3e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f41:	e9 69 ff ff ff       	jmp    f0100eaf <vprintfmt+0x40>

f0100f46 <.L23>:
f0100f46:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0100f49:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100f50:	e9 5a ff ff ff       	jmp    f0100eaf <vprintfmt+0x40>
f0100f55:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100f58:	eb bf                	jmp    f0100f19 <.L26+0x14>

f0100f5a <.L33>:
			lflag++;
f0100f5a:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100f5e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0100f61:	e9 49 ff ff ff       	jmp    f0100eaf <vprintfmt+0x40>

f0100f66 <.L30>:
			putch(va_arg(ap, int), putdat);
f0100f66:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f69:	8d 78 04             	lea    0x4(%eax),%edi
f0100f6c:	83 ec 08             	sub    $0x8,%esp
f0100f6f:	56                   	push   %esi
f0100f70:	ff 30                	pushl  (%eax)
f0100f72:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100f75:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0100f78:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0100f7b:	e9 6e 02 00 00       	jmp    f01011ee <.L34+0x3d>

f0100f80 <.L32>:
			err = va_arg(ap, int);
f0100f80:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f83:	8d 78 04             	lea    0x4(%eax),%edi
f0100f86:	8b 00                	mov    (%eax),%eax
f0100f88:	99                   	cltd   
f0100f89:	31 d0                	xor    %edx,%eax
f0100f8b:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100f8d:	83 f8 06             	cmp    $0x6,%eax
f0100f90:	7f 27                	jg     f0100fb9 <.L32+0x39>
f0100f92:	8b 94 83 20 1d 00 00 	mov    0x1d20(%ebx,%eax,4),%edx
f0100f99:	85 d2                	test   %edx,%edx
f0100f9b:	74 1c                	je     f0100fb9 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f0100f9d:	52                   	push   %edx
f0100f9e:	8d 83 22 0c ff ff    	lea    -0xf3de(%ebx),%eax
f0100fa4:	50                   	push   %eax
f0100fa5:	56                   	push   %esi
f0100fa6:	ff 75 08             	pushl  0x8(%ebp)
f0100fa9:	e8 a4 fe ff ff       	call   f0100e52 <printfmt>
f0100fae:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0100fb1:	89 7d 14             	mov    %edi,0x14(%ebp)
f0100fb4:	e9 35 02 00 00       	jmp    f01011ee <.L34+0x3d>
				printfmt(putch, putdat, "error %d", err);
f0100fb9:	50                   	push   %eax
f0100fba:	8d 83 19 0c ff ff    	lea    -0xf3e7(%ebx),%eax
f0100fc0:	50                   	push   %eax
f0100fc1:	56                   	push   %esi
f0100fc2:	ff 75 08             	pushl  0x8(%ebp)
f0100fc5:	e8 88 fe ff ff       	call   f0100e52 <printfmt>
f0100fca:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0100fcd:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0100fd0:	e9 19 02 00 00       	jmp    f01011ee <.L34+0x3d>

f0100fd5 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f0100fd5:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fd8:	83 c0 04             	add    $0x4,%eax
f0100fdb:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100fde:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fe1:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0100fe3:	85 ff                	test   %edi,%edi
f0100fe5:	8d 83 12 0c ff ff    	lea    -0xf3ee(%ebx),%eax
f0100feb:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0100fee:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100ff2:	0f 8e b5 00 00 00    	jle    f01010ad <.L36+0xd8>
f0100ff8:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0100ffc:	75 08                	jne    f0101006 <.L36+0x31>
f0100ffe:	89 75 0c             	mov    %esi,0xc(%ebp)
f0101001:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0101004:	eb 6d                	jmp    f0101073 <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101006:	83 ec 08             	sub    $0x8,%esp
f0101009:	ff 75 cc             	pushl  -0x34(%ebp)
f010100c:	57                   	push   %edi
f010100d:	e8 7d 04 00 00       	call   f010148f <strnlen>
f0101012:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101015:	29 c2                	sub    %eax,%edx
f0101017:	89 55 c8             	mov    %edx,-0x38(%ebp)
f010101a:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f010101d:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0101021:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101024:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101027:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0101029:	eb 10                	jmp    f010103b <.L36+0x66>
					putch(padc, putdat);
f010102b:	83 ec 08             	sub    $0x8,%esp
f010102e:	56                   	push   %esi
f010102f:	ff 75 e0             	pushl  -0x20(%ebp)
f0101032:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0101035:	83 ef 01             	sub    $0x1,%edi
f0101038:	83 c4 10             	add    $0x10,%esp
f010103b:	85 ff                	test   %edi,%edi
f010103d:	7f ec                	jg     f010102b <.L36+0x56>
f010103f:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101042:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0101045:	85 d2                	test   %edx,%edx
f0101047:	b8 00 00 00 00       	mov    $0x0,%eax
f010104c:	0f 49 c2             	cmovns %edx,%eax
f010104f:	29 c2                	sub    %eax,%edx
f0101051:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101054:	89 75 0c             	mov    %esi,0xc(%ebp)
f0101057:	8b 75 cc             	mov    -0x34(%ebp),%esi
f010105a:	eb 17                	jmp    f0101073 <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f010105c:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101060:	75 30                	jne    f0101092 <.L36+0xbd>
					putch(ch, putdat);
f0101062:	83 ec 08             	sub    $0x8,%esp
f0101065:	ff 75 0c             	pushl  0xc(%ebp)
f0101068:	50                   	push   %eax
f0101069:	ff 55 08             	call   *0x8(%ebp)
f010106c:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010106f:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f0101073:	83 c7 01             	add    $0x1,%edi
f0101076:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f010107a:	0f be c2             	movsbl %dl,%eax
f010107d:	85 c0                	test   %eax,%eax
f010107f:	74 52                	je     f01010d3 <.L36+0xfe>
f0101081:	85 f6                	test   %esi,%esi
f0101083:	78 d7                	js     f010105c <.L36+0x87>
f0101085:	83 ee 01             	sub    $0x1,%esi
f0101088:	79 d2                	jns    f010105c <.L36+0x87>
f010108a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010108d:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101090:	eb 32                	jmp    f01010c4 <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f0101092:	0f be d2             	movsbl %dl,%edx
f0101095:	83 ea 20             	sub    $0x20,%edx
f0101098:	83 fa 5e             	cmp    $0x5e,%edx
f010109b:	76 c5                	jbe    f0101062 <.L36+0x8d>
					putch('?', putdat);
f010109d:	83 ec 08             	sub    $0x8,%esp
f01010a0:	ff 75 0c             	pushl  0xc(%ebp)
f01010a3:	6a 3f                	push   $0x3f
f01010a5:	ff 55 08             	call   *0x8(%ebp)
f01010a8:	83 c4 10             	add    $0x10,%esp
f01010ab:	eb c2                	jmp    f010106f <.L36+0x9a>
f01010ad:	89 75 0c             	mov    %esi,0xc(%ebp)
f01010b0:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01010b3:	eb be                	jmp    f0101073 <.L36+0x9e>
				putch(' ', putdat);
f01010b5:	83 ec 08             	sub    $0x8,%esp
f01010b8:	56                   	push   %esi
f01010b9:	6a 20                	push   $0x20
f01010bb:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f01010be:	83 ef 01             	sub    $0x1,%edi
f01010c1:	83 c4 10             	add    $0x10,%esp
f01010c4:	85 ff                	test   %edi,%edi
f01010c6:	7f ed                	jg     f01010b5 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f01010c8:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01010cb:	89 45 14             	mov    %eax,0x14(%ebp)
f01010ce:	e9 1b 01 00 00       	jmp    f01011ee <.L34+0x3d>
f01010d3:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01010d6:	8b 75 0c             	mov    0xc(%ebp),%esi
f01010d9:	eb e9                	jmp    f01010c4 <.L36+0xef>

f01010db <.L31>:
f01010db:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01010de:	83 f9 01             	cmp    $0x1,%ecx
f01010e1:	7e 40                	jle    f0101123 <.L31+0x48>
		return va_arg(*ap, long long);
f01010e3:	8b 45 14             	mov    0x14(%ebp),%eax
f01010e6:	8b 50 04             	mov    0x4(%eax),%edx
f01010e9:	8b 00                	mov    (%eax),%eax
f01010eb:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01010ee:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01010f1:	8b 45 14             	mov    0x14(%ebp),%eax
f01010f4:	8d 40 08             	lea    0x8(%eax),%eax
f01010f7:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f01010fa:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01010fe:	79 55                	jns    f0101155 <.L31+0x7a>
				putch('-', putdat);
f0101100:	83 ec 08             	sub    $0x8,%esp
f0101103:	56                   	push   %esi
f0101104:	6a 2d                	push   $0x2d
f0101106:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0101109:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010110c:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010110f:	f7 da                	neg    %edx
f0101111:	83 d1 00             	adc    $0x0,%ecx
f0101114:	f7 d9                	neg    %ecx
f0101116:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0101119:	b8 0a 00 00 00       	mov    $0xa,%eax
f010111e:	e9 b0 00 00 00       	jmp    f01011d3 <.L34+0x22>
	else if (lflag)
f0101123:	85 c9                	test   %ecx,%ecx
f0101125:	75 17                	jne    f010113e <.L31+0x63>
		return va_arg(*ap, int);
f0101127:	8b 45 14             	mov    0x14(%ebp),%eax
f010112a:	8b 00                	mov    (%eax),%eax
f010112c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010112f:	99                   	cltd   
f0101130:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101133:	8b 45 14             	mov    0x14(%ebp),%eax
f0101136:	8d 40 04             	lea    0x4(%eax),%eax
f0101139:	89 45 14             	mov    %eax,0x14(%ebp)
f010113c:	eb bc                	jmp    f01010fa <.L31+0x1f>
		return va_arg(*ap, long);
f010113e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101141:	8b 00                	mov    (%eax),%eax
f0101143:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101146:	99                   	cltd   
f0101147:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010114a:	8b 45 14             	mov    0x14(%ebp),%eax
f010114d:	8d 40 04             	lea    0x4(%eax),%eax
f0101150:	89 45 14             	mov    %eax,0x14(%ebp)
f0101153:	eb a5                	jmp    f01010fa <.L31+0x1f>
			num = getint(&ap, lflag);
f0101155:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101158:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f010115b:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101160:	eb 71                	jmp    f01011d3 <.L34+0x22>

f0101162 <.L37>:
f0101162:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0101165:	83 f9 01             	cmp    $0x1,%ecx
f0101168:	7e 15                	jle    f010117f <.L37+0x1d>
		return va_arg(*ap, unsigned long long);
f010116a:	8b 45 14             	mov    0x14(%ebp),%eax
f010116d:	8b 10                	mov    (%eax),%edx
f010116f:	8b 48 04             	mov    0x4(%eax),%ecx
f0101172:	8d 40 08             	lea    0x8(%eax),%eax
f0101175:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101178:	b8 0a 00 00 00       	mov    $0xa,%eax
f010117d:	eb 54                	jmp    f01011d3 <.L34+0x22>
	else if (lflag)
f010117f:	85 c9                	test   %ecx,%ecx
f0101181:	75 17                	jne    f010119a <.L37+0x38>
		return va_arg(*ap, unsigned int);
f0101183:	8b 45 14             	mov    0x14(%ebp),%eax
f0101186:	8b 10                	mov    (%eax),%edx
f0101188:	b9 00 00 00 00       	mov    $0x0,%ecx
f010118d:	8d 40 04             	lea    0x4(%eax),%eax
f0101190:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101193:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101198:	eb 39                	jmp    f01011d3 <.L34+0x22>
		return va_arg(*ap, unsigned long);
f010119a:	8b 45 14             	mov    0x14(%ebp),%eax
f010119d:	8b 10                	mov    (%eax),%edx
f010119f:	b9 00 00 00 00       	mov    $0x0,%ecx
f01011a4:	8d 40 04             	lea    0x4(%eax),%eax
f01011a7:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01011aa:	b8 0a 00 00 00       	mov    $0xa,%eax
f01011af:	eb 22                	jmp    f01011d3 <.L34+0x22>

f01011b1 <.L34>:
f01011b1:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01011b4:	83 f9 01             	cmp    $0x1,%ecx
f01011b7:	7e 5d                	jle    f0101216 <.L34+0x65>
		return va_arg(*ap, long long);
f01011b9:	8b 45 14             	mov    0x14(%ebp),%eax
f01011bc:	8b 50 04             	mov    0x4(%eax),%edx
f01011bf:	8b 00                	mov    (%eax),%eax
f01011c1:	8b 4d 14             	mov    0x14(%ebp),%ecx
f01011c4:	8d 49 08             	lea    0x8(%ecx),%ecx
f01011c7:	89 4d 14             	mov    %ecx,0x14(%ebp)
			num = getint(&ap, lflag);
f01011ca:	89 d1                	mov    %edx,%ecx
f01011cc:	89 c2                	mov    %eax,%edx
			base = 8;
f01011ce:	b8 08 00 00 00       	mov    $0x8,%eax
			printnum(putch, putdat, num, base, width, padc);
f01011d3:	83 ec 0c             	sub    $0xc,%esp
f01011d6:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01011da:	57                   	push   %edi
f01011db:	ff 75 e0             	pushl  -0x20(%ebp)
f01011de:	50                   	push   %eax
f01011df:	51                   	push   %ecx
f01011e0:	52                   	push   %edx
f01011e1:	89 f2                	mov    %esi,%edx
f01011e3:	8b 45 08             	mov    0x8(%ebp),%eax
f01011e6:	e8 80 fb ff ff       	call   f0100d6b <printnum>
			break;
f01011eb:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f01011ee:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01011f1:	83 c7 01             	add    $0x1,%edi
f01011f4:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01011f8:	83 f8 25             	cmp    $0x25,%eax
f01011fb:	0f 84 8d fc ff ff    	je     f0100e8e <vprintfmt+0x1f>
			if (ch == '\0')
f0101201:	85 c0                	test   %eax,%eax
f0101203:	0f 84 f0 00 00 00    	je     f01012f9 <.L22+0x21>
			putch(ch, putdat);
f0101209:	83 ec 08             	sub    $0x8,%esp
f010120c:	56                   	push   %esi
f010120d:	50                   	push   %eax
f010120e:	ff 55 08             	call   *0x8(%ebp)
f0101211:	83 c4 10             	add    $0x10,%esp
f0101214:	eb db                	jmp    f01011f1 <.L34+0x40>
	else if (lflag)
f0101216:	85 c9                	test   %ecx,%ecx
f0101218:	75 13                	jne    f010122d <.L34+0x7c>
		return va_arg(*ap, int);
f010121a:	8b 45 14             	mov    0x14(%ebp),%eax
f010121d:	8b 10                	mov    (%eax),%edx
f010121f:	89 d0                	mov    %edx,%eax
f0101221:	99                   	cltd   
f0101222:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0101225:	8d 49 04             	lea    0x4(%ecx),%ecx
f0101228:	89 4d 14             	mov    %ecx,0x14(%ebp)
f010122b:	eb 9d                	jmp    f01011ca <.L34+0x19>
		return va_arg(*ap, long);
f010122d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101230:	8b 10                	mov    (%eax),%edx
f0101232:	89 d0                	mov    %edx,%eax
f0101234:	99                   	cltd   
f0101235:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0101238:	8d 49 04             	lea    0x4(%ecx),%ecx
f010123b:	89 4d 14             	mov    %ecx,0x14(%ebp)
f010123e:	eb 8a                	jmp    f01011ca <.L34+0x19>

f0101240 <.L35>:
			putch('0', putdat);
f0101240:	83 ec 08             	sub    $0x8,%esp
f0101243:	56                   	push   %esi
f0101244:	6a 30                	push   $0x30
f0101246:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0101249:	83 c4 08             	add    $0x8,%esp
f010124c:	56                   	push   %esi
f010124d:	6a 78                	push   $0x78
f010124f:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f0101252:	8b 45 14             	mov    0x14(%ebp),%eax
f0101255:	8b 10                	mov    (%eax),%edx
f0101257:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f010125c:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f010125f:	8d 40 04             	lea    0x4(%eax),%eax
f0101262:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101265:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f010126a:	e9 64 ff ff ff       	jmp    f01011d3 <.L34+0x22>

f010126f <.L38>:
f010126f:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0101272:	83 f9 01             	cmp    $0x1,%ecx
f0101275:	7e 18                	jle    f010128f <.L38+0x20>
		return va_arg(*ap, unsigned long long);
f0101277:	8b 45 14             	mov    0x14(%ebp),%eax
f010127a:	8b 10                	mov    (%eax),%edx
f010127c:	8b 48 04             	mov    0x4(%eax),%ecx
f010127f:	8d 40 08             	lea    0x8(%eax),%eax
f0101282:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101285:	b8 10 00 00 00       	mov    $0x10,%eax
f010128a:	e9 44 ff ff ff       	jmp    f01011d3 <.L34+0x22>
	else if (lflag)
f010128f:	85 c9                	test   %ecx,%ecx
f0101291:	75 1a                	jne    f01012ad <.L38+0x3e>
		return va_arg(*ap, unsigned int);
f0101293:	8b 45 14             	mov    0x14(%ebp),%eax
f0101296:	8b 10                	mov    (%eax),%edx
f0101298:	b9 00 00 00 00       	mov    $0x0,%ecx
f010129d:	8d 40 04             	lea    0x4(%eax),%eax
f01012a0:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01012a3:	b8 10 00 00 00       	mov    $0x10,%eax
f01012a8:	e9 26 ff ff ff       	jmp    f01011d3 <.L34+0x22>
		return va_arg(*ap, unsigned long);
f01012ad:	8b 45 14             	mov    0x14(%ebp),%eax
f01012b0:	8b 10                	mov    (%eax),%edx
f01012b2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01012b7:	8d 40 04             	lea    0x4(%eax),%eax
f01012ba:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01012bd:	b8 10 00 00 00       	mov    $0x10,%eax
f01012c2:	e9 0c ff ff ff       	jmp    f01011d3 <.L34+0x22>

f01012c7 <.L25>:
			putch(ch, putdat);
f01012c7:	83 ec 08             	sub    $0x8,%esp
f01012ca:	56                   	push   %esi
f01012cb:	6a 25                	push   $0x25
f01012cd:	ff 55 08             	call   *0x8(%ebp)
			break;
f01012d0:	83 c4 10             	add    $0x10,%esp
f01012d3:	e9 16 ff ff ff       	jmp    f01011ee <.L34+0x3d>

f01012d8 <.L22>:
			putch('%', putdat);
f01012d8:	83 ec 08             	sub    $0x8,%esp
f01012db:	56                   	push   %esi
f01012dc:	6a 25                	push   $0x25
f01012de:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01012e1:	83 c4 10             	add    $0x10,%esp
f01012e4:	89 f8                	mov    %edi,%eax
f01012e6:	eb 03                	jmp    f01012eb <.L22+0x13>
f01012e8:	83 e8 01             	sub    $0x1,%eax
f01012eb:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f01012ef:	75 f7                	jne    f01012e8 <.L22+0x10>
f01012f1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01012f4:	e9 f5 fe ff ff       	jmp    f01011ee <.L34+0x3d>
}
f01012f9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01012fc:	5b                   	pop    %ebx
f01012fd:	5e                   	pop    %esi
f01012fe:	5f                   	pop    %edi
f01012ff:	5d                   	pop    %ebp
f0101300:	c3                   	ret    

f0101301 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101301:	55                   	push   %ebp
f0101302:	89 e5                	mov    %esp,%ebp
f0101304:	53                   	push   %ebx
f0101305:	83 ec 14             	sub    $0x14,%esp
f0101308:	e8 c1 ee ff ff       	call   f01001ce <__x86.get_pc_thunk.bx>
f010130d:	81 c3 fb ff 00 00    	add    $0xfffb,%ebx
f0101313:	8b 45 08             	mov    0x8(%ebp),%eax
f0101316:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101319:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010131c:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101320:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101323:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010132a:	85 c0                	test   %eax,%eax
f010132c:	74 2b                	je     f0101359 <vsnprintf+0x58>
f010132e:	85 d2                	test   %edx,%edx
f0101330:	7e 27                	jle    f0101359 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101332:	ff 75 14             	pushl  0x14(%ebp)
f0101335:	ff 75 10             	pushl  0x10(%ebp)
f0101338:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010133b:	50                   	push   %eax
f010133c:	8d 83 2d fb fe ff    	lea    -0x104d3(%ebx),%eax
f0101342:	50                   	push   %eax
f0101343:	e8 27 fb ff ff       	call   f0100e6f <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101348:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010134b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010134e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101351:	83 c4 10             	add    $0x10,%esp
}
f0101354:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101357:	c9                   	leave  
f0101358:	c3                   	ret    
		return -E_INVAL;
f0101359:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010135e:	eb f4                	jmp    f0101354 <vsnprintf+0x53>

f0101360 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101360:	55                   	push   %ebp
f0101361:	89 e5                	mov    %esp,%ebp
f0101363:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101366:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101369:	50                   	push   %eax
f010136a:	ff 75 10             	pushl  0x10(%ebp)
f010136d:	ff 75 0c             	pushl  0xc(%ebp)
f0101370:	ff 75 08             	pushl  0x8(%ebp)
f0101373:	e8 89 ff ff ff       	call   f0101301 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101378:	c9                   	leave  
f0101379:	c3                   	ret    

f010137a <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010137a:	55                   	push   %ebp
f010137b:	89 e5                	mov    %esp,%ebp
f010137d:	57                   	push   %edi
f010137e:	56                   	push   %esi
f010137f:	53                   	push   %ebx
f0101380:	83 ec 1c             	sub    $0x1c,%esp
f0101383:	e8 46 ee ff ff       	call   f01001ce <__x86.get_pc_thunk.bx>
f0101388:	81 c3 80 ff 00 00    	add    $0xff80,%ebx
f010138e:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101391:	85 c0                	test   %eax,%eax
f0101393:	74 13                	je     f01013a8 <readline+0x2e>
		cprintf("%s", prompt);
f0101395:	83 ec 08             	sub    $0x8,%esp
f0101398:	50                   	push   %eax
f0101399:	8d 83 22 0c ff ff    	lea    -0xf3de(%ebx),%eax
f010139f:	50                   	push   %eax
f01013a0:	e8 b6 f6 ff ff       	call   f0100a5b <cprintf>
f01013a5:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01013a8:	83 ec 0c             	sub    $0xc,%esp
f01013ab:	6a 00                	push   $0x0
f01013ad:	e8 b4 f3 ff ff       	call   f0100766 <iscons>
f01013b2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01013b5:	83 c4 10             	add    $0x10,%esp
	i = 0;
f01013b8:	bf 00 00 00 00       	mov    $0x0,%edi
f01013bd:	eb 46                	jmp    f0101405 <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f01013bf:	83 ec 08             	sub    $0x8,%esp
f01013c2:	50                   	push   %eax
f01013c3:	8d 83 e8 0d ff ff    	lea    -0xf218(%ebx),%eax
f01013c9:	50                   	push   %eax
f01013ca:	e8 8c f6 ff ff       	call   f0100a5b <cprintf>
			return NULL;
f01013cf:	83 c4 10             	add    $0x10,%esp
f01013d2:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f01013d7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01013da:	5b                   	pop    %ebx
f01013db:	5e                   	pop    %esi
f01013dc:	5f                   	pop    %edi
f01013dd:	5d                   	pop    %ebp
f01013de:	c3                   	ret    
			if (echoing)
f01013df:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01013e3:	75 05                	jne    f01013ea <readline+0x70>
			i--;
f01013e5:	83 ef 01             	sub    $0x1,%edi
f01013e8:	eb 1b                	jmp    f0101405 <readline+0x8b>
				cputchar('\b');
f01013ea:	83 ec 0c             	sub    $0xc,%esp
f01013ed:	6a 08                	push   $0x8
f01013ef:	e8 51 f3 ff ff       	call   f0100745 <cputchar>
f01013f4:	83 c4 10             	add    $0x10,%esp
f01013f7:	eb ec                	jmp    f01013e5 <readline+0x6b>
			buf[i++] = c;
f01013f9:	89 f0                	mov    %esi,%eax
f01013fb:	88 84 3b 98 1f 00 00 	mov    %al,0x1f98(%ebx,%edi,1)
f0101402:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0101405:	e8 4b f3 ff ff       	call   f0100755 <getchar>
f010140a:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f010140c:	85 c0                	test   %eax,%eax
f010140e:	78 af                	js     f01013bf <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101410:	83 f8 08             	cmp    $0x8,%eax
f0101413:	0f 94 c2             	sete   %dl
f0101416:	83 f8 7f             	cmp    $0x7f,%eax
f0101419:	0f 94 c0             	sete   %al
f010141c:	08 c2                	or     %al,%dl
f010141e:	74 04                	je     f0101424 <readline+0xaa>
f0101420:	85 ff                	test   %edi,%edi
f0101422:	7f bb                	jg     f01013df <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101424:	83 fe 1f             	cmp    $0x1f,%esi
f0101427:	7e 1c                	jle    f0101445 <readline+0xcb>
f0101429:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f010142f:	7f 14                	jg     f0101445 <readline+0xcb>
			if (echoing)
f0101431:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101435:	74 c2                	je     f01013f9 <readline+0x7f>
				cputchar(c);
f0101437:	83 ec 0c             	sub    $0xc,%esp
f010143a:	56                   	push   %esi
f010143b:	e8 05 f3 ff ff       	call   f0100745 <cputchar>
f0101440:	83 c4 10             	add    $0x10,%esp
f0101443:	eb b4                	jmp    f01013f9 <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f0101445:	83 fe 0a             	cmp    $0xa,%esi
f0101448:	74 05                	je     f010144f <readline+0xd5>
f010144a:	83 fe 0d             	cmp    $0xd,%esi
f010144d:	75 b6                	jne    f0101405 <readline+0x8b>
			if (echoing)
f010144f:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101453:	75 13                	jne    f0101468 <readline+0xee>
			buf[i] = 0;
f0101455:	c6 84 3b 98 1f 00 00 	movb   $0x0,0x1f98(%ebx,%edi,1)
f010145c:	00 
			return buf;
f010145d:	8d 83 98 1f 00 00    	lea    0x1f98(%ebx),%eax
f0101463:	e9 6f ff ff ff       	jmp    f01013d7 <readline+0x5d>
				cputchar('\n');
f0101468:	83 ec 0c             	sub    $0xc,%esp
f010146b:	6a 0a                	push   $0xa
f010146d:	e8 d3 f2 ff ff       	call   f0100745 <cputchar>
f0101472:	83 c4 10             	add    $0x10,%esp
f0101475:	eb de                	jmp    f0101455 <readline+0xdb>

f0101477 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101477:	55                   	push   %ebp
f0101478:	89 e5                	mov    %esp,%ebp
f010147a:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010147d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101482:	eb 03                	jmp    f0101487 <strlen+0x10>
		n++;
f0101484:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0101487:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010148b:	75 f7                	jne    f0101484 <strlen+0xd>
	return n;
}
f010148d:	5d                   	pop    %ebp
f010148e:	c3                   	ret    

f010148f <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010148f:	55                   	push   %ebp
f0101490:	89 e5                	mov    %esp,%ebp
f0101492:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101495:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101498:	b8 00 00 00 00       	mov    $0x0,%eax
f010149d:	eb 03                	jmp    f01014a2 <strnlen+0x13>
		n++;
f010149f:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01014a2:	39 d0                	cmp    %edx,%eax
f01014a4:	74 06                	je     f01014ac <strnlen+0x1d>
f01014a6:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01014aa:	75 f3                	jne    f010149f <strnlen+0x10>
	return n;
}
f01014ac:	5d                   	pop    %ebp
f01014ad:	c3                   	ret    

f01014ae <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01014ae:	55                   	push   %ebp
f01014af:	89 e5                	mov    %esp,%ebp
f01014b1:	53                   	push   %ebx
f01014b2:	8b 45 08             	mov    0x8(%ebp),%eax
f01014b5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01014b8:	89 c2                	mov    %eax,%edx
f01014ba:	83 c1 01             	add    $0x1,%ecx
f01014bd:	83 c2 01             	add    $0x1,%edx
f01014c0:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01014c4:	88 5a ff             	mov    %bl,-0x1(%edx)
f01014c7:	84 db                	test   %bl,%bl
f01014c9:	75 ef                	jne    f01014ba <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01014cb:	5b                   	pop    %ebx
f01014cc:	5d                   	pop    %ebp
f01014cd:	c3                   	ret    

f01014ce <strcat>:

char *
strcat(char *dst, const char *src)
{
f01014ce:	55                   	push   %ebp
f01014cf:	89 e5                	mov    %esp,%ebp
f01014d1:	53                   	push   %ebx
f01014d2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01014d5:	53                   	push   %ebx
f01014d6:	e8 9c ff ff ff       	call   f0101477 <strlen>
f01014db:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01014de:	ff 75 0c             	pushl  0xc(%ebp)
f01014e1:	01 d8                	add    %ebx,%eax
f01014e3:	50                   	push   %eax
f01014e4:	e8 c5 ff ff ff       	call   f01014ae <strcpy>
	return dst;
}
f01014e9:	89 d8                	mov    %ebx,%eax
f01014eb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01014ee:	c9                   	leave  
f01014ef:	c3                   	ret    

f01014f0 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01014f0:	55                   	push   %ebp
f01014f1:	89 e5                	mov    %esp,%ebp
f01014f3:	56                   	push   %esi
f01014f4:	53                   	push   %ebx
f01014f5:	8b 75 08             	mov    0x8(%ebp),%esi
f01014f8:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01014fb:	89 f3                	mov    %esi,%ebx
f01014fd:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101500:	89 f2                	mov    %esi,%edx
f0101502:	eb 0f                	jmp    f0101513 <strncpy+0x23>
		*dst++ = *src;
f0101504:	83 c2 01             	add    $0x1,%edx
f0101507:	0f b6 01             	movzbl (%ecx),%eax
f010150a:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010150d:	80 39 01             	cmpb   $0x1,(%ecx)
f0101510:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0101513:	39 da                	cmp    %ebx,%edx
f0101515:	75 ed                	jne    f0101504 <strncpy+0x14>
	}
	return ret;
}
f0101517:	89 f0                	mov    %esi,%eax
f0101519:	5b                   	pop    %ebx
f010151a:	5e                   	pop    %esi
f010151b:	5d                   	pop    %ebp
f010151c:	c3                   	ret    

f010151d <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010151d:	55                   	push   %ebp
f010151e:	89 e5                	mov    %esp,%ebp
f0101520:	56                   	push   %esi
f0101521:	53                   	push   %ebx
f0101522:	8b 75 08             	mov    0x8(%ebp),%esi
f0101525:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101528:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010152b:	89 f0                	mov    %esi,%eax
f010152d:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101531:	85 c9                	test   %ecx,%ecx
f0101533:	75 0b                	jne    f0101540 <strlcpy+0x23>
f0101535:	eb 17                	jmp    f010154e <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101537:	83 c2 01             	add    $0x1,%edx
f010153a:	83 c0 01             	add    $0x1,%eax
f010153d:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0101540:	39 d8                	cmp    %ebx,%eax
f0101542:	74 07                	je     f010154b <strlcpy+0x2e>
f0101544:	0f b6 0a             	movzbl (%edx),%ecx
f0101547:	84 c9                	test   %cl,%cl
f0101549:	75 ec                	jne    f0101537 <strlcpy+0x1a>
		*dst = '\0';
f010154b:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010154e:	29 f0                	sub    %esi,%eax
}
f0101550:	5b                   	pop    %ebx
f0101551:	5e                   	pop    %esi
f0101552:	5d                   	pop    %ebp
f0101553:	c3                   	ret    

f0101554 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101554:	55                   	push   %ebp
f0101555:	89 e5                	mov    %esp,%ebp
f0101557:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010155a:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010155d:	eb 06                	jmp    f0101565 <strcmp+0x11>
		p++, q++;
f010155f:	83 c1 01             	add    $0x1,%ecx
f0101562:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0101565:	0f b6 01             	movzbl (%ecx),%eax
f0101568:	84 c0                	test   %al,%al
f010156a:	74 04                	je     f0101570 <strcmp+0x1c>
f010156c:	3a 02                	cmp    (%edx),%al
f010156e:	74 ef                	je     f010155f <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101570:	0f b6 c0             	movzbl %al,%eax
f0101573:	0f b6 12             	movzbl (%edx),%edx
f0101576:	29 d0                	sub    %edx,%eax
}
f0101578:	5d                   	pop    %ebp
f0101579:	c3                   	ret    

f010157a <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010157a:	55                   	push   %ebp
f010157b:	89 e5                	mov    %esp,%ebp
f010157d:	53                   	push   %ebx
f010157e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101581:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101584:	89 c3                	mov    %eax,%ebx
f0101586:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0101589:	eb 06                	jmp    f0101591 <strncmp+0x17>
		n--, p++, q++;
f010158b:	83 c0 01             	add    $0x1,%eax
f010158e:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0101591:	39 d8                	cmp    %ebx,%eax
f0101593:	74 16                	je     f01015ab <strncmp+0x31>
f0101595:	0f b6 08             	movzbl (%eax),%ecx
f0101598:	84 c9                	test   %cl,%cl
f010159a:	74 04                	je     f01015a0 <strncmp+0x26>
f010159c:	3a 0a                	cmp    (%edx),%cl
f010159e:	74 eb                	je     f010158b <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01015a0:	0f b6 00             	movzbl (%eax),%eax
f01015a3:	0f b6 12             	movzbl (%edx),%edx
f01015a6:	29 d0                	sub    %edx,%eax
}
f01015a8:	5b                   	pop    %ebx
f01015a9:	5d                   	pop    %ebp
f01015aa:	c3                   	ret    
		return 0;
f01015ab:	b8 00 00 00 00       	mov    $0x0,%eax
f01015b0:	eb f6                	jmp    f01015a8 <strncmp+0x2e>

f01015b2 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01015b2:	55                   	push   %ebp
f01015b3:	89 e5                	mov    %esp,%ebp
f01015b5:	8b 45 08             	mov    0x8(%ebp),%eax
f01015b8:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01015bc:	0f b6 10             	movzbl (%eax),%edx
f01015bf:	84 d2                	test   %dl,%dl
f01015c1:	74 09                	je     f01015cc <strchr+0x1a>
		if (*s == c)
f01015c3:	38 ca                	cmp    %cl,%dl
f01015c5:	74 0a                	je     f01015d1 <strchr+0x1f>
	for (; *s; s++)
f01015c7:	83 c0 01             	add    $0x1,%eax
f01015ca:	eb f0                	jmp    f01015bc <strchr+0xa>
			return (char *) s;
	return 0;
f01015cc:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01015d1:	5d                   	pop    %ebp
f01015d2:	c3                   	ret    

f01015d3 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01015d3:	55                   	push   %ebp
f01015d4:	89 e5                	mov    %esp,%ebp
f01015d6:	8b 45 08             	mov    0x8(%ebp),%eax
f01015d9:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01015dd:	eb 03                	jmp    f01015e2 <strfind+0xf>
f01015df:	83 c0 01             	add    $0x1,%eax
f01015e2:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01015e5:	38 ca                	cmp    %cl,%dl
f01015e7:	74 04                	je     f01015ed <strfind+0x1a>
f01015e9:	84 d2                	test   %dl,%dl
f01015eb:	75 f2                	jne    f01015df <strfind+0xc>
			break;
	return (char *) s;
}
f01015ed:	5d                   	pop    %ebp
f01015ee:	c3                   	ret    

f01015ef <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01015ef:	55                   	push   %ebp
f01015f0:	89 e5                	mov    %esp,%ebp
f01015f2:	57                   	push   %edi
f01015f3:	56                   	push   %esi
f01015f4:	53                   	push   %ebx
f01015f5:	8b 7d 08             	mov    0x8(%ebp),%edi
f01015f8:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01015fb:	85 c9                	test   %ecx,%ecx
f01015fd:	74 13                	je     f0101612 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01015ff:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101605:	75 05                	jne    f010160c <memset+0x1d>
f0101607:	f6 c1 03             	test   $0x3,%cl
f010160a:	74 0d                	je     f0101619 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010160c:	8b 45 0c             	mov    0xc(%ebp),%eax
f010160f:	fc                   	cld    
f0101610:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101612:	89 f8                	mov    %edi,%eax
f0101614:	5b                   	pop    %ebx
f0101615:	5e                   	pop    %esi
f0101616:	5f                   	pop    %edi
f0101617:	5d                   	pop    %ebp
f0101618:	c3                   	ret    
		c &= 0xFF;
f0101619:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010161d:	89 d3                	mov    %edx,%ebx
f010161f:	c1 e3 08             	shl    $0x8,%ebx
f0101622:	89 d0                	mov    %edx,%eax
f0101624:	c1 e0 18             	shl    $0x18,%eax
f0101627:	89 d6                	mov    %edx,%esi
f0101629:	c1 e6 10             	shl    $0x10,%esi
f010162c:	09 f0                	or     %esi,%eax
f010162e:	09 c2                	or     %eax,%edx
f0101630:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0101632:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0101635:	89 d0                	mov    %edx,%eax
f0101637:	fc                   	cld    
f0101638:	f3 ab                	rep stos %eax,%es:(%edi)
f010163a:	eb d6                	jmp    f0101612 <memset+0x23>

f010163c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010163c:	55                   	push   %ebp
f010163d:	89 e5                	mov    %esp,%ebp
f010163f:	57                   	push   %edi
f0101640:	56                   	push   %esi
f0101641:	8b 45 08             	mov    0x8(%ebp),%eax
f0101644:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101647:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010164a:	39 c6                	cmp    %eax,%esi
f010164c:	73 35                	jae    f0101683 <memmove+0x47>
f010164e:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101651:	39 c2                	cmp    %eax,%edx
f0101653:	76 2e                	jbe    f0101683 <memmove+0x47>
		s += n;
		d += n;
f0101655:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101658:	89 d6                	mov    %edx,%esi
f010165a:	09 fe                	or     %edi,%esi
f010165c:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101662:	74 0c                	je     f0101670 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101664:	83 ef 01             	sub    $0x1,%edi
f0101667:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f010166a:	fd                   	std    
f010166b:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010166d:	fc                   	cld    
f010166e:	eb 21                	jmp    f0101691 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101670:	f6 c1 03             	test   $0x3,%cl
f0101673:	75 ef                	jne    f0101664 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101675:	83 ef 04             	sub    $0x4,%edi
f0101678:	8d 72 fc             	lea    -0x4(%edx),%esi
f010167b:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f010167e:	fd                   	std    
f010167f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101681:	eb ea                	jmp    f010166d <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101683:	89 f2                	mov    %esi,%edx
f0101685:	09 c2                	or     %eax,%edx
f0101687:	f6 c2 03             	test   $0x3,%dl
f010168a:	74 09                	je     f0101695 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010168c:	89 c7                	mov    %eax,%edi
f010168e:	fc                   	cld    
f010168f:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101691:	5e                   	pop    %esi
f0101692:	5f                   	pop    %edi
f0101693:	5d                   	pop    %ebp
f0101694:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101695:	f6 c1 03             	test   $0x3,%cl
f0101698:	75 f2                	jne    f010168c <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010169a:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f010169d:	89 c7                	mov    %eax,%edi
f010169f:	fc                   	cld    
f01016a0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01016a2:	eb ed                	jmp    f0101691 <memmove+0x55>

f01016a4 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01016a4:	55                   	push   %ebp
f01016a5:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01016a7:	ff 75 10             	pushl  0x10(%ebp)
f01016aa:	ff 75 0c             	pushl  0xc(%ebp)
f01016ad:	ff 75 08             	pushl  0x8(%ebp)
f01016b0:	e8 87 ff ff ff       	call   f010163c <memmove>
}
f01016b5:	c9                   	leave  
f01016b6:	c3                   	ret    

f01016b7 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01016b7:	55                   	push   %ebp
f01016b8:	89 e5                	mov    %esp,%ebp
f01016ba:	56                   	push   %esi
f01016bb:	53                   	push   %ebx
f01016bc:	8b 45 08             	mov    0x8(%ebp),%eax
f01016bf:	8b 55 0c             	mov    0xc(%ebp),%edx
f01016c2:	89 c6                	mov    %eax,%esi
f01016c4:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016c7:	39 f0                	cmp    %esi,%eax
f01016c9:	74 1c                	je     f01016e7 <memcmp+0x30>
		if (*s1 != *s2)
f01016cb:	0f b6 08             	movzbl (%eax),%ecx
f01016ce:	0f b6 1a             	movzbl (%edx),%ebx
f01016d1:	38 d9                	cmp    %bl,%cl
f01016d3:	75 08                	jne    f01016dd <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f01016d5:	83 c0 01             	add    $0x1,%eax
f01016d8:	83 c2 01             	add    $0x1,%edx
f01016db:	eb ea                	jmp    f01016c7 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f01016dd:	0f b6 c1             	movzbl %cl,%eax
f01016e0:	0f b6 db             	movzbl %bl,%ebx
f01016e3:	29 d8                	sub    %ebx,%eax
f01016e5:	eb 05                	jmp    f01016ec <memcmp+0x35>
	}

	return 0;
f01016e7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01016ec:	5b                   	pop    %ebx
f01016ed:	5e                   	pop    %esi
f01016ee:	5d                   	pop    %ebp
f01016ef:	c3                   	ret    

f01016f0 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01016f0:	55                   	push   %ebp
f01016f1:	89 e5                	mov    %esp,%ebp
f01016f3:	8b 45 08             	mov    0x8(%ebp),%eax
f01016f6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01016f9:	89 c2                	mov    %eax,%edx
f01016fb:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01016fe:	39 d0                	cmp    %edx,%eax
f0101700:	73 09                	jae    f010170b <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101702:	38 08                	cmp    %cl,(%eax)
f0101704:	74 05                	je     f010170b <memfind+0x1b>
	for (; s < ends; s++)
f0101706:	83 c0 01             	add    $0x1,%eax
f0101709:	eb f3                	jmp    f01016fe <memfind+0xe>
			break;
	return (void *) s;
}
f010170b:	5d                   	pop    %ebp
f010170c:	c3                   	ret    

f010170d <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010170d:	55                   	push   %ebp
f010170e:	89 e5                	mov    %esp,%ebp
f0101710:	57                   	push   %edi
f0101711:	56                   	push   %esi
f0101712:	53                   	push   %ebx
f0101713:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101716:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101719:	eb 03                	jmp    f010171e <strtol+0x11>
		s++;
f010171b:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f010171e:	0f b6 01             	movzbl (%ecx),%eax
f0101721:	3c 20                	cmp    $0x20,%al
f0101723:	74 f6                	je     f010171b <strtol+0xe>
f0101725:	3c 09                	cmp    $0x9,%al
f0101727:	74 f2                	je     f010171b <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0101729:	3c 2b                	cmp    $0x2b,%al
f010172b:	74 2e                	je     f010175b <strtol+0x4e>
	int neg = 0;
f010172d:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0101732:	3c 2d                	cmp    $0x2d,%al
f0101734:	74 2f                	je     f0101765 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101736:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010173c:	75 05                	jne    f0101743 <strtol+0x36>
f010173e:	80 39 30             	cmpb   $0x30,(%ecx)
f0101741:	74 2c                	je     f010176f <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101743:	85 db                	test   %ebx,%ebx
f0101745:	75 0a                	jne    f0101751 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101747:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f010174c:	80 39 30             	cmpb   $0x30,(%ecx)
f010174f:	74 28                	je     f0101779 <strtol+0x6c>
		base = 10;
f0101751:	b8 00 00 00 00       	mov    $0x0,%eax
f0101756:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101759:	eb 50                	jmp    f01017ab <strtol+0x9e>
		s++;
f010175b:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f010175e:	bf 00 00 00 00       	mov    $0x0,%edi
f0101763:	eb d1                	jmp    f0101736 <strtol+0x29>
		s++, neg = 1;
f0101765:	83 c1 01             	add    $0x1,%ecx
f0101768:	bf 01 00 00 00       	mov    $0x1,%edi
f010176d:	eb c7                	jmp    f0101736 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010176f:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101773:	74 0e                	je     f0101783 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0101775:	85 db                	test   %ebx,%ebx
f0101777:	75 d8                	jne    f0101751 <strtol+0x44>
		s++, base = 8;
f0101779:	83 c1 01             	add    $0x1,%ecx
f010177c:	bb 08 00 00 00       	mov    $0x8,%ebx
f0101781:	eb ce                	jmp    f0101751 <strtol+0x44>
		s += 2, base = 16;
f0101783:	83 c1 02             	add    $0x2,%ecx
f0101786:	bb 10 00 00 00       	mov    $0x10,%ebx
f010178b:	eb c4                	jmp    f0101751 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f010178d:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101790:	89 f3                	mov    %esi,%ebx
f0101792:	80 fb 19             	cmp    $0x19,%bl
f0101795:	77 29                	ja     f01017c0 <strtol+0xb3>
			dig = *s - 'a' + 10;
f0101797:	0f be d2             	movsbl %dl,%edx
f010179a:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f010179d:	3b 55 10             	cmp    0x10(%ebp),%edx
f01017a0:	7d 30                	jge    f01017d2 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f01017a2:	83 c1 01             	add    $0x1,%ecx
f01017a5:	0f af 45 10          	imul   0x10(%ebp),%eax
f01017a9:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f01017ab:	0f b6 11             	movzbl (%ecx),%edx
f01017ae:	8d 72 d0             	lea    -0x30(%edx),%esi
f01017b1:	89 f3                	mov    %esi,%ebx
f01017b3:	80 fb 09             	cmp    $0x9,%bl
f01017b6:	77 d5                	ja     f010178d <strtol+0x80>
			dig = *s - '0';
f01017b8:	0f be d2             	movsbl %dl,%edx
f01017bb:	83 ea 30             	sub    $0x30,%edx
f01017be:	eb dd                	jmp    f010179d <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f01017c0:	8d 72 bf             	lea    -0x41(%edx),%esi
f01017c3:	89 f3                	mov    %esi,%ebx
f01017c5:	80 fb 19             	cmp    $0x19,%bl
f01017c8:	77 08                	ja     f01017d2 <strtol+0xc5>
			dig = *s - 'A' + 10;
f01017ca:	0f be d2             	movsbl %dl,%edx
f01017cd:	83 ea 37             	sub    $0x37,%edx
f01017d0:	eb cb                	jmp    f010179d <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f01017d2:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01017d6:	74 05                	je     f01017dd <strtol+0xd0>
		*endptr = (char *) s;
f01017d8:	8b 75 0c             	mov    0xc(%ebp),%esi
f01017db:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f01017dd:	89 c2                	mov    %eax,%edx
f01017df:	f7 da                	neg    %edx
f01017e1:	85 ff                	test   %edi,%edi
f01017e3:	0f 45 c2             	cmovne %edx,%eax
}
f01017e6:	5b                   	pop    %ebx
f01017e7:	5e                   	pop    %esi
f01017e8:	5f                   	pop    %edi
f01017e9:	5d                   	pop    %ebp
f01017ea:	c3                   	ret    
f01017eb:	66 90                	xchg   %ax,%ax
f01017ed:	66 90                	xchg   %ax,%ax
f01017ef:	90                   	nop

f01017f0 <__udivdi3>:
f01017f0:	55                   	push   %ebp
f01017f1:	57                   	push   %edi
f01017f2:	56                   	push   %esi
f01017f3:	53                   	push   %ebx
f01017f4:	83 ec 1c             	sub    $0x1c,%esp
f01017f7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01017fb:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f01017ff:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101803:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0101807:	85 d2                	test   %edx,%edx
f0101809:	75 35                	jne    f0101840 <__udivdi3+0x50>
f010180b:	39 f3                	cmp    %esi,%ebx
f010180d:	0f 87 bd 00 00 00    	ja     f01018d0 <__udivdi3+0xe0>
f0101813:	85 db                	test   %ebx,%ebx
f0101815:	89 d9                	mov    %ebx,%ecx
f0101817:	75 0b                	jne    f0101824 <__udivdi3+0x34>
f0101819:	b8 01 00 00 00       	mov    $0x1,%eax
f010181e:	31 d2                	xor    %edx,%edx
f0101820:	f7 f3                	div    %ebx
f0101822:	89 c1                	mov    %eax,%ecx
f0101824:	31 d2                	xor    %edx,%edx
f0101826:	89 f0                	mov    %esi,%eax
f0101828:	f7 f1                	div    %ecx
f010182a:	89 c6                	mov    %eax,%esi
f010182c:	89 e8                	mov    %ebp,%eax
f010182e:	89 f7                	mov    %esi,%edi
f0101830:	f7 f1                	div    %ecx
f0101832:	89 fa                	mov    %edi,%edx
f0101834:	83 c4 1c             	add    $0x1c,%esp
f0101837:	5b                   	pop    %ebx
f0101838:	5e                   	pop    %esi
f0101839:	5f                   	pop    %edi
f010183a:	5d                   	pop    %ebp
f010183b:	c3                   	ret    
f010183c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101840:	39 f2                	cmp    %esi,%edx
f0101842:	77 7c                	ja     f01018c0 <__udivdi3+0xd0>
f0101844:	0f bd fa             	bsr    %edx,%edi
f0101847:	83 f7 1f             	xor    $0x1f,%edi
f010184a:	0f 84 98 00 00 00    	je     f01018e8 <__udivdi3+0xf8>
f0101850:	89 f9                	mov    %edi,%ecx
f0101852:	b8 20 00 00 00       	mov    $0x20,%eax
f0101857:	29 f8                	sub    %edi,%eax
f0101859:	d3 e2                	shl    %cl,%edx
f010185b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010185f:	89 c1                	mov    %eax,%ecx
f0101861:	89 da                	mov    %ebx,%edx
f0101863:	d3 ea                	shr    %cl,%edx
f0101865:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101869:	09 d1                	or     %edx,%ecx
f010186b:	89 f2                	mov    %esi,%edx
f010186d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101871:	89 f9                	mov    %edi,%ecx
f0101873:	d3 e3                	shl    %cl,%ebx
f0101875:	89 c1                	mov    %eax,%ecx
f0101877:	d3 ea                	shr    %cl,%edx
f0101879:	89 f9                	mov    %edi,%ecx
f010187b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010187f:	d3 e6                	shl    %cl,%esi
f0101881:	89 eb                	mov    %ebp,%ebx
f0101883:	89 c1                	mov    %eax,%ecx
f0101885:	d3 eb                	shr    %cl,%ebx
f0101887:	09 de                	or     %ebx,%esi
f0101889:	89 f0                	mov    %esi,%eax
f010188b:	f7 74 24 08          	divl   0x8(%esp)
f010188f:	89 d6                	mov    %edx,%esi
f0101891:	89 c3                	mov    %eax,%ebx
f0101893:	f7 64 24 0c          	mull   0xc(%esp)
f0101897:	39 d6                	cmp    %edx,%esi
f0101899:	72 0c                	jb     f01018a7 <__udivdi3+0xb7>
f010189b:	89 f9                	mov    %edi,%ecx
f010189d:	d3 e5                	shl    %cl,%ebp
f010189f:	39 c5                	cmp    %eax,%ebp
f01018a1:	73 5d                	jae    f0101900 <__udivdi3+0x110>
f01018a3:	39 d6                	cmp    %edx,%esi
f01018a5:	75 59                	jne    f0101900 <__udivdi3+0x110>
f01018a7:	8d 43 ff             	lea    -0x1(%ebx),%eax
f01018aa:	31 ff                	xor    %edi,%edi
f01018ac:	89 fa                	mov    %edi,%edx
f01018ae:	83 c4 1c             	add    $0x1c,%esp
f01018b1:	5b                   	pop    %ebx
f01018b2:	5e                   	pop    %esi
f01018b3:	5f                   	pop    %edi
f01018b4:	5d                   	pop    %ebp
f01018b5:	c3                   	ret    
f01018b6:	8d 76 00             	lea    0x0(%esi),%esi
f01018b9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f01018c0:	31 ff                	xor    %edi,%edi
f01018c2:	31 c0                	xor    %eax,%eax
f01018c4:	89 fa                	mov    %edi,%edx
f01018c6:	83 c4 1c             	add    $0x1c,%esp
f01018c9:	5b                   	pop    %ebx
f01018ca:	5e                   	pop    %esi
f01018cb:	5f                   	pop    %edi
f01018cc:	5d                   	pop    %ebp
f01018cd:	c3                   	ret    
f01018ce:	66 90                	xchg   %ax,%ax
f01018d0:	31 ff                	xor    %edi,%edi
f01018d2:	89 e8                	mov    %ebp,%eax
f01018d4:	89 f2                	mov    %esi,%edx
f01018d6:	f7 f3                	div    %ebx
f01018d8:	89 fa                	mov    %edi,%edx
f01018da:	83 c4 1c             	add    $0x1c,%esp
f01018dd:	5b                   	pop    %ebx
f01018de:	5e                   	pop    %esi
f01018df:	5f                   	pop    %edi
f01018e0:	5d                   	pop    %ebp
f01018e1:	c3                   	ret    
f01018e2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01018e8:	39 f2                	cmp    %esi,%edx
f01018ea:	72 06                	jb     f01018f2 <__udivdi3+0x102>
f01018ec:	31 c0                	xor    %eax,%eax
f01018ee:	39 eb                	cmp    %ebp,%ebx
f01018f0:	77 d2                	ja     f01018c4 <__udivdi3+0xd4>
f01018f2:	b8 01 00 00 00       	mov    $0x1,%eax
f01018f7:	eb cb                	jmp    f01018c4 <__udivdi3+0xd4>
f01018f9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101900:	89 d8                	mov    %ebx,%eax
f0101902:	31 ff                	xor    %edi,%edi
f0101904:	eb be                	jmp    f01018c4 <__udivdi3+0xd4>
f0101906:	66 90                	xchg   %ax,%ax
f0101908:	66 90                	xchg   %ax,%ax
f010190a:	66 90                	xchg   %ax,%ax
f010190c:	66 90                	xchg   %ax,%ax
f010190e:	66 90                	xchg   %ax,%ax

f0101910 <__umoddi3>:
f0101910:	55                   	push   %ebp
f0101911:	57                   	push   %edi
f0101912:	56                   	push   %esi
f0101913:	53                   	push   %ebx
f0101914:	83 ec 1c             	sub    $0x1c,%esp
f0101917:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f010191b:	8b 74 24 30          	mov    0x30(%esp),%esi
f010191f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0101923:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101927:	85 ed                	test   %ebp,%ebp
f0101929:	89 f0                	mov    %esi,%eax
f010192b:	89 da                	mov    %ebx,%edx
f010192d:	75 19                	jne    f0101948 <__umoddi3+0x38>
f010192f:	39 df                	cmp    %ebx,%edi
f0101931:	0f 86 b1 00 00 00    	jbe    f01019e8 <__umoddi3+0xd8>
f0101937:	f7 f7                	div    %edi
f0101939:	89 d0                	mov    %edx,%eax
f010193b:	31 d2                	xor    %edx,%edx
f010193d:	83 c4 1c             	add    $0x1c,%esp
f0101940:	5b                   	pop    %ebx
f0101941:	5e                   	pop    %esi
f0101942:	5f                   	pop    %edi
f0101943:	5d                   	pop    %ebp
f0101944:	c3                   	ret    
f0101945:	8d 76 00             	lea    0x0(%esi),%esi
f0101948:	39 dd                	cmp    %ebx,%ebp
f010194a:	77 f1                	ja     f010193d <__umoddi3+0x2d>
f010194c:	0f bd cd             	bsr    %ebp,%ecx
f010194f:	83 f1 1f             	xor    $0x1f,%ecx
f0101952:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101956:	0f 84 b4 00 00 00    	je     f0101a10 <__umoddi3+0x100>
f010195c:	b8 20 00 00 00       	mov    $0x20,%eax
f0101961:	89 c2                	mov    %eax,%edx
f0101963:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101967:	29 c2                	sub    %eax,%edx
f0101969:	89 c1                	mov    %eax,%ecx
f010196b:	89 f8                	mov    %edi,%eax
f010196d:	d3 e5                	shl    %cl,%ebp
f010196f:	89 d1                	mov    %edx,%ecx
f0101971:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101975:	d3 e8                	shr    %cl,%eax
f0101977:	09 c5                	or     %eax,%ebp
f0101979:	8b 44 24 04          	mov    0x4(%esp),%eax
f010197d:	89 c1                	mov    %eax,%ecx
f010197f:	d3 e7                	shl    %cl,%edi
f0101981:	89 d1                	mov    %edx,%ecx
f0101983:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101987:	89 df                	mov    %ebx,%edi
f0101989:	d3 ef                	shr    %cl,%edi
f010198b:	89 c1                	mov    %eax,%ecx
f010198d:	89 f0                	mov    %esi,%eax
f010198f:	d3 e3                	shl    %cl,%ebx
f0101991:	89 d1                	mov    %edx,%ecx
f0101993:	89 fa                	mov    %edi,%edx
f0101995:	d3 e8                	shr    %cl,%eax
f0101997:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010199c:	09 d8                	or     %ebx,%eax
f010199e:	f7 f5                	div    %ebp
f01019a0:	d3 e6                	shl    %cl,%esi
f01019a2:	89 d1                	mov    %edx,%ecx
f01019a4:	f7 64 24 08          	mull   0x8(%esp)
f01019a8:	39 d1                	cmp    %edx,%ecx
f01019aa:	89 c3                	mov    %eax,%ebx
f01019ac:	89 d7                	mov    %edx,%edi
f01019ae:	72 06                	jb     f01019b6 <__umoddi3+0xa6>
f01019b0:	75 0e                	jne    f01019c0 <__umoddi3+0xb0>
f01019b2:	39 c6                	cmp    %eax,%esi
f01019b4:	73 0a                	jae    f01019c0 <__umoddi3+0xb0>
f01019b6:	2b 44 24 08          	sub    0x8(%esp),%eax
f01019ba:	19 ea                	sbb    %ebp,%edx
f01019bc:	89 d7                	mov    %edx,%edi
f01019be:	89 c3                	mov    %eax,%ebx
f01019c0:	89 ca                	mov    %ecx,%edx
f01019c2:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f01019c7:	29 de                	sub    %ebx,%esi
f01019c9:	19 fa                	sbb    %edi,%edx
f01019cb:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f01019cf:	89 d0                	mov    %edx,%eax
f01019d1:	d3 e0                	shl    %cl,%eax
f01019d3:	89 d9                	mov    %ebx,%ecx
f01019d5:	d3 ee                	shr    %cl,%esi
f01019d7:	d3 ea                	shr    %cl,%edx
f01019d9:	09 f0                	or     %esi,%eax
f01019db:	83 c4 1c             	add    $0x1c,%esp
f01019de:	5b                   	pop    %ebx
f01019df:	5e                   	pop    %esi
f01019e0:	5f                   	pop    %edi
f01019e1:	5d                   	pop    %ebp
f01019e2:	c3                   	ret    
f01019e3:	90                   	nop
f01019e4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019e8:	85 ff                	test   %edi,%edi
f01019ea:	89 f9                	mov    %edi,%ecx
f01019ec:	75 0b                	jne    f01019f9 <__umoddi3+0xe9>
f01019ee:	b8 01 00 00 00       	mov    $0x1,%eax
f01019f3:	31 d2                	xor    %edx,%edx
f01019f5:	f7 f7                	div    %edi
f01019f7:	89 c1                	mov    %eax,%ecx
f01019f9:	89 d8                	mov    %ebx,%eax
f01019fb:	31 d2                	xor    %edx,%edx
f01019fd:	f7 f1                	div    %ecx
f01019ff:	89 f0                	mov    %esi,%eax
f0101a01:	f7 f1                	div    %ecx
f0101a03:	e9 31 ff ff ff       	jmp    f0101939 <__umoddi3+0x29>
f0101a08:	90                   	nop
f0101a09:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101a10:	39 dd                	cmp    %ebx,%ebp
f0101a12:	72 08                	jb     f0101a1c <__umoddi3+0x10c>
f0101a14:	39 f7                	cmp    %esi,%edi
f0101a16:	0f 87 21 ff ff ff    	ja     f010193d <__umoddi3+0x2d>
f0101a1c:	89 da                	mov    %ebx,%edx
f0101a1e:	89 f0                	mov    %esi,%eax
f0101a20:	29 f8                	sub    %edi,%eax
f0101a22:	19 ea                	sbb    %ebp,%edx
f0101a24:	e9 14 ff ff ff       	jmp    f010193d <__umoddi3+0x2d>
