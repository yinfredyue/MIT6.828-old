
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
f0100057:	8d 83 58 07 ff ff    	lea    -0xf8a8(%ebx),%eax
f010005d:	50                   	push   %eax
f010005e:	e8 17 0a 00 00       	call   f0100a7a <cprintf>
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
f0100073:	e8 3c 08 00 00       	call   f01008b4 <mon_backtrace>
f0100078:	83 c4 10             	add    $0x10,%esp
	cprintf("leaving test_backtrace %d\n", x);
f010007b:	83 ec 08             	sub    $0x8,%esp
f010007e:	56                   	push   %esi
f010007f:	8d 83 74 07 ff ff    	lea    -0xf88c(%ebx),%eax
f0100085:	50                   	push   %eax
f0100086:	e8 ef 09 00 00       	call   f0100a7a <cprintf>
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
f01000ca:	e8 3f 15 00 00       	call   f010160e <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000cf:	e8 6e 05 00 00       	call   f0100642 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000d4:	83 c4 08             	add    $0x8,%esp
f01000d7:	68 ac 1a 00 00       	push   $0x1aac
f01000dc:	8d 83 8f 07 ff ff    	lea    -0xf871(%ebx),%eax
f01000e2:	50                   	push   %eax
f01000e3:	e8 92 09 00 00       	call   f0100a7a <cprintf>

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
f01000fa:	8d 83 aa 07 ff ff    	lea    -0xf856(%ebx),%eax
f0100100:	50                   	push   %eax
f0100101:	e8 74 09 00 00       	call   f0100a7a <cprintf>

	unsigned int i = 0x00646c72;
f0100106:	c7 45 f4 72 6c 64 00 	movl   $0x646c72,-0xc(%ebp)
    cprintf("H%x Wo%s", 57616, &i);
f010010d:	83 c4 1c             	add    $0x1c,%esp
f0100110:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100113:	50                   	push   %eax
f0100114:	68 10 e1 00 00       	push   $0xe110
f0100119:	8d 83 bc 07 ff ff    	lea    -0xf844(%ebx),%eax
f010011f:	50                   	push   %eax
f0100120:	e8 55 09 00 00       	call   f0100a7a <cprintf>
f0100125:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100128:	83 ec 0c             	sub    $0xc,%esp
f010012b:	6a 00                	push   $0x0
f010012d:	e8 8c 07 00 00       	call   f01008be <monitor>
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
f010015e:	e8 5b 07 00 00       	call   f01008be <monitor>
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
f0100178:	8d 83 c5 07 ff ff    	lea    -0xf83b(%ebx),%eax
f010017e:	50                   	push   %eax
f010017f:	e8 f6 08 00 00       	call   f0100a7a <cprintf>
	vcprintf(fmt, ap);
f0100184:	83 c4 08             	add    $0x8,%esp
f0100187:	56                   	push   %esi
f0100188:	57                   	push   %edi
f0100189:	e8 b5 08 00 00       	call   f0100a43 <vcprintf>
	cprintf("\n");
f010018e:	8d 83 01 08 ff ff    	lea    -0xf7ff(%ebx),%eax
f0100194:	89 04 24             	mov    %eax,(%esp)
f0100197:	e8 de 08 00 00       	call   f0100a7a <cprintf>
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
f01001bd:	8d 83 dd 07 ff ff    	lea    -0xf823(%ebx),%eax
f01001c3:	50                   	push   %eax
f01001c4:	e8 b1 08 00 00       	call   f0100a7a <cprintf>
	vcprintf(fmt, ap);
f01001c9:	83 c4 08             	add    $0x8,%esp
f01001cc:	56                   	push   %esi
f01001cd:	ff 75 10             	pushl  0x10(%ebp)
f01001d0:	e8 6e 08 00 00       	call   f0100a43 <vcprintf>
	cprintf("\n");
f01001d5:	8d 83 01 08 ff ff    	lea    -0xf7ff(%ebx),%eax
f01001db:	89 04 24             	mov    %eax,(%esp)
f01001de:	e8 97 08 00 00       	call   f0100a7a <cprintf>
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
f01002b5:	0f b6 84 13 38 09 ff 	movzbl -0xf6c8(%ebx,%edx,1),%eax
f01002bc:	ff 
f01002bd:	0b 83 58 1d 00 00    	or     0x1d58(%ebx),%eax
	shift ^= togglecode[data];
f01002c3:	0f b6 8c 13 38 08 ff 	movzbl -0xf7c8(%ebx,%edx,1),%ecx
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
f0100308:	8d 83 f7 07 ff ff    	lea    -0xf809(%ebx),%eax
f010030e:	50                   	push   %eax
f010030f:	e8 66 07 00 00       	call   f0100a7a <cprintf>
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
f010034f:	0f b6 84 13 38 09 ff 	movzbl -0xf6c8(%ebx,%edx,1),%eax
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
f0100570:	e8 e6 10 00 00       	call   f010165b <memmove>
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
f0100753:	8d 83 03 08 ff ff    	lea    -0xf7fd(%ebx),%eax
f0100759:	50                   	push   %eax
f010075a:	e8 1b 03 00 00       	call   f0100a7a <cprintf>
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
f01007a6:	8d 83 38 0a ff ff    	lea    -0xf5c8(%ebx),%eax
f01007ac:	50                   	push   %eax
f01007ad:	8d 83 56 0a ff ff    	lea    -0xf5aa(%ebx),%eax
f01007b3:	50                   	push   %eax
f01007b4:	8d b3 5b 0a ff ff    	lea    -0xf5a5(%ebx),%esi
f01007ba:	56                   	push   %esi
f01007bb:	e8 ba 02 00 00       	call   f0100a7a <cprintf>
f01007c0:	83 c4 0c             	add    $0xc,%esp
f01007c3:	8d 83 c4 0a ff ff    	lea    -0xf53c(%ebx),%eax
f01007c9:	50                   	push   %eax
f01007ca:	8d 83 64 0a ff ff    	lea    -0xf59c(%ebx),%eax
f01007d0:	50                   	push   %eax
f01007d1:	56                   	push   %esi
f01007d2:	e8 a3 02 00 00       	call   f0100a7a <cprintf>
	return 0;
}
f01007d7:	b8 00 00 00 00       	mov    $0x0,%eax
f01007dc:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01007df:	5b                   	pop    %ebx
f01007e0:	5e                   	pop    %esi
f01007e1:	5d                   	pop    %ebp
f01007e2:	c3                   	ret    

f01007e3 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007e3:	55                   	push   %ebp
f01007e4:	89 e5                	mov    %esp,%ebp
f01007e6:	57                   	push   %edi
f01007e7:	56                   	push   %esi
f01007e8:	53                   	push   %ebx
f01007e9:	83 ec 18             	sub    $0x18,%esp
f01007ec:	e8 fc f9 ff ff       	call   f01001ed <__x86.get_pc_thunk.bx>
f01007f1:	81 c3 17 0b 01 00    	add    $0x10b17,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007f7:	8d 83 6d 0a ff ff    	lea    -0xf593(%ebx),%eax
f01007fd:	50                   	push   %eax
f01007fe:	e8 77 02 00 00       	call   f0100a7a <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100803:	83 c4 08             	add    $0x8,%esp
f0100806:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f010080c:	8d 83 ec 0a ff ff    	lea    -0xf514(%ebx),%eax
f0100812:	50                   	push   %eax
f0100813:	e8 62 02 00 00       	call   f0100a7a <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100818:	83 c4 0c             	add    $0xc,%esp
f010081b:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f0100821:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f0100827:	50                   	push   %eax
f0100828:	57                   	push   %edi
f0100829:	8d 83 14 0b ff ff    	lea    -0xf4ec(%ebx),%eax
f010082f:	50                   	push   %eax
f0100830:	e8 45 02 00 00       	call   f0100a7a <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100835:	83 c4 0c             	add    $0xc,%esp
f0100838:	c7 c0 49 1a 10 f0    	mov    $0xf0101a49,%eax
f010083e:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100844:	52                   	push   %edx
f0100845:	50                   	push   %eax
f0100846:	8d 83 38 0b ff ff    	lea    -0xf4c8(%ebx),%eax
f010084c:	50                   	push   %eax
f010084d:	e8 28 02 00 00       	call   f0100a7a <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100852:	83 c4 0c             	add    $0xc,%esp
f0100855:	c7 c0 60 30 11 f0    	mov    $0xf0113060,%eax
f010085b:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100861:	52                   	push   %edx
f0100862:	50                   	push   %eax
f0100863:	8d 83 5c 0b ff ff    	lea    -0xf4a4(%ebx),%eax
f0100869:	50                   	push   %eax
f010086a:	e8 0b 02 00 00       	call   f0100a7a <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010086f:	83 c4 0c             	add    $0xc,%esp
f0100872:	c7 c6 a0 36 11 f0    	mov    $0xf01136a0,%esi
f0100878:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f010087e:	50                   	push   %eax
f010087f:	56                   	push   %esi
f0100880:	8d 83 80 0b ff ff    	lea    -0xf480(%ebx),%eax
f0100886:	50                   	push   %eax
f0100887:	e8 ee 01 00 00       	call   f0100a7a <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f010088c:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f010088f:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f0100895:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100897:	c1 fe 0a             	sar    $0xa,%esi
f010089a:	56                   	push   %esi
f010089b:	8d 83 a4 0b ff ff    	lea    -0xf45c(%ebx),%eax
f01008a1:	50                   	push   %eax
f01008a2:	e8 d3 01 00 00       	call   f0100a7a <cprintf>
	return 0;
}
f01008a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01008ac:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008af:	5b                   	pop    %ebx
f01008b0:	5e                   	pop    %esi
f01008b1:	5f                   	pop    %edi
f01008b2:	5d                   	pop    %ebp
f01008b3:	c3                   	ret    

f01008b4 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01008b4:	55                   	push   %ebp
f01008b5:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f01008b7:	b8 00 00 00 00       	mov    $0x0,%eax
f01008bc:	5d                   	pop    %ebp
f01008bd:	c3                   	ret    

f01008be <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01008be:	55                   	push   %ebp
f01008bf:	89 e5                	mov    %esp,%ebp
f01008c1:	57                   	push   %edi
f01008c2:	56                   	push   %esi
f01008c3:	53                   	push   %ebx
f01008c4:	83 ec 68             	sub    $0x68,%esp
f01008c7:	e8 21 f9 ff ff       	call   f01001ed <__x86.get_pc_thunk.bx>
f01008cc:	81 c3 3c 0a 01 00    	add    $0x10a3c,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01008d2:	8d 83 d0 0b ff ff    	lea    -0xf430(%ebx),%eax
f01008d8:	50                   	push   %eax
f01008d9:	e8 9c 01 00 00       	call   f0100a7a <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01008de:	8d 83 f4 0b ff ff    	lea    -0xf40c(%ebx),%eax
f01008e4:	89 04 24             	mov    %eax,(%esp)
f01008e7:	e8 8e 01 00 00       	call   f0100a7a <cprintf>
f01008ec:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f01008ef:	8d bb 8a 0a ff ff    	lea    -0xf576(%ebx),%edi
f01008f5:	eb 4a                	jmp    f0100941 <monitor+0x83>
f01008f7:	83 ec 08             	sub    $0x8,%esp
f01008fa:	0f be c0             	movsbl %al,%eax
f01008fd:	50                   	push   %eax
f01008fe:	57                   	push   %edi
f01008ff:	e8 cd 0c 00 00       	call   f01015d1 <strchr>
f0100904:	83 c4 10             	add    $0x10,%esp
f0100907:	85 c0                	test   %eax,%eax
f0100909:	74 08                	je     f0100913 <monitor+0x55>
			*buf++ = 0;
f010090b:	c6 06 00             	movb   $0x0,(%esi)
f010090e:	8d 76 01             	lea    0x1(%esi),%esi
f0100911:	eb 79                	jmp    f010098c <monitor+0xce>
		if (*buf == 0)
f0100913:	80 3e 00             	cmpb   $0x0,(%esi)
f0100916:	74 7f                	je     f0100997 <monitor+0xd9>
		if (argc == MAXARGS-1) {
f0100918:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f010091c:	74 0f                	je     f010092d <monitor+0x6f>
		argv[argc++] = buf;
f010091e:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100921:	8d 48 01             	lea    0x1(%eax),%ecx
f0100924:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f0100927:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
f010092b:	eb 44                	jmp    f0100971 <monitor+0xb3>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010092d:	83 ec 08             	sub    $0x8,%esp
f0100930:	6a 10                	push   $0x10
f0100932:	8d 83 8f 0a ff ff    	lea    -0xf571(%ebx),%eax
f0100938:	50                   	push   %eax
f0100939:	e8 3c 01 00 00       	call   f0100a7a <cprintf>
f010093e:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f0100941:	8d 83 86 0a ff ff    	lea    -0xf57a(%ebx),%eax
f0100947:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f010094a:	83 ec 0c             	sub    $0xc,%esp
f010094d:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100950:	e8 44 0a 00 00       	call   f0101399 <readline>
f0100955:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f0100957:	83 c4 10             	add    $0x10,%esp
f010095a:	85 c0                	test   %eax,%eax
f010095c:	74 ec                	je     f010094a <monitor+0x8c>
	argv[argc] = 0;
f010095e:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100965:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f010096c:	eb 1e                	jmp    f010098c <monitor+0xce>
			buf++;
f010096e:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100971:	0f b6 06             	movzbl (%esi),%eax
f0100974:	84 c0                	test   %al,%al
f0100976:	74 14                	je     f010098c <monitor+0xce>
f0100978:	83 ec 08             	sub    $0x8,%esp
f010097b:	0f be c0             	movsbl %al,%eax
f010097e:	50                   	push   %eax
f010097f:	57                   	push   %edi
f0100980:	e8 4c 0c 00 00       	call   f01015d1 <strchr>
f0100985:	83 c4 10             	add    $0x10,%esp
f0100988:	85 c0                	test   %eax,%eax
f010098a:	74 e2                	je     f010096e <monitor+0xb0>
		while (*buf && strchr(WHITESPACE, *buf))
f010098c:	0f b6 06             	movzbl (%esi),%eax
f010098f:	84 c0                	test   %al,%al
f0100991:	0f 85 60 ff ff ff    	jne    f01008f7 <monitor+0x39>
	argv[argc] = 0;
f0100997:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f010099a:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f01009a1:	00 
	if (argc == 0)
f01009a2:	85 c0                	test   %eax,%eax
f01009a4:	74 9b                	je     f0100941 <monitor+0x83>
		if (strcmp(argv[0], commands[i].name) == 0)
f01009a6:	83 ec 08             	sub    $0x8,%esp
f01009a9:	8d 83 56 0a ff ff    	lea    -0xf5aa(%ebx),%eax
f01009af:	50                   	push   %eax
f01009b0:	ff 75 a8             	pushl  -0x58(%ebp)
f01009b3:	e8 bb 0b 00 00       	call   f0101573 <strcmp>
f01009b8:	83 c4 10             	add    $0x10,%esp
f01009bb:	85 c0                	test   %eax,%eax
f01009bd:	74 38                	je     f01009f7 <monitor+0x139>
f01009bf:	83 ec 08             	sub    $0x8,%esp
f01009c2:	8d 83 64 0a ff ff    	lea    -0xf59c(%ebx),%eax
f01009c8:	50                   	push   %eax
f01009c9:	ff 75 a8             	pushl  -0x58(%ebp)
f01009cc:	e8 a2 0b 00 00       	call   f0101573 <strcmp>
f01009d1:	83 c4 10             	add    $0x10,%esp
f01009d4:	85 c0                	test   %eax,%eax
f01009d6:	74 1a                	je     f01009f2 <monitor+0x134>
	cprintf("Unknown command '%s'\n", argv[0]);
f01009d8:	83 ec 08             	sub    $0x8,%esp
f01009db:	ff 75 a8             	pushl  -0x58(%ebp)
f01009de:	8d 83 ac 0a ff ff    	lea    -0xf554(%ebx),%eax
f01009e4:	50                   	push   %eax
f01009e5:	e8 90 00 00 00       	call   f0100a7a <cprintf>
f01009ea:	83 c4 10             	add    $0x10,%esp
f01009ed:	e9 4f ff ff ff       	jmp    f0100941 <monitor+0x83>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f01009f2:	b8 01 00 00 00       	mov    $0x1,%eax
			return commands[i].func(argc, argv, tf);
f01009f7:	83 ec 04             	sub    $0x4,%esp
f01009fa:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01009fd:	ff 75 08             	pushl  0x8(%ebp)
f0100a00:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a03:	52                   	push   %edx
f0100a04:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100a07:	ff 94 83 10 1d 00 00 	call   *0x1d10(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100a0e:	83 c4 10             	add    $0x10,%esp
f0100a11:	85 c0                	test   %eax,%eax
f0100a13:	0f 89 28 ff ff ff    	jns    f0100941 <monitor+0x83>
				break;
	}
}
f0100a19:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a1c:	5b                   	pop    %ebx
f0100a1d:	5e                   	pop    %esi
f0100a1e:	5f                   	pop    %edi
f0100a1f:	5d                   	pop    %ebp
f0100a20:	c3                   	ret    

f0100a21 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100a21:	55                   	push   %ebp
f0100a22:	89 e5                	mov    %esp,%ebp
f0100a24:	53                   	push   %ebx
f0100a25:	83 ec 10             	sub    $0x10,%esp
f0100a28:	e8 c0 f7 ff ff       	call   f01001ed <__x86.get_pc_thunk.bx>
f0100a2d:	81 c3 db 08 01 00    	add    $0x108db,%ebx
	cputchar(ch);
f0100a33:	ff 75 08             	pushl  0x8(%ebp)
f0100a36:	e8 29 fd ff ff       	call   f0100764 <cputchar>
	*cnt++;
}
f0100a3b:	83 c4 10             	add    $0x10,%esp
f0100a3e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100a41:	c9                   	leave  
f0100a42:	c3                   	ret    

f0100a43 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100a43:	55                   	push   %ebp
f0100a44:	89 e5                	mov    %esp,%ebp
f0100a46:	53                   	push   %ebx
f0100a47:	83 ec 14             	sub    $0x14,%esp
f0100a4a:	e8 9e f7 ff ff       	call   f01001ed <__x86.get_pc_thunk.bx>
f0100a4f:	81 c3 b9 08 01 00    	add    $0x108b9,%ebx
	int cnt = 0;
f0100a55:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100a5c:	ff 75 0c             	pushl  0xc(%ebp)
f0100a5f:	ff 75 08             	pushl  0x8(%ebp)
f0100a62:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100a65:	50                   	push   %eax
f0100a66:	8d 83 19 f7 fe ff    	lea    -0x108e7(%ebx),%eax
f0100a6c:	50                   	push   %eax
f0100a6d:	e8 1c 04 00 00       	call   f0100e8e <vprintfmt>
	return cnt;
}
f0100a72:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100a75:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100a78:	c9                   	leave  
f0100a79:	c3                   	ret    

f0100a7a <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100a7a:	55                   	push   %ebp
f0100a7b:	89 e5                	mov    %esp,%ebp
f0100a7d:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100a80:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100a83:	50                   	push   %eax
f0100a84:	ff 75 08             	pushl  0x8(%ebp)
f0100a87:	e8 b7 ff ff ff       	call   f0100a43 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100a8c:	c9                   	leave  
f0100a8d:	c3                   	ret    

f0100a8e <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100a8e:	55                   	push   %ebp
f0100a8f:	89 e5                	mov    %esp,%ebp
f0100a91:	57                   	push   %edi
f0100a92:	56                   	push   %esi
f0100a93:	53                   	push   %ebx
f0100a94:	83 ec 14             	sub    $0x14,%esp
f0100a97:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100a9a:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100a9d:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100aa0:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100aa3:	8b 32                	mov    (%edx),%esi
f0100aa5:	8b 01                	mov    (%ecx),%eax
f0100aa7:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100aaa:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100ab1:	eb 2f                	jmp    f0100ae2 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0100ab3:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0100ab6:	39 c6                	cmp    %eax,%esi
f0100ab8:	7f 49                	jg     f0100b03 <stab_binsearch+0x75>
f0100aba:	0f b6 0a             	movzbl (%edx),%ecx
f0100abd:	83 ea 0c             	sub    $0xc,%edx
f0100ac0:	39 f9                	cmp    %edi,%ecx
f0100ac2:	75 ef                	jne    f0100ab3 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100ac4:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100ac7:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100aca:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100ace:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100ad1:	73 35                	jae    f0100b08 <stab_binsearch+0x7a>
			*region_left = m;
f0100ad3:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100ad6:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0100ad8:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f0100adb:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0100ae2:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0100ae5:	7f 4e                	jg     f0100b35 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0100ae7:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100aea:	01 f0                	add    %esi,%eax
f0100aec:	89 c3                	mov    %eax,%ebx
f0100aee:	c1 eb 1f             	shr    $0x1f,%ebx
f0100af1:	01 c3                	add    %eax,%ebx
f0100af3:	d1 fb                	sar    %ebx
f0100af5:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100af8:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100afb:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0100aff:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0100b01:	eb b3                	jmp    f0100ab6 <stab_binsearch+0x28>
			l = true_m + 1;
f0100b03:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0100b06:	eb da                	jmp    f0100ae2 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0100b08:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100b0b:	76 14                	jbe    f0100b21 <stab_binsearch+0x93>
			*region_right = m - 1;
f0100b0d:	83 e8 01             	sub    $0x1,%eax
f0100b10:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100b13:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100b16:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0100b18:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100b1f:	eb c1                	jmp    f0100ae2 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100b21:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100b24:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100b26:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100b2a:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f0100b2c:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100b33:	eb ad                	jmp    f0100ae2 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0100b35:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100b39:	74 16                	je     f0100b51 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100b3b:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b3e:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100b40:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100b43:	8b 0e                	mov    (%esi),%ecx
f0100b45:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100b48:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100b4b:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f0100b4f:	eb 12                	jmp    f0100b63 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0100b51:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b54:	8b 00                	mov    (%eax),%eax
f0100b56:	83 e8 01             	sub    $0x1,%eax
f0100b59:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100b5c:	89 07                	mov    %eax,(%edi)
f0100b5e:	eb 16                	jmp    f0100b76 <stab_binsearch+0xe8>
		     l--)
f0100b60:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0100b63:	39 c1                	cmp    %eax,%ecx
f0100b65:	7d 0a                	jge    f0100b71 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0100b67:	0f b6 1a             	movzbl (%edx),%ebx
f0100b6a:	83 ea 0c             	sub    $0xc,%edx
f0100b6d:	39 fb                	cmp    %edi,%ebx
f0100b6f:	75 ef                	jne    f0100b60 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f0100b71:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100b74:	89 07                	mov    %eax,(%edi)
	}
}
f0100b76:	83 c4 14             	add    $0x14,%esp
f0100b79:	5b                   	pop    %ebx
f0100b7a:	5e                   	pop    %esi
f0100b7b:	5f                   	pop    %edi
f0100b7c:	5d                   	pop    %ebp
f0100b7d:	c3                   	ret    

f0100b7e <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100b7e:	55                   	push   %ebp
f0100b7f:	89 e5                	mov    %esp,%ebp
f0100b81:	57                   	push   %edi
f0100b82:	56                   	push   %esi
f0100b83:	53                   	push   %ebx
f0100b84:	83 ec 2c             	sub    $0x2c,%esp
f0100b87:	e8 fa 01 00 00       	call   f0100d86 <__x86.get_pc_thunk.cx>
f0100b8c:	81 c1 7c 07 01 00    	add    $0x1077c,%ecx
f0100b92:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0100b95:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100b98:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100b9b:	8d 81 1c 0c ff ff    	lea    -0xf3e4(%ecx),%eax
f0100ba1:	89 07                	mov    %eax,(%edi)
	info->eip_line = 0;
f0100ba3:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f0100baa:	89 47 08             	mov    %eax,0x8(%edi)
	info->eip_fn_namelen = 9;
f0100bad:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f0100bb4:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f0100bb7:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100bbe:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0100bc4:	0f 86 f4 00 00 00    	jbe    f0100cbe <debuginfo_eip+0x140>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100bca:	c7 c0 49 5d 10 f0    	mov    $0xf0105d49,%eax
f0100bd0:	39 81 fc ff ff ff    	cmp    %eax,-0x4(%ecx)
f0100bd6:	0f 86 88 01 00 00    	jbe    f0100d64 <debuginfo_eip+0x1e6>
f0100bdc:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0100bdf:	c7 c0 98 76 10 f0    	mov    $0xf0107698,%eax
f0100be5:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0100be9:	0f 85 7c 01 00 00    	jne    f0100d6b <debuginfo_eip+0x1ed>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100bef:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100bf6:	c7 c0 3c 21 10 f0    	mov    $0xf010213c,%eax
f0100bfc:	c7 c2 48 5d 10 f0    	mov    $0xf0105d48,%edx
f0100c02:	29 c2                	sub    %eax,%edx
f0100c04:	c1 fa 02             	sar    $0x2,%edx
f0100c07:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0100c0d:	83 ea 01             	sub    $0x1,%edx
f0100c10:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100c13:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100c16:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100c19:	83 ec 08             	sub    $0x8,%esp
f0100c1c:	53                   	push   %ebx
f0100c1d:	6a 64                	push   $0x64
f0100c1f:	e8 6a fe ff ff       	call   f0100a8e <stab_binsearch>
	if (lfile == 0)
f0100c24:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c27:	83 c4 10             	add    $0x10,%esp
f0100c2a:	85 c0                	test   %eax,%eax
f0100c2c:	0f 84 40 01 00 00    	je     f0100d72 <debuginfo_eip+0x1f4>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100c32:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100c35:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c38:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100c3b:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100c3e:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c41:	83 ec 08             	sub    $0x8,%esp
f0100c44:	53                   	push   %ebx
f0100c45:	6a 24                	push   $0x24
f0100c47:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0100c4a:	c7 c0 3c 21 10 f0    	mov    $0xf010213c,%eax
f0100c50:	e8 39 fe ff ff       	call   f0100a8e <stab_binsearch>

	if (lfun <= rfun) {
f0100c55:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0100c58:	83 c4 10             	add    $0x10,%esp
f0100c5b:	3b 75 d8             	cmp    -0x28(%ebp),%esi
f0100c5e:	7f 79                	jg     f0100cd9 <debuginfo_eip+0x15b>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100c60:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100c63:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100c66:	c7 c2 3c 21 10 f0    	mov    $0xf010213c,%edx
f0100c6c:	8d 0c 82             	lea    (%edx,%eax,4),%ecx
f0100c6f:	8b 11                	mov    (%ecx),%edx
f0100c71:	c7 c0 98 76 10 f0    	mov    $0xf0107698,%eax
f0100c77:	81 e8 49 5d 10 f0    	sub    $0xf0105d49,%eax
f0100c7d:	39 c2                	cmp    %eax,%edx
f0100c7f:	73 09                	jae    f0100c8a <debuginfo_eip+0x10c>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100c81:	81 c2 49 5d 10 f0    	add    $0xf0105d49,%edx
f0100c87:	89 57 08             	mov    %edx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100c8a:	8b 41 08             	mov    0x8(%ecx),%eax
f0100c8d:	89 47 10             	mov    %eax,0x10(%edi)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100c90:	83 ec 08             	sub    $0x8,%esp
f0100c93:	6a 3a                	push   $0x3a
f0100c95:	ff 77 08             	pushl  0x8(%edi)
f0100c98:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100c9b:	e8 52 09 00 00       	call   f01015f2 <strfind>
f0100ca0:	2b 47 08             	sub    0x8(%edi),%eax
f0100ca3:	89 47 0c             	mov    %eax,0xc(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100ca6:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100ca9:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100cac:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100caf:	c7 c2 3c 21 10 f0    	mov    $0xf010213c,%edx
f0100cb5:	8d 44 82 04          	lea    0x4(%edx,%eax,4),%eax
f0100cb9:	83 c4 10             	add    $0x10,%esp
f0100cbc:	eb 29                	jmp    f0100ce7 <debuginfo_eip+0x169>
  	        panic("User address");
f0100cbe:	83 ec 04             	sub    $0x4,%esp
f0100cc1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100cc4:	8d 83 26 0c ff ff    	lea    -0xf3da(%ebx),%eax
f0100cca:	50                   	push   %eax
f0100ccb:	6a 7f                	push   $0x7f
f0100ccd:	8d 83 33 0c ff ff    	lea    -0xf3cd(%ebx),%eax
f0100cd3:	50                   	push   %eax
f0100cd4:	e8 5e f4 ff ff       	call   f0100137 <_panic>
		info->eip_fn_addr = addr;
f0100cd9:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f0100cdc:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100cdf:	eb af                	jmp    f0100c90 <debuginfo_eip+0x112>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100ce1:	83 ee 01             	sub    $0x1,%esi
f0100ce4:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f0100ce7:	39 f3                	cmp    %esi,%ebx
f0100ce9:	7f 3a                	jg     f0100d25 <debuginfo_eip+0x1a7>
	       && stabs[lline].n_type != N_SOL
f0100ceb:	0f b6 10             	movzbl (%eax),%edx
f0100cee:	80 fa 84             	cmp    $0x84,%dl
f0100cf1:	74 0b                	je     f0100cfe <debuginfo_eip+0x180>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100cf3:	80 fa 64             	cmp    $0x64,%dl
f0100cf6:	75 e9                	jne    f0100ce1 <debuginfo_eip+0x163>
f0100cf8:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f0100cfc:	74 e3                	je     f0100ce1 <debuginfo_eip+0x163>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100cfe:	8d 14 76             	lea    (%esi,%esi,2),%edx
f0100d01:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100d04:	c7 c0 3c 21 10 f0    	mov    $0xf010213c,%eax
f0100d0a:	8b 14 90             	mov    (%eax,%edx,4),%edx
f0100d0d:	c7 c0 98 76 10 f0    	mov    $0xf0107698,%eax
f0100d13:	81 e8 49 5d 10 f0    	sub    $0xf0105d49,%eax
f0100d19:	39 c2                	cmp    %eax,%edx
f0100d1b:	73 08                	jae    f0100d25 <debuginfo_eip+0x1a7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100d1d:	81 c2 49 5d 10 f0    	add    $0xf0105d49,%edx
f0100d23:	89 17                	mov    %edx,(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100d25:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100d28:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100d2b:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0100d30:	39 cb                	cmp    %ecx,%ebx
f0100d32:	7d 4a                	jge    f0100d7e <debuginfo_eip+0x200>
		for (lline = lfun + 1;
f0100d34:	8d 53 01             	lea    0x1(%ebx),%edx
f0100d37:	8d 1c 5b             	lea    (%ebx,%ebx,2),%ebx
f0100d3a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100d3d:	c7 c0 3c 21 10 f0    	mov    $0xf010213c,%eax
f0100d43:	8d 44 98 10          	lea    0x10(%eax,%ebx,4),%eax
f0100d47:	eb 07                	jmp    f0100d50 <debuginfo_eip+0x1d2>
			info->eip_fn_narg++;
f0100d49:	83 47 14 01          	addl   $0x1,0x14(%edi)
		     lline++)
f0100d4d:	83 c2 01             	add    $0x1,%edx
		for (lline = lfun + 1;
f0100d50:	39 d1                	cmp    %edx,%ecx
f0100d52:	74 25                	je     f0100d79 <debuginfo_eip+0x1fb>
f0100d54:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100d57:	80 78 f4 a0          	cmpb   $0xa0,-0xc(%eax)
f0100d5b:	74 ec                	je     f0100d49 <debuginfo_eip+0x1cb>
	return 0;
f0100d5d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d62:	eb 1a                	jmp    f0100d7e <debuginfo_eip+0x200>
		return -1;
f0100d64:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d69:	eb 13                	jmp    f0100d7e <debuginfo_eip+0x200>
f0100d6b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d70:	eb 0c                	jmp    f0100d7e <debuginfo_eip+0x200>
		return -1;
f0100d72:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100d77:	eb 05                	jmp    f0100d7e <debuginfo_eip+0x200>
	return 0;
f0100d79:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100d7e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100d81:	5b                   	pop    %ebx
f0100d82:	5e                   	pop    %esi
f0100d83:	5f                   	pop    %edi
f0100d84:	5d                   	pop    %ebp
f0100d85:	c3                   	ret    

f0100d86 <__x86.get_pc_thunk.cx>:
f0100d86:	8b 0c 24             	mov    (%esp),%ecx
f0100d89:	c3                   	ret    

f0100d8a <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100d8a:	55                   	push   %ebp
f0100d8b:	89 e5                	mov    %esp,%ebp
f0100d8d:	57                   	push   %edi
f0100d8e:	56                   	push   %esi
f0100d8f:	53                   	push   %ebx
f0100d90:	83 ec 2c             	sub    $0x2c,%esp
f0100d93:	e8 ee ff ff ff       	call   f0100d86 <__x86.get_pc_thunk.cx>
f0100d98:	81 c1 70 05 01 00    	add    $0x10570,%ecx
f0100d9e:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100da1:	89 c7                	mov    %eax,%edi
f0100da3:	89 d6                	mov    %edx,%esi
f0100da5:	8b 45 08             	mov    0x8(%ebp),%eax
f0100da8:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100dab:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100dae:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100db1:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100db4:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100db9:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f0100dbc:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0100dbf:	39 d3                	cmp    %edx,%ebx
f0100dc1:	72 09                	jb     f0100dcc <printnum+0x42>
f0100dc3:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100dc6:	0f 87 83 00 00 00    	ja     f0100e4f <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100dcc:	83 ec 0c             	sub    $0xc,%esp
f0100dcf:	ff 75 18             	pushl  0x18(%ebp)
f0100dd2:	8b 45 14             	mov    0x14(%ebp),%eax
f0100dd5:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100dd8:	53                   	push   %ebx
f0100dd9:	ff 75 10             	pushl  0x10(%ebp)
f0100ddc:	83 ec 08             	sub    $0x8,%esp
f0100ddf:	ff 75 dc             	pushl  -0x24(%ebp)
f0100de2:	ff 75 d8             	pushl  -0x28(%ebp)
f0100de5:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100de8:	ff 75 d0             	pushl  -0x30(%ebp)
f0100deb:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100dee:	e8 1d 0a 00 00       	call   f0101810 <__udivdi3>
f0100df3:	83 c4 18             	add    $0x18,%esp
f0100df6:	52                   	push   %edx
f0100df7:	50                   	push   %eax
f0100df8:	89 f2                	mov    %esi,%edx
f0100dfa:	89 f8                	mov    %edi,%eax
f0100dfc:	e8 89 ff ff ff       	call   f0100d8a <printnum>
f0100e01:	83 c4 20             	add    $0x20,%esp
f0100e04:	eb 13                	jmp    f0100e19 <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100e06:	83 ec 08             	sub    $0x8,%esp
f0100e09:	56                   	push   %esi
f0100e0a:	ff 75 18             	pushl  0x18(%ebp)
f0100e0d:	ff d7                	call   *%edi
f0100e0f:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0100e12:	83 eb 01             	sub    $0x1,%ebx
f0100e15:	85 db                	test   %ebx,%ebx
f0100e17:	7f ed                	jg     f0100e06 <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100e19:	83 ec 08             	sub    $0x8,%esp
f0100e1c:	56                   	push   %esi
f0100e1d:	83 ec 04             	sub    $0x4,%esp
f0100e20:	ff 75 dc             	pushl  -0x24(%ebp)
f0100e23:	ff 75 d8             	pushl  -0x28(%ebp)
f0100e26:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100e29:	ff 75 d0             	pushl  -0x30(%ebp)
f0100e2c:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100e2f:	89 f3                	mov    %esi,%ebx
f0100e31:	e8 fa 0a 00 00       	call   f0101930 <__umoddi3>
f0100e36:	83 c4 14             	add    $0x14,%esp
f0100e39:	0f be 84 06 41 0c ff 	movsbl -0xf3bf(%esi,%eax,1),%eax
f0100e40:	ff 
f0100e41:	50                   	push   %eax
f0100e42:	ff d7                	call   *%edi
}
f0100e44:	83 c4 10             	add    $0x10,%esp
f0100e47:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e4a:	5b                   	pop    %ebx
f0100e4b:	5e                   	pop    %esi
f0100e4c:	5f                   	pop    %edi
f0100e4d:	5d                   	pop    %ebp
f0100e4e:	c3                   	ret    
f0100e4f:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100e52:	eb be                	jmp    f0100e12 <printnum+0x88>

f0100e54 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100e54:	55                   	push   %ebp
f0100e55:	89 e5                	mov    %esp,%ebp
f0100e57:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100e5a:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100e5e:	8b 10                	mov    (%eax),%edx
f0100e60:	3b 50 04             	cmp    0x4(%eax),%edx
f0100e63:	73 0a                	jae    f0100e6f <sprintputch+0x1b>
		*b->buf++ = ch;
f0100e65:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100e68:	89 08                	mov    %ecx,(%eax)
f0100e6a:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e6d:	88 02                	mov    %al,(%edx)
}
f0100e6f:	5d                   	pop    %ebp
f0100e70:	c3                   	ret    

f0100e71 <printfmt>:
{
f0100e71:	55                   	push   %ebp
f0100e72:	89 e5                	mov    %esp,%ebp
f0100e74:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0100e77:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100e7a:	50                   	push   %eax
f0100e7b:	ff 75 10             	pushl  0x10(%ebp)
f0100e7e:	ff 75 0c             	pushl  0xc(%ebp)
f0100e81:	ff 75 08             	pushl  0x8(%ebp)
f0100e84:	e8 05 00 00 00       	call   f0100e8e <vprintfmt>
}
f0100e89:	83 c4 10             	add    $0x10,%esp
f0100e8c:	c9                   	leave  
f0100e8d:	c3                   	ret    

f0100e8e <vprintfmt>:
{
f0100e8e:	55                   	push   %ebp
f0100e8f:	89 e5                	mov    %esp,%ebp
f0100e91:	57                   	push   %edi
f0100e92:	56                   	push   %esi
f0100e93:	53                   	push   %ebx
f0100e94:	83 ec 2c             	sub    $0x2c,%esp
f0100e97:	e8 51 f3 ff ff       	call   f01001ed <__x86.get_pc_thunk.bx>
f0100e9c:	81 c3 6c 04 01 00    	add    $0x1046c,%ebx
f0100ea2:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100ea5:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100ea8:	e9 63 03 00 00       	jmp    f0101210 <.L34+0x40>
		padc = ' ';
f0100ead:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f0100eb1:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0100eb8:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
		width = -1;
f0100ebf:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0100ec6:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100ecb:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100ece:	8d 47 01             	lea    0x1(%edi),%eax
f0100ed1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100ed4:	0f b6 17             	movzbl (%edi),%edx
f0100ed7:	8d 42 dd             	lea    -0x23(%edx),%eax
f0100eda:	3c 55                	cmp    $0x55,%al
f0100edc:	0f 87 15 04 00 00    	ja     f01012f7 <.L22>
f0100ee2:	0f b6 c0             	movzbl %al,%eax
f0100ee5:	89 d9                	mov    %ebx,%ecx
f0100ee7:	03 8c 83 cc 0c ff ff 	add    -0xf334(%ebx,%eax,4),%ecx
f0100eee:	ff e1                	jmp    *%ecx

f0100ef0 <.L70>:
f0100ef0:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0100ef3:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0100ef7:	eb d5                	jmp    f0100ece <vprintfmt+0x40>

f0100ef9 <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f0100ef9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f0100efc:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100f00:	eb cc                	jmp    f0100ece <vprintfmt+0x40>

f0100f02 <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f0100f02:	0f b6 d2             	movzbl %dl,%edx
f0100f05:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0100f08:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f0100f0d:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100f10:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0100f14:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0100f17:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0100f1a:	83 f9 09             	cmp    $0x9,%ecx
f0100f1d:	77 55                	ja     f0100f74 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f0100f1f:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0100f22:	eb e9                	jmp    f0100f0d <.L29+0xb>

f0100f24 <.L26>:
			precision = va_arg(ap, int);
f0100f24:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f27:	8b 00                	mov    (%eax),%eax
f0100f29:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100f2c:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f2f:	8d 40 04             	lea    0x4(%eax),%eax
f0100f32:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100f35:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0100f38:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100f3c:	79 90                	jns    f0100ece <vprintfmt+0x40>
				width = precision, precision = -1;
f0100f3e:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0100f41:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100f44:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f0100f4b:	eb 81                	jmp    f0100ece <vprintfmt+0x40>

f0100f4d <.L27>:
f0100f4d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f50:	85 c0                	test   %eax,%eax
f0100f52:	ba 00 00 00 00       	mov    $0x0,%edx
f0100f57:	0f 49 d0             	cmovns %eax,%edx
f0100f5a:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100f5d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100f60:	e9 69 ff ff ff       	jmp    f0100ece <vprintfmt+0x40>

f0100f65 <.L23>:
f0100f65:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0100f68:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0100f6f:	e9 5a ff ff ff       	jmp    f0100ece <vprintfmt+0x40>
f0100f74:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100f77:	eb bf                	jmp    f0100f38 <.L26+0x14>

f0100f79 <.L33>:
			lflag++;
f0100f79:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100f7d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0100f80:	e9 49 ff ff ff       	jmp    f0100ece <vprintfmt+0x40>

f0100f85 <.L30>:
			putch(va_arg(ap, int), putdat);
f0100f85:	8b 45 14             	mov    0x14(%ebp),%eax
f0100f88:	8d 78 04             	lea    0x4(%eax),%edi
f0100f8b:	83 ec 08             	sub    $0x8,%esp
f0100f8e:	56                   	push   %esi
f0100f8f:	ff 30                	pushl  (%eax)
f0100f91:	ff 55 08             	call   *0x8(%ebp)
			break;
f0100f94:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0100f97:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0100f9a:	e9 6e 02 00 00       	jmp    f010120d <.L34+0x3d>

f0100f9f <.L32>:
			err = va_arg(ap, int);
f0100f9f:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fa2:	8d 78 04             	lea    0x4(%eax),%edi
f0100fa5:	8b 00                	mov    (%eax),%eax
f0100fa7:	99                   	cltd   
f0100fa8:	31 d0                	xor    %edx,%eax
f0100faa:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0100fac:	83 f8 06             	cmp    $0x6,%eax
f0100faf:	7f 27                	jg     f0100fd8 <.L32+0x39>
f0100fb1:	8b 94 83 20 1d 00 00 	mov    0x1d20(%ebx,%eax,4),%edx
f0100fb8:	85 d2                	test   %edx,%edx
f0100fba:	74 1c                	je     f0100fd8 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f0100fbc:	52                   	push   %edx
f0100fbd:	8d 83 c2 07 ff ff    	lea    -0xf83e(%ebx),%eax
f0100fc3:	50                   	push   %eax
f0100fc4:	56                   	push   %esi
f0100fc5:	ff 75 08             	pushl  0x8(%ebp)
f0100fc8:	e8 a4 fe ff ff       	call   f0100e71 <printfmt>
f0100fcd:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0100fd0:	89 7d 14             	mov    %edi,0x14(%ebp)
f0100fd3:	e9 35 02 00 00       	jmp    f010120d <.L34+0x3d>
				printfmt(putch, putdat, "error %d", err);
f0100fd8:	50                   	push   %eax
f0100fd9:	8d 83 59 0c ff ff    	lea    -0xf3a7(%ebx),%eax
f0100fdf:	50                   	push   %eax
f0100fe0:	56                   	push   %esi
f0100fe1:	ff 75 08             	pushl  0x8(%ebp)
f0100fe4:	e8 88 fe ff ff       	call   f0100e71 <printfmt>
f0100fe9:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0100fec:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0100fef:	e9 19 02 00 00       	jmp    f010120d <.L34+0x3d>

f0100ff4 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f0100ff4:	8b 45 14             	mov    0x14(%ebp),%eax
f0100ff7:	83 c0 04             	add    $0x4,%eax
f0100ffa:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100ffd:	8b 45 14             	mov    0x14(%ebp),%eax
f0101000:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0101002:	85 ff                	test   %edi,%edi
f0101004:	8d 83 52 0c ff ff    	lea    -0xf3ae(%ebx),%eax
f010100a:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f010100d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0101011:	0f 8e b5 00 00 00    	jle    f01010cc <.L36+0xd8>
f0101017:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f010101b:	75 08                	jne    f0101025 <.L36+0x31>
f010101d:	89 75 0c             	mov    %esi,0xc(%ebp)
f0101020:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0101023:	eb 6d                	jmp    f0101092 <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f0101025:	83 ec 08             	sub    $0x8,%esp
f0101028:	ff 75 cc             	pushl  -0x34(%ebp)
f010102b:	57                   	push   %edi
f010102c:	e8 7d 04 00 00       	call   f01014ae <strnlen>
f0101031:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101034:	29 c2                	sub    %eax,%edx
f0101036:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0101039:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f010103c:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0101040:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0101043:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101046:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0101048:	eb 10                	jmp    f010105a <.L36+0x66>
					putch(padc, putdat);
f010104a:	83 ec 08             	sub    $0x8,%esp
f010104d:	56                   	push   %esi
f010104e:	ff 75 e0             	pushl  -0x20(%ebp)
f0101051:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0101054:	83 ef 01             	sub    $0x1,%edi
f0101057:	83 c4 10             	add    $0x10,%esp
f010105a:	85 ff                	test   %edi,%edi
f010105c:	7f ec                	jg     f010104a <.L36+0x56>
f010105e:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101061:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0101064:	85 d2                	test   %edx,%edx
f0101066:	b8 00 00 00 00       	mov    $0x0,%eax
f010106b:	0f 49 c2             	cmovns %edx,%eax
f010106e:	29 c2                	sub    %eax,%edx
f0101070:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101073:	89 75 0c             	mov    %esi,0xc(%ebp)
f0101076:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0101079:	eb 17                	jmp    f0101092 <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f010107b:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f010107f:	75 30                	jne    f01010b1 <.L36+0xbd>
					putch(ch, putdat);
f0101081:	83 ec 08             	sub    $0x8,%esp
f0101084:	ff 75 0c             	pushl  0xc(%ebp)
f0101087:	50                   	push   %eax
f0101088:	ff 55 08             	call   *0x8(%ebp)
f010108b:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010108e:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f0101092:	83 c7 01             	add    $0x1,%edi
f0101095:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0101099:	0f be c2             	movsbl %dl,%eax
f010109c:	85 c0                	test   %eax,%eax
f010109e:	74 52                	je     f01010f2 <.L36+0xfe>
f01010a0:	85 f6                	test   %esi,%esi
f01010a2:	78 d7                	js     f010107b <.L36+0x87>
f01010a4:	83 ee 01             	sub    $0x1,%esi
f01010a7:	79 d2                	jns    f010107b <.L36+0x87>
f01010a9:	8b 75 0c             	mov    0xc(%ebp),%esi
f01010ac:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01010af:	eb 32                	jmp    f01010e3 <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f01010b1:	0f be d2             	movsbl %dl,%edx
f01010b4:	83 ea 20             	sub    $0x20,%edx
f01010b7:	83 fa 5e             	cmp    $0x5e,%edx
f01010ba:	76 c5                	jbe    f0101081 <.L36+0x8d>
					putch('?', putdat);
f01010bc:	83 ec 08             	sub    $0x8,%esp
f01010bf:	ff 75 0c             	pushl  0xc(%ebp)
f01010c2:	6a 3f                	push   $0x3f
f01010c4:	ff 55 08             	call   *0x8(%ebp)
f01010c7:	83 c4 10             	add    $0x10,%esp
f01010ca:	eb c2                	jmp    f010108e <.L36+0x9a>
f01010cc:	89 75 0c             	mov    %esi,0xc(%ebp)
f01010cf:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01010d2:	eb be                	jmp    f0101092 <.L36+0x9e>
				putch(' ', putdat);
f01010d4:	83 ec 08             	sub    $0x8,%esp
f01010d7:	56                   	push   %esi
f01010d8:	6a 20                	push   $0x20
f01010da:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f01010dd:	83 ef 01             	sub    $0x1,%edi
f01010e0:	83 c4 10             	add    $0x10,%esp
f01010e3:	85 ff                	test   %edi,%edi
f01010e5:	7f ed                	jg     f01010d4 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f01010e7:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01010ea:	89 45 14             	mov    %eax,0x14(%ebp)
f01010ed:	e9 1b 01 00 00       	jmp    f010120d <.L34+0x3d>
f01010f2:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01010f5:	8b 75 0c             	mov    0xc(%ebp),%esi
f01010f8:	eb e9                	jmp    f01010e3 <.L36+0xef>

f01010fa <.L31>:
f01010fa:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01010fd:	83 f9 01             	cmp    $0x1,%ecx
f0101100:	7e 40                	jle    f0101142 <.L31+0x48>
		return va_arg(*ap, long long);
f0101102:	8b 45 14             	mov    0x14(%ebp),%eax
f0101105:	8b 50 04             	mov    0x4(%eax),%edx
f0101108:	8b 00                	mov    (%eax),%eax
f010110a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010110d:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101110:	8b 45 14             	mov    0x14(%ebp),%eax
f0101113:	8d 40 08             	lea    0x8(%eax),%eax
f0101116:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0101119:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f010111d:	79 55                	jns    f0101174 <.L31+0x7a>
				putch('-', putdat);
f010111f:	83 ec 08             	sub    $0x8,%esp
f0101122:	56                   	push   %esi
f0101123:	6a 2d                	push   $0x2d
f0101125:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0101128:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010112b:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010112e:	f7 da                	neg    %edx
f0101130:	83 d1 00             	adc    $0x0,%ecx
f0101133:	f7 d9                	neg    %ecx
f0101135:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0101138:	b8 0a 00 00 00       	mov    $0xa,%eax
f010113d:	e9 b0 00 00 00       	jmp    f01011f2 <.L34+0x22>
	else if (lflag)
f0101142:	85 c9                	test   %ecx,%ecx
f0101144:	75 17                	jne    f010115d <.L31+0x63>
		return va_arg(*ap, int);
f0101146:	8b 45 14             	mov    0x14(%ebp),%eax
f0101149:	8b 00                	mov    (%eax),%eax
f010114b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f010114e:	99                   	cltd   
f010114f:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101152:	8b 45 14             	mov    0x14(%ebp),%eax
f0101155:	8d 40 04             	lea    0x4(%eax),%eax
f0101158:	89 45 14             	mov    %eax,0x14(%ebp)
f010115b:	eb bc                	jmp    f0101119 <.L31+0x1f>
		return va_arg(*ap, long);
f010115d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101160:	8b 00                	mov    (%eax),%eax
f0101162:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101165:	99                   	cltd   
f0101166:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101169:	8b 45 14             	mov    0x14(%ebp),%eax
f010116c:	8d 40 04             	lea    0x4(%eax),%eax
f010116f:	89 45 14             	mov    %eax,0x14(%ebp)
f0101172:	eb a5                	jmp    f0101119 <.L31+0x1f>
			num = getint(&ap, lflag);
f0101174:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101177:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f010117a:	b8 0a 00 00 00       	mov    $0xa,%eax
f010117f:	eb 71                	jmp    f01011f2 <.L34+0x22>

f0101181 <.L37>:
f0101181:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0101184:	83 f9 01             	cmp    $0x1,%ecx
f0101187:	7e 15                	jle    f010119e <.L37+0x1d>
		return va_arg(*ap, unsigned long long);
f0101189:	8b 45 14             	mov    0x14(%ebp),%eax
f010118c:	8b 10                	mov    (%eax),%edx
f010118e:	8b 48 04             	mov    0x4(%eax),%ecx
f0101191:	8d 40 08             	lea    0x8(%eax),%eax
f0101194:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101197:	b8 0a 00 00 00       	mov    $0xa,%eax
f010119c:	eb 54                	jmp    f01011f2 <.L34+0x22>
	else if (lflag)
f010119e:	85 c9                	test   %ecx,%ecx
f01011a0:	75 17                	jne    f01011b9 <.L37+0x38>
		return va_arg(*ap, unsigned int);
f01011a2:	8b 45 14             	mov    0x14(%ebp),%eax
f01011a5:	8b 10                	mov    (%eax),%edx
f01011a7:	b9 00 00 00 00       	mov    $0x0,%ecx
f01011ac:	8d 40 04             	lea    0x4(%eax),%eax
f01011af:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01011b2:	b8 0a 00 00 00       	mov    $0xa,%eax
f01011b7:	eb 39                	jmp    f01011f2 <.L34+0x22>
		return va_arg(*ap, unsigned long);
f01011b9:	8b 45 14             	mov    0x14(%ebp),%eax
f01011bc:	8b 10                	mov    (%eax),%edx
f01011be:	b9 00 00 00 00       	mov    $0x0,%ecx
f01011c3:	8d 40 04             	lea    0x4(%eax),%eax
f01011c6:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f01011c9:	b8 0a 00 00 00       	mov    $0xa,%eax
f01011ce:	eb 22                	jmp    f01011f2 <.L34+0x22>

f01011d0 <.L34>:
f01011d0:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01011d3:	83 f9 01             	cmp    $0x1,%ecx
f01011d6:	7e 5d                	jle    f0101235 <.L34+0x65>
		return va_arg(*ap, long long);
f01011d8:	8b 45 14             	mov    0x14(%ebp),%eax
f01011db:	8b 50 04             	mov    0x4(%eax),%edx
f01011de:	8b 00                	mov    (%eax),%eax
f01011e0:	8b 4d 14             	mov    0x14(%ebp),%ecx
f01011e3:	8d 49 08             	lea    0x8(%ecx),%ecx
f01011e6:	89 4d 14             	mov    %ecx,0x14(%ebp)
			num = getint(&ap, lflag);
f01011e9:	89 d1                	mov    %edx,%ecx
f01011eb:	89 c2                	mov    %eax,%edx
			base = 8;
f01011ed:	b8 08 00 00 00       	mov    $0x8,%eax
			printnum(putch, putdat, num, base, width, padc);
f01011f2:	83 ec 0c             	sub    $0xc,%esp
f01011f5:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01011f9:	57                   	push   %edi
f01011fa:	ff 75 e0             	pushl  -0x20(%ebp)
f01011fd:	50                   	push   %eax
f01011fe:	51                   	push   %ecx
f01011ff:	52                   	push   %edx
f0101200:	89 f2                	mov    %esi,%edx
f0101202:	8b 45 08             	mov    0x8(%ebp),%eax
f0101205:	e8 80 fb ff ff       	call   f0100d8a <printnum>
			break;
f010120a:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f010120d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0101210:	83 c7 01             	add    $0x1,%edi
f0101213:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0101217:	83 f8 25             	cmp    $0x25,%eax
f010121a:	0f 84 8d fc ff ff    	je     f0100ead <vprintfmt+0x1f>
			if (ch == '\0')
f0101220:	85 c0                	test   %eax,%eax
f0101222:	0f 84 f0 00 00 00    	je     f0101318 <.L22+0x21>
			putch(ch, putdat);
f0101228:	83 ec 08             	sub    $0x8,%esp
f010122b:	56                   	push   %esi
f010122c:	50                   	push   %eax
f010122d:	ff 55 08             	call   *0x8(%ebp)
f0101230:	83 c4 10             	add    $0x10,%esp
f0101233:	eb db                	jmp    f0101210 <.L34+0x40>
	else if (lflag)
f0101235:	85 c9                	test   %ecx,%ecx
f0101237:	75 13                	jne    f010124c <.L34+0x7c>
		return va_arg(*ap, int);
f0101239:	8b 45 14             	mov    0x14(%ebp),%eax
f010123c:	8b 10                	mov    (%eax),%edx
f010123e:	89 d0                	mov    %edx,%eax
f0101240:	99                   	cltd   
f0101241:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0101244:	8d 49 04             	lea    0x4(%ecx),%ecx
f0101247:	89 4d 14             	mov    %ecx,0x14(%ebp)
f010124a:	eb 9d                	jmp    f01011e9 <.L34+0x19>
		return va_arg(*ap, long);
f010124c:	8b 45 14             	mov    0x14(%ebp),%eax
f010124f:	8b 10                	mov    (%eax),%edx
f0101251:	89 d0                	mov    %edx,%eax
f0101253:	99                   	cltd   
f0101254:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0101257:	8d 49 04             	lea    0x4(%ecx),%ecx
f010125a:	89 4d 14             	mov    %ecx,0x14(%ebp)
f010125d:	eb 8a                	jmp    f01011e9 <.L34+0x19>

f010125f <.L35>:
			putch('0', putdat);
f010125f:	83 ec 08             	sub    $0x8,%esp
f0101262:	56                   	push   %esi
f0101263:	6a 30                	push   $0x30
f0101265:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0101268:	83 c4 08             	add    $0x8,%esp
f010126b:	56                   	push   %esi
f010126c:	6a 78                	push   $0x78
f010126e:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f0101271:	8b 45 14             	mov    0x14(%ebp),%eax
f0101274:	8b 10                	mov    (%eax),%edx
f0101276:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f010127b:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f010127e:	8d 40 04             	lea    0x4(%eax),%eax
f0101281:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101284:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0101289:	e9 64 ff ff ff       	jmp    f01011f2 <.L34+0x22>

f010128e <.L38>:
f010128e:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0101291:	83 f9 01             	cmp    $0x1,%ecx
f0101294:	7e 18                	jle    f01012ae <.L38+0x20>
		return va_arg(*ap, unsigned long long);
f0101296:	8b 45 14             	mov    0x14(%ebp),%eax
f0101299:	8b 10                	mov    (%eax),%edx
f010129b:	8b 48 04             	mov    0x4(%eax),%ecx
f010129e:	8d 40 08             	lea    0x8(%eax),%eax
f01012a1:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01012a4:	b8 10 00 00 00       	mov    $0x10,%eax
f01012a9:	e9 44 ff ff ff       	jmp    f01011f2 <.L34+0x22>
	else if (lflag)
f01012ae:	85 c9                	test   %ecx,%ecx
f01012b0:	75 1a                	jne    f01012cc <.L38+0x3e>
		return va_arg(*ap, unsigned int);
f01012b2:	8b 45 14             	mov    0x14(%ebp),%eax
f01012b5:	8b 10                	mov    (%eax),%edx
f01012b7:	b9 00 00 00 00       	mov    $0x0,%ecx
f01012bc:	8d 40 04             	lea    0x4(%eax),%eax
f01012bf:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01012c2:	b8 10 00 00 00       	mov    $0x10,%eax
f01012c7:	e9 26 ff ff ff       	jmp    f01011f2 <.L34+0x22>
		return va_arg(*ap, unsigned long);
f01012cc:	8b 45 14             	mov    0x14(%ebp),%eax
f01012cf:	8b 10                	mov    (%eax),%edx
f01012d1:	b9 00 00 00 00       	mov    $0x0,%ecx
f01012d6:	8d 40 04             	lea    0x4(%eax),%eax
f01012d9:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f01012dc:	b8 10 00 00 00       	mov    $0x10,%eax
f01012e1:	e9 0c ff ff ff       	jmp    f01011f2 <.L34+0x22>

f01012e6 <.L25>:
			putch(ch, putdat);
f01012e6:	83 ec 08             	sub    $0x8,%esp
f01012e9:	56                   	push   %esi
f01012ea:	6a 25                	push   $0x25
f01012ec:	ff 55 08             	call   *0x8(%ebp)
			break;
f01012ef:	83 c4 10             	add    $0x10,%esp
f01012f2:	e9 16 ff ff ff       	jmp    f010120d <.L34+0x3d>

f01012f7 <.L22>:
			putch('%', putdat);
f01012f7:	83 ec 08             	sub    $0x8,%esp
f01012fa:	56                   	push   %esi
f01012fb:	6a 25                	push   $0x25
f01012fd:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101300:	83 c4 10             	add    $0x10,%esp
f0101303:	89 f8                	mov    %edi,%eax
f0101305:	eb 03                	jmp    f010130a <.L22+0x13>
f0101307:	83 e8 01             	sub    $0x1,%eax
f010130a:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f010130e:	75 f7                	jne    f0101307 <.L22+0x10>
f0101310:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101313:	e9 f5 fe ff ff       	jmp    f010120d <.L34+0x3d>
}
f0101318:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010131b:	5b                   	pop    %ebx
f010131c:	5e                   	pop    %esi
f010131d:	5f                   	pop    %edi
f010131e:	5d                   	pop    %ebp
f010131f:	c3                   	ret    

f0101320 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101320:	55                   	push   %ebp
f0101321:	89 e5                	mov    %esp,%ebp
f0101323:	53                   	push   %ebx
f0101324:	83 ec 14             	sub    $0x14,%esp
f0101327:	e8 c1 ee ff ff       	call   f01001ed <__x86.get_pc_thunk.bx>
f010132c:	81 c3 dc ff 00 00    	add    $0xffdc,%ebx
f0101332:	8b 45 08             	mov    0x8(%ebp),%eax
f0101335:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101338:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010133b:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010133f:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0101342:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101349:	85 c0                	test   %eax,%eax
f010134b:	74 2b                	je     f0101378 <vsnprintf+0x58>
f010134d:	85 d2                	test   %edx,%edx
f010134f:	7e 27                	jle    f0101378 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101351:	ff 75 14             	pushl  0x14(%ebp)
f0101354:	ff 75 10             	pushl  0x10(%ebp)
f0101357:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010135a:	50                   	push   %eax
f010135b:	8d 83 4c fb fe ff    	lea    -0x104b4(%ebx),%eax
f0101361:	50                   	push   %eax
f0101362:	e8 27 fb ff ff       	call   f0100e8e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0101367:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010136a:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010136d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101370:	83 c4 10             	add    $0x10,%esp
}
f0101373:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101376:	c9                   	leave  
f0101377:	c3                   	ret    
		return -E_INVAL;
f0101378:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010137d:	eb f4                	jmp    f0101373 <vsnprintf+0x53>

f010137f <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010137f:	55                   	push   %ebp
f0101380:	89 e5                	mov    %esp,%ebp
f0101382:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101385:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101388:	50                   	push   %eax
f0101389:	ff 75 10             	pushl  0x10(%ebp)
f010138c:	ff 75 0c             	pushl  0xc(%ebp)
f010138f:	ff 75 08             	pushl  0x8(%ebp)
f0101392:	e8 89 ff ff ff       	call   f0101320 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101397:	c9                   	leave  
f0101398:	c3                   	ret    

f0101399 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101399:	55                   	push   %ebp
f010139a:	89 e5                	mov    %esp,%ebp
f010139c:	57                   	push   %edi
f010139d:	56                   	push   %esi
f010139e:	53                   	push   %ebx
f010139f:	83 ec 1c             	sub    $0x1c,%esp
f01013a2:	e8 46 ee ff ff       	call   f01001ed <__x86.get_pc_thunk.bx>
f01013a7:	81 c3 61 ff 00 00    	add    $0xff61,%ebx
f01013ad:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01013b0:	85 c0                	test   %eax,%eax
f01013b2:	74 13                	je     f01013c7 <readline+0x2e>
		cprintf("%s", prompt);
f01013b4:	83 ec 08             	sub    $0x8,%esp
f01013b7:	50                   	push   %eax
f01013b8:	8d 83 c2 07 ff ff    	lea    -0xf83e(%ebx),%eax
f01013be:	50                   	push   %eax
f01013bf:	e8 b6 f6 ff ff       	call   f0100a7a <cprintf>
f01013c4:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01013c7:	83 ec 0c             	sub    $0xc,%esp
f01013ca:	6a 00                	push   $0x0
f01013cc:	e8 b4 f3 ff ff       	call   f0100785 <iscons>
f01013d1:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01013d4:	83 c4 10             	add    $0x10,%esp
	i = 0;
f01013d7:	bf 00 00 00 00       	mov    $0x0,%edi
f01013dc:	eb 46                	jmp    f0101424 <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f01013de:	83 ec 08             	sub    $0x8,%esp
f01013e1:	50                   	push   %eax
f01013e2:	8d 83 24 0e ff ff    	lea    -0xf1dc(%ebx),%eax
f01013e8:	50                   	push   %eax
f01013e9:	e8 8c f6 ff ff       	call   f0100a7a <cprintf>
			return NULL;
f01013ee:	83 c4 10             	add    $0x10,%esp
f01013f1:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f01013f6:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01013f9:	5b                   	pop    %ebx
f01013fa:	5e                   	pop    %esi
f01013fb:	5f                   	pop    %edi
f01013fc:	5d                   	pop    %ebp
f01013fd:	c3                   	ret    
			if (echoing)
f01013fe:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101402:	75 05                	jne    f0101409 <readline+0x70>
			i--;
f0101404:	83 ef 01             	sub    $0x1,%edi
f0101407:	eb 1b                	jmp    f0101424 <readline+0x8b>
				cputchar('\b');
f0101409:	83 ec 0c             	sub    $0xc,%esp
f010140c:	6a 08                	push   $0x8
f010140e:	e8 51 f3 ff ff       	call   f0100764 <cputchar>
f0101413:	83 c4 10             	add    $0x10,%esp
f0101416:	eb ec                	jmp    f0101404 <readline+0x6b>
			buf[i++] = c;
f0101418:	89 f0                	mov    %esi,%eax
f010141a:	88 84 3b 98 1f 00 00 	mov    %al,0x1f98(%ebx,%edi,1)
f0101421:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0101424:	e8 4b f3 ff ff       	call   f0100774 <getchar>
f0101429:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f010142b:	85 c0                	test   %eax,%eax
f010142d:	78 af                	js     f01013de <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010142f:	83 f8 08             	cmp    $0x8,%eax
f0101432:	0f 94 c2             	sete   %dl
f0101435:	83 f8 7f             	cmp    $0x7f,%eax
f0101438:	0f 94 c0             	sete   %al
f010143b:	08 c2                	or     %al,%dl
f010143d:	74 04                	je     f0101443 <readline+0xaa>
f010143f:	85 ff                	test   %edi,%edi
f0101441:	7f bb                	jg     f01013fe <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101443:	83 fe 1f             	cmp    $0x1f,%esi
f0101446:	7e 1c                	jle    f0101464 <readline+0xcb>
f0101448:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f010144e:	7f 14                	jg     f0101464 <readline+0xcb>
			if (echoing)
f0101450:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101454:	74 c2                	je     f0101418 <readline+0x7f>
				cputchar(c);
f0101456:	83 ec 0c             	sub    $0xc,%esp
f0101459:	56                   	push   %esi
f010145a:	e8 05 f3 ff ff       	call   f0100764 <cputchar>
f010145f:	83 c4 10             	add    $0x10,%esp
f0101462:	eb b4                	jmp    f0101418 <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f0101464:	83 fe 0a             	cmp    $0xa,%esi
f0101467:	74 05                	je     f010146e <readline+0xd5>
f0101469:	83 fe 0d             	cmp    $0xd,%esi
f010146c:	75 b6                	jne    f0101424 <readline+0x8b>
			if (echoing)
f010146e:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101472:	75 13                	jne    f0101487 <readline+0xee>
			buf[i] = 0;
f0101474:	c6 84 3b 98 1f 00 00 	movb   $0x0,0x1f98(%ebx,%edi,1)
f010147b:	00 
			return buf;
f010147c:	8d 83 98 1f 00 00    	lea    0x1f98(%ebx),%eax
f0101482:	e9 6f ff ff ff       	jmp    f01013f6 <readline+0x5d>
				cputchar('\n');
f0101487:	83 ec 0c             	sub    $0xc,%esp
f010148a:	6a 0a                	push   $0xa
f010148c:	e8 d3 f2 ff ff       	call   f0100764 <cputchar>
f0101491:	83 c4 10             	add    $0x10,%esp
f0101494:	eb de                	jmp    f0101474 <readline+0xdb>

f0101496 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101496:	55                   	push   %ebp
f0101497:	89 e5                	mov    %esp,%ebp
f0101499:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010149c:	b8 00 00 00 00       	mov    $0x0,%eax
f01014a1:	eb 03                	jmp    f01014a6 <strlen+0x10>
		n++;
f01014a3:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f01014a6:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01014aa:	75 f7                	jne    f01014a3 <strlen+0xd>
	return n;
}
f01014ac:	5d                   	pop    %ebp
f01014ad:	c3                   	ret    

f01014ae <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01014ae:	55                   	push   %ebp
f01014af:	89 e5                	mov    %esp,%ebp
f01014b1:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01014b4:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01014b7:	b8 00 00 00 00       	mov    $0x0,%eax
f01014bc:	eb 03                	jmp    f01014c1 <strnlen+0x13>
		n++;
f01014be:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01014c1:	39 d0                	cmp    %edx,%eax
f01014c3:	74 06                	je     f01014cb <strnlen+0x1d>
f01014c5:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f01014c9:	75 f3                	jne    f01014be <strnlen+0x10>
	return n;
}
f01014cb:	5d                   	pop    %ebp
f01014cc:	c3                   	ret    

f01014cd <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01014cd:	55                   	push   %ebp
f01014ce:	89 e5                	mov    %esp,%ebp
f01014d0:	53                   	push   %ebx
f01014d1:	8b 45 08             	mov    0x8(%ebp),%eax
f01014d4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01014d7:	89 c2                	mov    %eax,%edx
f01014d9:	83 c1 01             	add    $0x1,%ecx
f01014dc:	83 c2 01             	add    $0x1,%edx
f01014df:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01014e3:	88 5a ff             	mov    %bl,-0x1(%edx)
f01014e6:	84 db                	test   %bl,%bl
f01014e8:	75 ef                	jne    f01014d9 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01014ea:	5b                   	pop    %ebx
f01014eb:	5d                   	pop    %ebp
f01014ec:	c3                   	ret    

f01014ed <strcat>:

char *
strcat(char *dst, const char *src)
{
f01014ed:	55                   	push   %ebp
f01014ee:	89 e5                	mov    %esp,%ebp
f01014f0:	53                   	push   %ebx
f01014f1:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01014f4:	53                   	push   %ebx
f01014f5:	e8 9c ff ff ff       	call   f0101496 <strlen>
f01014fa:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01014fd:	ff 75 0c             	pushl  0xc(%ebp)
f0101500:	01 d8                	add    %ebx,%eax
f0101502:	50                   	push   %eax
f0101503:	e8 c5 ff ff ff       	call   f01014cd <strcpy>
	return dst;
}
f0101508:	89 d8                	mov    %ebx,%eax
f010150a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010150d:	c9                   	leave  
f010150e:	c3                   	ret    

f010150f <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f010150f:	55                   	push   %ebp
f0101510:	89 e5                	mov    %esp,%ebp
f0101512:	56                   	push   %esi
f0101513:	53                   	push   %ebx
f0101514:	8b 75 08             	mov    0x8(%ebp),%esi
f0101517:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010151a:	89 f3                	mov    %esi,%ebx
f010151c:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f010151f:	89 f2                	mov    %esi,%edx
f0101521:	eb 0f                	jmp    f0101532 <strncpy+0x23>
		*dst++ = *src;
f0101523:	83 c2 01             	add    $0x1,%edx
f0101526:	0f b6 01             	movzbl (%ecx),%eax
f0101529:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010152c:	80 39 01             	cmpb   $0x1,(%ecx)
f010152f:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0101532:	39 da                	cmp    %ebx,%edx
f0101534:	75 ed                	jne    f0101523 <strncpy+0x14>
	}
	return ret;
}
f0101536:	89 f0                	mov    %esi,%eax
f0101538:	5b                   	pop    %ebx
f0101539:	5e                   	pop    %esi
f010153a:	5d                   	pop    %ebp
f010153b:	c3                   	ret    

f010153c <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010153c:	55                   	push   %ebp
f010153d:	89 e5                	mov    %esp,%ebp
f010153f:	56                   	push   %esi
f0101540:	53                   	push   %ebx
f0101541:	8b 75 08             	mov    0x8(%ebp),%esi
f0101544:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101547:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010154a:	89 f0                	mov    %esi,%eax
f010154c:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101550:	85 c9                	test   %ecx,%ecx
f0101552:	75 0b                	jne    f010155f <strlcpy+0x23>
f0101554:	eb 17                	jmp    f010156d <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0101556:	83 c2 01             	add    $0x1,%edx
f0101559:	83 c0 01             	add    $0x1,%eax
f010155c:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f010155f:	39 d8                	cmp    %ebx,%eax
f0101561:	74 07                	je     f010156a <strlcpy+0x2e>
f0101563:	0f b6 0a             	movzbl (%edx),%ecx
f0101566:	84 c9                	test   %cl,%cl
f0101568:	75 ec                	jne    f0101556 <strlcpy+0x1a>
		*dst = '\0';
f010156a:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f010156d:	29 f0                	sub    %esi,%eax
}
f010156f:	5b                   	pop    %ebx
f0101570:	5e                   	pop    %esi
f0101571:	5d                   	pop    %ebp
f0101572:	c3                   	ret    

f0101573 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101573:	55                   	push   %ebp
f0101574:	89 e5                	mov    %esp,%ebp
f0101576:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101579:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f010157c:	eb 06                	jmp    f0101584 <strcmp+0x11>
		p++, q++;
f010157e:	83 c1 01             	add    $0x1,%ecx
f0101581:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0101584:	0f b6 01             	movzbl (%ecx),%eax
f0101587:	84 c0                	test   %al,%al
f0101589:	74 04                	je     f010158f <strcmp+0x1c>
f010158b:	3a 02                	cmp    (%edx),%al
f010158d:	74 ef                	je     f010157e <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f010158f:	0f b6 c0             	movzbl %al,%eax
f0101592:	0f b6 12             	movzbl (%edx),%edx
f0101595:	29 d0                	sub    %edx,%eax
}
f0101597:	5d                   	pop    %ebp
f0101598:	c3                   	ret    

f0101599 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0101599:	55                   	push   %ebp
f010159a:	89 e5                	mov    %esp,%ebp
f010159c:	53                   	push   %ebx
f010159d:	8b 45 08             	mov    0x8(%ebp),%eax
f01015a0:	8b 55 0c             	mov    0xc(%ebp),%edx
f01015a3:	89 c3                	mov    %eax,%ebx
f01015a5:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01015a8:	eb 06                	jmp    f01015b0 <strncmp+0x17>
		n--, p++, q++;
f01015aa:	83 c0 01             	add    $0x1,%eax
f01015ad:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f01015b0:	39 d8                	cmp    %ebx,%eax
f01015b2:	74 16                	je     f01015ca <strncmp+0x31>
f01015b4:	0f b6 08             	movzbl (%eax),%ecx
f01015b7:	84 c9                	test   %cl,%cl
f01015b9:	74 04                	je     f01015bf <strncmp+0x26>
f01015bb:	3a 0a                	cmp    (%edx),%cl
f01015bd:	74 eb                	je     f01015aa <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01015bf:	0f b6 00             	movzbl (%eax),%eax
f01015c2:	0f b6 12             	movzbl (%edx),%edx
f01015c5:	29 d0                	sub    %edx,%eax
}
f01015c7:	5b                   	pop    %ebx
f01015c8:	5d                   	pop    %ebp
f01015c9:	c3                   	ret    
		return 0;
f01015ca:	b8 00 00 00 00       	mov    $0x0,%eax
f01015cf:	eb f6                	jmp    f01015c7 <strncmp+0x2e>

f01015d1 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01015d1:	55                   	push   %ebp
f01015d2:	89 e5                	mov    %esp,%ebp
f01015d4:	8b 45 08             	mov    0x8(%ebp),%eax
f01015d7:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01015db:	0f b6 10             	movzbl (%eax),%edx
f01015de:	84 d2                	test   %dl,%dl
f01015e0:	74 09                	je     f01015eb <strchr+0x1a>
		if (*s == c)
f01015e2:	38 ca                	cmp    %cl,%dl
f01015e4:	74 0a                	je     f01015f0 <strchr+0x1f>
	for (; *s; s++)
f01015e6:	83 c0 01             	add    $0x1,%eax
f01015e9:	eb f0                	jmp    f01015db <strchr+0xa>
			return (char *) s;
	return 0;
f01015eb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01015f0:	5d                   	pop    %ebp
f01015f1:	c3                   	ret    

f01015f2 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01015f2:	55                   	push   %ebp
f01015f3:	89 e5                	mov    %esp,%ebp
f01015f5:	8b 45 08             	mov    0x8(%ebp),%eax
f01015f8:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01015fc:	eb 03                	jmp    f0101601 <strfind+0xf>
f01015fe:	83 c0 01             	add    $0x1,%eax
f0101601:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0101604:	38 ca                	cmp    %cl,%dl
f0101606:	74 04                	je     f010160c <strfind+0x1a>
f0101608:	84 d2                	test   %dl,%dl
f010160a:	75 f2                	jne    f01015fe <strfind+0xc>
			break;
	return (char *) s;
}
f010160c:	5d                   	pop    %ebp
f010160d:	c3                   	ret    

f010160e <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f010160e:	55                   	push   %ebp
f010160f:	89 e5                	mov    %esp,%ebp
f0101611:	57                   	push   %edi
f0101612:	56                   	push   %esi
f0101613:	53                   	push   %ebx
f0101614:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101617:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010161a:	85 c9                	test   %ecx,%ecx
f010161c:	74 13                	je     f0101631 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010161e:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101624:	75 05                	jne    f010162b <memset+0x1d>
f0101626:	f6 c1 03             	test   $0x3,%cl
f0101629:	74 0d                	je     f0101638 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010162b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010162e:	fc                   	cld    
f010162f:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101631:	89 f8                	mov    %edi,%eax
f0101633:	5b                   	pop    %ebx
f0101634:	5e                   	pop    %esi
f0101635:	5f                   	pop    %edi
f0101636:	5d                   	pop    %ebp
f0101637:	c3                   	ret    
		c &= 0xFF;
f0101638:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010163c:	89 d3                	mov    %edx,%ebx
f010163e:	c1 e3 08             	shl    $0x8,%ebx
f0101641:	89 d0                	mov    %edx,%eax
f0101643:	c1 e0 18             	shl    $0x18,%eax
f0101646:	89 d6                	mov    %edx,%esi
f0101648:	c1 e6 10             	shl    $0x10,%esi
f010164b:	09 f0                	or     %esi,%eax
f010164d:	09 c2                	or     %eax,%edx
f010164f:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0101651:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0101654:	89 d0                	mov    %edx,%eax
f0101656:	fc                   	cld    
f0101657:	f3 ab                	rep stos %eax,%es:(%edi)
f0101659:	eb d6                	jmp    f0101631 <memset+0x23>

f010165b <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010165b:	55                   	push   %ebp
f010165c:	89 e5                	mov    %esp,%ebp
f010165e:	57                   	push   %edi
f010165f:	56                   	push   %esi
f0101660:	8b 45 08             	mov    0x8(%ebp),%eax
f0101663:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101666:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101669:	39 c6                	cmp    %eax,%esi
f010166b:	73 35                	jae    f01016a2 <memmove+0x47>
f010166d:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101670:	39 c2                	cmp    %eax,%edx
f0101672:	76 2e                	jbe    f01016a2 <memmove+0x47>
		s += n;
		d += n;
f0101674:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101677:	89 d6                	mov    %edx,%esi
f0101679:	09 fe                	or     %edi,%esi
f010167b:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101681:	74 0c                	je     f010168f <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101683:	83 ef 01             	sub    $0x1,%edi
f0101686:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0101689:	fd                   	std    
f010168a:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f010168c:	fc                   	cld    
f010168d:	eb 21                	jmp    f01016b0 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010168f:	f6 c1 03             	test   $0x3,%cl
f0101692:	75 ef                	jne    f0101683 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101694:	83 ef 04             	sub    $0x4,%edi
f0101697:	8d 72 fc             	lea    -0x4(%edx),%esi
f010169a:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f010169d:	fd                   	std    
f010169e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01016a0:	eb ea                	jmp    f010168c <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01016a2:	89 f2                	mov    %esi,%edx
f01016a4:	09 c2                	or     %eax,%edx
f01016a6:	f6 c2 03             	test   $0x3,%dl
f01016a9:	74 09                	je     f01016b4 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01016ab:	89 c7                	mov    %eax,%edi
f01016ad:	fc                   	cld    
f01016ae:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01016b0:	5e                   	pop    %esi
f01016b1:	5f                   	pop    %edi
f01016b2:	5d                   	pop    %ebp
f01016b3:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01016b4:	f6 c1 03             	test   $0x3,%cl
f01016b7:	75 f2                	jne    f01016ab <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01016b9:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f01016bc:	89 c7                	mov    %eax,%edi
f01016be:	fc                   	cld    
f01016bf:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01016c1:	eb ed                	jmp    f01016b0 <memmove+0x55>

f01016c3 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01016c3:	55                   	push   %ebp
f01016c4:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01016c6:	ff 75 10             	pushl  0x10(%ebp)
f01016c9:	ff 75 0c             	pushl  0xc(%ebp)
f01016cc:	ff 75 08             	pushl  0x8(%ebp)
f01016cf:	e8 87 ff ff ff       	call   f010165b <memmove>
}
f01016d4:	c9                   	leave  
f01016d5:	c3                   	ret    

f01016d6 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01016d6:	55                   	push   %ebp
f01016d7:	89 e5                	mov    %esp,%ebp
f01016d9:	56                   	push   %esi
f01016da:	53                   	push   %ebx
f01016db:	8b 45 08             	mov    0x8(%ebp),%eax
f01016de:	8b 55 0c             	mov    0xc(%ebp),%edx
f01016e1:	89 c6                	mov    %eax,%esi
f01016e3:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01016e6:	39 f0                	cmp    %esi,%eax
f01016e8:	74 1c                	je     f0101706 <memcmp+0x30>
		if (*s1 != *s2)
f01016ea:	0f b6 08             	movzbl (%eax),%ecx
f01016ed:	0f b6 1a             	movzbl (%edx),%ebx
f01016f0:	38 d9                	cmp    %bl,%cl
f01016f2:	75 08                	jne    f01016fc <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f01016f4:	83 c0 01             	add    $0x1,%eax
f01016f7:	83 c2 01             	add    $0x1,%edx
f01016fa:	eb ea                	jmp    f01016e6 <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f01016fc:	0f b6 c1             	movzbl %cl,%eax
f01016ff:	0f b6 db             	movzbl %bl,%ebx
f0101702:	29 d8                	sub    %ebx,%eax
f0101704:	eb 05                	jmp    f010170b <memcmp+0x35>
	}

	return 0;
f0101706:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010170b:	5b                   	pop    %ebx
f010170c:	5e                   	pop    %esi
f010170d:	5d                   	pop    %ebp
f010170e:	c3                   	ret    

f010170f <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010170f:	55                   	push   %ebp
f0101710:	89 e5                	mov    %esp,%ebp
f0101712:	8b 45 08             	mov    0x8(%ebp),%eax
f0101715:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0101718:	89 c2                	mov    %eax,%edx
f010171a:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f010171d:	39 d0                	cmp    %edx,%eax
f010171f:	73 09                	jae    f010172a <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101721:	38 08                	cmp    %cl,(%eax)
f0101723:	74 05                	je     f010172a <memfind+0x1b>
	for (; s < ends; s++)
f0101725:	83 c0 01             	add    $0x1,%eax
f0101728:	eb f3                	jmp    f010171d <memfind+0xe>
			break;
	return (void *) s;
}
f010172a:	5d                   	pop    %ebp
f010172b:	c3                   	ret    

f010172c <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f010172c:	55                   	push   %ebp
f010172d:	89 e5                	mov    %esp,%ebp
f010172f:	57                   	push   %edi
f0101730:	56                   	push   %esi
f0101731:	53                   	push   %ebx
f0101732:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101735:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101738:	eb 03                	jmp    f010173d <strtol+0x11>
		s++;
f010173a:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f010173d:	0f b6 01             	movzbl (%ecx),%eax
f0101740:	3c 20                	cmp    $0x20,%al
f0101742:	74 f6                	je     f010173a <strtol+0xe>
f0101744:	3c 09                	cmp    $0x9,%al
f0101746:	74 f2                	je     f010173a <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0101748:	3c 2b                	cmp    $0x2b,%al
f010174a:	74 2e                	je     f010177a <strtol+0x4e>
	int neg = 0;
f010174c:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0101751:	3c 2d                	cmp    $0x2d,%al
f0101753:	74 2f                	je     f0101784 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101755:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010175b:	75 05                	jne    f0101762 <strtol+0x36>
f010175d:	80 39 30             	cmpb   $0x30,(%ecx)
f0101760:	74 2c                	je     f010178e <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101762:	85 db                	test   %ebx,%ebx
f0101764:	75 0a                	jne    f0101770 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101766:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f010176b:	80 39 30             	cmpb   $0x30,(%ecx)
f010176e:	74 28                	je     f0101798 <strtol+0x6c>
		base = 10;
f0101770:	b8 00 00 00 00       	mov    $0x0,%eax
f0101775:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0101778:	eb 50                	jmp    f01017ca <strtol+0x9e>
		s++;
f010177a:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f010177d:	bf 00 00 00 00       	mov    $0x0,%edi
f0101782:	eb d1                	jmp    f0101755 <strtol+0x29>
		s++, neg = 1;
f0101784:	83 c1 01             	add    $0x1,%ecx
f0101787:	bf 01 00 00 00       	mov    $0x1,%edi
f010178c:	eb c7                	jmp    f0101755 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010178e:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101792:	74 0e                	je     f01017a2 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0101794:	85 db                	test   %ebx,%ebx
f0101796:	75 d8                	jne    f0101770 <strtol+0x44>
		s++, base = 8;
f0101798:	83 c1 01             	add    $0x1,%ecx
f010179b:	bb 08 00 00 00       	mov    $0x8,%ebx
f01017a0:	eb ce                	jmp    f0101770 <strtol+0x44>
		s += 2, base = 16;
f01017a2:	83 c1 02             	add    $0x2,%ecx
f01017a5:	bb 10 00 00 00       	mov    $0x10,%ebx
f01017aa:	eb c4                	jmp    f0101770 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f01017ac:	8d 72 9f             	lea    -0x61(%edx),%esi
f01017af:	89 f3                	mov    %esi,%ebx
f01017b1:	80 fb 19             	cmp    $0x19,%bl
f01017b4:	77 29                	ja     f01017df <strtol+0xb3>
			dig = *s - 'a' + 10;
f01017b6:	0f be d2             	movsbl %dl,%edx
f01017b9:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01017bc:	3b 55 10             	cmp    0x10(%ebp),%edx
f01017bf:	7d 30                	jge    f01017f1 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f01017c1:	83 c1 01             	add    $0x1,%ecx
f01017c4:	0f af 45 10          	imul   0x10(%ebp),%eax
f01017c8:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f01017ca:	0f b6 11             	movzbl (%ecx),%edx
f01017cd:	8d 72 d0             	lea    -0x30(%edx),%esi
f01017d0:	89 f3                	mov    %esi,%ebx
f01017d2:	80 fb 09             	cmp    $0x9,%bl
f01017d5:	77 d5                	ja     f01017ac <strtol+0x80>
			dig = *s - '0';
f01017d7:	0f be d2             	movsbl %dl,%edx
f01017da:	83 ea 30             	sub    $0x30,%edx
f01017dd:	eb dd                	jmp    f01017bc <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f01017df:	8d 72 bf             	lea    -0x41(%edx),%esi
f01017e2:	89 f3                	mov    %esi,%ebx
f01017e4:	80 fb 19             	cmp    $0x19,%bl
f01017e7:	77 08                	ja     f01017f1 <strtol+0xc5>
			dig = *s - 'A' + 10;
f01017e9:	0f be d2             	movsbl %dl,%edx
f01017ec:	83 ea 37             	sub    $0x37,%edx
f01017ef:	eb cb                	jmp    f01017bc <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f01017f1:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01017f5:	74 05                	je     f01017fc <strtol+0xd0>
		*endptr = (char *) s;
f01017f7:	8b 75 0c             	mov    0xc(%ebp),%esi
f01017fa:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f01017fc:	89 c2                	mov    %eax,%edx
f01017fe:	f7 da                	neg    %edx
f0101800:	85 ff                	test   %edi,%edi
f0101802:	0f 45 c2             	cmovne %edx,%eax
}
f0101805:	5b                   	pop    %ebx
f0101806:	5e                   	pop    %esi
f0101807:	5f                   	pop    %edi
f0101808:	5d                   	pop    %ebp
f0101809:	c3                   	ret    
f010180a:	66 90                	xchg   %ax,%ax
f010180c:	66 90                	xchg   %ax,%ax
f010180e:	66 90                	xchg   %ax,%ax

f0101810 <__udivdi3>:
f0101810:	55                   	push   %ebp
f0101811:	57                   	push   %edi
f0101812:	56                   	push   %esi
f0101813:	53                   	push   %ebx
f0101814:	83 ec 1c             	sub    $0x1c,%esp
f0101817:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010181b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f010181f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0101823:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0101827:	85 d2                	test   %edx,%edx
f0101829:	75 35                	jne    f0101860 <__udivdi3+0x50>
f010182b:	39 f3                	cmp    %esi,%ebx
f010182d:	0f 87 bd 00 00 00    	ja     f01018f0 <__udivdi3+0xe0>
f0101833:	85 db                	test   %ebx,%ebx
f0101835:	89 d9                	mov    %ebx,%ecx
f0101837:	75 0b                	jne    f0101844 <__udivdi3+0x34>
f0101839:	b8 01 00 00 00       	mov    $0x1,%eax
f010183e:	31 d2                	xor    %edx,%edx
f0101840:	f7 f3                	div    %ebx
f0101842:	89 c1                	mov    %eax,%ecx
f0101844:	31 d2                	xor    %edx,%edx
f0101846:	89 f0                	mov    %esi,%eax
f0101848:	f7 f1                	div    %ecx
f010184a:	89 c6                	mov    %eax,%esi
f010184c:	89 e8                	mov    %ebp,%eax
f010184e:	89 f7                	mov    %esi,%edi
f0101850:	f7 f1                	div    %ecx
f0101852:	89 fa                	mov    %edi,%edx
f0101854:	83 c4 1c             	add    $0x1c,%esp
f0101857:	5b                   	pop    %ebx
f0101858:	5e                   	pop    %esi
f0101859:	5f                   	pop    %edi
f010185a:	5d                   	pop    %ebp
f010185b:	c3                   	ret    
f010185c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101860:	39 f2                	cmp    %esi,%edx
f0101862:	77 7c                	ja     f01018e0 <__udivdi3+0xd0>
f0101864:	0f bd fa             	bsr    %edx,%edi
f0101867:	83 f7 1f             	xor    $0x1f,%edi
f010186a:	0f 84 98 00 00 00    	je     f0101908 <__udivdi3+0xf8>
f0101870:	89 f9                	mov    %edi,%ecx
f0101872:	b8 20 00 00 00       	mov    $0x20,%eax
f0101877:	29 f8                	sub    %edi,%eax
f0101879:	d3 e2                	shl    %cl,%edx
f010187b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010187f:	89 c1                	mov    %eax,%ecx
f0101881:	89 da                	mov    %ebx,%edx
f0101883:	d3 ea                	shr    %cl,%edx
f0101885:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101889:	09 d1                	or     %edx,%ecx
f010188b:	89 f2                	mov    %esi,%edx
f010188d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101891:	89 f9                	mov    %edi,%ecx
f0101893:	d3 e3                	shl    %cl,%ebx
f0101895:	89 c1                	mov    %eax,%ecx
f0101897:	d3 ea                	shr    %cl,%edx
f0101899:	89 f9                	mov    %edi,%ecx
f010189b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010189f:	d3 e6                	shl    %cl,%esi
f01018a1:	89 eb                	mov    %ebp,%ebx
f01018a3:	89 c1                	mov    %eax,%ecx
f01018a5:	d3 eb                	shr    %cl,%ebx
f01018a7:	09 de                	or     %ebx,%esi
f01018a9:	89 f0                	mov    %esi,%eax
f01018ab:	f7 74 24 08          	divl   0x8(%esp)
f01018af:	89 d6                	mov    %edx,%esi
f01018b1:	89 c3                	mov    %eax,%ebx
f01018b3:	f7 64 24 0c          	mull   0xc(%esp)
f01018b7:	39 d6                	cmp    %edx,%esi
f01018b9:	72 0c                	jb     f01018c7 <__udivdi3+0xb7>
f01018bb:	89 f9                	mov    %edi,%ecx
f01018bd:	d3 e5                	shl    %cl,%ebp
f01018bf:	39 c5                	cmp    %eax,%ebp
f01018c1:	73 5d                	jae    f0101920 <__udivdi3+0x110>
f01018c3:	39 d6                	cmp    %edx,%esi
f01018c5:	75 59                	jne    f0101920 <__udivdi3+0x110>
f01018c7:	8d 43 ff             	lea    -0x1(%ebx),%eax
f01018ca:	31 ff                	xor    %edi,%edi
f01018cc:	89 fa                	mov    %edi,%edx
f01018ce:	83 c4 1c             	add    $0x1c,%esp
f01018d1:	5b                   	pop    %ebx
f01018d2:	5e                   	pop    %esi
f01018d3:	5f                   	pop    %edi
f01018d4:	5d                   	pop    %ebp
f01018d5:	c3                   	ret    
f01018d6:	8d 76 00             	lea    0x0(%esi),%esi
f01018d9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f01018e0:	31 ff                	xor    %edi,%edi
f01018e2:	31 c0                	xor    %eax,%eax
f01018e4:	89 fa                	mov    %edi,%edx
f01018e6:	83 c4 1c             	add    $0x1c,%esp
f01018e9:	5b                   	pop    %ebx
f01018ea:	5e                   	pop    %esi
f01018eb:	5f                   	pop    %edi
f01018ec:	5d                   	pop    %ebp
f01018ed:	c3                   	ret    
f01018ee:	66 90                	xchg   %ax,%ax
f01018f0:	31 ff                	xor    %edi,%edi
f01018f2:	89 e8                	mov    %ebp,%eax
f01018f4:	89 f2                	mov    %esi,%edx
f01018f6:	f7 f3                	div    %ebx
f01018f8:	89 fa                	mov    %edi,%edx
f01018fa:	83 c4 1c             	add    $0x1c,%esp
f01018fd:	5b                   	pop    %ebx
f01018fe:	5e                   	pop    %esi
f01018ff:	5f                   	pop    %edi
f0101900:	5d                   	pop    %ebp
f0101901:	c3                   	ret    
f0101902:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101908:	39 f2                	cmp    %esi,%edx
f010190a:	72 06                	jb     f0101912 <__udivdi3+0x102>
f010190c:	31 c0                	xor    %eax,%eax
f010190e:	39 eb                	cmp    %ebp,%ebx
f0101910:	77 d2                	ja     f01018e4 <__udivdi3+0xd4>
f0101912:	b8 01 00 00 00       	mov    $0x1,%eax
f0101917:	eb cb                	jmp    f01018e4 <__udivdi3+0xd4>
f0101919:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101920:	89 d8                	mov    %ebx,%eax
f0101922:	31 ff                	xor    %edi,%edi
f0101924:	eb be                	jmp    f01018e4 <__udivdi3+0xd4>
f0101926:	66 90                	xchg   %ax,%ax
f0101928:	66 90                	xchg   %ax,%ax
f010192a:	66 90                	xchg   %ax,%ax
f010192c:	66 90                	xchg   %ax,%ax
f010192e:	66 90                	xchg   %ax,%ax

f0101930 <__umoddi3>:
f0101930:	55                   	push   %ebp
f0101931:	57                   	push   %edi
f0101932:	56                   	push   %esi
f0101933:	53                   	push   %ebx
f0101934:	83 ec 1c             	sub    $0x1c,%esp
f0101937:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f010193b:	8b 74 24 30          	mov    0x30(%esp),%esi
f010193f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0101943:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0101947:	85 ed                	test   %ebp,%ebp
f0101949:	89 f0                	mov    %esi,%eax
f010194b:	89 da                	mov    %ebx,%edx
f010194d:	75 19                	jne    f0101968 <__umoddi3+0x38>
f010194f:	39 df                	cmp    %ebx,%edi
f0101951:	0f 86 b1 00 00 00    	jbe    f0101a08 <__umoddi3+0xd8>
f0101957:	f7 f7                	div    %edi
f0101959:	89 d0                	mov    %edx,%eax
f010195b:	31 d2                	xor    %edx,%edx
f010195d:	83 c4 1c             	add    $0x1c,%esp
f0101960:	5b                   	pop    %ebx
f0101961:	5e                   	pop    %esi
f0101962:	5f                   	pop    %edi
f0101963:	5d                   	pop    %ebp
f0101964:	c3                   	ret    
f0101965:	8d 76 00             	lea    0x0(%esi),%esi
f0101968:	39 dd                	cmp    %ebx,%ebp
f010196a:	77 f1                	ja     f010195d <__umoddi3+0x2d>
f010196c:	0f bd cd             	bsr    %ebp,%ecx
f010196f:	83 f1 1f             	xor    $0x1f,%ecx
f0101972:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101976:	0f 84 b4 00 00 00    	je     f0101a30 <__umoddi3+0x100>
f010197c:	b8 20 00 00 00       	mov    $0x20,%eax
f0101981:	89 c2                	mov    %eax,%edx
f0101983:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101987:	29 c2                	sub    %eax,%edx
f0101989:	89 c1                	mov    %eax,%ecx
f010198b:	89 f8                	mov    %edi,%eax
f010198d:	d3 e5                	shl    %cl,%ebp
f010198f:	89 d1                	mov    %edx,%ecx
f0101991:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101995:	d3 e8                	shr    %cl,%eax
f0101997:	09 c5                	or     %eax,%ebp
f0101999:	8b 44 24 04          	mov    0x4(%esp),%eax
f010199d:	89 c1                	mov    %eax,%ecx
f010199f:	d3 e7                	shl    %cl,%edi
f01019a1:	89 d1                	mov    %edx,%ecx
f01019a3:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01019a7:	89 df                	mov    %ebx,%edi
f01019a9:	d3 ef                	shr    %cl,%edi
f01019ab:	89 c1                	mov    %eax,%ecx
f01019ad:	89 f0                	mov    %esi,%eax
f01019af:	d3 e3                	shl    %cl,%ebx
f01019b1:	89 d1                	mov    %edx,%ecx
f01019b3:	89 fa                	mov    %edi,%edx
f01019b5:	d3 e8                	shr    %cl,%eax
f01019b7:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01019bc:	09 d8                	or     %ebx,%eax
f01019be:	f7 f5                	div    %ebp
f01019c0:	d3 e6                	shl    %cl,%esi
f01019c2:	89 d1                	mov    %edx,%ecx
f01019c4:	f7 64 24 08          	mull   0x8(%esp)
f01019c8:	39 d1                	cmp    %edx,%ecx
f01019ca:	89 c3                	mov    %eax,%ebx
f01019cc:	89 d7                	mov    %edx,%edi
f01019ce:	72 06                	jb     f01019d6 <__umoddi3+0xa6>
f01019d0:	75 0e                	jne    f01019e0 <__umoddi3+0xb0>
f01019d2:	39 c6                	cmp    %eax,%esi
f01019d4:	73 0a                	jae    f01019e0 <__umoddi3+0xb0>
f01019d6:	2b 44 24 08          	sub    0x8(%esp),%eax
f01019da:	19 ea                	sbb    %ebp,%edx
f01019dc:	89 d7                	mov    %edx,%edi
f01019de:	89 c3                	mov    %eax,%ebx
f01019e0:	89 ca                	mov    %ecx,%edx
f01019e2:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f01019e7:	29 de                	sub    %ebx,%esi
f01019e9:	19 fa                	sbb    %edi,%edx
f01019eb:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f01019ef:	89 d0                	mov    %edx,%eax
f01019f1:	d3 e0                	shl    %cl,%eax
f01019f3:	89 d9                	mov    %ebx,%ecx
f01019f5:	d3 ee                	shr    %cl,%esi
f01019f7:	d3 ea                	shr    %cl,%edx
f01019f9:	09 f0                	or     %esi,%eax
f01019fb:	83 c4 1c             	add    $0x1c,%esp
f01019fe:	5b                   	pop    %ebx
f01019ff:	5e                   	pop    %esi
f0101a00:	5f                   	pop    %edi
f0101a01:	5d                   	pop    %ebp
f0101a02:	c3                   	ret    
f0101a03:	90                   	nop
f0101a04:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101a08:	85 ff                	test   %edi,%edi
f0101a0a:	89 f9                	mov    %edi,%ecx
f0101a0c:	75 0b                	jne    f0101a19 <__umoddi3+0xe9>
f0101a0e:	b8 01 00 00 00       	mov    $0x1,%eax
f0101a13:	31 d2                	xor    %edx,%edx
f0101a15:	f7 f7                	div    %edi
f0101a17:	89 c1                	mov    %eax,%ecx
f0101a19:	89 d8                	mov    %ebx,%eax
f0101a1b:	31 d2                	xor    %edx,%edx
f0101a1d:	f7 f1                	div    %ecx
f0101a1f:	89 f0                	mov    %esi,%eax
f0101a21:	f7 f1                	div    %ecx
f0101a23:	e9 31 ff ff ff       	jmp    f0101959 <__umoddi3+0x29>
f0101a28:	90                   	nop
f0101a29:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101a30:	39 dd                	cmp    %ebx,%ebp
f0101a32:	72 08                	jb     f0101a3c <__umoddi3+0x10c>
f0101a34:	39 f7                	cmp    %esi,%edi
f0101a36:	0f 87 21 ff ff ff    	ja     f010195d <__umoddi3+0x2d>
f0101a3c:	89 da                	mov    %ebx,%edx
f0101a3e:	89 f0                	mov    %esi,%eax
f0101a40:	29 f8                	sub    %edi,%eax
f0101a42:	19 ea                	sbb    %ebp,%edx
f0101a44:	e9 14 ff ff ff       	jmp    f010195d <__umoddi3+0x2d>
