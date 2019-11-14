
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
f0100045:	e8 a3 01 00 00       	call   f01001ed <__x86.get_pc_thunk.bx>
f010004a:	81 c3 be 12 01 00    	add    $0x112be,%ebx
f0100050:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("entering test_backtrace %d\n", x);
f0100053:	83 ec 08             	sub    $0x8,%esp
f0100056:	56                   	push   %esi
f0100057:	8d 83 d8 08 ff ff    	lea    -0xf728(%ebx),%eax
f010005d:	50                   	push   %eax
f010005e:	e8 29 0b 00 00       	call   f0100b8c <cprintf>
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
f0100073:	e8 53 08 00 00       	call   f01008cb <mon_backtrace>
f0100078:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007b:	83 ec 08             	sub    $0x8,%esp
f010007e:	56                   	push   %esi
f010007f:	8d 83 f4 08 ff ff    	lea    -0xf70c(%ebx),%eax
f0100085:	50                   	push   %eax
f0100086:	e8 01 0b 00 00       	call   f0100b8c <cprintf>
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
f01000aa:	83 ec 18             	sub    $0x18,%esp
f01000ad:	e8 3b 01 00 00       	call   f01001ed <__x86.get_pc_thunk.bx>
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
f01000ca:	e8 d1 16 00 00       	call   f01017a0 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000cf:	e8 6e 05 00 00       	call   f0100642 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000d4:	83 c4 08             	add    $0x8,%esp
f01000d7:	68 ac 1a 00 00       	push   $0x1aac
f01000dc:	8d 83 0f 09 ff ff    	lea    -0xf6f1(%ebx),%eax
f01000e2:	50                   	push   %eax
f01000e3:	e8 a4 0a 00 00       	call   f0100b8c <cprintf>

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
f01000fa:	8d 83 2a 09 ff ff    	lea    -0xf6d6(%ebx),%eax
f0100100:	50                   	push   %eax
f0100101:	e8 86 0a 00 00       	call   f0100b8c <cprintf>

	unsigned int i = 0x00646c72;
f0100106:	c7 45 f4 72 6c 64 00 	movl   $0x646c72,-0xc(%ebp)
    cprintf("H%x Wo%s", 57616, &i);
f010010d:	83 c4 1c             	add    $0x1c,%esp
f0100110:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100113:	50                   	push   %eax
f0100114:	68 10 e1 00 00       	push   $0xe110
f0100119:	8d 83 3c 09 ff ff    	lea    -0xf6c4(%ebx),%eax
f010011f:	50                   	push   %eax
f0100120:	e8 67 0a 00 00       	call   f0100b8c <cprintf>
f0100125:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100128:	83 ec 0c             	sub    $0xc,%esp
f010012b:	6a 00                	push   $0x0
f010012d:	e8 a2 08 00 00       	call   f01009d4 <monitor>
f0100132:	83 c4 10             	add    $0x10,%esp
f0100135:	eb f1                	jmp    f0100128 <i386_init+0x82>

f0100137 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100137:	55                   	push   %ebp
f0100138:	89 e5                	mov    %esp,%ebp
f010013a:	57                   	push   %edi
f010013b:	56                   	push   %esi
f010013c:	53                   	push   %ebx
f010013d:	83 ec 0c             	sub    $0xc,%esp
f0100140:	e8 a8 00 00 00       	call   f01001ed <__x86.get_pc_thunk.bx>
f0100145:	81 c3 c3 11 01 00    	add    $0x111c3,%ebx
f010014b:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f010014e:	c7 c0 a4 36 11 f0    	mov    $0xf01136a4,%eax
f0100154:	83 38 00             	cmpl   $0x0,(%eax)
f0100157:	74 0f                	je     f0100168 <_panic+0x31>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100159:	83 ec 0c             	sub    $0xc,%esp
f010015c:	6a 00                	push   $0x0
f010015e:	e8 71 08 00 00       	call   f01009d4 <monitor>
f0100163:	83 c4 10             	add    $0x10,%esp
f0100166:	eb f1                	jmp    f0100159 <_panic+0x22>
	panicstr = fmt;
f0100168:	89 38                	mov    %edi,(%eax)
	asm volatile("cli; cld");
f010016a:	fa                   	cli    
f010016b:	fc                   	cld    
	va_start(ap, fmt);
f010016c:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
f010016f:	83 ec 04             	sub    $0x4,%esp
f0100172:	ff 75 0c             	pushl  0xc(%ebp)
f0100175:	ff 75 08             	pushl  0x8(%ebp)
f0100178:	8d 83 45 09 ff ff    	lea    -0xf6bb(%ebx),%eax
f010017e:	50                   	push   %eax
f010017f:	e8 08 0a 00 00       	call   f0100b8c <cprintf>
	vcprintf(fmt, ap);
f0100184:	83 c4 08             	add    $0x8,%esp
f0100187:	56                   	push   %esi
f0100188:	57                   	push   %edi
f0100189:	e8 c7 09 00 00       	call   f0100b55 <vcprintf>
	cprintf("\n");
f010018e:	8d 83 81 09 ff ff    	lea    -0xf67f(%ebx),%eax
f0100194:	89 04 24             	mov    %eax,(%esp)
f0100197:	e8 f0 09 00 00       	call   f0100b8c <cprintf>
f010019c:	83 c4 10             	add    $0x10,%esp
f010019f:	eb b8                	jmp    f0100159 <_panic+0x22>

f01001a1 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01001a1:	55                   	push   %ebp
f01001a2:	89 e5                	mov    %esp,%ebp
f01001a4:	56                   	push   %esi
f01001a5:	53                   	push   %ebx
f01001a6:	e8 42 00 00 00       	call   f01001ed <__x86.get_pc_thunk.bx>
f01001ab:	81 c3 5d 11 01 00    	add    $0x1115d,%ebx
	va_list ap;

	va_start(ap, fmt);
f01001b1:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f01001b4:	83 ec 04             	sub    $0x4,%esp
f01001b7:	ff 75 0c             	pushl  0xc(%ebp)
f01001ba:	ff 75 08             	pushl  0x8(%ebp)
f01001bd:	8d 83 5d 09 ff ff    	lea    -0xf6a3(%ebx),%eax
f01001c3:	50                   	push   %eax
f01001c4:	e8 c3 09 00 00       	call   f0100b8c <cprintf>
	vcprintf(fmt, ap);
f01001c9:	83 c4 08             	add    $0x8,%esp
f01001cc:	56                   	push   %esi
f01001cd:	ff 75 10             	pushl  0x10(%ebp)
f01001d0:	e8 80 09 00 00       	call   f0100b55 <vcprintf>
	cprintf("\n");
f01001d5:	8d 83 81 09 ff ff    	lea    -0xf67f(%ebx),%eax
f01001db:	89 04 24             	mov    %eax,(%esp)
f01001de:	e8 a9 09 00 00       	call   f0100b8c <cprintf>
	va_end(ap);
}
f01001e3:	83 c4 10             	add    $0x10,%esp
f01001e6:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01001e9:	5b                   	pop    %ebx
f01001ea:	5e                   	pop    %esi
f01001eb:	5d                   	pop    %ebp
f01001ec:	c3                   	ret    

f01001ed <__x86.get_pc_thunk.bx>:
f01001ed:	8b 1c 24             	mov    (%esp),%ebx
f01001f0:	c3                   	ret    

f01001f1 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001f1:	55                   	push   %ebp
f01001f2:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001f4:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001f9:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001fa:	a8 01                	test   $0x1,%al
f01001fc:	74 0b                	je     f0100209 <serial_proc_data+0x18>
f01001fe:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100203:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100204:	0f b6 c0             	movzbl %al,%eax
}
f0100207:	5d                   	pop    %ebp
f0100208:	c3                   	ret    
		return -1;
f0100209:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010020e:	eb f7                	jmp    f0100207 <serial_proc_data+0x16>

f0100210 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100210:	55                   	push   %ebp
f0100211:	89 e5                	mov    %esp,%ebp
f0100213:	56                   	push   %esi
f0100214:	53                   	push   %ebx
f0100215:	e8 d3 ff ff ff       	call   f01001ed <__x86.get_pc_thunk.bx>
f010021a:	81 c3 ee 10 01 00    	add    $0x110ee,%ebx
f0100220:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
f0100222:	ff d6                	call   *%esi
f0100224:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100227:	74 2e                	je     f0100257 <cons_intr+0x47>
		if (c == 0)
f0100229:	85 c0                	test   %eax,%eax
f010022b:	74 f5                	je     f0100222 <cons_intr+0x12>
			continue;
		cons.buf[cons.wpos++] = c;
f010022d:	8b 8b 7c 1f 00 00    	mov    0x1f7c(%ebx),%ecx
f0100233:	8d 51 01             	lea    0x1(%ecx),%edx
f0100236:	89 93 7c 1f 00 00    	mov    %edx,0x1f7c(%ebx)
f010023c:	88 84 0b 78 1d 00 00 	mov    %al,0x1d78(%ebx,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f0100243:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100249:	75 d7                	jne    f0100222 <cons_intr+0x12>
			cons.wpos = 0;
f010024b:	c7 83 7c 1f 00 00 00 	movl   $0x0,0x1f7c(%ebx)
f0100252:	00 00 00 
f0100255:	eb cb                	jmp    f0100222 <cons_intr+0x12>
	}
}
f0100257:	5b                   	pop    %ebx
f0100258:	5e                   	pop    %esi
f0100259:	5d                   	pop    %ebp
f010025a:	c3                   	ret    

f010025b <kbd_proc_data>:
{
f010025b:	55                   	push   %ebp
f010025c:	89 e5                	mov    %esp,%ebp
f010025e:	56                   	push   %esi
f010025f:	53                   	push   %ebx
f0100260:	e8 88 ff ff ff       	call   f01001ed <__x86.get_pc_thunk.bx>
f0100265:	81 c3 a3 10 01 00    	add    $0x110a3,%ebx
f010026b:	ba 64 00 00 00       	mov    $0x64,%edx
f0100270:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f0100271:	a8 01                	test   $0x1,%al
f0100273:	0f 84 06 01 00 00    	je     f010037f <kbd_proc_data+0x124>
	if (stat & KBS_TERR)
f0100279:	a8 20                	test   $0x20,%al
f010027b:	0f 85 05 01 00 00    	jne    f0100386 <kbd_proc_data+0x12b>
f0100281:	ba 60 00 00 00       	mov    $0x60,%edx
f0100286:	ec                   	in     (%dx),%al
f0100287:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f0100289:	3c e0                	cmp    $0xe0,%al
f010028b:	0f 84 93 00 00 00    	je     f0100324 <kbd_proc_data+0xc9>
	} else if (data & 0x80) {
f0100291:	84 c0                	test   %al,%al
f0100293:	0f 88 a0 00 00 00    	js     f0100339 <kbd_proc_data+0xde>
	} else if (shift & E0ESC) {
f0100299:	8b 8b 58 1d 00 00    	mov    0x1d58(%ebx),%ecx
f010029f:	f6 c1 40             	test   $0x40,%cl
f01002a2:	74 0e                	je     f01002b2 <kbd_proc_data+0x57>
		data |= 0x80;
f01002a4:	83 c8 80             	or     $0xffffff80,%eax
f01002a7:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01002a9:	83 e1 bf             	and    $0xffffffbf,%ecx
f01002ac:	89 8b 58 1d 00 00    	mov    %ecx,0x1d58(%ebx)
	shift |= shiftcode[data];
f01002b2:	0f b6 d2             	movzbl %dl,%edx
f01002b5:	0f b6 84 13 b8 0a ff 	movzbl -0xf548(%ebx,%edx,1),%eax
f01002bc:	ff 
f01002bd:	0b 83 58 1d 00 00    	or     0x1d58(%ebx),%eax
	shift ^= togglecode[data];
f01002c3:	0f b6 8c 13 b8 09 ff 	movzbl -0xf648(%ebx,%edx,1),%ecx
f01002ca:	ff 
f01002cb:	31 c8                	xor    %ecx,%eax
f01002cd:	89 83 58 1d 00 00    	mov    %eax,0x1d58(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f01002d3:	89 c1                	mov    %eax,%ecx
f01002d5:	83 e1 03             	and    $0x3,%ecx
f01002d8:	8b 8c 8b f8 1c 00 00 	mov    0x1cf8(%ebx,%ecx,4),%ecx
f01002df:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01002e3:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
f01002e6:	a8 08                	test   $0x8,%al
f01002e8:	74 0d                	je     f01002f7 <kbd_proc_data+0x9c>
		if ('a' <= c && c <= 'z')
f01002ea:	89 f2                	mov    %esi,%edx
f01002ec:	8d 4e 9f             	lea    -0x61(%esi),%ecx
f01002ef:	83 f9 19             	cmp    $0x19,%ecx
f01002f2:	77 7a                	ja     f010036e <kbd_proc_data+0x113>
			c += 'A' - 'a';
f01002f4:	83 ee 20             	sub    $0x20,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01002f7:	f7 d0                	not    %eax
f01002f9:	a8 06                	test   $0x6,%al
f01002fb:	75 33                	jne    f0100330 <kbd_proc_data+0xd5>
f01002fd:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
f0100303:	75 2b                	jne    f0100330 <kbd_proc_data+0xd5>
		cprintf("Rebooting!\n");
f0100305:	83 ec 0c             	sub    $0xc,%esp
f0100308:	8d 83 77 09 ff ff    	lea    -0xf689(%ebx),%eax
f010030e:	50                   	push   %eax
f010030f:	e8 78 08 00 00       	call   f0100b8c <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100314:	b8 03 00 00 00       	mov    $0x3,%eax
f0100319:	ba 92 00 00 00       	mov    $0x92,%edx
f010031e:	ee                   	out    %al,(%dx)
f010031f:	83 c4 10             	add    $0x10,%esp
f0100322:	eb 0c                	jmp    f0100330 <kbd_proc_data+0xd5>
		shift |= E0ESC;
f0100324:	83 8b 58 1d 00 00 40 	orl    $0x40,0x1d58(%ebx)
		return 0;
f010032b:	be 00 00 00 00       	mov    $0x0,%esi
}
f0100330:	89 f0                	mov    %esi,%eax
f0100332:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100335:	5b                   	pop    %ebx
f0100336:	5e                   	pop    %esi
f0100337:	5d                   	pop    %ebp
f0100338:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f0100339:	8b 8b 58 1d 00 00    	mov    0x1d58(%ebx),%ecx
f010033f:	89 ce                	mov    %ecx,%esi
f0100341:	83 e6 40             	and    $0x40,%esi
f0100344:	83 e0 7f             	and    $0x7f,%eax
f0100347:	85 f6                	test   %esi,%esi
f0100349:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010034c:	0f b6 d2             	movzbl %dl,%edx
f010034f:	0f b6 84 13 b8 0a ff 	movzbl -0xf548(%ebx,%edx,1),%eax
f0100356:	ff 
f0100357:	83 c8 40             	or     $0x40,%eax
f010035a:	0f b6 c0             	movzbl %al,%eax
f010035d:	f7 d0                	not    %eax
f010035f:	21 c8                	and    %ecx,%eax
f0100361:	89 83 58 1d 00 00    	mov    %eax,0x1d58(%ebx)
		return 0;
f0100367:	be 00 00 00 00       	mov    $0x0,%esi
f010036c:	eb c2                	jmp    f0100330 <kbd_proc_data+0xd5>
		else if ('A' <= c && c <= 'Z')
f010036e:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100371:	8d 4e 20             	lea    0x20(%esi),%ecx
f0100374:	83 fa 1a             	cmp    $0x1a,%edx
f0100377:	0f 42 f1             	cmovb  %ecx,%esi
f010037a:	e9 78 ff ff ff       	jmp    f01002f7 <kbd_proc_data+0x9c>
		return -1;
f010037f:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0100384:	eb aa                	jmp    f0100330 <kbd_proc_data+0xd5>
		return -1;
f0100386:	be ff ff ff ff       	mov    $0xffffffff,%esi
f010038b:	eb a3                	jmp    f0100330 <kbd_proc_data+0xd5>

f010038d <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f010038d:	55                   	push   %ebp
f010038e:	89 e5                	mov    %esp,%ebp
f0100390:	57                   	push   %edi
f0100391:	56                   	push   %esi
f0100392:	53                   	push   %ebx
f0100393:	83 ec 1c             	sub    $0x1c,%esp
f0100396:	e8 52 fe ff ff       	call   f01001ed <__x86.get_pc_thunk.bx>
f010039b:	81 c3 6d 0f 01 00    	add    $0x10f6d,%ebx
f01003a1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0;
f01003a4:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003a9:	bf fd 03 00 00       	mov    $0x3fd,%edi
f01003ae:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003b3:	eb 09                	jmp    f01003be <cons_putc+0x31>
f01003b5:	89 ca                	mov    %ecx,%edx
f01003b7:	ec                   	in     (%dx),%al
f01003b8:	ec                   	in     (%dx),%al
f01003b9:	ec                   	in     (%dx),%al
f01003ba:	ec                   	in     (%dx),%al
	     i++)
f01003bb:	83 c6 01             	add    $0x1,%esi
f01003be:	89 fa                	mov    %edi,%edx
f01003c0:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01003c1:	a8 20                	test   $0x20,%al
f01003c3:	75 08                	jne    f01003cd <cons_putc+0x40>
f01003c5:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f01003cb:	7e e8                	jle    f01003b5 <cons_putc+0x28>
	outb(COM1 + COM_TX, c);
f01003cd:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01003d0:	89 f8                	mov    %edi,%eax
f01003d2:	88 45 e3             	mov    %al,-0x1d(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003d5:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01003da:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01003db:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003e0:	bf 79 03 00 00       	mov    $0x379,%edi
f01003e5:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003ea:	eb 09                	jmp    f01003f5 <cons_putc+0x68>
f01003ec:	89 ca                	mov    %ecx,%edx
f01003ee:	ec                   	in     (%dx),%al
f01003ef:	ec                   	in     (%dx),%al
f01003f0:	ec                   	in     (%dx),%al
f01003f1:	ec                   	in     (%dx),%al
f01003f2:	83 c6 01             	add    $0x1,%esi
f01003f5:	89 fa                	mov    %edi,%edx
f01003f7:	ec                   	in     (%dx),%al
f01003f8:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f01003fe:	7f 04                	jg     f0100404 <cons_putc+0x77>
f0100400:	84 c0                	test   %al,%al
f0100402:	79 e8                	jns    f01003ec <cons_putc+0x5f>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100404:	ba 78 03 00 00       	mov    $0x378,%edx
f0100409:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f010040d:	ee                   	out    %al,(%dx)
f010040e:	ba 7a 03 00 00       	mov    $0x37a,%edx
f0100413:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100418:	ee                   	out    %al,(%dx)
f0100419:	b8 08 00 00 00       	mov    $0x8,%eax
f010041e:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f010041f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100422:	89 fa                	mov    %edi,%edx
f0100424:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010042a:	89 f8                	mov    %edi,%eax
f010042c:	80 cc 07             	or     $0x7,%ah
f010042f:	85 d2                	test   %edx,%edx
f0100431:	0f 45 c7             	cmovne %edi,%eax
f0100434:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch (c & 0xff) {
f0100437:	0f b6 c0             	movzbl %al,%eax
f010043a:	83 f8 09             	cmp    $0x9,%eax
f010043d:	0f 84 b9 00 00 00    	je     f01004fc <cons_putc+0x16f>
f0100443:	83 f8 09             	cmp    $0x9,%eax
f0100446:	7e 74                	jle    f01004bc <cons_putc+0x12f>
f0100448:	83 f8 0a             	cmp    $0xa,%eax
f010044b:	0f 84 9e 00 00 00    	je     f01004ef <cons_putc+0x162>
f0100451:	83 f8 0d             	cmp    $0xd,%eax
f0100454:	0f 85 d9 00 00 00    	jne    f0100533 <cons_putc+0x1a6>
		crt_pos -= (crt_pos % CRT_COLS);
f010045a:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f0100461:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100467:	c1 e8 16             	shr    $0x16,%eax
f010046a:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010046d:	c1 e0 04             	shl    $0x4,%eax
f0100470:	66 89 83 80 1f 00 00 	mov    %ax,0x1f80(%ebx)
	if (crt_pos >= CRT_SIZE) {
f0100477:	66 81 bb 80 1f 00 00 	cmpw   $0x7cf,0x1f80(%ebx)
f010047e:	cf 07 
f0100480:	0f 87 d4 00 00 00    	ja     f010055a <cons_putc+0x1cd>
	outb(addr_6845, 14);
f0100486:	8b 8b 88 1f 00 00    	mov    0x1f88(%ebx),%ecx
f010048c:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100491:	89 ca                	mov    %ecx,%edx
f0100493:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100494:	0f b7 9b 80 1f 00 00 	movzwl 0x1f80(%ebx),%ebx
f010049b:	8d 71 01             	lea    0x1(%ecx),%esi
f010049e:	89 d8                	mov    %ebx,%eax
f01004a0:	66 c1 e8 08          	shr    $0x8,%ax
f01004a4:	89 f2                	mov    %esi,%edx
f01004a6:	ee                   	out    %al,(%dx)
f01004a7:	b8 0f 00 00 00       	mov    $0xf,%eax
f01004ac:	89 ca                	mov    %ecx,%edx
f01004ae:	ee                   	out    %al,(%dx)
f01004af:	89 d8                	mov    %ebx,%eax
f01004b1:	89 f2                	mov    %esi,%edx
f01004b3:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01004b4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01004b7:	5b                   	pop    %ebx
f01004b8:	5e                   	pop    %esi
f01004b9:	5f                   	pop    %edi
f01004ba:	5d                   	pop    %ebp
f01004bb:	c3                   	ret    
	switch (c & 0xff) {
f01004bc:	83 f8 08             	cmp    $0x8,%eax
f01004bf:	75 72                	jne    f0100533 <cons_putc+0x1a6>
		if (crt_pos > 0) {
f01004c1:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f01004c8:	66 85 c0             	test   %ax,%ax
f01004cb:	74 b9                	je     f0100486 <cons_putc+0xf9>
			crt_pos--;
f01004cd:	83 e8 01             	sub    $0x1,%eax
f01004d0:	66 89 83 80 1f 00 00 	mov    %ax,0x1f80(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004d7:	0f b7 c0             	movzwl %ax,%eax
f01004da:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f01004de:	b2 00                	mov    $0x0,%dl
f01004e0:	83 ca 20             	or     $0x20,%edx
f01004e3:	8b 8b 84 1f 00 00    	mov    0x1f84(%ebx),%ecx
f01004e9:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f01004ed:	eb 88                	jmp    f0100477 <cons_putc+0xea>
		crt_pos += CRT_COLS;
f01004ef:	66 83 83 80 1f 00 00 	addw   $0x50,0x1f80(%ebx)
f01004f6:	50 
f01004f7:	e9 5e ff ff ff       	jmp    f010045a <cons_putc+0xcd>
		cons_putc(' ');
f01004fc:	b8 20 00 00 00       	mov    $0x20,%eax
f0100501:	e8 87 fe ff ff       	call   f010038d <cons_putc>
		cons_putc(' ');
f0100506:	b8 20 00 00 00       	mov    $0x20,%eax
f010050b:	e8 7d fe ff ff       	call   f010038d <cons_putc>
		cons_putc(' ');
f0100510:	b8 20 00 00 00       	mov    $0x20,%eax
f0100515:	e8 73 fe ff ff       	call   f010038d <cons_putc>
		cons_putc(' ');
f010051a:	b8 20 00 00 00       	mov    $0x20,%eax
f010051f:	e8 69 fe ff ff       	call   f010038d <cons_putc>
		cons_putc(' ');
f0100524:	b8 20 00 00 00       	mov    $0x20,%eax
f0100529:	e8 5f fe ff ff       	call   f010038d <cons_putc>
f010052e:	e9 44 ff ff ff       	jmp    f0100477 <cons_putc+0xea>
		crt_buf[crt_pos++] = c;		/* write the character */
f0100533:	0f b7 83 80 1f 00 00 	movzwl 0x1f80(%ebx),%eax
f010053a:	8d 50 01             	lea    0x1(%eax),%edx
f010053d:	66 89 93 80 1f 00 00 	mov    %dx,0x1f80(%ebx)
f0100544:	0f b7 c0             	movzwl %ax,%eax
f0100547:	8b 93 84 1f 00 00    	mov    0x1f84(%ebx),%edx
f010054d:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f0100551:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f0100555:	e9 1d ff ff ff       	jmp    f0100477 <cons_putc+0xea>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010055a:	8b 83 84 1f 00 00    	mov    0x1f84(%ebx),%eax
f0100560:	83 ec 04             	sub    $0x4,%esp
f0100563:	68 00 0f 00 00       	push   $0xf00
f0100568:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f010056e:	52                   	push   %edx
f010056f:	50                   	push   %eax
f0100570:	e8 78 12 00 00       	call   f01017ed <memmove>
			crt_buf[i] = 0x0700 | ' ';
f0100575:	8b 93 84 1f 00 00    	mov    0x1f84(%ebx),%edx
f010057b:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100581:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100587:	83 c4 10             	add    $0x10,%esp
f010058a:	66 c7 00 20 07       	movw   $0x720,(%eax)
f010058f:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100592:	39 d0                	cmp    %edx,%eax
f0100594:	75 f4                	jne    f010058a <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
f0100596:	66 83 ab 80 1f 00 00 	subw   $0x50,0x1f80(%ebx)
f010059d:	50 
f010059e:	e9 e3 fe ff ff       	jmp    f0100486 <cons_putc+0xf9>

f01005a3 <serial_intr>:
{
f01005a3:	e8 e7 01 00 00       	call   f010078f <__x86.get_pc_thunk.ax>
f01005a8:	05 60 0d 01 00       	add    $0x10d60,%eax
	if (serial_exists)
f01005ad:	80 b8 8c 1f 00 00 00 	cmpb   $0x0,0x1f8c(%eax)
f01005b4:	75 02                	jne    f01005b8 <serial_intr+0x15>
f01005b6:	f3 c3                	repz ret 
{
f01005b8:	55                   	push   %ebp
f01005b9:	89 e5                	mov    %esp,%ebp
f01005bb:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f01005be:	8d 80 e9 ee fe ff    	lea    -0x11117(%eax),%eax
f01005c4:	e8 47 fc ff ff       	call   f0100210 <cons_intr>
}
f01005c9:	c9                   	leave  
f01005ca:	c3                   	ret    

f01005cb <kbd_intr>:
{
f01005cb:	55                   	push   %ebp
f01005cc:	89 e5                	mov    %esp,%ebp
f01005ce:	83 ec 08             	sub    $0x8,%esp
f01005d1:	e8 b9 01 00 00       	call   f010078f <__x86.get_pc_thunk.ax>
f01005d6:	05 32 0d 01 00       	add    $0x10d32,%eax
	cons_intr(kbd_proc_data);
f01005db:	8d 80 53 ef fe ff    	lea    -0x110ad(%eax),%eax
f01005e1:	e8 2a fc ff ff       	call   f0100210 <cons_intr>
}
f01005e6:	c9                   	leave  
f01005e7:	c3                   	ret    

f01005e8 <cons_getc>:
{
f01005e8:	55                   	push   %ebp
f01005e9:	89 e5                	mov    %esp,%ebp
f01005eb:	53                   	push   %ebx
f01005ec:	83 ec 04             	sub    $0x4,%esp
f01005ef:	e8 f9 fb ff ff       	call   f01001ed <__x86.get_pc_thunk.bx>
f01005f4:	81 c3 14 0d 01 00    	add    $0x10d14,%ebx
	serial_intr();
f01005fa:	e8 a4 ff ff ff       	call   f01005a3 <serial_intr>
	kbd_intr();
f01005ff:	e8 c7 ff ff ff       	call   f01005cb <kbd_intr>
	if (cons.rpos != cons.wpos) {
f0100604:	8b 93 78 1f 00 00    	mov    0x1f78(%ebx),%edx
	return 0;
f010060a:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f010060f:	3b 93 7c 1f 00 00    	cmp    0x1f7c(%ebx),%edx
f0100615:	74 19                	je     f0100630 <cons_getc+0x48>
		c = cons.buf[cons.rpos++];
f0100617:	8d 4a 01             	lea    0x1(%edx),%ecx
f010061a:	89 8b 78 1f 00 00    	mov    %ecx,0x1f78(%ebx)
f0100620:	0f b6 84 13 78 1d 00 	movzbl 0x1d78(%ebx,%edx,1),%eax
f0100627:	00 
		if (cons.rpos == CONSBUFSIZE)
f0100628:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f010062e:	74 06                	je     f0100636 <cons_getc+0x4e>
}
f0100630:	83 c4 04             	add    $0x4,%esp
f0100633:	5b                   	pop    %ebx
f0100634:	5d                   	pop    %ebp
f0100635:	c3                   	ret    
			cons.rpos = 0;
f0100636:	c7 83 78 1f 00 00 00 	movl   $0x0,0x1f78(%ebx)
f010063d:	00 00 00 
f0100640:	eb ee                	jmp    f0100630 <cons_getc+0x48>

f0100642 <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f0100642:	55                   	push   %ebp
f0100643:	89 e5                	mov    %esp,%ebp
f0100645:	57                   	push   %edi
f0100646:	56                   	push   %esi
f0100647:	53                   	push   %ebx
f0100648:	83 ec 1c             	sub    $0x1c,%esp
f010064b:	e8 9d fb ff ff       	call   f01001ed <__x86.get_pc_thunk.bx>
f0100650:	81 c3 b8 0c 01 00    	add    $0x10cb8,%ebx
	was = *cp;
f0100656:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010065d:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100664:	5a a5 
	if (*cp != 0xA55A) {
f0100666:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010066d:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100671:	0f 84 bc 00 00 00    	je     f0100733 <cons_init+0xf1>
		addr_6845 = MONO_BASE;
f0100677:	c7 83 88 1f 00 00 b4 	movl   $0x3b4,0x1f88(%ebx)
f010067e:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100681:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f0100688:	8b bb 88 1f 00 00    	mov    0x1f88(%ebx),%edi
f010068e:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100693:	89 fa                	mov    %edi,%edx
f0100695:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100696:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100699:	89 ca                	mov    %ecx,%edx
f010069b:	ec                   	in     (%dx),%al
f010069c:	0f b6 f0             	movzbl %al,%esi
f010069f:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006a2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01006a7:	89 fa                	mov    %edi,%edx
f01006a9:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006aa:	89 ca                	mov    %ecx,%edx
f01006ac:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f01006ad:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01006b0:	89 bb 84 1f 00 00    	mov    %edi,0x1f84(%ebx)
	pos |= inb(addr_6845 + 1);
f01006b6:	0f b6 c0             	movzbl %al,%eax
f01006b9:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f01006bb:	66 89 b3 80 1f 00 00 	mov    %si,0x1f80(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006c2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01006c7:	89 c8                	mov    %ecx,%eax
f01006c9:	ba fa 03 00 00       	mov    $0x3fa,%edx
f01006ce:	ee                   	out    %al,(%dx)
f01006cf:	bf fb 03 00 00       	mov    $0x3fb,%edi
f01006d4:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01006d9:	89 fa                	mov    %edi,%edx
f01006db:	ee                   	out    %al,(%dx)
f01006dc:	b8 0c 00 00 00       	mov    $0xc,%eax
f01006e1:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01006e6:	ee                   	out    %al,(%dx)
f01006e7:	be f9 03 00 00       	mov    $0x3f9,%esi
f01006ec:	89 c8                	mov    %ecx,%eax
f01006ee:	89 f2                	mov    %esi,%edx
f01006f0:	ee                   	out    %al,(%dx)
f01006f1:	b8 03 00 00 00       	mov    $0x3,%eax
f01006f6:	89 fa                	mov    %edi,%edx
f01006f8:	ee                   	out    %al,(%dx)
f01006f9:	ba fc 03 00 00       	mov    $0x3fc,%edx
f01006fe:	89 c8                	mov    %ecx,%eax
f0100700:	ee                   	out    %al,(%dx)
f0100701:	b8 01 00 00 00       	mov    $0x1,%eax
f0100706:	89 f2                	mov    %esi,%edx
f0100708:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100709:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010070e:	ec                   	in     (%dx),%al
f010070f:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100711:	3c ff                	cmp    $0xff,%al
f0100713:	0f 95 83 8c 1f 00 00 	setne  0x1f8c(%ebx)
f010071a:	ba fa 03 00 00       	mov    $0x3fa,%edx
f010071f:	ec                   	in     (%dx),%al
f0100720:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100725:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100726:	80 f9 ff             	cmp    $0xff,%cl
f0100729:	74 25                	je     f0100750 <cons_init+0x10e>
		cprintf("Serial port does not exist!\n");
}
f010072b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010072e:	5b                   	pop    %ebx
f010072f:	5e                   	pop    %esi
f0100730:	5f                   	pop    %edi
f0100731:	5d                   	pop    %ebp
f0100732:	c3                   	ret    
		*cp = was;
f0100733:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010073a:	c7 83 88 1f 00 00 d4 	movl   $0x3d4,0x1f88(%ebx)
f0100741:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100744:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f010074b:	e9 38 ff ff ff       	jmp    f0100688 <cons_init+0x46>
		cprintf("Serial port does not exist!\n");
f0100750:	83 ec 0c             	sub    $0xc,%esp
f0100753:	8d 83 83 09 ff ff    	lea    -0xf67d(%ebx),%eax
f0100759:	50                   	push   %eax
f010075a:	e8 2d 04 00 00       	call   f0100b8c <cprintf>
f010075f:	83 c4 10             	add    $0x10,%esp
}
f0100762:	eb c7                	jmp    f010072b <cons_init+0xe9>

f0100764 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100764:	55                   	push   %ebp
f0100765:	89 e5                	mov    %esp,%ebp
f0100767:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010076a:	8b 45 08             	mov    0x8(%ebp),%eax
f010076d:	e8 1b fc ff ff       	call   f010038d <cons_putc>
}
f0100772:	c9                   	leave  
f0100773:	c3                   	ret    

f0100774 <getchar>:

int
getchar(void)
{
f0100774:	55                   	push   %ebp
f0100775:	89 e5                	mov    %esp,%ebp
f0100777:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010077a:	e8 69 fe ff ff       	call   f01005e8 <cons_getc>
f010077f:	85 c0                	test   %eax,%eax
f0100781:	74 f7                	je     f010077a <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100783:	c9                   	leave  
f0100784:	c3                   	ret    

f0100785 <iscons>:

int
iscons(int fdnum)
{
f0100785:	55                   	push   %ebp
f0100786:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100788:	b8 01 00 00 00       	mov    $0x1,%eax
f010078d:	5d                   	pop    %ebp
f010078e:	c3                   	ret    

f010078f <__x86.get_pc_thunk.ax>:
f010078f:	8b 04 24             	mov    (%esp),%eax
f0100792:	c3                   	ret    

f0100793 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100793:	55                   	push   %ebp
f0100794:	89 e5                	mov    %esp,%ebp
f0100796:	56                   	push   %esi
f0100797:	53                   	push   %ebx
f0100798:	e8 50 fa ff ff       	call   f01001ed <__x86.get_pc_thunk.bx>
f010079d:	81 c3 6b 0b 01 00    	add    $0x10b6b,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01007a3:	83 ec 04             	sub    $0x4,%esp
f01007a6:	8d 83 b8 0b ff ff    	lea    -0xf448(%ebx),%eax
f01007ac:	50                   	push   %eax
f01007ad:	8d 83 d6 0b ff ff    	lea    -0xf42a(%ebx),%eax
f01007b3:	50                   	push   %eax
f01007b4:	8d b3 db 0b ff ff    	lea    -0xf425(%ebx),%esi
f01007ba:	56                   	push   %esi
f01007bb:	e8 cc 03 00 00       	call   f0100b8c <cprintf>
f01007c0:	83 c4 0c             	add    $0xc,%esp
f01007c3:	8d 83 94 0c ff ff    	lea    -0xf36c(%ebx),%eax
f01007c9:	50                   	push   %eax
f01007ca:	8d 83 e4 0b ff ff    	lea    -0xf41c(%ebx),%eax
f01007d0:	50                   	push   %eax
f01007d1:	56                   	push   %esi
f01007d2:	e8 b5 03 00 00       	call   f0100b8c <cprintf>
f01007d7:	83 c4 0c             	add    $0xc,%esp
f01007da:	8d 83 bc 0c ff ff    	lea    -0xf344(%ebx),%eax
f01007e0:	50                   	push   %eax
f01007e1:	8d 83 ed 0b ff ff    	lea    -0xf413(%ebx),%eax
f01007e7:	50                   	push   %eax
f01007e8:	56                   	push   %esi
f01007e9:	e8 9e 03 00 00       	call   f0100b8c <cprintf>
	return 0;
}
f01007ee:	b8 00 00 00 00       	mov    $0x0,%eax
f01007f3:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01007f6:	5b                   	pop    %ebx
f01007f7:	5e                   	pop    %esi
f01007f8:	5d                   	pop    %ebp
f01007f9:	c3                   	ret    

f01007fa <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007fa:	55                   	push   %ebp
f01007fb:	89 e5                	mov    %esp,%ebp
f01007fd:	57                   	push   %edi
f01007fe:	56                   	push   %esi
f01007ff:	53                   	push   %ebx
f0100800:	83 ec 18             	sub    $0x18,%esp
f0100803:	e8 e5 f9 ff ff       	call   f01001ed <__x86.get_pc_thunk.bx>
f0100808:	81 c3 00 0b 01 00    	add    $0x10b00,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f010080e:	8d 83 f7 0b ff ff    	lea    -0xf409(%ebx),%eax
f0100814:	50                   	push   %eax
f0100815:	e8 72 03 00 00       	call   f0100b8c <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010081a:	83 c4 08             	add    $0x8,%esp
f010081d:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f0100823:	8d 83 f0 0c ff ff    	lea    -0xf310(%ebx),%eax
f0100829:	50                   	push   %eax
f010082a:	e8 5d 03 00 00       	call   f0100b8c <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010082f:	83 c4 0c             	add    $0xc,%esp
f0100832:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f0100838:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f010083e:	50                   	push   %eax
f010083f:	57                   	push   %edi
f0100840:	8d 83 18 0d ff ff    	lea    -0xf2e8(%ebx),%eax
f0100846:	50                   	push   %eax
f0100847:	e8 40 03 00 00       	call   f0100b8c <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010084c:	83 c4 0c             	add    $0xc,%esp
f010084f:	c7 c0 d9 1b 10 f0    	mov    $0xf0101bd9,%eax
f0100855:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010085b:	52                   	push   %edx
f010085c:	50                   	push   %eax
f010085d:	8d 83 3c 0d ff ff    	lea    -0xf2c4(%ebx),%eax
f0100863:	50                   	push   %eax
f0100864:	e8 23 03 00 00       	call   f0100b8c <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100869:	83 c4 0c             	add    $0xc,%esp
f010086c:	c7 c0 60 30 11 f0    	mov    $0xf0113060,%eax
f0100872:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100878:	52                   	push   %edx
f0100879:	50                   	push   %eax
f010087a:	8d 83 60 0d ff ff    	lea    -0xf2a0(%ebx),%eax
f0100880:	50                   	push   %eax
f0100881:	e8 06 03 00 00       	call   f0100b8c <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100886:	83 c4 0c             	add    $0xc,%esp
f0100889:	c7 c6 a0 36 11 f0    	mov    $0xf01136a0,%esi
f010088f:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f0100895:	50                   	push   %eax
f0100896:	56                   	push   %esi
f0100897:	8d 83 84 0d ff ff    	lea    -0xf27c(%ebx),%eax
f010089d:	50                   	push   %eax
f010089e:	e8 e9 02 00 00       	call   f0100b8c <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f01008a3:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f01008a6:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f01008ac:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f01008ae:	c1 fe 0a             	sar    $0xa,%esi
f01008b1:	56                   	push   %esi
f01008b2:	8d 83 a8 0d ff ff    	lea    -0xf258(%ebx),%eax
f01008b8:	50                   	push   %eax
f01008b9:	e8 ce 02 00 00       	call   f0100b8c <cprintf>
	return 0;
}
f01008be:	b8 00 00 00 00       	mov    $0x0,%eax
f01008c3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008c6:	5b                   	pop    %ebx
f01008c7:	5e                   	pop    %esi
f01008c8:	5f                   	pop    %edi
f01008c9:	5d                   	pop    %ebp
f01008ca:	c3                   	ret    

f01008cb <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01008cb:	55                   	push   %ebp
f01008cc:	89 e5                	mov    %esp,%ebp
f01008ce:	57                   	push   %edi
f01008cf:	56                   	push   %esi
f01008d0:	53                   	push   %ebx
f01008d1:	83 ec 58             	sub    $0x58,%esp
f01008d4:	e8 14 f9 ff ff       	call   f01001ed <__x86.get_pc_thunk.bx>
f01008d9:	81 c3 2f 0a 01 00    	add    $0x10a2f,%ebx
	cprintf("Stack backtrace:\n");
f01008df:	8d 83 10 0c ff ff    	lea    -0xf3f0(%ebx),%eax
f01008e5:	50                   	push   %eax
f01008e6:	e8 a1 02 00 00       	call   f0100b8c <cprintf>

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01008eb:	89 ef                	mov    %ebp,%edi
	int* curr_ebp = (int *) read_ebp();
f01008ed:	83 c4 10             	add    $0x10,%esp
		// is already the last function in the call stack, and
		// thus you print the info and return.

		eip = (uint32_t) *(curr_ebp + 1);

		cprintf("  ebp %08x eip %08x ", curr_ebp, eip);
f01008f0:	8d 83 22 0c ff ff    	lea    -0xf3de(%ebx),%eax
f01008f6:	89 45 b8             	mov    %eax,-0x48(%ebp)
		cprintf("args");
f01008f9:	8d 83 37 0c ff ff    	lea    -0xf3c9(%ebx),%eax
f01008ff:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		prev_ebp = (int *) *curr_ebp;
f0100902:	8b 07                	mov    (%edi),%eax
f0100904:	89 45 c0             	mov    %eax,-0x40(%ebp)
		eip = (uint32_t) *(curr_ebp + 1);
f0100907:	8b 47 04             	mov    0x4(%edi),%eax
f010090a:	89 45 bc             	mov    %eax,-0x44(%ebp)
		cprintf("  ebp %08x eip %08x ", curr_ebp, eip);
f010090d:	83 ec 04             	sub    $0x4,%esp
f0100910:	50                   	push   %eax
f0100911:	57                   	push   %edi
f0100912:	ff 75 b8             	pushl  -0x48(%ebp)
f0100915:	e8 72 02 00 00       	call   f0100b8c <cprintf>
		cprintf("args");
f010091a:	83 c4 04             	add    $0x4,%esp
f010091d:	ff 75 b4             	pushl  -0x4c(%ebp)
f0100920:	e8 67 02 00 00       	call   f0100b8c <cprintf>
		int *arg_p = curr_ebp + 2;
f0100925:	8d 77 08             	lea    0x8(%edi),%esi
f0100928:	8d 47 1c             	lea    0x1c(%edi),%eax
f010092b:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f010092e:	83 c4 10             	add    $0x10,%esp
		for (int i = 0; i < 5; ++i) {
			cprintf(" %08x", *arg_p);
f0100931:	8d bb 3c 0c ff ff    	lea    -0xf3c4(%ebx),%edi
f0100937:	83 ec 08             	sub    $0x8,%esp
f010093a:	ff 36                	pushl  (%esi)
f010093c:	57                   	push   %edi
f010093d:	e8 4a 02 00 00       	call   f0100b8c <cprintf>
			++arg_p;
f0100942:	83 c6 04             	add    $0x4,%esi
		for (int i = 0; i < 5; ++i) {
f0100945:	83 c4 10             	add    $0x10,%esp
f0100948:	39 75 c4             	cmp    %esi,-0x3c(%ebp)
f010094b:	75 ea                	jne    f0100937 <mon_backtrace+0x6c>
		}

		cprintf("\n");
f010094d:	83 ec 0c             	sub    $0xc,%esp
f0100950:	8d 83 81 09 ff ff    	lea    -0xf67f(%ebx),%eax
f0100956:	50                   	push   %eax
f0100957:	e8 30 02 00 00       	call   f0100b8c <cprintf>

		// debugging info
		struct Eipdebuginfo info;
		debuginfo_eip(eip, &info);
f010095c:	83 c4 08             	add    $0x8,%esp
f010095f:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100962:	50                   	push   %eax
f0100963:	8b 7d bc             	mov    -0x44(%ebp),%edi
f0100966:	57                   	push   %edi
f0100967:	e8 24 03 00 00       	call   f0100c90 <debuginfo_eip>
		cprintf("        ");
f010096c:	8d 83 42 0c ff ff    	lea    -0xf3be(%ebx),%eax
f0100972:	89 04 24             	mov    %eax,(%esp)
f0100975:	e8 12 02 00 00       	call   f0100b8c <cprintf>
		cprintf("%s:%d: ", info.eip_file, info.eip_line);
f010097a:	83 c4 0c             	add    $0xc,%esp
f010097d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100980:	ff 75 d0             	pushl  -0x30(%ebp)
f0100983:	8d 83 55 09 ff ff    	lea    -0xf6ab(%ebx),%eax
f0100989:	50                   	push   %eax
f010098a:	e8 fd 01 00 00       	call   f0100b8c <cprintf>
		cprintf("%.*s", info.eip_fn_namelen, info.eip_fn_name);
f010098f:	83 c4 0c             	add    $0xc,%esp
f0100992:	ff 75 d8             	pushl  -0x28(%ebp)
f0100995:	ff 75 dc             	pushl  -0x24(%ebp)
f0100998:	8d 83 4b 0c ff ff    	lea    -0xf3b5(%ebx),%eax
f010099e:	50                   	push   %eax
f010099f:	e8 e8 01 00 00       	call   f0100b8c <cprintf>
		cprintf("+%d\n", eip - (uint32_t)info.eip_fn_addr);
f01009a4:	83 c4 08             	add    $0x8,%esp
f01009a7:	89 f8                	mov    %edi,%eax
f01009a9:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01009ac:	50                   	push   %eax
f01009ad:	8d 83 50 0c ff ff    	lea    -0xf3b0(%ebx),%eax
f01009b3:	50                   	push   %eax
f01009b4:	e8 d3 01 00 00       	call   f0100b8c <cprintf>

		// Check ending
		if (prev_ebp == 0) {
f01009b9:	83 c4 10             	add    $0x10,%esp
f01009bc:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01009bf:	85 ff                	test   %edi,%edi
f01009c1:	0f 85 3b ff ff ff    	jne    f0100902 <mon_backtrace+0x37>
		} else {
			curr_ebp = prev_ebp;
		}
	}
	return 0;
}
f01009c7:	b8 00 00 00 00       	mov    $0x0,%eax
f01009cc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01009cf:	5b                   	pop    %ebx
f01009d0:	5e                   	pop    %esi
f01009d1:	5f                   	pop    %edi
f01009d2:	5d                   	pop    %ebp
f01009d3:	c3                   	ret    

f01009d4 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01009d4:	55                   	push   %ebp
f01009d5:	89 e5                	mov    %esp,%ebp
f01009d7:	57                   	push   %edi
f01009d8:	56                   	push   %esi
f01009d9:	53                   	push   %ebx
f01009da:	83 ec 68             	sub    $0x68,%esp
f01009dd:	e8 0b f8 ff ff       	call   f01001ed <__x86.get_pc_thunk.bx>
f01009e2:	81 c3 26 09 01 00    	add    $0x10926,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01009e8:	8d 83 d4 0d ff ff    	lea    -0xf22c(%ebx),%eax
f01009ee:	50                   	push   %eax
f01009ef:	e8 98 01 00 00       	call   f0100b8c <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01009f4:	8d 83 f8 0d ff ff    	lea    -0xf208(%ebx),%eax
f01009fa:	89 04 24             	mov    %eax,(%esp)
f01009fd:	e8 8a 01 00 00       	call   f0100b8c <cprintf>
f0100a02:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100a05:	8d bb 59 0c ff ff    	lea    -0xf3a7(%ebx),%edi
f0100a0b:	eb 4a                	jmp    f0100a57 <monitor+0x83>
f0100a0d:	83 ec 08             	sub    $0x8,%esp
f0100a10:	0f be c0             	movsbl %al,%eax
f0100a13:	50                   	push   %eax
f0100a14:	57                   	push   %edi
f0100a15:	e8 49 0d 00 00       	call   f0101763 <strchr>
f0100a1a:	83 c4 10             	add    $0x10,%esp
f0100a1d:	85 c0                	test   %eax,%eax
f0100a1f:	74 08                	je     f0100a29 <monitor+0x55>
			*buf++ = 0;
f0100a21:	c6 06 00             	movb   $0x0,(%esi)
f0100a24:	8d 76 01             	lea    0x1(%esi),%esi
f0100a27:	eb 79                	jmp    f0100aa2 <monitor+0xce>
		if (*buf == 0)
f0100a29:	80 3e 00             	cmpb   $0x0,(%esi)
f0100a2c:	74 7f                	je     f0100aad <monitor+0xd9>
		if (argc == MAXARGS-1) {
f0100a2e:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f0100a32:	74 0f                	je     f0100a43 <monitor+0x6f>
		argv[argc++] = buf;
f0100a34:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100a37:	8d 48 01             	lea    0x1(%eax),%ecx
f0100a3a:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f0100a3d:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
f0100a41:	eb 44                	jmp    f0100a87 <monitor+0xb3>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100a43:	83 ec 08             	sub    $0x8,%esp
f0100a46:	6a 10                	push   $0x10
f0100a48:	8d 83 5e 0c ff ff    	lea    -0xf3a2(%ebx),%eax
f0100a4e:	50                   	push   %eax
f0100a4f:	e8 38 01 00 00       	call   f0100b8c <cprintf>
f0100a54:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100a57:	8d 83 55 0c ff ff    	lea    -0xf3ab(%ebx),%eax
f0100a5d:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f0100a60:	83 ec 0c             	sub    $0xc,%esp
f0100a63:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100a66:	e8 c0 0a 00 00       	call   f010152b <readline>
f0100a6b:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f0100a6d:	83 c4 10             	add    $0x10,%esp
f0100a70:	85 c0                	test   %eax,%eax
f0100a72:	74 ec                	je     f0100a60 <monitor+0x8c>
	argv[argc] = 0;
f0100a74:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100a7b:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f0100a82:	eb 1e                	jmp    f0100aa2 <monitor+0xce>
			buf++;
f0100a84:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a87:	0f b6 06             	movzbl (%esi),%eax
f0100a8a:	84 c0                	test   %al,%al
f0100a8c:	74 14                	je     f0100aa2 <monitor+0xce>
f0100a8e:	83 ec 08             	sub    $0x8,%esp
f0100a91:	0f be c0             	movsbl %al,%eax
f0100a94:	50                   	push   %eax
f0100a95:	57                   	push   %edi
f0100a96:	e8 c8 0c 00 00       	call   f0101763 <strchr>
f0100a9b:	83 c4 10             	add    $0x10,%esp
f0100a9e:	85 c0                	test   %eax,%eax
f0100aa0:	74 e2                	je     f0100a84 <monitor+0xb0>
		while (*buf && strchr(WHITESPACE, *buf))
f0100aa2:	0f b6 06             	movzbl (%esi),%eax
f0100aa5:	84 c0                	test   %al,%al
f0100aa7:	0f 85 60 ff ff ff    	jne    f0100a0d <monitor+0x39>
	argv[argc] = 0;
f0100aad:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100ab0:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f0100ab7:	00 
	if (argc == 0)
f0100ab8:	85 c0                	test   %eax,%eax
f0100aba:	74 9b                	je     f0100a57 <monitor+0x83>
f0100abc:	8d b3 18 1d 00 00    	lea    0x1d18(%ebx),%esi
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100ac2:	c7 45 a0 00 00 00 00 	movl   $0x0,-0x60(%ebp)
		if (strcmp(argv[0], commands[i].name) == 0)
f0100ac9:	83 ec 08             	sub    $0x8,%esp
f0100acc:	ff 36                	pushl  (%esi)
f0100ace:	ff 75 a8             	pushl  -0x58(%ebp)
f0100ad1:	e8 2f 0c 00 00       	call   f0101705 <strcmp>
f0100ad6:	83 c4 10             	add    $0x10,%esp
f0100ad9:	85 c0                	test   %eax,%eax
f0100adb:	74 29                	je     f0100b06 <monitor+0x132>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100add:	83 45 a0 01          	addl   $0x1,-0x60(%ebp)
f0100ae1:	8b 45 a0             	mov    -0x60(%ebp),%eax
f0100ae4:	83 c6 0c             	add    $0xc,%esi
f0100ae7:	83 f8 03             	cmp    $0x3,%eax
f0100aea:	75 dd                	jne    f0100ac9 <monitor+0xf5>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100aec:	83 ec 08             	sub    $0x8,%esp
f0100aef:	ff 75 a8             	pushl  -0x58(%ebp)
f0100af2:	8d 83 7b 0c ff ff    	lea    -0xf385(%ebx),%eax
f0100af8:	50                   	push   %eax
f0100af9:	e8 8e 00 00 00       	call   f0100b8c <cprintf>
f0100afe:	83 c4 10             	add    $0x10,%esp
f0100b01:	e9 51 ff ff ff       	jmp    f0100a57 <monitor+0x83>
			return commands[i].func(argc, argv, tf);
f0100b06:	83 ec 04             	sub    $0x4,%esp
f0100b09:	8b 45 a0             	mov    -0x60(%ebp),%eax
f0100b0c:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100b0f:	ff 75 08             	pushl  0x8(%ebp)
f0100b12:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100b15:	52                   	push   %edx
f0100b16:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100b19:	ff 94 83 20 1d 00 00 	call   *0x1d20(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100b20:	83 c4 10             	add    $0x10,%esp
f0100b23:	85 c0                	test   %eax,%eax
f0100b25:	0f 89 2c ff ff ff    	jns    f0100a57 <monitor+0x83>
				break;
	}
}
f0100b2b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100b2e:	5b                   	pop    %ebx
f0100b2f:	5e                   	pop    %esi
f0100b30:	5f                   	pop    %edi
f0100b31:	5d                   	pop    %ebp
f0100b32:	c3                   	ret    

f0100b33 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100b33:	55                   	push   %ebp
f0100b34:	89 e5                	mov    %esp,%ebp
f0100b36:	53                   	push   %ebx
f0100b37:	83 ec 10             	sub    $0x10,%esp
f0100b3a:	e8 ae f6 ff ff       	call   f01001ed <__x86.get_pc_thunk.bx>
f0100b3f:	81 c3 c9 07 01 00    	add    $0x107c9,%ebx
	cputchar(ch);
f0100b45:	ff 75 08             	pushl  0x8(%ebp)
f0100b48:	e8 17 fc ff ff       	call   f0100764 <cputchar>
	*cnt++;
}
f0100b4d:	83 c4 10             	add    $0x10,%esp
f0100b50:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100b53:	c9                   	leave  
f0100b54:	c3                   	ret    

f0100b55 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100b55:	55                   	push   %ebp
f0100b56:	89 e5                	mov    %esp,%ebp
f0100b58:	53                   	push   %ebx
f0100b59:	83 ec 14             	sub    $0x14,%esp
f0100b5c:	e8 8c f6 ff ff       	call   f01001ed <__x86.get_pc_thunk.bx>
f0100b61:	81 c3 a7 07 01 00    	add    $0x107a7,%ebx
	int cnt = 0;
f0100b67:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100b6e:	ff 75 0c             	pushl  0xc(%ebp)
f0100b71:	ff 75 08             	pushl  0x8(%ebp)
f0100b74:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100b77:	50                   	push   %eax
f0100b78:	8d 83 2b f8 fe ff    	lea    -0x107d5(%ebx),%eax
f0100b7e:	50                   	push   %eax
f0100b7f:	e8 98 04 00 00       	call   f010101c <vprintfmt>
	return cnt;
}
f0100b84:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100b87:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100b8a:	c9                   	leave  
f0100b8b:	c3                   	ret    

f0100b8c <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100b8c:	55                   	push   %ebp
f0100b8d:	89 e5                	mov    %esp,%ebp
f0100b8f:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100b92:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100b95:	50                   	push   %eax
f0100b96:	ff 75 08             	pushl  0x8(%ebp)
f0100b99:	e8 b7 ff ff ff       	call   f0100b55 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100b9e:	c9                   	leave  
f0100b9f:	c3                   	ret    

f0100ba0 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100ba0:	55                   	push   %ebp
f0100ba1:	89 e5                	mov    %esp,%ebp
f0100ba3:	57                   	push   %edi
f0100ba4:	56                   	push   %esi
f0100ba5:	53                   	push   %ebx
f0100ba6:	83 ec 14             	sub    $0x14,%esp
f0100ba9:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100bac:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100baf:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100bb2:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100bb5:	8b 32                	mov    (%edx),%esi
f0100bb7:	8b 01                	mov    (%ecx),%eax
f0100bb9:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100bbc:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100bc3:	eb 2f                	jmp    f0100bf4 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0100bc5:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0100bc8:	39 c6                	cmp    %eax,%esi
f0100bca:	7f 49                	jg     f0100c15 <stab_binsearch+0x75>
f0100bcc:	0f b6 0a             	movzbl (%edx),%ecx
f0100bcf:	83 ea 0c             	sub    $0xc,%edx
f0100bd2:	39 f9                	cmp    %edi,%ecx
f0100bd4:	75 ef                	jne    f0100bc5 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100bd6:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100bd9:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100bdc:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100be0:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100be3:	73 35                	jae    f0100c1a <stab_binsearch+0x7a>
			*region_left = m;
f0100be5:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100be8:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0100bea:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f0100bed:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0100bf4:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0100bf7:	7f 4e                	jg     f0100c47 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0100bf9:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100bfc:	01 f0                	add    %esi,%eax
f0100bfe:	89 c3                	mov    %eax,%ebx
f0100c00:	c1 eb 1f             	shr    $0x1f,%ebx
f0100c03:	01 c3                	add    %eax,%ebx
f0100c05:	d1 fb                	sar    %ebx
f0100c07:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100c0a:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100c0d:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0100c11:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0100c13:	eb b3                	jmp    f0100bc8 <stab_binsearch+0x28>
			l = true_m + 1;
f0100c15:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0100c18:	eb da                	jmp    f0100bf4 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0100c1a:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100c1d:	76 14                	jbe    f0100c33 <stab_binsearch+0x93>
			*region_right = m - 1;
f0100c1f:	83 e8 01             	sub    $0x1,%eax
f0100c22:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100c25:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100c28:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0100c2a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100c31:	eb c1                	jmp    f0100bf4 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100c33:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100c36:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100c38:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100c3c:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f0100c3e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100c45:	eb ad                	jmp    f0100bf4 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0100c47:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100c4b:	74 16                	je     f0100c63 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100c4d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c50:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100c52:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100c55:	8b 0e                	mov    (%esi),%ecx
f0100c57:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100c5a:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100c5d:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f0100c61:	eb 12                	jmp    f0100c75 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0100c63:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c66:	8b 00                	mov    (%eax),%eax
f0100c68:	83 e8 01             	sub    $0x1,%eax
f0100c6b:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100c6e:	89 07                	mov    %eax,(%edi)
f0100c70:	eb 16                	jmp    f0100c88 <stab_binsearch+0xe8>
		     l--)
f0100c72:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0100c75:	39 c1                	cmp    %eax,%ecx
f0100c77:	7d 0a                	jge    f0100c83 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0100c79:	0f b6 1a             	movzbl (%edx),%ebx
f0100c7c:	83 ea 0c             	sub    $0xc,%edx
f0100c7f:	39 fb                	cmp    %edi,%ebx
f0100c81:	75 ef                	jne    f0100c72 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f0100c83:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100c86:	89 07                	mov    %eax,(%edi)
	}
}
f0100c88:	83 c4 14             	add    $0x14,%esp
f0100c8b:	5b                   	pop    %ebx
f0100c8c:	5e                   	pop    %esi
f0100c8d:	5f                   	pop    %edi
f0100c8e:	5d                   	pop    %ebp
f0100c8f:	c3                   	ret    

f0100c90 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100c90:	55                   	push   %ebp
f0100c91:	89 e5                	mov    %esp,%ebp
f0100c93:	57                   	push   %edi
f0100c94:	56                   	push   %esi
f0100c95:	53                   	push   %ebx
f0100c96:	83 ec 3c             	sub    $0x3c,%esp
f0100c99:	e8 4f f5 ff ff       	call   f01001ed <__x86.get_pc_thunk.bx>
f0100c9e:	81 c3 6a 06 01 00    	add    $0x1066a,%ebx
f0100ca4:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100ca7:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100caa:	8d 83 20 0e ff ff    	lea    -0xf1e0(%ebx),%eax
f0100cb0:	89 06                	mov    %eax,(%esi)
	info->eip_line = 0;
f0100cb2:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0100cb9:	89 46 08             	mov    %eax,0x8(%esi)
	info->eip_fn_namelen = 9;
f0100cbc:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f0100cc3:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0100cc6:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100ccd:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f0100cd3:	0f 86 37 01 00 00    	jbe    f0100e10 <debuginfo_eip+0x180>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100cd9:	c7 c0 09 61 10 f0    	mov    $0xf0106109,%eax
f0100cdf:	39 83 fc ff ff ff    	cmp    %eax,-0x4(%ebx)
f0100ce5:	0f 86 04 02 00 00    	jbe    f0100eef <debuginfo_eip+0x25f>
f0100ceb:	c7 c0 a1 7a 10 f0    	mov    $0xf0107aa1,%eax
f0100cf1:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0100cf5:	0f 85 fb 01 00 00    	jne    f0100ef6 <debuginfo_eip+0x266>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100cfb:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100d02:	c7 c0 40 23 10 f0    	mov    $0xf0102340,%eax
f0100d08:	c7 c2 08 61 10 f0    	mov    $0xf0106108,%edx
f0100d0e:	29 c2                	sub    %eax,%edx
f0100d10:	c1 fa 02             	sar    $0x2,%edx
f0100d13:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0100d19:	83 ea 01             	sub    $0x1,%edx
f0100d1c:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100d1f:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100d22:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100d25:	83 ec 08             	sub    $0x8,%esp
f0100d28:	57                   	push   %edi
f0100d29:	6a 64                	push   $0x64
f0100d2b:	e8 70 fe ff ff       	call   f0100ba0 <stab_binsearch>
	if (lfile == 0)
f0100d30:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d33:	83 c4 10             	add    $0x10,%esp
f0100d36:	85 c0                	test   %eax,%eax
f0100d38:	0f 84 bf 01 00 00    	je     f0100efd <debuginfo_eip+0x26d>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100d3e:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100d41:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100d44:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100d47:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100d4a:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100d4d:	83 ec 08             	sub    $0x8,%esp
f0100d50:	57                   	push   %edi
f0100d51:	6a 24                	push   $0x24
f0100d53:	c7 c0 40 23 10 f0    	mov    $0xf0102340,%eax
f0100d59:	e8 42 fe ff ff       	call   f0100ba0 <stab_binsearch>

	if (lfun <= rfun) {
f0100d5e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100d61:	8b 4d d8             	mov    -0x28(%ebp),%ecx
f0100d64:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
f0100d67:	83 c4 10             	add    $0x10,%esp
f0100d6a:	39 c8                	cmp    %ecx,%eax
f0100d6c:	0f 8f b6 00 00 00    	jg     f0100e28 <debuginfo_eip+0x198>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100d72:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100d75:	c7 c1 40 23 10 f0    	mov    $0xf0102340,%ecx
f0100d7b:	8d 0c 91             	lea    (%ecx,%edx,4),%ecx
f0100d7e:	8b 11                	mov    (%ecx),%edx
f0100d80:	89 55 c0             	mov    %edx,-0x40(%ebp)
f0100d83:	c7 c2 a1 7a 10 f0    	mov    $0xf0107aa1,%edx
f0100d89:	81 ea 09 61 10 f0    	sub    $0xf0106109,%edx
f0100d8f:	39 55 c0             	cmp    %edx,-0x40(%ebp)
f0100d92:	73 0c                	jae    f0100da0 <debuginfo_eip+0x110>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100d94:	8b 55 c0             	mov    -0x40(%ebp),%edx
f0100d97:	81 c2 09 61 10 f0    	add    $0xf0106109,%edx
f0100d9d:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100da0:	8b 51 08             	mov    0x8(%ecx),%edx
f0100da3:	89 56 10             	mov    %edx,0x10(%esi)
		addr -= info->eip_fn_addr;
f0100da6:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0100da8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100dab:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100dae:	89 45 d0             	mov    %eax,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100db1:	83 ec 08             	sub    $0x8,%esp
f0100db4:	6a 3a                	push   $0x3a
f0100db6:	ff 76 08             	pushl  0x8(%esi)
f0100db9:	e8 c6 09 00 00       	call   f0101784 <strfind>
f0100dbe:	2b 46 08             	sub    0x8(%esi),%eax
f0100dc1:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100dc4:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100dc7:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100dca:	83 c4 08             	add    $0x8,%esp
f0100dcd:	57                   	push   %edi
f0100dce:	6a 44                	push   $0x44
f0100dd0:	c7 c0 40 23 10 f0    	mov    $0xf0102340,%eax
f0100dd6:	e8 c5 fd ff ff       	call   f0100ba0 <stab_binsearch>
	if (lline <= rline) {
f0100ddb:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0100dde:	83 c4 10             	add    $0x10,%esp
f0100de1:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0100de4:	0f 8f 1a 01 00 00    	jg     f0100f04 <debuginfo_eip+0x274>
        info->eip_line = stabs[lline].n_desc;
f0100dea:	89 d0                	mov    %edx,%eax
f0100dec:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100def:	c1 e2 02             	shl    $0x2,%edx
f0100df2:	c7 c1 40 23 10 f0    	mov    $0xf0102340,%ecx
f0100df8:	0f b7 7c 0a 06       	movzwl 0x6(%edx,%ecx,1),%edi
f0100dfd:	89 7e 04             	mov    %edi,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100e00:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100e03:	8d 54 0a 04          	lea    0x4(%edx,%ecx,1),%edx
f0100e07:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0100e0b:	89 75 0c             	mov    %esi,0xc(%ebp)
f0100e0e:	eb 36                	jmp    f0100e46 <debuginfo_eip+0x1b6>
  	        panic("User address");
f0100e10:	83 ec 04             	sub    $0x4,%esp
f0100e13:	8d 83 2a 0e ff ff    	lea    -0xf1d6(%ebx),%eax
f0100e19:	50                   	push   %eax
f0100e1a:	6a 7f                	push   $0x7f
f0100e1c:	8d 83 37 0e ff ff    	lea    -0xf1c9(%ebx),%eax
f0100e22:	50                   	push   %eax
f0100e23:	e8 0f f3 ff ff       	call   f0100137 <_panic>
		info->eip_fn_addr = addr;
f0100e28:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0100e2b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e2e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100e31:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e34:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100e37:	e9 75 ff ff ff       	jmp    f0100db1 <debuginfo_eip+0x121>
f0100e3c:	83 e8 01             	sub    $0x1,%eax
f0100e3f:	83 ea 0c             	sub    $0xc,%edx
f0100e42:	c6 45 c4 01          	movb   $0x1,-0x3c(%ebp)
f0100e46:	89 45 c0             	mov    %eax,-0x40(%ebp)
	while (lline >= lfile
f0100e49:	39 c7                	cmp    %eax,%edi
f0100e4b:	7f 24                	jg     f0100e71 <debuginfo_eip+0x1e1>
	       && stabs[lline].n_type != N_SOL
f0100e4d:	0f b6 0a             	movzbl (%edx),%ecx
f0100e50:	80 f9 84             	cmp    $0x84,%cl
f0100e53:	74 46                	je     f0100e9b <debuginfo_eip+0x20b>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100e55:	80 f9 64             	cmp    $0x64,%cl
f0100e58:	75 e2                	jne    f0100e3c <debuginfo_eip+0x1ac>
f0100e5a:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f0100e5e:	74 dc                	je     f0100e3c <debuginfo_eip+0x1ac>
f0100e60:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100e63:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0100e67:	74 3b                	je     f0100ea4 <debuginfo_eip+0x214>
f0100e69:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0100e6c:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100e6f:	eb 33                	jmp    f0100ea4 <debuginfo_eip+0x214>
f0100e71:	8b 75 0c             	mov    0xc(%ebp),%esi
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100e74:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100e77:	8b 7d d8             	mov    -0x28(%ebp),%edi
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100e7a:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0100e7f:	39 fa                	cmp    %edi,%edx
f0100e81:	0f 8d 89 00 00 00    	jge    f0100f10 <debuginfo_eip+0x280>
		for (lline = lfun + 1;
f0100e87:	83 c2 01             	add    $0x1,%edx
f0100e8a:	89 d0                	mov    %edx,%eax
f0100e8c:	8d 0c 52             	lea    (%edx,%edx,2),%ecx
f0100e8f:	c7 c2 40 23 10 f0    	mov    $0xf0102340,%edx
f0100e95:	8d 54 8a 04          	lea    0x4(%edx,%ecx,4),%edx
f0100e99:	eb 3b                	jmp    f0100ed6 <debuginfo_eip+0x246>
f0100e9b:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100e9e:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0100ea2:	75 26                	jne    f0100eca <debuginfo_eip+0x23a>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100ea4:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100ea7:	c7 c0 40 23 10 f0    	mov    $0xf0102340,%eax
f0100ead:	8b 14 90             	mov    (%eax,%edx,4),%edx
f0100eb0:	c7 c0 a1 7a 10 f0    	mov    $0xf0107aa1,%eax
f0100eb6:	81 e8 09 61 10 f0    	sub    $0xf0106109,%eax
f0100ebc:	39 c2                	cmp    %eax,%edx
f0100ebe:	73 b4                	jae    f0100e74 <debuginfo_eip+0x1e4>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100ec0:	81 c2 09 61 10 f0    	add    $0xf0106109,%edx
f0100ec6:	89 16                	mov    %edx,(%esi)
f0100ec8:	eb aa                	jmp    f0100e74 <debuginfo_eip+0x1e4>
f0100eca:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0100ecd:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0100ed0:	eb d2                	jmp    f0100ea4 <debuginfo_eip+0x214>
			info->eip_fn_narg++;
f0100ed2:	83 46 14 01          	addl   $0x1,0x14(%esi)
		for (lline = lfun + 1;
f0100ed6:	39 c7                	cmp    %eax,%edi
f0100ed8:	7e 31                	jle    f0100f0b <debuginfo_eip+0x27b>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100eda:	0f b6 0a             	movzbl (%edx),%ecx
f0100edd:	83 c0 01             	add    $0x1,%eax
f0100ee0:	83 c2 0c             	add    $0xc,%edx
f0100ee3:	80 f9 a0             	cmp    $0xa0,%cl
f0100ee6:	74 ea                	je     f0100ed2 <debuginfo_eip+0x242>
	return 0;
f0100ee8:	b8 00 00 00 00       	mov    $0x0,%eax
f0100eed:	eb 21                	jmp    f0100f10 <debuginfo_eip+0x280>
		return -1;
f0100eef:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ef4:	eb 1a                	jmp    f0100f10 <debuginfo_eip+0x280>
f0100ef6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100efb:	eb 13                	jmp    f0100f10 <debuginfo_eip+0x280>
		return -1;
f0100efd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100f02:	eb 0c                	jmp    f0100f10 <debuginfo_eip+0x280>
        return -1;
f0100f04:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100f09:	eb 05                	jmp    f0100f10 <debuginfo_eip+0x280>
	return 0;
f0100f0b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100f10:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100f13:	5b                   	pop    %ebx
f0100f14:	5e                   	pop    %esi
f0100f15:	5f                   	pop    %edi
f0100f16:	5d                   	pop    %ebp
f0100f17:	c3                   	ret    

f0100f18 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100f18:	55                   	push   %ebp
f0100f19:	89 e5                	mov    %esp,%ebp
f0100f1b:	57                   	push   %edi
f0100f1c:	56                   	push   %esi
f0100f1d:	53                   	push   %ebx
f0100f1e:	83 ec 2c             	sub    $0x2c,%esp
f0100f21:	e8 01 06 00 00       	call   f0101527 <__x86.get_pc_thunk.cx>
f0100f26:	81 c1 e2 03 01 00    	add    $0x103e2,%ecx
f0100f2c:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100f2f:	89 c7                	mov    %eax,%edi
f0100f31:	89 d6                	mov    %edx,%esi
f0100f33:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f36:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100f39:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100f3c:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100f3f:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100f42:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100f47:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f0100f4a:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0100f4d:	39 d3                	cmp    %edx,%ebx
f0100f4f:	72 09                	jb     f0100f5a <printnum+0x42>
f0100f51:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100f54:	0f 87 83 00 00 00    	ja     f0100fdd <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100f5a:	83 ec 0c             	sub    $0xc,%esp
f0100f5d:	ff 75 18             	pushl  0x18(%ebp)
f0100f60:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f63:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100f66:	53                   	push   %ebx
f0100f67:	ff 75 10             	pushl  0x10(%ebp)
f0100f6a:	83 ec 08             	sub    $0x8,%esp
f0100f6d:	ff 75 dc             	pushl  -0x24(%ebp)
f0100f70:	ff 75 d8             	pushl  -0x28(%ebp)
f0100f73:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100f76:	ff 75 d0             	pushl  -0x30(%ebp)
f0100f79:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100f7c:	e8 1f 0a 00 00       	call   f01019a0 <__udivdi3>
f0100f81:	83 c4 18             	add    $0x18,%esp
f0100f84:	52                   	push   %edx
f0100f85:	50                   	push   %eax
f0100f86:	89 f2                	mov    %esi,%edx
f0100f88:	89 f8                	mov    %edi,%eax
f0100f8a:	e8 89 ff ff ff       	call   f0100f18 <printnum>
f0100f8f:	83 c4 20             	add    $0x20,%esp
f0100f92:	eb 13                	jmp    f0100fa7 <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100f94:	83 ec 08             	sub    $0x8,%esp
f0100f97:	56                   	push   %esi
f0100f98:	ff 75 18             	pushl  0x18(%ebp)
f0100f9b:	ff d7                	call   *%edi
f0100f9d:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0100fa0:	83 eb 01             	sub    $0x1,%ebx
f0100fa3:	85 db                	test   %ebx,%ebx
f0100fa5:	7f ed                	jg     f0100f94 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100fa7:	83 ec 08             	sub    $0x8,%esp
f0100faa:	56                   	push   %esi
f0100fab:	83 ec 04             	sub    $0x4,%esp
f0100fae:	ff 75 dc             	pushl  -0x24(%ebp)
f0100fb1:	ff 75 d8             	pushl  -0x28(%ebp)
f0100fb4:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100fb7:	ff 75 d0             	pushl  -0x30(%ebp)
f0100fba:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100fbd:	89 f3                	mov    %esi,%ebx
f0100fbf:	e8 fc 0a 00 00       	call   f0101ac0 <__umoddi3>
f0100fc4:	83 c4 14             	add    $0x14,%esp
f0100fc7:	0f be 84 06 45 0e ff 	movsbl -0xf1bb(%esi,%eax,1),%eax
f0100fce:	ff 
f0100fcf:	50                   	push   %eax
f0100fd0:	ff d7                	call   *%edi
}
f0100fd2:	83 c4 10             	add    $0x10,%esp
f0100fd5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100fd8:	5b                   	pop    %ebx
f0100fd9:	5e                   	pop    %esi
f0100fda:	5f                   	pop    %edi
f0100fdb:	5d                   	pop    %ebp
f0100fdc:	c3                   	ret    
f0100fdd:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100fe0:	eb be                	jmp    f0100fa0 <printnum+0x88>

f0100fe2 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100fe2:	55                   	push   %ebp
f0100fe3:	89 e5                	mov    %esp,%ebp
f0100fe5:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100fe8:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100fec:	8b 10                	mov    (%eax),%edx
f0100fee:	3b 50 04             	cmp    0x4(%eax),%edx
f0100ff1:	73 0a                	jae    f0100ffd <sprintputch+0x1b>
		*b->buf++ = ch;
f0100ff3:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100ff6:	89 08                	mov    %ecx,(%eax)
f0100ff8:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ffb:	88 02                	mov    %al,(%edx)
}
f0100ffd:	5d                   	pop    %ebp
f0100ffe:	c3                   	ret    

f0100fff <printfmt>:
{
f0100fff:	55                   	push   %ebp
f0101000:	89 e5                	mov    %esp,%ebp
f0101002:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0101005:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0101008:	50                   	push   %eax
f0101009:	ff 75 10             	pushl  0x10(%ebp)
f010100c:	ff 75 0c             	pushl  0xc(%ebp)
f010100f:	ff 75 08             	pushl  0x8(%ebp)
f0101012:	e8 05 00 00 00       	call   f010101c <vprintfmt>
}
f0101017:	83 c4 10             	add    $0x10,%esp
f010101a:	c9                   	leave  
f010101b:	c3                   	ret    

f010101c <vprintfmt>:
{
f010101c:	55                   	push   %ebp
f010101d:	89 e5                	mov    %esp,%ebp
f010101f:	57                   	push   %edi
f0101020:	56                   	push   %esi
f0101021:	53                   	push   %ebx
f0101022:	83 ec 2c             	sub    $0x2c,%esp
f0101025:	e8 c3 f1 ff ff       	call   f01001ed <__x86.get_pc_thunk.bx>
f010102a:	81 c3 de 02 01 00    	add    $0x102de,%ebx
f0101030:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101033:	8b 7d 10             	mov    0x10(%ebp),%edi
f0101036:	e9 63 03 00 00       	jmp    f010139e <.L34+0x40>
		padc = ' ';
f010103b:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f010103f:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0101046:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
		width = -1;
f010104d:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0101054:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101059:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010105c:	8d 47 01             	lea    0x1(%edi),%eax
f010105f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101062:	0f b6 17             	movzbl (%edi),%edx
f0101065:	8d 42 dd             	lea    -0x23(%edx),%eax
f0101068:	3c 55                	cmp    $0x55,%al
f010106a:	0f 87 15 04 00 00    	ja     f0101485 <.L22>
f0101070:	0f b6 c0             	movzbl %al,%eax
f0101073:	89 d9                	mov    %ebx,%ecx
f0101075:	03 8c 83 d0 0e ff ff 	add    -0xf130(%ebx,%eax,4),%ecx
f010107c:	ff e1                	jmp    *%ecx

f010107e <.L70>:
f010107e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0101081:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0101085:	eb d5                	jmp    f010105c <vprintfmt+0x40>

f0101087 <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f0101087:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f010108a:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f010108e:	eb cc                	jmp    f010105c <vprintfmt+0x40>

f0101090 <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f0101090:	0f b6 d2             	movzbl %dl,%edx
f0101093:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0101096:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f010109b:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010109e:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f01010a2:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f01010a5:	8d 4a d0             	lea    -0x30(%edx),%ecx
f01010a8:	83 f9 09             	cmp    $0x9,%ecx
f01010ab:	77 55                	ja     f0101102 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f01010ad:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f01010b0:	eb e9                	jmp    f010109b <.L29+0xb>

f01010b2 <.L26>:
			precision = va_arg(ap, int);
f01010b2:	8b 45 14             	mov    0x14(%ebp),%eax
f01010b5:	8b 00                	mov    (%eax),%eax
f01010b7:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01010ba:	8b 45 14             	mov    0x14(%ebp),%eax
f01010bd:	8d 40 04             	lea    0x4(%eax),%eax
f01010c0:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01010c3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f01010c6:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01010ca:	79 90                	jns    f010105c <vprintfmt+0x40>
				width = precision, precision = -1;
f01010cc:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01010cf:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01010d2:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f01010d9:	eb 81                	jmp    f010105c <vprintfmt+0x40>

f01010db <.L27>:
f01010db:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010de:	85 c0                	test   %eax,%eax
f01010e0:	ba 00 00 00 00       	mov    $0x0,%edx
f01010e5:	0f 49 d0             	cmovns %eax,%edx
f01010e8:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01010eb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01010ee:	e9 69 ff ff ff       	jmp    f010105c <vprintfmt+0x40>

f01010f3 <.L23>:
f01010f3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f01010f6:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f01010fd:	e9 5a ff ff ff       	jmp    f010105c <vprintfmt+0x40>
f0101102:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101105:	eb bf                	jmp    f01010c6 <.L26+0x14>

f0101107 <.L33>:
			lflag++;
f0101107:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f010110b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f010110e:	e9 49 ff ff ff       	jmp    f010105c <vprintfmt+0x40>

f0101113 <.L30>:
			putch(va_arg(ap, int), putdat);
f0101113:	8b 45 14             	mov    0x14(%ebp),%eax
f0101116:	8d 78 04             	lea    0x4(%eax),%edi
f0101119:	83 ec 08             	sub    $0x8,%esp
f010111c:	56                   	push   %esi
f010111d:	ff 30                	pushl  (%eax)
f010111f:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101122:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0101125:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0101128:	e9 6e 02 00 00       	jmp    f010139b <.L34+0x3d>

f010112d <.L32>:
			err = va_arg(ap, int);
f010112d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101130:	8d 78 04             	lea    0x4(%eax),%edi
f0101133:	8b 00                	mov    (%eax),%eax
f0101135:	99                   	cltd   
f0101136:	31 d0                	xor    %edx,%eax
f0101138:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010113a:	83 f8 06             	cmp    $0x6,%eax
f010113d:	7f 27                	jg     f0101166 <.L32+0x39>
f010113f:	8b 94 83 3c 1d 00 00 	mov    0x1d3c(%ebx,%eax,4),%edx
f0101146:	85 d2                	test   %edx,%edx
f0101148:	74 1c                	je     f0101166 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f010114a:	52                   	push   %edx
f010114b:	8d 83 42 09 ff ff    	lea    -0xf6be(%ebx),%eax
f0101151:	50                   	push   %eax
f0101152:	56                   	push   %esi
f0101153:	ff 75 08             	pushl  0x8(%ebp)
f0101156:	e8 a4 fe ff ff       	call   f0100fff <printfmt>
f010115b:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f010115e:	89 7d 14             	mov    %edi,0x14(%ebp)
f0101161:	e9 35 02 00 00       	jmp    f010139b <.L34+0x3d>
				printfmt(putch, putdat, "error %d", err);
f0101166:	50                   	push   %eax
f0101167:	8d 83 5d 0e ff ff    	lea    -0xf1a3(%ebx),%eax
f010116d:	50                   	push   %eax
f010116e:	56                   	push   %esi
f010116f:	ff 75 08             	pushl  0x8(%ebp)
f0101172:	e8 88 fe ff ff       	call   f0100fff <printfmt>
f0101177:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f010117a:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f010117d:	e9 19 02 00 00       	jmp    f010139b <.L34+0x3d>

f0101182 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f0101182:	8b 45 14             	mov    0x14(%ebp),%eax
f0101185:	83 c0 04             	add    $0x4,%eax
f0101188:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010118b:	8b 45 14             	mov    0x14(%ebp),%eax
f010118e:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101190:	85 ff                	test   %edi,%edi
f0101192:	8d 83 56 0e ff ff    	lea    -0xf1aa(%ebx),%eax
f0101198:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f010119b:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f010119f:	0f 8e b5 00 00 00    	jle    f010125a <.L36+0xd8>
f01011a5:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f01011a9:	75 08                	jne    f01011b3 <.L36+0x31>
f01011ab:	89 75 0c             	mov    %esi,0xc(%ebp)
f01011ae:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01011b1:	eb 6d                	jmp    f0101220 <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f01011b3:	83 ec 08             	sub    $0x8,%esp
f01011b6:	ff 75 cc             	pushl  -0x34(%ebp)
f01011b9:	57                   	push   %edi
f01011ba:	e8 81 04 00 00       	call   f0101640 <strnlen>
f01011bf:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01011c2:	29 c2                	sub    %eax,%edx
f01011c4:	89 55 c8             	mov    %edx,-0x38(%ebp)
f01011c7:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f01011ca:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f01011ce:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01011d1:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01011d4:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f01011d6:	eb 10                	jmp    f01011e8 <.L36+0x66>
					putch(padc, putdat);
f01011d8:	83 ec 08             	sub    $0x8,%esp
f01011db:	56                   	push   %esi
f01011dc:	ff 75 e0             	pushl  -0x20(%ebp)
f01011df:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f01011e2:	83 ef 01             	sub    $0x1,%edi
f01011e5:	83 c4 10             	add    $0x10,%esp
f01011e8:	85 ff                	test   %edi,%edi
f01011ea:	7f ec                	jg     f01011d8 <.L36+0x56>
f01011ec:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01011ef:	8b 55 c8             	mov    -0x38(%ebp),%edx
f01011f2:	85 d2                	test   %edx,%edx
f01011f4:	b8 00 00 00 00       	mov    $0x0,%eax
f01011f9:	0f 49 c2             	cmovns %edx,%eax
f01011fc:	29 c2                	sub    %eax,%edx
f01011fe:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101201:	89 75 0c             	mov    %esi,0xc(%ebp)
f0101204:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0101207:	eb 17                	jmp    f0101220 <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f0101209:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010120d:	75 30                	jne    f010123f <.L36+0xbd>
					putch(ch, putdat);
f010120f:	83 ec 08             	sub    $0x8,%esp
f0101212:	ff 75 0c             	pushl  0xc(%ebp)
f0101215:	50                   	push   %eax
f0101216:	ff 55 08             	call   *0x8(%ebp)
f0101219:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010121c:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f0101220:	83 c7 01             	add    $0x1,%edi
f0101223:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0101227:	0f be c2             	movsbl %dl,%eax
f010122a:	85 c0                	test   %eax,%eax
f010122c:	74 52                	je     f0101280 <.L36+0xfe>
f010122e:	85 f6                	test   %esi,%esi
f0101230:	78 d7                	js     f0101209 <.L36+0x87>
f0101232:	83 ee 01             	sub    $0x1,%esi
f0101235:	79 d2                	jns    f0101209 <.L36+0x87>
f0101237:	8b 75 0c             	mov    0xc(%ebp),%esi
f010123a:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010123d:	eb 32                	jmp    f0101271 <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f010123f:	0f be d2             	movsbl %dl,%edx
f0101242:	83 ea 20             	sub    $0x20,%edx
f0101245:	83 fa 5e             	cmp    $0x5e,%edx
f0101248:	76 c5                	jbe    f010120f <.L36+0x8d>
					putch('?', putdat);
f010124a:	83 ec 08             	sub    $0x8,%esp
f010124d:	ff 75 0c             	pushl  0xc(%ebp)
f0101250:	6a 3f                	push   $0x3f
f0101252:	ff 55 08             	call   *0x8(%ebp)
f0101255:	83 c4 10             	add    $0x10,%esp
f0101258:	eb c2                	jmp    f010121c <.L36+0x9a>
f010125a:	89 75 0c             	mov    %esi,0xc(%ebp)
f010125d:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0101260:	eb be                	jmp    f0101220 <.L36+0x9e>
				putch(' ', putdat);
f0101262:	83 ec 08             	sub    $0x8,%esp
f0101265:	56                   	push   %esi
f0101266:	6a 20                	push   $0x20
f0101268:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f010126b:	83 ef 01             	sub    $0x1,%edi
f010126e:	83 c4 10             	add    $0x10,%esp
f0101271:	85 ff                	test   %edi,%edi
f0101273:	7f ed                	jg     f0101262 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f0101275:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101278:	89 45 14             	mov    %eax,0x14(%ebp)
f010127b:	e9 1b 01 00 00       	jmp    f010139b <.L34+0x3d>
f0101280:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101283:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101286:	eb e9                	jmp    f0101271 <.L36+0xef>

f0101288 <.L31>:
f0101288:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f010128b:	83 f9 01             	cmp    $0x1,%ecx
f010128e:	7e 40                	jle    f01012d0 <.L31+0x48>
		return va_arg(*ap, long long);
f0101290:	8b 45 14             	mov    0x14(%ebp),%eax
f0101293:	8b 50 04             	mov    0x4(%eax),%edx
f0101296:	8b 00                	mov    (%eax),%eax
f0101298:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010129b:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010129e:	8b 45 14             	mov    0x14(%ebp),%eax
f01012a1:	8d 40 08             	lea    0x8(%eax),%eax
f01012a4:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f01012a7:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01012ab:	79 55                	jns    f0101302 <.L31+0x7a>
				putch('-', putdat);
f01012ad:	83 ec 08             	sub    $0x8,%esp
f01012b0:	56                   	push   %esi
f01012b1:	6a 2d                	push   $0x2d
f01012b3:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01012b6:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01012b9:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01012bc:	f7 da                	neg    %edx
f01012be:	83 d1 00             	adc    $0x0,%ecx
f01012c1:	f7 d9                	neg    %ecx
f01012c3:	83 c4 10             	add    $0x10,%esp
			base = 10;
f01012c6:	b8 0a 00 00 00       	mov    $0xa,%eax
f01012cb:	e9 b0 00 00 00       	jmp    f0101380 <.L34+0x22>
	else if (lflag)
f01012d0:	85 c9                	test   %ecx,%ecx
f01012d2:	75 17                	jne    f01012eb <.L31+0x63>
		return va_arg(*ap, int);
f01012d4:	8b 45 14             	mov    0x14(%ebp),%eax
f01012d7:	8b 00                	mov    (%eax),%eax
f01012d9:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01012dc:	99                   	cltd   
f01012dd:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01012e0:	8b 45 14             	mov    0x14(%ebp),%eax
f01012e3:	8d 40 04             	lea    0x4(%eax),%eax
f01012e6:	89 45 14             	mov    %eax,0x14(%ebp)
f01012e9:	eb bc                	jmp    f01012a7 <.L31+0x1f>
		return va_arg(*ap, long);
f01012eb:	8b 45 14             	mov    0x14(%ebp),%eax
f01012ee:	8b 00                	mov    (%eax),%eax
f01012f0:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01012f3:	99                   	cltd   
f01012f4:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01012f7:	8b 45 14             	mov    0x14(%ebp),%eax
f01012fa:	8d 40 04             	lea    0x4(%eax),%eax
f01012fd:	89 45 14             	mov    %eax,0x14(%ebp)
f0101300:	eb a5                	jmp    f01012a7 <.L31+0x1f>
			num = getint(&ap, lflag);
f0101302:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101305:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0101308:	b8 0a 00 00 00       	mov    $0xa,%eax
f010130d:	eb 71                	jmp    f0101380 <.L34+0x22>

f010130f <.L37>:
f010130f:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0101312:	83 f9 01             	cmp    $0x1,%ecx
f0101315:	7e 15                	jle    f010132c <.L37+0x1d>
		return va_arg(*ap, unsigned long long);
f0101317:	8b 45 14             	mov    0x14(%ebp),%eax
f010131a:	8b 10                	mov    (%eax),%edx
f010131c:	8b 48 04             	mov    0x4(%eax),%ecx
f010131f:	8d 40 08             	lea    0x8(%eax),%eax
f0101322:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101325:	b8 0a 00 00 00       	mov    $0xa,%eax
f010132a:	eb 54                	jmp    f0101380 <.L34+0x22>
	else if (lflag)
f010132c:	85 c9                	test   %ecx,%ecx
f010132e:	75 17                	jne    f0101347 <.L37+0x38>
		return va_arg(*ap, unsigned int);
f0101330:	8b 45 14             	mov    0x14(%ebp),%eax
f0101333:	8b 10                	mov    (%eax),%edx
f0101335:	b9 00 00 00 00       	mov    $0x0,%ecx
f010133a:	8d 40 04             	lea    0x4(%eax),%eax
f010133d:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101340:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101345:	eb 39                	jmp    f0101380 <.L34+0x22>
		return va_arg(*ap, unsigned long);
f0101347:	8b 45 14             	mov    0x14(%ebp),%eax
f010134a:	8b 10                	mov    (%eax),%edx
f010134c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101351:	8d 40 04             	lea    0x4(%eax),%eax
f0101354:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101357:	b8 0a 00 00 00       	mov    $0xa,%eax
f010135c:	eb 22                	jmp    f0101380 <.L34+0x22>

f010135e <.L34>:
f010135e:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0101361:	83 f9 01             	cmp    $0x1,%ecx
f0101364:	7e 5d                	jle    f01013c3 <.L34+0x65>
		return va_arg(*ap, long long);
f0101366:	8b 45 14             	mov    0x14(%ebp),%eax
f0101369:	8b 50 04             	mov    0x4(%eax),%edx
f010136c:	8b 00                	mov    (%eax),%eax
f010136e:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0101371:	8d 49 08             	lea    0x8(%ecx),%ecx
f0101374:	89 4d 14             	mov    %ecx,0x14(%ebp)
			num = getint(&ap, lflag);
f0101377:	89 d1                	mov    %edx,%ecx
f0101379:	89 c2                	mov    %eax,%edx
			base = 8;
f010137b:	b8 08 00 00 00       	mov    $0x8,%eax
			printnum(putch, putdat, num, base, width, padc);
f0101380:	83 ec 0c             	sub    $0xc,%esp
f0101383:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0101387:	57                   	push   %edi
f0101388:	ff 75 e0             	pushl  -0x20(%ebp)
f010138b:	50                   	push   %eax
f010138c:	51                   	push   %ecx
f010138d:	52                   	push   %edx
f010138e:	89 f2                	mov    %esi,%edx
f0101390:	8b 45 08             	mov    0x8(%ebp),%eax
f0101393:	e8 80 fb ff ff       	call   f0100f18 <printnum>
			break;
f0101398:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f010139b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010139e:	83 c7 01             	add    $0x1,%edi
f01013a1:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01013a5:	83 f8 25             	cmp    $0x25,%eax
f01013a8:	0f 84 8d fc ff ff    	je     f010103b <vprintfmt+0x1f>
			if (ch == '\0')
f01013ae:	85 c0                	test   %eax,%eax
f01013b0:	0f 84 f0 00 00 00    	je     f01014a6 <.L22+0x21>
			putch(ch, putdat);
f01013b6:	83 ec 08             	sub    $0x8,%esp
f01013b9:	56                   	push   %esi
f01013ba:	50                   	push   %eax
f01013bb:	ff 55 08             	call   *0x8(%ebp)
f01013be:	83 c4 10             	add    $0x10,%esp
f01013c1:	eb db                	jmp    f010139e <.L34+0x40>
	else if (lflag)
f01013c3:	85 c9                	test   %ecx,%ecx
f01013c5:	75 13                	jne    f01013da <.L34+0x7c>
		return va_arg(*ap, int);
f01013c7:	8b 45 14             	mov    0x14(%ebp),%eax
f01013ca:	8b 10                	mov    (%eax),%edx
f01013cc:	89 d0                	mov    %edx,%eax
f01013ce:	99                   	cltd   
f01013cf:	8b 4d 14             	mov    0x14(%ebp),%ecx
f01013d2:	8d 49 04             	lea    0x4(%ecx),%ecx
f01013d5:	89 4d 14             	mov    %ecx,0x14(%ebp)
f01013d8:	eb 9d                	jmp    f0101377 <.L34+0x19>
		return va_arg(*ap, long);
f01013da:	8b 45 14             	mov    0x14(%ebp),%eax
f01013dd:	8b 10                	mov    (%eax),%edx
f01013df:	89 d0                	mov    %edx,%eax
f01013e1:	99                   	cltd   
f01013e2:	8b 4d 14             	mov    0x14(%ebp),%ecx
f01013e5:	8d 49 04             	lea    0x4(%ecx),%ecx
f01013e8:	89 4d 14             	mov    %ecx,0x14(%ebp)
f01013eb:	eb 8a                	jmp    f0101377 <.L34+0x19>

f01013ed <.L35>:
			putch('0', putdat);
f01013ed:	83 ec 08             	sub    $0x8,%esp
f01013f0:	56                   	push   %esi
f01013f1:	6a 30                	push   $0x30
f01013f3:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01013f6:	83 c4 08             	add    $0x8,%esp
f01013f9:	56                   	push   %esi
f01013fa:	6a 78                	push   $0x78
f01013fc:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f01013ff:	8b 45 14             	mov    0x14(%ebp),%eax
f0101402:	8b 10                	mov    (%eax),%edx
f0101404:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0101409:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f010140c:	8d 40 04             	lea    0x4(%eax),%eax
f010140f:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101412:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0101417:	e9 64 ff ff ff       	jmp    f0101380 <.L34+0x22>

f010141c <.L38>:
f010141c:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f010141f:	83 f9 01             	cmp    $0x1,%ecx
f0101422:	7e 18                	jle    f010143c <.L38+0x20>
		return va_arg(*ap, unsigned long long);
f0101424:	8b 45 14             	mov    0x14(%ebp),%eax
f0101427:	8b 10                	mov    (%eax),%edx
f0101429:	8b 48 04             	mov    0x4(%eax),%ecx
f010142c:	8d 40 08             	lea    0x8(%eax),%eax
f010142f:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101432:	b8 10 00 00 00       	mov    $0x10,%eax
f0101437:	e9 44 ff ff ff       	jmp    f0101380 <.L34+0x22>
	else if (lflag)
f010143c:	85 c9                	test   %ecx,%ecx
f010143e:	75 1a                	jne    f010145a <.L38+0x3e>
		return va_arg(*ap, unsigned int);
f0101440:	8b 45 14             	mov    0x14(%ebp),%eax
f0101443:	8b 10                	mov    (%eax),%edx
f0101445:	b9 00 00 00 00       	mov    $0x0,%ecx
f010144a:	8d 40 04             	lea    0x4(%eax),%eax
f010144d:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101450:	b8 10 00 00 00       	mov    $0x10,%eax
f0101455:	e9 26 ff ff ff       	jmp    f0101380 <.L34+0x22>
		return va_arg(*ap, unsigned long);
f010145a:	8b 45 14             	mov    0x14(%ebp),%eax
f010145d:	8b 10                	mov    (%eax),%edx
f010145f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101464:	8d 40 04             	lea    0x4(%eax),%eax
f0101467:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f010146a:	b8 10 00 00 00       	mov    $0x10,%eax
f010146f:	e9 0c ff ff ff       	jmp    f0101380 <.L34+0x22>

f0101474 <.L25>:
			putch(ch, putdat);
f0101474:	83 ec 08             	sub    $0x8,%esp
f0101477:	56                   	push   %esi
f0101478:	6a 25                	push   $0x25
f010147a:	ff 55 08             	call   *0x8(%ebp)
			break;
f010147d:	83 c4 10             	add    $0x10,%esp
f0101480:	e9 16 ff ff ff       	jmp    f010139b <.L34+0x3d>

f0101485 <.L22>:
			putch('%', putdat);
f0101485:	83 ec 08             	sub    $0x8,%esp
f0101488:	56                   	push   %esi
f0101489:	6a 25                	push   $0x25
f010148b:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f010148e:	83 c4 10             	add    $0x10,%esp
f0101491:	89 f8                	mov    %edi,%eax
f0101493:	eb 03                	jmp    f0101498 <.L22+0x13>
f0101495:	83 e8 01             	sub    $0x1,%eax
f0101498:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f010149c:	75 f7                	jne    f0101495 <.L22+0x10>
f010149e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01014a1:	e9 f5 fe ff ff       	jmp    f010139b <.L34+0x3d>
}
f01014a6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01014a9:	5b                   	pop    %ebx
f01014aa:	5e                   	pop    %esi
f01014ab:	5f                   	pop    %edi
f01014ac:	5d                   	pop    %ebp
f01014ad:	c3                   	ret    

f01014ae <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01014ae:	55                   	push   %ebp
f01014af:	89 e5                	mov    %esp,%ebp
f01014b1:	53                   	push   %ebx
f01014b2:	83 ec 14             	sub    $0x14,%esp
f01014b5:	e8 33 ed ff ff       	call   f01001ed <__x86.get_pc_thunk.bx>
f01014ba:	81 c3 4e fe 00 00    	add    $0xfe4e,%ebx
f01014c0:	8b 45 08             	mov    0x8(%ebp),%eax
f01014c3:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01014c6:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01014c9:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01014cd:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01014d0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01014d7:	85 c0                	test   %eax,%eax
f01014d9:	74 2b                	je     f0101506 <vsnprintf+0x58>
f01014db:	85 d2                	test   %edx,%edx
f01014dd:	7e 27                	jle    f0101506 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01014df:	ff 75 14             	pushl  0x14(%ebp)
f01014e2:	ff 75 10             	pushl  0x10(%ebp)
f01014e5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01014e8:	50                   	push   %eax
f01014e9:	8d 83 da fc fe ff    	lea    -0x10326(%ebx),%eax
f01014ef:	50                   	push   %eax
f01014f0:	e8 27 fb ff ff       	call   f010101c <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01014f5:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01014f8:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01014fb:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01014fe:	83 c4 10             	add    $0x10,%esp
}
f0101501:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101504:	c9                   	leave  
f0101505:	c3                   	ret    
		return -E_INVAL;
f0101506:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010150b:	eb f4                	jmp    f0101501 <vsnprintf+0x53>

f010150d <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010150d:	55                   	push   %ebp
f010150e:	89 e5                	mov    %esp,%ebp
f0101510:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101513:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101516:	50                   	push   %eax
f0101517:	ff 75 10             	pushl  0x10(%ebp)
f010151a:	ff 75 0c             	pushl  0xc(%ebp)
f010151d:	ff 75 08             	pushl  0x8(%ebp)
f0101520:	e8 89 ff ff ff       	call   f01014ae <vsnprintf>
	va_end(ap);

	return rc;
}
f0101525:	c9                   	leave  
f0101526:	c3                   	ret    

f0101527 <__x86.get_pc_thunk.cx>:
f0101527:	8b 0c 24             	mov    (%esp),%ecx
f010152a:	c3                   	ret    

f010152b <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010152b:	55                   	push   %ebp
f010152c:	89 e5                	mov    %esp,%ebp
f010152e:	57                   	push   %edi
f010152f:	56                   	push   %esi
f0101530:	53                   	push   %ebx
f0101531:	83 ec 1c             	sub    $0x1c,%esp
f0101534:	e8 b4 ec ff ff       	call   f01001ed <__x86.get_pc_thunk.bx>
f0101539:	81 c3 cf fd 00 00    	add    $0xfdcf,%ebx
f010153f:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101542:	85 c0                	test   %eax,%eax
f0101544:	74 13                	je     f0101559 <readline+0x2e>
		cprintf("%s", prompt);
f0101546:	83 ec 08             	sub    $0x8,%esp
f0101549:	50                   	push   %eax
f010154a:	8d 83 42 09 ff ff    	lea    -0xf6be(%ebx),%eax
f0101550:	50                   	push   %eax
f0101551:	e8 36 f6 ff ff       	call   f0100b8c <cprintf>
f0101556:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0101559:	83 ec 0c             	sub    $0xc,%esp
f010155c:	6a 00                	push   $0x0
f010155e:	e8 22 f2 ff ff       	call   f0100785 <iscons>
f0101563:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101566:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0101569:	bf 00 00 00 00       	mov    $0x0,%edi
f010156e:	eb 46                	jmp    f01015b6 <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0101570:	83 ec 08             	sub    $0x8,%esp
f0101573:	50                   	push   %eax
f0101574:	8d 83 28 10 ff ff    	lea    -0xefd8(%ebx),%eax
f010157a:	50                   	push   %eax
f010157b:	e8 0c f6 ff ff       	call   f0100b8c <cprintf>
			return NULL;
f0101580:	83 c4 10             	add    $0x10,%esp
f0101583:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0101588:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010158b:	5b                   	pop    %ebx
f010158c:	5e                   	pop    %esi
f010158d:	5f                   	pop    %edi
f010158e:	5d                   	pop    %ebp
f010158f:	c3                   	ret    
			if (echoing)
f0101590:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101594:	75 05                	jne    f010159b <readline+0x70>
			i--;
f0101596:	83 ef 01             	sub    $0x1,%edi
f0101599:	eb 1b                	jmp    f01015b6 <readline+0x8b>
				cputchar('\b');
f010159b:	83 ec 0c             	sub    $0xc,%esp
f010159e:	6a 08                	push   $0x8
f01015a0:	e8 bf f1 ff ff       	call   f0100764 <cputchar>
f01015a5:	83 c4 10             	add    $0x10,%esp
f01015a8:	eb ec                	jmp    f0101596 <readline+0x6b>
			buf[i++] = c;
f01015aa:	89 f0                	mov    %esi,%eax
f01015ac:	88 84 3b 98 1f 00 00 	mov    %al,0x1f98(%ebx,%edi,1)
f01015b3:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f01015b6:	e8 b9 f1 ff ff       	call   f0100774 <getchar>
f01015bb:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f01015bd:	85 c0                	test   %eax,%eax
f01015bf:	78 af                	js     f0101570 <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01015c1:	83 f8 08             	cmp    $0x8,%eax
f01015c4:	0f 94 c2             	sete   %dl
f01015c7:	83 f8 7f             	cmp    $0x7f,%eax
f01015ca:	0f 94 c0             	sete   %al
f01015cd:	08 c2                	or     %al,%dl
f01015cf:	74 04                	je     f01015d5 <readline+0xaa>
f01015d1:	85 ff                	test   %edi,%edi
f01015d3:	7f bb                	jg     f0101590 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01015d5:	83 fe 1f             	cmp    $0x1f,%esi
f01015d8:	7e 1c                	jle    f01015f6 <readline+0xcb>
f01015da:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f01015e0:	7f 14                	jg     f01015f6 <readline+0xcb>
			if (echoing)
f01015e2:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01015e6:	74 c2                	je     f01015aa <readline+0x7f>
				cputchar(c);
f01015e8:	83 ec 0c             	sub    $0xc,%esp
f01015eb:	56                   	push   %esi
f01015ec:	e8 73 f1 ff ff       	call   f0100764 <cputchar>
f01015f1:	83 c4 10             	add    $0x10,%esp
f01015f4:	eb b4                	jmp    f01015aa <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f01015f6:	83 fe 0a             	cmp    $0xa,%esi
f01015f9:	74 05                	je     f0101600 <readline+0xd5>
f01015fb:	83 fe 0d             	cmp    $0xd,%esi
f01015fe:	75 b6                	jne    f01015b6 <readline+0x8b>
			if (echoing)
f0101600:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101604:	75 13                	jne    f0101619 <readline+0xee>
			buf[i] = 0;
f0101606:	c6 84 3b 98 1f 00 00 	movb   $0x0,0x1f98(%ebx,%edi,1)
f010160d:	00 
			return buf;
f010160e:	8d 83 98 1f 00 00    	lea    0x1f98(%ebx),%eax
f0101614:	e9 6f ff ff ff       	jmp    f0101588 <readline+0x5d>
				cputchar('\n');
f0101619:	83 ec 0c             	sub    $0xc,%esp
f010161c:	6a 0a                	push   $0xa
f010161e:	e8 41 f1 ff ff       	call   f0100764 <cputchar>
f0101623:	83 c4 10             	add    $0x10,%esp
f0101626:	eb de                	jmp    f0101606 <readline+0xdb>

f0101628 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101628:	55                   	push   %ebp
f0101629:	89 e5                	mov    %esp,%ebp
f010162b:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010162e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101633:	eb 03                	jmp    f0101638 <strlen+0x10>
		n++;
f0101635:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0101638:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010163c:	75 f7                	jne    f0101635 <strlen+0xd>
	return n;
}
f010163e:	5d                   	pop    %ebp
f010163f:	c3                   	ret    

f0101640 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101640:	55                   	push   %ebp
f0101641:	89 e5                	mov    %esp,%ebp
f0101643:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101646:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101649:	b8 00 00 00 00       	mov    $0x0,%eax
f010164e:	eb 03                	jmp    f0101653 <strnlen+0x13>
		n++;
f0101650:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101653:	39 d0                	cmp    %edx,%eax
f0101655:	74 06                	je     f010165d <strnlen+0x1d>
f0101657:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f010165b:	75 f3                	jne    f0101650 <strnlen+0x10>
	return n;
}
f010165d:	5d                   	pop    %ebp
f010165e:	c3                   	ret    

f010165f <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010165f:	55                   	push   %ebp
f0101660:	89 e5                	mov    %esp,%ebp
f0101662:	53                   	push   %ebx
f0101663:	8b 45 08             	mov    0x8(%ebp),%eax
f0101666:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101669:	89 c2                	mov    %eax,%edx
f010166b:	83 c1 01             	add    $0x1,%ecx
f010166e:	83 c2 01             	add    $0x1,%edx
f0101671:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101675:	88 5a ff             	mov    %bl,-0x1(%edx)
f0101678:	84 db                	test   %bl,%bl
f010167a:	75 ef                	jne    f010166b <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010167c:	5b                   	pop    %ebx
f010167d:	5d                   	pop    %ebp
f010167e:	c3                   	ret    

f010167f <strcat>:

char *
strcat(char *dst, const char *src)
{
f010167f:	55                   	push   %ebp
f0101680:	89 e5                	mov    %esp,%ebp
f0101682:	53                   	push   %ebx
f0101683:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101686:	53                   	push   %ebx
f0101687:	e8 9c ff ff ff       	call   f0101628 <strlen>
f010168c:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010168f:	ff 75 0c             	pushl  0xc(%ebp)
f0101692:	01 d8                	add    %ebx,%eax
f0101694:	50                   	push   %eax
f0101695:	e8 c5 ff ff ff       	call   f010165f <strcpy>
	return dst;
}
f010169a:	89 d8                	mov    %ebx,%eax
f010169c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010169f:	c9                   	leave  
f01016a0:	c3                   	ret    

f01016a1 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01016a1:	55                   	push   %ebp
f01016a2:	89 e5                	mov    %esp,%ebp
f01016a4:	56                   	push   %esi
f01016a5:	53                   	push   %ebx
f01016a6:	8b 75 08             	mov    0x8(%ebp),%esi
f01016a9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01016ac:	89 f3                	mov    %esi,%ebx
f01016ae:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01016b1:	89 f2                	mov    %esi,%edx
f01016b3:	eb 0f                	jmp    f01016c4 <strncpy+0x23>
		*dst++ = *src;
f01016b5:	83 c2 01             	add    $0x1,%edx
f01016b8:	0f b6 01             	movzbl (%ecx),%eax
f01016bb:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01016be:	80 39 01             	cmpb   $0x1,(%ecx)
f01016c1:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f01016c4:	39 da                	cmp    %ebx,%edx
f01016c6:	75 ed                	jne    f01016b5 <strncpy+0x14>
	}
	return ret;
}
f01016c8:	89 f0                	mov    %esi,%eax
f01016ca:	5b                   	pop    %ebx
f01016cb:	5e                   	pop    %esi
f01016cc:	5d                   	pop    %ebp
f01016cd:	c3                   	ret    

f01016ce <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01016ce:	55                   	push   %ebp
f01016cf:	89 e5                	mov    %esp,%ebp
f01016d1:	56                   	push   %esi
f01016d2:	53                   	push   %ebx
f01016d3:	8b 75 08             	mov    0x8(%ebp),%esi
f01016d6:	8b 55 0c             	mov    0xc(%ebp),%edx
f01016d9:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01016dc:	89 f0                	mov    %esi,%eax
f01016de:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01016e2:	85 c9                	test   %ecx,%ecx
f01016e4:	75 0b                	jne    f01016f1 <strlcpy+0x23>
f01016e6:	eb 17                	jmp    f01016ff <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01016e8:	83 c2 01             	add    $0x1,%edx
f01016eb:	83 c0 01             	add    $0x1,%eax
f01016ee:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f01016f1:	39 d8                	cmp    %ebx,%eax
f01016f3:	74 07                	je     f01016fc <strlcpy+0x2e>
f01016f5:	0f b6 0a             	movzbl (%edx),%ecx
f01016f8:	84 c9                	test   %cl,%cl
f01016fa:	75 ec                	jne    f01016e8 <strlcpy+0x1a>
		*dst = '\0';
f01016fc:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01016ff:	29 f0                	sub    %esi,%eax
}
f0101701:	5b                   	pop    %ebx
f0101702:	5e                   	pop    %esi
f0101703:	5d                   	pop    %ebp
f0101704:	c3                   	ret    

f0101705 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101705:	55                   	push   %ebp
f0101706:	89 e5                	mov    %esp,%ebp
f0101708:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010170b:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010170e:	eb 06                	jmp    f0101716 <strcmp+0x11>
		p++, q++;
f0101710:	83 c1 01             	add    $0x1,%ecx
f0101713:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0101716:	0f b6 01             	movzbl (%ecx),%eax
f0101719:	84 c0                	test   %al,%al
f010171b:	74 04                	je     f0101721 <strcmp+0x1c>
f010171d:	3a 02                	cmp    (%edx),%al
f010171f:	74 ef                	je     f0101710 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101721:	0f b6 c0             	movzbl %al,%eax
f0101724:	0f b6 12             	movzbl (%edx),%edx
f0101727:	29 d0                	sub    %edx,%eax
}
f0101729:	5d                   	pop    %ebp
f010172a:	c3                   	ret    

f010172b <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010172b:	55                   	push   %ebp
f010172c:	89 e5                	mov    %esp,%ebp
f010172e:	53                   	push   %ebx
f010172f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101732:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101735:	89 c3                	mov    %eax,%ebx
f0101737:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010173a:	eb 06                	jmp    f0101742 <strncmp+0x17>
		n--, p++, q++;
f010173c:	83 c0 01             	add    $0x1,%eax
f010173f:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0101742:	39 d8                	cmp    %ebx,%eax
f0101744:	74 16                	je     f010175c <strncmp+0x31>
f0101746:	0f b6 08             	movzbl (%eax),%ecx
f0101749:	84 c9                	test   %cl,%cl
f010174b:	74 04                	je     f0101751 <strncmp+0x26>
f010174d:	3a 0a                	cmp    (%edx),%cl
f010174f:	74 eb                	je     f010173c <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101751:	0f b6 00             	movzbl (%eax),%eax
f0101754:	0f b6 12             	movzbl (%edx),%edx
f0101757:	29 d0                	sub    %edx,%eax
}
f0101759:	5b                   	pop    %ebx
f010175a:	5d                   	pop    %ebp
f010175b:	c3                   	ret    
		return 0;
f010175c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101761:	eb f6                	jmp    f0101759 <strncmp+0x2e>

f0101763 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101763:	55                   	push   %ebp
f0101764:	89 e5                	mov    %esp,%ebp
f0101766:	8b 45 08             	mov    0x8(%ebp),%eax
f0101769:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010176d:	0f b6 10             	movzbl (%eax),%edx
f0101770:	84 d2                	test   %dl,%dl
f0101772:	74 09                	je     f010177d <strchr+0x1a>
		if (*s == c)
f0101774:	38 ca                	cmp    %cl,%dl
f0101776:	74 0a                	je     f0101782 <strchr+0x1f>
	for (; *s; s++)
f0101778:	83 c0 01             	add    $0x1,%eax
f010177b:	eb f0                	jmp    f010176d <strchr+0xa>
			return (char *) s;
	return 0;
f010177d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101782:	5d                   	pop    %ebp
f0101783:	c3                   	ret    

f0101784 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0101784:	55                   	push   %ebp
f0101785:	89 e5                	mov    %esp,%ebp
f0101787:	8b 45 08             	mov    0x8(%ebp),%eax
f010178a:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010178e:	eb 03                	jmp    f0101793 <strfind+0xf>
f0101790:	83 c0 01             	add    $0x1,%eax
f0101793:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101796:	38 ca                	cmp    %cl,%dl
f0101798:	74 04                	je     f010179e <strfind+0x1a>
f010179a:	84 d2                	test   %dl,%dl
f010179c:	75 f2                	jne    f0101790 <strfind+0xc>
			break;
	return (char *) s;
}
f010179e:	5d                   	pop    %ebp
f010179f:	c3                   	ret    

f01017a0 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01017a0:	55                   	push   %ebp
f01017a1:	89 e5                	mov    %esp,%ebp
f01017a3:	57                   	push   %edi
f01017a4:	56                   	push   %esi
f01017a5:	53                   	push   %ebx
f01017a6:	8b 7d 08             	mov    0x8(%ebp),%edi
f01017a9:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01017ac:	85 c9                	test   %ecx,%ecx
f01017ae:	74 13                	je     f01017c3 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01017b0:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01017b6:	75 05                	jne    f01017bd <memset+0x1d>
f01017b8:	f6 c1 03             	test   $0x3,%cl
f01017bb:	74 0d                	je     f01017ca <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01017bd:	8b 45 0c             	mov    0xc(%ebp),%eax
f01017c0:	fc                   	cld    
f01017c1:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01017c3:	89 f8                	mov    %edi,%eax
f01017c5:	5b                   	pop    %ebx
f01017c6:	5e                   	pop    %esi
f01017c7:	5f                   	pop    %edi
f01017c8:	5d                   	pop    %ebp
f01017c9:	c3                   	ret    
		c &= 0xFF;
f01017ca:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01017ce:	89 d3                	mov    %edx,%ebx
f01017d0:	c1 e3 08             	shl    $0x8,%ebx
f01017d3:	89 d0                	mov    %edx,%eax
f01017d5:	c1 e0 18             	shl    $0x18,%eax
f01017d8:	89 d6                	mov    %edx,%esi
f01017da:	c1 e6 10             	shl    $0x10,%esi
f01017dd:	09 f0                	or     %esi,%eax
f01017df:	09 c2                	or     %eax,%edx
f01017e1:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f01017e3:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f01017e6:	89 d0                	mov    %edx,%eax
f01017e8:	fc                   	cld    
f01017e9:	f3 ab                	rep stos %eax,%es:(%edi)
f01017eb:	eb d6                	jmp    f01017c3 <memset+0x23>

f01017ed <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01017ed:	55                   	push   %ebp
f01017ee:	89 e5                	mov    %esp,%ebp
f01017f0:	57                   	push   %edi
f01017f1:	56                   	push   %esi
f01017f2:	8b 45 08             	mov    0x8(%ebp),%eax
f01017f5:	8b 75 0c             	mov    0xc(%ebp),%esi
f01017f8:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01017fb:	39 c6                	cmp    %eax,%esi
f01017fd:	73 35                	jae    f0101834 <memmove+0x47>
f01017ff:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101802:	39 c2                	cmp    %eax,%edx
f0101804:	76 2e                	jbe    f0101834 <memmove+0x47>
		s += n;
		d += n;
f0101806:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101809:	89 d6                	mov    %edx,%esi
f010180b:	09 fe                	or     %edi,%esi
f010180d:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101813:	74 0c                	je     f0101821 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101815:	83 ef 01             	sub    $0x1,%edi
f0101818:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f010181b:	fd                   	std    
f010181c:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010181e:	fc                   	cld    
f010181f:	eb 21                	jmp    f0101842 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101821:	f6 c1 03             	test   $0x3,%cl
f0101824:	75 ef                	jne    f0101815 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101826:	83 ef 04             	sub    $0x4,%edi
f0101829:	8d 72 fc             	lea    -0x4(%edx),%esi
f010182c:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f010182f:	fd                   	std    
f0101830:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101832:	eb ea                	jmp    f010181e <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101834:	89 f2                	mov    %esi,%edx
f0101836:	09 c2                	or     %eax,%edx
f0101838:	f6 c2 03             	test   $0x3,%dl
f010183b:	74 09                	je     f0101846 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010183d:	89 c7                	mov    %eax,%edi
f010183f:	fc                   	cld    
f0101840:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101842:	5e                   	pop    %esi
f0101843:	5f                   	pop    %edi
f0101844:	5d                   	pop    %ebp
f0101845:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101846:	f6 c1 03             	test   $0x3,%cl
f0101849:	75 f2                	jne    f010183d <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010184b:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f010184e:	89 c7                	mov    %eax,%edi
f0101850:	fc                   	cld    
f0101851:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101853:	eb ed                	jmp    f0101842 <memmove+0x55>

f0101855 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101855:	55                   	push   %ebp
f0101856:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f0101858:	ff 75 10             	pushl  0x10(%ebp)
f010185b:	ff 75 0c             	pushl  0xc(%ebp)
f010185e:	ff 75 08             	pushl  0x8(%ebp)
f0101861:	e8 87 ff ff ff       	call   f01017ed <memmove>
}
f0101866:	c9                   	leave  
f0101867:	c3                   	ret    

f0101868 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101868:	55                   	push   %ebp
f0101869:	89 e5                	mov    %esp,%ebp
f010186b:	56                   	push   %esi
f010186c:	53                   	push   %ebx
f010186d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101870:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101873:	89 c6                	mov    %eax,%esi
f0101875:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101878:	39 f0                	cmp    %esi,%eax
f010187a:	74 1c                	je     f0101898 <memcmp+0x30>
		if (*s1 != *s2)
f010187c:	0f b6 08             	movzbl (%eax),%ecx
f010187f:	0f b6 1a             	movzbl (%edx),%ebx
f0101882:	38 d9                	cmp    %bl,%cl
f0101884:	75 08                	jne    f010188e <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f0101886:	83 c0 01             	add    $0x1,%eax
f0101889:	83 c2 01             	add    $0x1,%edx
f010188c:	eb ea                	jmp    f0101878 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f010188e:	0f b6 c1             	movzbl %cl,%eax
f0101891:	0f b6 db             	movzbl %bl,%ebx
f0101894:	29 d8                	sub    %ebx,%eax
f0101896:	eb 05                	jmp    f010189d <memcmp+0x35>
	}

	return 0;
f0101898:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010189d:	5b                   	pop    %ebx
f010189e:	5e                   	pop    %esi
f010189f:	5d                   	pop    %ebp
f01018a0:	c3                   	ret    

f01018a1 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01018a1:	55                   	push   %ebp
f01018a2:	89 e5                	mov    %esp,%ebp
f01018a4:	8b 45 08             	mov    0x8(%ebp),%eax
f01018a7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01018aa:	89 c2                	mov    %eax,%edx
f01018ac:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01018af:	39 d0                	cmp    %edx,%eax
f01018b1:	73 09                	jae    f01018bc <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f01018b3:	38 08                	cmp    %cl,(%eax)
f01018b5:	74 05                	je     f01018bc <memfind+0x1b>
	for (; s < ends; s++)
f01018b7:	83 c0 01             	add    $0x1,%eax
f01018ba:	eb f3                	jmp    f01018af <memfind+0xe>
			break;
	return (void *) s;
}
f01018bc:	5d                   	pop    %ebp
f01018bd:	c3                   	ret    

f01018be <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01018be:	55                   	push   %ebp
f01018bf:	89 e5                	mov    %esp,%ebp
f01018c1:	57                   	push   %edi
f01018c2:	56                   	push   %esi
f01018c3:	53                   	push   %ebx
f01018c4:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01018c7:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01018ca:	eb 03                	jmp    f01018cf <strtol+0x11>
		s++;
f01018cc:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f01018cf:	0f b6 01             	movzbl (%ecx),%eax
f01018d2:	3c 20                	cmp    $0x20,%al
f01018d4:	74 f6                	je     f01018cc <strtol+0xe>
f01018d6:	3c 09                	cmp    $0x9,%al
f01018d8:	74 f2                	je     f01018cc <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f01018da:	3c 2b                	cmp    $0x2b,%al
f01018dc:	74 2e                	je     f010190c <strtol+0x4e>
	int neg = 0;
f01018de:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f01018e3:	3c 2d                	cmp    $0x2d,%al
f01018e5:	74 2f                	je     f0101916 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01018e7:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01018ed:	75 05                	jne    f01018f4 <strtol+0x36>
f01018ef:	80 39 30             	cmpb   $0x30,(%ecx)
f01018f2:	74 2c                	je     f0101920 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01018f4:	85 db                	test   %ebx,%ebx
f01018f6:	75 0a                	jne    f0101902 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01018f8:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f01018fd:	80 39 30             	cmpb   $0x30,(%ecx)
f0101900:	74 28                	je     f010192a <strtol+0x6c>
		base = 10;
f0101902:	b8 00 00 00 00       	mov    $0x0,%eax
f0101907:	89 5d 10             	mov    %ebx,0x10(%ebp)
f010190a:	eb 50                	jmp    f010195c <strtol+0x9e>
		s++;
f010190c:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f010190f:	bf 00 00 00 00       	mov    $0x0,%edi
f0101914:	eb d1                	jmp    f01018e7 <strtol+0x29>
		s++, neg = 1;
f0101916:	83 c1 01             	add    $0x1,%ecx
f0101919:	bf 01 00 00 00       	mov    $0x1,%edi
f010191e:	eb c7                	jmp    f01018e7 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101920:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101924:	74 0e                	je     f0101934 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0101926:	85 db                	test   %ebx,%ebx
f0101928:	75 d8                	jne    f0101902 <strtol+0x44>
		s++, base = 8;
f010192a:	83 c1 01             	add    $0x1,%ecx
f010192d:	bb 08 00 00 00       	mov    $0x8,%ebx
f0101932:	eb ce                	jmp    f0101902 <strtol+0x44>
		s += 2, base = 16;
f0101934:	83 c1 02             	add    $0x2,%ecx
f0101937:	bb 10 00 00 00       	mov    $0x10,%ebx
f010193c:	eb c4                	jmp    f0101902 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f010193e:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101941:	89 f3                	mov    %esi,%ebx
f0101943:	80 fb 19             	cmp    $0x19,%bl
f0101946:	77 29                	ja     f0101971 <strtol+0xb3>
			dig = *s - 'a' + 10;
f0101948:	0f be d2             	movsbl %dl,%edx
f010194b:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f010194e:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101951:	7d 30                	jge    f0101983 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0101953:	83 c1 01             	add    $0x1,%ecx
f0101956:	0f af 45 10          	imul   0x10(%ebp),%eax
f010195a:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f010195c:	0f b6 11             	movzbl (%ecx),%edx
f010195f:	8d 72 d0             	lea    -0x30(%edx),%esi
f0101962:	89 f3                	mov    %esi,%ebx
f0101964:	80 fb 09             	cmp    $0x9,%bl
f0101967:	77 d5                	ja     f010193e <strtol+0x80>
			dig = *s - '0';
f0101969:	0f be d2             	movsbl %dl,%edx
f010196c:	83 ea 30             	sub    $0x30,%edx
f010196f:	eb dd                	jmp    f010194e <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0101971:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101974:	89 f3                	mov    %esi,%ebx
f0101976:	80 fb 19             	cmp    $0x19,%bl
f0101979:	77 08                	ja     f0101983 <strtol+0xc5>
			dig = *s - 'A' + 10;
f010197b:	0f be d2             	movsbl %dl,%edx
f010197e:	83 ea 37             	sub    $0x37,%edx
f0101981:	eb cb                	jmp    f010194e <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0101983:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101987:	74 05                	je     f010198e <strtol+0xd0>
		*endptr = (char *) s;
f0101989:	8b 75 0c             	mov    0xc(%ebp),%esi
f010198c:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f010198e:	89 c2                	mov    %eax,%edx
f0101990:	f7 da                	neg    %edx
f0101992:	85 ff                	test   %edi,%edi
f0101994:	0f 45 c2             	cmovne %edx,%eax
}
f0101997:	5b                   	pop    %ebx
f0101998:	5e                   	pop    %esi
f0101999:	5f                   	pop    %edi
f010199a:	5d                   	pop    %ebp
f010199b:	c3                   	ret    
f010199c:	66 90                	xchg   %ax,%ax
f010199e:	66 90                	xchg   %ax,%ax

f01019a0 <__udivdi3>:
f01019a0:	55                   	push   %ebp
f01019a1:	57                   	push   %edi
f01019a2:	56                   	push   %esi
f01019a3:	53                   	push   %ebx
f01019a4:	83 ec 1c             	sub    $0x1c,%esp
f01019a7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01019ab:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f01019af:	8b 74 24 34          	mov    0x34(%esp),%esi
f01019b3:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f01019b7:	85 d2                	test   %edx,%edx
f01019b9:	75 35                	jne    f01019f0 <__udivdi3+0x50>
f01019bb:	39 f3                	cmp    %esi,%ebx
f01019bd:	0f 87 bd 00 00 00    	ja     f0101a80 <__udivdi3+0xe0>
f01019c3:	85 db                	test   %ebx,%ebx
f01019c5:	89 d9                	mov    %ebx,%ecx
f01019c7:	75 0b                	jne    f01019d4 <__udivdi3+0x34>
f01019c9:	b8 01 00 00 00       	mov    $0x1,%eax
f01019ce:	31 d2                	xor    %edx,%edx
f01019d0:	f7 f3                	div    %ebx
f01019d2:	89 c1                	mov    %eax,%ecx
f01019d4:	31 d2                	xor    %edx,%edx
f01019d6:	89 f0                	mov    %esi,%eax
f01019d8:	f7 f1                	div    %ecx
f01019da:	89 c6                	mov    %eax,%esi
f01019dc:	89 e8                	mov    %ebp,%eax
f01019de:	89 f7                	mov    %esi,%edi
f01019e0:	f7 f1                	div    %ecx
f01019e2:	89 fa                	mov    %edi,%edx
f01019e4:	83 c4 1c             	add    $0x1c,%esp
f01019e7:	5b                   	pop    %ebx
f01019e8:	5e                   	pop    %esi
f01019e9:	5f                   	pop    %edi
f01019ea:	5d                   	pop    %ebp
f01019eb:	c3                   	ret    
f01019ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019f0:	39 f2                	cmp    %esi,%edx
f01019f2:	77 7c                	ja     f0101a70 <__udivdi3+0xd0>
f01019f4:	0f bd fa             	bsr    %edx,%edi
f01019f7:	83 f7 1f             	xor    $0x1f,%edi
f01019fa:	0f 84 98 00 00 00    	je     f0101a98 <__udivdi3+0xf8>
f0101a00:	89 f9                	mov    %edi,%ecx
f0101a02:	b8 20 00 00 00       	mov    $0x20,%eax
f0101a07:	29 f8                	sub    %edi,%eax
f0101a09:	d3 e2                	shl    %cl,%edx
f0101a0b:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101a0f:	89 c1                	mov    %eax,%ecx
f0101a11:	89 da                	mov    %ebx,%edx
f0101a13:	d3 ea                	shr    %cl,%edx
f0101a15:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101a19:	09 d1                	or     %edx,%ecx
f0101a1b:	89 f2                	mov    %esi,%edx
f0101a1d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101a21:	89 f9                	mov    %edi,%ecx
f0101a23:	d3 e3                	shl    %cl,%ebx
f0101a25:	89 c1                	mov    %eax,%ecx
f0101a27:	d3 ea                	shr    %cl,%edx
f0101a29:	89 f9                	mov    %edi,%ecx
f0101a2b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0101a2f:	d3 e6                	shl    %cl,%esi
f0101a31:	89 eb                	mov    %ebp,%ebx
f0101a33:	89 c1                	mov    %eax,%ecx
f0101a35:	d3 eb                	shr    %cl,%ebx
f0101a37:	09 de                	or     %ebx,%esi
f0101a39:	89 f0                	mov    %esi,%eax
f0101a3b:	f7 74 24 08          	divl   0x8(%esp)
f0101a3f:	89 d6                	mov    %edx,%esi
f0101a41:	89 c3                	mov    %eax,%ebx
f0101a43:	f7 64 24 0c          	mull   0xc(%esp)
f0101a47:	39 d6                	cmp    %edx,%esi
f0101a49:	72 0c                	jb     f0101a57 <__udivdi3+0xb7>
f0101a4b:	89 f9                	mov    %edi,%ecx
f0101a4d:	d3 e5                	shl    %cl,%ebp
f0101a4f:	39 c5                	cmp    %eax,%ebp
f0101a51:	73 5d                	jae    f0101ab0 <__udivdi3+0x110>
f0101a53:	39 d6                	cmp    %edx,%esi
f0101a55:	75 59                	jne    f0101ab0 <__udivdi3+0x110>
f0101a57:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0101a5a:	31 ff                	xor    %edi,%edi
f0101a5c:	89 fa                	mov    %edi,%edx
f0101a5e:	83 c4 1c             	add    $0x1c,%esp
f0101a61:	5b                   	pop    %ebx
f0101a62:	5e                   	pop    %esi
f0101a63:	5f                   	pop    %edi
f0101a64:	5d                   	pop    %ebp
f0101a65:	c3                   	ret    
f0101a66:	8d 76 00             	lea    0x0(%esi),%esi
f0101a69:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0101a70:	31 ff                	xor    %edi,%edi
f0101a72:	31 c0                	xor    %eax,%eax
f0101a74:	89 fa                	mov    %edi,%edx
f0101a76:	83 c4 1c             	add    $0x1c,%esp
f0101a79:	5b                   	pop    %ebx
f0101a7a:	5e                   	pop    %esi
f0101a7b:	5f                   	pop    %edi
f0101a7c:	5d                   	pop    %ebp
f0101a7d:	c3                   	ret    
f0101a7e:	66 90                	xchg   %ax,%ax
f0101a80:	31 ff                	xor    %edi,%edi
f0101a82:	89 e8                	mov    %ebp,%eax
f0101a84:	89 f2                	mov    %esi,%edx
f0101a86:	f7 f3                	div    %ebx
f0101a88:	89 fa                	mov    %edi,%edx
f0101a8a:	83 c4 1c             	add    $0x1c,%esp
f0101a8d:	5b                   	pop    %ebx
f0101a8e:	5e                   	pop    %esi
f0101a8f:	5f                   	pop    %edi
f0101a90:	5d                   	pop    %ebp
f0101a91:	c3                   	ret    
f0101a92:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101a98:	39 f2                	cmp    %esi,%edx
f0101a9a:	72 06                	jb     f0101aa2 <__udivdi3+0x102>
f0101a9c:	31 c0                	xor    %eax,%eax
f0101a9e:	39 eb                	cmp    %ebp,%ebx
f0101aa0:	77 d2                	ja     f0101a74 <__udivdi3+0xd4>
f0101aa2:	b8 01 00 00 00       	mov    $0x1,%eax
f0101aa7:	eb cb                	jmp    f0101a74 <__udivdi3+0xd4>
f0101aa9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101ab0:	89 d8                	mov    %ebx,%eax
f0101ab2:	31 ff                	xor    %edi,%edi
f0101ab4:	eb be                	jmp    f0101a74 <__udivdi3+0xd4>
f0101ab6:	66 90                	xchg   %ax,%ax
f0101ab8:	66 90                	xchg   %ax,%ax
f0101aba:	66 90                	xchg   %ax,%ax
f0101abc:	66 90                	xchg   %ax,%ax
f0101abe:	66 90                	xchg   %ax,%ax

f0101ac0 <__umoddi3>:
f0101ac0:	55                   	push   %ebp
f0101ac1:	57                   	push   %edi
f0101ac2:	56                   	push   %esi
f0101ac3:	53                   	push   %ebx
f0101ac4:	83 ec 1c             	sub    $0x1c,%esp
f0101ac7:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f0101acb:	8b 74 24 30          	mov    0x30(%esp),%esi
f0101acf:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0101ad3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101ad7:	85 ed                	test   %ebp,%ebp
f0101ad9:	89 f0                	mov    %esi,%eax
f0101adb:	89 da                	mov    %ebx,%edx
f0101add:	75 19                	jne    f0101af8 <__umoddi3+0x38>
f0101adf:	39 df                	cmp    %ebx,%edi
f0101ae1:	0f 86 b1 00 00 00    	jbe    f0101b98 <__umoddi3+0xd8>
f0101ae7:	f7 f7                	div    %edi
f0101ae9:	89 d0                	mov    %edx,%eax
f0101aeb:	31 d2                	xor    %edx,%edx
f0101aed:	83 c4 1c             	add    $0x1c,%esp
f0101af0:	5b                   	pop    %ebx
f0101af1:	5e                   	pop    %esi
f0101af2:	5f                   	pop    %edi
f0101af3:	5d                   	pop    %ebp
f0101af4:	c3                   	ret    
f0101af5:	8d 76 00             	lea    0x0(%esi),%esi
f0101af8:	39 dd                	cmp    %ebx,%ebp
f0101afa:	77 f1                	ja     f0101aed <__umoddi3+0x2d>
f0101afc:	0f bd cd             	bsr    %ebp,%ecx
f0101aff:	83 f1 1f             	xor    $0x1f,%ecx
f0101b02:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101b06:	0f 84 b4 00 00 00    	je     f0101bc0 <__umoddi3+0x100>
f0101b0c:	b8 20 00 00 00       	mov    $0x20,%eax
f0101b11:	89 c2                	mov    %eax,%edx
f0101b13:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101b17:	29 c2                	sub    %eax,%edx
f0101b19:	89 c1                	mov    %eax,%ecx
f0101b1b:	89 f8                	mov    %edi,%eax
f0101b1d:	d3 e5                	shl    %cl,%ebp
f0101b1f:	89 d1                	mov    %edx,%ecx
f0101b21:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101b25:	d3 e8                	shr    %cl,%eax
f0101b27:	09 c5                	or     %eax,%ebp
f0101b29:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101b2d:	89 c1                	mov    %eax,%ecx
f0101b2f:	d3 e7                	shl    %cl,%edi
f0101b31:	89 d1                	mov    %edx,%ecx
f0101b33:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101b37:	89 df                	mov    %ebx,%edi
f0101b39:	d3 ef                	shr    %cl,%edi
f0101b3b:	89 c1                	mov    %eax,%ecx
f0101b3d:	89 f0                	mov    %esi,%eax
f0101b3f:	d3 e3                	shl    %cl,%ebx
f0101b41:	89 d1                	mov    %edx,%ecx
f0101b43:	89 fa                	mov    %edi,%edx
f0101b45:	d3 e8                	shr    %cl,%eax
f0101b47:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101b4c:	09 d8                	or     %ebx,%eax
f0101b4e:	f7 f5                	div    %ebp
f0101b50:	d3 e6                	shl    %cl,%esi
f0101b52:	89 d1                	mov    %edx,%ecx
f0101b54:	f7 64 24 08          	mull   0x8(%esp)
f0101b58:	39 d1                	cmp    %edx,%ecx
f0101b5a:	89 c3                	mov    %eax,%ebx
f0101b5c:	89 d7                	mov    %edx,%edi
f0101b5e:	72 06                	jb     f0101b66 <__umoddi3+0xa6>
f0101b60:	75 0e                	jne    f0101b70 <__umoddi3+0xb0>
f0101b62:	39 c6                	cmp    %eax,%esi
f0101b64:	73 0a                	jae    f0101b70 <__umoddi3+0xb0>
f0101b66:	2b 44 24 08          	sub    0x8(%esp),%eax
f0101b6a:	19 ea                	sbb    %ebp,%edx
f0101b6c:	89 d7                	mov    %edx,%edi
f0101b6e:	89 c3                	mov    %eax,%ebx
f0101b70:	89 ca                	mov    %ecx,%edx
f0101b72:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0101b77:	29 de                	sub    %ebx,%esi
f0101b79:	19 fa                	sbb    %edi,%edx
f0101b7b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f0101b7f:	89 d0                	mov    %edx,%eax
f0101b81:	d3 e0                	shl    %cl,%eax
f0101b83:	89 d9                	mov    %ebx,%ecx
f0101b85:	d3 ee                	shr    %cl,%esi
f0101b87:	d3 ea                	shr    %cl,%edx
f0101b89:	09 f0                	or     %esi,%eax
f0101b8b:	83 c4 1c             	add    $0x1c,%esp
f0101b8e:	5b                   	pop    %ebx
f0101b8f:	5e                   	pop    %esi
f0101b90:	5f                   	pop    %edi
f0101b91:	5d                   	pop    %ebp
f0101b92:	c3                   	ret    
f0101b93:	90                   	nop
f0101b94:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101b98:	85 ff                	test   %edi,%edi
f0101b9a:	89 f9                	mov    %edi,%ecx
f0101b9c:	75 0b                	jne    f0101ba9 <__umoddi3+0xe9>
f0101b9e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101ba3:	31 d2                	xor    %edx,%edx
f0101ba5:	f7 f7                	div    %edi
f0101ba7:	89 c1                	mov    %eax,%ecx
f0101ba9:	89 d8                	mov    %ebx,%eax
f0101bab:	31 d2                	xor    %edx,%edx
f0101bad:	f7 f1                	div    %ecx
f0101baf:	89 f0                	mov    %esi,%eax
f0101bb1:	f7 f1                	div    %ecx
f0101bb3:	e9 31 ff ff ff       	jmp    f0101ae9 <__umoddi3+0x29>
f0101bb8:	90                   	nop
f0101bb9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101bc0:	39 dd                	cmp    %ebx,%ebp
f0101bc2:	72 08                	jb     f0101bcc <__umoddi3+0x10c>
f0101bc4:	39 f7                	cmp    %esi,%edi
f0101bc6:	0f 87 21 ff ff ff    	ja     f0101aed <__umoddi3+0x2d>
f0101bcc:	89 da                	mov    %ebx,%edx
f0101bce:	89 f0                	mov    %esi,%eax
f0101bd0:	29 f8                	sub    %edi,%eax
f0101bd2:	19 ea                	sbb    %ebp,%edx
f0101bd4:	e9 14 ff ff ff       	jmp    f0101aed <__umoddi3+0x2d>
