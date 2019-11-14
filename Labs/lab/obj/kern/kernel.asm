
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
f0100057:	8d 83 f8 07 ff ff    	lea    -0xf808(%ebx),%eax
f010005d:	50                   	push   %eax
f010005e:	e8 cb 0a 00 00       	call   f0100b2e <cprintf>
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
f010007f:	8d 83 14 08 ff ff    	lea    -0xf7ec(%ebx),%eax
f0100085:	50                   	push   %eax
f0100086:	e8 a3 0a 00 00       	call   f0100b2e <cprintf>
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
f01000ca:	e8 f3 15 00 00       	call   f01016c2 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000cf:	e8 6e 05 00 00       	call   f0100642 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000d4:	83 c4 08             	add    $0x8,%esp
f01000d7:	68 ac 1a 00 00       	push   $0x1aac
f01000dc:	8d 83 2f 08 ff ff    	lea    -0xf7d1(%ebx),%eax
f01000e2:	50                   	push   %eax
f01000e3:	e8 46 0a 00 00       	call   f0100b2e <cprintf>

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
f01000fa:	8d 83 4a 08 ff ff    	lea    -0xf7b6(%ebx),%eax
f0100100:	50                   	push   %eax
f0100101:	e8 28 0a 00 00       	call   f0100b2e <cprintf>

	unsigned int i = 0x00646c72;
f0100106:	c7 45 f4 72 6c 64 00 	movl   $0x646c72,-0xc(%ebp)
    cprintf("H%x Wo%s", 57616, &i);
f010010d:	83 c4 1c             	add    $0x1c,%esp
f0100110:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100113:	50                   	push   %eax
f0100114:	68 10 e1 00 00       	push   $0xe110
f0100119:	8d 83 5c 08 ff ff    	lea    -0xf7a4(%ebx),%eax
f010011f:	50                   	push   %eax
f0100120:	e8 09 0a 00 00       	call   f0100b2e <cprintf>
f0100125:	83 c4 10             	add    $0x10,%esp

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100128:	83 ec 0c             	sub    $0xc,%esp
f010012b:	6a 00                	push   $0x0
f010012d:	e8 40 08 00 00       	call   f0100972 <monitor>
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
f010015e:	e8 0f 08 00 00       	call   f0100972 <monitor>
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
f0100178:	8d 83 65 08 ff ff    	lea    -0xf79b(%ebx),%eax
f010017e:	50                   	push   %eax
f010017f:	e8 aa 09 00 00       	call   f0100b2e <cprintf>
	vcprintf(fmt, ap);
f0100184:	83 c4 08             	add    $0x8,%esp
f0100187:	56                   	push   %esi
f0100188:	57                   	push   %edi
f0100189:	e8 69 09 00 00       	call   f0100af7 <vcprintf>
	cprintf("\n");
f010018e:	8d 83 a1 08 ff ff    	lea    -0xf75f(%ebx),%eax
f0100194:	89 04 24             	mov    %eax,(%esp)
f0100197:	e8 92 09 00 00       	call   f0100b2e <cprintf>
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
f01001bd:	8d 83 7d 08 ff ff    	lea    -0xf783(%ebx),%eax
f01001c3:	50                   	push   %eax
f01001c4:	e8 65 09 00 00       	call   f0100b2e <cprintf>
	vcprintf(fmt, ap);
f01001c9:	83 c4 08             	add    $0x8,%esp
f01001cc:	56                   	push   %esi
f01001cd:	ff 75 10             	pushl  0x10(%ebp)
f01001d0:	e8 22 09 00 00       	call   f0100af7 <vcprintf>
	cprintf("\n");
f01001d5:	8d 83 a1 08 ff ff    	lea    -0xf75f(%ebx),%eax
f01001db:	89 04 24             	mov    %eax,(%esp)
f01001de:	e8 4b 09 00 00       	call   f0100b2e <cprintf>
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
f01002b5:	0f b6 84 13 d8 09 ff 	movzbl -0xf628(%ebx,%edx,1),%eax
f01002bc:	ff 
f01002bd:	0b 83 58 1d 00 00    	or     0x1d58(%ebx),%eax
	shift ^= togglecode[data];
f01002c3:	0f b6 8c 13 d8 08 ff 	movzbl -0xf728(%ebx,%edx,1),%ecx
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
f0100308:	8d 83 97 08 ff ff    	lea    -0xf769(%ebx),%eax
f010030e:	50                   	push   %eax
f010030f:	e8 1a 08 00 00       	call   f0100b2e <cprintf>
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
f010034f:	0f b6 84 13 d8 09 ff 	movzbl -0xf628(%ebx,%edx,1),%eax
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
f0100570:	e8 9a 11 00 00       	call   f010170f <memmove>
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
f0100753:	8d 83 a3 08 ff ff    	lea    -0xf75d(%ebx),%eax
f0100759:	50                   	push   %eax
f010075a:	e8 cf 03 00 00       	call   f0100b2e <cprintf>
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
f01007a6:	8d 83 d8 0a ff ff    	lea    -0xf528(%ebx),%eax
f01007ac:	50                   	push   %eax
f01007ad:	8d 83 f6 0a ff ff    	lea    -0xf50a(%ebx),%eax
f01007b3:	50                   	push   %eax
f01007b4:	8d b3 fb 0a ff ff    	lea    -0xf505(%ebx),%esi
f01007ba:	56                   	push   %esi
f01007bb:	e8 6e 03 00 00       	call   f0100b2e <cprintf>
f01007c0:	83 c4 0c             	add    $0xc,%esp
f01007c3:	8d 83 98 0b ff ff    	lea    -0xf468(%ebx),%eax
f01007c9:	50                   	push   %eax
f01007ca:	8d 83 04 0b ff ff    	lea    -0xf4fc(%ebx),%eax
f01007d0:	50                   	push   %eax
f01007d1:	56                   	push   %esi
f01007d2:	e8 57 03 00 00       	call   f0100b2e <cprintf>
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
f01007f7:	8d 83 0d 0b ff ff    	lea    -0xf4f3(%ebx),%eax
f01007fd:	50                   	push   %eax
f01007fe:	e8 2b 03 00 00       	call   f0100b2e <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100803:	83 c4 08             	add    $0x8,%esp
f0100806:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f010080c:	8d 83 c0 0b ff ff    	lea    -0xf440(%ebx),%eax
f0100812:	50                   	push   %eax
f0100813:	e8 16 03 00 00       	call   f0100b2e <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100818:	83 c4 0c             	add    $0xc,%esp
f010081b:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f0100821:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f0100827:	50                   	push   %eax
f0100828:	57                   	push   %edi
f0100829:	8d 83 e8 0b ff ff    	lea    -0xf418(%ebx),%eax
f010082f:	50                   	push   %eax
f0100830:	e8 f9 02 00 00       	call   f0100b2e <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100835:	83 c4 0c             	add    $0xc,%esp
f0100838:	c7 c0 f9 1a 10 f0    	mov    $0xf0101af9,%eax
f010083e:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100844:	52                   	push   %edx
f0100845:	50                   	push   %eax
f0100846:	8d 83 0c 0c ff ff    	lea    -0xf3f4(%ebx),%eax
f010084c:	50                   	push   %eax
f010084d:	e8 dc 02 00 00       	call   f0100b2e <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100852:	83 c4 0c             	add    $0xc,%esp
f0100855:	c7 c0 60 30 11 f0    	mov    $0xf0113060,%eax
f010085b:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0100861:	52                   	push   %edx
f0100862:	50                   	push   %eax
f0100863:	8d 83 30 0c ff ff    	lea    -0xf3d0(%ebx),%eax
f0100869:	50                   	push   %eax
f010086a:	e8 bf 02 00 00       	call   f0100b2e <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010086f:	83 c4 0c             	add    $0xc,%esp
f0100872:	c7 c6 a0 36 11 f0    	mov    $0xf01136a0,%esi
f0100878:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f010087e:	50                   	push   %eax
f010087f:	56                   	push   %esi
f0100880:	8d 83 54 0c ff ff    	lea    -0xf3ac(%ebx),%eax
f0100886:	50                   	push   %eax
f0100887:	e8 a2 02 00 00       	call   f0100b2e <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f010088c:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f010088f:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f0100895:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100897:	c1 fe 0a             	sar    $0xa,%esi
f010089a:	56                   	push   %esi
f010089b:	8d 83 78 0c ff ff    	lea    -0xf388(%ebx),%eax
f01008a1:	50                   	push   %eax
f01008a2:	e8 87 02 00 00       	call   f0100b2e <cprintf>
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
f01008b7:	57                   	push   %edi
f01008b8:	56                   	push   %esi
f01008b9:	53                   	push   %ebx
f01008ba:	83 ec 28             	sub    $0x28,%esp
f01008bd:	e8 2b f9 ff ff       	call   f01001ed <__x86.get_pc_thunk.bx>
f01008c2:	81 c3 46 0a 01 00    	add    $0x10a46,%ebx
			uint32_t ebp;
			asm volatile("movl %%ebp,%0" : "=r" (ebp));
			return ebp;
		} 
	 */
	cprintf("Stack backtrace:\n");
f01008c8:	8d 83 26 0b ff ff    	lea    -0xf4da(%ebx),%eax
f01008ce:	50                   	push   %eax
f01008cf:	e8 5a 02 00 00       	call   f0100b2e <cprintf>

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f01008d4:	89 ef                	mov    %ebp,%edi
	int* curr_ebp = (int *) read_ebp();
f01008d6:	83 c4 10             	add    $0x10,%esp
		// If prev_ebp == 0x0, it means the current function 
		// is already the last function in the call stack, and
		// thus you print the info and return.

		// Assumption: int is 32-bit, 4 byte.
		cprintf("  ");
f01008d9:	8d 83 38 0b ff ff    	lea    -0xf4c8(%ebx),%eax
f01008df:	89 45 dc             	mov    %eax,-0x24(%ebp)
		cprintf("ebp %08x ", curr_ebp);
f01008e2:	8d 83 3b 0b ff ff    	lea    -0xf4c5(%ebx),%eax
f01008e8:	89 45 d8             	mov    %eax,-0x28(%ebp)
		int* prev_ebp = (int *) *curr_ebp;
f01008eb:	8b 07                	mov    (%edi),%eax
f01008ed:	89 45 e0             	mov    %eax,-0x20(%ebp)
		cprintf("  ");
f01008f0:	83 ec 0c             	sub    $0xc,%esp
f01008f3:	ff 75 dc             	pushl  -0x24(%ebp)
f01008f6:	e8 33 02 00 00       	call   f0100b2e <cprintf>
		cprintf("ebp %08x ", curr_ebp);
f01008fb:	83 c4 08             	add    $0x8,%esp
f01008fe:	57                   	push   %edi
f01008ff:	ff 75 d8             	pushl  -0x28(%ebp)
f0100902:	e8 27 02 00 00       	call   f0100b2e <cprintf>
		cprintf("eip %08x ", *(curr_ebp + 1));
f0100907:	83 c4 08             	add    $0x8,%esp
f010090a:	ff 77 04             	pushl  0x4(%edi)
f010090d:	8d 83 45 0b ff ff    	lea    -0xf4bb(%ebx),%eax
f0100913:	50                   	push   %eax
f0100914:	e8 15 02 00 00       	call   f0100b2e <cprintf>
		
		cprintf("args");
f0100919:	8d 83 4f 0b ff ff    	lea    -0xf4b1(%ebx),%eax
f010091f:	89 04 24             	mov    %eax,(%esp)
f0100922:	e8 07 02 00 00       	call   f0100b2e <cprintf>
		int *arg_p = curr_ebp + 2;
f0100927:	8d 77 08             	lea    0x8(%edi),%esi
f010092a:	8d 47 1c             	lea    0x1c(%edi),%eax
f010092d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100930:	83 c4 10             	add    $0x10,%esp
		for (int i = 0; i < 5; ++i) {
			cprintf(" %08x", *arg_p);
f0100933:	8d bb 54 0b ff ff    	lea    -0xf4ac(%ebx),%edi
f0100939:	83 ec 08             	sub    $0x8,%esp
f010093c:	ff 36                	pushl  (%esi)
f010093e:	57                   	push   %edi
f010093f:	e8 ea 01 00 00       	call   f0100b2e <cprintf>
			++arg_p;
f0100944:	83 c6 04             	add    $0x4,%esi
		for (int i = 0; i < 5; ++i) {
f0100947:	83 c4 10             	add    $0x10,%esp
f010094a:	39 75 e4             	cmp    %esi,-0x1c(%ebp)
f010094d:	75 ea                	jne    f0100939 <mon_backtrace+0x85>
		}

		cprintf("\n");
f010094f:	83 ec 0c             	sub    $0xc,%esp
f0100952:	8d 83 a1 08 ff ff    	lea    -0xf75f(%ebx),%eax
f0100958:	50                   	push   %eax
f0100959:	e8 d0 01 00 00       	call   f0100b2e <cprintf>
		if (prev_ebp == 0) {
			return 0;
		} else {
			curr_ebp = prev_ebp;
f010095e:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100961:	89 c7                	mov    %eax,%edi
		if (prev_ebp == 0) {
f0100963:	83 c4 10             	add    $0x10,%esp
f0100966:	85 c0                	test   %eax,%eax
f0100968:	75 81                	jne    f01008eb <mon_backtrace+0x37>
		}
	}
	return 0;
}
f010096a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010096d:	5b                   	pop    %ebx
f010096e:	5e                   	pop    %esi
f010096f:	5f                   	pop    %edi
f0100970:	5d                   	pop    %ebp
f0100971:	c3                   	ret    

f0100972 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100972:	55                   	push   %ebp
f0100973:	89 e5                	mov    %esp,%ebp
f0100975:	57                   	push   %edi
f0100976:	56                   	push   %esi
f0100977:	53                   	push   %ebx
f0100978:	83 ec 68             	sub    $0x68,%esp
f010097b:	e8 6d f8 ff ff       	call   f01001ed <__x86.get_pc_thunk.bx>
f0100980:	81 c3 88 09 01 00    	add    $0x10988,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100986:	8d 83 a4 0c ff ff    	lea    -0xf35c(%ebx),%eax
f010098c:	50                   	push   %eax
f010098d:	e8 9c 01 00 00       	call   f0100b2e <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100992:	8d 83 c8 0c ff ff    	lea    -0xf338(%ebx),%eax
f0100998:	89 04 24             	mov    %eax,(%esp)
f010099b:	e8 8e 01 00 00       	call   f0100b2e <cprintf>
f01009a0:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f01009a3:	8d bb 5e 0b ff ff    	lea    -0xf4a2(%ebx),%edi
f01009a9:	eb 4a                	jmp    f01009f5 <monitor+0x83>
f01009ab:	83 ec 08             	sub    $0x8,%esp
f01009ae:	0f be c0             	movsbl %al,%eax
f01009b1:	50                   	push   %eax
f01009b2:	57                   	push   %edi
f01009b3:	e8 cd 0c 00 00       	call   f0101685 <strchr>
f01009b8:	83 c4 10             	add    $0x10,%esp
f01009bb:	85 c0                	test   %eax,%eax
f01009bd:	74 08                	je     f01009c7 <monitor+0x55>
			*buf++ = 0;
f01009bf:	c6 06 00             	movb   $0x0,(%esi)
f01009c2:	8d 76 01             	lea    0x1(%esi),%esi
f01009c5:	eb 79                	jmp    f0100a40 <monitor+0xce>
		if (*buf == 0)
f01009c7:	80 3e 00             	cmpb   $0x0,(%esi)
f01009ca:	74 7f                	je     f0100a4b <monitor+0xd9>
		if (argc == MAXARGS-1) {
f01009cc:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f01009d0:	74 0f                	je     f01009e1 <monitor+0x6f>
		argv[argc++] = buf;
f01009d2:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01009d5:	8d 48 01             	lea    0x1(%eax),%ecx
f01009d8:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f01009db:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
f01009df:	eb 44                	jmp    f0100a25 <monitor+0xb3>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01009e1:	83 ec 08             	sub    $0x8,%esp
f01009e4:	6a 10                	push   $0x10
f01009e6:	8d 83 63 0b ff ff    	lea    -0xf49d(%ebx),%eax
f01009ec:	50                   	push   %eax
f01009ed:	e8 3c 01 00 00       	call   f0100b2e <cprintf>
f01009f2:	83 c4 10             	add    $0x10,%esp


	while (1) {
		buf = readline("K> ");
f01009f5:	8d 83 5a 0b ff ff    	lea    -0xf4a6(%ebx),%eax
f01009fb:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f01009fe:	83 ec 0c             	sub    $0xc,%esp
f0100a01:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100a04:	e8 44 0a 00 00       	call   f010144d <readline>
f0100a09:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f0100a0b:	83 c4 10             	add    $0x10,%esp
f0100a0e:	85 c0                	test   %eax,%eax
f0100a10:	74 ec                	je     f01009fe <monitor+0x8c>
	argv[argc] = 0;
f0100a12:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100a19:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f0100a20:	eb 1e                	jmp    f0100a40 <monitor+0xce>
			buf++;
f0100a22:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a25:	0f b6 06             	movzbl (%esi),%eax
f0100a28:	84 c0                	test   %al,%al
f0100a2a:	74 14                	je     f0100a40 <monitor+0xce>
f0100a2c:	83 ec 08             	sub    $0x8,%esp
f0100a2f:	0f be c0             	movsbl %al,%eax
f0100a32:	50                   	push   %eax
f0100a33:	57                   	push   %edi
f0100a34:	e8 4c 0c 00 00       	call   f0101685 <strchr>
f0100a39:	83 c4 10             	add    $0x10,%esp
f0100a3c:	85 c0                	test   %eax,%eax
f0100a3e:	74 e2                	je     f0100a22 <monitor+0xb0>
		while (*buf && strchr(WHITESPACE, *buf))
f0100a40:	0f b6 06             	movzbl (%esi),%eax
f0100a43:	84 c0                	test   %al,%al
f0100a45:	0f 85 60 ff ff ff    	jne    f01009ab <monitor+0x39>
	argv[argc] = 0;
f0100a4b:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100a4e:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f0100a55:	00 
	if (argc == 0)
f0100a56:	85 c0                	test   %eax,%eax
f0100a58:	74 9b                	je     f01009f5 <monitor+0x83>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a5a:	83 ec 08             	sub    $0x8,%esp
f0100a5d:	8d 83 f6 0a ff ff    	lea    -0xf50a(%ebx),%eax
f0100a63:	50                   	push   %eax
f0100a64:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a67:	e8 bb 0b 00 00       	call   f0101627 <strcmp>
f0100a6c:	83 c4 10             	add    $0x10,%esp
f0100a6f:	85 c0                	test   %eax,%eax
f0100a71:	74 38                	je     f0100aab <monitor+0x139>
f0100a73:	83 ec 08             	sub    $0x8,%esp
f0100a76:	8d 83 04 0b ff ff    	lea    -0xf4fc(%ebx),%eax
f0100a7c:	50                   	push   %eax
f0100a7d:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a80:	e8 a2 0b 00 00       	call   f0101627 <strcmp>
f0100a85:	83 c4 10             	add    $0x10,%esp
f0100a88:	85 c0                	test   %eax,%eax
f0100a8a:	74 1a                	je     f0100aa6 <monitor+0x134>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a8c:	83 ec 08             	sub    $0x8,%esp
f0100a8f:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a92:	8d 83 80 0b ff ff    	lea    -0xf480(%ebx),%eax
f0100a98:	50                   	push   %eax
f0100a99:	e8 90 00 00 00       	call   f0100b2e <cprintf>
f0100a9e:	83 c4 10             	add    $0x10,%esp
f0100aa1:	e9 4f ff ff ff       	jmp    f01009f5 <monitor+0x83>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100aa6:	b8 01 00 00 00       	mov    $0x1,%eax
			return commands[i].func(argc, argv, tf);
f0100aab:	83 ec 04             	sub    $0x4,%esp
f0100aae:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100ab1:	ff 75 08             	pushl  0x8(%ebp)
f0100ab4:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100ab7:	52                   	push   %edx
f0100ab8:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100abb:	ff 94 83 10 1d 00 00 	call   *0x1d10(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100ac2:	83 c4 10             	add    $0x10,%esp
f0100ac5:	85 c0                	test   %eax,%eax
f0100ac7:	0f 89 28 ff ff ff    	jns    f01009f5 <monitor+0x83>
				break;
	}
}
f0100acd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100ad0:	5b                   	pop    %ebx
f0100ad1:	5e                   	pop    %esi
f0100ad2:	5f                   	pop    %edi
f0100ad3:	5d                   	pop    %ebp
f0100ad4:	c3                   	ret    

f0100ad5 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100ad5:	55                   	push   %ebp
f0100ad6:	89 e5                	mov    %esp,%ebp
f0100ad8:	53                   	push   %ebx
f0100ad9:	83 ec 10             	sub    $0x10,%esp
f0100adc:	e8 0c f7 ff ff       	call   f01001ed <__x86.get_pc_thunk.bx>
f0100ae1:	81 c3 27 08 01 00    	add    $0x10827,%ebx
	cputchar(ch);
f0100ae7:	ff 75 08             	pushl  0x8(%ebp)
f0100aea:	e8 75 fc ff ff       	call   f0100764 <cputchar>
	*cnt++;
}
f0100aef:	83 c4 10             	add    $0x10,%esp
f0100af2:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100af5:	c9                   	leave  
f0100af6:	c3                   	ret    

f0100af7 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100af7:	55                   	push   %ebp
f0100af8:	89 e5                	mov    %esp,%ebp
f0100afa:	53                   	push   %ebx
f0100afb:	83 ec 14             	sub    $0x14,%esp
f0100afe:	e8 ea f6 ff ff       	call   f01001ed <__x86.get_pc_thunk.bx>
f0100b03:	81 c3 05 08 01 00    	add    $0x10805,%ebx
	int cnt = 0;
f0100b09:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100b10:	ff 75 0c             	pushl  0xc(%ebp)
f0100b13:	ff 75 08             	pushl  0x8(%ebp)
f0100b16:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100b19:	50                   	push   %eax
f0100b1a:	8d 83 cd f7 fe ff    	lea    -0x10833(%ebx),%eax
f0100b20:	50                   	push   %eax
f0100b21:	e8 1c 04 00 00       	call   f0100f42 <vprintfmt>
	return cnt;
}
f0100b26:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100b29:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100b2c:	c9                   	leave  
f0100b2d:	c3                   	ret    

f0100b2e <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100b2e:	55                   	push   %ebp
f0100b2f:	89 e5                	mov    %esp,%ebp
f0100b31:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100b34:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100b37:	50                   	push   %eax
f0100b38:	ff 75 08             	pushl  0x8(%ebp)
f0100b3b:	e8 b7 ff ff ff       	call   f0100af7 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100b40:	c9                   	leave  
f0100b41:	c3                   	ret    

f0100b42 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100b42:	55                   	push   %ebp
f0100b43:	89 e5                	mov    %esp,%ebp
f0100b45:	57                   	push   %edi
f0100b46:	56                   	push   %esi
f0100b47:	53                   	push   %ebx
f0100b48:	83 ec 14             	sub    $0x14,%esp
f0100b4b:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0100b4e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100b51:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0100b54:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100b57:	8b 32                	mov    (%edx),%esi
f0100b59:	8b 01                	mov    (%ecx),%eax
f0100b5b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100b5e:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0100b65:	eb 2f                	jmp    f0100b96 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f0100b67:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f0100b6a:	39 c6                	cmp    %eax,%esi
f0100b6c:	7f 49                	jg     f0100bb7 <stab_binsearch+0x75>
f0100b6e:	0f b6 0a             	movzbl (%edx),%ecx
f0100b71:	83 ea 0c             	sub    $0xc,%edx
f0100b74:	39 f9                	cmp    %edi,%ecx
f0100b76:	75 ef                	jne    f0100b67 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100b78:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100b7b:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100b7e:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0100b82:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100b85:	73 35                	jae    f0100bbc <stab_binsearch+0x7a>
			*region_left = m;
f0100b87:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100b8a:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0100b8c:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f0100b8f:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0100b96:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0100b99:	7f 4e                	jg     f0100be9 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0100b9b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100b9e:	01 f0                	add    %esi,%eax
f0100ba0:	89 c3                	mov    %eax,%ebx
f0100ba2:	c1 eb 1f             	shr    $0x1f,%ebx
f0100ba5:	01 c3                	add    %eax,%ebx
f0100ba7:	d1 fb                	sar    %ebx
f0100ba9:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100bac:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100baf:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0100bb3:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0100bb5:	eb b3                	jmp    f0100b6a <stab_binsearch+0x28>
			l = true_m + 1;
f0100bb7:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0100bba:	eb da                	jmp    f0100b96 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0100bbc:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0100bbf:	76 14                	jbe    f0100bd5 <stab_binsearch+0x93>
			*region_right = m - 1;
f0100bc1:	83 e8 01             	sub    $0x1,%eax
f0100bc4:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100bc7:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100bca:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0100bcc:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100bd3:	eb c1                	jmp    f0100b96 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100bd5:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100bd8:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0100bda:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0100bde:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f0100be0:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0100be7:	eb ad                	jmp    f0100b96 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0100be9:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0100bed:	74 16                	je     f0100c05 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100bef:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100bf2:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100bf4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100bf7:	8b 0e                	mov    (%esi),%ecx
f0100bf9:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0100bfc:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0100bff:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f0100c03:	eb 12                	jmp    f0100c17 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0100c05:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c08:	8b 00                	mov    (%eax),%eax
f0100c0a:	83 e8 01             	sub    $0x1,%eax
f0100c0d:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0100c10:	89 07                	mov    %eax,(%edi)
f0100c12:	eb 16                	jmp    f0100c2a <stab_binsearch+0xe8>
		     l--)
f0100c14:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0100c17:	39 c1                	cmp    %eax,%ecx
f0100c19:	7d 0a                	jge    f0100c25 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0100c1b:	0f b6 1a             	movzbl (%edx),%ebx
f0100c1e:	83 ea 0c             	sub    $0xc,%edx
f0100c21:	39 fb                	cmp    %edi,%ebx
f0100c23:	75 ef                	jne    f0100c14 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f0100c25:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100c28:	89 07                	mov    %eax,(%edi)
	}
}
f0100c2a:	83 c4 14             	add    $0x14,%esp
f0100c2d:	5b                   	pop    %ebx
f0100c2e:	5e                   	pop    %esi
f0100c2f:	5f                   	pop    %edi
f0100c30:	5d                   	pop    %ebp
f0100c31:	c3                   	ret    

f0100c32 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100c32:	55                   	push   %ebp
f0100c33:	89 e5                	mov    %esp,%ebp
f0100c35:	57                   	push   %edi
f0100c36:	56                   	push   %esi
f0100c37:	53                   	push   %ebx
f0100c38:	83 ec 2c             	sub    $0x2c,%esp
f0100c3b:	e8 fa 01 00 00       	call   f0100e3a <__x86.get_pc_thunk.cx>
f0100c40:	81 c1 c8 06 01 00    	add    $0x106c8,%ecx
f0100c46:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0100c49:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100c4c:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100c4f:	8d 81 f0 0c ff ff    	lea    -0xf310(%ecx),%eax
f0100c55:	89 07                	mov    %eax,(%edi)
	info->eip_line = 0;
f0100c57:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f0100c5e:	89 47 08             	mov    %eax,0x8(%edi)
	info->eip_fn_namelen = 9;
f0100c61:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f0100c68:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f0100c6b:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100c72:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0100c78:	0f 86 f4 00 00 00    	jbe    f0100d72 <debuginfo_eip+0x140>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100c7e:	c7 c0 55 5f 10 f0    	mov    $0xf0105f55,%eax
f0100c84:	39 81 fc ff ff ff    	cmp    %eax,-0x4(%ecx)
f0100c8a:	0f 86 88 01 00 00    	jbe    f0100e18 <debuginfo_eip+0x1e6>
f0100c90:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0100c93:	c7 c0 ca 78 10 f0    	mov    $0xf01078ca,%eax
f0100c99:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0100c9d:	0f 85 7c 01 00 00    	jne    f0100e1f <debuginfo_eip+0x1ed>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100ca3:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100caa:	c7 c0 10 22 10 f0    	mov    $0xf0102210,%eax
f0100cb0:	c7 c2 54 5f 10 f0    	mov    $0xf0105f54,%edx
f0100cb6:	29 c2                	sub    %eax,%edx
f0100cb8:	c1 fa 02             	sar    $0x2,%edx
f0100cbb:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f0100cc1:	83 ea 01             	sub    $0x1,%edx
f0100cc4:	89 55 e0             	mov    %edx,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100cc7:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100cca:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100ccd:	83 ec 08             	sub    $0x8,%esp
f0100cd0:	53                   	push   %ebx
f0100cd1:	6a 64                	push   $0x64
f0100cd3:	e8 6a fe ff ff       	call   f0100b42 <stab_binsearch>
	if (lfile == 0)
f0100cd8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100cdb:	83 c4 10             	add    $0x10,%esp
f0100cde:	85 c0                	test   %eax,%eax
f0100ce0:	0f 84 40 01 00 00    	je     f0100e26 <debuginfo_eip+0x1f4>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100ce6:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0100ce9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100cec:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100cef:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100cf2:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100cf5:	83 ec 08             	sub    $0x8,%esp
f0100cf8:	53                   	push   %ebx
f0100cf9:	6a 24                	push   $0x24
f0100cfb:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0100cfe:	c7 c0 10 22 10 f0    	mov    $0xf0102210,%eax
f0100d04:	e8 39 fe ff ff       	call   f0100b42 <stab_binsearch>

	if (lfun <= rfun) {
f0100d09:	8b 75 dc             	mov    -0x24(%ebp),%esi
f0100d0c:	83 c4 10             	add    $0x10,%esp
f0100d0f:	3b 75 d8             	cmp    -0x28(%ebp),%esi
f0100d12:	7f 79                	jg     f0100d8d <debuginfo_eip+0x15b>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100d14:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100d17:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100d1a:	c7 c2 10 22 10 f0    	mov    $0xf0102210,%edx
f0100d20:	8d 0c 82             	lea    (%edx,%eax,4),%ecx
f0100d23:	8b 11                	mov    (%ecx),%edx
f0100d25:	c7 c0 ca 78 10 f0    	mov    $0xf01078ca,%eax
f0100d2b:	81 e8 55 5f 10 f0    	sub    $0xf0105f55,%eax
f0100d31:	39 c2                	cmp    %eax,%edx
f0100d33:	73 09                	jae    f0100d3e <debuginfo_eip+0x10c>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100d35:	81 c2 55 5f 10 f0    	add    $0xf0105f55,%edx
f0100d3b:	89 57 08             	mov    %edx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100d3e:	8b 41 08             	mov    0x8(%ecx),%eax
f0100d41:	89 47 10             	mov    %eax,0x10(%edi)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100d44:	83 ec 08             	sub    $0x8,%esp
f0100d47:	6a 3a                	push   $0x3a
f0100d49:	ff 77 08             	pushl  0x8(%edi)
f0100d4c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100d4f:	e8 52 09 00 00       	call   f01016a6 <strfind>
f0100d54:	2b 47 08             	sub    0x8(%edi),%eax
f0100d57:	89 47 0c             	mov    %eax,0xc(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100d5a:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100d5d:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0100d60:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0100d63:	c7 c2 10 22 10 f0    	mov    $0xf0102210,%edx
f0100d69:	8d 44 82 04          	lea    0x4(%edx,%eax,4),%eax
f0100d6d:	83 c4 10             	add    $0x10,%esp
f0100d70:	eb 29                	jmp    f0100d9b <debuginfo_eip+0x169>
  	        panic("User address");
f0100d72:	83 ec 04             	sub    $0x4,%esp
f0100d75:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100d78:	8d 83 fa 0c ff ff    	lea    -0xf306(%ebx),%eax
f0100d7e:	50                   	push   %eax
f0100d7f:	6a 7f                	push   $0x7f
f0100d81:	8d 83 07 0d ff ff    	lea    -0xf2f9(%ebx),%eax
f0100d87:	50                   	push   %eax
f0100d88:	e8 aa f3 ff ff       	call   f0100137 <_panic>
		info->eip_fn_addr = addr;
f0100d8d:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f0100d90:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100d93:	eb af                	jmp    f0100d44 <debuginfo_eip+0x112>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100d95:	83 ee 01             	sub    $0x1,%esi
f0100d98:	83 e8 0c             	sub    $0xc,%eax
	while (lline >= lfile
f0100d9b:	39 f3                	cmp    %esi,%ebx
f0100d9d:	7f 3a                	jg     f0100dd9 <debuginfo_eip+0x1a7>
	       && stabs[lline].n_type != N_SOL
f0100d9f:	0f b6 10             	movzbl (%eax),%edx
f0100da2:	80 fa 84             	cmp    $0x84,%dl
f0100da5:	74 0b                	je     f0100db2 <debuginfo_eip+0x180>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100da7:	80 fa 64             	cmp    $0x64,%dl
f0100daa:	75 e9                	jne    f0100d95 <debuginfo_eip+0x163>
f0100dac:	83 78 04 00          	cmpl   $0x0,0x4(%eax)
f0100db0:	74 e3                	je     f0100d95 <debuginfo_eip+0x163>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100db2:	8d 14 76             	lea    (%esi,%esi,2),%edx
f0100db5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100db8:	c7 c0 10 22 10 f0    	mov    $0xf0102210,%eax
f0100dbe:	8b 14 90             	mov    (%eax,%edx,4),%edx
f0100dc1:	c7 c0 ca 78 10 f0    	mov    $0xf01078ca,%eax
f0100dc7:	81 e8 55 5f 10 f0    	sub    $0xf0105f55,%eax
f0100dcd:	39 c2                	cmp    %eax,%edx
f0100dcf:	73 08                	jae    f0100dd9 <debuginfo_eip+0x1a7>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100dd1:	81 c2 55 5f 10 f0    	add    $0xf0105f55,%edx
f0100dd7:	89 17                	mov    %edx,(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100dd9:	8b 5d dc             	mov    -0x24(%ebp),%ebx
f0100ddc:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100ddf:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0100de4:	39 cb                	cmp    %ecx,%ebx
f0100de6:	7d 4a                	jge    f0100e32 <debuginfo_eip+0x200>
		for (lline = lfun + 1;
f0100de8:	8d 53 01             	lea    0x1(%ebx),%edx
f0100deb:	8d 1c 5b             	lea    (%ebx,%ebx,2),%ebx
f0100dee:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100df1:	c7 c0 10 22 10 f0    	mov    $0xf0102210,%eax
f0100df7:	8d 44 98 10          	lea    0x10(%eax,%ebx,4),%eax
f0100dfb:	eb 07                	jmp    f0100e04 <debuginfo_eip+0x1d2>
			info->eip_fn_narg++;
f0100dfd:	83 47 14 01          	addl   $0x1,0x14(%edi)
		     lline++)
f0100e01:	83 c2 01             	add    $0x1,%edx
		for (lline = lfun + 1;
f0100e04:	39 d1                	cmp    %edx,%ecx
f0100e06:	74 25                	je     f0100e2d <debuginfo_eip+0x1fb>
f0100e08:	83 c0 0c             	add    $0xc,%eax
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100e0b:	80 78 f4 a0          	cmpb   $0xa0,-0xc(%eax)
f0100e0f:	74 ec                	je     f0100dfd <debuginfo_eip+0x1cb>
	return 0;
f0100e11:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e16:	eb 1a                	jmp    f0100e32 <debuginfo_eip+0x200>
		return -1;
f0100e18:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100e1d:	eb 13                	jmp    f0100e32 <debuginfo_eip+0x200>
f0100e1f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100e24:	eb 0c                	jmp    f0100e32 <debuginfo_eip+0x200>
		return -1;
f0100e26:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100e2b:	eb 05                	jmp    f0100e32 <debuginfo_eip+0x200>
	return 0;
f0100e2d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100e32:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e35:	5b                   	pop    %ebx
f0100e36:	5e                   	pop    %esi
f0100e37:	5f                   	pop    %edi
f0100e38:	5d                   	pop    %ebp
f0100e39:	c3                   	ret    

f0100e3a <__x86.get_pc_thunk.cx>:
f0100e3a:	8b 0c 24             	mov    (%esp),%ecx
f0100e3d:	c3                   	ret    

f0100e3e <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100e3e:	55                   	push   %ebp
f0100e3f:	89 e5                	mov    %esp,%ebp
f0100e41:	57                   	push   %edi
f0100e42:	56                   	push   %esi
f0100e43:	53                   	push   %ebx
f0100e44:	83 ec 2c             	sub    $0x2c,%esp
f0100e47:	e8 ee ff ff ff       	call   f0100e3a <__x86.get_pc_thunk.cx>
f0100e4c:	81 c1 bc 04 01 00    	add    $0x104bc,%ecx
f0100e52:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100e55:	89 c7                	mov    %eax,%edi
f0100e57:	89 d6                	mov    %edx,%esi
f0100e59:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e5c:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100e5f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100e62:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0100e65:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0100e68:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100e6d:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f0100e70:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0100e73:	39 d3                	cmp    %edx,%ebx
f0100e75:	72 09                	jb     f0100e80 <printnum+0x42>
f0100e77:	39 45 10             	cmp    %eax,0x10(%ebp)
f0100e7a:	0f 87 83 00 00 00    	ja     f0100f03 <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0100e80:	83 ec 0c             	sub    $0xc,%esp
f0100e83:	ff 75 18             	pushl  0x18(%ebp)
f0100e86:	8b 45 14             	mov    0x14(%ebp),%eax
f0100e89:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0100e8c:	53                   	push   %ebx
f0100e8d:	ff 75 10             	pushl  0x10(%ebp)
f0100e90:	83 ec 08             	sub    $0x8,%esp
f0100e93:	ff 75 dc             	pushl  -0x24(%ebp)
f0100e96:	ff 75 d8             	pushl  -0x28(%ebp)
f0100e99:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100e9c:	ff 75 d0             	pushl  -0x30(%ebp)
f0100e9f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0100ea2:	e8 19 0a 00 00       	call   f01018c0 <__udivdi3>
f0100ea7:	83 c4 18             	add    $0x18,%esp
f0100eaa:	52                   	push   %edx
f0100eab:	50                   	push   %eax
f0100eac:	89 f2                	mov    %esi,%edx
f0100eae:	89 f8                	mov    %edi,%eax
f0100eb0:	e8 89 ff ff ff       	call   f0100e3e <printnum>
f0100eb5:	83 c4 20             	add    $0x20,%esp
f0100eb8:	eb 13                	jmp    f0100ecd <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0100eba:	83 ec 08             	sub    $0x8,%esp
f0100ebd:	56                   	push   %esi
f0100ebe:	ff 75 18             	pushl  0x18(%ebp)
f0100ec1:	ff d7                	call   *%edi
f0100ec3:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0100ec6:	83 eb 01             	sub    $0x1,%ebx
f0100ec9:	85 db                	test   %ebx,%ebx
f0100ecb:	7f ed                	jg     f0100eba <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0100ecd:	83 ec 08             	sub    $0x8,%esp
f0100ed0:	56                   	push   %esi
f0100ed1:	83 ec 04             	sub    $0x4,%esp
f0100ed4:	ff 75 dc             	pushl  -0x24(%ebp)
f0100ed7:	ff 75 d8             	pushl  -0x28(%ebp)
f0100eda:	ff 75 d4             	pushl  -0x2c(%ebp)
f0100edd:	ff 75 d0             	pushl  -0x30(%ebp)
f0100ee0:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0100ee3:	89 f3                	mov    %esi,%ebx
f0100ee5:	e8 f6 0a 00 00       	call   f01019e0 <__umoddi3>
f0100eea:	83 c4 14             	add    $0x14,%esp
f0100eed:	0f be 84 06 15 0d ff 	movsbl -0xf2eb(%esi,%eax,1),%eax
f0100ef4:	ff 
f0100ef5:	50                   	push   %eax
f0100ef6:	ff d7                	call   *%edi
}
f0100ef8:	83 c4 10             	add    $0x10,%esp
f0100efb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100efe:	5b                   	pop    %ebx
f0100eff:	5e                   	pop    %esi
f0100f00:	5f                   	pop    %edi
f0100f01:	5d                   	pop    %ebp
f0100f02:	c3                   	ret    
f0100f03:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100f06:	eb be                	jmp    f0100ec6 <printnum+0x88>

f0100f08 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0100f08:	55                   	push   %ebp
f0100f09:	89 e5                	mov    %esp,%ebp
f0100f0b:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0100f0e:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0100f12:	8b 10                	mov    (%eax),%edx
f0100f14:	3b 50 04             	cmp    0x4(%eax),%edx
f0100f17:	73 0a                	jae    f0100f23 <sprintputch+0x1b>
		*b->buf++ = ch;
f0100f19:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100f1c:	89 08                	mov    %ecx,(%eax)
f0100f1e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f21:	88 02                	mov    %al,(%edx)
}
f0100f23:	5d                   	pop    %ebp
f0100f24:	c3                   	ret    

f0100f25 <printfmt>:
{
f0100f25:	55                   	push   %ebp
f0100f26:	89 e5                	mov    %esp,%ebp
f0100f28:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0100f2b:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0100f2e:	50                   	push   %eax
f0100f2f:	ff 75 10             	pushl  0x10(%ebp)
f0100f32:	ff 75 0c             	pushl  0xc(%ebp)
f0100f35:	ff 75 08             	pushl  0x8(%ebp)
f0100f38:	e8 05 00 00 00       	call   f0100f42 <vprintfmt>
}
f0100f3d:	83 c4 10             	add    $0x10,%esp
f0100f40:	c9                   	leave  
f0100f41:	c3                   	ret    

f0100f42 <vprintfmt>:
{
f0100f42:	55                   	push   %ebp
f0100f43:	89 e5                	mov    %esp,%ebp
f0100f45:	57                   	push   %edi
f0100f46:	56                   	push   %esi
f0100f47:	53                   	push   %ebx
f0100f48:	83 ec 2c             	sub    $0x2c,%esp
f0100f4b:	e8 9d f2 ff ff       	call   f01001ed <__x86.get_pc_thunk.bx>
f0100f50:	81 c3 b8 03 01 00    	add    $0x103b8,%ebx
f0100f56:	8b 75 0c             	mov    0xc(%ebp),%esi
f0100f59:	8b 7d 10             	mov    0x10(%ebp),%edi
f0100f5c:	e9 63 03 00 00       	jmp    f01012c4 <.L34+0x40>
		padc = ' ';
f0100f61:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f0100f65:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0100f6c:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
		width = -1;
f0100f73:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0100f7a:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100f7f:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100f82:	8d 47 01             	lea    0x1(%edi),%eax
f0100f85:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100f88:	0f b6 17             	movzbl (%edi),%edx
f0100f8b:	8d 42 dd             	lea    -0x23(%edx),%eax
f0100f8e:	3c 55                	cmp    $0x55,%al
f0100f90:	0f 87 15 04 00 00    	ja     f01013ab <.L22>
f0100f96:	0f b6 c0             	movzbl %al,%eax
f0100f99:	89 d9                	mov    %ebx,%ecx
f0100f9b:	03 8c 83 a0 0d ff ff 	add    -0xf260(%ebx,%eax,4),%ecx
f0100fa2:	ff e1                	jmp    *%ecx

f0100fa4 <.L70>:
f0100fa4:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0100fa7:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0100fab:	eb d5                	jmp    f0100f82 <vprintfmt+0x40>

f0100fad <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f0100fad:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f0100fb0:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0100fb4:	eb cc                	jmp    f0100f82 <vprintfmt+0x40>

f0100fb6 <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f0100fb6:	0f b6 d2             	movzbl %dl,%edx
f0100fb9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0100fbc:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f0100fc1:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100fc4:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0100fc8:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0100fcb:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0100fce:	83 f9 09             	cmp    $0x9,%ecx
f0100fd1:	77 55                	ja     f0101028 <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f0100fd3:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0100fd6:	eb e9                	jmp    f0100fc1 <.L29+0xb>

f0100fd8 <.L26>:
			precision = va_arg(ap, int);
f0100fd8:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fdb:	8b 00                	mov    (%eax),%eax
f0100fdd:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100fe0:	8b 45 14             	mov    0x14(%ebp),%eax
f0100fe3:	8d 40 04             	lea    0x4(%eax),%eax
f0100fe6:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0100fe9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0100fec:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0100ff0:	79 90                	jns    f0100f82 <vprintfmt+0x40>
				width = precision, precision = -1;
f0100ff2:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0100ff5:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100ff8:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f0100fff:	eb 81                	jmp    f0100f82 <vprintfmt+0x40>

f0101001 <.L27>:
f0101001:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101004:	85 c0                	test   %eax,%eax
f0101006:	ba 00 00 00 00       	mov    $0x0,%edx
f010100b:	0f 49 d0             	cmovns %eax,%edx
f010100e:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101011:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0101014:	e9 69 ff ff ff       	jmp    f0100f82 <vprintfmt+0x40>

f0101019 <.L23>:
f0101019:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f010101c:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0101023:	e9 5a ff ff ff       	jmp    f0100f82 <vprintfmt+0x40>
f0101028:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010102b:	eb bf                	jmp    f0100fec <.L26+0x14>

f010102d <.L33>:
			lflag++;
f010102d:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0101031:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0101034:	e9 49 ff ff ff       	jmp    f0100f82 <vprintfmt+0x40>

f0101039 <.L30>:
			putch(va_arg(ap, int), putdat);
f0101039:	8b 45 14             	mov    0x14(%ebp),%eax
f010103c:	8d 78 04             	lea    0x4(%eax),%edi
f010103f:	83 ec 08             	sub    $0x8,%esp
f0101042:	56                   	push   %esi
f0101043:	ff 30                	pushl  (%eax)
f0101045:	ff 55 08             	call   *0x8(%ebp)
			break;
f0101048:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f010104b:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f010104e:	e9 6e 02 00 00       	jmp    f01012c1 <.L34+0x3d>

f0101053 <.L32>:
			err = va_arg(ap, int);
f0101053:	8b 45 14             	mov    0x14(%ebp),%eax
f0101056:	8d 78 04             	lea    0x4(%eax),%edi
f0101059:	8b 00                	mov    (%eax),%eax
f010105b:	99                   	cltd   
f010105c:	31 d0                	xor    %edx,%eax
f010105e:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0101060:	83 f8 06             	cmp    $0x6,%eax
f0101063:	7f 27                	jg     f010108c <.L32+0x39>
f0101065:	8b 94 83 20 1d 00 00 	mov    0x1d20(%ebx,%eax,4),%edx
f010106c:	85 d2                	test   %edx,%edx
f010106e:	74 1c                	je     f010108c <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f0101070:	52                   	push   %edx
f0101071:	8d 83 62 08 ff ff    	lea    -0xf79e(%ebx),%eax
f0101077:	50                   	push   %eax
f0101078:	56                   	push   %esi
f0101079:	ff 75 08             	pushl  0x8(%ebp)
f010107c:	e8 a4 fe ff ff       	call   f0100f25 <printfmt>
f0101081:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0101084:	89 7d 14             	mov    %edi,0x14(%ebp)
f0101087:	e9 35 02 00 00       	jmp    f01012c1 <.L34+0x3d>
				printfmt(putch, putdat, "error %d", err);
f010108c:	50                   	push   %eax
f010108d:	8d 83 2d 0d ff ff    	lea    -0xf2d3(%ebx),%eax
f0101093:	50                   	push   %eax
f0101094:	56                   	push   %esi
f0101095:	ff 75 08             	pushl  0x8(%ebp)
f0101098:	e8 88 fe ff ff       	call   f0100f25 <printfmt>
f010109d:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f01010a0:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f01010a3:	e9 19 02 00 00       	jmp    f01012c1 <.L34+0x3d>

f01010a8 <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f01010a8:	8b 45 14             	mov    0x14(%ebp),%eax
f01010ab:	83 c0 04             	add    $0x4,%eax
f01010ae:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01010b1:	8b 45 14             	mov    0x14(%ebp),%eax
f01010b4:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f01010b6:	85 ff                	test   %edi,%edi
f01010b8:	8d 83 26 0d ff ff    	lea    -0xf2da(%ebx),%eax
f01010be:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f01010c1:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01010c5:	0f 8e b5 00 00 00    	jle    f0101180 <.L36+0xd8>
f01010cb:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f01010cf:	75 08                	jne    f01010d9 <.L36+0x31>
f01010d1:	89 75 0c             	mov    %esi,0xc(%ebp)
f01010d4:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01010d7:	eb 6d                	jmp    f0101146 <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f01010d9:	83 ec 08             	sub    $0x8,%esp
f01010dc:	ff 75 cc             	pushl  -0x34(%ebp)
f01010df:	57                   	push   %edi
f01010e0:	e8 7d 04 00 00       	call   f0101562 <strnlen>
f01010e5:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01010e8:	29 c2                	sub    %eax,%edx
f01010ea:	89 55 c8             	mov    %edx,-0x38(%ebp)
f01010ed:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f01010f0:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f01010f4:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01010f7:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01010fa:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f01010fc:	eb 10                	jmp    f010110e <.L36+0x66>
					putch(padc, putdat);
f01010fe:	83 ec 08             	sub    $0x8,%esp
f0101101:	56                   	push   %esi
f0101102:	ff 75 e0             	pushl  -0x20(%ebp)
f0101105:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0101108:	83 ef 01             	sub    $0x1,%edi
f010110b:	83 c4 10             	add    $0x10,%esp
f010110e:	85 ff                	test   %edi,%edi
f0101110:	7f ec                	jg     f01010fe <.L36+0x56>
f0101112:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101115:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0101118:	85 d2                	test   %edx,%edx
f010111a:	b8 00 00 00 00       	mov    $0x0,%eax
f010111f:	0f 49 c2             	cmovns %edx,%eax
f0101122:	29 c2                	sub    %eax,%edx
f0101124:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0101127:	89 75 0c             	mov    %esi,0xc(%ebp)
f010112a:	8b 75 cc             	mov    -0x34(%ebp),%esi
f010112d:	eb 17                	jmp    f0101146 <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f010112f:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0101133:	75 30                	jne    f0101165 <.L36+0xbd>
					putch(ch, putdat);
f0101135:	83 ec 08             	sub    $0x8,%esp
f0101138:	ff 75 0c             	pushl  0xc(%ebp)
f010113b:	50                   	push   %eax
f010113c:	ff 55 08             	call   *0x8(%ebp)
f010113f:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101142:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f0101146:	83 c7 01             	add    $0x1,%edi
f0101149:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f010114d:	0f be c2             	movsbl %dl,%eax
f0101150:	85 c0                	test   %eax,%eax
f0101152:	74 52                	je     f01011a6 <.L36+0xfe>
f0101154:	85 f6                	test   %esi,%esi
f0101156:	78 d7                	js     f010112f <.L36+0x87>
f0101158:	83 ee 01             	sub    $0x1,%esi
f010115b:	79 d2                	jns    f010112f <.L36+0x87>
f010115d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101160:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0101163:	eb 32                	jmp    f0101197 <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f0101165:	0f be d2             	movsbl %dl,%edx
f0101168:	83 ea 20             	sub    $0x20,%edx
f010116b:	83 fa 5e             	cmp    $0x5e,%edx
f010116e:	76 c5                	jbe    f0101135 <.L36+0x8d>
					putch('?', putdat);
f0101170:	83 ec 08             	sub    $0x8,%esp
f0101173:	ff 75 0c             	pushl  0xc(%ebp)
f0101176:	6a 3f                	push   $0x3f
f0101178:	ff 55 08             	call   *0x8(%ebp)
f010117b:	83 c4 10             	add    $0x10,%esp
f010117e:	eb c2                	jmp    f0101142 <.L36+0x9a>
f0101180:	89 75 0c             	mov    %esi,0xc(%ebp)
f0101183:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0101186:	eb be                	jmp    f0101146 <.L36+0x9e>
				putch(' ', putdat);
f0101188:	83 ec 08             	sub    $0x8,%esp
f010118b:	56                   	push   %esi
f010118c:	6a 20                	push   $0x20
f010118e:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f0101191:	83 ef 01             	sub    $0x1,%edi
f0101194:	83 c4 10             	add    $0x10,%esp
f0101197:	85 ff                	test   %edi,%edi
f0101199:	7f ed                	jg     f0101188 <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f010119b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010119e:	89 45 14             	mov    %eax,0x14(%ebp)
f01011a1:	e9 1b 01 00 00       	jmp    f01012c1 <.L34+0x3d>
f01011a6:	8b 7d e0             	mov    -0x20(%ebp),%edi
f01011a9:	8b 75 0c             	mov    0xc(%ebp),%esi
f01011ac:	eb e9                	jmp    f0101197 <.L36+0xef>

f01011ae <.L31>:
f01011ae:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f01011b1:	83 f9 01             	cmp    $0x1,%ecx
f01011b4:	7e 40                	jle    f01011f6 <.L31+0x48>
		return va_arg(*ap, long long);
f01011b6:	8b 45 14             	mov    0x14(%ebp),%eax
f01011b9:	8b 50 04             	mov    0x4(%eax),%edx
f01011bc:	8b 00                	mov    (%eax),%eax
f01011be:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01011c1:	89 55 dc             	mov    %edx,-0x24(%ebp)
f01011c4:	8b 45 14             	mov    0x14(%ebp),%eax
f01011c7:	8d 40 08             	lea    0x8(%eax),%eax
f01011ca:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f01011cd:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01011d1:	79 55                	jns    f0101228 <.L31+0x7a>
				putch('-', putdat);
f01011d3:	83 ec 08             	sub    $0x8,%esp
f01011d6:	56                   	push   %esi
f01011d7:	6a 2d                	push   $0x2d
f01011d9:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01011dc:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01011df:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01011e2:	f7 da                	neg    %edx
f01011e4:	83 d1 00             	adc    $0x0,%ecx
f01011e7:	f7 d9                	neg    %ecx
f01011e9:	83 c4 10             	add    $0x10,%esp
			base = 10;
f01011ec:	b8 0a 00 00 00       	mov    $0xa,%eax
f01011f1:	e9 b0 00 00 00       	jmp    f01012a6 <.L34+0x22>
	else if (lflag)
f01011f6:	85 c9                	test   %ecx,%ecx
f01011f8:	75 17                	jne    f0101211 <.L31+0x63>
		return va_arg(*ap, int);
f01011fa:	8b 45 14             	mov    0x14(%ebp),%eax
f01011fd:	8b 00                	mov    (%eax),%eax
f01011ff:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101202:	99                   	cltd   
f0101203:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0101206:	8b 45 14             	mov    0x14(%ebp),%eax
f0101209:	8d 40 04             	lea    0x4(%eax),%eax
f010120c:	89 45 14             	mov    %eax,0x14(%ebp)
f010120f:	eb bc                	jmp    f01011cd <.L31+0x1f>
		return va_arg(*ap, long);
f0101211:	8b 45 14             	mov    0x14(%ebp),%eax
f0101214:	8b 00                	mov    (%eax),%eax
f0101216:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101219:	99                   	cltd   
f010121a:	89 55 dc             	mov    %edx,-0x24(%ebp)
f010121d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101220:	8d 40 04             	lea    0x4(%eax),%eax
f0101223:	89 45 14             	mov    %eax,0x14(%ebp)
f0101226:	eb a5                	jmp    f01011cd <.L31+0x1f>
			num = getint(&ap, lflag);
f0101228:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010122b:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f010122e:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101233:	eb 71                	jmp    f01012a6 <.L34+0x22>

f0101235 <.L37>:
f0101235:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0101238:	83 f9 01             	cmp    $0x1,%ecx
f010123b:	7e 15                	jle    f0101252 <.L37+0x1d>
		return va_arg(*ap, unsigned long long);
f010123d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101240:	8b 10                	mov    (%eax),%edx
f0101242:	8b 48 04             	mov    0x4(%eax),%ecx
f0101245:	8d 40 08             	lea    0x8(%eax),%eax
f0101248:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f010124b:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101250:	eb 54                	jmp    f01012a6 <.L34+0x22>
	else if (lflag)
f0101252:	85 c9                	test   %ecx,%ecx
f0101254:	75 17                	jne    f010126d <.L37+0x38>
		return va_arg(*ap, unsigned int);
f0101256:	8b 45 14             	mov    0x14(%ebp),%eax
f0101259:	8b 10                	mov    (%eax),%edx
f010125b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101260:	8d 40 04             	lea    0x4(%eax),%eax
f0101263:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0101266:	b8 0a 00 00 00       	mov    $0xa,%eax
f010126b:	eb 39                	jmp    f01012a6 <.L34+0x22>
		return va_arg(*ap, unsigned long);
f010126d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101270:	8b 10                	mov    (%eax),%edx
f0101272:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101277:	8d 40 04             	lea    0x4(%eax),%eax
f010127a:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f010127d:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101282:	eb 22                	jmp    f01012a6 <.L34+0x22>

f0101284 <.L34>:
f0101284:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0101287:	83 f9 01             	cmp    $0x1,%ecx
f010128a:	7e 5d                	jle    f01012e9 <.L34+0x65>
		return va_arg(*ap, long long);
f010128c:	8b 45 14             	mov    0x14(%ebp),%eax
f010128f:	8b 50 04             	mov    0x4(%eax),%edx
f0101292:	8b 00                	mov    (%eax),%eax
f0101294:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0101297:	8d 49 08             	lea    0x8(%ecx),%ecx
f010129a:	89 4d 14             	mov    %ecx,0x14(%ebp)
			num = getint(&ap, lflag);
f010129d:	89 d1                	mov    %edx,%ecx
f010129f:	89 c2                	mov    %eax,%edx
			base = 8;
f01012a1:	b8 08 00 00 00       	mov    $0x8,%eax
			printnum(putch, putdat, num, base, width, padc);
f01012a6:	83 ec 0c             	sub    $0xc,%esp
f01012a9:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f01012ad:	57                   	push   %edi
f01012ae:	ff 75 e0             	pushl  -0x20(%ebp)
f01012b1:	50                   	push   %eax
f01012b2:	51                   	push   %ecx
f01012b3:	52                   	push   %edx
f01012b4:	89 f2                	mov    %esi,%edx
f01012b6:	8b 45 08             	mov    0x8(%ebp),%eax
f01012b9:	e8 80 fb ff ff       	call   f0100e3e <printnum>
			break;
f01012be:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f01012c1:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01012c4:	83 c7 01             	add    $0x1,%edi
f01012c7:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f01012cb:	83 f8 25             	cmp    $0x25,%eax
f01012ce:	0f 84 8d fc ff ff    	je     f0100f61 <vprintfmt+0x1f>
			if (ch == '\0')
f01012d4:	85 c0                	test   %eax,%eax
f01012d6:	0f 84 f0 00 00 00    	je     f01013cc <.L22+0x21>
			putch(ch, putdat);
f01012dc:	83 ec 08             	sub    $0x8,%esp
f01012df:	56                   	push   %esi
f01012e0:	50                   	push   %eax
f01012e1:	ff 55 08             	call   *0x8(%ebp)
f01012e4:	83 c4 10             	add    $0x10,%esp
f01012e7:	eb db                	jmp    f01012c4 <.L34+0x40>
	else if (lflag)
f01012e9:	85 c9                	test   %ecx,%ecx
f01012eb:	75 13                	jne    f0101300 <.L34+0x7c>
		return va_arg(*ap, int);
f01012ed:	8b 45 14             	mov    0x14(%ebp),%eax
f01012f0:	8b 10                	mov    (%eax),%edx
f01012f2:	89 d0                	mov    %edx,%eax
f01012f4:	99                   	cltd   
f01012f5:	8b 4d 14             	mov    0x14(%ebp),%ecx
f01012f8:	8d 49 04             	lea    0x4(%ecx),%ecx
f01012fb:	89 4d 14             	mov    %ecx,0x14(%ebp)
f01012fe:	eb 9d                	jmp    f010129d <.L34+0x19>
		return va_arg(*ap, long);
f0101300:	8b 45 14             	mov    0x14(%ebp),%eax
f0101303:	8b 10                	mov    (%eax),%edx
f0101305:	89 d0                	mov    %edx,%eax
f0101307:	99                   	cltd   
f0101308:	8b 4d 14             	mov    0x14(%ebp),%ecx
f010130b:	8d 49 04             	lea    0x4(%ecx),%ecx
f010130e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0101311:	eb 8a                	jmp    f010129d <.L34+0x19>

f0101313 <.L35>:
			putch('0', putdat);
f0101313:	83 ec 08             	sub    $0x8,%esp
f0101316:	56                   	push   %esi
f0101317:	6a 30                	push   $0x30
f0101319:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f010131c:	83 c4 08             	add    $0x8,%esp
f010131f:	56                   	push   %esi
f0101320:	6a 78                	push   $0x78
f0101322:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f0101325:	8b 45 14             	mov    0x14(%ebp),%eax
f0101328:	8b 10                	mov    (%eax),%edx
f010132a:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f010132f:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0101332:	8d 40 04             	lea    0x4(%eax),%eax
f0101335:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101338:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f010133d:	e9 64 ff ff ff       	jmp    f01012a6 <.L34+0x22>

f0101342 <.L38>:
f0101342:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0101345:	83 f9 01             	cmp    $0x1,%ecx
f0101348:	7e 18                	jle    f0101362 <.L38+0x20>
		return va_arg(*ap, unsigned long long);
f010134a:	8b 45 14             	mov    0x14(%ebp),%eax
f010134d:	8b 10                	mov    (%eax),%edx
f010134f:	8b 48 04             	mov    0x4(%eax),%ecx
f0101352:	8d 40 08             	lea    0x8(%eax),%eax
f0101355:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101358:	b8 10 00 00 00       	mov    $0x10,%eax
f010135d:	e9 44 ff ff ff       	jmp    f01012a6 <.L34+0x22>
	else if (lflag)
f0101362:	85 c9                	test   %ecx,%ecx
f0101364:	75 1a                	jne    f0101380 <.L38+0x3e>
		return va_arg(*ap, unsigned int);
f0101366:	8b 45 14             	mov    0x14(%ebp),%eax
f0101369:	8b 10                	mov    (%eax),%edx
f010136b:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101370:	8d 40 04             	lea    0x4(%eax),%eax
f0101373:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101376:	b8 10 00 00 00       	mov    $0x10,%eax
f010137b:	e9 26 ff ff ff       	jmp    f01012a6 <.L34+0x22>
		return va_arg(*ap, unsigned long);
f0101380:	8b 45 14             	mov    0x14(%ebp),%eax
f0101383:	8b 10                	mov    (%eax),%edx
f0101385:	b9 00 00 00 00       	mov    $0x0,%ecx
f010138a:	8d 40 04             	lea    0x4(%eax),%eax
f010138d:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0101390:	b8 10 00 00 00       	mov    $0x10,%eax
f0101395:	e9 0c ff ff ff       	jmp    f01012a6 <.L34+0x22>

f010139a <.L25>:
			putch(ch, putdat);
f010139a:	83 ec 08             	sub    $0x8,%esp
f010139d:	56                   	push   %esi
f010139e:	6a 25                	push   $0x25
f01013a0:	ff 55 08             	call   *0x8(%ebp)
			break;
f01013a3:	83 c4 10             	add    $0x10,%esp
f01013a6:	e9 16 ff ff ff       	jmp    f01012c1 <.L34+0x3d>

f01013ab <.L22>:
			putch('%', putdat);
f01013ab:	83 ec 08             	sub    $0x8,%esp
f01013ae:	56                   	push   %esi
f01013af:	6a 25                	push   $0x25
f01013b1:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01013b4:	83 c4 10             	add    $0x10,%esp
f01013b7:	89 f8                	mov    %edi,%eax
f01013b9:	eb 03                	jmp    f01013be <.L22+0x13>
f01013bb:	83 e8 01             	sub    $0x1,%eax
f01013be:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f01013c2:	75 f7                	jne    f01013bb <.L22+0x10>
f01013c4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01013c7:	e9 f5 fe ff ff       	jmp    f01012c1 <.L34+0x3d>
}
f01013cc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01013cf:	5b                   	pop    %ebx
f01013d0:	5e                   	pop    %esi
f01013d1:	5f                   	pop    %edi
f01013d2:	5d                   	pop    %ebp
f01013d3:	c3                   	ret    

f01013d4 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01013d4:	55                   	push   %ebp
f01013d5:	89 e5                	mov    %esp,%ebp
f01013d7:	53                   	push   %ebx
f01013d8:	83 ec 14             	sub    $0x14,%esp
f01013db:	e8 0d ee ff ff       	call   f01001ed <__x86.get_pc_thunk.bx>
f01013e0:	81 c3 28 ff 00 00    	add    $0xff28,%ebx
f01013e6:	8b 45 08             	mov    0x8(%ebp),%eax
f01013e9:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01013ec:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01013ef:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01013f3:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01013f6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01013fd:	85 c0                	test   %eax,%eax
f01013ff:	74 2b                	je     f010142c <vsnprintf+0x58>
f0101401:	85 d2                	test   %edx,%edx
f0101403:	7e 27                	jle    f010142c <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101405:	ff 75 14             	pushl  0x14(%ebp)
f0101408:	ff 75 10             	pushl  0x10(%ebp)
f010140b:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010140e:	50                   	push   %eax
f010140f:	8d 83 00 fc fe ff    	lea    -0x10400(%ebx),%eax
f0101415:	50                   	push   %eax
f0101416:	e8 27 fb ff ff       	call   f0100f42 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010141b:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010141e:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101421:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101424:	83 c4 10             	add    $0x10,%esp
}
f0101427:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010142a:	c9                   	leave  
f010142b:	c3                   	ret    
		return -E_INVAL;
f010142c:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0101431:	eb f4                	jmp    f0101427 <vsnprintf+0x53>

f0101433 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0101433:	55                   	push   %ebp
f0101434:	89 e5                	mov    %esp,%ebp
f0101436:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101439:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010143c:	50                   	push   %eax
f010143d:	ff 75 10             	pushl  0x10(%ebp)
f0101440:	ff 75 0c             	pushl  0xc(%ebp)
f0101443:	ff 75 08             	pushl  0x8(%ebp)
f0101446:	e8 89 ff ff ff       	call   f01013d4 <vsnprintf>
	va_end(ap);

	return rc;
}
f010144b:	c9                   	leave  
f010144c:	c3                   	ret    

f010144d <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010144d:	55                   	push   %ebp
f010144e:	89 e5                	mov    %esp,%ebp
f0101450:	57                   	push   %edi
f0101451:	56                   	push   %esi
f0101452:	53                   	push   %ebx
f0101453:	83 ec 1c             	sub    $0x1c,%esp
f0101456:	e8 92 ed ff ff       	call   f01001ed <__x86.get_pc_thunk.bx>
f010145b:	81 c3 ad fe 00 00    	add    $0xfead,%ebx
f0101461:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0101464:	85 c0                	test   %eax,%eax
f0101466:	74 13                	je     f010147b <readline+0x2e>
		cprintf("%s", prompt);
f0101468:	83 ec 08             	sub    $0x8,%esp
f010146b:	50                   	push   %eax
f010146c:	8d 83 62 08 ff ff    	lea    -0xf79e(%ebx),%eax
f0101472:	50                   	push   %eax
f0101473:	e8 b6 f6 ff ff       	call   f0100b2e <cprintf>
f0101478:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f010147b:	83 ec 0c             	sub    $0xc,%esp
f010147e:	6a 00                	push   $0x0
f0101480:	e8 00 f3 ff ff       	call   f0100785 <iscons>
f0101485:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101488:	83 c4 10             	add    $0x10,%esp
	i = 0;
f010148b:	bf 00 00 00 00       	mov    $0x0,%edi
f0101490:	eb 46                	jmp    f01014d8 <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0101492:	83 ec 08             	sub    $0x8,%esp
f0101495:	50                   	push   %eax
f0101496:	8d 83 f8 0e ff ff    	lea    -0xf108(%ebx),%eax
f010149c:	50                   	push   %eax
f010149d:	e8 8c f6 ff ff       	call   f0100b2e <cprintf>
			return NULL;
f01014a2:	83 c4 10             	add    $0x10,%esp
f01014a5:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f01014aa:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01014ad:	5b                   	pop    %ebx
f01014ae:	5e                   	pop    %esi
f01014af:	5f                   	pop    %edi
f01014b0:	5d                   	pop    %ebp
f01014b1:	c3                   	ret    
			if (echoing)
f01014b2:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01014b6:	75 05                	jne    f01014bd <readline+0x70>
			i--;
f01014b8:	83 ef 01             	sub    $0x1,%edi
f01014bb:	eb 1b                	jmp    f01014d8 <readline+0x8b>
				cputchar('\b');
f01014bd:	83 ec 0c             	sub    $0xc,%esp
f01014c0:	6a 08                	push   $0x8
f01014c2:	e8 9d f2 ff ff       	call   f0100764 <cputchar>
f01014c7:	83 c4 10             	add    $0x10,%esp
f01014ca:	eb ec                	jmp    f01014b8 <readline+0x6b>
			buf[i++] = c;
f01014cc:	89 f0                	mov    %esi,%eax
f01014ce:	88 84 3b 98 1f 00 00 	mov    %al,0x1f98(%ebx,%edi,1)
f01014d5:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f01014d8:	e8 97 f2 ff ff       	call   f0100774 <getchar>
f01014dd:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f01014df:	85 c0                	test   %eax,%eax
f01014e1:	78 af                	js     f0101492 <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01014e3:	83 f8 08             	cmp    $0x8,%eax
f01014e6:	0f 94 c2             	sete   %dl
f01014e9:	83 f8 7f             	cmp    $0x7f,%eax
f01014ec:	0f 94 c0             	sete   %al
f01014ef:	08 c2                	or     %al,%dl
f01014f1:	74 04                	je     f01014f7 <readline+0xaa>
f01014f3:	85 ff                	test   %edi,%edi
f01014f5:	7f bb                	jg     f01014b2 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01014f7:	83 fe 1f             	cmp    $0x1f,%esi
f01014fa:	7e 1c                	jle    f0101518 <readline+0xcb>
f01014fc:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0101502:	7f 14                	jg     f0101518 <readline+0xcb>
			if (echoing)
f0101504:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101508:	74 c2                	je     f01014cc <readline+0x7f>
				cputchar(c);
f010150a:	83 ec 0c             	sub    $0xc,%esp
f010150d:	56                   	push   %esi
f010150e:	e8 51 f2 ff ff       	call   f0100764 <cputchar>
f0101513:	83 c4 10             	add    $0x10,%esp
f0101516:	eb b4                	jmp    f01014cc <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f0101518:	83 fe 0a             	cmp    $0xa,%esi
f010151b:	74 05                	je     f0101522 <readline+0xd5>
f010151d:	83 fe 0d             	cmp    $0xd,%esi
f0101520:	75 b6                	jne    f01014d8 <readline+0x8b>
			if (echoing)
f0101522:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101526:	75 13                	jne    f010153b <readline+0xee>
			buf[i] = 0;
f0101528:	c6 84 3b 98 1f 00 00 	movb   $0x0,0x1f98(%ebx,%edi,1)
f010152f:	00 
			return buf;
f0101530:	8d 83 98 1f 00 00    	lea    0x1f98(%ebx),%eax
f0101536:	e9 6f ff ff ff       	jmp    f01014aa <readline+0x5d>
				cputchar('\n');
f010153b:	83 ec 0c             	sub    $0xc,%esp
f010153e:	6a 0a                	push   $0xa
f0101540:	e8 1f f2 ff ff       	call   f0100764 <cputchar>
f0101545:	83 c4 10             	add    $0x10,%esp
f0101548:	eb de                	jmp    f0101528 <readline+0xdb>

f010154a <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f010154a:	55                   	push   %ebp
f010154b:	89 e5                	mov    %esp,%ebp
f010154d:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101550:	b8 00 00 00 00       	mov    $0x0,%eax
f0101555:	eb 03                	jmp    f010155a <strlen+0x10>
		n++;
f0101557:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f010155a:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f010155e:	75 f7                	jne    f0101557 <strlen+0xd>
	return n;
}
f0101560:	5d                   	pop    %ebp
f0101561:	c3                   	ret    

f0101562 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0101562:	55                   	push   %ebp
f0101563:	89 e5                	mov    %esp,%ebp
f0101565:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101568:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010156b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101570:	eb 03                	jmp    f0101575 <strnlen+0x13>
		n++;
f0101572:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101575:	39 d0                	cmp    %edx,%eax
f0101577:	74 06                	je     f010157f <strnlen+0x1d>
f0101579:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f010157d:	75 f3                	jne    f0101572 <strnlen+0x10>
	return n;
}
f010157f:	5d                   	pop    %ebp
f0101580:	c3                   	ret    

f0101581 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0101581:	55                   	push   %ebp
f0101582:	89 e5                	mov    %esp,%ebp
f0101584:	53                   	push   %ebx
f0101585:	8b 45 08             	mov    0x8(%ebp),%eax
f0101588:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010158b:	89 c2                	mov    %eax,%edx
f010158d:	83 c1 01             	add    $0x1,%ecx
f0101590:	83 c2 01             	add    $0x1,%edx
f0101593:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0101597:	88 5a ff             	mov    %bl,-0x1(%edx)
f010159a:	84 db                	test   %bl,%bl
f010159c:	75 ef                	jne    f010158d <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f010159e:	5b                   	pop    %ebx
f010159f:	5d                   	pop    %ebp
f01015a0:	c3                   	ret    

f01015a1 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01015a1:	55                   	push   %ebp
f01015a2:	89 e5                	mov    %esp,%ebp
f01015a4:	53                   	push   %ebx
f01015a5:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01015a8:	53                   	push   %ebx
f01015a9:	e8 9c ff ff ff       	call   f010154a <strlen>
f01015ae:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f01015b1:	ff 75 0c             	pushl  0xc(%ebp)
f01015b4:	01 d8                	add    %ebx,%eax
f01015b6:	50                   	push   %eax
f01015b7:	e8 c5 ff ff ff       	call   f0101581 <strcpy>
	return dst;
}
f01015bc:	89 d8                	mov    %ebx,%eax
f01015be:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01015c1:	c9                   	leave  
f01015c2:	c3                   	ret    

f01015c3 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01015c3:	55                   	push   %ebp
f01015c4:	89 e5                	mov    %esp,%ebp
f01015c6:	56                   	push   %esi
f01015c7:	53                   	push   %ebx
f01015c8:	8b 75 08             	mov    0x8(%ebp),%esi
f01015cb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01015ce:	89 f3                	mov    %esi,%ebx
f01015d0:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01015d3:	89 f2                	mov    %esi,%edx
f01015d5:	eb 0f                	jmp    f01015e6 <strncpy+0x23>
		*dst++ = *src;
f01015d7:	83 c2 01             	add    $0x1,%edx
f01015da:	0f b6 01             	movzbl (%ecx),%eax
f01015dd:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01015e0:	80 39 01             	cmpb   $0x1,(%ecx)
f01015e3:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f01015e6:	39 da                	cmp    %ebx,%edx
f01015e8:	75 ed                	jne    f01015d7 <strncpy+0x14>
	}
	return ret;
}
f01015ea:	89 f0                	mov    %esi,%eax
f01015ec:	5b                   	pop    %ebx
f01015ed:	5e                   	pop    %esi
f01015ee:	5d                   	pop    %ebp
f01015ef:	c3                   	ret    

f01015f0 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01015f0:	55                   	push   %ebp
f01015f1:	89 e5                	mov    %esp,%ebp
f01015f3:	56                   	push   %esi
f01015f4:	53                   	push   %ebx
f01015f5:	8b 75 08             	mov    0x8(%ebp),%esi
f01015f8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01015fb:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01015fe:	89 f0                	mov    %esi,%eax
f0101600:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101604:	85 c9                	test   %ecx,%ecx
f0101606:	75 0b                	jne    f0101613 <strlcpy+0x23>
f0101608:	eb 17                	jmp    f0101621 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010160a:	83 c2 01             	add    $0x1,%edx
f010160d:	83 c0 01             	add    $0x1,%eax
f0101610:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0101613:	39 d8                	cmp    %ebx,%eax
f0101615:	74 07                	je     f010161e <strlcpy+0x2e>
f0101617:	0f b6 0a             	movzbl (%edx),%ecx
f010161a:	84 c9                	test   %cl,%cl
f010161c:	75 ec                	jne    f010160a <strlcpy+0x1a>
		*dst = '\0';
f010161e:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101621:	29 f0                	sub    %esi,%eax
}
f0101623:	5b                   	pop    %ebx
f0101624:	5e                   	pop    %esi
f0101625:	5d                   	pop    %ebp
f0101626:	c3                   	ret    

f0101627 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0101627:	55                   	push   %ebp
f0101628:	89 e5                	mov    %esp,%ebp
f010162a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010162d:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101630:	eb 06                	jmp    f0101638 <strcmp+0x11>
		p++, q++;
f0101632:	83 c1 01             	add    $0x1,%ecx
f0101635:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f0101638:	0f b6 01             	movzbl (%ecx),%eax
f010163b:	84 c0                	test   %al,%al
f010163d:	74 04                	je     f0101643 <strcmp+0x1c>
f010163f:	3a 02                	cmp    (%edx),%al
f0101641:	74 ef                	je     f0101632 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101643:	0f b6 c0             	movzbl %al,%eax
f0101646:	0f b6 12             	movzbl (%edx),%edx
f0101649:	29 d0                	sub    %edx,%eax
}
f010164b:	5d                   	pop    %ebp
f010164c:	c3                   	ret    

f010164d <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010164d:	55                   	push   %ebp
f010164e:	89 e5                	mov    %esp,%ebp
f0101650:	53                   	push   %ebx
f0101651:	8b 45 08             	mov    0x8(%ebp),%eax
f0101654:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101657:	89 c3                	mov    %eax,%ebx
f0101659:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010165c:	eb 06                	jmp    f0101664 <strncmp+0x17>
		n--, p++, q++;
f010165e:	83 c0 01             	add    $0x1,%eax
f0101661:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0101664:	39 d8                	cmp    %ebx,%eax
f0101666:	74 16                	je     f010167e <strncmp+0x31>
f0101668:	0f b6 08             	movzbl (%eax),%ecx
f010166b:	84 c9                	test   %cl,%cl
f010166d:	74 04                	je     f0101673 <strncmp+0x26>
f010166f:	3a 0a                	cmp    (%edx),%cl
f0101671:	74 eb                	je     f010165e <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0101673:	0f b6 00             	movzbl (%eax),%eax
f0101676:	0f b6 12             	movzbl (%edx),%edx
f0101679:	29 d0                	sub    %edx,%eax
}
f010167b:	5b                   	pop    %ebx
f010167c:	5d                   	pop    %ebp
f010167d:	c3                   	ret    
		return 0;
f010167e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101683:	eb f6                	jmp    f010167b <strncmp+0x2e>

f0101685 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101685:	55                   	push   %ebp
f0101686:	89 e5                	mov    %esp,%ebp
f0101688:	8b 45 08             	mov    0x8(%ebp),%eax
f010168b:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010168f:	0f b6 10             	movzbl (%eax),%edx
f0101692:	84 d2                	test   %dl,%dl
f0101694:	74 09                	je     f010169f <strchr+0x1a>
		if (*s == c)
f0101696:	38 ca                	cmp    %cl,%dl
f0101698:	74 0a                	je     f01016a4 <strchr+0x1f>
	for (; *s; s++)
f010169a:	83 c0 01             	add    $0x1,%eax
f010169d:	eb f0                	jmp    f010168f <strchr+0xa>
			return (char *) s;
	return 0;
f010169f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01016a4:	5d                   	pop    %ebp
f01016a5:	c3                   	ret    

f01016a6 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01016a6:	55                   	push   %ebp
f01016a7:	89 e5                	mov    %esp,%ebp
f01016a9:	8b 45 08             	mov    0x8(%ebp),%eax
f01016ac:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01016b0:	eb 03                	jmp    f01016b5 <strfind+0xf>
f01016b2:	83 c0 01             	add    $0x1,%eax
f01016b5:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f01016b8:	38 ca                	cmp    %cl,%dl
f01016ba:	74 04                	je     f01016c0 <strfind+0x1a>
f01016bc:	84 d2                	test   %dl,%dl
f01016be:	75 f2                	jne    f01016b2 <strfind+0xc>
			break;
	return (char *) s;
}
f01016c0:	5d                   	pop    %ebp
f01016c1:	c3                   	ret    

f01016c2 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01016c2:	55                   	push   %ebp
f01016c3:	89 e5                	mov    %esp,%ebp
f01016c5:	57                   	push   %edi
f01016c6:	56                   	push   %esi
f01016c7:	53                   	push   %ebx
f01016c8:	8b 7d 08             	mov    0x8(%ebp),%edi
f01016cb:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01016ce:	85 c9                	test   %ecx,%ecx
f01016d0:	74 13                	je     f01016e5 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01016d2:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01016d8:	75 05                	jne    f01016df <memset+0x1d>
f01016da:	f6 c1 03             	test   $0x3,%cl
f01016dd:	74 0d                	je     f01016ec <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01016df:	8b 45 0c             	mov    0xc(%ebp),%eax
f01016e2:	fc                   	cld    
f01016e3:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01016e5:	89 f8                	mov    %edi,%eax
f01016e7:	5b                   	pop    %ebx
f01016e8:	5e                   	pop    %esi
f01016e9:	5f                   	pop    %edi
f01016ea:	5d                   	pop    %ebp
f01016eb:	c3                   	ret    
		c &= 0xFF;
f01016ec:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01016f0:	89 d3                	mov    %edx,%ebx
f01016f2:	c1 e3 08             	shl    $0x8,%ebx
f01016f5:	89 d0                	mov    %edx,%eax
f01016f7:	c1 e0 18             	shl    $0x18,%eax
f01016fa:	89 d6                	mov    %edx,%esi
f01016fc:	c1 e6 10             	shl    $0x10,%esi
f01016ff:	09 f0                	or     %esi,%eax
f0101701:	09 c2                	or     %eax,%edx
f0101703:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0101705:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f0101708:	89 d0                	mov    %edx,%eax
f010170a:	fc                   	cld    
f010170b:	f3 ab                	rep stos %eax,%es:(%edi)
f010170d:	eb d6                	jmp    f01016e5 <memset+0x23>

f010170f <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010170f:	55                   	push   %ebp
f0101710:	89 e5                	mov    %esp,%ebp
f0101712:	57                   	push   %edi
f0101713:	56                   	push   %esi
f0101714:	8b 45 08             	mov    0x8(%ebp),%eax
f0101717:	8b 75 0c             	mov    0xc(%ebp),%esi
f010171a:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010171d:	39 c6                	cmp    %eax,%esi
f010171f:	73 35                	jae    f0101756 <memmove+0x47>
f0101721:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101724:	39 c2                	cmp    %eax,%edx
f0101726:	76 2e                	jbe    f0101756 <memmove+0x47>
		s += n;
		d += n;
f0101728:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010172b:	89 d6                	mov    %edx,%esi
f010172d:	09 fe                	or     %edi,%esi
f010172f:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101735:	74 0c                	je     f0101743 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101737:	83 ef 01             	sub    $0x1,%edi
f010173a:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f010173d:	fd                   	std    
f010173e:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101740:	fc                   	cld    
f0101741:	eb 21                	jmp    f0101764 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101743:	f6 c1 03             	test   $0x3,%cl
f0101746:	75 ef                	jne    f0101737 <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101748:	83 ef 04             	sub    $0x4,%edi
f010174b:	8d 72 fc             	lea    -0x4(%edx),%esi
f010174e:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0101751:	fd                   	std    
f0101752:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101754:	eb ea                	jmp    f0101740 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101756:	89 f2                	mov    %esi,%edx
f0101758:	09 c2                	or     %eax,%edx
f010175a:	f6 c2 03             	test   $0x3,%dl
f010175d:	74 09                	je     f0101768 <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010175f:	89 c7                	mov    %eax,%edi
f0101761:	fc                   	cld    
f0101762:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101764:	5e                   	pop    %esi
f0101765:	5f                   	pop    %edi
f0101766:	5d                   	pop    %ebp
f0101767:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101768:	f6 c1 03             	test   $0x3,%cl
f010176b:	75 f2                	jne    f010175f <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010176d:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0101770:	89 c7                	mov    %eax,%edi
f0101772:	fc                   	cld    
f0101773:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101775:	eb ed                	jmp    f0101764 <memmove+0x55>

f0101777 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101777:	55                   	push   %ebp
f0101778:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010177a:	ff 75 10             	pushl  0x10(%ebp)
f010177d:	ff 75 0c             	pushl  0xc(%ebp)
f0101780:	ff 75 08             	pushl  0x8(%ebp)
f0101783:	e8 87 ff ff ff       	call   f010170f <memmove>
}
f0101788:	c9                   	leave  
f0101789:	c3                   	ret    

f010178a <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010178a:	55                   	push   %ebp
f010178b:	89 e5                	mov    %esp,%ebp
f010178d:	56                   	push   %esi
f010178e:	53                   	push   %ebx
f010178f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101792:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101795:	89 c6                	mov    %eax,%esi
f0101797:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010179a:	39 f0                	cmp    %esi,%eax
f010179c:	74 1c                	je     f01017ba <memcmp+0x30>
		if (*s1 != *s2)
f010179e:	0f b6 08             	movzbl (%eax),%ecx
f01017a1:	0f b6 1a             	movzbl (%edx),%ebx
f01017a4:	38 d9                	cmp    %bl,%cl
f01017a6:	75 08                	jne    f01017b0 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f01017a8:	83 c0 01             	add    $0x1,%eax
f01017ab:	83 c2 01             	add    $0x1,%edx
f01017ae:	eb ea                	jmp    f010179a <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f01017b0:	0f b6 c1             	movzbl %cl,%eax
f01017b3:	0f b6 db             	movzbl %bl,%ebx
f01017b6:	29 d8                	sub    %ebx,%eax
f01017b8:	eb 05                	jmp    f01017bf <memcmp+0x35>
	}

	return 0;
f01017ba:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01017bf:	5b                   	pop    %ebx
f01017c0:	5e                   	pop    %esi
f01017c1:	5d                   	pop    %ebp
f01017c2:	c3                   	ret    

f01017c3 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01017c3:	55                   	push   %ebp
f01017c4:	89 e5                	mov    %esp,%ebp
f01017c6:	8b 45 08             	mov    0x8(%ebp),%eax
f01017c9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01017cc:	89 c2                	mov    %eax,%edx
f01017ce:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01017d1:	39 d0                	cmp    %edx,%eax
f01017d3:	73 09                	jae    f01017de <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f01017d5:	38 08                	cmp    %cl,(%eax)
f01017d7:	74 05                	je     f01017de <memfind+0x1b>
	for (; s < ends; s++)
f01017d9:	83 c0 01             	add    $0x1,%eax
f01017dc:	eb f3                	jmp    f01017d1 <memfind+0xe>
			break;
	return (void *) s;
}
f01017de:	5d                   	pop    %ebp
f01017df:	c3                   	ret    

f01017e0 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01017e0:	55                   	push   %ebp
f01017e1:	89 e5                	mov    %esp,%ebp
f01017e3:	57                   	push   %edi
f01017e4:	56                   	push   %esi
f01017e5:	53                   	push   %ebx
f01017e6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01017e9:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01017ec:	eb 03                	jmp    f01017f1 <strtol+0x11>
		s++;
f01017ee:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f01017f1:	0f b6 01             	movzbl (%ecx),%eax
f01017f4:	3c 20                	cmp    $0x20,%al
f01017f6:	74 f6                	je     f01017ee <strtol+0xe>
f01017f8:	3c 09                	cmp    $0x9,%al
f01017fa:	74 f2                	je     f01017ee <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f01017fc:	3c 2b                	cmp    $0x2b,%al
f01017fe:	74 2e                	je     f010182e <strtol+0x4e>
	int neg = 0;
f0101800:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0101805:	3c 2d                	cmp    $0x2d,%al
f0101807:	74 2f                	je     f0101838 <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101809:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f010180f:	75 05                	jne    f0101816 <strtol+0x36>
f0101811:	80 39 30             	cmpb   $0x30,(%ecx)
f0101814:	74 2c                	je     f0101842 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101816:	85 db                	test   %ebx,%ebx
f0101818:	75 0a                	jne    f0101824 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010181a:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f010181f:	80 39 30             	cmpb   $0x30,(%ecx)
f0101822:	74 28                	je     f010184c <strtol+0x6c>
		base = 10;
f0101824:	b8 00 00 00 00       	mov    $0x0,%eax
f0101829:	89 5d 10             	mov    %ebx,0x10(%ebp)
f010182c:	eb 50                	jmp    f010187e <strtol+0x9e>
		s++;
f010182e:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0101831:	bf 00 00 00 00       	mov    $0x0,%edi
f0101836:	eb d1                	jmp    f0101809 <strtol+0x29>
		s++, neg = 1;
f0101838:	83 c1 01             	add    $0x1,%ecx
f010183b:	bf 01 00 00 00       	mov    $0x1,%edi
f0101840:	eb c7                	jmp    f0101809 <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101842:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0101846:	74 0e                	je     f0101856 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0101848:	85 db                	test   %ebx,%ebx
f010184a:	75 d8                	jne    f0101824 <strtol+0x44>
		s++, base = 8;
f010184c:	83 c1 01             	add    $0x1,%ecx
f010184f:	bb 08 00 00 00       	mov    $0x8,%ebx
f0101854:	eb ce                	jmp    f0101824 <strtol+0x44>
		s += 2, base = 16;
f0101856:	83 c1 02             	add    $0x2,%ecx
f0101859:	bb 10 00 00 00       	mov    $0x10,%ebx
f010185e:	eb c4                	jmp    f0101824 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0101860:	8d 72 9f             	lea    -0x61(%edx),%esi
f0101863:	89 f3                	mov    %esi,%ebx
f0101865:	80 fb 19             	cmp    $0x19,%bl
f0101868:	77 29                	ja     f0101893 <strtol+0xb3>
			dig = *s - 'a' + 10;
f010186a:	0f be d2             	movsbl %dl,%edx
f010186d:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101870:	3b 55 10             	cmp    0x10(%ebp),%edx
f0101873:	7d 30                	jge    f01018a5 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0101875:	83 c1 01             	add    $0x1,%ecx
f0101878:	0f af 45 10          	imul   0x10(%ebp),%eax
f010187c:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f010187e:	0f b6 11             	movzbl (%ecx),%edx
f0101881:	8d 72 d0             	lea    -0x30(%edx),%esi
f0101884:	89 f3                	mov    %esi,%ebx
f0101886:	80 fb 09             	cmp    $0x9,%bl
f0101889:	77 d5                	ja     f0101860 <strtol+0x80>
			dig = *s - '0';
f010188b:	0f be d2             	movsbl %dl,%edx
f010188e:	83 ea 30             	sub    $0x30,%edx
f0101891:	eb dd                	jmp    f0101870 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0101893:	8d 72 bf             	lea    -0x41(%edx),%esi
f0101896:	89 f3                	mov    %esi,%ebx
f0101898:	80 fb 19             	cmp    $0x19,%bl
f010189b:	77 08                	ja     f01018a5 <strtol+0xc5>
			dig = *s - 'A' + 10;
f010189d:	0f be d2             	movsbl %dl,%edx
f01018a0:	83 ea 37             	sub    $0x37,%edx
f01018a3:	eb cb                	jmp    f0101870 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f01018a5:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01018a9:	74 05                	je     f01018b0 <strtol+0xd0>
		*endptr = (char *) s;
f01018ab:	8b 75 0c             	mov    0xc(%ebp),%esi
f01018ae:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f01018b0:	89 c2                	mov    %eax,%edx
f01018b2:	f7 da                	neg    %edx
f01018b4:	85 ff                	test   %edi,%edi
f01018b6:	0f 45 c2             	cmovne %edx,%eax
}
f01018b9:	5b                   	pop    %ebx
f01018ba:	5e                   	pop    %esi
f01018bb:	5f                   	pop    %edi
f01018bc:	5d                   	pop    %ebp
f01018bd:	c3                   	ret    
f01018be:	66 90                	xchg   %ax,%ax

f01018c0 <__udivdi3>:
f01018c0:	55                   	push   %ebp
f01018c1:	57                   	push   %edi
f01018c2:	56                   	push   %esi
f01018c3:	53                   	push   %ebx
f01018c4:	83 ec 1c             	sub    $0x1c,%esp
f01018c7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01018cb:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f01018cf:	8b 74 24 34          	mov    0x34(%esp),%esi
f01018d3:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f01018d7:	85 d2                	test   %edx,%edx
f01018d9:	75 35                	jne    f0101910 <__udivdi3+0x50>
f01018db:	39 f3                	cmp    %esi,%ebx
f01018dd:	0f 87 bd 00 00 00    	ja     f01019a0 <__udivdi3+0xe0>
f01018e3:	85 db                	test   %ebx,%ebx
f01018e5:	89 d9                	mov    %ebx,%ecx
f01018e7:	75 0b                	jne    f01018f4 <__udivdi3+0x34>
f01018e9:	b8 01 00 00 00       	mov    $0x1,%eax
f01018ee:	31 d2                	xor    %edx,%edx
f01018f0:	f7 f3                	div    %ebx
f01018f2:	89 c1                	mov    %eax,%ecx
f01018f4:	31 d2                	xor    %edx,%edx
f01018f6:	89 f0                	mov    %esi,%eax
f01018f8:	f7 f1                	div    %ecx
f01018fa:	89 c6                	mov    %eax,%esi
f01018fc:	89 e8                	mov    %ebp,%eax
f01018fe:	89 f7                	mov    %esi,%edi
f0101900:	f7 f1                	div    %ecx
f0101902:	89 fa                	mov    %edi,%edx
f0101904:	83 c4 1c             	add    $0x1c,%esp
f0101907:	5b                   	pop    %ebx
f0101908:	5e                   	pop    %esi
f0101909:	5f                   	pop    %edi
f010190a:	5d                   	pop    %ebp
f010190b:	c3                   	ret    
f010190c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101910:	39 f2                	cmp    %esi,%edx
f0101912:	77 7c                	ja     f0101990 <__udivdi3+0xd0>
f0101914:	0f bd fa             	bsr    %edx,%edi
f0101917:	83 f7 1f             	xor    $0x1f,%edi
f010191a:	0f 84 98 00 00 00    	je     f01019b8 <__udivdi3+0xf8>
f0101920:	89 f9                	mov    %edi,%ecx
f0101922:	b8 20 00 00 00       	mov    $0x20,%eax
f0101927:	29 f8                	sub    %edi,%eax
f0101929:	d3 e2                	shl    %cl,%edx
f010192b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010192f:	89 c1                	mov    %eax,%ecx
f0101931:	89 da                	mov    %ebx,%edx
f0101933:	d3 ea                	shr    %cl,%edx
f0101935:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0101939:	09 d1                	or     %edx,%ecx
f010193b:	89 f2                	mov    %esi,%edx
f010193d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0101941:	89 f9                	mov    %edi,%ecx
f0101943:	d3 e3                	shl    %cl,%ebx
f0101945:	89 c1                	mov    %eax,%ecx
f0101947:	d3 ea                	shr    %cl,%edx
f0101949:	89 f9                	mov    %edi,%ecx
f010194b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010194f:	d3 e6                	shl    %cl,%esi
f0101951:	89 eb                	mov    %ebp,%ebx
f0101953:	89 c1                	mov    %eax,%ecx
f0101955:	d3 eb                	shr    %cl,%ebx
f0101957:	09 de                	or     %ebx,%esi
f0101959:	89 f0                	mov    %esi,%eax
f010195b:	f7 74 24 08          	divl   0x8(%esp)
f010195f:	89 d6                	mov    %edx,%esi
f0101961:	89 c3                	mov    %eax,%ebx
f0101963:	f7 64 24 0c          	mull   0xc(%esp)
f0101967:	39 d6                	cmp    %edx,%esi
f0101969:	72 0c                	jb     f0101977 <__udivdi3+0xb7>
f010196b:	89 f9                	mov    %edi,%ecx
f010196d:	d3 e5                	shl    %cl,%ebp
f010196f:	39 c5                	cmp    %eax,%ebp
f0101971:	73 5d                	jae    f01019d0 <__udivdi3+0x110>
f0101973:	39 d6                	cmp    %edx,%esi
f0101975:	75 59                	jne    f01019d0 <__udivdi3+0x110>
f0101977:	8d 43 ff             	lea    -0x1(%ebx),%eax
f010197a:	31 ff                	xor    %edi,%edi
f010197c:	89 fa                	mov    %edi,%edx
f010197e:	83 c4 1c             	add    $0x1c,%esp
f0101981:	5b                   	pop    %ebx
f0101982:	5e                   	pop    %esi
f0101983:	5f                   	pop    %edi
f0101984:	5d                   	pop    %ebp
f0101985:	c3                   	ret    
f0101986:	8d 76 00             	lea    0x0(%esi),%esi
f0101989:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0101990:	31 ff                	xor    %edi,%edi
f0101992:	31 c0                	xor    %eax,%eax
f0101994:	89 fa                	mov    %edi,%edx
f0101996:	83 c4 1c             	add    $0x1c,%esp
f0101999:	5b                   	pop    %ebx
f010199a:	5e                   	pop    %esi
f010199b:	5f                   	pop    %edi
f010199c:	5d                   	pop    %ebp
f010199d:	c3                   	ret    
f010199e:	66 90                	xchg   %ax,%ax
f01019a0:	31 ff                	xor    %edi,%edi
f01019a2:	89 e8                	mov    %ebp,%eax
f01019a4:	89 f2                	mov    %esi,%edx
f01019a6:	f7 f3                	div    %ebx
f01019a8:	89 fa                	mov    %edi,%edx
f01019aa:	83 c4 1c             	add    $0x1c,%esp
f01019ad:	5b                   	pop    %ebx
f01019ae:	5e                   	pop    %esi
f01019af:	5f                   	pop    %edi
f01019b0:	5d                   	pop    %ebp
f01019b1:	c3                   	ret    
f01019b2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01019b8:	39 f2                	cmp    %esi,%edx
f01019ba:	72 06                	jb     f01019c2 <__udivdi3+0x102>
f01019bc:	31 c0                	xor    %eax,%eax
f01019be:	39 eb                	cmp    %ebp,%ebx
f01019c0:	77 d2                	ja     f0101994 <__udivdi3+0xd4>
f01019c2:	b8 01 00 00 00       	mov    $0x1,%eax
f01019c7:	eb cb                	jmp    f0101994 <__udivdi3+0xd4>
f01019c9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01019d0:	89 d8                	mov    %ebx,%eax
f01019d2:	31 ff                	xor    %edi,%edi
f01019d4:	eb be                	jmp    f0101994 <__udivdi3+0xd4>
f01019d6:	66 90                	xchg   %ax,%ax
f01019d8:	66 90                	xchg   %ax,%ax
f01019da:	66 90                	xchg   %ax,%ax
f01019dc:	66 90                	xchg   %ax,%ax
f01019de:	66 90                	xchg   %ax,%ax

f01019e0 <__umoddi3>:
f01019e0:	55                   	push   %ebp
f01019e1:	57                   	push   %edi
f01019e2:	56                   	push   %esi
f01019e3:	53                   	push   %ebx
f01019e4:	83 ec 1c             	sub    $0x1c,%esp
f01019e7:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f01019eb:	8b 74 24 30          	mov    0x30(%esp),%esi
f01019ef:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f01019f3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01019f7:	85 ed                	test   %ebp,%ebp
f01019f9:	89 f0                	mov    %esi,%eax
f01019fb:	89 da                	mov    %ebx,%edx
f01019fd:	75 19                	jne    f0101a18 <__umoddi3+0x38>
f01019ff:	39 df                	cmp    %ebx,%edi
f0101a01:	0f 86 b1 00 00 00    	jbe    f0101ab8 <__umoddi3+0xd8>
f0101a07:	f7 f7                	div    %edi
f0101a09:	89 d0                	mov    %edx,%eax
f0101a0b:	31 d2                	xor    %edx,%edx
f0101a0d:	83 c4 1c             	add    $0x1c,%esp
f0101a10:	5b                   	pop    %ebx
f0101a11:	5e                   	pop    %esi
f0101a12:	5f                   	pop    %edi
f0101a13:	5d                   	pop    %ebp
f0101a14:	c3                   	ret    
f0101a15:	8d 76 00             	lea    0x0(%esi),%esi
f0101a18:	39 dd                	cmp    %ebx,%ebp
f0101a1a:	77 f1                	ja     f0101a0d <__umoddi3+0x2d>
f0101a1c:	0f bd cd             	bsr    %ebp,%ecx
f0101a1f:	83 f1 1f             	xor    $0x1f,%ecx
f0101a22:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101a26:	0f 84 b4 00 00 00    	je     f0101ae0 <__umoddi3+0x100>
f0101a2c:	b8 20 00 00 00       	mov    $0x20,%eax
f0101a31:	89 c2                	mov    %eax,%edx
f0101a33:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101a37:	29 c2                	sub    %eax,%edx
f0101a39:	89 c1                	mov    %eax,%ecx
f0101a3b:	89 f8                	mov    %edi,%eax
f0101a3d:	d3 e5                	shl    %cl,%ebp
f0101a3f:	89 d1                	mov    %edx,%ecx
f0101a41:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101a45:	d3 e8                	shr    %cl,%eax
f0101a47:	09 c5                	or     %eax,%ebp
f0101a49:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101a4d:	89 c1                	mov    %eax,%ecx
f0101a4f:	d3 e7                	shl    %cl,%edi
f0101a51:	89 d1                	mov    %edx,%ecx
f0101a53:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0101a57:	89 df                	mov    %ebx,%edi
f0101a59:	d3 ef                	shr    %cl,%edi
f0101a5b:	89 c1                	mov    %eax,%ecx
f0101a5d:	89 f0                	mov    %esi,%eax
f0101a5f:	d3 e3                	shl    %cl,%ebx
f0101a61:	89 d1                	mov    %edx,%ecx
f0101a63:	89 fa                	mov    %edi,%edx
f0101a65:	d3 e8                	shr    %cl,%eax
f0101a67:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101a6c:	09 d8                	or     %ebx,%eax
f0101a6e:	f7 f5                	div    %ebp
f0101a70:	d3 e6                	shl    %cl,%esi
f0101a72:	89 d1                	mov    %edx,%ecx
f0101a74:	f7 64 24 08          	mull   0x8(%esp)
f0101a78:	39 d1                	cmp    %edx,%ecx
f0101a7a:	89 c3                	mov    %eax,%ebx
f0101a7c:	89 d7                	mov    %edx,%edi
f0101a7e:	72 06                	jb     f0101a86 <__umoddi3+0xa6>
f0101a80:	75 0e                	jne    f0101a90 <__umoddi3+0xb0>
f0101a82:	39 c6                	cmp    %eax,%esi
f0101a84:	73 0a                	jae    f0101a90 <__umoddi3+0xb0>
f0101a86:	2b 44 24 08          	sub    0x8(%esp),%eax
f0101a8a:	19 ea                	sbb    %ebp,%edx
f0101a8c:	89 d7                	mov    %edx,%edi
f0101a8e:	89 c3                	mov    %eax,%ebx
f0101a90:	89 ca                	mov    %ecx,%edx
f0101a92:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0101a97:	29 de                	sub    %ebx,%esi
f0101a99:	19 fa                	sbb    %edi,%edx
f0101a9b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f0101a9f:	89 d0                	mov    %edx,%eax
f0101aa1:	d3 e0                	shl    %cl,%eax
f0101aa3:	89 d9                	mov    %ebx,%ecx
f0101aa5:	d3 ee                	shr    %cl,%esi
f0101aa7:	d3 ea                	shr    %cl,%edx
f0101aa9:	09 f0                	or     %esi,%eax
f0101aab:	83 c4 1c             	add    $0x1c,%esp
f0101aae:	5b                   	pop    %ebx
f0101aaf:	5e                   	pop    %esi
f0101ab0:	5f                   	pop    %edi
f0101ab1:	5d                   	pop    %ebp
f0101ab2:	c3                   	ret    
f0101ab3:	90                   	nop
f0101ab4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101ab8:	85 ff                	test   %edi,%edi
f0101aba:	89 f9                	mov    %edi,%ecx
f0101abc:	75 0b                	jne    f0101ac9 <__umoddi3+0xe9>
f0101abe:	b8 01 00 00 00       	mov    $0x1,%eax
f0101ac3:	31 d2                	xor    %edx,%edx
f0101ac5:	f7 f7                	div    %edi
f0101ac7:	89 c1                	mov    %eax,%ecx
f0101ac9:	89 d8                	mov    %ebx,%eax
f0101acb:	31 d2                	xor    %edx,%edx
f0101acd:	f7 f1                	div    %ecx
f0101acf:	89 f0                	mov    %esi,%eax
f0101ad1:	f7 f1                	div    %ecx
f0101ad3:	e9 31 ff ff ff       	jmp    f0101a09 <__umoddi3+0x29>
f0101ad8:	90                   	nop
f0101ad9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101ae0:	39 dd                	cmp    %ebx,%ebp
f0101ae2:	72 08                	jb     f0101aec <__umoddi3+0x10c>
f0101ae4:	39 f7                	cmp    %esi,%edi
f0101ae6:	0f 87 21 ff ff ff    	ja     f0101a0d <__umoddi3+0x2d>
f0101aec:	89 da                	mov    %ebx,%edx
f0101aee:	89 f0                	mov    %esi,%eax
f0101af0:	29 f8                	sub    %edi,%eax
f0101af2:	19 ea                	sbb    %ebp,%edx
f0101af4:	e9 14 ff ff ff       	jmp    f0101a0d <__umoddi3+0x2d>
