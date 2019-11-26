
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
f0100015:	b8 00 e0 18 00       	mov    $0x18e000,%eax
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
f0100034:	bc 00 b0 11 f0       	mov    $0xf011b000,%esp

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
f0100043:	53                   	push   %ebx
f0100044:	83 ec 08             	sub    $0x8,%esp
f0100047:	e8 1b 01 00 00       	call   f0100167 <__x86.get_pc_thunk.bx>
f010004c:	81 c3 d4 cf 08 00    	add    $0x8cfd4,%ebx
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100052:	c7 c0 10 00 19 f0    	mov    $0xf0190010,%eax
f0100058:	c7 c2 00 f1 18 f0    	mov    $0xf018f100,%edx
f010005e:	29 d0                	sub    %edx,%eax
f0100060:	50                   	push   %eax
f0100061:	6a 00                	push   $0x0
f0100063:	52                   	push   %edx
f0100064:	e8 dd 52 00 00       	call   f0105346 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 4e 05 00 00       	call   f01005bc <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 80 87 f7 ff    	lea    -0x87880(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 3c 3c 00 00       	call   f0103cbe <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 ab 14 00 00       	call   f0101532 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100087:	e8 41 35 00 00       	call   f01035cd <env_init>
	trap_init();
f010008c:	e8 e0 3c 00 00       	call   f0103d71 <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100091:	83 c4 08             	add    $0x8,%esp
f0100094:	6a 00                	push   $0x0
f0100096:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f010009c:	e8 27 37 00 00       	call   f01037c8 <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000a1:	83 c4 04             	add    $0x4,%esp
f01000a4:	c7 c0 4c f3 18 f0    	mov    $0xf018f34c,%eax
f01000aa:	ff 30                	pushl  (%eax)
f01000ac:	e8 0d 3b 00 00       	call   f0103bbe <env_run>

f01000b1 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000b1:	55                   	push   %ebp
f01000b2:	89 e5                	mov    %esp,%ebp
f01000b4:	57                   	push   %edi
f01000b5:	56                   	push   %esi
f01000b6:	53                   	push   %ebx
f01000b7:	83 ec 0c             	sub    $0xc,%esp
f01000ba:	e8 a8 00 00 00       	call   f0100167 <__x86.get_pc_thunk.bx>
f01000bf:	81 c3 61 cf 08 00    	add    $0x8cf61,%ebx
f01000c5:	8b 7d 10             	mov    0x10(%ebp),%edi
	va_list ap;

	if (panicstr)
f01000c8:	c7 c0 00 00 19 f0    	mov    $0xf0190000,%eax
f01000ce:	83 38 00             	cmpl   $0x0,(%eax)
f01000d1:	74 0f                	je     f01000e2 <_panic+0x31>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 71 08 00 00       	call   f010094e <monitor>
f01000dd:	83 c4 10             	add    $0x10,%esp
f01000e0:	eb f1                	jmp    f01000d3 <_panic+0x22>
	panicstr = fmt;
f01000e2:	89 38                	mov    %edi,(%eax)
	asm volatile("cli; cld");
f01000e4:	fa                   	cli    
f01000e5:	fc                   	cld    
	va_start(ap, fmt);
f01000e6:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel panic at %s:%d: ", file, line);
f01000e9:	83 ec 04             	sub    $0x4,%esp
f01000ec:	ff 75 0c             	pushl  0xc(%ebp)
f01000ef:	ff 75 08             	pushl  0x8(%ebp)
f01000f2:	8d 83 9b 87 f7 ff    	lea    -0x87865(%ebx),%eax
f01000f8:	50                   	push   %eax
f01000f9:	e8 c0 3b 00 00       	call   f0103cbe <cprintf>
	vcprintf(fmt, ap);
f01000fe:	83 c4 08             	add    $0x8,%esp
f0100101:	56                   	push   %esi
f0100102:	57                   	push   %edi
f0100103:	e8 7f 3b 00 00       	call   f0103c87 <vcprintf>
	cprintf("\n");
f0100108:	8d 83 61 8f f7 ff    	lea    -0x8709f(%ebx),%eax
f010010e:	89 04 24             	mov    %eax,(%esp)
f0100111:	e8 a8 3b 00 00       	call   f0103cbe <cprintf>
f0100116:	83 c4 10             	add    $0x10,%esp
f0100119:	eb b8                	jmp    f01000d3 <_panic+0x22>

f010011b <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010011b:	55                   	push   %ebp
f010011c:	89 e5                	mov    %esp,%ebp
f010011e:	56                   	push   %esi
f010011f:	53                   	push   %ebx
f0100120:	e8 42 00 00 00       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100125:	81 c3 fb ce 08 00    	add    $0x8cefb,%ebx
	va_list ap;

	va_start(ap, fmt);
f010012b:	8d 75 14             	lea    0x14(%ebp),%esi
	cprintf("kernel warning at %s:%d: ", file, line);
f010012e:	83 ec 04             	sub    $0x4,%esp
f0100131:	ff 75 0c             	pushl  0xc(%ebp)
f0100134:	ff 75 08             	pushl  0x8(%ebp)
f0100137:	8d 83 b3 87 f7 ff    	lea    -0x8784d(%ebx),%eax
f010013d:	50                   	push   %eax
f010013e:	e8 7b 3b 00 00       	call   f0103cbe <cprintf>
	vcprintf(fmt, ap);
f0100143:	83 c4 08             	add    $0x8,%esp
f0100146:	56                   	push   %esi
f0100147:	ff 75 10             	pushl  0x10(%ebp)
f010014a:	e8 38 3b 00 00       	call   f0103c87 <vcprintf>
	cprintf("\n");
f010014f:	8d 83 61 8f f7 ff    	lea    -0x8709f(%ebx),%eax
f0100155:	89 04 24             	mov    %eax,(%esp)
f0100158:	e8 61 3b 00 00       	call   f0103cbe <cprintf>
	va_end(ap);
}
f010015d:	83 c4 10             	add    $0x10,%esp
f0100160:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100163:	5b                   	pop    %ebx
f0100164:	5e                   	pop    %esi
f0100165:	5d                   	pop    %ebp
f0100166:	c3                   	ret    

f0100167 <__x86.get_pc_thunk.bx>:
f0100167:	8b 1c 24             	mov    (%esp),%ebx
f010016a:	c3                   	ret    

f010016b <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010016b:	55                   	push   %ebp
f010016c:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010016e:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100173:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100174:	a8 01                	test   $0x1,%al
f0100176:	74 0b                	je     f0100183 <serial_proc_data+0x18>
f0100178:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010017d:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f010017e:	0f b6 c0             	movzbl %al,%eax
}
f0100181:	5d                   	pop    %ebp
f0100182:	c3                   	ret    
		return -1;
f0100183:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100188:	eb f7                	jmp    f0100181 <serial_proc_data+0x16>

f010018a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010018a:	55                   	push   %ebp
f010018b:	89 e5                	mov    %esp,%ebp
f010018d:	56                   	push   %esi
f010018e:	53                   	push   %ebx
f010018f:	e8 d3 ff ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100194:	81 c3 8c ce 08 00    	add    $0x8ce8c,%ebx
f010019a:	89 c6                	mov    %eax,%esi
	int c;

	while ((c = (*proc)()) != -1) {
f010019c:	ff d6                	call   *%esi
f010019e:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001a1:	74 2e                	je     f01001d1 <cons_intr+0x47>
		if (c == 0)
f01001a3:	85 c0                	test   %eax,%eax
f01001a5:	74 f5                	je     f010019c <cons_intr+0x12>
			continue;
		cons.buf[cons.wpos++] = c;
f01001a7:	8b 8b 04 23 00 00    	mov    0x2304(%ebx),%ecx
f01001ad:	8d 51 01             	lea    0x1(%ecx),%edx
f01001b0:	89 93 04 23 00 00    	mov    %edx,0x2304(%ebx)
f01001b6:	88 84 0b 00 21 00 00 	mov    %al,0x2100(%ebx,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f01001bd:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001c3:	75 d7                	jne    f010019c <cons_intr+0x12>
			cons.wpos = 0;
f01001c5:	c7 83 04 23 00 00 00 	movl   $0x0,0x2304(%ebx)
f01001cc:	00 00 00 
f01001cf:	eb cb                	jmp    f010019c <cons_intr+0x12>
	}
}
f01001d1:	5b                   	pop    %ebx
f01001d2:	5e                   	pop    %esi
f01001d3:	5d                   	pop    %ebp
f01001d4:	c3                   	ret    

f01001d5 <kbd_proc_data>:
{
f01001d5:	55                   	push   %ebp
f01001d6:	89 e5                	mov    %esp,%ebp
f01001d8:	56                   	push   %esi
f01001d9:	53                   	push   %ebx
f01001da:	e8 88 ff ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01001df:	81 c3 41 ce 08 00    	add    $0x8ce41,%ebx
f01001e5:	ba 64 00 00 00       	mov    $0x64,%edx
f01001ea:	ec                   	in     (%dx),%al
	if ((stat & KBS_DIB) == 0)
f01001eb:	a8 01                	test   $0x1,%al
f01001ed:	0f 84 06 01 00 00    	je     f01002f9 <kbd_proc_data+0x124>
	if (stat & KBS_TERR)
f01001f3:	a8 20                	test   $0x20,%al
f01001f5:	0f 85 05 01 00 00    	jne    f0100300 <kbd_proc_data+0x12b>
f01001fb:	ba 60 00 00 00       	mov    $0x60,%edx
f0100200:	ec                   	in     (%dx),%al
f0100201:	89 c2                	mov    %eax,%edx
	if (data == 0xE0) {
f0100203:	3c e0                	cmp    $0xe0,%al
f0100205:	0f 84 93 00 00 00    	je     f010029e <kbd_proc_data+0xc9>
	} else if (data & 0x80) {
f010020b:	84 c0                	test   %al,%al
f010020d:	0f 88 a0 00 00 00    	js     f01002b3 <kbd_proc_data+0xde>
	} else if (shift & E0ESC) {
f0100213:	8b 8b e0 20 00 00    	mov    0x20e0(%ebx),%ecx
f0100219:	f6 c1 40             	test   $0x40,%cl
f010021c:	74 0e                	je     f010022c <kbd_proc_data+0x57>
		data |= 0x80;
f010021e:	83 c8 80             	or     $0xffffff80,%eax
f0100221:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100223:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100226:	89 8b e0 20 00 00    	mov    %ecx,0x20e0(%ebx)
	shift |= shiftcode[data];
f010022c:	0f b6 d2             	movzbl %dl,%edx
f010022f:	0f b6 84 13 00 89 f7 	movzbl -0x87700(%ebx,%edx,1),%eax
f0100236:	ff 
f0100237:	0b 83 e0 20 00 00    	or     0x20e0(%ebx),%eax
	shift ^= togglecode[data];
f010023d:	0f b6 8c 13 00 88 f7 	movzbl -0x87800(%ebx,%edx,1),%ecx
f0100244:	ff 
f0100245:	31 c8                	xor    %ecx,%eax
f0100247:	89 83 e0 20 00 00    	mov    %eax,0x20e0(%ebx)
	c = charcode[shift & (CTL | SHIFT)][data];
f010024d:	89 c1                	mov    %eax,%ecx
f010024f:	83 e1 03             	and    $0x3,%ecx
f0100252:	8b 8c 8b 00 20 00 00 	mov    0x2000(%ebx,%ecx,4),%ecx
f0100259:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f010025d:	0f b6 f2             	movzbl %dl,%esi
	if (shift & CAPSLOCK) {
f0100260:	a8 08                	test   $0x8,%al
f0100262:	74 0d                	je     f0100271 <kbd_proc_data+0x9c>
		if ('a' <= c && c <= 'z')
f0100264:	89 f2                	mov    %esi,%edx
f0100266:	8d 4e 9f             	lea    -0x61(%esi),%ecx
f0100269:	83 f9 19             	cmp    $0x19,%ecx
f010026c:	77 7a                	ja     f01002e8 <kbd_proc_data+0x113>
			c += 'A' - 'a';
f010026e:	83 ee 20             	sub    $0x20,%esi
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100271:	f7 d0                	not    %eax
f0100273:	a8 06                	test   $0x6,%al
f0100275:	75 33                	jne    f01002aa <kbd_proc_data+0xd5>
f0100277:	81 fe e9 00 00 00    	cmp    $0xe9,%esi
f010027d:	75 2b                	jne    f01002aa <kbd_proc_data+0xd5>
		cprintf("Rebooting!\n");
f010027f:	83 ec 0c             	sub    $0xc,%esp
f0100282:	8d 83 cd 87 f7 ff    	lea    -0x87833(%ebx),%eax
f0100288:	50                   	push   %eax
f0100289:	e8 30 3a 00 00       	call   f0103cbe <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010028e:	b8 03 00 00 00       	mov    $0x3,%eax
f0100293:	ba 92 00 00 00       	mov    $0x92,%edx
f0100298:	ee                   	out    %al,(%dx)
f0100299:	83 c4 10             	add    $0x10,%esp
f010029c:	eb 0c                	jmp    f01002aa <kbd_proc_data+0xd5>
		shift |= E0ESC;
f010029e:	83 8b e0 20 00 00 40 	orl    $0x40,0x20e0(%ebx)
		return 0;
f01002a5:	be 00 00 00 00       	mov    $0x0,%esi
}
f01002aa:	89 f0                	mov    %esi,%eax
f01002ac:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01002af:	5b                   	pop    %ebx
f01002b0:	5e                   	pop    %esi
f01002b1:	5d                   	pop    %ebp
f01002b2:	c3                   	ret    
		data = (shift & E0ESC ? data : data & 0x7F);
f01002b3:	8b 8b e0 20 00 00    	mov    0x20e0(%ebx),%ecx
f01002b9:	89 ce                	mov    %ecx,%esi
f01002bb:	83 e6 40             	and    $0x40,%esi
f01002be:	83 e0 7f             	and    $0x7f,%eax
f01002c1:	85 f6                	test   %esi,%esi
f01002c3:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01002c6:	0f b6 d2             	movzbl %dl,%edx
f01002c9:	0f b6 84 13 00 89 f7 	movzbl -0x87700(%ebx,%edx,1),%eax
f01002d0:	ff 
f01002d1:	83 c8 40             	or     $0x40,%eax
f01002d4:	0f b6 c0             	movzbl %al,%eax
f01002d7:	f7 d0                	not    %eax
f01002d9:	21 c8                	and    %ecx,%eax
f01002db:	89 83 e0 20 00 00    	mov    %eax,0x20e0(%ebx)
		return 0;
f01002e1:	be 00 00 00 00       	mov    $0x0,%esi
f01002e6:	eb c2                	jmp    f01002aa <kbd_proc_data+0xd5>
		else if ('A' <= c && c <= 'Z')
f01002e8:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01002eb:	8d 4e 20             	lea    0x20(%esi),%ecx
f01002ee:	83 fa 1a             	cmp    $0x1a,%edx
f01002f1:	0f 42 f1             	cmovb  %ecx,%esi
f01002f4:	e9 78 ff ff ff       	jmp    f0100271 <kbd_proc_data+0x9c>
		return -1;
f01002f9:	be ff ff ff ff       	mov    $0xffffffff,%esi
f01002fe:	eb aa                	jmp    f01002aa <kbd_proc_data+0xd5>
		return -1;
f0100300:	be ff ff ff ff       	mov    $0xffffffff,%esi
f0100305:	eb a3                	jmp    f01002aa <kbd_proc_data+0xd5>

f0100307 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100307:	55                   	push   %ebp
f0100308:	89 e5                	mov    %esp,%ebp
f010030a:	57                   	push   %edi
f010030b:	56                   	push   %esi
f010030c:	53                   	push   %ebx
f010030d:	83 ec 1c             	sub    $0x1c,%esp
f0100310:	e8 52 fe ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100315:	81 c3 0b cd 08 00    	add    $0x8cd0b,%ebx
f010031b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for (i = 0;
f010031e:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100323:	bf fd 03 00 00       	mov    $0x3fd,%edi
f0100328:	b9 84 00 00 00       	mov    $0x84,%ecx
f010032d:	eb 09                	jmp    f0100338 <cons_putc+0x31>
f010032f:	89 ca                	mov    %ecx,%edx
f0100331:	ec                   	in     (%dx),%al
f0100332:	ec                   	in     (%dx),%al
f0100333:	ec                   	in     (%dx),%al
f0100334:	ec                   	in     (%dx),%al
	     i++)
f0100335:	83 c6 01             	add    $0x1,%esi
f0100338:	89 fa                	mov    %edi,%edx
f010033a:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f010033b:	a8 20                	test   $0x20,%al
f010033d:	75 08                	jne    f0100347 <cons_putc+0x40>
f010033f:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f0100345:	7e e8                	jle    f010032f <cons_putc+0x28>
	outb(COM1 + COM_TX, c);
f0100347:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010034a:	89 f8                	mov    %edi,%eax
f010034c:	88 45 e3             	mov    %al,-0x1d(%ebp)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010034f:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100354:	ee                   	out    %al,(%dx)
	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100355:	be 00 00 00 00       	mov    $0x0,%esi
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010035a:	bf 79 03 00 00       	mov    $0x379,%edi
f010035f:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100364:	eb 09                	jmp    f010036f <cons_putc+0x68>
f0100366:	89 ca                	mov    %ecx,%edx
f0100368:	ec                   	in     (%dx),%al
f0100369:	ec                   	in     (%dx),%al
f010036a:	ec                   	in     (%dx),%al
f010036b:	ec                   	in     (%dx),%al
f010036c:	83 c6 01             	add    $0x1,%esi
f010036f:	89 fa                	mov    %edi,%edx
f0100371:	ec                   	in     (%dx),%al
f0100372:	81 fe ff 31 00 00    	cmp    $0x31ff,%esi
f0100378:	7f 04                	jg     f010037e <cons_putc+0x77>
f010037a:	84 c0                	test   %al,%al
f010037c:	79 e8                	jns    f0100366 <cons_putc+0x5f>
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010037e:	ba 78 03 00 00       	mov    $0x378,%edx
f0100383:	0f b6 45 e3          	movzbl -0x1d(%ebp),%eax
f0100387:	ee                   	out    %al,(%dx)
f0100388:	ba 7a 03 00 00       	mov    $0x37a,%edx
f010038d:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100392:	ee                   	out    %al,(%dx)
f0100393:	b8 08 00 00 00       	mov    $0x8,%eax
f0100398:	ee                   	out    %al,(%dx)
	if (!(c & ~0xFF))
f0100399:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010039c:	89 fa                	mov    %edi,%edx
f010039e:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f01003a4:	89 f8                	mov    %edi,%eax
f01003a6:	80 cc 07             	or     $0x7,%ah
f01003a9:	85 d2                	test   %edx,%edx
f01003ab:	0f 45 c7             	cmovne %edi,%eax
f01003ae:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	switch (c & 0xff) {
f01003b1:	0f b6 c0             	movzbl %al,%eax
f01003b4:	83 f8 09             	cmp    $0x9,%eax
f01003b7:	0f 84 b9 00 00 00    	je     f0100476 <cons_putc+0x16f>
f01003bd:	83 f8 09             	cmp    $0x9,%eax
f01003c0:	7e 74                	jle    f0100436 <cons_putc+0x12f>
f01003c2:	83 f8 0a             	cmp    $0xa,%eax
f01003c5:	0f 84 9e 00 00 00    	je     f0100469 <cons_putc+0x162>
f01003cb:	83 f8 0d             	cmp    $0xd,%eax
f01003ce:	0f 85 d9 00 00 00    	jne    f01004ad <cons_putc+0x1a6>
		crt_pos -= (crt_pos % CRT_COLS);
f01003d4:	0f b7 83 08 23 00 00 	movzwl 0x2308(%ebx),%eax
f01003db:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003e1:	c1 e8 16             	shr    $0x16,%eax
f01003e4:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003e7:	c1 e0 04             	shl    $0x4,%eax
f01003ea:	66 89 83 08 23 00 00 	mov    %ax,0x2308(%ebx)
	if (crt_pos >= CRT_SIZE) {
f01003f1:	66 81 bb 08 23 00 00 	cmpw   $0x7cf,0x2308(%ebx)
f01003f8:	cf 07 
f01003fa:	0f 87 d4 00 00 00    	ja     f01004d4 <cons_putc+0x1cd>
	outb(addr_6845, 14);
f0100400:	8b 8b 10 23 00 00    	mov    0x2310(%ebx),%ecx
f0100406:	b8 0e 00 00 00       	mov    $0xe,%eax
f010040b:	89 ca                	mov    %ecx,%edx
f010040d:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010040e:	0f b7 9b 08 23 00 00 	movzwl 0x2308(%ebx),%ebx
f0100415:	8d 71 01             	lea    0x1(%ecx),%esi
f0100418:	89 d8                	mov    %ebx,%eax
f010041a:	66 c1 e8 08          	shr    $0x8,%ax
f010041e:	89 f2                	mov    %esi,%edx
f0100420:	ee                   	out    %al,(%dx)
f0100421:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100426:	89 ca                	mov    %ecx,%edx
f0100428:	ee                   	out    %al,(%dx)
f0100429:	89 d8                	mov    %ebx,%eax
f010042b:	89 f2                	mov    %esi,%edx
f010042d:	ee                   	out    %al,(%dx)
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010042e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100431:	5b                   	pop    %ebx
f0100432:	5e                   	pop    %esi
f0100433:	5f                   	pop    %edi
f0100434:	5d                   	pop    %ebp
f0100435:	c3                   	ret    
	switch (c & 0xff) {
f0100436:	83 f8 08             	cmp    $0x8,%eax
f0100439:	75 72                	jne    f01004ad <cons_putc+0x1a6>
		if (crt_pos > 0) {
f010043b:	0f b7 83 08 23 00 00 	movzwl 0x2308(%ebx),%eax
f0100442:	66 85 c0             	test   %ax,%ax
f0100445:	74 b9                	je     f0100400 <cons_putc+0xf9>
			crt_pos--;
f0100447:	83 e8 01             	sub    $0x1,%eax
f010044a:	66 89 83 08 23 00 00 	mov    %ax,0x2308(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100451:	0f b7 c0             	movzwl %ax,%eax
f0100454:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f0100458:	b2 00                	mov    $0x0,%dl
f010045a:	83 ca 20             	or     $0x20,%edx
f010045d:	8b 8b 0c 23 00 00    	mov    0x230c(%ebx),%ecx
f0100463:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f0100467:	eb 88                	jmp    f01003f1 <cons_putc+0xea>
		crt_pos += CRT_COLS;
f0100469:	66 83 83 08 23 00 00 	addw   $0x50,0x2308(%ebx)
f0100470:	50 
f0100471:	e9 5e ff ff ff       	jmp    f01003d4 <cons_putc+0xcd>
		cons_putc(' ');
f0100476:	b8 20 00 00 00       	mov    $0x20,%eax
f010047b:	e8 87 fe ff ff       	call   f0100307 <cons_putc>
		cons_putc(' ');
f0100480:	b8 20 00 00 00       	mov    $0x20,%eax
f0100485:	e8 7d fe ff ff       	call   f0100307 <cons_putc>
		cons_putc(' ');
f010048a:	b8 20 00 00 00       	mov    $0x20,%eax
f010048f:	e8 73 fe ff ff       	call   f0100307 <cons_putc>
		cons_putc(' ');
f0100494:	b8 20 00 00 00       	mov    $0x20,%eax
f0100499:	e8 69 fe ff ff       	call   f0100307 <cons_putc>
		cons_putc(' ');
f010049e:	b8 20 00 00 00       	mov    $0x20,%eax
f01004a3:	e8 5f fe ff ff       	call   f0100307 <cons_putc>
f01004a8:	e9 44 ff ff ff       	jmp    f01003f1 <cons_putc+0xea>
		crt_buf[crt_pos++] = c;		/* write the character */
f01004ad:	0f b7 83 08 23 00 00 	movzwl 0x2308(%ebx),%eax
f01004b4:	8d 50 01             	lea    0x1(%eax),%edx
f01004b7:	66 89 93 08 23 00 00 	mov    %dx,0x2308(%ebx)
f01004be:	0f b7 c0             	movzwl %ax,%eax
f01004c1:	8b 93 0c 23 00 00    	mov    0x230c(%ebx),%edx
f01004c7:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f01004cb:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004cf:	e9 1d ff ff ff       	jmp    f01003f1 <cons_putc+0xea>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01004d4:	8b 83 0c 23 00 00    	mov    0x230c(%ebx),%eax
f01004da:	83 ec 04             	sub    $0x4,%esp
f01004dd:	68 00 0f 00 00       	push   $0xf00
f01004e2:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004e8:	52                   	push   %edx
f01004e9:	50                   	push   %eax
f01004ea:	e8 a4 4e 00 00       	call   f0105393 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01004ef:	8b 93 0c 23 00 00    	mov    0x230c(%ebx),%edx
f01004f5:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01004fb:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100501:	83 c4 10             	add    $0x10,%esp
f0100504:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100509:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010050c:	39 d0                	cmp    %edx,%eax
f010050e:	75 f4                	jne    f0100504 <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
f0100510:	66 83 ab 08 23 00 00 	subw   $0x50,0x2308(%ebx)
f0100517:	50 
f0100518:	e9 e3 fe ff ff       	jmp    f0100400 <cons_putc+0xf9>

f010051d <serial_intr>:
{
f010051d:	e8 e7 01 00 00       	call   f0100709 <__x86.get_pc_thunk.ax>
f0100522:	05 fe ca 08 00       	add    $0x8cafe,%eax
	if (serial_exists)
f0100527:	80 b8 14 23 00 00 00 	cmpb   $0x0,0x2314(%eax)
f010052e:	75 02                	jne    f0100532 <serial_intr+0x15>
f0100530:	f3 c3                	repz ret 
{
f0100532:	55                   	push   %ebp
f0100533:	89 e5                	mov    %esp,%ebp
f0100535:	83 ec 08             	sub    $0x8,%esp
		cons_intr(serial_proc_data);
f0100538:	8d 80 4b 31 f7 ff    	lea    -0x8ceb5(%eax),%eax
f010053e:	e8 47 fc ff ff       	call   f010018a <cons_intr>
}
f0100543:	c9                   	leave  
f0100544:	c3                   	ret    

f0100545 <kbd_intr>:
{
f0100545:	55                   	push   %ebp
f0100546:	89 e5                	mov    %esp,%ebp
f0100548:	83 ec 08             	sub    $0x8,%esp
f010054b:	e8 b9 01 00 00       	call   f0100709 <__x86.get_pc_thunk.ax>
f0100550:	05 d0 ca 08 00       	add    $0x8cad0,%eax
	cons_intr(kbd_proc_data);
f0100555:	8d 80 b5 31 f7 ff    	lea    -0x8ce4b(%eax),%eax
f010055b:	e8 2a fc ff ff       	call   f010018a <cons_intr>
}
f0100560:	c9                   	leave  
f0100561:	c3                   	ret    

f0100562 <cons_getc>:
{
f0100562:	55                   	push   %ebp
f0100563:	89 e5                	mov    %esp,%ebp
f0100565:	53                   	push   %ebx
f0100566:	83 ec 04             	sub    $0x4,%esp
f0100569:	e8 f9 fb ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010056e:	81 c3 b2 ca 08 00    	add    $0x8cab2,%ebx
	serial_intr();
f0100574:	e8 a4 ff ff ff       	call   f010051d <serial_intr>
	kbd_intr();
f0100579:	e8 c7 ff ff ff       	call   f0100545 <kbd_intr>
	if (cons.rpos != cons.wpos) {
f010057e:	8b 93 00 23 00 00    	mov    0x2300(%ebx),%edx
	return 0;
f0100584:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f0100589:	3b 93 04 23 00 00    	cmp    0x2304(%ebx),%edx
f010058f:	74 19                	je     f01005aa <cons_getc+0x48>
		c = cons.buf[cons.rpos++];
f0100591:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100594:	89 8b 00 23 00 00    	mov    %ecx,0x2300(%ebx)
f010059a:	0f b6 84 13 00 21 00 	movzbl 0x2100(%ebx,%edx,1),%eax
f01005a1:	00 
		if (cons.rpos == CONSBUFSIZE)
f01005a2:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01005a8:	74 06                	je     f01005b0 <cons_getc+0x4e>
}
f01005aa:	83 c4 04             	add    $0x4,%esp
f01005ad:	5b                   	pop    %ebx
f01005ae:	5d                   	pop    %ebp
f01005af:	c3                   	ret    
			cons.rpos = 0;
f01005b0:	c7 83 00 23 00 00 00 	movl   $0x0,0x2300(%ebx)
f01005b7:	00 00 00 
f01005ba:	eb ee                	jmp    f01005aa <cons_getc+0x48>

f01005bc <cons_init>:

// initialize the console devices
void
cons_init(void)
{
f01005bc:	55                   	push   %ebp
f01005bd:	89 e5                	mov    %esp,%ebp
f01005bf:	57                   	push   %edi
f01005c0:	56                   	push   %esi
f01005c1:	53                   	push   %ebx
f01005c2:	83 ec 1c             	sub    $0x1c,%esp
f01005c5:	e8 9d fb ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01005ca:	81 c3 56 ca 08 00    	add    $0x8ca56,%ebx
	was = *cp;
f01005d0:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01005d7:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01005de:	5a a5 
	if (*cp != 0xA55A) {
f01005e0:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01005e7:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01005eb:	0f 84 bc 00 00 00    	je     f01006ad <cons_init+0xf1>
		addr_6845 = MONO_BASE;
f01005f1:	c7 83 10 23 00 00 b4 	movl   $0x3b4,0x2310(%ebx)
f01005f8:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005fb:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f0100602:	8b bb 10 23 00 00    	mov    0x2310(%ebx),%edi
f0100608:	b8 0e 00 00 00       	mov    $0xe,%eax
f010060d:	89 fa                	mov    %edi,%edx
f010060f:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100610:	8d 4f 01             	lea    0x1(%edi),%ecx
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100613:	89 ca                	mov    %ecx,%edx
f0100615:	ec                   	in     (%dx),%al
f0100616:	0f b6 f0             	movzbl %al,%esi
f0100619:	c1 e6 08             	shl    $0x8,%esi
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010061c:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100621:	89 fa                	mov    %edi,%edx
f0100623:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100624:	89 ca                	mov    %ecx,%edx
f0100626:	ec                   	in     (%dx),%al
	crt_buf = (uint16_t*) cp;
f0100627:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010062a:	89 bb 0c 23 00 00    	mov    %edi,0x230c(%ebx)
	pos |= inb(addr_6845 + 1);
f0100630:	0f b6 c0             	movzbl %al,%eax
f0100633:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f0100635:	66 89 b3 08 23 00 00 	mov    %si,0x2308(%ebx)
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010063c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100641:	89 c8                	mov    %ecx,%eax
f0100643:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100648:	ee                   	out    %al,(%dx)
f0100649:	bf fb 03 00 00       	mov    $0x3fb,%edi
f010064e:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100653:	89 fa                	mov    %edi,%edx
f0100655:	ee                   	out    %al,(%dx)
f0100656:	b8 0c 00 00 00       	mov    $0xc,%eax
f010065b:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100660:	ee                   	out    %al,(%dx)
f0100661:	be f9 03 00 00       	mov    $0x3f9,%esi
f0100666:	89 c8                	mov    %ecx,%eax
f0100668:	89 f2                	mov    %esi,%edx
f010066a:	ee                   	out    %al,(%dx)
f010066b:	b8 03 00 00 00       	mov    $0x3,%eax
f0100670:	89 fa                	mov    %edi,%edx
f0100672:	ee                   	out    %al,(%dx)
f0100673:	ba fc 03 00 00       	mov    $0x3fc,%edx
f0100678:	89 c8                	mov    %ecx,%eax
f010067a:	ee                   	out    %al,(%dx)
f010067b:	b8 01 00 00 00       	mov    $0x1,%eax
f0100680:	89 f2                	mov    %esi,%edx
f0100682:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100683:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100688:	ec                   	in     (%dx),%al
f0100689:	89 c1                	mov    %eax,%ecx
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010068b:	3c ff                	cmp    $0xff,%al
f010068d:	0f 95 83 14 23 00 00 	setne  0x2314(%ebx)
f0100694:	ba fa 03 00 00       	mov    $0x3fa,%edx
f0100699:	ec                   	in     (%dx),%al
f010069a:	ba f8 03 00 00       	mov    $0x3f8,%edx
f010069f:	ec                   	in     (%dx),%al
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01006a0:	80 f9 ff             	cmp    $0xff,%cl
f01006a3:	74 25                	je     f01006ca <cons_init+0x10e>
		cprintf("Serial port does not exist!\n");
}
f01006a5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01006a8:	5b                   	pop    %ebx
f01006a9:	5e                   	pop    %esi
f01006aa:	5f                   	pop    %edi
f01006ab:	5d                   	pop    %ebp
f01006ac:	c3                   	ret    
		*cp = was;
f01006ad:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01006b4:	c7 83 10 23 00 00 d4 	movl   $0x3d4,0x2310(%ebx)
f01006bb:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006be:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f01006c5:	e9 38 ff ff ff       	jmp    f0100602 <cons_init+0x46>
		cprintf("Serial port does not exist!\n");
f01006ca:	83 ec 0c             	sub    $0xc,%esp
f01006cd:	8d 83 d9 87 f7 ff    	lea    -0x87827(%ebx),%eax
f01006d3:	50                   	push   %eax
f01006d4:	e8 e5 35 00 00       	call   f0103cbe <cprintf>
f01006d9:	83 c4 10             	add    $0x10,%esp
}
f01006dc:	eb c7                	jmp    f01006a5 <cons_init+0xe9>

f01006de <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01006de:	55                   	push   %ebp
f01006df:	89 e5                	mov    %esp,%ebp
f01006e1:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01006e4:	8b 45 08             	mov    0x8(%ebp),%eax
f01006e7:	e8 1b fc ff ff       	call   f0100307 <cons_putc>
}
f01006ec:	c9                   	leave  
f01006ed:	c3                   	ret    

f01006ee <getchar>:

int
getchar(void)
{
f01006ee:	55                   	push   %ebp
f01006ef:	89 e5                	mov    %esp,%ebp
f01006f1:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01006f4:	e8 69 fe ff ff       	call   f0100562 <cons_getc>
f01006f9:	85 c0                	test   %eax,%eax
f01006fb:	74 f7                	je     f01006f4 <getchar+0x6>
		/* do nothing */;
	return c;
}
f01006fd:	c9                   	leave  
f01006fe:	c3                   	ret    

f01006ff <iscons>:

int
iscons(int fdnum)
{
f01006ff:	55                   	push   %ebp
f0100700:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f0100702:	b8 01 00 00 00       	mov    $0x1,%eax
f0100707:	5d                   	pop    %ebp
f0100708:	c3                   	ret    

f0100709 <__x86.get_pc_thunk.ax>:
f0100709:	8b 04 24             	mov    (%esp),%eax
f010070c:	c3                   	ret    

f010070d <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010070d:	55                   	push   %ebp
f010070e:	89 e5                	mov    %esp,%ebp
f0100710:	56                   	push   %esi
f0100711:	53                   	push   %ebx
f0100712:	e8 50 fa ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100717:	81 c3 09 c9 08 00    	add    $0x8c909,%ebx
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010071d:	83 ec 04             	sub    $0x4,%esp
f0100720:	8d 83 00 8a f7 ff    	lea    -0x87600(%ebx),%eax
f0100726:	50                   	push   %eax
f0100727:	8d 83 1e 8a f7 ff    	lea    -0x875e2(%ebx),%eax
f010072d:	50                   	push   %eax
f010072e:	8d b3 23 8a f7 ff    	lea    -0x875dd(%ebx),%esi
f0100734:	56                   	push   %esi
f0100735:	e8 84 35 00 00       	call   f0103cbe <cprintf>
f010073a:	83 c4 0c             	add    $0xc,%esp
f010073d:	8d 83 dc 8a f7 ff    	lea    -0x87524(%ebx),%eax
f0100743:	50                   	push   %eax
f0100744:	8d 83 2c 8a f7 ff    	lea    -0x875d4(%ebx),%eax
f010074a:	50                   	push   %eax
f010074b:	56                   	push   %esi
f010074c:	e8 6d 35 00 00       	call   f0103cbe <cprintf>
f0100751:	83 c4 0c             	add    $0xc,%esp
f0100754:	8d 83 04 8b f7 ff    	lea    -0x874fc(%ebx),%eax
f010075a:	50                   	push   %eax
f010075b:	8d 83 35 8a f7 ff    	lea    -0x875cb(%ebx),%eax
f0100761:	50                   	push   %eax
f0100762:	56                   	push   %esi
f0100763:	e8 56 35 00 00       	call   f0103cbe <cprintf>
	return 0;
}
f0100768:	b8 00 00 00 00       	mov    $0x0,%eax
f010076d:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100770:	5b                   	pop    %ebx
f0100771:	5e                   	pop    %esi
f0100772:	5d                   	pop    %ebp
f0100773:	c3                   	ret    

f0100774 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100774:	55                   	push   %ebp
f0100775:	89 e5                	mov    %esp,%ebp
f0100777:	57                   	push   %edi
f0100778:	56                   	push   %esi
f0100779:	53                   	push   %ebx
f010077a:	83 ec 18             	sub    $0x18,%esp
f010077d:	e8 e5 f9 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100782:	81 c3 9e c8 08 00    	add    $0x8c89e,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100788:	8d 83 3f 8a f7 ff    	lea    -0x875c1(%ebx),%eax
f010078e:	50                   	push   %eax
f010078f:	e8 2a 35 00 00       	call   f0103cbe <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100794:	83 c4 08             	add    $0x8,%esp
f0100797:	ff b3 f4 ff ff ff    	pushl  -0xc(%ebx)
f010079d:	8d 83 38 8b f7 ff    	lea    -0x874c8(%ebx),%eax
f01007a3:	50                   	push   %eax
f01007a4:	e8 15 35 00 00       	call   f0103cbe <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007a9:	83 c4 0c             	add    $0xc,%esp
f01007ac:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f01007b2:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f01007b8:	50                   	push   %eax
f01007b9:	57                   	push   %edi
f01007ba:	8d 83 60 8b f7 ff    	lea    -0x874a0(%ebx),%eax
f01007c0:	50                   	push   %eax
f01007c1:	e8 f8 34 00 00       	call   f0103cbe <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007c6:	83 c4 0c             	add    $0xc,%esp
f01007c9:	c7 c0 89 57 10 f0    	mov    $0xf0105789,%eax
f01007cf:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007d5:	52                   	push   %edx
f01007d6:	50                   	push   %eax
f01007d7:	8d 83 84 8b f7 ff    	lea    -0x8747c(%ebx),%eax
f01007dd:	50                   	push   %eax
f01007de:	e8 db 34 00 00       	call   f0103cbe <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007e3:	83 c4 0c             	add    $0xc,%esp
f01007e6:	c7 c0 00 f1 18 f0    	mov    $0xf018f100,%eax
f01007ec:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007f2:	52                   	push   %edx
f01007f3:	50                   	push   %eax
f01007f4:	8d 83 a8 8b f7 ff    	lea    -0x87458(%ebx),%eax
f01007fa:	50                   	push   %eax
f01007fb:	e8 be 34 00 00       	call   f0103cbe <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100800:	83 c4 0c             	add    $0xc,%esp
f0100803:	c7 c6 10 00 19 f0    	mov    $0xf0190010,%esi
f0100809:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f010080f:	50                   	push   %eax
f0100810:	56                   	push   %esi
f0100811:	8d 83 cc 8b f7 ff    	lea    -0x87434(%ebx),%eax
f0100817:	50                   	push   %eax
f0100818:	e8 a1 34 00 00       	call   f0103cbe <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f010081d:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100820:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f0100826:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100828:	c1 fe 0a             	sar    $0xa,%esi
f010082b:	56                   	push   %esi
f010082c:	8d 83 f0 8b f7 ff    	lea    -0x87410(%ebx),%eax
f0100832:	50                   	push   %eax
f0100833:	e8 86 34 00 00       	call   f0103cbe <cprintf>
	return 0;
}
f0100838:	b8 00 00 00 00       	mov    $0x0,%eax
f010083d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100840:	5b                   	pop    %ebx
f0100841:	5e                   	pop    %esi
f0100842:	5f                   	pop    %edi
f0100843:	5d                   	pop    %ebp
f0100844:	c3                   	ret    

f0100845 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100845:	55                   	push   %ebp
f0100846:	89 e5                	mov    %esp,%ebp
f0100848:	57                   	push   %edi
f0100849:	56                   	push   %esi
f010084a:	53                   	push   %ebx
f010084b:	83 ec 58             	sub    $0x58,%esp
f010084e:	e8 14 f9 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100853:	81 c3 cd c7 08 00    	add    $0x8c7cd,%ebx
	cprintf("Stack backtrace:\n");
f0100859:	8d 83 58 8a f7 ff    	lea    -0x875a8(%ebx),%eax
f010085f:	50                   	push   %eax
f0100860:	e8 59 34 00 00       	call   f0103cbe <cprintf>

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f0100865:	89 ef                	mov    %ebp,%edi
	int* curr_ebp = (int *) read_ebp();
f0100867:	83 c4 10             	add    $0x10,%esp
		// is already the last function in the call stack, and
		// thus you print the info and return.

		eip = (uint32_t) *(curr_ebp + 1);

		cprintf("  ebp %08x eip %08x ", curr_ebp, eip);
f010086a:	8d 83 6a 8a f7 ff    	lea    -0x87596(%ebx),%eax
f0100870:	89 45 b8             	mov    %eax,-0x48(%ebp)
		cprintf("args");
f0100873:	8d 83 7f 8a f7 ff    	lea    -0x87581(%ebx),%eax
f0100879:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		prev_ebp = (int *) *curr_ebp;
f010087c:	8b 07                	mov    (%edi),%eax
f010087e:	89 45 c0             	mov    %eax,-0x40(%ebp)
		eip = (uint32_t) *(curr_ebp + 1);
f0100881:	8b 47 04             	mov    0x4(%edi),%eax
f0100884:	89 45 bc             	mov    %eax,-0x44(%ebp)
		cprintf("  ebp %08x eip %08x ", curr_ebp, eip);
f0100887:	83 ec 04             	sub    $0x4,%esp
f010088a:	50                   	push   %eax
f010088b:	57                   	push   %edi
f010088c:	ff 75 b8             	pushl  -0x48(%ebp)
f010088f:	e8 2a 34 00 00       	call   f0103cbe <cprintf>
		cprintf("args");
f0100894:	83 c4 04             	add    $0x4,%esp
f0100897:	ff 75 b4             	pushl  -0x4c(%ebp)
f010089a:	e8 1f 34 00 00       	call   f0103cbe <cprintf>
		int *arg_p = curr_ebp + 2;
f010089f:	8d 77 08             	lea    0x8(%edi),%esi
f01008a2:	8d 47 1c             	lea    0x1c(%edi),%eax
f01008a5:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f01008a8:	83 c4 10             	add    $0x10,%esp
		for (int i = 0; i < 5; ++i) {
			cprintf(" %08x", *arg_p);
f01008ab:	8d bb 84 8a f7 ff    	lea    -0x8757c(%ebx),%edi
f01008b1:	83 ec 08             	sub    $0x8,%esp
f01008b4:	ff 36                	pushl  (%esi)
f01008b6:	57                   	push   %edi
f01008b7:	e8 02 34 00 00       	call   f0103cbe <cprintf>
			++arg_p;
f01008bc:	83 c6 04             	add    $0x4,%esi
		for (int i = 0; i < 5; ++i) {
f01008bf:	83 c4 10             	add    $0x10,%esp
f01008c2:	39 75 c4             	cmp    %esi,-0x3c(%ebp)
f01008c5:	75 ea                	jne    f01008b1 <mon_backtrace+0x6c>
		}

		cprintf("\n");
f01008c7:	83 ec 0c             	sub    $0xc,%esp
f01008ca:	8d 83 61 8f f7 ff    	lea    -0x8709f(%ebx),%eax
f01008d0:	50                   	push   %eax
f01008d1:	e8 e8 33 00 00       	call   f0103cbe <cprintf>

		// debugging info
		struct Eipdebuginfo info;
		debuginfo_eip(eip, &info);
f01008d6:	83 c4 08             	add    $0x8,%esp
f01008d9:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01008dc:	50                   	push   %eax
f01008dd:	8b 7d bc             	mov    -0x44(%ebp),%edi
f01008e0:	57                   	push   %edi
f01008e1:	e8 da 3e 00 00       	call   f01047c0 <debuginfo_eip>
		cprintf("        ");
f01008e6:	8d 83 8a 8a f7 ff    	lea    -0x87576(%ebx),%eax
f01008ec:	89 04 24             	mov    %eax,(%esp)
f01008ef:	e8 ca 33 00 00       	call   f0103cbe <cprintf>
		cprintf("%s:%d: ", info.eip_file, info.eip_line);
f01008f4:	83 c4 0c             	add    $0xc,%esp
f01008f7:	ff 75 d4             	pushl  -0x2c(%ebp)
f01008fa:	ff 75 d0             	pushl  -0x30(%ebp)
f01008fd:	8d 83 ab 87 f7 ff    	lea    -0x87855(%ebx),%eax
f0100903:	50                   	push   %eax
f0100904:	e8 b5 33 00 00       	call   f0103cbe <cprintf>
		cprintf("%.*s", info.eip_fn_namelen, info.eip_fn_name);
f0100909:	83 c4 0c             	add    $0xc,%esp
f010090c:	ff 75 d8             	pushl  -0x28(%ebp)
f010090f:	ff 75 dc             	pushl  -0x24(%ebp)
f0100912:	8d 83 93 8a f7 ff    	lea    -0x8756d(%ebx),%eax
f0100918:	50                   	push   %eax
f0100919:	e8 a0 33 00 00       	call   f0103cbe <cprintf>
		cprintf("+%d\n", eip - (uint32_t)info.eip_fn_addr);
f010091e:	83 c4 08             	add    $0x8,%esp
f0100921:	89 f8                	mov    %edi,%eax
f0100923:	2b 45 e0             	sub    -0x20(%ebp),%eax
f0100926:	50                   	push   %eax
f0100927:	8d 83 98 8a f7 ff    	lea    -0x87568(%ebx),%eax
f010092d:	50                   	push   %eax
f010092e:	e8 8b 33 00 00       	call   f0103cbe <cprintf>

		// Check ending
		if (prev_ebp == 0) {
f0100933:	83 c4 10             	add    $0x10,%esp
f0100936:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0100939:	85 ff                	test   %edi,%edi
f010093b:	0f 85 3b ff ff ff    	jne    f010087c <mon_backtrace+0x37>
		} else {
			curr_ebp = prev_ebp;
		}
	}
	return 0;
}
f0100941:	b8 00 00 00 00       	mov    $0x0,%eax
f0100946:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100949:	5b                   	pop    %ebx
f010094a:	5e                   	pop    %esi
f010094b:	5f                   	pop    %edi
f010094c:	5d                   	pop    %ebp
f010094d:	c3                   	ret    

f010094e <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010094e:	55                   	push   %ebp
f010094f:	89 e5                	mov    %esp,%ebp
f0100951:	57                   	push   %edi
f0100952:	56                   	push   %esi
f0100953:	53                   	push   %ebx
f0100954:	83 ec 68             	sub    $0x68,%esp
f0100957:	e8 0b f8 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010095c:	81 c3 c4 c6 08 00    	add    $0x8c6c4,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100962:	8d 83 1c 8c f7 ff    	lea    -0x873e4(%ebx),%eax
f0100968:	50                   	push   %eax
f0100969:	e8 50 33 00 00       	call   f0103cbe <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010096e:	8d 83 40 8c f7 ff    	lea    -0x873c0(%ebx),%eax
f0100974:	89 04 24             	mov    %eax,(%esp)
f0100977:	e8 42 33 00 00       	call   f0103cbe <cprintf>

	if (tf != NULL)
f010097c:	83 c4 10             	add    $0x10,%esp
f010097f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100983:	74 0e                	je     f0100993 <monitor+0x45>
		print_trapframe(tf);
f0100985:	83 ec 0c             	sub    $0xc,%esp
f0100988:	ff 75 08             	pushl  0x8(%ebp)
f010098b:	e8 39 38 00 00       	call   f01041c9 <print_trapframe>
f0100990:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100993:	8d bb a1 8a f7 ff    	lea    -0x8755f(%ebx),%edi
f0100999:	eb 4a                	jmp    f01009e5 <monitor+0x97>
f010099b:	83 ec 08             	sub    $0x8,%esp
f010099e:	0f be c0             	movsbl %al,%eax
f01009a1:	50                   	push   %eax
f01009a2:	57                   	push   %edi
f01009a3:	e8 61 49 00 00       	call   f0105309 <strchr>
f01009a8:	83 c4 10             	add    $0x10,%esp
f01009ab:	85 c0                	test   %eax,%eax
f01009ad:	74 08                	je     f01009b7 <monitor+0x69>
			*buf++ = 0;
f01009af:	c6 06 00             	movb   $0x0,(%esi)
f01009b2:	8d 76 01             	lea    0x1(%esi),%esi
f01009b5:	eb 76                	jmp    f0100a2d <monitor+0xdf>
		if (*buf == 0)
f01009b7:	80 3e 00             	cmpb   $0x0,(%esi)
f01009ba:	74 7c                	je     f0100a38 <monitor+0xea>
		if (argc == MAXARGS-1) {
f01009bc:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f01009c0:	74 0f                	je     f01009d1 <monitor+0x83>
		argv[argc++] = buf;
f01009c2:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01009c5:	8d 48 01             	lea    0x1(%eax),%ecx
f01009c8:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f01009cb:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
f01009cf:	eb 41                	jmp    f0100a12 <monitor+0xc4>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01009d1:	83 ec 08             	sub    $0x8,%esp
f01009d4:	6a 10                	push   $0x10
f01009d6:	8d 83 a6 8a f7 ff    	lea    -0x8755a(%ebx),%eax
f01009dc:	50                   	push   %eax
f01009dd:	e8 dc 32 00 00       	call   f0103cbe <cprintf>
f01009e2:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f01009e5:	8d 83 9d 8a f7 ff    	lea    -0x87563(%ebx),%eax
f01009eb:	89 c6                	mov    %eax,%esi
f01009ed:	83 ec 0c             	sub    $0xc,%esp
f01009f0:	56                   	push   %esi
f01009f1:	e8 db 46 00 00       	call   f01050d1 <readline>
		if (buf != NULL)
f01009f6:	83 c4 10             	add    $0x10,%esp
f01009f9:	85 c0                	test   %eax,%eax
f01009fb:	74 f0                	je     f01009ed <monitor+0x9f>
f01009fd:	89 c6                	mov    %eax,%esi
	argv[argc] = 0;
f01009ff:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f0100a06:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f0100a0d:	eb 1e                	jmp    f0100a2d <monitor+0xdf>
			buf++;
f0100a0f:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a12:	0f b6 06             	movzbl (%esi),%eax
f0100a15:	84 c0                	test   %al,%al
f0100a17:	74 14                	je     f0100a2d <monitor+0xdf>
f0100a19:	83 ec 08             	sub    $0x8,%esp
f0100a1c:	0f be c0             	movsbl %al,%eax
f0100a1f:	50                   	push   %eax
f0100a20:	57                   	push   %edi
f0100a21:	e8 e3 48 00 00       	call   f0105309 <strchr>
f0100a26:	83 c4 10             	add    $0x10,%esp
f0100a29:	85 c0                	test   %eax,%eax
f0100a2b:	74 e2                	je     f0100a0f <monitor+0xc1>
		while (*buf && strchr(WHITESPACE, *buf))
f0100a2d:	0f b6 06             	movzbl (%esi),%eax
f0100a30:	84 c0                	test   %al,%al
f0100a32:	0f 85 63 ff ff ff    	jne    f010099b <monitor+0x4d>
	argv[argc] = 0;
f0100a38:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100a3b:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f0100a42:	00 
	if (argc == 0)
f0100a43:	85 c0                	test   %eax,%eax
f0100a45:	74 9e                	je     f01009e5 <monitor+0x97>
f0100a47:	8d b3 20 20 00 00    	lea    0x2020(%ebx),%esi
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a4d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a52:	89 7d a0             	mov    %edi,-0x60(%ebp)
f0100a55:	89 c7                	mov    %eax,%edi
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a57:	83 ec 08             	sub    $0x8,%esp
f0100a5a:	ff 36                	pushl  (%esi)
f0100a5c:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a5f:	e8 47 48 00 00       	call   f01052ab <strcmp>
f0100a64:	83 c4 10             	add    $0x10,%esp
f0100a67:	85 c0                	test   %eax,%eax
f0100a69:	74 28                	je     f0100a93 <monitor+0x145>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a6b:	83 c7 01             	add    $0x1,%edi
f0100a6e:	83 c6 0c             	add    $0xc,%esi
f0100a71:	83 ff 03             	cmp    $0x3,%edi
f0100a74:	75 e1                	jne    f0100a57 <monitor+0x109>
f0100a76:	8b 7d a0             	mov    -0x60(%ebp),%edi
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a79:	83 ec 08             	sub    $0x8,%esp
f0100a7c:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a7f:	8d 83 c3 8a f7 ff    	lea    -0x8753d(%ebx),%eax
f0100a85:	50                   	push   %eax
f0100a86:	e8 33 32 00 00       	call   f0103cbe <cprintf>
f0100a8b:	83 c4 10             	add    $0x10,%esp
f0100a8e:	e9 52 ff ff ff       	jmp    f01009e5 <monitor+0x97>
f0100a93:	89 f8                	mov    %edi,%eax
f0100a95:	8b 7d a0             	mov    -0x60(%ebp),%edi
			return commands[i].func(argc, argv, tf);
f0100a98:	83 ec 04             	sub    $0x4,%esp
f0100a9b:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100a9e:	ff 75 08             	pushl  0x8(%ebp)
f0100aa1:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100aa4:	52                   	push   %edx
f0100aa5:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100aa8:	ff 94 83 28 20 00 00 	call   *0x2028(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100aaf:	83 c4 10             	add    $0x10,%esp
f0100ab2:	85 c0                	test   %eax,%eax
f0100ab4:	0f 89 2b ff ff ff    	jns    f01009e5 <monitor+0x97>
				break;
	}
}
f0100aba:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100abd:	5b                   	pop    %ebx
f0100abe:	5e                   	pop    %esi
f0100abf:	5f                   	pop    %edi
f0100ac0:	5d                   	pop    %ebp
f0100ac1:	c3                   	ret    

f0100ac2 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100ac2:	55                   	push   %ebp
f0100ac3:	89 e5                	mov    %esp,%ebp
f0100ac5:	57                   	push   %edi
f0100ac6:	56                   	push   %esi
f0100ac7:	53                   	push   %ebx
f0100ac8:	83 ec 18             	sub    $0x18,%esp
f0100acb:	e8 97 f6 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100ad0:	81 c3 50 c5 08 00    	add    $0x8c550,%ebx
f0100ad6:	89 c7                	mov    %eax,%edi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100ad8:	50                   	push   %eax
f0100ad9:	e8 59 31 00 00       	call   f0103c37 <mc146818_read>
f0100ade:	89 c6                	mov    %eax,%esi
f0100ae0:	83 c7 01             	add    $0x1,%edi
f0100ae3:	89 3c 24             	mov    %edi,(%esp)
f0100ae6:	e8 4c 31 00 00       	call   f0103c37 <mc146818_read>
f0100aeb:	c1 e0 08             	shl    $0x8,%eax
f0100aee:	09 f0                	or     %esi,%eax
}
f0100af0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100af3:	5b                   	pop    %ebx
f0100af4:	5e                   	pop    %esi
f0100af5:	5f                   	pop    %edi
f0100af6:	5d                   	pop    %ebp
f0100af7:	c3                   	ret    

f0100af8 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100af8:	55                   	push   %ebp
f0100af9:	89 e5                	mov    %esp,%ebp
f0100afb:	53                   	push   %ebx
f0100afc:	83 ec 04             	sub    $0x4,%esp
f0100aff:	e8 63 f6 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100b04:	81 c3 1c c5 08 00    	add    $0x8c51c,%ebx
f0100b0a:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100b0c:	83 bb 18 23 00 00 00 	cmpl   $0x0,0x2318(%ebx)
f0100b13:	74 27                	je     f0100b3c <boot_alloc+0x44>
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	/* Check within 4MB Limit. Mentioned in Lab1. */
	if ((uint32_t)(nextfree + ROUNDUP(n, PGSIZE)) <= 0x400000 + KERNBASE) {
f0100b15:	8b 83 18 23 00 00    	mov    0x2318(%ebx),%eax
f0100b1b:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f0100b21:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b27:	01 c2                	add    %eax,%edx
f0100b29:	81 fa 00 00 40 f0    	cmp    $0xf0400000,%edx
f0100b2f:	77 23                	ja     f0100b54 <boot_alloc+0x5c>
		if (n >= 0) {
			result = nextfree;
			nextfree += ROUNDUP(n, PGSIZE);
f0100b31:	89 93 18 23 00 00    	mov    %edx,0x2318(%ebx)
	} else {
		panic("Exceed 4MB Limit");
	}

	return NULL;
}
f0100b37:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100b3a:	c9                   	leave  
f0100b3b:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100b3c:	c7 c0 10 00 19 f0    	mov    $0xf0190010,%eax
f0100b42:	05 ff 0f 00 00       	add    $0xfff,%eax
f0100b47:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b4c:	89 83 18 23 00 00    	mov    %eax,0x2318(%ebx)
f0100b52:	eb c1                	jmp    f0100b15 <boot_alloc+0x1d>
		panic("Exceed 4MB Limit");
f0100b54:	83 ec 04             	sub    $0x4,%esp
f0100b57:	8d 83 65 8c f7 ff    	lea    -0x8739b(%ebx),%eax
f0100b5d:	50                   	push   %eax
f0100b5e:	6a 75                	push   $0x75
f0100b60:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0100b66:	50                   	push   %eax
f0100b67:	e8 45 f5 ff ff       	call   f01000b1 <_panic>

f0100b6c <check_va2pa>:
// defined by the page directory 'pgdir'.  The hardware normally performs
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100b6c:	55                   	push   %ebp
f0100b6d:	89 e5                	mov    %esp,%ebp
f0100b6f:	56                   	push   %esi
f0100b70:	53                   	push   %ebx
f0100b71:	e8 c5 28 00 00       	call   f010343b <__x86.get_pc_thunk.cx>
f0100b76:	81 c1 aa c4 08 00    	add    $0x8c4aa,%ecx
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100b7c:	89 d3                	mov    %edx,%ebx
f0100b7e:	c1 eb 16             	shr    $0x16,%ebx
	if (!(*pgdir & PTE_P))
f0100b81:	8b 04 98             	mov    (%eax,%ebx,4),%eax
f0100b84:	a8 01                	test   $0x1,%al
f0100b86:	74 5a                	je     f0100be2 <check_va2pa+0x76>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100b88:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b8d:	89 c6                	mov    %eax,%esi
f0100b8f:	c1 ee 0c             	shr    $0xc,%esi
f0100b92:	c7 c3 04 00 19 f0    	mov    $0xf0190004,%ebx
f0100b98:	3b 33                	cmp    (%ebx),%esi
f0100b9a:	73 2b                	jae    f0100bc7 <check_va2pa+0x5b>
	if (!(p[PTX(va)] & PTE_P))
f0100b9c:	c1 ea 0c             	shr    $0xc,%edx
f0100b9f:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100ba5:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100bac:	89 c2                	mov    %eax,%edx
f0100bae:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100bb1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100bb6:	85 d2                	test   %edx,%edx
f0100bb8:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100bbd:	0f 44 c2             	cmove  %edx,%eax
}
f0100bc0:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100bc3:	5b                   	pop    %ebx
f0100bc4:	5e                   	pop    %esi
f0100bc5:	5d                   	pop    %ebp
f0100bc6:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bc7:	50                   	push   %eax
f0100bc8:	8d 81 94 8f f7 ff    	lea    -0x8706c(%ecx),%eax
f0100bce:	50                   	push   %eax
f0100bcf:	68 a1 03 00 00       	push   $0x3a1
f0100bd4:	8d 81 76 8c f7 ff    	lea    -0x8738a(%ecx),%eax
f0100bda:	50                   	push   %eax
f0100bdb:	89 cb                	mov    %ecx,%ebx
f0100bdd:	e8 cf f4 ff ff       	call   f01000b1 <_panic>
		return ~0;
f0100be2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100be7:	eb d7                	jmp    f0100bc0 <check_va2pa+0x54>

f0100be9 <check_page_free_list>:
{
f0100be9:	55                   	push   %ebp
f0100bea:	89 e5                	mov    %esp,%ebp
f0100bec:	57                   	push   %edi
f0100bed:	56                   	push   %esi
f0100bee:	53                   	push   %ebx
f0100bef:	83 ec 3c             	sub    $0x3c,%esp
f0100bf2:	e8 48 28 00 00       	call   f010343f <__x86.get_pc_thunk.di>
f0100bf7:	81 c7 29 c4 08 00    	add    $0x8c429,%edi
f0100bfd:	89 7d c4             	mov    %edi,-0x3c(%ebp)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c00:	84 c0                	test   %al,%al
f0100c02:	0f 85 dd 02 00 00    	jne    f0100ee5 <check_page_free_list+0x2fc>
	if (!page_free_list)
f0100c08:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100c0b:	83 b8 20 23 00 00 00 	cmpl   $0x0,0x2320(%eax)
f0100c12:	74 0c                	je     f0100c20 <check_page_free_list+0x37>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c14:	c7 45 d4 00 04 00 00 	movl   $0x400,-0x2c(%ebp)
f0100c1b:	e9 2f 03 00 00       	jmp    f0100f4f <check_page_free_list+0x366>
		panic("'page_free_list' is a null pointer!");
f0100c20:	83 ec 04             	sub    $0x4,%esp
f0100c23:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c26:	8d 83 b8 8f f7 ff    	lea    -0x87048(%ebx),%eax
f0100c2c:	50                   	push   %eax
f0100c2d:	68 de 02 00 00       	push   $0x2de
f0100c32:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0100c38:	50                   	push   %eax
f0100c39:	e8 73 f4 ff ff       	call   f01000b1 <_panic>
f0100c3e:	50                   	push   %eax
f0100c3f:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c42:	8d 83 94 8f f7 ff    	lea    -0x8706c(%ebx),%eax
f0100c48:	50                   	push   %eax
f0100c49:	6a 56                	push   $0x56
f0100c4b:	8d 83 82 8c f7 ff    	lea    -0x8737e(%ebx),%eax
f0100c51:	50                   	push   %eax
f0100c52:	e8 5a f4 ff ff       	call   f01000b1 <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c57:	8b 36                	mov    (%esi),%esi
f0100c59:	85 f6                	test   %esi,%esi
f0100c5b:	74 40                	je     f0100c9d <check_page_free_list+0xb4>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c5d:	89 f0                	mov    %esi,%eax
f0100c5f:	2b 07                	sub    (%edi),%eax
f0100c61:	c1 f8 03             	sar    $0x3,%eax
f0100c64:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100c67:	89 c2                	mov    %eax,%edx
f0100c69:	c1 ea 16             	shr    $0x16,%edx
f0100c6c:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100c6f:	73 e6                	jae    f0100c57 <check_page_free_list+0x6e>
	if (PGNUM(pa) >= npages)
f0100c71:	89 c2                	mov    %eax,%edx
f0100c73:	c1 ea 0c             	shr    $0xc,%edx
f0100c76:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100c79:	3b 11                	cmp    (%ecx),%edx
f0100c7b:	73 c1                	jae    f0100c3e <check_page_free_list+0x55>
			memset(page2kva(pp), 0x97, 128);
f0100c7d:	83 ec 04             	sub    $0x4,%esp
f0100c80:	68 80 00 00 00       	push   $0x80
f0100c85:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100c8a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c8f:	50                   	push   %eax
f0100c90:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c93:	e8 ae 46 00 00       	call   f0105346 <memset>
f0100c98:	83 c4 10             	add    $0x10,%esp
f0100c9b:	eb ba                	jmp    f0100c57 <check_page_free_list+0x6e>
	first_free_page = (char *) boot_alloc(0);
f0100c9d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ca2:	e8 51 fe ff ff       	call   f0100af8 <boot_alloc>
f0100ca7:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100caa:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100cad:	8b 97 20 23 00 00    	mov    0x2320(%edi),%edx
		assert(pp >= pages);
f0100cb3:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0100cb9:	8b 08                	mov    (%eax),%ecx
		assert(pp < pages + npages);
f0100cbb:	c7 c0 04 00 19 f0    	mov    $0xf0190004,%eax
f0100cc1:	8b 00                	mov    (%eax),%eax
f0100cc3:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100cc6:	8d 1c c1             	lea    (%ecx,%eax,8),%ebx
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100cc9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f0100ccc:	bf 00 00 00 00       	mov    $0x0,%edi
f0100cd1:	89 75 d0             	mov    %esi,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100cd4:	e9 08 01 00 00       	jmp    f0100de1 <check_page_free_list+0x1f8>
		assert(pp >= pages);
f0100cd9:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100cdc:	8d 83 90 8c f7 ff    	lea    -0x87370(%ebx),%eax
f0100ce2:	50                   	push   %eax
f0100ce3:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0100ce9:	50                   	push   %eax
f0100cea:	68 f8 02 00 00       	push   $0x2f8
f0100cef:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0100cf5:	50                   	push   %eax
f0100cf6:	e8 b6 f3 ff ff       	call   f01000b1 <_panic>
		assert(pp < pages + npages);
f0100cfb:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100cfe:	8d 83 b1 8c f7 ff    	lea    -0x8734f(%ebx),%eax
f0100d04:	50                   	push   %eax
f0100d05:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0100d0b:	50                   	push   %eax
f0100d0c:	68 f9 02 00 00       	push   $0x2f9
f0100d11:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0100d17:	50                   	push   %eax
f0100d18:	e8 94 f3 ff ff       	call   f01000b1 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d1d:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d20:	8d 83 dc 8f f7 ff    	lea    -0x87024(%ebx),%eax
f0100d26:	50                   	push   %eax
f0100d27:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0100d2d:	50                   	push   %eax
f0100d2e:	68 fa 02 00 00       	push   $0x2fa
f0100d33:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0100d39:	50                   	push   %eax
f0100d3a:	e8 72 f3 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != 0);
f0100d3f:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d42:	8d 83 c5 8c f7 ff    	lea    -0x8733b(%ebx),%eax
f0100d48:	50                   	push   %eax
f0100d49:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0100d4f:	50                   	push   %eax
f0100d50:	68 fd 02 00 00       	push   $0x2fd
f0100d55:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0100d5b:	50                   	push   %eax
f0100d5c:	e8 50 f3 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d61:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d64:	8d 83 d6 8c f7 ff    	lea    -0x8732a(%ebx),%eax
f0100d6a:	50                   	push   %eax
f0100d6b:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0100d71:	50                   	push   %eax
f0100d72:	68 fe 02 00 00       	push   $0x2fe
f0100d77:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0100d7d:	50                   	push   %eax
f0100d7e:	e8 2e f3 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d83:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d86:	8d 83 10 90 f7 ff    	lea    -0x86ff0(%ebx),%eax
f0100d8c:	50                   	push   %eax
f0100d8d:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0100d93:	50                   	push   %eax
f0100d94:	68 ff 02 00 00       	push   $0x2ff
f0100d99:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0100d9f:	50                   	push   %eax
f0100da0:	e8 0c f3 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100da5:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100da8:	8d 83 ef 8c f7 ff    	lea    -0x87311(%ebx),%eax
f0100dae:	50                   	push   %eax
f0100daf:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0100db5:	50                   	push   %eax
f0100db6:	68 00 03 00 00       	push   $0x300
f0100dbb:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0100dc1:	50                   	push   %eax
f0100dc2:	e8 ea f2 ff ff       	call   f01000b1 <_panic>
	if (PGNUM(pa) >= npages)
f0100dc7:	89 c6                	mov    %eax,%esi
f0100dc9:	c1 ee 0c             	shr    $0xc,%esi
f0100dcc:	39 75 cc             	cmp    %esi,-0x34(%ebp)
f0100dcf:	76 70                	jbe    f0100e41 <check_page_free_list+0x258>
	return (void *)(pa + KERNBASE);
f0100dd1:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100dd6:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100dd9:	77 7f                	ja     f0100e5a <check_page_free_list+0x271>
			++nfree_extmem;
f0100ddb:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ddf:	8b 12                	mov    (%edx),%edx
f0100de1:	85 d2                	test   %edx,%edx
f0100de3:	0f 84 93 00 00 00    	je     f0100e7c <check_page_free_list+0x293>
		assert(pp >= pages);
f0100de9:	39 d1                	cmp    %edx,%ecx
f0100deb:	0f 87 e8 fe ff ff    	ja     f0100cd9 <check_page_free_list+0xf0>
		assert(pp < pages + npages);
f0100df1:	39 d3                	cmp    %edx,%ebx
f0100df3:	0f 86 02 ff ff ff    	jbe    f0100cfb <check_page_free_list+0x112>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100df9:	89 d0                	mov    %edx,%eax
f0100dfb:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100dfe:	a8 07                	test   $0x7,%al
f0100e00:	0f 85 17 ff ff ff    	jne    f0100d1d <check_page_free_list+0x134>
	return (pp - pages) << PGSHIFT;
f0100e06:	c1 f8 03             	sar    $0x3,%eax
f0100e09:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f0100e0c:	85 c0                	test   %eax,%eax
f0100e0e:	0f 84 2b ff ff ff    	je     f0100d3f <check_page_free_list+0x156>
		assert(page2pa(pp) != IOPHYSMEM);
f0100e14:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100e19:	0f 84 42 ff ff ff    	je     f0100d61 <check_page_free_list+0x178>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100e1f:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100e24:	0f 84 59 ff ff ff    	je     f0100d83 <check_page_free_list+0x19a>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100e2a:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100e2f:	0f 84 70 ff ff ff    	je     f0100da5 <check_page_free_list+0x1bc>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e35:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100e3a:	77 8b                	ja     f0100dc7 <check_page_free_list+0x1de>
			++nfree_basemem;
f0100e3c:	83 c7 01             	add    $0x1,%edi
f0100e3f:	eb 9e                	jmp    f0100ddf <check_page_free_list+0x1f6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e41:	50                   	push   %eax
f0100e42:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e45:	8d 83 94 8f f7 ff    	lea    -0x8706c(%ebx),%eax
f0100e4b:	50                   	push   %eax
f0100e4c:	6a 56                	push   $0x56
f0100e4e:	8d 83 82 8c f7 ff    	lea    -0x8737e(%ebx),%eax
f0100e54:	50                   	push   %eax
f0100e55:	e8 57 f2 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e5a:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e5d:	8d 83 34 90 f7 ff    	lea    -0x86fcc(%ebx),%eax
f0100e63:	50                   	push   %eax
f0100e64:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0100e6a:	50                   	push   %eax
f0100e6b:	68 01 03 00 00       	push   $0x301
f0100e70:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0100e76:	50                   	push   %eax
f0100e77:	e8 35 f2 ff ff       	call   f01000b1 <_panic>
f0100e7c:	8b 75 d0             	mov    -0x30(%ebp),%esi
	assert(nfree_basemem > 0);
f0100e7f:	85 ff                	test   %edi,%edi
f0100e81:	7e 1e                	jle    f0100ea1 <check_page_free_list+0x2b8>
	assert(nfree_extmem > 0);
f0100e83:	85 f6                	test   %esi,%esi
f0100e85:	7e 3c                	jle    f0100ec3 <check_page_free_list+0x2da>
	cprintf("check_page_free_list() succeeded!\n");
f0100e87:	83 ec 0c             	sub    $0xc,%esp
f0100e8a:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e8d:	8d 83 7c 90 f7 ff    	lea    -0x86f84(%ebx),%eax
f0100e93:	50                   	push   %eax
f0100e94:	e8 25 2e 00 00       	call   f0103cbe <cprintf>
}
f0100e99:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e9c:	5b                   	pop    %ebx
f0100e9d:	5e                   	pop    %esi
f0100e9e:	5f                   	pop    %edi
f0100e9f:	5d                   	pop    %ebp
f0100ea0:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100ea1:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100ea4:	8d 83 09 8d f7 ff    	lea    -0x872f7(%ebx),%eax
f0100eaa:	50                   	push   %eax
f0100eab:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0100eb1:	50                   	push   %eax
f0100eb2:	68 09 03 00 00       	push   $0x309
f0100eb7:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0100ebd:	50                   	push   %eax
f0100ebe:	e8 ee f1 ff ff       	call   f01000b1 <_panic>
	assert(nfree_extmem > 0);
f0100ec3:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100ec6:	8d 83 1b 8d f7 ff    	lea    -0x872e5(%ebx),%eax
f0100ecc:	50                   	push   %eax
f0100ecd:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0100ed3:	50                   	push   %eax
f0100ed4:	68 0a 03 00 00       	push   $0x30a
f0100ed9:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0100edf:	50                   	push   %eax
f0100ee0:	e8 cc f1 ff ff       	call   f01000b1 <_panic>
	if (!page_free_list)
f0100ee5:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100ee8:	8b 80 20 23 00 00    	mov    0x2320(%eax),%eax
f0100eee:	85 c0                	test   %eax,%eax
f0100ef0:	0f 84 2a fd ff ff    	je     f0100c20 <check_page_free_list+0x37>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100ef6:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100ef9:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100efc:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100eff:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100f02:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100f05:	c7 c3 0c 00 19 f0    	mov    $0xf019000c,%ebx
f0100f0b:	89 c2                	mov    %eax,%edx
f0100f0d:	2b 13                	sub    (%ebx),%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100f0f:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100f15:	0f 95 c2             	setne  %dl
f0100f18:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100f1b:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100f1f:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100f21:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100f25:	8b 00                	mov    (%eax),%eax
f0100f27:	85 c0                	test   %eax,%eax
f0100f29:	75 e0                	jne    f0100f0b <check_page_free_list+0x322>
		*tp[1] = 0;
f0100f2b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100f2e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100f34:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100f37:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f3a:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100f3c:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100f3f:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100f42:	89 87 20 23 00 00    	mov    %eax,0x2320(%edi)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100f48:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100f4f:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100f52:	8b b0 20 23 00 00    	mov    0x2320(%eax),%esi
f0100f58:	c7 c7 0c 00 19 f0    	mov    $0xf019000c,%edi
	if (PGNUM(pa) >= npages)
f0100f5e:	c7 c0 04 00 19 f0    	mov    $0xf0190004,%eax
f0100f64:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100f67:	e9 ed fc ff ff       	jmp    f0100c59 <check_page_free_list+0x70>

f0100f6c <page_init>:
{
f0100f6c:	55                   	push   %ebp
f0100f6d:	89 e5                	mov    %esp,%ebp
f0100f6f:	57                   	push   %edi
f0100f70:	56                   	push   %esi
f0100f71:	53                   	push   %ebx
f0100f72:	83 ec 1c             	sub    $0x1c,%esp
f0100f75:	e8 c5 24 00 00       	call   f010343f <__x86.get_pc_thunk.di>
f0100f7a:	81 c7 a6 c0 08 00    	add    $0x8c0a6,%edi
f0100f80:	89 fe                	mov    %edi,%esi
f0100f82:	89 7d e4             	mov    %edi,-0x1c(%ebp)
	pages[0].pp_ref = 1;
f0100f85:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0100f8b:	8b 00                	mov    (%eax),%eax
f0100f8d:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	pages[0].pp_link = NULL;
f0100f93:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	for(i = 1; i < npages_basemem; ++i) {
f0100f99:	8b bf 24 23 00 00    	mov    0x2324(%edi),%edi
f0100f9f:	8b 8e 20 23 00 00    	mov    0x2320(%esi),%ecx
f0100fa5:	b8 00 00 00 00       	mov    $0x0,%eax
f0100faa:	bb 01 00 00 00       	mov    $0x1,%ebx
		pages[i].pp_ref = 0;
f0100faf:	c7 c6 0c 00 19 f0    	mov    $0xf019000c,%esi
	for(i = 1; i < npages_basemem; ++i) {
f0100fb5:	eb 1f                	jmp    f0100fd6 <page_init+0x6a>
		pages[i].pp_ref = 0;
f0100fb7:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
f0100fbe:	89 c2                	mov    %eax,%edx
f0100fc0:	03 16                	add    (%esi),%edx
f0100fc2:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
		pages[i].pp_link = page_free_list;
f0100fc8:	89 0a                	mov    %ecx,(%edx)
	for(i = 1; i < npages_basemem; ++i) {
f0100fca:	83 c3 01             	add    $0x1,%ebx
		page_free_list = &pages[i];
f0100fcd:	03 06                	add    (%esi),%eax
f0100fcf:	89 c1                	mov    %eax,%ecx
f0100fd1:	b8 01 00 00 00       	mov    $0x1,%eax
	for(i = 1; i < npages_basemem; ++i) {
f0100fd6:	39 df                	cmp    %ebx,%edi
f0100fd8:	77 dd                	ja     f0100fb7 <page_init+0x4b>
f0100fda:	84 c0                	test   %al,%al
f0100fdc:	75 12                	jne    f0100ff0 <page_init+0x84>
f0100fde:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
		pages[i].pp_ref = 1;
f0100fe5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0100fe8:	c7 c1 0c 00 19 f0    	mov    $0xf019000c,%ecx
f0100fee:	eb 21                	jmp    f0101011 <page_init+0xa5>
f0100ff0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ff3:	89 88 20 23 00 00    	mov    %ecx,0x2320(%eax)
f0100ff9:	eb e3                	jmp    f0100fde <page_init+0x72>
f0100ffb:	89 c2                	mov    %eax,%edx
f0100ffd:	03 11                	add    (%ecx),%edx
f0100fff:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
		pages[i].pp_link = NULL;
f0101005:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
	for(; i < EXTPHYSMEM / PGSIZE; ++i) {
f010100b:	83 c3 01             	add    $0x1,%ebx
f010100e:	83 c0 08             	add    $0x8,%eax
f0101011:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f0101017:	76 e2                	jbe    f0100ffb <page_init+0x8f>
	char* first_free_page = (char *)PADDR(boot_alloc(0));
f0101019:	b8 00 00 00 00       	mov    $0x0,%eax
f010101e:	e8 d5 fa ff ff       	call   f0100af8 <boot_alloc>
	if ((uint32_t)kva < KERNBASE)
f0101023:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101028:	76 1a                	jbe    f0101044 <page_init+0xd8>
	return (physaddr_t)kva - KERNBASE;
f010102a:	05 00 00 00 10       	add    $0x10000000,%eax
	for(; i < (uint32_t)first_free_page / PGSIZE; ++i) {
f010102f:	c1 e8 0c             	shr    $0xc,%eax
f0101032:	8d 14 dd 00 00 00 00 	lea    0x0(,%ebx,8),%edx
		pages[i].pp_ref = 1;
f0101039:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f010103c:	c7 c6 0c 00 19 f0    	mov    $0xf019000c,%esi
	for(; i < (uint32_t)first_free_page / PGSIZE; ++i) {
f0101042:	eb 32                	jmp    f0101076 <page_init+0x10a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101044:	50                   	push   %eax
f0101045:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0101048:	8d 83 a0 90 f7 ff    	lea    -0x86f60(%ebx),%eax
f010104e:	50                   	push   %eax
f010104f:	68 4b 01 00 00       	push   $0x14b
f0101054:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f010105a:	50                   	push   %eax
f010105b:	e8 51 f0 ff ff       	call   f01000b1 <_panic>
		pages[i].pp_ref = 1;
f0101060:	89 d1                	mov    %edx,%ecx
f0101062:	03 0e                	add    (%esi),%ecx
f0101064:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
		pages[i].pp_link = NULL;
f010106a:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	for(; i < (uint32_t)first_free_page / PGSIZE; ++i) {
f0101070:	83 c3 01             	add    $0x1,%ebx
f0101073:	83 c2 08             	add    $0x8,%edx
f0101076:	39 d8                	cmp    %ebx,%eax
f0101078:	77 e6                	ja     f0101060 <page_init+0xf4>
f010107a:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010107d:	8b 8e 20 23 00 00    	mov    0x2320(%esi),%ecx
f0101083:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
f010108a:	ba 00 00 00 00       	mov    $0x0,%edx
	for(; i < npages; ++i) {
f010108f:	c7 c7 04 00 19 f0    	mov    $0xf0190004,%edi
		pages[i].pp_ref = 0;
f0101095:	c7 c6 0c 00 19 f0    	mov    $0xf019000c,%esi
f010109b:	eb 1b                	jmp    f01010b8 <page_init+0x14c>
f010109d:	89 c2                	mov    %eax,%edx
f010109f:	03 16                	add    (%esi),%edx
f01010a1:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
		pages[i].pp_link = page_free_list;
f01010a7:	89 0a                	mov    %ecx,(%edx)
		page_free_list = &pages[i];
f01010a9:	89 c1                	mov    %eax,%ecx
f01010ab:	03 0e                	add    (%esi),%ecx
	for(; i < npages; ++i) {
f01010ad:	83 c3 01             	add    $0x1,%ebx
f01010b0:	83 c0 08             	add    $0x8,%eax
f01010b3:	ba 01 00 00 00       	mov    $0x1,%edx
f01010b8:	39 1f                	cmp    %ebx,(%edi)
f01010ba:	77 e1                	ja     f010109d <page_init+0x131>
f01010bc:	84 d2                	test   %dl,%dl
f01010be:	75 08                	jne    f01010c8 <page_init+0x15c>
}
f01010c0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01010c3:	5b                   	pop    %ebx
f01010c4:	5e                   	pop    %esi
f01010c5:	5f                   	pop    %edi
f01010c6:	5d                   	pop    %ebp
f01010c7:	c3                   	ret    
f01010c8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01010cb:	89 88 20 23 00 00    	mov    %ecx,0x2320(%eax)
f01010d1:	eb ed                	jmp    f01010c0 <page_init+0x154>

f01010d3 <page_alloc>:
{
f01010d3:	55                   	push   %ebp
f01010d4:	89 e5                	mov    %esp,%ebp
f01010d6:	56                   	push   %esi
f01010d7:	53                   	push   %ebx
f01010d8:	e8 8a f0 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01010dd:	81 c3 43 bf 08 00    	add    $0x8bf43,%ebx
	if (page_free_list) {
f01010e3:	8b b3 20 23 00 00    	mov    0x2320(%ebx),%esi
f01010e9:	85 f6                	test   %esi,%esi
f01010eb:	74 1a                	je     f0101107 <page_alloc+0x34>
		page_free_list = page_free_list->pp_link;
f01010ed:	8b 06                	mov    (%esi),%eax
f01010ef:	89 83 20 23 00 00    	mov    %eax,0x2320(%ebx)
		res->pp_ref = 0;
f01010f5:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)
		res->pp_link = NULL;	// Important
f01010fb:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
		if (alloc_flags & ALLOC_ZERO) {
f0101101:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0101105:	75 09                	jne    f0101110 <page_alloc+0x3d>
}
f0101107:	89 f0                	mov    %esi,%eax
f0101109:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010110c:	5b                   	pop    %ebx
f010110d:	5e                   	pop    %esi
f010110e:	5d                   	pop    %ebp
f010110f:	c3                   	ret    
	return (pp - pages) << PGSHIFT;
f0101110:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0101116:	89 f2                	mov    %esi,%edx
f0101118:	2b 10                	sub    (%eax),%edx
f010111a:	89 d0                	mov    %edx,%eax
f010111c:	c1 f8 03             	sar    $0x3,%eax
f010111f:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101122:	89 c1                	mov    %eax,%ecx
f0101124:	c1 e9 0c             	shr    $0xc,%ecx
f0101127:	c7 c2 04 00 19 f0    	mov    $0xf0190004,%edx
f010112d:	3b 0a                	cmp    (%edx),%ecx
f010112f:	73 1a                	jae    f010114b <page_alloc+0x78>
			memset(page2kva(res), '\0', PGSIZE);
f0101131:	83 ec 04             	sub    $0x4,%esp
f0101134:	68 00 10 00 00       	push   $0x1000
f0101139:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f010113b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101140:	50                   	push   %eax
f0101141:	e8 00 42 00 00       	call   f0105346 <memset>
f0101146:	83 c4 10             	add    $0x10,%esp
f0101149:	eb bc                	jmp    f0101107 <page_alloc+0x34>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010114b:	50                   	push   %eax
f010114c:	8d 83 94 8f f7 ff    	lea    -0x8706c(%ebx),%eax
f0101152:	50                   	push   %eax
f0101153:	6a 56                	push   $0x56
f0101155:	8d 83 82 8c f7 ff    	lea    -0x8737e(%ebx),%eax
f010115b:	50                   	push   %eax
f010115c:	e8 50 ef ff ff       	call   f01000b1 <_panic>

f0101161 <page_free>:
{
f0101161:	55                   	push   %ebp
f0101162:	89 e5                	mov    %esp,%ebp
f0101164:	53                   	push   %ebx
f0101165:	83 ec 04             	sub    $0x4,%esp
f0101168:	e8 fa ef ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010116d:	81 c3 b3 be 08 00    	add    $0x8beb3,%ebx
f0101173:	8b 45 08             	mov    0x8(%ebp),%eax
	if (pp->pp_ref != 0) {
f0101176:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f010117b:	75 18                	jne    f0101195 <page_free+0x34>
	} else if (pp->pp_link != NULL) {
f010117d:	83 38 00             	cmpl   $0x0,(%eax)
f0101180:	75 2e                	jne    f01011b0 <page_free+0x4f>
		pp->pp_link = page_free_list;
f0101182:	8b 8b 20 23 00 00    	mov    0x2320(%ebx),%ecx
f0101188:	89 08                	mov    %ecx,(%eax)
		page_free_list = pp;
f010118a:	89 83 20 23 00 00    	mov    %eax,0x2320(%ebx)
}
f0101190:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101193:	c9                   	leave  
f0101194:	c3                   	ret    
		panic("Nonzero pp_ref");
f0101195:	83 ec 04             	sub    $0x4,%esp
f0101198:	8d 83 2c 8d f7 ff    	lea    -0x872d4(%ebx),%eax
f010119e:	50                   	push   %eax
f010119f:	68 83 01 00 00       	push   $0x183
f01011a4:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f01011aa:	50                   	push   %eax
f01011ab:	e8 01 ef ff ff       	call   f01000b1 <_panic>
		panic("pp_link is not NULL");
f01011b0:	83 ec 04             	sub    $0x4,%esp
f01011b3:	8d 83 3b 8d f7 ff    	lea    -0x872c5(%ebx),%eax
f01011b9:	50                   	push   %eax
f01011ba:	68 85 01 00 00       	push   $0x185
f01011bf:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f01011c5:	50                   	push   %eax
f01011c6:	e8 e6 ee ff ff       	call   f01000b1 <_panic>

f01011cb <page_decref>:
{
f01011cb:	55                   	push   %ebp
f01011cc:	89 e5                	mov    %esp,%ebp
f01011ce:	83 ec 08             	sub    $0x8,%esp
f01011d1:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f01011d4:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f01011d8:	83 e8 01             	sub    $0x1,%eax
f01011db:	66 89 42 04          	mov    %ax,0x4(%edx)
f01011df:	66 85 c0             	test   %ax,%ax
f01011e2:	74 02                	je     f01011e6 <page_decref+0x1b>
}
f01011e4:	c9                   	leave  
f01011e5:	c3                   	ret    
		page_free(pp);
f01011e6:	83 ec 0c             	sub    $0xc,%esp
f01011e9:	52                   	push   %edx
f01011ea:	e8 72 ff ff ff       	call   f0101161 <page_free>
f01011ef:	83 c4 10             	add    $0x10,%esp
}
f01011f2:	eb f0                	jmp    f01011e4 <page_decref+0x19>

f01011f4 <pgdir_walk>:
{
f01011f4:	55                   	push   %ebp
f01011f5:	89 e5                	mov    %esp,%ebp
f01011f7:	57                   	push   %edi
f01011f8:	56                   	push   %esi
f01011f9:	53                   	push   %ebx
f01011fa:	83 ec 1c             	sub    $0x1c,%esp
f01011fd:	e8 65 ef ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0101202:	81 c3 1e be 08 00    	add    $0x8be1e,%ebx
	uintptr_t pg_va = (uintptr_t) ROUNDDOWN(va, PGSIZE);
f0101208:	8b 75 0c             	mov    0xc(%ebp),%esi
f010120b:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	pgtbl_idx = PTX(pg_va);
f0101211:	89 f0                	mov    %esi,%eax
f0101213:	c1 e8 0c             	shr    $0xc,%eax
f0101216:	25 ff 03 00 00       	and    $0x3ff,%eax
f010121b:	89 c7                	mov    %eax,%edi
	pgdir_idx = PDX(pg_va);
f010121d:	c1 ee 16             	shr    $0x16,%esi
	if (pgdir[pgdir_idx] & PTE_P) {	// The page table is present
f0101220:	c1 e6 02             	shl    $0x2,%esi
f0101223:	03 75 08             	add    0x8(%ebp),%esi
f0101226:	8b 06                	mov    (%esi),%eax
f0101228:	a8 01                	test   $0x1,%al
f010122a:	74 3d                	je     f0101269 <pgdir_walk+0x75>
		pgtable = KADDR(PTE_ADDR(pgdir[pgdir_idx]));
f010122c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101231:	89 c2                	mov    %eax,%edx
f0101233:	c1 ea 0c             	shr    $0xc,%edx
f0101236:	c7 c1 04 00 19 f0    	mov    $0xf0190004,%ecx
f010123c:	39 11                	cmp    %edx,(%ecx)
f010123e:	76 10                	jbe    f0101250 <pgdir_walk+0x5c>
	return (void *)(pa + KERNBASE);
f0101240:	2d 00 00 00 10       	sub    $0x10000000,%eax
	return &(pgtable[pgtbl_idx]);
f0101245:	8d 04 b8             	lea    (%eax,%edi,4),%eax
}
f0101248:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010124b:	5b                   	pop    %ebx
f010124c:	5e                   	pop    %esi
f010124d:	5f                   	pop    %edi
f010124e:	5d                   	pop    %ebp
f010124f:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101250:	50                   	push   %eax
f0101251:	8d 83 94 8f f7 ff    	lea    -0x8706c(%ebx),%eax
f0101257:	50                   	push   %eax
f0101258:	68 c9 01 00 00       	push   $0x1c9
f010125d:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0101263:	50                   	push   %eax
f0101264:	e8 48 ee ff ff       	call   f01000b1 <_panic>
		if (!create || (pginfo_ptr = page_alloc(1)) == NULL) {
f0101269:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010126d:	74 76                	je     f01012e5 <pgdir_walk+0xf1>
f010126f:	83 ec 0c             	sub    $0xc,%esp
f0101272:	6a 01                	push   $0x1
f0101274:	e8 5a fe ff ff       	call   f01010d3 <page_alloc>
f0101279:	83 c4 10             	add    $0x10,%esp
f010127c:	85 c0                	test   %eax,%eax
f010127e:	74 6f                	je     f01012ef <pgdir_walk+0xfb>
		pginfo_ptr->pp_ref = 1;
f0101280:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0101283:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
		memset(pgdir + pgdir_idx, 0, sizeof(pde_t));
f0101289:	83 ec 04             	sub    $0x4,%esp
f010128c:	6a 04                	push   $0x4
f010128e:	6a 00                	push   $0x0
f0101290:	56                   	push   %esi
f0101291:	e8 b0 40 00 00       	call   f0105346 <memset>
	return (pp - pages) << PGSHIFT;
f0101296:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f010129c:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010129f:	2b 08                	sub    (%eax),%ecx
f01012a1:	89 c8                	mov    %ecx,%eax
f01012a3:	c1 f8 03             	sar    $0x3,%eax
f01012a6:	c1 e0 0c             	shl    $0xc,%eax
		pgdir[pgdir_idx] = pgtable_phyaddr | PTE_P | PTE_W | PTE_U;	
f01012a9:	89 c2                	mov    %eax,%edx
f01012ab:	83 ca 07             	or     $0x7,%edx
f01012ae:	89 16                	mov    %edx,(%esi)
	if (PGNUM(pa) >= npages)
f01012b0:	89 c1                	mov    %eax,%ecx
f01012b2:	c1 e9 0c             	shr    $0xc,%ecx
f01012b5:	83 c4 10             	add    $0x10,%esp
f01012b8:	c7 c2 04 00 19 f0    	mov    $0xf0190004,%edx
f01012be:	3b 0a                	cmp    (%edx),%ecx
f01012c0:	73 0a                	jae    f01012cc <pgdir_walk+0xd8>
	return (void *)(pa + KERNBASE);
f01012c2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01012c7:	e9 79 ff ff ff       	jmp    f0101245 <pgdir_walk+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01012cc:	50                   	push   %eax
f01012cd:	8d 83 94 8f f7 ff    	lea    -0x8706c(%ebx),%eax
f01012d3:	50                   	push   %eax
f01012d4:	68 db 01 00 00       	push   $0x1db
f01012d9:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f01012df:	50                   	push   %eax
f01012e0:	e8 cc ed ff ff       	call   f01000b1 <_panic>
			return NULL;
f01012e5:	b8 00 00 00 00       	mov    $0x0,%eax
f01012ea:	e9 59 ff ff ff       	jmp    f0101248 <pgdir_walk+0x54>
f01012ef:	b8 00 00 00 00       	mov    $0x0,%eax
f01012f4:	e9 4f ff ff ff       	jmp    f0101248 <pgdir_walk+0x54>

f01012f9 <boot_map_region>:
{
f01012f9:	55                   	push   %ebp
f01012fa:	89 e5                	mov    %esp,%ebp
f01012fc:	57                   	push   %edi
f01012fd:	56                   	push   %esi
f01012fe:	53                   	push   %ebx
f01012ff:	83 ec 1c             	sub    $0x1c,%esp
f0101302:	e8 38 21 00 00       	call   f010343f <__x86.get_pc_thunk.di>
f0101307:	81 c7 19 bd 08 00    	add    $0x8bd19,%edi
f010130d:	89 7d d8             	mov    %edi,-0x28(%ebp)
f0101310:	89 45 e0             	mov    %eax,-0x20(%ebp)
	end = va + size;
f0101313:	8d 04 0a             	lea    (%edx,%ecx,1),%eax
f0101316:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	vir_p = va;
f0101319:	89 d3                	mov    %edx,%ebx
f010131b:	8b 7d 08             	mov    0x8(%ebp),%edi
f010131e:	29 d7                	sub    %edx,%edi
		*pte_p = phy_p | perm | PTE_P;
f0101320:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101323:	83 c8 01             	or     $0x1,%eax
f0101326:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101329:	8d 34 1f             	lea    (%edi,%ebx,1),%esi
		if (vir_p == end) {
f010132c:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f010132f:	74 63                	je     f0101394 <boot_map_region+0x9b>
		if ((pte_p = pgdir_walk(pgdir, (void *)vir_p, 1)) == NULL) {
f0101331:	83 ec 04             	sub    $0x4,%esp
f0101334:	6a 01                	push   $0x1
f0101336:	53                   	push   %ebx
f0101337:	ff 75 e0             	pushl  -0x20(%ebp)
f010133a:	e8 b5 fe ff ff       	call   f01011f4 <pgdir_walk>
f010133f:	83 c4 10             	add    $0x10,%esp
f0101342:	85 c0                	test   %eax,%eax
f0101344:	74 12                	je     f0101358 <boot_map_region+0x5f>
		if (*pte_p & PTE_P) {	// PTE already exist
f0101346:	f6 00 01             	testb  $0x1,(%eax)
f0101349:	75 2b                	jne    f0101376 <boot_map_region+0x7d>
		*pte_p = phy_p | perm | PTE_P;
f010134b:	0b 75 dc             	or     -0x24(%ebp),%esi
f010134e:	89 30                	mov    %esi,(%eax)
		vir_p += PGSIZE;
f0101350:	81 c3 00 10 00 00    	add    $0x1000,%ebx
		if (vir_p == end) {
f0101356:	eb d1                	jmp    f0101329 <boot_map_region+0x30>
			panic("pgdir_walk error");
f0101358:	83 ec 04             	sub    $0x4,%esp
f010135b:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f010135e:	8d 83 4f 8d f7 ff    	lea    -0x872b1(%ebx),%eax
f0101364:	50                   	push   %eax
f0101365:	68 fd 01 00 00       	push   $0x1fd
f010136a:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0101370:	50                   	push   %eax
f0101371:	e8 3b ed ff ff       	call   f01000b1 <_panic>
			panic("remap");
f0101376:	83 ec 04             	sub    $0x4,%esp
f0101379:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f010137c:	8d 83 60 8d f7 ff    	lea    -0x872a0(%ebx),%eax
f0101382:	50                   	push   %eax
f0101383:	68 02 02 00 00       	push   $0x202
f0101388:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f010138e:	50                   	push   %eax
f010138f:	e8 1d ed ff ff       	call   f01000b1 <_panic>
}
f0101394:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101397:	5b                   	pop    %ebx
f0101398:	5e                   	pop    %esi
f0101399:	5f                   	pop    %edi
f010139a:	5d                   	pop    %ebp
f010139b:	c3                   	ret    

f010139c <page_lookup>:
{
f010139c:	55                   	push   %ebp
f010139d:	89 e5                	mov    %esp,%ebp
f010139f:	56                   	push   %esi
f01013a0:	53                   	push   %ebx
f01013a1:	e8 c1 ed ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01013a6:	81 c3 7a bc 08 00    	add    $0x8bc7a,%ebx
f01013ac:	8b 75 10             	mov    0x10(%ebp),%esi
	pte_t *ret = pgdir_walk(pgdir, va, 0);
f01013af:	83 ec 04             	sub    $0x4,%esp
f01013b2:	6a 00                	push   $0x0
f01013b4:	ff 75 0c             	pushl  0xc(%ebp)
f01013b7:	ff 75 08             	pushl  0x8(%ebp)
f01013ba:	e8 35 fe ff ff       	call   f01011f4 <pgdir_walk>
	if (pte_store != 0) {
f01013bf:	83 c4 10             	add    $0x10,%esp
f01013c2:	85 f6                	test   %esi,%esi
f01013c4:	74 02                	je     f01013c8 <page_lookup+0x2c>
		*pte_store = ret;
f01013c6:	89 06                	mov    %eax,(%esi)
	if (ret && (*ret & PTE_P)) {
f01013c8:	85 c0                	test   %eax,%eax
f01013ca:	74 3d                	je     f0101409 <page_lookup+0x6d>
f01013cc:	8b 00                	mov    (%eax),%eax
f01013ce:	a8 01                	test   $0x1,%al
f01013d0:	74 3e                	je     f0101410 <page_lookup+0x74>
f01013d2:	c1 e8 0c             	shr    $0xc,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01013d5:	c7 c2 04 00 19 f0    	mov    $0xf0190004,%edx
f01013db:	39 02                	cmp    %eax,(%edx)
f01013dd:	76 12                	jbe    f01013f1 <page_lookup+0x55>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f01013df:	c7 c2 0c 00 19 f0    	mov    $0xf019000c,%edx
f01013e5:	8b 12                	mov    (%edx),%edx
f01013e7:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f01013ea:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01013ed:	5b                   	pop    %ebx
f01013ee:	5e                   	pop    %esi
f01013ef:	5d                   	pop    %ebp
f01013f0:	c3                   	ret    
		panic("pa2page called with invalid pa");
f01013f1:	83 ec 04             	sub    $0x4,%esp
f01013f4:	8d 83 c4 90 f7 ff    	lea    -0x86f3c(%ebx),%eax
f01013fa:	50                   	push   %eax
f01013fb:	6a 4f                	push   $0x4f
f01013fd:	8d 83 82 8c f7 ff    	lea    -0x8737e(%ebx),%eax
f0101403:	50                   	push   %eax
f0101404:	e8 a8 ec ff ff       	call   f01000b1 <_panic>
		return NULL;
f0101409:	b8 00 00 00 00       	mov    $0x0,%eax
f010140e:	eb da                	jmp    f01013ea <page_lookup+0x4e>
f0101410:	b8 00 00 00 00       	mov    $0x0,%eax
f0101415:	eb d3                	jmp    f01013ea <page_lookup+0x4e>

f0101417 <page_remove>:
{
f0101417:	55                   	push   %ebp
f0101418:	89 e5                	mov    %esp,%ebp
f010141a:	56                   	push   %esi
f010141b:	53                   	push   %ebx
f010141c:	83 ec 14             	sub    $0x14,%esp
f010141f:	e8 43 ed ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0101424:	81 c3 fc bb 08 00    	add    $0x8bbfc,%ebx
f010142a:	8b 75 0c             	mov    0xc(%ebp),%esi
	struct PageInfo *pginfo_p = page_lookup(pgdir, va, &pte_p);
f010142d:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101430:	50                   	push   %eax
f0101431:	56                   	push   %esi
f0101432:	ff 75 08             	pushl  0x8(%ebp)
f0101435:	e8 62 ff ff ff       	call   f010139c <page_lookup>
	if (pginfo_p) { // The virtual address is mapped
f010143a:	83 c4 10             	add    $0x10,%esp
f010143d:	85 c0                	test   %eax,%eax
f010143f:	74 26                	je     f0101467 <page_remove+0x50>
		page_decref(pginfo_p);
f0101441:	83 ec 0c             	sub    $0xc,%esp
f0101444:	50                   	push   %eax
f0101445:	e8 81 fd ff ff       	call   f01011cb <page_decref>
		if (pte_p) {
f010144a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010144d:	83 c4 10             	add    $0x10,%esp
f0101450:	85 c0                	test   %eax,%eax
f0101452:	74 13                	je     f0101467 <page_remove+0x50>
			memset(pte_p, 0, sizeof(pte_t));
f0101454:	83 ec 04             	sub    $0x4,%esp
f0101457:	6a 04                	push   $0x4
f0101459:	6a 00                	push   $0x0
f010145b:	50                   	push   %eax
f010145c:	e8 e5 3e 00 00       	call   f0105346 <memset>
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101461:	0f 01 3e             	invlpg (%esi)
f0101464:	83 c4 10             	add    $0x10,%esp
}
f0101467:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010146a:	5b                   	pop    %ebx
f010146b:	5e                   	pop    %esi
f010146c:	5d                   	pop    %ebp
f010146d:	c3                   	ret    

f010146e <page_insert>:
{
f010146e:	55                   	push   %ebp
f010146f:	89 e5                	mov    %esp,%ebp
f0101471:	57                   	push   %edi
f0101472:	56                   	push   %esi
f0101473:	53                   	push   %ebx
f0101474:	83 ec 10             	sub    $0x10,%esp
f0101477:	e8 c3 1f 00 00       	call   f010343f <__x86.get_pc_thunk.di>
f010147c:	81 c7 a4 bb 08 00    	add    $0x8bba4,%edi
f0101482:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t *pte_p = pgdir_walk(pgdir, va, 0); // NULL only if page table doesn't exist
f0101485:	6a 00                	push   $0x0
f0101487:	ff 75 10             	pushl  0x10(%ebp)
f010148a:	ff 75 08             	pushl  0x8(%ebp)
f010148d:	e8 62 fd ff ff       	call   f01011f4 <pgdir_walk>
	if (pte_p) {
f0101492:	83 c4 10             	add    $0x10,%esp
f0101495:	85 c0                	test   %eax,%eax
f0101497:	74 79                	je     f0101512 <page_insert+0xa4>
f0101499:	89 c3                	mov    %eax,%ebx
		if (*pte_p & PTE_P) {
f010149b:	8b 00                	mov    (%eax),%eax
f010149d:	a8 01                	test   $0x1,%al
f010149f:	74 2c                	je     f01014cd <page_insert+0x5f>
			if (PTE_ADDR(*pte_p) == page2pa(pp)) {	
f01014a1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	return (pp - pages) << PGSHIFT;
f01014a6:	c7 c2 0c 00 19 f0    	mov    $0xf019000c,%edx
f01014ac:	89 f1                	mov    %esi,%ecx
f01014ae:	2b 0a                	sub    (%edx),%ecx
f01014b0:	89 ca                	mov    %ecx,%edx
f01014b2:	c1 fa 03             	sar    $0x3,%edx
f01014b5:	c1 e2 0c             	shl    $0xc,%edx
f01014b8:	39 d0                	cmp    %edx,%eax
f01014ba:	74 45                	je     f0101501 <page_insert+0x93>
				page_remove(pgdir, va);
f01014bc:	83 ec 08             	sub    $0x8,%esp
f01014bf:	ff 75 10             	pushl  0x10(%ebp)
f01014c2:	ff 75 08             	pushl  0x8(%ebp)
f01014c5:	e8 4d ff ff ff       	call   f0101417 <page_remove>
f01014ca:	83 c4 10             	add    $0x10,%esp
f01014cd:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f01014d3:	89 f1                	mov    %esi,%ecx
f01014d5:	2b 08                	sub    (%eax),%ecx
f01014d7:	89 c8                	mov    %ecx,%eax
f01014d9:	c1 f8 03             	sar    $0x3,%eax
f01014dc:	c1 e0 0c             	shl    $0xc,%eax
	*pte_p = page2pa(pp) | perm | PTE_P;
f01014df:	8b 55 14             	mov    0x14(%ebp),%edx
f01014e2:	83 ca 01             	or     $0x1,%edx
f01014e5:	09 d0                	or     %edx,%eax
f01014e7:	89 03                	mov    %eax,(%ebx)
	++(pp->pp_ref);
f01014e9:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
f01014ee:	8b 45 10             	mov    0x10(%ebp),%eax
f01014f1:	0f 01 38             	invlpg (%eax)
	return 0;
f01014f4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01014f9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01014fc:	5b                   	pop    %ebx
f01014fd:	5e                   	pop    %esi
f01014fe:	5f                   	pop    %edi
f01014ff:	5d                   	pop    %ebp
f0101500:	c3                   	ret    
				*pte_p = page2pa(pp) | perm | PTE_P;
f0101501:	8b 55 14             	mov    0x14(%ebp),%edx
f0101504:	83 ca 01             	or     $0x1,%edx
f0101507:	09 d0                	or     %edx,%eax
f0101509:	89 03                	mov    %eax,(%ebx)
				return 0;
f010150b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101510:	eb e7                	jmp    f01014f9 <page_insert+0x8b>
		if ((pte_p = pgdir_walk(pgdir, va, 1)) == NULL) { // Try create page table
f0101512:	83 ec 04             	sub    $0x4,%esp
f0101515:	6a 01                	push   $0x1
f0101517:	ff 75 10             	pushl  0x10(%ebp)
f010151a:	ff 75 08             	pushl  0x8(%ebp)
f010151d:	e8 d2 fc ff ff       	call   f01011f4 <pgdir_walk>
f0101522:	89 c3                	mov    %eax,%ebx
f0101524:	83 c4 10             	add    $0x10,%esp
f0101527:	85 c0                	test   %eax,%eax
f0101529:	75 a2                	jne    f01014cd <page_insert+0x5f>
			return -E_NO_MEM;
f010152b:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0101530:	eb c7                	jmp    f01014f9 <page_insert+0x8b>

f0101532 <mem_init>:
{
f0101532:	55                   	push   %ebp
f0101533:	89 e5                	mov    %esp,%ebp
f0101535:	57                   	push   %edi
f0101536:	56                   	push   %esi
f0101537:	53                   	push   %ebx
f0101538:	83 ec 3c             	sub    $0x3c,%esp
f010153b:	e8 c9 f1 ff ff       	call   f0100709 <__x86.get_pc_thunk.ax>
f0101540:	05 e0 ba 08 00       	add    $0x8bae0,%eax
f0101545:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	basemem = nvram_read(NVRAM_BASELO);
f0101548:	b8 15 00 00 00       	mov    $0x15,%eax
f010154d:	e8 70 f5 ff ff       	call   f0100ac2 <nvram_read>
f0101552:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f0101554:	b8 17 00 00 00       	mov    $0x17,%eax
f0101559:	e8 64 f5 ff ff       	call   f0100ac2 <nvram_read>
f010155e:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f0101560:	b8 34 00 00 00       	mov    $0x34,%eax
f0101565:	e8 58 f5 ff ff       	call   f0100ac2 <nvram_read>
f010156a:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f010156d:	85 c0                	test   %eax,%eax
f010156f:	0f 85 f3 00 00 00    	jne    f0101668 <mem_init+0x136>
		totalmem = 1 * 1024 + extmem;
f0101575:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f010157b:	85 f6                	test   %esi,%esi
f010157d:	0f 44 c3             	cmove  %ebx,%eax
	npages = totalmem / (PGSIZE / 1024);	// npages = 32768
f0101580:	89 c1                	mov    %eax,%ecx
f0101582:	c1 e9 02             	shr    $0x2,%ecx
f0101585:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101588:	c7 c2 04 00 19 f0    	mov    $0xf0190004,%edx
f010158e:	89 0a                	mov    %ecx,(%edx)
	npages_basemem = basemem / (PGSIZE / 1024);
f0101590:	89 da                	mov    %ebx,%edx
f0101592:	c1 ea 02             	shr    $0x2,%edx
f0101595:	89 97 24 23 00 00    	mov    %edx,0x2324(%edi)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010159b:	89 c2                	mov    %eax,%edx
f010159d:	29 da                	sub    %ebx,%edx
f010159f:	52                   	push   %edx
f01015a0:	53                   	push   %ebx
f01015a1:	50                   	push   %eax
f01015a2:	8d 87 e4 90 f7 ff    	lea    -0x86f1c(%edi),%eax
f01015a8:	50                   	push   %eax
f01015a9:	89 fb                	mov    %edi,%ebx
f01015ab:	e8 0e 27 00 00       	call   f0103cbe <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01015b0:	b8 00 10 00 00       	mov    $0x1000,%eax
f01015b5:	e8 3e f5 ff ff       	call   f0100af8 <boot_alloc>
f01015ba:	c7 c6 08 00 19 f0    	mov    $0xf0190008,%esi
f01015c0:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);
f01015c2:	83 c4 0c             	add    $0xc,%esp
f01015c5:	68 00 10 00 00       	push   $0x1000
f01015ca:	6a 00                	push   $0x0
f01015cc:	50                   	push   %eax
f01015cd:	e8 74 3d 00 00       	call   f0105346 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01015d2:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f01015d4:	83 c4 10             	add    $0x10,%esp
f01015d7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01015dc:	0f 86 90 00 00 00    	jbe    f0101672 <mem_init+0x140>
	return (physaddr_t)kva - KERNBASE;
f01015e2:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01015e8:	83 ca 05             	or     $0x5,%edx
f01015eb:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = boot_alloc(npages * sizeof(struct PageInfo));
f01015f1:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01015f4:	c7 c3 04 00 19 f0    	mov    $0xf0190004,%ebx
f01015fa:	8b 03                	mov    (%ebx),%eax
f01015fc:	c1 e0 03             	shl    $0x3,%eax
f01015ff:	e8 f4 f4 ff ff       	call   f0100af8 <boot_alloc>
f0101604:	c7 c6 0c 00 19 f0    	mov    $0xf019000c,%esi
f010160a:	89 06                	mov    %eax,(%esi)
	memset(pages, 0, npages * sizeof(struct PageInfo));
f010160c:	83 ec 04             	sub    $0x4,%esp
f010160f:	8b 13                	mov    (%ebx),%edx
f0101611:	c1 e2 03             	shl    $0x3,%edx
f0101614:	52                   	push   %edx
f0101615:	6a 00                	push   $0x0
f0101617:	50                   	push   %eax
f0101618:	89 fb                	mov    %edi,%ebx
f010161a:	e8 27 3d 00 00       	call   f0105346 <memset>
	envs = boot_alloc(NENV * sizeof(struct Env));
f010161f:	b8 00 80 01 00       	mov    $0x18000,%eax
f0101624:	e8 cf f4 ff ff       	call   f0100af8 <boot_alloc>
f0101629:	c7 c2 4c f3 18 f0    	mov    $0xf018f34c,%edx
f010162f:	89 02                	mov    %eax,(%edx)
	memset(envs, 0, NENV * sizeof(struct Env));
f0101631:	83 c4 0c             	add    $0xc,%esp
f0101634:	68 00 80 01 00       	push   $0x18000
f0101639:	6a 00                	push   $0x0
f010163b:	50                   	push   %eax
f010163c:	e8 05 3d 00 00       	call   f0105346 <memset>
	page_init();
f0101641:	e8 26 f9 ff ff       	call   f0100f6c <page_init>
	check_page_free_list(1);
f0101646:	b8 01 00 00 00       	mov    $0x1,%eax
f010164b:	e8 99 f5 ff ff       	call   f0100be9 <check_page_free_list>
	if (!pages)
f0101650:	83 c4 10             	add    $0x10,%esp
f0101653:	83 3e 00             	cmpl   $0x0,(%esi)
f0101656:	74 36                	je     f010168e <mem_init+0x15c>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101658:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010165b:	8b 80 20 23 00 00    	mov    0x2320(%eax),%eax
f0101661:	be 00 00 00 00       	mov    $0x0,%esi
f0101666:	eb 49                	jmp    f01016b1 <mem_init+0x17f>
		totalmem = 16 * 1024 + ext16mem;
f0101668:	05 00 40 00 00       	add    $0x4000,%eax
f010166d:	e9 0e ff ff ff       	jmp    f0101580 <mem_init+0x4e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101672:	50                   	push   %eax
f0101673:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101676:	8d 83 a0 90 f7 ff    	lea    -0x86f60(%ebx),%eax
f010167c:	50                   	push   %eax
f010167d:	68 99 00 00 00       	push   $0x99
f0101682:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0101688:	50                   	push   %eax
f0101689:	e8 23 ea ff ff       	call   f01000b1 <_panic>
		panic("'pages' is a null pointer!");
f010168e:	83 ec 04             	sub    $0x4,%esp
f0101691:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101694:	8d 83 66 8d f7 ff    	lea    -0x8729a(%ebx),%eax
f010169a:	50                   	push   %eax
f010169b:	68 1d 03 00 00       	push   $0x31d
f01016a0:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f01016a6:	50                   	push   %eax
f01016a7:	e8 05 ea ff ff       	call   f01000b1 <_panic>
		++nfree;
f01016ac:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01016af:	8b 00                	mov    (%eax),%eax
f01016b1:	85 c0                	test   %eax,%eax
f01016b3:	75 f7                	jne    f01016ac <mem_init+0x17a>
	assert((pp0 = page_alloc(0)));
f01016b5:	83 ec 0c             	sub    $0xc,%esp
f01016b8:	6a 00                	push   $0x0
f01016ba:	e8 14 fa ff ff       	call   f01010d3 <page_alloc>
f01016bf:	89 c3                	mov    %eax,%ebx
f01016c1:	83 c4 10             	add    $0x10,%esp
f01016c4:	85 c0                	test   %eax,%eax
f01016c6:	0f 84 3b 02 00 00    	je     f0101907 <mem_init+0x3d5>
	assert((pp1 = page_alloc(0)));
f01016cc:	83 ec 0c             	sub    $0xc,%esp
f01016cf:	6a 00                	push   $0x0
f01016d1:	e8 fd f9 ff ff       	call   f01010d3 <page_alloc>
f01016d6:	89 c7                	mov    %eax,%edi
f01016d8:	83 c4 10             	add    $0x10,%esp
f01016db:	85 c0                	test   %eax,%eax
f01016dd:	0f 84 46 02 00 00    	je     f0101929 <mem_init+0x3f7>
	assert((pp2 = page_alloc(0)));
f01016e3:	83 ec 0c             	sub    $0xc,%esp
f01016e6:	6a 00                	push   $0x0
f01016e8:	e8 e6 f9 ff ff       	call   f01010d3 <page_alloc>
f01016ed:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01016f0:	83 c4 10             	add    $0x10,%esp
f01016f3:	85 c0                	test   %eax,%eax
f01016f5:	0f 84 50 02 00 00    	je     f010194b <mem_init+0x419>
	assert(pp1 && pp1 != pp0);
f01016fb:	39 fb                	cmp    %edi,%ebx
f01016fd:	0f 84 6a 02 00 00    	je     f010196d <mem_init+0x43b>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101703:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101706:	39 c7                	cmp    %eax,%edi
f0101708:	0f 84 81 02 00 00    	je     f010198f <mem_init+0x45d>
f010170e:	39 c3                	cmp    %eax,%ebx
f0101710:	0f 84 79 02 00 00    	je     f010198f <mem_init+0x45d>
	return (pp - pages) << PGSHIFT;
f0101716:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101719:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f010171f:	8b 08                	mov    (%eax),%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101721:	c7 c0 04 00 19 f0    	mov    $0xf0190004,%eax
f0101727:	8b 10                	mov    (%eax),%edx
f0101729:	c1 e2 0c             	shl    $0xc,%edx
f010172c:	89 d8                	mov    %ebx,%eax
f010172e:	29 c8                	sub    %ecx,%eax
f0101730:	c1 f8 03             	sar    $0x3,%eax
f0101733:	c1 e0 0c             	shl    $0xc,%eax
f0101736:	39 d0                	cmp    %edx,%eax
f0101738:	0f 83 73 02 00 00    	jae    f01019b1 <mem_init+0x47f>
f010173e:	89 f8                	mov    %edi,%eax
f0101740:	29 c8                	sub    %ecx,%eax
f0101742:	c1 f8 03             	sar    $0x3,%eax
f0101745:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f0101748:	39 c2                	cmp    %eax,%edx
f010174a:	0f 86 83 02 00 00    	jbe    f01019d3 <mem_init+0x4a1>
f0101750:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101753:	29 c8                	sub    %ecx,%eax
f0101755:	c1 f8 03             	sar    $0x3,%eax
f0101758:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f010175b:	39 c2                	cmp    %eax,%edx
f010175d:	0f 86 92 02 00 00    	jbe    f01019f5 <mem_init+0x4c3>
	fl = page_free_list;
f0101763:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101766:	8b 88 20 23 00 00    	mov    0x2320(%eax),%ecx
f010176c:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f010176f:	c7 80 20 23 00 00 00 	movl   $0x0,0x2320(%eax)
f0101776:	00 00 00 
	assert(!page_alloc(0));
f0101779:	83 ec 0c             	sub    $0xc,%esp
f010177c:	6a 00                	push   $0x0
f010177e:	e8 50 f9 ff ff       	call   f01010d3 <page_alloc>
f0101783:	83 c4 10             	add    $0x10,%esp
f0101786:	85 c0                	test   %eax,%eax
f0101788:	0f 85 89 02 00 00    	jne    f0101a17 <mem_init+0x4e5>
	page_free(pp0);
f010178e:	83 ec 0c             	sub    $0xc,%esp
f0101791:	53                   	push   %ebx
f0101792:	e8 ca f9 ff ff       	call   f0101161 <page_free>
	page_free(pp1);
f0101797:	89 3c 24             	mov    %edi,(%esp)
f010179a:	e8 c2 f9 ff ff       	call   f0101161 <page_free>
	page_free(pp2);
f010179f:	83 c4 04             	add    $0x4,%esp
f01017a2:	ff 75 d0             	pushl  -0x30(%ebp)
f01017a5:	e8 b7 f9 ff ff       	call   f0101161 <page_free>
	assert((pp0 = page_alloc(0)));
f01017aa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017b1:	e8 1d f9 ff ff       	call   f01010d3 <page_alloc>
f01017b6:	89 c7                	mov    %eax,%edi
f01017b8:	83 c4 10             	add    $0x10,%esp
f01017bb:	85 c0                	test   %eax,%eax
f01017bd:	0f 84 76 02 00 00    	je     f0101a39 <mem_init+0x507>
	assert((pp1 = page_alloc(0)));
f01017c3:	83 ec 0c             	sub    $0xc,%esp
f01017c6:	6a 00                	push   $0x0
f01017c8:	e8 06 f9 ff ff       	call   f01010d3 <page_alloc>
f01017cd:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01017d0:	83 c4 10             	add    $0x10,%esp
f01017d3:	85 c0                	test   %eax,%eax
f01017d5:	0f 84 80 02 00 00    	je     f0101a5b <mem_init+0x529>
	assert((pp2 = page_alloc(0)));
f01017db:	83 ec 0c             	sub    $0xc,%esp
f01017de:	6a 00                	push   $0x0
f01017e0:	e8 ee f8 ff ff       	call   f01010d3 <page_alloc>
f01017e5:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01017e8:	83 c4 10             	add    $0x10,%esp
f01017eb:	85 c0                	test   %eax,%eax
f01017ed:	0f 84 8a 02 00 00    	je     f0101a7d <mem_init+0x54b>
	assert(pp1 && pp1 != pp0);
f01017f3:	3b 7d d0             	cmp    -0x30(%ebp),%edi
f01017f6:	0f 84 a3 02 00 00    	je     f0101a9f <mem_init+0x56d>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01017fc:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01017ff:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101802:	0f 84 b9 02 00 00    	je     f0101ac1 <mem_init+0x58f>
f0101808:	39 c7                	cmp    %eax,%edi
f010180a:	0f 84 b1 02 00 00    	je     f0101ac1 <mem_init+0x58f>
	assert(!page_alloc(0));
f0101810:	83 ec 0c             	sub    $0xc,%esp
f0101813:	6a 00                	push   $0x0
f0101815:	e8 b9 f8 ff ff       	call   f01010d3 <page_alloc>
f010181a:	83 c4 10             	add    $0x10,%esp
f010181d:	85 c0                	test   %eax,%eax
f010181f:	0f 85 be 02 00 00    	jne    f0101ae3 <mem_init+0x5b1>
f0101825:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101828:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f010182e:	89 f9                	mov    %edi,%ecx
f0101830:	2b 08                	sub    (%eax),%ecx
f0101832:	89 c8                	mov    %ecx,%eax
f0101834:	c1 f8 03             	sar    $0x3,%eax
f0101837:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f010183a:	89 c1                	mov    %eax,%ecx
f010183c:	c1 e9 0c             	shr    $0xc,%ecx
f010183f:	c7 c2 04 00 19 f0    	mov    $0xf0190004,%edx
f0101845:	3b 0a                	cmp    (%edx),%ecx
f0101847:	0f 83 b8 02 00 00    	jae    f0101b05 <mem_init+0x5d3>
	memset(page2kva(pp0), 1, PGSIZE);
f010184d:	83 ec 04             	sub    $0x4,%esp
f0101850:	68 00 10 00 00       	push   $0x1000
f0101855:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0101857:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010185c:	50                   	push   %eax
f010185d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101860:	e8 e1 3a 00 00       	call   f0105346 <memset>
	page_free(pp0);
f0101865:	89 3c 24             	mov    %edi,(%esp)
f0101868:	e8 f4 f8 ff ff       	call   f0101161 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010186d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101874:	e8 5a f8 ff ff       	call   f01010d3 <page_alloc>
f0101879:	83 c4 10             	add    $0x10,%esp
f010187c:	85 c0                	test   %eax,%eax
f010187e:	0f 84 97 02 00 00    	je     f0101b1b <mem_init+0x5e9>
	assert(pp && pp0 == pp);
f0101884:	39 c7                	cmp    %eax,%edi
f0101886:	0f 85 b1 02 00 00    	jne    f0101b3d <mem_init+0x60b>
	return (pp - pages) << PGSHIFT;
f010188c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010188f:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0101895:	89 fa                	mov    %edi,%edx
f0101897:	2b 10                	sub    (%eax),%edx
f0101899:	c1 fa 03             	sar    $0x3,%edx
f010189c:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f010189f:	89 d1                	mov    %edx,%ecx
f01018a1:	c1 e9 0c             	shr    $0xc,%ecx
f01018a4:	c7 c0 04 00 19 f0    	mov    $0xf0190004,%eax
f01018aa:	3b 08                	cmp    (%eax),%ecx
f01018ac:	0f 83 ad 02 00 00    	jae    f0101b5f <mem_init+0x62d>
	return (void *)(pa + KERNBASE);
f01018b2:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f01018b8:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f01018be:	80 38 00             	cmpb   $0x0,(%eax)
f01018c1:	0f 85 ae 02 00 00    	jne    f0101b75 <mem_init+0x643>
f01018c7:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f01018ca:	39 d0                	cmp    %edx,%eax
f01018cc:	75 f0                	jne    f01018be <mem_init+0x38c>
	page_free_list = fl;
f01018ce:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018d1:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01018d4:	89 8b 20 23 00 00    	mov    %ecx,0x2320(%ebx)
	page_free(pp0);
f01018da:	83 ec 0c             	sub    $0xc,%esp
f01018dd:	57                   	push   %edi
f01018de:	e8 7e f8 ff ff       	call   f0101161 <page_free>
	page_free(pp1);
f01018e3:	83 c4 04             	add    $0x4,%esp
f01018e6:	ff 75 d0             	pushl  -0x30(%ebp)
f01018e9:	e8 73 f8 ff ff       	call   f0101161 <page_free>
	page_free(pp2);
f01018ee:	83 c4 04             	add    $0x4,%esp
f01018f1:	ff 75 cc             	pushl  -0x34(%ebp)
f01018f4:	e8 68 f8 ff ff       	call   f0101161 <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01018f9:	8b 83 20 23 00 00    	mov    0x2320(%ebx),%eax
f01018ff:	83 c4 10             	add    $0x10,%esp
f0101902:	e9 95 02 00 00       	jmp    f0101b9c <mem_init+0x66a>
	assert((pp0 = page_alloc(0)));
f0101907:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010190a:	8d 83 81 8d f7 ff    	lea    -0x8727f(%ebx),%eax
f0101910:	50                   	push   %eax
f0101911:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0101917:	50                   	push   %eax
f0101918:	68 25 03 00 00       	push   $0x325
f010191d:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0101923:	50                   	push   %eax
f0101924:	e8 88 e7 ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f0101929:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010192c:	8d 83 97 8d f7 ff    	lea    -0x87269(%ebx),%eax
f0101932:	50                   	push   %eax
f0101933:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0101939:	50                   	push   %eax
f010193a:	68 26 03 00 00       	push   $0x326
f010193f:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0101945:	50                   	push   %eax
f0101946:	e8 66 e7 ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f010194b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010194e:	8d 83 ad 8d f7 ff    	lea    -0x87253(%ebx),%eax
f0101954:	50                   	push   %eax
f0101955:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f010195b:	50                   	push   %eax
f010195c:	68 27 03 00 00       	push   $0x327
f0101961:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0101967:	50                   	push   %eax
f0101968:	e8 44 e7 ff ff       	call   f01000b1 <_panic>
	assert(pp1 && pp1 != pp0);
f010196d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101970:	8d 83 c3 8d f7 ff    	lea    -0x8723d(%ebx),%eax
f0101976:	50                   	push   %eax
f0101977:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f010197d:	50                   	push   %eax
f010197e:	68 2a 03 00 00       	push   $0x32a
f0101983:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0101989:	50                   	push   %eax
f010198a:	e8 22 e7 ff ff       	call   f01000b1 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010198f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101992:	8d 83 20 91 f7 ff    	lea    -0x86ee0(%ebx),%eax
f0101998:	50                   	push   %eax
f0101999:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f010199f:	50                   	push   %eax
f01019a0:	68 2b 03 00 00       	push   $0x32b
f01019a5:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f01019ab:	50                   	push   %eax
f01019ac:	e8 00 e7 ff ff       	call   f01000b1 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f01019b1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01019b4:	8d 83 d5 8d f7 ff    	lea    -0x8722b(%ebx),%eax
f01019ba:	50                   	push   %eax
f01019bb:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f01019c1:	50                   	push   %eax
f01019c2:	68 2c 03 00 00       	push   $0x32c
f01019c7:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f01019cd:	50                   	push   %eax
f01019ce:	e8 de e6 ff ff       	call   f01000b1 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f01019d3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01019d6:	8d 83 f2 8d f7 ff    	lea    -0x8720e(%ebx),%eax
f01019dc:	50                   	push   %eax
f01019dd:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f01019e3:	50                   	push   %eax
f01019e4:	68 2d 03 00 00       	push   $0x32d
f01019e9:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f01019ef:	50                   	push   %eax
f01019f0:	e8 bc e6 ff ff       	call   f01000b1 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f01019f5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01019f8:	8d 83 0f 8e f7 ff    	lea    -0x871f1(%ebx),%eax
f01019fe:	50                   	push   %eax
f01019ff:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0101a05:	50                   	push   %eax
f0101a06:	68 2e 03 00 00       	push   $0x32e
f0101a0b:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0101a11:	50                   	push   %eax
f0101a12:	e8 9a e6 ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f0101a17:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101a1a:	8d 83 2c 8e f7 ff    	lea    -0x871d4(%ebx),%eax
f0101a20:	50                   	push   %eax
f0101a21:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0101a27:	50                   	push   %eax
f0101a28:	68 35 03 00 00       	push   $0x335
f0101a2d:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0101a33:	50                   	push   %eax
f0101a34:	e8 78 e6 ff ff       	call   f01000b1 <_panic>
	assert((pp0 = page_alloc(0)));
f0101a39:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101a3c:	8d 83 81 8d f7 ff    	lea    -0x8727f(%ebx),%eax
f0101a42:	50                   	push   %eax
f0101a43:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0101a49:	50                   	push   %eax
f0101a4a:	68 3c 03 00 00       	push   $0x33c
f0101a4f:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0101a55:	50                   	push   %eax
f0101a56:	e8 56 e6 ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f0101a5b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101a5e:	8d 83 97 8d f7 ff    	lea    -0x87269(%ebx),%eax
f0101a64:	50                   	push   %eax
f0101a65:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0101a6b:	50                   	push   %eax
f0101a6c:	68 3d 03 00 00       	push   $0x33d
f0101a71:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0101a77:	50                   	push   %eax
f0101a78:	e8 34 e6 ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f0101a7d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101a80:	8d 83 ad 8d f7 ff    	lea    -0x87253(%ebx),%eax
f0101a86:	50                   	push   %eax
f0101a87:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0101a8d:	50                   	push   %eax
f0101a8e:	68 3e 03 00 00       	push   $0x33e
f0101a93:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0101a99:	50                   	push   %eax
f0101a9a:	e8 12 e6 ff ff       	call   f01000b1 <_panic>
	assert(pp1 && pp1 != pp0);
f0101a9f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101aa2:	8d 83 c3 8d f7 ff    	lea    -0x8723d(%ebx),%eax
f0101aa8:	50                   	push   %eax
f0101aa9:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0101aaf:	50                   	push   %eax
f0101ab0:	68 40 03 00 00       	push   $0x340
f0101ab5:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0101abb:	50                   	push   %eax
f0101abc:	e8 f0 e5 ff ff       	call   f01000b1 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101ac1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101ac4:	8d 83 20 91 f7 ff    	lea    -0x86ee0(%ebx),%eax
f0101aca:	50                   	push   %eax
f0101acb:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0101ad1:	50                   	push   %eax
f0101ad2:	68 41 03 00 00       	push   $0x341
f0101ad7:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0101add:	50                   	push   %eax
f0101ade:	e8 ce e5 ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f0101ae3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101ae6:	8d 83 2c 8e f7 ff    	lea    -0x871d4(%ebx),%eax
f0101aec:	50                   	push   %eax
f0101aed:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0101af3:	50                   	push   %eax
f0101af4:	68 42 03 00 00       	push   $0x342
f0101af9:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0101aff:	50                   	push   %eax
f0101b00:	e8 ac e5 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101b05:	50                   	push   %eax
f0101b06:	8d 83 94 8f f7 ff    	lea    -0x8706c(%ebx),%eax
f0101b0c:	50                   	push   %eax
f0101b0d:	6a 56                	push   $0x56
f0101b0f:	8d 83 82 8c f7 ff    	lea    -0x8737e(%ebx),%eax
f0101b15:	50                   	push   %eax
f0101b16:	e8 96 e5 ff ff       	call   f01000b1 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101b1b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101b1e:	8d 83 3b 8e f7 ff    	lea    -0x871c5(%ebx),%eax
f0101b24:	50                   	push   %eax
f0101b25:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0101b2b:	50                   	push   %eax
f0101b2c:	68 47 03 00 00       	push   $0x347
f0101b31:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0101b37:	50                   	push   %eax
f0101b38:	e8 74 e5 ff ff       	call   f01000b1 <_panic>
	assert(pp && pp0 == pp);
f0101b3d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101b40:	8d 83 59 8e f7 ff    	lea    -0x871a7(%ebx),%eax
f0101b46:	50                   	push   %eax
f0101b47:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0101b4d:	50                   	push   %eax
f0101b4e:	68 48 03 00 00       	push   $0x348
f0101b53:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0101b59:	50                   	push   %eax
f0101b5a:	e8 52 e5 ff ff       	call   f01000b1 <_panic>
f0101b5f:	52                   	push   %edx
f0101b60:	8d 83 94 8f f7 ff    	lea    -0x8706c(%ebx),%eax
f0101b66:	50                   	push   %eax
f0101b67:	6a 56                	push   $0x56
f0101b69:	8d 83 82 8c f7 ff    	lea    -0x8737e(%ebx),%eax
f0101b6f:	50                   	push   %eax
f0101b70:	e8 3c e5 ff ff       	call   f01000b1 <_panic>
		assert(c[i] == 0);
f0101b75:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101b78:	8d 83 69 8e f7 ff    	lea    -0x87197(%ebx),%eax
f0101b7e:	50                   	push   %eax
f0101b7f:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0101b85:	50                   	push   %eax
f0101b86:	68 4b 03 00 00       	push   $0x34b
f0101b8b:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0101b91:	50                   	push   %eax
f0101b92:	e8 1a e5 ff ff       	call   f01000b1 <_panic>
		--nfree;
f0101b97:	83 ee 01             	sub    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101b9a:	8b 00                	mov    (%eax),%eax
f0101b9c:	85 c0                	test   %eax,%eax
f0101b9e:	75 f7                	jne    f0101b97 <mem_init+0x665>
	assert(nfree == 0);
f0101ba0:	85 f6                	test   %esi,%esi
f0101ba2:	0f 85 6f 08 00 00    	jne    f0102417 <mem_init+0xee5>
	cprintf("check_page_alloc() succeeded!\n");
f0101ba8:	83 ec 0c             	sub    $0xc,%esp
f0101bab:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101bae:	8d 83 40 91 f7 ff    	lea    -0x86ec0(%ebx),%eax
f0101bb4:	50                   	push   %eax
f0101bb5:	e8 04 21 00 00       	call   f0103cbe <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101bba:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101bc1:	e8 0d f5 ff ff       	call   f01010d3 <page_alloc>
f0101bc6:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101bc9:	83 c4 10             	add    $0x10,%esp
f0101bcc:	85 c0                	test   %eax,%eax
f0101bce:	0f 84 65 08 00 00    	je     f0102439 <mem_init+0xf07>
	assert((pp1 = page_alloc(0)));
f0101bd4:	83 ec 0c             	sub    $0xc,%esp
f0101bd7:	6a 00                	push   $0x0
f0101bd9:	e8 f5 f4 ff ff       	call   f01010d3 <page_alloc>
f0101bde:	89 c7                	mov    %eax,%edi
f0101be0:	83 c4 10             	add    $0x10,%esp
f0101be3:	85 c0                	test   %eax,%eax
f0101be5:	0f 84 70 08 00 00    	je     f010245b <mem_init+0xf29>
	assert((pp2 = page_alloc(0)));
f0101beb:	83 ec 0c             	sub    $0xc,%esp
f0101bee:	6a 00                	push   $0x0
f0101bf0:	e8 de f4 ff ff       	call   f01010d3 <page_alloc>
f0101bf5:	89 c6                	mov    %eax,%esi
f0101bf7:	83 c4 10             	add    $0x10,%esp
f0101bfa:	85 c0                	test   %eax,%eax
f0101bfc:	0f 84 7b 08 00 00    	je     f010247d <mem_init+0xf4b>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101c02:	39 7d d0             	cmp    %edi,-0x30(%ebp)
f0101c05:	0f 84 94 08 00 00    	je     f010249f <mem_init+0xf6d>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101c0b:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101c0e:	0f 84 ad 08 00 00    	je     f01024c1 <mem_init+0xf8f>
f0101c14:	39 c7                	cmp    %eax,%edi
f0101c16:	0f 84 a5 08 00 00    	je     f01024c1 <mem_init+0xf8f>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101c1c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c1f:	8b 88 20 23 00 00    	mov    0x2320(%eax),%ecx
f0101c25:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f0101c28:	c7 80 20 23 00 00 00 	movl   $0x0,0x2320(%eax)
f0101c2f:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101c32:	83 ec 0c             	sub    $0xc,%esp
f0101c35:	6a 00                	push   $0x0
f0101c37:	e8 97 f4 ff ff       	call   f01010d3 <page_alloc>
f0101c3c:	83 c4 10             	add    $0x10,%esp
f0101c3f:	85 c0                	test   %eax,%eax
f0101c41:	0f 85 9c 08 00 00    	jne    f01024e3 <mem_init+0xfb1>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101c47:	83 ec 04             	sub    $0x4,%esp
f0101c4a:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101c4d:	50                   	push   %eax
f0101c4e:	6a 00                	push   $0x0
f0101c50:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c53:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f0101c59:	ff 30                	pushl  (%eax)
f0101c5b:	e8 3c f7 ff ff       	call   f010139c <page_lookup>
f0101c60:	83 c4 10             	add    $0x10,%esp
f0101c63:	85 c0                	test   %eax,%eax
f0101c65:	0f 85 9a 08 00 00    	jne    f0102505 <mem_init+0xfd3>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101c6b:	6a 02                	push   $0x2
f0101c6d:	6a 00                	push   $0x0
f0101c6f:	57                   	push   %edi
f0101c70:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c73:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f0101c79:	ff 30                	pushl  (%eax)
f0101c7b:	e8 ee f7 ff ff       	call   f010146e <page_insert>
f0101c80:	83 c4 10             	add    $0x10,%esp
f0101c83:	85 c0                	test   %eax,%eax
f0101c85:	0f 89 9c 08 00 00    	jns    f0102527 <mem_init+0xff5>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101c8b:	83 ec 0c             	sub    $0xc,%esp
f0101c8e:	ff 75 d0             	pushl  -0x30(%ebp)
f0101c91:	e8 cb f4 ff ff       	call   f0101161 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101c96:	6a 02                	push   $0x2
f0101c98:	6a 00                	push   $0x0
f0101c9a:	57                   	push   %edi
f0101c9b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c9e:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f0101ca4:	ff 30                	pushl  (%eax)
f0101ca6:	e8 c3 f7 ff ff       	call   f010146e <page_insert>
f0101cab:	83 c4 20             	add    $0x20,%esp
f0101cae:	85 c0                	test   %eax,%eax
f0101cb0:	0f 85 93 08 00 00    	jne    f0102549 <mem_init+0x1017>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101cb6:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101cb9:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f0101cbf:	8b 18                	mov    (%eax),%ebx
	return (pp - pages) << PGSHIFT;
f0101cc1:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0101cc7:	8b 08                	mov    (%eax),%ecx
f0101cc9:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0101ccc:	8b 13                	mov    (%ebx),%edx
f0101cce:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101cd4:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101cd7:	29 c8                	sub    %ecx,%eax
f0101cd9:	c1 f8 03             	sar    $0x3,%eax
f0101cdc:	c1 e0 0c             	shl    $0xc,%eax
f0101cdf:	39 c2                	cmp    %eax,%edx
f0101ce1:	0f 85 84 08 00 00    	jne    f010256b <mem_init+0x1039>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101ce7:	ba 00 00 00 00       	mov    $0x0,%edx
f0101cec:	89 d8                	mov    %ebx,%eax
f0101cee:	e8 79 ee ff ff       	call   f0100b6c <check_va2pa>
f0101cf3:	89 fa                	mov    %edi,%edx
f0101cf5:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101cf8:	c1 fa 03             	sar    $0x3,%edx
f0101cfb:	c1 e2 0c             	shl    $0xc,%edx
f0101cfe:	39 d0                	cmp    %edx,%eax
f0101d00:	0f 85 87 08 00 00    	jne    f010258d <mem_init+0x105b>
	assert(pp1->pp_ref == 1);
f0101d06:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101d0b:	0f 85 9e 08 00 00    	jne    f01025af <mem_init+0x107d>
	assert(pp0->pp_ref == 1);
f0101d11:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101d14:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101d19:	0f 85 b2 08 00 00    	jne    f01025d1 <mem_init+0x109f>

	// should be able to map pp2 at PGSIZE because 
	// pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101d1f:	6a 02                	push   $0x2
f0101d21:	68 00 10 00 00       	push   $0x1000
f0101d26:	56                   	push   %esi
f0101d27:	53                   	push   %ebx
f0101d28:	e8 41 f7 ff ff       	call   f010146e <page_insert>
f0101d2d:	83 c4 10             	add    $0x10,%esp
f0101d30:	85 c0                	test   %eax,%eax
f0101d32:	0f 85 bb 08 00 00    	jne    f01025f3 <mem_init+0x10c1>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101d38:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d3d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101d40:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f0101d46:	8b 00                	mov    (%eax),%eax
f0101d48:	e8 1f ee ff ff       	call   f0100b6c <check_va2pa>
f0101d4d:	c7 c2 0c 00 19 f0    	mov    $0xf019000c,%edx
f0101d53:	89 f1                	mov    %esi,%ecx
f0101d55:	2b 0a                	sub    (%edx),%ecx
f0101d57:	89 ca                	mov    %ecx,%edx
f0101d59:	c1 fa 03             	sar    $0x3,%edx
f0101d5c:	c1 e2 0c             	shl    $0xc,%edx
f0101d5f:	39 d0                	cmp    %edx,%eax
f0101d61:	0f 85 ae 08 00 00    	jne    f0102615 <mem_init+0x10e3>
	assert(pp2->pp_ref == 1);
f0101d67:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d6c:	0f 85 c5 08 00 00    	jne    f0102637 <mem_init+0x1105>

	// should be no free memory
	assert(!page_alloc(0));
f0101d72:	83 ec 0c             	sub    $0xc,%esp
f0101d75:	6a 00                	push   $0x0
f0101d77:	e8 57 f3 ff ff       	call   f01010d3 <page_alloc>
f0101d7c:	83 c4 10             	add    $0x10,%esp
f0101d7f:	85 c0                	test   %eax,%eax
f0101d81:	0f 85 d2 08 00 00    	jne    f0102659 <mem_init+0x1127>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101d87:	6a 02                	push   $0x2
f0101d89:	68 00 10 00 00       	push   $0x1000
f0101d8e:	56                   	push   %esi
f0101d8f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d92:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f0101d98:	ff 30                	pushl  (%eax)
f0101d9a:	e8 cf f6 ff ff       	call   f010146e <page_insert>
f0101d9f:	83 c4 10             	add    $0x10,%esp
f0101da2:	85 c0                	test   %eax,%eax
f0101da4:	0f 85 d1 08 00 00    	jne    f010267b <mem_init+0x1149>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101daa:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101daf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101db2:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f0101db8:	8b 00                	mov    (%eax),%eax
f0101dba:	e8 ad ed ff ff       	call   f0100b6c <check_va2pa>
f0101dbf:	c7 c2 0c 00 19 f0    	mov    $0xf019000c,%edx
f0101dc5:	89 f1                	mov    %esi,%ecx
f0101dc7:	2b 0a                	sub    (%edx),%ecx
f0101dc9:	89 ca                	mov    %ecx,%edx
f0101dcb:	c1 fa 03             	sar    $0x3,%edx
f0101dce:	c1 e2 0c             	shl    $0xc,%edx
f0101dd1:	39 d0                	cmp    %edx,%eax
f0101dd3:	0f 85 c4 08 00 00    	jne    f010269d <mem_init+0x116b>
	assert(pp2->pp_ref == 1);
f0101dd9:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101dde:	0f 85 db 08 00 00    	jne    f01026bf <mem_init+0x118d>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101de4:	83 ec 0c             	sub    $0xc,%esp
f0101de7:	6a 00                	push   $0x0
f0101de9:	e8 e5 f2 ff ff       	call   f01010d3 <page_alloc>
f0101dee:	83 c4 10             	add    $0x10,%esp
f0101df1:	85 c0                	test   %eax,%eax
f0101df3:	0f 85 e8 08 00 00    	jne    f01026e1 <mem_init+0x11af>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101df9:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101dfc:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f0101e02:	8b 10                	mov    (%eax),%edx
f0101e04:	8b 02                	mov    (%edx),%eax
f0101e06:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101e0b:	89 c3                	mov    %eax,%ebx
f0101e0d:	c1 eb 0c             	shr    $0xc,%ebx
f0101e10:	c7 c1 04 00 19 f0    	mov    $0xf0190004,%ecx
f0101e16:	3b 19                	cmp    (%ecx),%ebx
f0101e18:	0f 83 e5 08 00 00    	jae    f0102703 <mem_init+0x11d1>
	return (void *)(pa + KERNBASE);
f0101e1e:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101e23:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101e26:	83 ec 04             	sub    $0x4,%esp
f0101e29:	6a 00                	push   $0x0
f0101e2b:	68 00 10 00 00       	push   $0x1000
f0101e30:	52                   	push   %edx
f0101e31:	e8 be f3 ff ff       	call   f01011f4 <pgdir_walk>
f0101e36:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101e39:	8d 51 04             	lea    0x4(%ecx),%edx
f0101e3c:	83 c4 10             	add    $0x10,%esp
f0101e3f:	39 d0                	cmp    %edx,%eax
f0101e41:	0f 85 d8 08 00 00    	jne    f010271f <mem_init+0x11ed>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101e47:	6a 06                	push   $0x6
f0101e49:	68 00 10 00 00       	push   $0x1000
f0101e4e:	56                   	push   %esi
f0101e4f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e52:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f0101e58:	ff 30                	pushl  (%eax)
f0101e5a:	e8 0f f6 ff ff       	call   f010146e <page_insert>
f0101e5f:	83 c4 10             	add    $0x10,%esp
f0101e62:	85 c0                	test   %eax,%eax
f0101e64:	0f 85 d7 08 00 00    	jne    f0102741 <mem_init+0x120f>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101e6a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e6d:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f0101e73:	8b 18                	mov    (%eax),%ebx
f0101e75:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e7a:	89 d8                	mov    %ebx,%eax
f0101e7c:	e8 eb ec ff ff       	call   f0100b6c <check_va2pa>
	return (pp - pages) << PGSHIFT;
f0101e81:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101e84:	c7 c2 0c 00 19 f0    	mov    $0xf019000c,%edx
f0101e8a:	89 f1                	mov    %esi,%ecx
f0101e8c:	2b 0a                	sub    (%edx),%ecx
f0101e8e:	89 ca                	mov    %ecx,%edx
f0101e90:	c1 fa 03             	sar    $0x3,%edx
f0101e93:	c1 e2 0c             	shl    $0xc,%edx
f0101e96:	39 d0                	cmp    %edx,%eax
f0101e98:	0f 85 c5 08 00 00    	jne    f0102763 <mem_init+0x1231>
	assert(pp2->pp_ref == 1);
f0101e9e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ea3:	0f 85 dc 08 00 00    	jne    f0102785 <mem_init+0x1253>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101ea9:	83 ec 04             	sub    $0x4,%esp
f0101eac:	6a 00                	push   $0x0
f0101eae:	68 00 10 00 00       	push   $0x1000
f0101eb3:	53                   	push   %ebx
f0101eb4:	e8 3b f3 ff ff       	call   f01011f4 <pgdir_walk>
f0101eb9:	83 c4 10             	add    $0x10,%esp
f0101ebc:	f6 00 04             	testb  $0x4,(%eax)
f0101ebf:	0f 84 e2 08 00 00    	je     f01027a7 <mem_init+0x1275>
	assert(kern_pgdir[0] & PTE_U);
f0101ec5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ec8:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f0101ece:	8b 00                	mov    (%eax),%eax
f0101ed0:	f6 00 04             	testb  $0x4,(%eax)
f0101ed3:	0f 84 f0 08 00 00    	je     f01027c9 <mem_init+0x1297>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101ed9:	6a 02                	push   $0x2
f0101edb:	68 00 10 00 00       	push   $0x1000
f0101ee0:	56                   	push   %esi
f0101ee1:	50                   	push   %eax
f0101ee2:	e8 87 f5 ff ff       	call   f010146e <page_insert>
f0101ee7:	83 c4 10             	add    $0x10,%esp
f0101eea:	85 c0                	test   %eax,%eax
f0101eec:	0f 85 f9 08 00 00    	jne    f01027eb <mem_init+0x12b9>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101ef2:	83 ec 04             	sub    $0x4,%esp
f0101ef5:	6a 00                	push   $0x0
f0101ef7:	68 00 10 00 00       	push   $0x1000
f0101efc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101eff:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f0101f05:	ff 30                	pushl  (%eax)
f0101f07:	e8 e8 f2 ff ff       	call   f01011f4 <pgdir_walk>
f0101f0c:	83 c4 10             	add    $0x10,%esp
f0101f0f:	f6 00 02             	testb  $0x2,(%eax)
f0101f12:	0f 84 f5 08 00 00    	je     f010280d <mem_init+0x12db>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101f18:	83 ec 04             	sub    $0x4,%esp
f0101f1b:	6a 00                	push   $0x0
f0101f1d:	68 00 10 00 00       	push   $0x1000
f0101f22:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f25:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f0101f2b:	ff 30                	pushl  (%eax)
f0101f2d:	e8 c2 f2 ff ff       	call   f01011f4 <pgdir_walk>
f0101f32:	83 c4 10             	add    $0x10,%esp
f0101f35:	f6 00 04             	testb  $0x4,(%eax)
f0101f38:	0f 85 f1 08 00 00    	jne    f010282f <mem_init+0x12fd>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101f3e:	6a 02                	push   $0x2
f0101f40:	68 00 00 40 00       	push   $0x400000
f0101f45:	ff 75 d0             	pushl  -0x30(%ebp)
f0101f48:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f4b:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f0101f51:	ff 30                	pushl  (%eax)
f0101f53:	e8 16 f5 ff ff       	call   f010146e <page_insert>
f0101f58:	83 c4 10             	add    $0x10,%esp
f0101f5b:	85 c0                	test   %eax,%eax
f0101f5d:	0f 89 ee 08 00 00    	jns    f0102851 <mem_init+0x131f>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101f63:	6a 02                	push   $0x2
f0101f65:	68 00 10 00 00       	push   $0x1000
f0101f6a:	57                   	push   %edi
f0101f6b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f6e:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f0101f74:	ff 30                	pushl  (%eax)
f0101f76:	e8 f3 f4 ff ff       	call   f010146e <page_insert>
f0101f7b:	83 c4 10             	add    $0x10,%esp
f0101f7e:	85 c0                	test   %eax,%eax
f0101f80:	0f 85 ed 08 00 00    	jne    f0102873 <mem_init+0x1341>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101f86:	83 ec 04             	sub    $0x4,%esp
f0101f89:	6a 00                	push   $0x0
f0101f8b:	68 00 10 00 00       	push   $0x1000
f0101f90:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f93:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f0101f99:	ff 30                	pushl  (%eax)
f0101f9b:	e8 54 f2 ff ff       	call   f01011f4 <pgdir_walk>
f0101fa0:	83 c4 10             	add    $0x10,%esp
f0101fa3:	f6 00 04             	testb  $0x4,(%eax)
f0101fa6:	0f 85 e9 08 00 00    	jne    f0102895 <mem_init+0x1363>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101fac:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101faf:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f0101fb5:	8b 18                	mov    (%eax),%ebx
f0101fb7:	ba 00 00 00 00       	mov    $0x0,%edx
f0101fbc:	89 d8                	mov    %ebx,%eax
f0101fbe:	e8 a9 eb ff ff       	call   f0100b6c <check_va2pa>
f0101fc3:	89 c2                	mov    %eax,%edx
f0101fc5:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101fc8:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101fcb:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0101fd1:	89 f9                	mov    %edi,%ecx
f0101fd3:	2b 08                	sub    (%eax),%ecx
f0101fd5:	89 c8                	mov    %ecx,%eax
f0101fd7:	c1 f8 03             	sar    $0x3,%eax
f0101fda:	c1 e0 0c             	shl    $0xc,%eax
f0101fdd:	39 c2                	cmp    %eax,%edx
f0101fdf:	0f 85 d2 08 00 00    	jne    f01028b7 <mem_init+0x1385>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101fe5:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fea:	89 d8                	mov    %ebx,%eax
f0101fec:	e8 7b eb ff ff       	call   f0100b6c <check_va2pa>
f0101ff1:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101ff4:	0f 85 df 08 00 00    	jne    f01028d9 <mem_init+0x13a7>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101ffa:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0101fff:	0f 85 f6 08 00 00    	jne    f01028fb <mem_init+0x13c9>
	assert(pp2->pp_ref == 0);
f0102005:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010200a:	0f 85 0d 09 00 00    	jne    f010291d <mem_init+0x13eb>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102010:	83 ec 0c             	sub    $0xc,%esp
f0102013:	6a 00                	push   $0x0
f0102015:	e8 b9 f0 ff ff       	call   f01010d3 <page_alloc>
f010201a:	83 c4 10             	add    $0x10,%esp
f010201d:	39 c6                	cmp    %eax,%esi
f010201f:	0f 85 1a 09 00 00    	jne    f010293f <mem_init+0x140d>
f0102025:	85 c0                	test   %eax,%eax
f0102027:	0f 84 12 09 00 00    	je     f010293f <mem_init+0x140d>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f010202d:	83 ec 08             	sub    $0x8,%esp
f0102030:	6a 00                	push   $0x0
f0102032:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102035:	c7 c3 08 00 19 f0    	mov    $0xf0190008,%ebx
f010203b:	ff 33                	pushl  (%ebx)
f010203d:	e8 d5 f3 ff ff       	call   f0101417 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102042:	8b 1b                	mov    (%ebx),%ebx
f0102044:	ba 00 00 00 00       	mov    $0x0,%edx
f0102049:	89 d8                	mov    %ebx,%eax
f010204b:	e8 1c eb ff ff       	call   f0100b6c <check_va2pa>
f0102050:	83 c4 10             	add    $0x10,%esp
f0102053:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102056:	0f 85 05 09 00 00    	jne    f0102961 <mem_init+0x142f>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010205c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102061:	89 d8                	mov    %ebx,%eax
f0102063:	e8 04 eb ff ff       	call   f0100b6c <check_va2pa>
f0102068:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010206b:	c7 c2 0c 00 19 f0    	mov    $0xf019000c,%edx
f0102071:	89 f9                	mov    %edi,%ecx
f0102073:	2b 0a                	sub    (%edx),%ecx
f0102075:	89 ca                	mov    %ecx,%edx
f0102077:	c1 fa 03             	sar    $0x3,%edx
f010207a:	c1 e2 0c             	shl    $0xc,%edx
f010207d:	39 d0                	cmp    %edx,%eax
f010207f:	0f 85 fe 08 00 00    	jne    f0102983 <mem_init+0x1451>
	assert(pp1->pp_ref == 1);
f0102085:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f010208a:	0f 85 15 09 00 00    	jne    f01029a5 <mem_init+0x1473>
	assert(pp2->pp_ref == 0);
f0102090:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102095:	0f 85 2c 09 00 00    	jne    f01029c7 <mem_init+0x1495>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f010209b:	6a 00                	push   $0x0
f010209d:	68 00 10 00 00       	push   $0x1000
f01020a2:	57                   	push   %edi
f01020a3:	53                   	push   %ebx
f01020a4:	e8 c5 f3 ff ff       	call   f010146e <page_insert>
f01020a9:	83 c4 10             	add    $0x10,%esp
f01020ac:	85 c0                	test   %eax,%eax
f01020ae:	0f 85 35 09 00 00    	jne    f01029e9 <mem_init+0x14b7>
	assert(pp1->pp_ref);
f01020b4:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01020b9:	0f 84 4c 09 00 00    	je     f0102a0b <mem_init+0x14d9>
	assert(pp1->pp_link == NULL);
f01020bf:	83 3f 00             	cmpl   $0x0,(%edi)
f01020c2:	0f 85 65 09 00 00    	jne    f0102a2d <mem_init+0x14fb>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01020c8:	83 ec 08             	sub    $0x8,%esp
f01020cb:	68 00 10 00 00       	push   $0x1000
f01020d0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020d3:	c7 c3 08 00 19 f0    	mov    $0xf0190008,%ebx
f01020d9:	ff 33                	pushl  (%ebx)
f01020db:	e8 37 f3 ff ff       	call   f0101417 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01020e0:	8b 1b                	mov    (%ebx),%ebx
f01020e2:	ba 00 00 00 00       	mov    $0x0,%edx
f01020e7:	89 d8                	mov    %ebx,%eax
f01020e9:	e8 7e ea ff ff       	call   f0100b6c <check_va2pa>
f01020ee:	83 c4 10             	add    $0x10,%esp
f01020f1:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020f4:	0f 85 55 09 00 00    	jne    f0102a4f <mem_init+0x151d>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01020fa:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020ff:	89 d8                	mov    %ebx,%eax
f0102101:	e8 66 ea ff ff       	call   f0100b6c <check_va2pa>
f0102106:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102109:	0f 85 62 09 00 00    	jne    f0102a71 <mem_init+0x153f>
	assert(pp1->pp_ref == 0);
f010210f:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102114:	0f 85 79 09 00 00    	jne    f0102a93 <mem_init+0x1561>
	assert(pp2->pp_ref == 0);
f010211a:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010211f:	0f 85 90 09 00 00    	jne    f0102ab5 <mem_init+0x1583>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102125:	83 ec 0c             	sub    $0xc,%esp
f0102128:	6a 00                	push   $0x0
f010212a:	e8 a4 ef ff ff       	call   f01010d3 <page_alloc>
f010212f:	83 c4 10             	add    $0x10,%esp
f0102132:	85 c0                	test   %eax,%eax
f0102134:	0f 84 9d 09 00 00    	je     f0102ad7 <mem_init+0x15a5>
f010213a:	39 c7                	cmp    %eax,%edi
f010213c:	0f 85 95 09 00 00    	jne    f0102ad7 <mem_init+0x15a5>

	// should be no free memory
	assert(!page_alloc(0));
f0102142:	83 ec 0c             	sub    $0xc,%esp
f0102145:	6a 00                	push   $0x0
f0102147:	e8 87 ef ff ff       	call   f01010d3 <page_alloc>
f010214c:	83 c4 10             	add    $0x10,%esp
f010214f:	85 c0                	test   %eax,%eax
f0102151:	0f 85 a2 09 00 00    	jne    f0102af9 <mem_init+0x15c7>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102157:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010215a:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f0102160:	8b 08                	mov    (%eax),%ecx
f0102162:	8b 11                	mov    (%ecx),%edx
f0102164:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010216a:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0102170:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0102173:	2b 18                	sub    (%eax),%ebx
f0102175:	89 d8                	mov    %ebx,%eax
f0102177:	c1 f8 03             	sar    $0x3,%eax
f010217a:	c1 e0 0c             	shl    $0xc,%eax
f010217d:	39 c2                	cmp    %eax,%edx
f010217f:	0f 85 96 09 00 00    	jne    f0102b1b <mem_init+0x15e9>
	kern_pgdir[0] = 0;
f0102185:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010218b:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010218e:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0102193:	0f 85 a4 09 00 00    	jne    f0102b3d <mem_init+0x160b>
	pp0->pp_ref = 0;
f0102199:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010219c:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01021a2:	83 ec 0c             	sub    $0xc,%esp
f01021a5:	50                   	push   %eax
f01021a6:	e8 b6 ef ff ff       	call   f0101161 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01021ab:	83 c4 0c             	add    $0xc,%esp
f01021ae:	6a 01                	push   $0x1
f01021b0:	68 00 10 40 00       	push   $0x401000
f01021b5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021b8:	c7 c3 08 00 19 f0    	mov    $0xf0190008,%ebx
f01021be:	ff 33                	pushl  (%ebx)
f01021c0:	e8 2f f0 ff ff       	call   f01011f4 <pgdir_walk>
f01021c5:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01021c8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01021cb:	8b 1b                	mov    (%ebx),%ebx
f01021cd:	8b 53 04             	mov    0x4(%ebx),%edx
f01021d0:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f01021d6:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01021d9:	c7 c1 04 00 19 f0    	mov    $0xf0190004,%ecx
f01021df:	8b 09                	mov    (%ecx),%ecx
f01021e1:	89 d0                	mov    %edx,%eax
f01021e3:	c1 e8 0c             	shr    $0xc,%eax
f01021e6:	83 c4 10             	add    $0x10,%esp
f01021e9:	39 c8                	cmp    %ecx,%eax
f01021eb:	0f 83 6e 09 00 00    	jae    f0102b5f <mem_init+0x162d>
	assert(ptep == ptep1 + PTX(va));
f01021f1:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f01021f7:	39 55 cc             	cmp    %edx,-0x34(%ebp)
f01021fa:	0f 85 7b 09 00 00    	jne    f0102b7b <mem_init+0x1649>
	kern_pgdir[PDX(va)] = 0;
f0102200:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	pp0->pp_ref = 0;
f0102207:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f010220a:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return (pp - pages) << PGSHIFT;
f0102210:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102213:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0102219:	2b 18                	sub    (%eax),%ebx
f010221b:	89 d8                	mov    %ebx,%eax
f010221d:	c1 f8 03             	sar    $0x3,%eax
f0102220:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102223:	89 c2                	mov    %eax,%edx
f0102225:	c1 ea 0c             	shr    $0xc,%edx
f0102228:	39 d1                	cmp    %edx,%ecx
f010222a:	0f 86 6d 09 00 00    	jbe    f0102b9d <mem_init+0x166b>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102230:	83 ec 04             	sub    $0x4,%esp
f0102233:	68 00 10 00 00       	push   $0x1000
f0102238:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f010223d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102242:	50                   	push   %eax
f0102243:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102246:	e8 fb 30 00 00       	call   f0105346 <memset>
	page_free(pp0);
f010224b:	83 c4 04             	add    $0x4,%esp
f010224e:	ff 75 d0             	pushl  -0x30(%ebp)
f0102251:	e8 0b ef ff ff       	call   f0101161 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102256:	83 c4 0c             	add    $0xc,%esp
f0102259:	6a 01                	push   $0x1
f010225b:	6a 00                	push   $0x0
f010225d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102260:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f0102266:	ff 30                	pushl  (%eax)
f0102268:	e8 87 ef ff ff       	call   f01011f4 <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f010226d:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0102273:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0102276:	2b 10                	sub    (%eax),%edx
f0102278:	c1 fa 03             	sar    $0x3,%edx
f010227b:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f010227e:	89 d1                	mov    %edx,%ecx
f0102280:	c1 e9 0c             	shr    $0xc,%ecx
f0102283:	83 c4 10             	add    $0x10,%esp
f0102286:	c7 c0 04 00 19 f0    	mov    $0xf0190004,%eax
f010228c:	3b 08                	cmp    (%eax),%ecx
f010228e:	0f 83 22 09 00 00    	jae    f0102bb6 <mem_init+0x1684>
	return (void *)(pa + KERNBASE);
f0102294:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010229a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010229d:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01022a3:	f6 00 01             	testb  $0x1,(%eax)
f01022a6:	0f 85 23 09 00 00    	jne    f0102bcf <mem_init+0x169d>
f01022ac:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f01022af:	39 d0                	cmp    %edx,%eax
f01022b1:	75 f0                	jne    f01022a3 <mem_init+0xd71>
	kern_pgdir[0] = 0;
f01022b3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022b6:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f01022bc:	8b 00                	mov    (%eax),%eax
f01022be:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f01022c4:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01022c7:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f01022cd:	8b 55 c8             	mov    -0x38(%ebp),%edx
f01022d0:	89 93 20 23 00 00    	mov    %edx,0x2320(%ebx)

	// free the pages we took
	page_free(pp0);
f01022d6:	83 ec 0c             	sub    $0xc,%esp
f01022d9:	50                   	push   %eax
f01022da:	e8 82 ee ff ff       	call   f0101161 <page_free>
	page_free(pp1);
f01022df:	89 3c 24             	mov    %edi,(%esp)
f01022e2:	e8 7a ee ff ff       	call   f0101161 <page_free>
	page_free(pp2);
f01022e7:	89 34 24             	mov    %esi,(%esp)
f01022ea:	e8 72 ee ff ff       	call   f0101161 <page_free>

	cprintf("check_page() succeeded!\n");
f01022ef:	8d 83 4a 8f f7 ff    	lea    -0x870b6(%ebx),%eax
f01022f5:	89 04 24             	mov    %eax,(%esp)
f01022f8:	e8 c1 19 00 00       	call   f0103cbe <cprintf>
	boot_map_region(kern_pgdir, 
f01022fd:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0102303:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102305:	83 c4 10             	add    $0x10,%esp
f0102308:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010230d:	0f 86 de 08 00 00    	jbe    f0102bf1 <mem_init+0x16bf>
					ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE), 
f0102313:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102316:	c7 c2 04 00 19 f0    	mov    $0xf0190004,%edx
f010231c:	8b 12                	mov    (%edx),%edx
f010231e:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
	boot_map_region(kern_pgdir, 
f0102325:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f010232b:	83 ec 08             	sub    $0x8,%esp
f010232e:	6a 05                	push   $0x5
	return (physaddr_t)kva - KERNBASE;
f0102330:	05 00 00 00 10       	add    $0x10000000,%eax
f0102335:	50                   	push   %eax
f0102336:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f010233b:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f0102341:	8b 00                	mov    (%eax),%eax
f0102343:	e8 b1 ef ff ff       	call   f01012f9 <boot_map_region>
	boot_map_region(kern_pgdir,
f0102348:	c7 c0 4c f3 18 f0    	mov    $0xf018f34c,%eax
f010234e:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102350:	83 c4 10             	add    $0x10,%esp
f0102353:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102358:	0f 86 af 08 00 00    	jbe    f0102c0d <mem_init+0x16db>
f010235e:	83 ec 08             	sub    $0x8,%esp
f0102361:	6a 05                	push   $0x5
	return (physaddr_t)kva - KERNBASE;
f0102363:	05 00 00 00 10       	add    $0x10000000,%eax
f0102368:	50                   	push   %eax
f0102369:	b9 00 80 01 00       	mov    $0x18000,%ecx
f010236e:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102373:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0102376:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f010237c:	8b 00                	mov    (%eax),%eax
f010237e:	e8 76 ef ff ff       	call   f01012f9 <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f0102383:	c7 c0 00 30 11 f0    	mov    $0xf0113000,%eax
f0102389:	89 45 c8             	mov    %eax,-0x38(%ebp)
f010238c:	83 c4 10             	add    $0x10,%esp
f010238f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102394:	0f 86 8f 08 00 00    	jbe    f0102c29 <mem_init+0x16f7>
	boot_map_region(kern_pgdir,
f010239a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010239d:	c7 c3 08 00 19 f0    	mov    $0xf0190008,%ebx
f01023a3:	83 ec 08             	sub    $0x8,%esp
f01023a6:	6a 03                	push   $0x3
	return (physaddr_t)kva - KERNBASE;
f01023a8:	8b 45 c8             	mov    -0x38(%ebp),%eax
f01023ab:	05 00 00 00 10       	add    $0x10000000,%eax
f01023b0:	50                   	push   %eax
f01023b1:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01023b6:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f01023bb:	8b 03                	mov    (%ebx),%eax
f01023bd:	e8 37 ef ff ff       	call   f01012f9 <boot_map_region>
	boot_map_region(kern_pgdir,
f01023c2:	83 c4 08             	add    $0x8,%esp
f01023c5:	6a 03                	push   $0x3
f01023c7:	6a 00                	push   $0x0
f01023c9:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01023ce:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01023d3:	8b 03                	mov    (%ebx),%eax
f01023d5:	e8 1f ef ff ff       	call   f01012f9 <boot_map_region>
	pgdir = kern_pgdir;
f01023da:	8b 33                	mov    (%ebx),%esi
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f01023dc:	c7 c0 04 00 19 f0    	mov    $0xf0190004,%eax
f01023e2:	8b 00                	mov    (%eax),%eax
f01023e4:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f01023e7:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f01023ee:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01023f3:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01023f6:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f01023fc:	8b 00                	mov    (%eax),%eax
f01023fe:	89 45 c0             	mov    %eax,-0x40(%ebp)
	if ((uint32_t)kva < KERNBASE)
f0102401:	89 45 cc             	mov    %eax,-0x34(%ebp)
	return (physaddr_t)kva - KERNBASE;
f0102404:	8d b8 00 00 00 10    	lea    0x10000000(%eax),%edi
f010240a:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < n; i += PGSIZE)
f010240d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102412:	e9 57 08 00 00       	jmp    f0102c6e <mem_init+0x173c>
	assert(nfree == 0);
f0102417:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010241a:	8d 83 73 8e f7 ff    	lea    -0x8718d(%ebx),%eax
f0102420:	50                   	push   %eax
f0102421:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102427:	50                   	push   %eax
f0102428:	68 58 03 00 00       	push   $0x358
f010242d:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102433:	50                   	push   %eax
f0102434:	e8 78 dc ff ff       	call   f01000b1 <_panic>
	assert((pp0 = page_alloc(0)));
f0102439:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010243c:	8d 83 81 8d f7 ff    	lea    -0x8727f(%ebx),%eax
f0102442:	50                   	push   %eax
f0102443:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102449:	50                   	push   %eax
f010244a:	68 b5 03 00 00       	push   $0x3b5
f010244f:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102455:	50                   	push   %eax
f0102456:	e8 56 dc ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f010245b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010245e:	8d 83 97 8d f7 ff    	lea    -0x87269(%ebx),%eax
f0102464:	50                   	push   %eax
f0102465:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f010246b:	50                   	push   %eax
f010246c:	68 b6 03 00 00       	push   $0x3b6
f0102471:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102477:	50                   	push   %eax
f0102478:	e8 34 dc ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f010247d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102480:	8d 83 ad 8d f7 ff    	lea    -0x87253(%ebx),%eax
f0102486:	50                   	push   %eax
f0102487:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f010248d:	50                   	push   %eax
f010248e:	68 b7 03 00 00       	push   $0x3b7
f0102493:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102499:	50                   	push   %eax
f010249a:	e8 12 dc ff ff       	call   f01000b1 <_panic>
	assert(pp1 && pp1 != pp0);
f010249f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024a2:	8d 83 c3 8d f7 ff    	lea    -0x8723d(%ebx),%eax
f01024a8:	50                   	push   %eax
f01024a9:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f01024af:	50                   	push   %eax
f01024b0:	68 ba 03 00 00       	push   $0x3ba
f01024b5:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f01024bb:	50                   	push   %eax
f01024bc:	e8 f0 db ff ff       	call   f01000b1 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01024c1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024c4:	8d 83 20 91 f7 ff    	lea    -0x86ee0(%ebx),%eax
f01024ca:	50                   	push   %eax
f01024cb:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f01024d1:	50                   	push   %eax
f01024d2:	68 bb 03 00 00       	push   $0x3bb
f01024d7:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f01024dd:	50                   	push   %eax
f01024de:	e8 ce db ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f01024e3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024e6:	8d 83 2c 8e f7 ff    	lea    -0x871d4(%ebx),%eax
f01024ec:	50                   	push   %eax
f01024ed:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f01024f3:	50                   	push   %eax
f01024f4:	68 c2 03 00 00       	push   $0x3c2
f01024f9:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f01024ff:	50                   	push   %eax
f0102500:	e8 ac db ff ff       	call   f01000b1 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0102505:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102508:	8d 83 60 91 f7 ff    	lea    -0x86ea0(%ebx),%eax
f010250e:	50                   	push   %eax
f010250f:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102515:	50                   	push   %eax
f0102516:	68 c5 03 00 00       	push   $0x3c5
f010251b:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102521:	50                   	push   %eax
f0102522:	e8 8a db ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0102527:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010252a:	8d 83 98 91 f7 ff    	lea    -0x86e68(%ebx),%eax
f0102530:	50                   	push   %eax
f0102531:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102537:	50                   	push   %eax
f0102538:	68 c8 03 00 00       	push   $0x3c8
f010253d:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102543:	50                   	push   %eax
f0102544:	e8 68 db ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0102549:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010254c:	8d 83 c8 91 f7 ff    	lea    -0x86e38(%ebx),%eax
f0102552:	50                   	push   %eax
f0102553:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102559:	50                   	push   %eax
f010255a:	68 cc 03 00 00       	push   $0x3cc
f010255f:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102565:	50                   	push   %eax
f0102566:	e8 46 db ff ff       	call   f01000b1 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010256b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010256e:	8d 83 f8 91 f7 ff    	lea    -0x86e08(%ebx),%eax
f0102574:	50                   	push   %eax
f0102575:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f010257b:	50                   	push   %eax
f010257c:	68 cd 03 00 00       	push   $0x3cd
f0102581:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102587:	50                   	push   %eax
f0102588:	e8 24 db ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010258d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102590:	8d 83 20 92 f7 ff    	lea    -0x86de0(%ebx),%eax
f0102596:	50                   	push   %eax
f0102597:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f010259d:	50                   	push   %eax
f010259e:	68 ce 03 00 00       	push   $0x3ce
f01025a3:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f01025a9:	50                   	push   %eax
f01025aa:	e8 02 db ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 1);
f01025af:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025b2:	8d 83 7e 8e f7 ff    	lea    -0x87182(%ebx),%eax
f01025b8:	50                   	push   %eax
f01025b9:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f01025bf:	50                   	push   %eax
f01025c0:	68 cf 03 00 00       	push   $0x3cf
f01025c5:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f01025cb:	50                   	push   %eax
f01025cc:	e8 e0 da ff ff       	call   f01000b1 <_panic>
	assert(pp0->pp_ref == 1);
f01025d1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025d4:	8d 83 8f 8e f7 ff    	lea    -0x87171(%ebx),%eax
f01025da:	50                   	push   %eax
f01025db:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f01025e1:	50                   	push   %eax
f01025e2:	68 d0 03 00 00       	push   $0x3d0
f01025e7:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f01025ed:	50                   	push   %eax
f01025ee:	e8 be da ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01025f3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025f6:	8d 83 50 92 f7 ff    	lea    -0x86db0(%ebx),%eax
f01025fc:	50                   	push   %eax
f01025fd:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102603:	50                   	push   %eax
f0102604:	68 d4 03 00 00       	push   $0x3d4
f0102609:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f010260f:	50                   	push   %eax
f0102610:	e8 9c da ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102615:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102618:	8d 83 8c 92 f7 ff    	lea    -0x86d74(%ebx),%eax
f010261e:	50                   	push   %eax
f010261f:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102625:	50                   	push   %eax
f0102626:	68 d5 03 00 00       	push   $0x3d5
f010262b:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102631:	50                   	push   %eax
f0102632:	e8 7a da ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f0102637:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010263a:	8d 83 a0 8e f7 ff    	lea    -0x87160(%ebx),%eax
f0102640:	50                   	push   %eax
f0102641:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102647:	50                   	push   %eax
f0102648:	68 d6 03 00 00       	push   $0x3d6
f010264d:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102653:	50                   	push   %eax
f0102654:	e8 58 da ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f0102659:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010265c:	8d 83 2c 8e f7 ff    	lea    -0x871d4(%ebx),%eax
f0102662:	50                   	push   %eax
f0102663:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102669:	50                   	push   %eax
f010266a:	68 d9 03 00 00       	push   $0x3d9
f010266f:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102675:	50                   	push   %eax
f0102676:	e8 36 da ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010267b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010267e:	8d 83 50 92 f7 ff    	lea    -0x86db0(%ebx),%eax
f0102684:	50                   	push   %eax
f0102685:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f010268b:	50                   	push   %eax
f010268c:	68 dc 03 00 00       	push   $0x3dc
f0102691:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102697:	50                   	push   %eax
f0102698:	e8 14 da ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010269d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026a0:	8d 83 8c 92 f7 ff    	lea    -0x86d74(%ebx),%eax
f01026a6:	50                   	push   %eax
f01026a7:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f01026ad:	50                   	push   %eax
f01026ae:	68 dd 03 00 00       	push   $0x3dd
f01026b3:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f01026b9:	50                   	push   %eax
f01026ba:	e8 f2 d9 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f01026bf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026c2:	8d 83 a0 8e f7 ff    	lea    -0x87160(%ebx),%eax
f01026c8:	50                   	push   %eax
f01026c9:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f01026cf:	50                   	push   %eax
f01026d0:	68 de 03 00 00       	push   $0x3de
f01026d5:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f01026db:	50                   	push   %eax
f01026dc:	e8 d0 d9 ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f01026e1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026e4:	8d 83 2c 8e f7 ff    	lea    -0x871d4(%ebx),%eax
f01026ea:	50                   	push   %eax
f01026eb:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f01026f1:	50                   	push   %eax
f01026f2:	68 e2 03 00 00       	push   $0x3e2
f01026f7:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f01026fd:	50                   	push   %eax
f01026fe:	e8 ae d9 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102703:	50                   	push   %eax
f0102704:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102707:	8d 83 94 8f f7 ff    	lea    -0x8706c(%ebx),%eax
f010270d:	50                   	push   %eax
f010270e:	68 e5 03 00 00       	push   $0x3e5
f0102713:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102719:	50                   	push   %eax
f010271a:	e8 92 d9 ff ff       	call   f01000b1 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f010271f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102722:	8d 83 bc 92 f7 ff    	lea    -0x86d44(%ebx),%eax
f0102728:	50                   	push   %eax
f0102729:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f010272f:	50                   	push   %eax
f0102730:	68 e6 03 00 00       	push   $0x3e6
f0102735:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f010273b:	50                   	push   %eax
f010273c:	e8 70 d9 ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102741:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102744:	8d 83 fc 92 f7 ff    	lea    -0x86d04(%ebx),%eax
f010274a:	50                   	push   %eax
f010274b:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102751:	50                   	push   %eax
f0102752:	68 e9 03 00 00       	push   $0x3e9
f0102757:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f010275d:	50                   	push   %eax
f010275e:	e8 4e d9 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102763:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102766:	8d 83 8c 92 f7 ff    	lea    -0x86d74(%ebx),%eax
f010276c:	50                   	push   %eax
f010276d:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102773:	50                   	push   %eax
f0102774:	68 ea 03 00 00       	push   $0x3ea
f0102779:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f010277f:	50                   	push   %eax
f0102780:	e8 2c d9 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f0102785:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102788:	8d 83 a0 8e f7 ff    	lea    -0x87160(%ebx),%eax
f010278e:	50                   	push   %eax
f010278f:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102795:	50                   	push   %eax
f0102796:	68 eb 03 00 00       	push   $0x3eb
f010279b:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f01027a1:	50                   	push   %eax
f01027a2:	e8 0a d9 ff ff       	call   f01000b1 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01027a7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027aa:	8d 83 3c 93 f7 ff    	lea    -0x86cc4(%ebx),%eax
f01027b0:	50                   	push   %eax
f01027b1:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f01027b7:	50                   	push   %eax
f01027b8:	68 ec 03 00 00       	push   $0x3ec
f01027bd:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f01027c3:	50                   	push   %eax
f01027c4:	e8 e8 d8 ff ff       	call   f01000b1 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01027c9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027cc:	8d 83 b1 8e f7 ff    	lea    -0x8714f(%ebx),%eax
f01027d2:	50                   	push   %eax
f01027d3:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f01027d9:	50                   	push   %eax
f01027da:	68 ed 03 00 00       	push   $0x3ed
f01027df:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f01027e5:	50                   	push   %eax
f01027e6:	e8 c6 d8 ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01027eb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027ee:	8d 83 50 92 f7 ff    	lea    -0x86db0(%ebx),%eax
f01027f4:	50                   	push   %eax
f01027f5:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f01027fb:	50                   	push   %eax
f01027fc:	68 f0 03 00 00       	push   $0x3f0
f0102801:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102807:	50                   	push   %eax
f0102808:	e8 a4 d8 ff ff       	call   f01000b1 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f010280d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102810:	8d 83 70 93 f7 ff    	lea    -0x86c90(%ebx),%eax
f0102816:	50                   	push   %eax
f0102817:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f010281d:	50                   	push   %eax
f010281e:	68 f1 03 00 00       	push   $0x3f1
f0102823:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102829:	50                   	push   %eax
f010282a:	e8 82 d8 ff ff       	call   f01000b1 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010282f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102832:	8d 83 a4 93 f7 ff    	lea    -0x86c5c(%ebx),%eax
f0102838:	50                   	push   %eax
f0102839:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f010283f:	50                   	push   %eax
f0102840:	68 f2 03 00 00       	push   $0x3f2
f0102845:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f010284b:	50                   	push   %eax
f010284c:	e8 60 d8 ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102851:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102854:	8d 83 dc 93 f7 ff    	lea    -0x86c24(%ebx),%eax
f010285a:	50                   	push   %eax
f010285b:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102861:	50                   	push   %eax
f0102862:	68 f5 03 00 00       	push   $0x3f5
f0102867:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f010286d:	50                   	push   %eax
f010286e:	e8 3e d8 ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102873:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102876:	8d 83 14 94 f7 ff    	lea    -0x86bec(%ebx),%eax
f010287c:	50                   	push   %eax
f010287d:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102883:	50                   	push   %eax
f0102884:	68 f8 03 00 00       	push   $0x3f8
f0102889:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f010288f:	50                   	push   %eax
f0102890:	e8 1c d8 ff ff       	call   f01000b1 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102895:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102898:	8d 83 a4 93 f7 ff    	lea    -0x86c5c(%ebx),%eax
f010289e:	50                   	push   %eax
f010289f:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f01028a5:	50                   	push   %eax
f01028a6:	68 f9 03 00 00       	push   $0x3f9
f01028ab:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f01028b1:	50                   	push   %eax
f01028b2:	e8 fa d7 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01028b7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028ba:	8d 83 50 94 f7 ff    	lea    -0x86bb0(%ebx),%eax
f01028c0:	50                   	push   %eax
f01028c1:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f01028c7:	50                   	push   %eax
f01028c8:	68 fc 03 00 00       	push   $0x3fc
f01028cd:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f01028d3:	50                   	push   %eax
f01028d4:	e8 d8 d7 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01028d9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028dc:	8d 83 7c 94 f7 ff    	lea    -0x86b84(%ebx),%eax
f01028e2:	50                   	push   %eax
f01028e3:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f01028e9:	50                   	push   %eax
f01028ea:	68 fd 03 00 00       	push   $0x3fd
f01028ef:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f01028f5:	50                   	push   %eax
f01028f6:	e8 b6 d7 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 2);
f01028fb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028fe:	8d 83 c7 8e f7 ff    	lea    -0x87139(%ebx),%eax
f0102904:	50                   	push   %eax
f0102905:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f010290b:	50                   	push   %eax
f010290c:	68 ff 03 00 00       	push   $0x3ff
f0102911:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102917:	50                   	push   %eax
f0102918:	e8 94 d7 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f010291d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102920:	8d 83 d8 8e f7 ff    	lea    -0x87128(%ebx),%eax
f0102926:	50                   	push   %eax
f0102927:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f010292d:	50                   	push   %eax
f010292e:	68 00 04 00 00       	push   $0x400
f0102933:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102939:	50                   	push   %eax
f010293a:	e8 72 d7 ff ff       	call   f01000b1 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f010293f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102942:	8d 83 ac 94 f7 ff    	lea    -0x86b54(%ebx),%eax
f0102948:	50                   	push   %eax
f0102949:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f010294f:	50                   	push   %eax
f0102950:	68 03 04 00 00       	push   $0x403
f0102955:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f010295b:	50                   	push   %eax
f010295c:	e8 50 d7 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102961:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102964:	8d 83 d0 94 f7 ff    	lea    -0x86b30(%ebx),%eax
f010296a:	50                   	push   %eax
f010296b:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102971:	50                   	push   %eax
f0102972:	68 07 04 00 00       	push   $0x407
f0102977:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f010297d:	50                   	push   %eax
f010297e:	e8 2e d7 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102983:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102986:	8d 83 7c 94 f7 ff    	lea    -0x86b84(%ebx),%eax
f010298c:	50                   	push   %eax
f010298d:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102993:	50                   	push   %eax
f0102994:	68 08 04 00 00       	push   $0x408
f0102999:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f010299f:	50                   	push   %eax
f01029a0:	e8 0c d7 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 1);
f01029a5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029a8:	8d 83 7e 8e f7 ff    	lea    -0x87182(%ebx),%eax
f01029ae:	50                   	push   %eax
f01029af:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f01029b5:	50                   	push   %eax
f01029b6:	68 09 04 00 00       	push   $0x409
f01029bb:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f01029c1:	50                   	push   %eax
f01029c2:	e8 ea d6 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f01029c7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029ca:	8d 83 d8 8e f7 ff    	lea    -0x87128(%ebx),%eax
f01029d0:	50                   	push   %eax
f01029d1:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f01029d7:	50                   	push   %eax
f01029d8:	68 0a 04 00 00       	push   $0x40a
f01029dd:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f01029e3:	50                   	push   %eax
f01029e4:	e8 c8 d6 ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f01029e9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029ec:	8d 83 f4 94 f7 ff    	lea    -0x86b0c(%ebx),%eax
f01029f2:	50                   	push   %eax
f01029f3:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f01029f9:	50                   	push   %eax
f01029fa:	68 0d 04 00 00       	push   $0x40d
f01029ff:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102a05:	50                   	push   %eax
f0102a06:	e8 a6 d6 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref);
f0102a0b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a0e:	8d 83 e9 8e f7 ff    	lea    -0x87117(%ebx),%eax
f0102a14:	50                   	push   %eax
f0102a15:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102a1b:	50                   	push   %eax
f0102a1c:	68 0e 04 00 00       	push   $0x40e
f0102a21:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102a27:	50                   	push   %eax
f0102a28:	e8 84 d6 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_link == NULL);
f0102a2d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a30:	8d 83 f5 8e f7 ff    	lea    -0x8710b(%ebx),%eax
f0102a36:	50                   	push   %eax
f0102a37:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102a3d:	50                   	push   %eax
f0102a3e:	68 0f 04 00 00       	push   $0x40f
f0102a43:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102a49:	50                   	push   %eax
f0102a4a:	e8 62 d6 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102a4f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a52:	8d 83 d0 94 f7 ff    	lea    -0x86b30(%ebx),%eax
f0102a58:	50                   	push   %eax
f0102a59:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102a5f:	50                   	push   %eax
f0102a60:	68 13 04 00 00       	push   $0x413
f0102a65:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102a6b:	50                   	push   %eax
f0102a6c:	e8 40 d6 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102a71:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a74:	8d 83 2c 95 f7 ff    	lea    -0x86ad4(%ebx),%eax
f0102a7a:	50                   	push   %eax
f0102a7b:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102a81:	50                   	push   %eax
f0102a82:	68 14 04 00 00       	push   $0x414
f0102a87:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102a8d:	50                   	push   %eax
f0102a8e:	e8 1e d6 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 0);
f0102a93:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102a96:	8d 83 0a 8f f7 ff    	lea    -0x870f6(%ebx),%eax
f0102a9c:	50                   	push   %eax
f0102a9d:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102aa3:	50                   	push   %eax
f0102aa4:	68 15 04 00 00       	push   $0x415
f0102aa9:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102aaf:	50                   	push   %eax
f0102ab0:	e8 fc d5 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f0102ab5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ab8:	8d 83 d8 8e f7 ff    	lea    -0x87128(%ebx),%eax
f0102abe:	50                   	push   %eax
f0102abf:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102ac5:	50                   	push   %eax
f0102ac6:	68 16 04 00 00       	push   $0x416
f0102acb:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102ad1:	50                   	push   %eax
f0102ad2:	e8 da d5 ff ff       	call   f01000b1 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f0102ad7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ada:	8d 83 54 95 f7 ff    	lea    -0x86aac(%ebx),%eax
f0102ae0:	50                   	push   %eax
f0102ae1:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102ae7:	50                   	push   %eax
f0102ae8:	68 19 04 00 00       	push   $0x419
f0102aed:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102af3:	50                   	push   %eax
f0102af4:	e8 b8 d5 ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f0102af9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102afc:	8d 83 2c 8e f7 ff    	lea    -0x871d4(%ebx),%eax
f0102b02:	50                   	push   %eax
f0102b03:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102b09:	50                   	push   %eax
f0102b0a:	68 1c 04 00 00       	push   $0x41c
f0102b0f:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102b15:	50                   	push   %eax
f0102b16:	e8 96 d5 ff ff       	call   f01000b1 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102b1b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b1e:	8d 83 f8 91 f7 ff    	lea    -0x86e08(%ebx),%eax
f0102b24:	50                   	push   %eax
f0102b25:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102b2b:	50                   	push   %eax
f0102b2c:	68 1f 04 00 00       	push   $0x41f
f0102b31:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102b37:	50                   	push   %eax
f0102b38:	e8 74 d5 ff ff       	call   f01000b1 <_panic>
	assert(pp0->pp_ref == 1);
f0102b3d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b40:	8d 83 8f 8e f7 ff    	lea    -0x87171(%ebx),%eax
f0102b46:	50                   	push   %eax
f0102b47:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102b4d:	50                   	push   %eax
f0102b4e:	68 21 04 00 00       	push   $0x421
f0102b53:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102b59:	50                   	push   %eax
f0102b5a:	e8 52 d5 ff ff       	call   f01000b1 <_panic>
f0102b5f:	52                   	push   %edx
f0102b60:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b63:	8d 83 94 8f f7 ff    	lea    -0x8706c(%ebx),%eax
f0102b69:	50                   	push   %eax
f0102b6a:	68 28 04 00 00       	push   $0x428
f0102b6f:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102b75:	50                   	push   %eax
f0102b76:	e8 36 d5 ff ff       	call   f01000b1 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102b7b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b7e:	8d 83 1b 8f f7 ff    	lea    -0x870e5(%ebx),%eax
f0102b84:	50                   	push   %eax
f0102b85:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102b8b:	50                   	push   %eax
f0102b8c:	68 29 04 00 00       	push   $0x429
f0102b91:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102b97:	50                   	push   %eax
f0102b98:	e8 14 d5 ff ff       	call   f01000b1 <_panic>
f0102b9d:	50                   	push   %eax
f0102b9e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ba1:	8d 83 94 8f f7 ff    	lea    -0x8706c(%ebx),%eax
f0102ba7:	50                   	push   %eax
f0102ba8:	6a 56                	push   $0x56
f0102baa:	8d 83 82 8c f7 ff    	lea    -0x8737e(%ebx),%eax
f0102bb0:	50                   	push   %eax
f0102bb1:	e8 fb d4 ff ff       	call   f01000b1 <_panic>
f0102bb6:	52                   	push   %edx
f0102bb7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102bba:	8d 83 94 8f f7 ff    	lea    -0x8706c(%ebx),%eax
f0102bc0:	50                   	push   %eax
f0102bc1:	6a 56                	push   $0x56
f0102bc3:	8d 83 82 8c f7 ff    	lea    -0x8737e(%ebx),%eax
f0102bc9:	50                   	push   %eax
f0102bca:	e8 e2 d4 ff ff       	call   f01000b1 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f0102bcf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102bd2:	8d 83 33 8f f7 ff    	lea    -0x870cd(%ebx),%eax
f0102bd8:	50                   	push   %eax
f0102bd9:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102bdf:	50                   	push   %eax
f0102be0:	68 33 04 00 00       	push   $0x433
f0102be5:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102beb:	50                   	push   %eax
f0102bec:	e8 c0 d4 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102bf1:	50                   	push   %eax
f0102bf2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102bf5:	8d 83 a0 90 f7 ff    	lea    -0x86f60(%ebx),%eax
f0102bfb:	50                   	push   %eax
f0102bfc:	68 c4 00 00 00       	push   $0xc4
f0102c01:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102c07:	50                   	push   %eax
f0102c08:	e8 a4 d4 ff ff       	call   f01000b1 <_panic>
f0102c0d:	50                   	push   %eax
f0102c0e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c11:	8d 83 a0 90 f7 ff    	lea    -0x86f60(%ebx),%eax
f0102c17:	50                   	push   %eax
f0102c18:	68 d1 00 00 00       	push   $0xd1
f0102c1d:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102c23:	50                   	push   %eax
f0102c24:	e8 88 d4 ff ff       	call   f01000b1 <_panic>
f0102c29:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c2c:	ff b3 fc ff ff ff    	pushl  -0x4(%ebx)
f0102c32:	8d 83 a0 90 f7 ff    	lea    -0x86f60(%ebx),%eax
f0102c38:	50                   	push   %eax
f0102c39:	68 e2 00 00 00       	push   $0xe2
f0102c3e:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102c44:	50                   	push   %eax
f0102c45:	e8 67 d4 ff ff       	call   f01000b1 <_panic>
f0102c4a:	ff 75 c0             	pushl  -0x40(%ebp)
f0102c4d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c50:	8d 83 a0 90 f7 ff    	lea    -0x86f60(%ebx),%eax
f0102c56:	50                   	push   %eax
f0102c57:	68 70 03 00 00       	push   $0x370
f0102c5c:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102c62:	50                   	push   %eax
f0102c63:	e8 49 d4 ff ff       	call   f01000b1 <_panic>
	for (i = 0; i < n; i += PGSIZE)
f0102c68:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102c6e:	39 5d d0             	cmp    %ebx,-0x30(%ebp)
f0102c71:	76 3f                	jbe    f0102cb2 <mem_init+0x1780>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102c73:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102c79:	89 f0                	mov    %esi,%eax
f0102c7b:	e8 ec de ff ff       	call   f0100b6c <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f0102c80:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f0102c87:	76 c1                	jbe    f0102c4a <mem_init+0x1718>
f0102c89:	8d 14 3b             	lea    (%ebx,%edi,1),%edx
f0102c8c:	39 d0                	cmp    %edx,%eax
f0102c8e:	74 d8                	je     f0102c68 <mem_init+0x1736>
f0102c90:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c93:	8d 83 78 95 f7 ff    	lea    -0x86a88(%ebx),%eax
f0102c99:	50                   	push   %eax
f0102c9a:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102ca0:	50                   	push   %eax
f0102ca1:	68 70 03 00 00       	push   $0x370
f0102ca6:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102cac:	50                   	push   %eax
f0102cad:	e8 ff d3 ff ff       	call   f01000b1 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102cb2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102cb5:	c7 c0 4c f3 18 f0    	mov    $0xf018f34c,%eax
f0102cbb:	8b 00                	mov    (%eax),%eax
f0102cbd:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102cc0:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102cc3:	bf 00 00 c0 ee       	mov    $0xeec00000,%edi
f0102cc8:	8d 98 00 00 40 21    	lea    0x21400000(%eax),%ebx
f0102cce:	89 fa                	mov    %edi,%edx
f0102cd0:	89 f0                	mov    %esi,%eax
f0102cd2:	e8 95 de ff ff       	call   f0100b6c <check_va2pa>
f0102cd7:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102cde:	76 3d                	jbe    f0102d1d <mem_init+0x17eb>
f0102ce0:	8d 14 3b             	lea    (%ebx,%edi,1),%edx
f0102ce3:	39 d0                	cmp    %edx,%eax
f0102ce5:	75 54                	jne    f0102d3b <mem_init+0x1809>
f0102ce7:	81 c7 00 10 00 00    	add    $0x1000,%edi
	for (i = 0; i < n; i += PGSIZE)
f0102ced:	81 ff 00 80 c1 ee    	cmp    $0xeec18000,%edi
f0102cf3:	75 d9                	jne    f0102cce <mem_init+0x179c>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102cf5:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102cf8:	c1 e7 0c             	shl    $0xc,%edi
f0102cfb:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102d00:	39 fb                	cmp    %edi,%ebx
f0102d02:	73 7b                	jae    f0102d7f <mem_init+0x184d>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102d04:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102d0a:	89 f0                	mov    %esi,%eax
f0102d0c:	e8 5b de ff ff       	call   f0100b6c <check_va2pa>
f0102d11:	39 c3                	cmp    %eax,%ebx
f0102d13:	75 48                	jne    f0102d5d <mem_init+0x182b>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102d15:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102d1b:	eb e3                	jmp    f0102d00 <mem_init+0x17ce>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d1d:	ff 75 cc             	pushl  -0x34(%ebp)
f0102d20:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d23:	8d 83 a0 90 f7 ff    	lea    -0x86f60(%ebx),%eax
f0102d29:	50                   	push   %eax
f0102d2a:	68 75 03 00 00       	push   $0x375
f0102d2f:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102d35:	50                   	push   %eax
f0102d36:	e8 76 d3 ff ff       	call   f01000b1 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102d3b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d3e:	8d 83 ac 95 f7 ff    	lea    -0x86a54(%ebx),%eax
f0102d44:	50                   	push   %eax
f0102d45:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102d4b:	50                   	push   %eax
f0102d4c:	68 75 03 00 00       	push   $0x375
f0102d51:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102d57:	50                   	push   %eax
f0102d58:	e8 54 d3 ff ff       	call   f01000b1 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102d5d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d60:	8d 83 e0 95 f7 ff    	lea    -0x86a20(%ebx),%eax
f0102d66:	50                   	push   %eax
f0102d67:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102d6d:	50                   	push   %eax
f0102d6e:	68 79 03 00 00       	push   $0x379
f0102d73:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102d79:	50                   	push   %eax
f0102d7a:	e8 32 d3 ff ff       	call   f01000b1 <_panic>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102d7f:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102d84:	8b 7d c8             	mov    -0x38(%ebp),%edi
f0102d87:	81 c7 00 80 00 20    	add    $0x20008000,%edi
f0102d8d:	89 da                	mov    %ebx,%edx
f0102d8f:	89 f0                	mov    %esi,%eax
f0102d91:	e8 d6 dd ff ff       	call   f0100b6c <check_va2pa>
f0102d96:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
f0102d99:	39 c2                	cmp    %eax,%edx
f0102d9b:	75 26                	jne    f0102dc3 <mem_init+0x1891>
f0102d9d:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102da3:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102da9:	75 e2                	jne    f0102d8d <mem_init+0x185b>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102dab:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102db0:	89 f0                	mov    %esi,%eax
f0102db2:	e8 b5 dd ff ff       	call   f0100b6c <check_va2pa>
f0102db7:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102dba:	75 29                	jne    f0102de5 <mem_init+0x18b3>
	for (i = 0; i < NPDENTRIES; i++) {
f0102dbc:	b8 00 00 00 00       	mov    $0x0,%eax
f0102dc1:	eb 6d                	jmp    f0102e30 <mem_init+0x18fe>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102dc3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102dc6:	8d 83 08 96 f7 ff    	lea    -0x869f8(%ebx),%eax
f0102dcc:	50                   	push   %eax
f0102dcd:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102dd3:	50                   	push   %eax
f0102dd4:	68 7d 03 00 00       	push   $0x37d
f0102dd9:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102ddf:	50                   	push   %eax
f0102de0:	e8 cc d2 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102de5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102de8:	8d 83 50 96 f7 ff    	lea    -0x869b0(%ebx),%eax
f0102dee:	50                   	push   %eax
f0102def:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102df5:	50                   	push   %eax
f0102df6:	68 7e 03 00 00       	push   $0x37e
f0102dfb:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102e01:	50                   	push   %eax
f0102e02:	e8 aa d2 ff ff       	call   f01000b1 <_panic>
			assert(pgdir[i] & PTE_P);
f0102e07:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102e0b:	74 52                	je     f0102e5f <mem_init+0x192d>
	for (i = 0; i < NPDENTRIES; i++) {
f0102e0d:	83 c0 01             	add    $0x1,%eax
f0102e10:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102e15:	0f 87 bb 00 00 00    	ja     f0102ed6 <mem_init+0x19a4>
		switch (i) {
f0102e1b:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102e20:	72 0e                	jb     f0102e30 <mem_init+0x18fe>
f0102e22:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102e27:	76 de                	jbe    f0102e07 <mem_init+0x18d5>
f0102e29:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102e2e:	74 d7                	je     f0102e07 <mem_init+0x18d5>
			if (i >= PDX(KERNBASE)) {
f0102e30:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102e35:	77 4a                	ja     f0102e81 <mem_init+0x194f>
				assert(pgdir[i] == 0);
f0102e37:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102e3b:	74 d0                	je     f0102e0d <mem_init+0x18db>
f0102e3d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e40:	8d 83 85 8f f7 ff    	lea    -0x8707b(%ebx),%eax
f0102e46:	50                   	push   %eax
f0102e47:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102e4d:	50                   	push   %eax
f0102e4e:	68 8e 03 00 00       	push   $0x38e
f0102e53:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102e59:	50                   	push   %eax
f0102e5a:	e8 52 d2 ff ff       	call   f01000b1 <_panic>
			assert(pgdir[i] & PTE_P);
f0102e5f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e62:	8d 83 63 8f f7 ff    	lea    -0x8709d(%ebx),%eax
f0102e68:	50                   	push   %eax
f0102e69:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102e6f:	50                   	push   %eax
f0102e70:	68 87 03 00 00       	push   $0x387
f0102e75:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102e7b:	50                   	push   %eax
f0102e7c:	e8 30 d2 ff ff       	call   f01000b1 <_panic>
				assert(pgdir[i] & PTE_P);
f0102e81:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102e84:	f6 c2 01             	test   $0x1,%dl
f0102e87:	74 2b                	je     f0102eb4 <mem_init+0x1982>
				assert(pgdir[i] & PTE_W);
f0102e89:	f6 c2 02             	test   $0x2,%dl
f0102e8c:	0f 85 7b ff ff ff    	jne    f0102e0d <mem_init+0x18db>
f0102e92:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e95:	8d 83 74 8f f7 ff    	lea    -0x8708c(%ebx),%eax
f0102e9b:	50                   	push   %eax
f0102e9c:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102ea2:	50                   	push   %eax
f0102ea3:	68 8c 03 00 00       	push   $0x38c
f0102ea8:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102eae:	50                   	push   %eax
f0102eaf:	e8 fd d1 ff ff       	call   f01000b1 <_panic>
				assert(pgdir[i] & PTE_P);
f0102eb4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102eb7:	8d 83 63 8f f7 ff    	lea    -0x8709d(%ebx),%eax
f0102ebd:	50                   	push   %eax
f0102ebe:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0102ec4:	50                   	push   %eax
f0102ec5:	68 8b 03 00 00       	push   $0x38b
f0102eca:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0102ed0:	50                   	push   %eax
f0102ed1:	e8 db d1 ff ff       	call   f01000b1 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102ed6:	83 ec 0c             	sub    $0xc,%esp
f0102ed9:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0102edc:	8d 86 80 96 f7 ff    	lea    -0x86980(%esi),%eax
f0102ee2:	50                   	push   %eax
f0102ee3:	89 f3                	mov    %esi,%ebx
f0102ee5:	e8 d4 0d 00 00       	call   f0103cbe <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102eea:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f0102ef0:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102ef2:	83 c4 10             	add    $0x10,%esp
f0102ef5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102efa:	0f 86 44 02 00 00    	jbe    f0103144 <mem_init+0x1c12>
	return (physaddr_t)kva - KERNBASE;
f0102f00:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102f05:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102f08:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f0d:	e8 d7 dc ff ff       	call   f0100be9 <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102f12:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102f15:	83 e0 f3             	and    $0xfffffff3,%eax
f0102f18:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102f1d:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102f20:	83 ec 0c             	sub    $0xc,%esp
f0102f23:	6a 00                	push   $0x0
f0102f25:	e8 a9 e1 ff ff       	call   f01010d3 <page_alloc>
f0102f2a:	89 c6                	mov    %eax,%esi
f0102f2c:	83 c4 10             	add    $0x10,%esp
f0102f2f:	85 c0                	test   %eax,%eax
f0102f31:	0f 84 29 02 00 00    	je     f0103160 <mem_init+0x1c2e>
	assert((pp1 = page_alloc(0)));
f0102f37:	83 ec 0c             	sub    $0xc,%esp
f0102f3a:	6a 00                	push   $0x0
f0102f3c:	e8 92 e1 ff ff       	call   f01010d3 <page_alloc>
f0102f41:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102f44:	83 c4 10             	add    $0x10,%esp
f0102f47:	85 c0                	test   %eax,%eax
f0102f49:	0f 84 33 02 00 00    	je     f0103182 <mem_init+0x1c50>
	assert((pp2 = page_alloc(0)));
f0102f4f:	83 ec 0c             	sub    $0xc,%esp
f0102f52:	6a 00                	push   $0x0
f0102f54:	e8 7a e1 ff ff       	call   f01010d3 <page_alloc>
f0102f59:	89 c7                	mov    %eax,%edi
f0102f5b:	83 c4 10             	add    $0x10,%esp
f0102f5e:	85 c0                	test   %eax,%eax
f0102f60:	0f 84 3e 02 00 00    	je     f01031a4 <mem_init+0x1c72>
	page_free(pp0);
f0102f66:	83 ec 0c             	sub    $0xc,%esp
f0102f69:	56                   	push   %esi
f0102f6a:	e8 f2 e1 ff ff       	call   f0101161 <page_free>
	return (pp - pages) << PGSHIFT;
f0102f6f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f72:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0102f78:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102f7b:	2b 08                	sub    (%eax),%ecx
f0102f7d:	89 c8                	mov    %ecx,%eax
f0102f7f:	c1 f8 03             	sar    $0x3,%eax
f0102f82:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102f85:	89 c1                	mov    %eax,%ecx
f0102f87:	c1 e9 0c             	shr    $0xc,%ecx
f0102f8a:	83 c4 10             	add    $0x10,%esp
f0102f8d:	c7 c2 04 00 19 f0    	mov    $0xf0190004,%edx
f0102f93:	3b 0a                	cmp    (%edx),%ecx
f0102f95:	0f 83 2b 02 00 00    	jae    f01031c6 <mem_init+0x1c94>
	memset(page2kva(pp1), 1, PGSIZE);
f0102f9b:	83 ec 04             	sub    $0x4,%esp
f0102f9e:	68 00 10 00 00       	push   $0x1000
f0102fa3:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102fa5:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102faa:	50                   	push   %eax
f0102fab:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102fae:	e8 93 23 00 00       	call   f0105346 <memset>
	return (pp - pages) << PGSHIFT;
f0102fb3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102fb6:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0102fbc:	89 f9                	mov    %edi,%ecx
f0102fbe:	2b 08                	sub    (%eax),%ecx
f0102fc0:	89 c8                	mov    %ecx,%eax
f0102fc2:	c1 f8 03             	sar    $0x3,%eax
f0102fc5:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102fc8:	89 c1                	mov    %eax,%ecx
f0102fca:	c1 e9 0c             	shr    $0xc,%ecx
f0102fcd:	83 c4 10             	add    $0x10,%esp
f0102fd0:	c7 c2 04 00 19 f0    	mov    $0xf0190004,%edx
f0102fd6:	3b 0a                	cmp    (%edx),%ecx
f0102fd8:	0f 83 fe 01 00 00    	jae    f01031dc <mem_init+0x1caa>
	memset(page2kva(pp2), 2, PGSIZE);
f0102fde:	83 ec 04             	sub    $0x4,%esp
f0102fe1:	68 00 10 00 00       	push   $0x1000
f0102fe6:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102fe8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102fed:	50                   	push   %eax
f0102fee:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ff1:	e8 50 23 00 00       	call   f0105346 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102ff6:	6a 02                	push   $0x2
f0102ff8:	68 00 10 00 00       	push   $0x1000
f0102ffd:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0103000:	53                   	push   %ebx
f0103001:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103004:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f010300a:	ff 30                	pushl  (%eax)
f010300c:	e8 5d e4 ff ff       	call   f010146e <page_insert>
	assert(pp1->pp_ref == 1);
f0103011:	83 c4 20             	add    $0x20,%esp
f0103014:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0103019:	0f 85 d3 01 00 00    	jne    f01031f2 <mem_init+0x1cc0>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010301f:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0103026:	01 01 01 
f0103029:	0f 85 e5 01 00 00    	jne    f0103214 <mem_init+0x1ce2>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f010302f:	6a 02                	push   $0x2
f0103031:	68 00 10 00 00       	push   $0x1000
f0103036:	57                   	push   %edi
f0103037:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010303a:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f0103040:	ff 30                	pushl  (%eax)
f0103042:	e8 27 e4 ff ff       	call   f010146e <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0103047:	83 c4 10             	add    $0x10,%esp
f010304a:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0103051:	02 02 02 
f0103054:	0f 85 dc 01 00 00    	jne    f0103236 <mem_init+0x1d04>
	assert(pp2->pp_ref == 1);
f010305a:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f010305f:	0f 85 f3 01 00 00    	jne    f0103258 <mem_init+0x1d26>
	assert(pp1->pp_ref == 0);
f0103065:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103068:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f010306d:	0f 85 07 02 00 00    	jne    f010327a <mem_init+0x1d48>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0103073:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f010307a:	03 03 03 
	return (pp - pages) << PGSHIFT;
f010307d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103080:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0103086:	89 f9                	mov    %edi,%ecx
f0103088:	2b 08                	sub    (%eax),%ecx
f010308a:	89 c8                	mov    %ecx,%eax
f010308c:	c1 f8 03             	sar    $0x3,%eax
f010308f:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0103092:	89 c1                	mov    %eax,%ecx
f0103094:	c1 e9 0c             	shr    $0xc,%ecx
f0103097:	c7 c2 04 00 19 f0    	mov    $0xf0190004,%edx
f010309d:	3b 0a                	cmp    (%edx),%ecx
f010309f:	0f 83 f7 01 00 00    	jae    f010329c <mem_init+0x1d6a>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01030a5:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01030ac:	03 03 03 
f01030af:	0f 85 fd 01 00 00    	jne    f01032b2 <mem_init+0x1d80>
	page_remove(kern_pgdir, (void*) PGSIZE);
f01030b5:	83 ec 08             	sub    $0x8,%esp
f01030b8:	68 00 10 00 00       	push   $0x1000
f01030bd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01030c0:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f01030c6:	ff 30                	pushl  (%eax)
f01030c8:	e8 4a e3 ff ff       	call   f0101417 <page_remove>
	assert(pp2->pp_ref == 0);
f01030cd:	83 c4 10             	add    $0x10,%esp
f01030d0:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01030d5:	0f 85 f9 01 00 00    	jne    f01032d4 <mem_init+0x1da2>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01030db:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01030de:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f01030e4:	8b 08                	mov    (%eax),%ecx
f01030e6:	8b 11                	mov    (%ecx),%edx
f01030e8:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f01030ee:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f01030f4:	89 f7                	mov    %esi,%edi
f01030f6:	2b 38                	sub    (%eax),%edi
f01030f8:	89 f8                	mov    %edi,%eax
f01030fa:	c1 f8 03             	sar    $0x3,%eax
f01030fd:	c1 e0 0c             	shl    $0xc,%eax
f0103100:	39 c2                	cmp    %eax,%edx
f0103102:	0f 85 ee 01 00 00    	jne    f01032f6 <mem_init+0x1dc4>
	kern_pgdir[0] = 0;
f0103108:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f010310e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0103113:	0f 85 ff 01 00 00    	jne    f0103318 <mem_init+0x1de6>
	pp0->pp_ref = 0;
f0103119:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f010311f:	83 ec 0c             	sub    $0xc,%esp
f0103122:	56                   	push   %esi
f0103123:	e8 39 e0 ff ff       	call   f0101161 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0103128:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010312b:	8d 83 14 97 f7 ff    	lea    -0x868ec(%ebx),%eax
f0103131:	89 04 24             	mov    %eax,(%esp)
f0103134:	e8 85 0b 00 00       	call   f0103cbe <cprintf>
}
f0103139:	83 c4 10             	add    $0x10,%esp
f010313c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010313f:	5b                   	pop    %ebx
f0103140:	5e                   	pop    %esi
f0103141:	5f                   	pop    %edi
f0103142:	5d                   	pop    %ebp
f0103143:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103144:	50                   	push   %eax
f0103145:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103148:	8d 83 a0 90 f7 ff    	lea    -0x86f60(%ebx),%eax
f010314e:	50                   	push   %eax
f010314f:	68 fe 00 00 00       	push   $0xfe
f0103154:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f010315a:	50                   	push   %eax
f010315b:	e8 51 cf ff ff       	call   f01000b1 <_panic>
	assert((pp0 = page_alloc(0)));
f0103160:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103163:	8d 83 81 8d f7 ff    	lea    -0x8727f(%ebx),%eax
f0103169:	50                   	push   %eax
f010316a:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0103170:	50                   	push   %eax
f0103171:	68 4e 04 00 00       	push   $0x44e
f0103176:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f010317c:	50                   	push   %eax
f010317d:	e8 2f cf ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f0103182:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103185:	8d 83 97 8d f7 ff    	lea    -0x87269(%ebx),%eax
f010318b:	50                   	push   %eax
f010318c:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0103192:	50                   	push   %eax
f0103193:	68 4f 04 00 00       	push   $0x44f
f0103198:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f010319e:	50                   	push   %eax
f010319f:	e8 0d cf ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f01031a4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01031a7:	8d 83 ad 8d f7 ff    	lea    -0x87253(%ebx),%eax
f01031ad:	50                   	push   %eax
f01031ae:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f01031b4:	50                   	push   %eax
f01031b5:	68 50 04 00 00       	push   $0x450
f01031ba:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f01031c0:	50                   	push   %eax
f01031c1:	e8 eb ce ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01031c6:	50                   	push   %eax
f01031c7:	8d 83 94 8f f7 ff    	lea    -0x8706c(%ebx),%eax
f01031cd:	50                   	push   %eax
f01031ce:	6a 56                	push   $0x56
f01031d0:	8d 83 82 8c f7 ff    	lea    -0x8737e(%ebx),%eax
f01031d6:	50                   	push   %eax
f01031d7:	e8 d5 ce ff ff       	call   f01000b1 <_panic>
f01031dc:	50                   	push   %eax
f01031dd:	8d 83 94 8f f7 ff    	lea    -0x8706c(%ebx),%eax
f01031e3:	50                   	push   %eax
f01031e4:	6a 56                	push   $0x56
f01031e6:	8d 83 82 8c f7 ff    	lea    -0x8737e(%ebx),%eax
f01031ec:	50                   	push   %eax
f01031ed:	e8 bf ce ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 1);
f01031f2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01031f5:	8d 83 7e 8e f7 ff    	lea    -0x87182(%ebx),%eax
f01031fb:	50                   	push   %eax
f01031fc:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0103202:	50                   	push   %eax
f0103203:	68 55 04 00 00       	push   $0x455
f0103208:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f010320e:	50                   	push   %eax
f010320f:	e8 9d ce ff ff       	call   f01000b1 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0103214:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103217:	8d 83 a0 96 f7 ff    	lea    -0x86960(%ebx),%eax
f010321d:	50                   	push   %eax
f010321e:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0103224:	50                   	push   %eax
f0103225:	68 56 04 00 00       	push   $0x456
f010322a:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0103230:	50                   	push   %eax
f0103231:	e8 7b ce ff ff       	call   f01000b1 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0103236:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103239:	8d 83 c4 96 f7 ff    	lea    -0x8693c(%ebx),%eax
f010323f:	50                   	push   %eax
f0103240:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0103246:	50                   	push   %eax
f0103247:	68 58 04 00 00       	push   $0x458
f010324c:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0103252:	50                   	push   %eax
f0103253:	e8 59 ce ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f0103258:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010325b:	8d 83 a0 8e f7 ff    	lea    -0x87160(%ebx),%eax
f0103261:	50                   	push   %eax
f0103262:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0103268:	50                   	push   %eax
f0103269:	68 59 04 00 00       	push   $0x459
f010326e:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0103274:	50                   	push   %eax
f0103275:	e8 37 ce ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 0);
f010327a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010327d:	8d 83 0a 8f f7 ff    	lea    -0x870f6(%ebx),%eax
f0103283:	50                   	push   %eax
f0103284:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f010328a:	50                   	push   %eax
f010328b:	68 5a 04 00 00       	push   $0x45a
f0103290:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0103296:	50                   	push   %eax
f0103297:	e8 15 ce ff ff       	call   f01000b1 <_panic>
f010329c:	50                   	push   %eax
f010329d:	8d 83 94 8f f7 ff    	lea    -0x8706c(%ebx),%eax
f01032a3:	50                   	push   %eax
f01032a4:	6a 56                	push   $0x56
f01032a6:	8d 83 82 8c f7 ff    	lea    -0x8737e(%ebx),%eax
f01032ac:	50                   	push   %eax
f01032ad:	e8 ff cd ff ff       	call   f01000b1 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01032b2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01032b5:	8d 83 e8 96 f7 ff    	lea    -0x86918(%ebx),%eax
f01032bb:	50                   	push   %eax
f01032bc:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f01032c2:	50                   	push   %eax
f01032c3:	68 5c 04 00 00       	push   $0x45c
f01032c8:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f01032ce:	50                   	push   %eax
f01032cf:	e8 dd cd ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f01032d4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01032d7:	8d 83 d8 8e f7 ff    	lea    -0x87128(%ebx),%eax
f01032dd:	50                   	push   %eax
f01032de:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f01032e4:	50                   	push   %eax
f01032e5:	68 5e 04 00 00       	push   $0x45e
f01032ea:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f01032f0:	50                   	push   %eax
f01032f1:	e8 bb cd ff ff       	call   f01000b1 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01032f6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01032f9:	8d 83 f8 91 f7 ff    	lea    -0x86e08(%ebx),%eax
f01032ff:	50                   	push   %eax
f0103300:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0103306:	50                   	push   %eax
f0103307:	68 61 04 00 00       	push   $0x461
f010330c:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0103312:	50                   	push   %eax
f0103313:	e8 99 cd ff ff       	call   f01000b1 <_panic>
	assert(pp0->pp_ref == 1);
f0103318:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010331b:	8d 83 8f 8e f7 ff    	lea    -0x87171(%ebx),%eax
f0103321:	50                   	push   %eax
f0103322:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0103328:	50                   	push   %eax
f0103329:	68 63 04 00 00       	push   $0x463
f010332e:	8d 83 76 8c f7 ff    	lea    -0x8738a(%ebx),%eax
f0103334:	50                   	push   %eax
f0103335:	e8 77 cd ff ff       	call   f01000b1 <_panic>

f010333a <tlb_invalidate>:
{
f010333a:	55                   	push   %ebp
f010333b:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010333d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103340:	0f 01 38             	invlpg (%eax)
}
f0103343:	5d                   	pop    %ebp
f0103344:	c3                   	ret    

f0103345 <user_mem_check>:
{
f0103345:	55                   	push   %ebp
f0103346:	89 e5                	mov    %esp,%ebp
f0103348:	57                   	push   %edi
f0103349:	56                   	push   %esi
f010334a:	53                   	push   %ebx
f010334b:	83 ec 1c             	sub    $0x1c,%esp
f010334e:	e8 ec 00 00 00       	call   f010343f <__x86.get_pc_thunk.di>
f0103353:	81 c7 cd 9c 08 00    	add    $0x89ccd,%edi
f0103359:	8b 75 0c             	mov    0xc(%ebp),%esi
	start = (uintptr_t)ROUNDDOWN(va, PGSIZE);
f010335c:	89 f3                	mov    %esi,%ebx
f010335e:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	end = (uintptr_t)ROUNDUP(va + len, PGSIZE);
f0103364:	89 f0                	mov    %esi,%eax
f0103366:	03 45 10             	add    0x10(%ebp),%eax
f0103369:	05 ff 0f 00 00       	add    $0xfff,%eax
f010336e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0103373:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	required_perm = perm | PTE_P | PTE_U;
f0103376:	8b 45 14             	mov    0x14(%ebp),%eax
f0103379:	83 c8 05             	or     $0x5,%eax
f010337c:	89 45 e0             	mov    %eax,-0x20(%ebp)
	for(addr = start; addr < end; addr += PGSIZE) {
f010337f:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0103382:	73 57                	jae    f01033db <user_mem_check+0x96>
		if (addr < ULIM) {
f0103384:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f010338a:	77 23                	ja     f01033af <user_mem_check+0x6a>
			pte_p = pgdir_walk(env->env_pgdir, (void *)addr, 0);
f010338c:	83 ec 04             	sub    $0x4,%esp
f010338f:	6a 00                	push   $0x0
f0103391:	53                   	push   %ebx
f0103392:	8b 45 08             	mov    0x8(%ebp),%eax
f0103395:	ff 70 5c             	pushl  0x5c(%eax)
f0103398:	e8 57 de ff ff       	call   f01011f4 <pgdir_walk>
			if (pte_p && *pte_p && (*pte_p & required_perm)) {
f010339d:	83 c4 10             	add    $0x10,%esp
f01033a0:	85 c0                	test   %eax,%eax
f01033a2:	74 0b                	je     f01033af <user_mem_check+0x6a>
f01033a4:	8b 00                	mov    (%eax),%eax
f01033a6:	85 c0                	test   %eax,%eax
f01033a8:	74 05                	je     f01033af <user_mem_check+0x6a>
f01033aa:	85 45 e0             	test   %eax,-0x20(%ebp)
f01033ad:	75 17                	jne    f01033c6 <user_mem_check+0x81>
		if (addr < (uintptr_t)va) {
f01033af:	39 f3                	cmp    %esi,%ebx
f01033b1:	73 1b                	jae    f01033ce <user_mem_check+0x89>
			user_mem_check_addr = (uintptr_t)va;
f01033b3:	89 b7 1c 23 00 00    	mov    %esi,0x231c(%edi)
		return -E_FAULT;
f01033b9:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
}
f01033be:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01033c1:	5b                   	pop    %ebx
f01033c2:	5e                   	pop    %esi
f01033c3:	5f                   	pop    %edi
f01033c4:	5d                   	pop    %ebp
f01033c5:	c3                   	ret    
	for(addr = start; addr < end; addr += PGSIZE) {
f01033c6:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01033cc:	eb b1                	jmp    f010337f <user_mem_check+0x3a>
			user_mem_check_addr = addr;
f01033ce:	89 9f 1c 23 00 00    	mov    %ebx,0x231c(%edi)
		return -E_FAULT;
f01033d4:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01033d9:	eb e3                	jmp    f01033be <user_mem_check+0x79>
	return 0;
f01033db:	b8 00 00 00 00       	mov    $0x0,%eax
f01033e0:	eb dc                	jmp    f01033be <user_mem_check+0x79>

f01033e2 <user_mem_assert>:
{
f01033e2:	55                   	push   %ebp
f01033e3:	89 e5                	mov    %esp,%ebp
f01033e5:	56                   	push   %esi
f01033e6:	53                   	push   %ebx
f01033e7:	e8 7b cd ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01033ec:	81 c3 34 9c 08 00    	add    $0x89c34,%ebx
f01033f2:	8b 75 08             	mov    0x8(%ebp),%esi
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f01033f5:	8b 45 14             	mov    0x14(%ebp),%eax
f01033f8:	83 c8 04             	or     $0x4,%eax
f01033fb:	50                   	push   %eax
f01033fc:	ff 75 10             	pushl  0x10(%ebp)
f01033ff:	ff 75 0c             	pushl  0xc(%ebp)
f0103402:	56                   	push   %esi
f0103403:	e8 3d ff ff ff       	call   f0103345 <user_mem_check>
f0103408:	83 c4 10             	add    $0x10,%esp
f010340b:	85 c0                	test   %eax,%eax
f010340d:	78 07                	js     f0103416 <user_mem_assert+0x34>
}
f010340f:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103412:	5b                   	pop    %ebx
f0103413:	5e                   	pop    %esi
f0103414:	5d                   	pop    %ebp
f0103415:	c3                   	ret    
		cprintf("[%08x] user_mem_check assertion failure for "
f0103416:	83 ec 04             	sub    $0x4,%esp
f0103419:	ff b3 1c 23 00 00    	pushl  0x231c(%ebx)
f010341f:	ff 76 48             	pushl  0x48(%esi)
f0103422:	8d 83 40 97 f7 ff    	lea    -0x868c0(%ebx),%eax
f0103428:	50                   	push   %eax
f0103429:	e8 90 08 00 00       	call   f0103cbe <cprintf>
		env_destroy(env);	// may not return
f010342e:	89 34 24             	mov    %esi,(%esp)
f0103431:	e8 1a 07 00 00       	call   f0103b50 <env_destroy>
f0103436:	83 c4 10             	add    $0x10,%esp
}
f0103439:	eb d4                	jmp    f010340f <user_mem_assert+0x2d>

f010343b <__x86.get_pc_thunk.cx>:
f010343b:	8b 0c 24             	mov    (%esp),%ecx
f010343e:	c3                   	ret    

f010343f <__x86.get_pc_thunk.di>:
f010343f:	8b 3c 24             	mov    (%esp),%edi
f0103442:	c3                   	ret    

f0103443 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0103443:	55                   	push   %ebp
f0103444:	89 e5                	mov    %esp,%ebp
f0103446:	57                   	push   %edi
f0103447:	56                   	push   %esi
f0103448:	53                   	push   %ebx
f0103449:	83 ec 1c             	sub    $0x1c,%esp
f010344c:	e8 16 cd ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103451:	81 c3 cf 9b 08 00    	add    $0x89bcf,%ebx
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)

	// Corner case: e equals to NULL
	if(e == 0)
f0103457:	85 c0                	test   %eax,%eax
f0103459:	74 52                	je     f01034ad <region_alloc+0x6a>
f010345b:	89 c7                	mov    %eax,%edi
		panic("The struct Env could not be NULL");

	// corner case: len equals to 0
	if(len == 0)
f010345d:	85 c9                	test   %ecx,%ecx
f010345f:	0f 84 99 00 00 00    	je     f01034fe <region_alloc+0xbb>
		return;

	uintptr_t start = (uintptr_t)ROUNDDOWN(va, PGSIZE);
f0103465:	89 d6                	mov    %edx,%esi
f0103467:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	uintptr_t end = (uintptr_t)ROUNDUP(va + len, PGSIZE);
f010346d:	8d 84 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%eax
f0103474:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0103479:	89 45 e4             	mov    %eax,-0x1c(%ebp)

	for(uintptr_t vaddr = start; vaddr < end; vaddr += PGSIZE) {
f010347c:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f010347f:	73 7d                	jae    f01034fe <region_alloc+0xbb>
		struct PageInfo* pginfo_p = page_alloc(0);
f0103481:	83 ec 0c             	sub    $0xc,%esp
f0103484:	6a 00                	push   $0x0
f0103486:	e8 48 dc ff ff       	call   f01010d3 <page_alloc>
		if (pginfo_p == NULL) {
f010348b:	83 c4 10             	add    $0x10,%esp
f010348e:	85 c0                	test   %eax,%eax
f0103490:	74 36                	je     f01034c8 <region_alloc+0x85>
			panic("Cannot allocate physical page");
		}
		if (page_insert(e->env_pgdir, pginfo_p, (void *)vaddr, PTE_P | PTE_U | PTE_W) < 0) {
f0103492:	6a 07                	push   $0x7
f0103494:	56                   	push   %esi
f0103495:	50                   	push   %eax
f0103496:	ff 77 5c             	pushl  0x5c(%edi)
f0103499:	e8 d0 df ff ff       	call   f010146e <page_insert>
f010349e:	83 c4 10             	add    $0x10,%esp
f01034a1:	85 c0                	test   %eax,%eax
f01034a3:	78 3e                	js     f01034e3 <region_alloc+0xa0>
	for(uintptr_t vaddr = start; vaddr < end; vaddr += PGSIZE) {
f01034a5:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01034ab:	eb cf                	jmp    f010347c <region_alloc+0x39>
		panic("The struct Env could not be NULL");
f01034ad:	83 ec 04             	sub    $0x4,%esp
f01034b0:	8d 83 78 97 f7 ff    	lea    -0x86888(%ebx),%eax
f01034b6:	50                   	push   %eax
f01034b7:	68 2b 01 00 00       	push   $0x12b
f01034bc:	8d 83 d2 97 f7 ff    	lea    -0x8682e(%ebx),%eax
f01034c2:	50                   	push   %eax
f01034c3:	e8 e9 cb ff ff       	call   f01000b1 <_panic>
			panic("Cannot allocate physical page");
f01034c8:	83 ec 04             	sub    $0x4,%esp
f01034cb:	8d 83 dd 97 f7 ff    	lea    -0x86823(%ebx),%eax
f01034d1:	50                   	push   %eax
f01034d2:	68 37 01 00 00       	push   $0x137
f01034d7:	8d 83 d2 97 f7 ff    	lea    -0x8682e(%ebx),%eax
f01034dd:	50                   	push   %eax
f01034de:	e8 ce cb ff ff       	call   f01000b1 <_panic>
			panic("page insertion failed.");
f01034e3:	83 ec 04             	sub    $0x4,%esp
f01034e6:	8d 83 fb 97 f7 ff    	lea    -0x86805(%ebx),%eax
f01034ec:	50                   	push   %eax
f01034ed:	68 3a 01 00 00       	push   $0x13a
f01034f2:	8d 83 d2 97 f7 ff    	lea    -0x8682e(%ebx),%eax
f01034f8:	50                   	push   %eax
f01034f9:	e8 b3 cb ff ff       	call   f01000b1 <_panic>
		}
	}
}
f01034fe:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103501:	5b                   	pop    %ebx
f0103502:	5e                   	pop    %esi
f0103503:	5f                   	pop    %edi
f0103504:	5d                   	pop    %ebp
f0103505:	c3                   	ret    

f0103506 <envid2env>:
{
f0103506:	55                   	push   %ebp
f0103507:	89 e5                	mov    %esp,%ebp
f0103509:	53                   	push   %ebx
f010350a:	e8 2c ff ff ff       	call   f010343b <__x86.get_pc_thunk.cx>
f010350f:	81 c1 11 9b 08 00    	add    $0x89b11,%ecx
f0103515:	8b 55 08             	mov    0x8(%ebp),%edx
f0103518:	8b 5d 10             	mov    0x10(%ebp),%ebx
	if (envid == 0) {
f010351b:	85 d2                	test   %edx,%edx
f010351d:	74 41                	je     f0103560 <envid2env+0x5a>
	e = &envs[ENVX(envid)];
f010351f:	89 d0                	mov    %edx,%eax
f0103521:	25 ff 03 00 00       	and    $0x3ff,%eax
f0103526:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103529:	c1 e0 05             	shl    $0x5,%eax
f010352c:	03 81 2c 23 00 00    	add    0x232c(%ecx),%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103532:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f0103536:	74 3a                	je     f0103572 <envid2env+0x6c>
f0103538:	39 50 48             	cmp    %edx,0x48(%eax)
f010353b:	75 35                	jne    f0103572 <envid2env+0x6c>
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f010353d:	84 db                	test   %bl,%bl
f010353f:	74 12                	je     f0103553 <envid2env+0x4d>
f0103541:	8b 91 28 23 00 00    	mov    0x2328(%ecx),%edx
f0103547:	39 c2                	cmp    %eax,%edx
f0103549:	74 08                	je     f0103553 <envid2env+0x4d>
f010354b:	8b 5a 48             	mov    0x48(%edx),%ebx
f010354e:	39 58 4c             	cmp    %ebx,0x4c(%eax)
f0103551:	75 2f                	jne    f0103582 <envid2env+0x7c>
	*env_store = e;
f0103553:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103556:	89 03                	mov    %eax,(%ebx)
	return 0;
f0103558:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010355d:	5b                   	pop    %ebx
f010355e:	5d                   	pop    %ebp
f010355f:	c3                   	ret    
		*env_store = curenv;
f0103560:	8b 81 28 23 00 00    	mov    0x2328(%ecx),%eax
f0103566:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103569:	89 01                	mov    %eax,(%ecx)
		return 0;
f010356b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103570:	eb eb                	jmp    f010355d <envid2env+0x57>
		*env_store = 0;
f0103572:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103575:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010357b:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103580:	eb db                	jmp    f010355d <envid2env+0x57>
		*env_store = 0;
f0103582:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103585:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010358b:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103590:	eb cb                	jmp    f010355d <envid2env+0x57>

f0103592 <env_init_percpu>:
{
f0103592:	55                   	push   %ebp
f0103593:	89 e5                	mov    %esp,%ebp
f0103595:	e8 6f d1 ff ff       	call   f0100709 <__x86.get_pc_thunk.ax>
f010359a:	05 86 9a 08 00       	add    $0x89a86,%eax
	asm volatile("lgdt (%0)" : : "r" (p));
f010359f:	8d 80 e0 1f 00 00    	lea    0x1fe0(%eax),%eax
f01035a5:	0f 01 10             	lgdtl  (%eax)
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f01035a8:	b8 23 00 00 00       	mov    $0x23,%eax
f01035ad:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f01035af:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f01035b1:	b8 10 00 00 00       	mov    $0x10,%eax
f01035b6:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f01035b8:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f01035ba:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f01035bc:	ea c3 35 10 f0 08 00 	ljmp   $0x8,$0xf01035c3
	asm volatile("lldt %0" : : "r" (sel));
f01035c3:	b8 00 00 00 00       	mov    $0x0,%eax
f01035c8:	0f 00 d0             	lldt   %ax
}
f01035cb:	5d                   	pop    %ebp
f01035cc:	c3                   	ret    

f01035cd <env_init>:
{
f01035cd:	55                   	push   %ebp
f01035ce:	89 e5                	mov    %esp,%ebp
f01035d0:	57                   	push   %edi
f01035d1:	56                   	push   %esi
f01035d2:	53                   	push   %ebx
f01035d3:	e8 5b 06 00 00       	call   f0103c33 <__x86.get_pc_thunk.si>
f01035d8:	81 c6 48 9a 08 00    	add    $0x89a48,%esi
		(envs + i)->env_status = ENV_FREE;
f01035de:	8b be 2c 23 00 00    	mov    0x232c(%esi),%edi
f01035e4:	8b 96 30 23 00 00    	mov    0x2330(%esi),%edx
f01035ea:	8d 87 a0 7f 01 00    	lea    0x17fa0(%edi),%eax
f01035f0:	8d 5f a0             	lea    -0x60(%edi),%ebx
f01035f3:	89 c1                	mov    %eax,%ecx
f01035f5:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
		(envs + i)->env_id = 0;
f01035fc:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		(envs + i)->env_link = env_free_list;
f0103603:	89 50 44             	mov    %edx,0x44(%eax)
f0103606:	83 e8 60             	sub    $0x60,%eax
		env_free_list = (envs + i);
f0103609:	89 ca                	mov    %ecx,%edx
	for(int i = NENV - 1; i >= 0; --i) {
f010360b:	39 d8                	cmp    %ebx,%eax
f010360d:	75 e4                	jne    f01035f3 <env_init+0x26>
f010360f:	89 be 30 23 00 00    	mov    %edi,0x2330(%esi)
	env_init_percpu();
f0103615:	e8 78 ff ff ff       	call   f0103592 <env_init_percpu>
}
f010361a:	5b                   	pop    %ebx
f010361b:	5e                   	pop    %esi
f010361c:	5f                   	pop    %edi
f010361d:	5d                   	pop    %ebp
f010361e:	c3                   	ret    

f010361f <env_alloc>:
{
f010361f:	55                   	push   %ebp
f0103620:	89 e5                	mov    %esp,%ebp
f0103622:	57                   	push   %edi
f0103623:	56                   	push   %esi
f0103624:	53                   	push   %ebx
f0103625:	83 ec 0c             	sub    $0xc,%esp
f0103628:	e8 3a cb ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010362d:	81 c3 f3 99 08 00    	add    $0x899f3,%ebx
	if (!(e = env_free_list))
f0103633:	8b b3 30 23 00 00    	mov    0x2330(%ebx),%esi
f0103639:	85 f6                	test   %esi,%esi
f010363b:	0f 84 79 01 00 00    	je     f01037ba <env_alloc+0x19b>
	if (!(p = page_alloc(ALLOC_ZERO)))
f0103641:	83 ec 0c             	sub    $0xc,%esp
f0103644:	6a 01                	push   $0x1
f0103646:	e8 88 da ff ff       	call   f01010d3 <page_alloc>
f010364b:	89 c7                	mov    %eax,%edi
f010364d:	83 c4 10             	add    $0x10,%esp
f0103650:	85 c0                	test   %eax,%eax
f0103652:	0f 84 69 01 00 00    	je     f01037c1 <env_alloc+0x1a2>
	return (pp - pages) << PGSHIFT;
f0103658:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f010365e:	89 f9                	mov    %edi,%ecx
f0103660:	2b 08                	sub    (%eax),%ecx
f0103662:	89 c8                	mov    %ecx,%eax
f0103664:	c1 f8 03             	sar    $0x3,%eax
f0103667:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f010366a:	89 c1                	mov    %eax,%ecx
f010366c:	c1 e9 0c             	shr    $0xc,%ecx
f010366f:	c7 c2 04 00 19 f0    	mov    $0xf0190004,%edx
f0103675:	3b 0a                	cmp    (%edx),%ecx
f0103677:	0f 83 0e 01 00 00    	jae    f010378b <env_alloc+0x16c>
	return (void *)(pa + KERNBASE);
f010367d:	2d 00 00 00 10       	sub    $0x10000000,%eax
	e->env_pgdir = (pde_t *)page2kva(p);
f0103682:	89 46 5c             	mov    %eax,0x5c(%esi)
	memset(e->env_pgdir, 0, PGSIZE);
f0103685:	83 ec 04             	sub    $0x4,%esp
f0103688:	68 00 10 00 00       	push   $0x1000
f010368d:	6a 00                	push   $0x0
f010368f:	50                   	push   %eax
f0103690:	e8 b1 1c 00 00       	call   f0105346 <memset>
	p->pp_ref += 1;
f0103695:	66 83 47 04 01       	addw   $0x1,0x4(%edi)
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE);
f010369a:	83 c4 0c             	add    $0xc,%esp
f010369d:	68 00 10 00 00       	push   $0x1000
f01036a2:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f01036a8:	ff 30                	pushl  (%eax)
f01036aa:	ff 76 5c             	pushl  0x5c(%esi)
f01036ad:	e8 49 1d 00 00       	call   f01053fb <memcpy>
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f01036b2:	8b 46 5c             	mov    0x5c(%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f01036b5:	83 c4 10             	add    $0x10,%esp
f01036b8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01036bd:	0f 86 de 00 00 00    	jbe    f01037a1 <env_alloc+0x182>
	return (physaddr_t)kva - KERNBASE;
f01036c3:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01036c9:	83 ca 05             	or     $0x5,%edx
f01036cc:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01036d2:	8b 46 48             	mov    0x48(%esi),%eax
f01036d5:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01036da:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f01036df:	ba 00 10 00 00       	mov    $0x1000,%edx
f01036e4:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01036e7:	89 f2                	mov    %esi,%edx
f01036e9:	2b 93 2c 23 00 00    	sub    0x232c(%ebx),%edx
f01036ef:	c1 fa 05             	sar    $0x5,%edx
f01036f2:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01036f8:	09 d0                	or     %edx,%eax
f01036fa:	89 46 48             	mov    %eax,0x48(%esi)
	e->env_parent_id = parent_id;
f01036fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103700:	89 46 4c             	mov    %eax,0x4c(%esi)
	e->env_type = ENV_TYPE_USER;
f0103703:	c7 46 50 00 00 00 00 	movl   $0x0,0x50(%esi)
	e->env_status = ENV_RUNNABLE;
f010370a:	c7 46 54 02 00 00 00 	movl   $0x2,0x54(%esi)
	e->env_runs = 0;
f0103711:	c7 46 58 00 00 00 00 	movl   $0x0,0x58(%esi)
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0103718:	83 ec 04             	sub    $0x4,%esp
f010371b:	6a 44                	push   $0x44
f010371d:	6a 00                	push   $0x0
f010371f:	56                   	push   %esi
f0103720:	e8 21 1c 00 00       	call   f0105346 <memset>
	e->env_tf.tf_ds = GD_UD | 3;
f0103725:	66 c7 46 24 23 00    	movw   $0x23,0x24(%esi)
	e->env_tf.tf_es = GD_UD | 3;
f010372b:	66 c7 46 20 23 00    	movw   $0x23,0x20(%esi)
	e->env_tf.tf_ss = GD_UD | 3;
f0103731:	66 c7 46 40 23 00    	movw   $0x23,0x40(%esi)
	e->env_tf.tf_esp = USTACKTOP;
f0103737:	c7 46 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%esi)
	e->env_tf.tf_cs = GD_UT | 3;
f010373e:	66 c7 46 34 1b 00    	movw   $0x1b,0x34(%esi)
	env_free_list = e->env_link;
f0103744:	8b 46 44             	mov    0x44(%esi),%eax
f0103747:	89 83 30 23 00 00    	mov    %eax,0x2330(%ebx)
	*newenv_store = e;
f010374d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103750:	89 30                	mov    %esi,(%eax)
	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103752:	8b 4e 48             	mov    0x48(%esi),%ecx
f0103755:	8b 83 28 23 00 00    	mov    0x2328(%ebx),%eax
f010375b:	83 c4 10             	add    $0x10,%esp
f010375e:	ba 00 00 00 00       	mov    $0x0,%edx
f0103763:	85 c0                	test   %eax,%eax
f0103765:	74 03                	je     f010376a <env_alloc+0x14b>
f0103767:	8b 50 48             	mov    0x48(%eax),%edx
f010376a:	83 ec 04             	sub    $0x4,%esp
f010376d:	51                   	push   %ecx
f010376e:	52                   	push   %edx
f010376f:	8d 83 12 98 f7 ff    	lea    -0x867ee(%ebx),%eax
f0103775:	50                   	push   %eax
f0103776:	e8 43 05 00 00       	call   f0103cbe <cprintf>
	return 0;
f010377b:	83 c4 10             	add    $0x10,%esp
f010377e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103783:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103786:	5b                   	pop    %ebx
f0103787:	5e                   	pop    %esi
f0103788:	5f                   	pop    %edi
f0103789:	5d                   	pop    %ebp
f010378a:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010378b:	50                   	push   %eax
f010378c:	8d 83 94 8f f7 ff    	lea    -0x8706c(%ebx),%eax
f0103792:	50                   	push   %eax
f0103793:	6a 56                	push   $0x56
f0103795:	8d 83 82 8c f7 ff    	lea    -0x8737e(%ebx),%eax
f010379b:	50                   	push   %eax
f010379c:	e8 10 c9 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01037a1:	50                   	push   %eax
f01037a2:	8d 83 a0 90 f7 ff    	lea    -0x86f60(%ebx),%eax
f01037a8:	50                   	push   %eax
f01037a9:	68 d4 00 00 00       	push   $0xd4
f01037ae:	8d 83 d2 97 f7 ff    	lea    -0x8682e(%ebx),%eax
f01037b4:	50                   	push   %eax
f01037b5:	e8 f7 c8 ff ff       	call   f01000b1 <_panic>
		return -E_NO_FREE_ENV;
f01037ba:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f01037bf:	eb c2                	jmp    f0103783 <env_alloc+0x164>
		return -E_NO_MEM;
f01037c1:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f01037c6:	eb bb                	jmp    f0103783 <env_alloc+0x164>

f01037c8 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f01037c8:	55                   	push   %ebp
f01037c9:	89 e5                	mov    %esp,%ebp
f01037cb:	57                   	push   %edi
f01037cc:	56                   	push   %esi
f01037cd:	53                   	push   %ebx
f01037ce:	83 ec 2c             	sub    $0x2c,%esp
f01037d1:	e8 91 c9 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01037d6:	81 c3 4a 98 08 00    	add    $0x8984a,%ebx
	// LAB 3: Your code here.
	if (env_free_list == NULL) {
f01037dc:	83 bb 30 23 00 00 00 	cmpl   $0x0,0x2330(%ebx)
f01037e3:	74 52                	je     f0103837 <env_create+0x6f>
		panic("No more free env");
		return;
	}

	struct Env *curr_env;
	if (env_alloc(&curr_env, 0) < 0) {
f01037e5:	83 ec 08             	sub    $0x8,%esp
f01037e8:	6a 00                	push   $0x0
f01037ea:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01037ed:	50                   	push   %eax
f01037ee:	e8 2c fe ff ff       	call   f010361f <env_alloc>
f01037f3:	83 c4 10             	add    $0x10,%esp
f01037f6:	85 c0                	test   %eax,%eax
f01037f8:	78 58                	js     f0103852 <env_create+0x8a>
		panic("Cannot allocate new env");
	}

	load_icode(curr_env, binary);
f01037fa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01037fd:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	if (elf->e_magic != ELF_MAGIC) {
f0103800:	8b 45 08             	mov    0x8(%ebp),%eax
f0103803:	81 38 7f 45 4c 46    	cmpl   $0x464c457f,(%eax)
f0103809:	75 62                	jne    f010386d <env_create+0xa5>
	lcr3(PADDR(e->env_pgdir));
f010380b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010380e:	8b 40 5c             	mov    0x5c(%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0103811:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103816:	76 70                	jbe    f0103888 <env_create+0xc0>
	return (physaddr_t)kva - KERNBASE;
f0103818:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f010381d:	0f 22 d8             	mov    %eax,%cr3
	struct Proghdr* ph = (struct Proghdr*)((uint32_t)binary + elf->e_phoff);
f0103820:	8b 45 08             	mov    0x8(%ebp),%eax
f0103823:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0103826:	89 c6                	mov    %eax,%esi
f0103828:	03 70 1c             	add    0x1c(%eax),%esi
	struct Proghdr* eph = ph + ((struct Elf*)binary)->e_phnum;
f010382b:	0f b7 40 2c          	movzwl 0x2c(%eax),%eax
f010382f:	c1 e0 05             	shl    $0x5,%eax
f0103832:	8d 3c 06             	lea    (%esi,%eax,1),%edi
f0103835:	eb 6d                	jmp    f01038a4 <env_create+0xdc>
		panic("No more free env");
f0103837:	83 ec 04             	sub    $0x4,%esp
f010383a:	8d 83 27 98 f7 ff    	lea    -0x867d9(%ebx),%eax
f0103840:	50                   	push   %eax
f0103841:	68 d5 01 00 00       	push   $0x1d5
f0103846:	8d 83 d2 97 f7 ff    	lea    -0x8682e(%ebx),%eax
f010384c:	50                   	push   %eax
f010384d:	e8 5f c8 ff ff       	call   f01000b1 <_panic>
		panic("Cannot allocate new env");
f0103852:	83 ec 04             	sub    $0x4,%esp
f0103855:	8d 83 38 98 f7 ff    	lea    -0x867c8(%ebx),%eax
f010385b:	50                   	push   %eax
f010385c:	68 db 01 00 00       	push   $0x1db
f0103861:	8d 83 d2 97 f7 ff    	lea    -0x8682e(%ebx),%eax
f0103867:	50                   	push   %eax
f0103868:	e8 44 c8 ff ff       	call   f01000b1 <_panic>
		panic("Not ELF format");
f010386d:	83 ec 04             	sub    $0x4,%esp
f0103870:	8d 83 50 98 f7 ff    	lea    -0x867b0(%ebx),%eax
f0103876:	50                   	push   %eax
f0103877:	68 77 01 00 00       	push   $0x177
f010387c:	8d 83 d2 97 f7 ff    	lea    -0x8682e(%ebx),%eax
f0103882:	50                   	push   %eax
f0103883:	e8 29 c8 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103888:	50                   	push   %eax
f0103889:	8d 83 a0 90 f7 ff    	lea    -0x86f60(%ebx),%eax
f010388f:	50                   	push   %eax
f0103890:	68 83 01 00 00       	push   $0x183
f0103895:	8d 83 d2 97 f7 ff    	lea    -0x8682e(%ebx),%eax
f010389b:	50                   	push   %eax
f010389c:	e8 10 c8 ff ff       	call   f01000b1 <_panic>
	for(; ph < eph; ph++) {
f01038a1:	83 c6 20             	add    $0x20,%esi
f01038a4:	39 f7                	cmp    %esi,%edi
f01038a6:	76 42                	jbe    f01038ea <env_create+0x122>
		if (ph->p_type == ELF_PROG_LOAD) {
f01038a8:	83 3e 01             	cmpl   $0x1,(%esi)
f01038ab:	75 f4                	jne    f01038a1 <env_create+0xd9>
			va = (uint32_t)binary + ph->p_offset;
f01038ad:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01038b0:	03 46 04             	add    0x4(%esi),%eax
f01038b3:	89 45 d0             	mov    %eax,-0x30(%ebp)
            region_alloc(e, (void *)ph->p_va, ph->p_memsz);
f01038b6:	8b 4e 14             	mov    0x14(%esi),%ecx
f01038b9:	8b 56 08             	mov    0x8(%esi),%edx
f01038bc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01038bf:	e8 7f fb ff ff       	call   f0103443 <region_alloc>
            memset((void*)ph->p_va, 0, ph->p_memsz);
f01038c4:	83 ec 04             	sub    $0x4,%esp
f01038c7:	ff 76 14             	pushl  0x14(%esi)
f01038ca:	6a 00                	push   $0x0
f01038cc:	ff 76 08             	pushl  0x8(%esi)
f01038cf:	e8 72 1a 00 00       	call   f0105346 <memset>
            memcpy((void*)ph->p_va, (void*)va, ph->p_filesz);
f01038d4:	83 c4 0c             	add    $0xc,%esp
f01038d7:	ff 76 10             	pushl  0x10(%esi)
f01038da:	ff 75 d0             	pushl  -0x30(%ebp)
f01038dd:	ff 76 08             	pushl  0x8(%esi)
f01038e0:	e8 16 1b 00 00       	call   f01053fb <memcpy>
f01038e5:	83 c4 10             	add    $0x10,%esp
f01038e8:	eb b7                	jmp    f01038a1 <env_create+0xd9>
	region_alloc(e, (void*)(USTACKTOP - PGSIZE), PGSIZE);
f01038ea:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01038ef:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01038f4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01038f7:	e8 47 fb ff ff       	call   f0103443 <region_alloc>
	lcr3(PADDR(kern_pgdir));
f01038fc:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f0103902:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0103904:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103909:	76 25                	jbe    f0103930 <env_create+0x168>
	return (physaddr_t)kva - KERNBASE;
f010390b:	05 00 00 00 10       	add    $0x10000000,%eax
f0103910:	0f 22 d8             	mov    %eax,%cr3
	e->env_tf.tf_eip = elf->e_entry;
f0103913:	8b 45 08             	mov    0x8(%ebp),%eax
f0103916:	8b 40 18             	mov    0x18(%eax),%eax
f0103919:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010391c:	89 41 30             	mov    %eax,0x30(%ecx)
	curr_env->env_type = type;
f010391f:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103922:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103925:	89 50 50             	mov    %edx,0x50(%eax)
}
f0103928:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010392b:	5b                   	pop    %ebx
f010392c:	5e                   	pop    %esi
f010392d:	5f                   	pop    %edi
f010392e:	5d                   	pop    %ebp
f010392f:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103930:	50                   	push   %eax
f0103931:	8d 83 a0 90 f7 ff    	lea    -0x86f60(%ebx),%eax
f0103937:	50                   	push   %eax
f0103938:	68 9a 01 00 00       	push   $0x19a
f010393d:	8d 83 d2 97 f7 ff    	lea    -0x8682e(%ebx),%eax
f0103943:	50                   	push   %eax
f0103944:	e8 68 c7 ff ff       	call   f01000b1 <_panic>

f0103949 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103949:	55                   	push   %ebp
f010394a:	89 e5                	mov    %esp,%ebp
f010394c:	57                   	push   %edi
f010394d:	56                   	push   %esi
f010394e:	53                   	push   %ebx
f010394f:	83 ec 2c             	sub    $0x2c,%esp
f0103952:	e8 10 c8 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103957:	81 c3 c9 96 08 00    	add    $0x896c9,%ebx
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f010395d:	8b 93 28 23 00 00    	mov    0x2328(%ebx),%edx
f0103963:	3b 55 08             	cmp    0x8(%ebp),%edx
f0103966:	75 17                	jne    f010397f <env_free+0x36>
		lcr3(PADDR(kern_pgdir));
f0103968:	c7 c0 08 00 19 f0    	mov    $0xf0190008,%eax
f010396e:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0103970:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103975:	76 46                	jbe    f01039bd <env_free+0x74>
	return (physaddr_t)kva - KERNBASE;
f0103977:	05 00 00 00 10       	add    $0x10000000,%eax
f010397c:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f010397f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103982:	8b 48 48             	mov    0x48(%eax),%ecx
f0103985:	b8 00 00 00 00       	mov    $0x0,%eax
f010398a:	85 d2                	test   %edx,%edx
f010398c:	74 03                	je     f0103991 <env_free+0x48>
f010398e:	8b 42 48             	mov    0x48(%edx),%eax
f0103991:	83 ec 04             	sub    $0x4,%esp
f0103994:	51                   	push   %ecx
f0103995:	50                   	push   %eax
f0103996:	8d 83 5f 98 f7 ff    	lea    -0x867a1(%ebx),%eax
f010399c:	50                   	push   %eax
f010399d:	e8 1c 03 00 00       	call   f0103cbe <cprintf>
f01039a2:	83 c4 10             	add    $0x10,%esp
f01039a5:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	if (PGNUM(pa) >= npages)
f01039ac:	c7 c0 04 00 19 f0    	mov    $0xf0190004,%eax
f01039b2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	if (PGNUM(pa) >= npages)
f01039b5:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01039b8:	e9 9f 00 00 00       	jmp    f0103a5c <env_free+0x113>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01039bd:	50                   	push   %eax
f01039be:	8d 83 a0 90 f7 ff    	lea    -0x86f60(%ebx),%eax
f01039c4:	50                   	push   %eax
f01039c5:	68 f0 01 00 00       	push   $0x1f0
f01039ca:	8d 83 d2 97 f7 ff    	lea    -0x8682e(%ebx),%eax
f01039d0:	50                   	push   %eax
f01039d1:	e8 db c6 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01039d6:	50                   	push   %eax
f01039d7:	8d 83 94 8f f7 ff    	lea    -0x8706c(%ebx),%eax
f01039dd:	50                   	push   %eax
f01039de:	68 ff 01 00 00       	push   $0x1ff
f01039e3:	8d 83 d2 97 f7 ff    	lea    -0x8682e(%ebx),%eax
f01039e9:	50                   	push   %eax
f01039ea:	e8 c2 c6 ff ff       	call   f01000b1 <_panic>
f01039ef:	83 c6 04             	add    $0x4,%esi
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01039f2:	39 fe                	cmp    %edi,%esi
f01039f4:	74 24                	je     f0103a1a <env_free+0xd1>
			if (pt[pteno] & PTE_P)
f01039f6:	f6 06 01             	testb  $0x1,(%esi)
f01039f9:	74 f4                	je     f01039ef <env_free+0xa6>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f01039fb:	83 ec 08             	sub    $0x8,%esp
f01039fe:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103a01:	01 f0                	add    %esi,%eax
f0103a03:	c1 e0 0a             	shl    $0xa,%eax
f0103a06:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103a09:	50                   	push   %eax
f0103a0a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a0d:	ff 70 5c             	pushl  0x5c(%eax)
f0103a10:	e8 02 da ff ff       	call   f0101417 <page_remove>
f0103a15:	83 c4 10             	add    $0x10,%esp
f0103a18:	eb d5                	jmp    f01039ef <env_free+0xa6>
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103a1a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a1d:	8b 40 5c             	mov    0x5c(%eax),%eax
f0103a20:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103a23:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
	if (PGNUM(pa) >= npages)
f0103a2a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0103a2d:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103a30:	3b 10                	cmp    (%eax),%edx
f0103a32:	73 6f                	jae    f0103aa3 <env_free+0x15a>
		page_decref(pa2page(pa));
f0103a34:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0103a37:	c7 c0 0c 00 19 f0    	mov    $0xf019000c,%eax
f0103a3d:	8b 00                	mov    (%eax),%eax
f0103a3f:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103a42:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f0103a45:	50                   	push   %eax
f0103a46:	e8 80 d7 ff ff       	call   f01011cb <page_decref>
f0103a4b:	83 c4 10             	add    $0x10,%esp
f0103a4e:	83 45 dc 04          	addl   $0x4,-0x24(%ebp)
f0103a52:	8b 45 dc             	mov    -0x24(%ebp),%eax
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103a55:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f0103a5a:	74 5f                	je     f0103abb <env_free+0x172>
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103a5c:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a5f:	8b 40 5c             	mov    0x5c(%eax),%eax
f0103a62:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103a65:	8b 04 10             	mov    (%eax,%edx,1),%eax
f0103a68:	a8 01                	test   $0x1,%al
f0103a6a:	74 e2                	je     f0103a4e <env_free+0x105>
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103a6c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0103a71:	89 c2                	mov    %eax,%edx
f0103a73:	c1 ea 0c             	shr    $0xc,%edx
f0103a76:	89 55 d8             	mov    %edx,-0x28(%ebp)
f0103a79:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0103a7c:	39 11                	cmp    %edx,(%ecx)
f0103a7e:	0f 86 52 ff ff ff    	jbe    f01039d6 <env_free+0x8d>
	return (void *)(pa + KERNBASE);
f0103a84:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103a8a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103a8d:	c1 e2 14             	shl    $0x14,%edx
f0103a90:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103a93:	8d b8 00 10 00 f0    	lea    -0xffff000(%eax),%edi
f0103a99:	f7 d8                	neg    %eax
f0103a9b:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0103a9e:	e9 53 ff ff ff       	jmp    f01039f6 <env_free+0xad>
		panic("pa2page called with invalid pa");
f0103aa3:	83 ec 04             	sub    $0x4,%esp
f0103aa6:	8d 83 c4 90 f7 ff    	lea    -0x86f3c(%ebx),%eax
f0103aac:	50                   	push   %eax
f0103aad:	6a 4f                	push   $0x4f
f0103aaf:	8d 83 82 8c f7 ff    	lea    -0x8737e(%ebx),%eax
f0103ab5:	50                   	push   %eax
f0103ab6:	e8 f6 c5 ff ff       	call   f01000b1 <_panic>
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103abb:	8b 45 08             	mov    0x8(%ebp),%eax
f0103abe:	8b 40 5c             	mov    0x5c(%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0103ac1:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103ac6:	76 57                	jbe    f0103b1f <env_free+0x1d6>
	e->env_pgdir = 0;
f0103ac8:	8b 55 08             	mov    0x8(%ebp),%edx
f0103acb:	c7 42 5c 00 00 00 00 	movl   $0x0,0x5c(%edx)
	return (physaddr_t)kva - KERNBASE;
f0103ad2:	05 00 00 00 10       	add    $0x10000000,%eax
	if (PGNUM(pa) >= npages)
f0103ad7:	c1 e8 0c             	shr    $0xc,%eax
f0103ada:	c7 c2 04 00 19 f0    	mov    $0xf0190004,%edx
f0103ae0:	3b 02                	cmp    (%edx),%eax
f0103ae2:	73 54                	jae    f0103b38 <env_free+0x1ef>
	page_decref(pa2page(pa));
f0103ae4:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0103ae7:	c7 c2 0c 00 19 f0    	mov    $0xf019000c,%edx
f0103aed:	8b 12                	mov    (%edx),%edx
f0103aef:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0103af2:	50                   	push   %eax
f0103af3:	e8 d3 d6 ff ff       	call   f01011cb <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103af8:	8b 45 08             	mov    0x8(%ebp),%eax
f0103afb:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
	e->env_link = env_free_list;
f0103b02:	8b 83 30 23 00 00    	mov    0x2330(%ebx),%eax
f0103b08:	8b 55 08             	mov    0x8(%ebp),%edx
f0103b0b:	89 42 44             	mov    %eax,0x44(%edx)
	env_free_list = e;
f0103b0e:	89 93 30 23 00 00    	mov    %edx,0x2330(%ebx)
}
f0103b14:	83 c4 10             	add    $0x10,%esp
f0103b17:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103b1a:	5b                   	pop    %ebx
f0103b1b:	5e                   	pop    %esi
f0103b1c:	5f                   	pop    %edi
f0103b1d:	5d                   	pop    %ebp
f0103b1e:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103b1f:	50                   	push   %eax
f0103b20:	8d 83 a0 90 f7 ff    	lea    -0x86f60(%ebx),%eax
f0103b26:	50                   	push   %eax
f0103b27:	68 0d 02 00 00       	push   $0x20d
f0103b2c:	8d 83 d2 97 f7 ff    	lea    -0x8682e(%ebx),%eax
f0103b32:	50                   	push   %eax
f0103b33:	e8 79 c5 ff ff       	call   f01000b1 <_panic>
		panic("pa2page called with invalid pa");
f0103b38:	83 ec 04             	sub    $0x4,%esp
f0103b3b:	8d 83 c4 90 f7 ff    	lea    -0x86f3c(%ebx),%eax
f0103b41:	50                   	push   %eax
f0103b42:	6a 4f                	push   $0x4f
f0103b44:	8d 83 82 8c f7 ff    	lea    -0x8737e(%ebx),%eax
f0103b4a:	50                   	push   %eax
f0103b4b:	e8 61 c5 ff ff       	call   f01000b1 <_panic>

f0103b50 <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f0103b50:	55                   	push   %ebp
f0103b51:	89 e5                	mov    %esp,%ebp
f0103b53:	53                   	push   %ebx
f0103b54:	83 ec 10             	sub    $0x10,%esp
f0103b57:	e8 0b c6 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103b5c:	81 c3 c4 94 08 00    	add    $0x894c4,%ebx
	env_free(e);
f0103b62:	ff 75 08             	pushl  0x8(%ebp)
f0103b65:	e8 df fd ff ff       	call   f0103949 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0103b6a:	8d 83 9c 97 f7 ff    	lea    -0x86864(%ebx),%eax
f0103b70:	89 04 24             	mov    %eax,(%esp)
f0103b73:	e8 46 01 00 00       	call   f0103cbe <cprintf>
f0103b78:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0103b7b:	83 ec 0c             	sub    $0xc,%esp
f0103b7e:	6a 00                	push   $0x0
f0103b80:	e8 c9 cd ff ff       	call   f010094e <monitor>
f0103b85:	83 c4 10             	add    $0x10,%esp
f0103b88:	eb f1                	jmp    f0103b7b <env_destroy+0x2b>

f0103b8a <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103b8a:	55                   	push   %ebp
f0103b8b:	89 e5                	mov    %esp,%ebp
f0103b8d:	53                   	push   %ebx
f0103b8e:	83 ec 08             	sub    $0x8,%esp
f0103b91:	e8 d1 c5 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103b96:	81 c3 8a 94 08 00    	add    $0x8948a,%ebx
	asm volatile(
f0103b9c:	8b 65 08             	mov    0x8(%ebp),%esp
f0103b9f:	61                   	popa   
f0103ba0:	07                   	pop    %es
f0103ba1:	1f                   	pop    %ds
f0103ba2:	83 c4 08             	add    $0x8,%esp
f0103ba5:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103ba6:	8d 83 75 98 f7 ff    	lea    -0x8678b(%ebx),%eax
f0103bac:	50                   	push   %eax
f0103bad:	68 36 02 00 00       	push   $0x236
f0103bb2:	8d 83 d2 97 f7 ff    	lea    -0x8682e(%ebx),%eax
f0103bb8:	50                   	push   %eax
f0103bb9:	e8 f3 c4 ff ff       	call   f01000b1 <_panic>

f0103bbe <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103bbe:	55                   	push   %ebp
f0103bbf:	89 e5                	mov    %esp,%ebp
f0103bc1:	53                   	push   %ebx
f0103bc2:	83 ec 04             	sub    $0x4,%esp
f0103bc5:	e8 9d c5 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103bca:	81 c3 56 94 08 00    	add    $0x89456,%ebx
f0103bd0:	8b 45 08             	mov    0x8(%ebp),%eax
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if (curenv != NULL) {
f0103bd3:	8b 93 28 23 00 00    	mov    0x2328(%ebx),%edx
f0103bd9:	85 d2                	test   %edx,%edx
f0103bdb:	74 06                	je     f0103be3 <env_run+0x25>
		if (curenv->env_status == ENV_RUNNING) {
f0103bdd:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0103be1:	74 35                	je     f0103c18 <env_run+0x5a>
			curenv->env_status = ENV_RUNNABLE;
		}
	}
	curenv = e;
f0103be3:	89 83 28 23 00 00    	mov    %eax,0x2328(%ebx)
	curenv->env_status = ENV_RUNNING;
f0103be9:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs += 1;
f0103bf0:	83 40 58 01          	addl   $0x1,0x58(%eax)

	lcr3(PADDR((e->env_pgdir)));
f0103bf4:	8b 50 5c             	mov    0x5c(%eax),%edx
	if ((uint32_t)kva < KERNBASE)
f0103bf7:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0103bfd:	77 22                	ja     f0103c21 <env_run+0x63>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103bff:	52                   	push   %edx
f0103c00:	8d 83 a0 90 f7 ff    	lea    -0x86f60(%ebx),%eax
f0103c06:	50                   	push   %eax
f0103c07:	68 5d 02 00 00       	push   $0x25d
f0103c0c:	8d 83 d2 97 f7 ff    	lea    -0x8682e(%ebx),%eax
f0103c12:	50                   	push   %eax
f0103c13:	e8 99 c4 ff ff       	call   f01000b1 <_panic>
			curenv->env_status = ENV_RUNNABLE;
f0103c18:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
f0103c1f:	eb c2                	jmp    f0103be3 <env_run+0x25>
	return (physaddr_t)kva - KERNBASE;
f0103c21:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0103c27:	0f 22 da             	mov    %edx,%cr3
	env_pop_tf(&(e->env_tf));
f0103c2a:	83 ec 0c             	sub    $0xc,%esp
f0103c2d:	50                   	push   %eax
f0103c2e:	e8 57 ff ff ff       	call   f0103b8a <env_pop_tf>

f0103c33 <__x86.get_pc_thunk.si>:
f0103c33:	8b 34 24             	mov    (%esp),%esi
f0103c36:	c3                   	ret    

f0103c37 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103c37:	55                   	push   %ebp
f0103c38:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103c3a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c3d:	ba 70 00 00 00       	mov    $0x70,%edx
f0103c42:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103c43:	ba 71 00 00 00       	mov    $0x71,%edx
f0103c48:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103c49:	0f b6 c0             	movzbl %al,%eax
}
f0103c4c:	5d                   	pop    %ebp
f0103c4d:	c3                   	ret    

f0103c4e <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103c4e:	55                   	push   %ebp
f0103c4f:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103c51:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c54:	ba 70 00 00 00       	mov    $0x70,%edx
f0103c59:	ee                   	out    %al,(%dx)
f0103c5a:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103c5d:	ba 71 00 00 00       	mov    $0x71,%edx
f0103c62:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103c63:	5d                   	pop    %ebp
f0103c64:	c3                   	ret    

f0103c65 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103c65:	55                   	push   %ebp
f0103c66:	89 e5                	mov    %esp,%ebp
f0103c68:	53                   	push   %ebx
f0103c69:	83 ec 10             	sub    $0x10,%esp
f0103c6c:	e8 f6 c4 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103c71:	81 c3 af 93 08 00    	add    $0x893af,%ebx
	cputchar(ch);
f0103c77:	ff 75 08             	pushl  0x8(%ebp)
f0103c7a:	e8 5f ca ff ff       	call   f01006de <cputchar>
	*cnt++;
}
f0103c7f:	83 c4 10             	add    $0x10,%esp
f0103c82:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103c85:	c9                   	leave  
f0103c86:	c3                   	ret    

f0103c87 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103c87:	55                   	push   %ebp
f0103c88:	89 e5                	mov    %esp,%ebp
f0103c8a:	53                   	push   %ebx
f0103c8b:	83 ec 14             	sub    $0x14,%esp
f0103c8e:	e8 d4 c4 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103c93:	81 c3 8d 93 08 00    	add    $0x8938d,%ebx
	int cnt = 0;
f0103c99:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103ca0:	ff 75 0c             	pushl  0xc(%ebp)
f0103ca3:	ff 75 08             	pushl  0x8(%ebp)
f0103ca6:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103ca9:	50                   	push   %eax
f0103caa:	8d 83 45 6c f7 ff    	lea    -0x893bb(%ebx),%eax
f0103cb0:	50                   	push   %eax
f0103cb1:	e8 10 0f 00 00       	call   f0104bc6 <vprintfmt>
	return cnt;
}
f0103cb6:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103cb9:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103cbc:	c9                   	leave  
f0103cbd:	c3                   	ret    

f0103cbe <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103cbe:	55                   	push   %ebp
f0103cbf:	89 e5                	mov    %esp,%ebp
f0103cc1:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103cc4:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103cc7:	50                   	push   %eax
f0103cc8:	ff 75 08             	pushl  0x8(%ebp)
f0103ccb:	e8 b7 ff ff ff       	call   f0103c87 <vcprintf>
	va_end(ap);

	return cnt;
}
f0103cd0:	c9                   	leave  
f0103cd1:	c3                   	ret    

f0103cd2 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103cd2:	55                   	push   %ebp
f0103cd3:	89 e5                	mov    %esp,%ebp
f0103cd5:	57                   	push   %edi
f0103cd6:	56                   	push   %esi
f0103cd7:	53                   	push   %ebx
f0103cd8:	83 ec 04             	sub    $0x4,%esp
f0103cdb:	e8 87 c4 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103ce0:	81 c3 40 93 08 00    	add    $0x89340,%ebx
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0103ce6:	c7 83 64 2b 00 00 00 	movl   $0xf0000000,0x2b64(%ebx)
f0103ced:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0103cf0:	66 c7 83 68 2b 00 00 	movw   $0x10,0x2b68(%ebx)
f0103cf7:	10 00 
	ts.ts_iomb = sizeof(struct Taskstate);
f0103cf9:	66 c7 83 c6 2b 00 00 	movw   $0x68,0x2bc6(%ebx)
f0103d00:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0103d02:	c7 c0 00 c3 11 f0    	mov    $0xf011c300,%eax
f0103d08:	66 c7 40 28 67 00    	movw   $0x67,0x28(%eax)
f0103d0e:	8d b3 60 2b 00 00    	lea    0x2b60(%ebx),%esi
f0103d14:	66 89 70 2a          	mov    %si,0x2a(%eax)
f0103d18:	89 f2                	mov    %esi,%edx
f0103d1a:	c1 ea 10             	shr    $0x10,%edx
f0103d1d:	88 50 2c             	mov    %dl,0x2c(%eax)
f0103d20:	0f b6 50 2d          	movzbl 0x2d(%eax),%edx
f0103d24:	83 e2 f0             	and    $0xfffffff0,%edx
f0103d27:	83 ca 09             	or     $0x9,%edx
f0103d2a:	83 e2 9f             	and    $0xffffff9f,%edx
f0103d2d:	83 ca 80             	or     $0xffffff80,%edx
f0103d30:	88 55 f3             	mov    %dl,-0xd(%ebp)
f0103d33:	88 50 2d             	mov    %dl,0x2d(%eax)
f0103d36:	0f b6 48 2e          	movzbl 0x2e(%eax),%ecx
f0103d3a:	83 e1 c0             	and    $0xffffffc0,%ecx
f0103d3d:	83 c9 40             	or     $0x40,%ecx
f0103d40:	83 e1 7f             	and    $0x7f,%ecx
f0103d43:	88 48 2e             	mov    %cl,0x2e(%eax)
f0103d46:	c1 ee 18             	shr    $0x18,%esi
f0103d49:	89 f1                	mov    %esi,%ecx
f0103d4b:	88 48 2f             	mov    %cl,0x2f(%eax)
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0103d4e:	0f b6 55 f3          	movzbl -0xd(%ebp),%edx
f0103d52:	83 e2 ef             	and    $0xffffffef,%edx
f0103d55:	88 50 2d             	mov    %dl,0x2d(%eax)
	asm volatile("ltr %0" : : "r" (sel));
f0103d58:	b8 28 00 00 00       	mov    $0x28,%eax
f0103d5d:	0f 00 d8             	ltr    %ax
	asm volatile("lidt (%0)" : : "r" (p));
f0103d60:	8d 83 e8 1f 00 00    	lea    0x1fe8(%ebx),%eax
f0103d66:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0103d69:	83 c4 04             	add    $0x4,%esp
f0103d6c:	5b                   	pop    %ebx
f0103d6d:	5e                   	pop    %esi
f0103d6e:	5f                   	pop    %edi
f0103d6f:	5d                   	pop    %ebp
f0103d70:	c3                   	ret    

f0103d71 <trap_init>:
{
f0103d71:	55                   	push   %ebp
f0103d72:	89 e5                	mov    %esp,%ebp
f0103d74:	e8 90 c9 ff ff       	call   f0100709 <__x86.get_pc_thunk.ax>
f0103d79:	05 a7 92 08 00       	add    $0x892a7,%eax
    SETGATE(idt[T_DIVIDE], 0, GD_KT, DIVIDE, 0);
f0103d7e:	c7 c2 72 45 10 f0    	mov    $0xf0104572,%edx
f0103d84:	66 89 90 40 23 00 00 	mov    %dx,0x2340(%eax)
f0103d8b:	66 c7 80 42 23 00 00 	movw   $0x8,0x2342(%eax)
f0103d92:	08 00 
f0103d94:	c6 80 44 23 00 00 00 	movb   $0x0,0x2344(%eax)
f0103d9b:	c6 80 45 23 00 00 8e 	movb   $0x8e,0x2345(%eax)
f0103da2:	c1 ea 10             	shr    $0x10,%edx
f0103da5:	66 89 90 46 23 00 00 	mov    %dx,0x2346(%eax)
	SETGATE(idt[T_DEBUG], 0, GD_KT, DEBUG, 0);
f0103dac:	c7 c2 78 45 10 f0    	mov    $0xf0104578,%edx
f0103db2:	66 89 90 48 23 00 00 	mov    %dx,0x2348(%eax)
f0103db9:	66 c7 80 4a 23 00 00 	movw   $0x8,0x234a(%eax)
f0103dc0:	08 00 
f0103dc2:	c6 80 4c 23 00 00 00 	movb   $0x0,0x234c(%eax)
f0103dc9:	c6 80 4d 23 00 00 8e 	movb   $0x8e,0x234d(%eax)
f0103dd0:	c1 ea 10             	shr    $0x10,%edx
f0103dd3:	66 89 90 4e 23 00 00 	mov    %dx,0x234e(%eax)
	SETGATE(idt[T_NMI], 0, GD_KT, NMI, 0);
f0103dda:	c7 c2 7e 45 10 f0    	mov    $0xf010457e,%edx
f0103de0:	66 89 90 50 23 00 00 	mov    %dx,0x2350(%eax)
f0103de7:	66 c7 80 52 23 00 00 	movw   $0x8,0x2352(%eax)
f0103dee:	08 00 
f0103df0:	c6 80 54 23 00 00 00 	movb   $0x0,0x2354(%eax)
f0103df7:	c6 80 55 23 00 00 8e 	movb   $0x8e,0x2355(%eax)
f0103dfe:	c1 ea 10             	shr    $0x10,%edx
f0103e01:	66 89 90 56 23 00 00 	mov    %dx,0x2356(%eax)
	SETGATE(idt[T_BRKPT], 1, GD_KT, BRKPT, 3);  // Lab3: Changed to a pseudo 
f0103e08:	c7 c2 82 45 10 f0    	mov    $0xf0104582,%edx
f0103e0e:	66 89 90 58 23 00 00 	mov    %dx,0x2358(%eax)
f0103e15:	66 c7 80 5a 23 00 00 	movw   $0x8,0x235a(%eax)
f0103e1c:	08 00 
f0103e1e:	c6 80 5c 23 00 00 00 	movb   $0x0,0x235c(%eax)
f0103e25:	c6 80 5d 23 00 00 ef 	movb   $0xef,0x235d(%eax)
f0103e2c:	c1 ea 10             	shr    $0x10,%edx
f0103e2f:	66 89 90 5e 23 00 00 	mov    %dx,0x235e(%eax)
	SETGATE(idt[T_OFLOW], 0, GD_KT, OFLOW, 0);
f0103e36:	c7 c2 88 45 10 f0    	mov    $0xf0104588,%edx
f0103e3c:	66 89 90 60 23 00 00 	mov    %dx,0x2360(%eax)
f0103e43:	66 c7 80 62 23 00 00 	movw   $0x8,0x2362(%eax)
f0103e4a:	08 00 
f0103e4c:	c6 80 64 23 00 00 00 	movb   $0x0,0x2364(%eax)
f0103e53:	c6 80 65 23 00 00 8e 	movb   $0x8e,0x2365(%eax)
f0103e5a:	c1 ea 10             	shr    $0x10,%edx
f0103e5d:	66 89 90 66 23 00 00 	mov    %dx,0x2366(%eax)
	SETGATE(idt[T_BOUND], 0, GD_KT, BOUND, 0);
f0103e64:	c7 c2 8e 45 10 f0    	mov    $0xf010458e,%edx
f0103e6a:	66 89 90 68 23 00 00 	mov    %dx,0x2368(%eax)
f0103e71:	66 c7 80 6a 23 00 00 	movw   $0x8,0x236a(%eax)
f0103e78:	08 00 
f0103e7a:	c6 80 6c 23 00 00 00 	movb   $0x0,0x236c(%eax)
f0103e81:	c6 80 6d 23 00 00 8e 	movb   $0x8e,0x236d(%eax)
f0103e88:	c1 ea 10             	shr    $0x10,%edx
f0103e8b:	66 89 90 6e 23 00 00 	mov    %dx,0x236e(%eax)
	SETGATE(idt[T_ILLOP], 0, GD_KT, ILLOP, 0);
f0103e92:	c7 c2 94 45 10 f0    	mov    $0xf0104594,%edx
f0103e98:	66 89 90 70 23 00 00 	mov    %dx,0x2370(%eax)
f0103e9f:	66 c7 80 72 23 00 00 	movw   $0x8,0x2372(%eax)
f0103ea6:	08 00 
f0103ea8:	c6 80 74 23 00 00 00 	movb   $0x0,0x2374(%eax)
f0103eaf:	c6 80 75 23 00 00 8e 	movb   $0x8e,0x2375(%eax)
f0103eb6:	c1 ea 10             	shr    $0x10,%edx
f0103eb9:	66 89 90 76 23 00 00 	mov    %dx,0x2376(%eax)
	SETGATE(idt[T_DEVICE], 0, GD_KT, DEVICE, 0);
f0103ec0:	c7 c2 9a 45 10 f0    	mov    $0xf010459a,%edx
f0103ec6:	66 89 90 78 23 00 00 	mov    %dx,0x2378(%eax)
f0103ecd:	66 c7 80 7a 23 00 00 	movw   $0x8,0x237a(%eax)
f0103ed4:	08 00 
f0103ed6:	c6 80 7c 23 00 00 00 	movb   $0x0,0x237c(%eax)
f0103edd:	c6 80 7d 23 00 00 8e 	movb   $0x8e,0x237d(%eax)
f0103ee4:	c1 ea 10             	shr    $0x10,%edx
f0103ee7:	66 89 90 7e 23 00 00 	mov    %dx,0x237e(%eax)
	SETGATE(idt[T_DBLFLT], 0, GD_KT, DBLFLT, 0);
f0103eee:	c7 c2 a0 45 10 f0    	mov    $0xf01045a0,%edx
f0103ef4:	66 89 90 80 23 00 00 	mov    %dx,0x2380(%eax)
f0103efb:	66 c7 80 82 23 00 00 	movw   $0x8,0x2382(%eax)
f0103f02:	08 00 
f0103f04:	c6 80 84 23 00 00 00 	movb   $0x0,0x2384(%eax)
f0103f0b:	c6 80 85 23 00 00 8e 	movb   $0x8e,0x2385(%eax)
f0103f12:	c1 ea 10             	shr    $0x10,%edx
f0103f15:	66 89 90 86 23 00 00 	mov    %dx,0x2386(%eax)
	SETGATE(idt[T_TSS], 0, GD_KT, TSS, 0);
f0103f1c:	c7 c2 a4 45 10 f0    	mov    $0xf01045a4,%edx
f0103f22:	66 89 90 90 23 00 00 	mov    %dx,0x2390(%eax)
f0103f29:	66 c7 80 92 23 00 00 	movw   $0x8,0x2392(%eax)
f0103f30:	08 00 
f0103f32:	c6 80 94 23 00 00 00 	movb   $0x0,0x2394(%eax)
f0103f39:	c6 80 95 23 00 00 8e 	movb   $0x8e,0x2395(%eax)
f0103f40:	c1 ea 10             	shr    $0x10,%edx
f0103f43:	66 89 90 96 23 00 00 	mov    %dx,0x2396(%eax)
	SETGATE(idt[T_SEGNP], 0, GD_KT, SEGNP, 0);
f0103f4a:	c7 c2 a8 45 10 f0    	mov    $0xf01045a8,%edx
f0103f50:	66 89 90 98 23 00 00 	mov    %dx,0x2398(%eax)
f0103f57:	66 c7 80 9a 23 00 00 	movw   $0x8,0x239a(%eax)
f0103f5e:	08 00 
f0103f60:	c6 80 9c 23 00 00 00 	movb   $0x0,0x239c(%eax)
f0103f67:	c6 80 9d 23 00 00 8e 	movb   $0x8e,0x239d(%eax)
f0103f6e:	c1 ea 10             	shr    $0x10,%edx
f0103f71:	66 89 90 9e 23 00 00 	mov    %dx,0x239e(%eax)
	SETGATE(idt[T_STACK], 0, GD_KT, STACK, 0);
f0103f78:	c7 c2 ac 45 10 f0    	mov    $0xf01045ac,%edx
f0103f7e:	66 89 90 a0 23 00 00 	mov    %dx,0x23a0(%eax)
f0103f85:	66 c7 80 a2 23 00 00 	movw   $0x8,0x23a2(%eax)
f0103f8c:	08 00 
f0103f8e:	c6 80 a4 23 00 00 00 	movb   $0x0,0x23a4(%eax)
f0103f95:	c6 80 a5 23 00 00 8e 	movb   $0x8e,0x23a5(%eax)
f0103f9c:	c1 ea 10             	shr    $0x10,%edx
f0103f9f:	66 89 90 a6 23 00 00 	mov    %dx,0x23a6(%eax)
	SETGATE(idt[T_GPFLT], 0, GD_KT, GPFLT, 0);
f0103fa6:	c7 c2 b0 45 10 f0    	mov    $0xf01045b0,%edx
f0103fac:	66 89 90 a8 23 00 00 	mov    %dx,0x23a8(%eax)
f0103fb3:	66 c7 80 aa 23 00 00 	movw   $0x8,0x23aa(%eax)
f0103fba:	08 00 
f0103fbc:	c6 80 ac 23 00 00 00 	movb   $0x0,0x23ac(%eax)
f0103fc3:	c6 80 ad 23 00 00 8e 	movb   $0x8e,0x23ad(%eax)
f0103fca:	c1 ea 10             	shr    $0x10,%edx
f0103fcd:	66 89 90 ae 23 00 00 	mov    %dx,0x23ae(%eax)
	SETGATE(idt[T_PGFLT], 1, GD_KT, PGFLT, 0);	// To pass PartA softint, this 
f0103fd4:	c7 c2 b4 45 10 f0    	mov    $0xf01045b4,%edx
f0103fda:	66 89 90 b0 23 00 00 	mov    %dx,0x23b0(%eax)
f0103fe1:	66 c7 80 b2 23 00 00 	movw   $0x8,0x23b2(%eax)
f0103fe8:	08 00 
f0103fea:	c6 80 b4 23 00 00 00 	movb   $0x0,0x23b4(%eax)
f0103ff1:	c6 80 b5 23 00 00 8f 	movb   $0x8f,0x23b5(%eax)
f0103ff8:	c1 ea 10             	shr    $0x10,%edx
f0103ffb:	66 89 90 b6 23 00 00 	mov    %dx,0x23b6(%eax)
	SETGATE(idt[T_FPERR], 0, GD_KT, FPERR, 0);
f0104002:	c7 c2 b8 45 10 f0    	mov    $0xf01045b8,%edx
f0104008:	66 89 90 c0 23 00 00 	mov    %dx,0x23c0(%eax)
f010400f:	66 c7 80 c2 23 00 00 	movw   $0x8,0x23c2(%eax)
f0104016:	08 00 
f0104018:	c6 80 c4 23 00 00 00 	movb   $0x0,0x23c4(%eax)
f010401f:	c6 80 c5 23 00 00 8e 	movb   $0x8e,0x23c5(%eax)
f0104026:	c1 ea 10             	shr    $0x10,%edx
f0104029:	66 89 90 c6 23 00 00 	mov    %dx,0x23c6(%eax)
	SETGATE(idt[T_ALIGN], 0, GD_KT, ALIGN, 0);
f0104030:	c7 c2 be 45 10 f0    	mov    $0xf01045be,%edx
f0104036:	66 89 90 c8 23 00 00 	mov    %dx,0x23c8(%eax)
f010403d:	66 c7 80 ca 23 00 00 	movw   $0x8,0x23ca(%eax)
f0104044:	08 00 
f0104046:	c6 80 cc 23 00 00 00 	movb   $0x0,0x23cc(%eax)
f010404d:	c6 80 cd 23 00 00 8e 	movb   $0x8e,0x23cd(%eax)
f0104054:	c1 ea 10             	shr    $0x10,%edx
f0104057:	66 89 90 ce 23 00 00 	mov    %dx,0x23ce(%eax)
	SETGATE(idt[T_MCHK], 0, GD_KT, MCHK, 0);
f010405e:	c7 c2 c2 45 10 f0    	mov    $0xf01045c2,%edx
f0104064:	66 89 90 d0 23 00 00 	mov    %dx,0x23d0(%eax)
f010406b:	66 c7 80 d2 23 00 00 	movw   $0x8,0x23d2(%eax)
f0104072:	08 00 
f0104074:	c6 80 d4 23 00 00 00 	movb   $0x0,0x23d4(%eax)
f010407b:	c6 80 d5 23 00 00 8e 	movb   $0x8e,0x23d5(%eax)
f0104082:	c1 ea 10             	shr    $0x10,%edx
f0104085:	66 89 90 d6 23 00 00 	mov    %dx,0x23d6(%eax)
	SETGATE(idt[T_SIMDERR], 0, GD_KT, SIMDERR, 0);
f010408c:	c7 c2 c6 45 10 f0    	mov    $0xf01045c6,%edx
f0104092:	66 89 90 d8 23 00 00 	mov    %dx,0x23d8(%eax)
f0104099:	66 c7 80 da 23 00 00 	movw   $0x8,0x23da(%eax)
f01040a0:	08 00 
f01040a2:	c6 80 dc 23 00 00 00 	movb   $0x0,0x23dc(%eax)
f01040a9:	c6 80 dd 23 00 00 8e 	movb   $0x8e,0x23dd(%eax)
f01040b0:	c1 ea 10             	shr    $0x10,%edx
f01040b3:	66 89 90 de 23 00 00 	mov    %dx,0x23de(%eax)
	SETGATE(idt[T_SYSCALL], 1, GD_KT, SYSCALL, 3);  // system call
f01040ba:	c7 c2 ca 45 10 f0    	mov    $0xf01045ca,%edx
f01040c0:	66 89 90 c0 24 00 00 	mov    %dx,0x24c0(%eax)
f01040c7:	66 c7 80 c2 24 00 00 	movw   $0x8,0x24c2(%eax)
f01040ce:	08 00 
f01040d0:	c6 80 c4 24 00 00 00 	movb   $0x0,0x24c4(%eax)
f01040d7:	c6 80 c5 24 00 00 ef 	movb   $0xef,0x24c5(%eax)
f01040de:	c1 ea 10             	shr    $0x10,%edx
f01040e1:	66 89 90 c6 24 00 00 	mov    %dx,0x24c6(%eax)
	SETGATE(idt[T_DEFAULT], 0, GD_KT, DEFAULT, 0);
f01040e8:	c7 c2 d0 45 10 f0    	mov    $0xf01045d0,%edx
f01040ee:	66 89 90 e0 32 00 00 	mov    %dx,0x32e0(%eax)
f01040f5:	66 c7 80 e2 32 00 00 	movw   $0x8,0x32e2(%eax)
f01040fc:	08 00 
f01040fe:	c6 80 e4 32 00 00 00 	movb   $0x0,0x32e4(%eax)
f0104105:	c6 80 e5 32 00 00 8e 	movb   $0x8e,0x32e5(%eax)
f010410c:	c1 ea 10             	shr    $0x10,%edx
f010410f:	66 89 90 e6 32 00 00 	mov    %dx,0x32e6(%eax)
	trap_init_percpu();
f0104116:	e8 b7 fb ff ff       	call   f0103cd2 <trap_init_percpu>
}
f010411b:	5d                   	pop    %ebp
f010411c:	c3                   	ret    

f010411d <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f010411d:	55                   	push   %ebp
f010411e:	89 e5                	mov    %esp,%ebp
f0104120:	56                   	push   %esi
f0104121:	53                   	push   %ebx
f0104122:	e8 40 c0 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0104127:	81 c3 f9 8e 08 00    	add    $0x88ef9,%ebx
f010412d:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0104130:	83 ec 08             	sub    $0x8,%esp
f0104133:	ff 36                	pushl  (%esi)
f0104135:	8d 83 81 98 f7 ff    	lea    -0x8677f(%ebx),%eax
f010413b:	50                   	push   %eax
f010413c:	e8 7d fb ff ff       	call   f0103cbe <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0104141:	83 c4 08             	add    $0x8,%esp
f0104144:	ff 76 04             	pushl  0x4(%esi)
f0104147:	8d 83 90 98 f7 ff    	lea    -0x86770(%ebx),%eax
f010414d:	50                   	push   %eax
f010414e:	e8 6b fb ff ff       	call   f0103cbe <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0104153:	83 c4 08             	add    $0x8,%esp
f0104156:	ff 76 08             	pushl  0x8(%esi)
f0104159:	8d 83 9f 98 f7 ff    	lea    -0x86761(%ebx),%eax
f010415f:	50                   	push   %eax
f0104160:	e8 59 fb ff ff       	call   f0103cbe <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0104165:	83 c4 08             	add    $0x8,%esp
f0104168:	ff 76 0c             	pushl  0xc(%esi)
f010416b:	8d 83 ae 98 f7 ff    	lea    -0x86752(%ebx),%eax
f0104171:	50                   	push   %eax
f0104172:	e8 47 fb ff ff       	call   f0103cbe <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0104177:	83 c4 08             	add    $0x8,%esp
f010417a:	ff 76 10             	pushl  0x10(%esi)
f010417d:	8d 83 bd 98 f7 ff    	lea    -0x86743(%ebx),%eax
f0104183:	50                   	push   %eax
f0104184:	e8 35 fb ff ff       	call   f0103cbe <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0104189:	83 c4 08             	add    $0x8,%esp
f010418c:	ff 76 14             	pushl  0x14(%esi)
f010418f:	8d 83 cc 98 f7 ff    	lea    -0x86734(%ebx),%eax
f0104195:	50                   	push   %eax
f0104196:	e8 23 fb ff ff       	call   f0103cbe <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f010419b:	83 c4 08             	add    $0x8,%esp
f010419e:	ff 76 18             	pushl  0x18(%esi)
f01041a1:	8d 83 db 98 f7 ff    	lea    -0x86725(%ebx),%eax
f01041a7:	50                   	push   %eax
f01041a8:	e8 11 fb ff ff       	call   f0103cbe <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f01041ad:	83 c4 08             	add    $0x8,%esp
f01041b0:	ff 76 1c             	pushl  0x1c(%esi)
f01041b3:	8d 83 ea 98 f7 ff    	lea    -0x86716(%ebx),%eax
f01041b9:	50                   	push   %eax
f01041ba:	e8 ff fa ff ff       	call   f0103cbe <cprintf>
}
f01041bf:	83 c4 10             	add    $0x10,%esp
f01041c2:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01041c5:	5b                   	pop    %ebx
f01041c6:	5e                   	pop    %esi
f01041c7:	5d                   	pop    %ebp
f01041c8:	c3                   	ret    

f01041c9 <print_trapframe>:
{
f01041c9:	55                   	push   %ebp
f01041ca:	89 e5                	mov    %esp,%ebp
f01041cc:	57                   	push   %edi
f01041cd:	56                   	push   %esi
f01041ce:	53                   	push   %ebx
f01041cf:	83 ec 14             	sub    $0x14,%esp
f01041d2:	e8 90 bf ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01041d7:	81 c3 49 8e 08 00    	add    $0x88e49,%ebx
f01041dd:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("TRAP frame at %p\n", tf);
f01041e0:	56                   	push   %esi
f01041e1:	8d 83 3b 9a f7 ff    	lea    -0x865c5(%ebx),%eax
f01041e7:	50                   	push   %eax
f01041e8:	e8 d1 fa ff ff       	call   f0103cbe <cprintf>
	print_regs(&tf->tf_regs);
f01041ed:	89 34 24             	mov    %esi,(%esp)
f01041f0:	e8 28 ff ff ff       	call   f010411d <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f01041f5:	83 c4 08             	add    $0x8,%esp
f01041f8:	0f b7 46 20          	movzwl 0x20(%esi),%eax
f01041fc:	50                   	push   %eax
f01041fd:	8d 83 3b 99 f7 ff    	lea    -0x866c5(%ebx),%eax
f0104203:	50                   	push   %eax
f0104204:	e8 b5 fa ff ff       	call   f0103cbe <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0104209:	83 c4 08             	add    $0x8,%esp
f010420c:	0f b7 46 24          	movzwl 0x24(%esi),%eax
f0104210:	50                   	push   %eax
f0104211:	8d 83 4e 99 f7 ff    	lea    -0x866b2(%ebx),%eax
f0104217:	50                   	push   %eax
f0104218:	e8 a1 fa ff ff       	call   f0103cbe <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f010421d:	8b 56 28             	mov    0x28(%esi),%edx
	if (trapno < ARRAY_SIZE(excnames))
f0104220:	83 c4 10             	add    $0x10,%esp
f0104223:	83 fa 13             	cmp    $0x13,%edx
f0104226:	0f 86 e9 00 00 00    	jbe    f0104315 <print_trapframe+0x14c>
	return "(unknown trap)";
f010422c:	83 fa 30             	cmp    $0x30,%edx
f010422f:	8d 83 f9 98 f7 ff    	lea    -0x86707(%ebx),%eax
f0104235:	8d 8b 05 99 f7 ff    	lea    -0x866fb(%ebx),%ecx
f010423b:	0f 45 c1             	cmovne %ecx,%eax
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f010423e:	83 ec 04             	sub    $0x4,%esp
f0104241:	50                   	push   %eax
f0104242:	52                   	push   %edx
f0104243:	8d 83 61 99 f7 ff    	lea    -0x8669f(%ebx),%eax
f0104249:	50                   	push   %eax
f010424a:	e8 6f fa ff ff       	call   f0103cbe <cprintf>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f010424f:	83 c4 10             	add    $0x10,%esp
f0104252:	39 b3 40 2b 00 00    	cmp    %esi,0x2b40(%ebx)
f0104258:	0f 84 c3 00 00 00    	je     f0104321 <print_trapframe+0x158>
	cprintf("  err  0x%08x", tf->tf_err);
f010425e:	83 ec 08             	sub    $0x8,%esp
f0104261:	ff 76 2c             	pushl  0x2c(%esi)
f0104264:	8d 83 82 99 f7 ff    	lea    -0x8667e(%ebx),%eax
f010426a:	50                   	push   %eax
f010426b:	e8 4e fa ff ff       	call   f0103cbe <cprintf>
	if (tf->tf_trapno == T_PGFLT)
f0104270:	83 c4 10             	add    $0x10,%esp
f0104273:	83 7e 28 0e          	cmpl   $0xe,0x28(%esi)
f0104277:	0f 85 c9 00 00 00    	jne    f0104346 <print_trapframe+0x17d>
			tf->tf_err & 1 ? "protection" : "not-present");
f010427d:	8b 46 2c             	mov    0x2c(%esi),%eax
		cprintf(" [%s, %s, %s]\n",
f0104280:	89 c2                	mov    %eax,%edx
f0104282:	83 e2 01             	and    $0x1,%edx
f0104285:	8d 8b 14 99 f7 ff    	lea    -0x866ec(%ebx),%ecx
f010428b:	8d 93 1f 99 f7 ff    	lea    -0x866e1(%ebx),%edx
f0104291:	0f 44 ca             	cmove  %edx,%ecx
f0104294:	89 c2                	mov    %eax,%edx
f0104296:	83 e2 02             	and    $0x2,%edx
f0104299:	8d 93 2b 99 f7 ff    	lea    -0x866d5(%ebx),%edx
f010429f:	8d bb 31 99 f7 ff    	lea    -0x866cf(%ebx),%edi
f01042a5:	0f 44 d7             	cmove  %edi,%edx
f01042a8:	83 e0 04             	and    $0x4,%eax
f01042ab:	8d 83 36 99 f7 ff    	lea    -0x866ca(%ebx),%eax
f01042b1:	8d bb 66 9a f7 ff    	lea    -0x8659a(%ebx),%edi
f01042b7:	0f 44 c7             	cmove  %edi,%eax
f01042ba:	51                   	push   %ecx
f01042bb:	52                   	push   %edx
f01042bc:	50                   	push   %eax
f01042bd:	8d 83 90 99 f7 ff    	lea    -0x86670(%ebx),%eax
f01042c3:	50                   	push   %eax
f01042c4:	e8 f5 f9 ff ff       	call   f0103cbe <cprintf>
f01042c9:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f01042cc:	83 ec 08             	sub    $0x8,%esp
f01042cf:	ff 76 30             	pushl  0x30(%esi)
f01042d2:	8d 83 9f 99 f7 ff    	lea    -0x86661(%ebx),%eax
f01042d8:	50                   	push   %eax
f01042d9:	e8 e0 f9 ff ff       	call   f0103cbe <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f01042de:	83 c4 08             	add    $0x8,%esp
f01042e1:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f01042e5:	50                   	push   %eax
f01042e6:	8d 83 ae 99 f7 ff    	lea    -0x86652(%ebx),%eax
f01042ec:	50                   	push   %eax
f01042ed:	e8 cc f9 ff ff       	call   f0103cbe <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f01042f2:	83 c4 08             	add    $0x8,%esp
f01042f5:	ff 76 38             	pushl  0x38(%esi)
f01042f8:	8d 83 c1 99 f7 ff    	lea    -0x8663f(%ebx),%eax
f01042fe:	50                   	push   %eax
f01042ff:	e8 ba f9 ff ff       	call   f0103cbe <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0104304:	83 c4 10             	add    $0x10,%esp
f0104307:	f6 46 34 03          	testb  $0x3,0x34(%esi)
f010430b:	75 50                	jne    f010435d <print_trapframe+0x194>
}
f010430d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104310:	5b                   	pop    %ebx
f0104311:	5e                   	pop    %esi
f0104312:	5f                   	pop    %edi
f0104313:	5d                   	pop    %ebp
f0104314:	c3                   	ret    
		return excnames[trapno];
f0104315:	8b 84 93 60 20 00 00 	mov    0x2060(%ebx,%edx,4),%eax
f010431c:	e9 1d ff ff ff       	jmp    f010423e <print_trapframe+0x75>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0104321:	83 7e 28 0e          	cmpl   $0xe,0x28(%esi)
f0104325:	0f 85 33 ff ff ff    	jne    f010425e <print_trapframe+0x95>
	asm volatile("movl %%cr2,%0" : "=r" (val));
f010432b:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f010432e:	83 ec 08             	sub    $0x8,%esp
f0104331:	50                   	push   %eax
f0104332:	8d 83 73 99 f7 ff    	lea    -0x8668d(%ebx),%eax
f0104338:	50                   	push   %eax
f0104339:	e8 80 f9 ff ff       	call   f0103cbe <cprintf>
f010433e:	83 c4 10             	add    $0x10,%esp
f0104341:	e9 18 ff ff ff       	jmp    f010425e <print_trapframe+0x95>
		cprintf("\n");
f0104346:	83 ec 0c             	sub    $0xc,%esp
f0104349:	8d 83 61 8f f7 ff    	lea    -0x8709f(%ebx),%eax
f010434f:	50                   	push   %eax
f0104350:	e8 69 f9 ff ff       	call   f0103cbe <cprintf>
f0104355:	83 c4 10             	add    $0x10,%esp
f0104358:	e9 6f ff ff ff       	jmp    f01042cc <print_trapframe+0x103>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f010435d:	83 ec 08             	sub    $0x8,%esp
f0104360:	ff 76 3c             	pushl  0x3c(%esi)
f0104363:	8d 83 d0 99 f7 ff    	lea    -0x86630(%ebx),%eax
f0104369:	50                   	push   %eax
f010436a:	e8 4f f9 ff ff       	call   f0103cbe <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f010436f:	83 c4 08             	add    $0x8,%esp
f0104372:	0f b7 46 40          	movzwl 0x40(%esi),%eax
f0104376:	50                   	push   %eax
f0104377:	8d 83 df 99 f7 ff    	lea    -0x86621(%ebx),%eax
f010437d:	50                   	push   %eax
f010437e:	e8 3b f9 ff ff       	call   f0103cbe <cprintf>
f0104383:	83 c4 10             	add    $0x10,%esp
}
f0104386:	eb 85                	jmp    f010430d <print_trapframe+0x144>

f0104388 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0104388:	55                   	push   %ebp
f0104389:	89 e5                	mov    %esp,%ebp
f010438b:	57                   	push   %edi
f010438c:	56                   	push   %esi
f010438d:	53                   	push   %ebx
f010438e:	83 ec 0c             	sub    $0xc,%esp
f0104391:	e8 d1 bd ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0104396:	81 c3 8a 8c 08 00    	add    $0x88c8a,%ebx
f010439c:	8b 75 08             	mov    0x8(%ebp),%esi
f010439f:	0f 20 d0             	mov    %cr2,%eax
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
	if ((tf->tf_cs & 3) == 0) {
f01043a2:	f6 46 34 03          	testb  $0x3,0x34(%esi)
f01043a6:	74 38                	je     f01043e0 <page_fault_handler+0x58>

	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01043a8:	ff 76 30             	pushl  0x30(%esi)
f01043ab:	50                   	push   %eax
f01043ac:	c7 c7 48 f3 18 f0    	mov    $0xf018f348,%edi
f01043b2:	8b 07                	mov    (%edi),%eax
f01043b4:	ff 70 48             	pushl  0x48(%eax)
f01043b7:	8d 83 b0 9b f7 ff    	lea    -0x86450(%ebx),%eax
f01043bd:	50                   	push   %eax
f01043be:	e8 fb f8 ff ff       	call   f0103cbe <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f01043c3:	89 34 24             	mov    %esi,(%esp)
f01043c6:	e8 fe fd ff ff       	call   f01041c9 <print_trapframe>
	env_destroy(curenv);
f01043cb:	83 c4 04             	add    $0x4,%esp
f01043ce:	ff 37                	pushl  (%edi)
f01043d0:	e8 7b f7 ff ff       	call   f0103b50 <env_destroy>
}
f01043d5:	83 c4 10             	add    $0x10,%esp
f01043d8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01043db:	5b                   	pop    %ebx
f01043dc:	5e                   	pop    %esi
f01043dd:	5f                   	pop    %edi
f01043de:	5d                   	pop    %ebp
f01043df:	c3                   	ret    
		panic("Page fault in kernel-mode!");
f01043e0:	83 ec 04             	sub    $0x4,%esp
f01043e3:	8d 83 f2 99 f7 ff    	lea    -0x8660e(%ebx),%eax
f01043e9:	50                   	push   %eax
f01043ea:	68 16 01 00 00       	push   $0x116
f01043ef:	8d 83 0d 9a f7 ff    	lea    -0x865f3(%ebx),%eax
f01043f5:	50                   	push   %eax
f01043f6:	e8 b6 bc ff ff       	call   f01000b1 <_panic>

f01043fb <trap>:
{
f01043fb:	55                   	push   %ebp
f01043fc:	89 e5                	mov    %esp,%ebp
f01043fe:	57                   	push   %edi
f01043ff:	56                   	push   %esi
f0104400:	53                   	push   %ebx
f0104401:	83 ec 0c             	sub    $0xc,%esp
f0104404:	e8 5e bd ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0104409:	81 c3 17 8c 08 00    	add    $0x88c17,%ebx
f010440f:	8b 75 08             	mov    0x8(%ebp),%esi
	asm volatile("cld" ::: "cc");
f0104412:	fc                   	cld    
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f0104413:	9c                   	pushf  
f0104414:	58                   	pop    %eax
	assert(!(read_eflags() & FL_IF));
f0104415:	f6 c4 02             	test   $0x2,%ah
f0104418:	74 1f                	je     f0104439 <trap+0x3e>
f010441a:	8d 83 19 9a f7 ff    	lea    -0x865e7(%ebx),%eax
f0104420:	50                   	push   %eax
f0104421:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f0104427:	50                   	push   %eax
f0104428:	68 ed 00 00 00       	push   $0xed
f010442d:	8d 83 0d 9a f7 ff    	lea    -0x865f3(%ebx),%eax
f0104433:	50                   	push   %eax
f0104434:	e8 78 bc ff ff       	call   f01000b1 <_panic>
	cprintf("Incoming TRAP frame at %p\n", tf);
f0104439:	83 ec 08             	sub    $0x8,%esp
f010443c:	56                   	push   %esi
f010443d:	8d 83 32 9a f7 ff    	lea    -0x865ce(%ebx),%eax
f0104443:	50                   	push   %eax
f0104444:	e8 75 f8 ff ff       	call   f0103cbe <cprintf>
	if ((tf->tf_cs & 3) == 3) {
f0104449:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f010444d:	83 e0 03             	and    $0x3,%eax
f0104450:	83 c4 10             	add    $0x10,%esp
f0104453:	66 83 f8 03          	cmp    $0x3,%ax
f0104457:	75 1d                	jne    f0104476 <trap+0x7b>
		assert(curenv);
f0104459:	c7 c0 48 f3 18 f0    	mov    $0xf018f348,%eax
f010445f:	8b 00                	mov    (%eax),%eax
f0104461:	85 c0                	test   %eax,%eax
f0104463:	74 5d                	je     f01044c2 <trap+0xc7>
		curenv->env_tf = *tf;
f0104465:	b9 11 00 00 00       	mov    $0x11,%ecx
f010446a:	89 c7                	mov    %eax,%edi
f010446c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		tf = &curenv->env_tf;
f010446e:	c7 c0 48 f3 18 f0    	mov    $0xf018f348,%eax
f0104474:	8b 30                	mov    (%eax),%esi
	last_tf = tf;
f0104476:	89 b3 40 2b 00 00    	mov    %esi,0x2b40(%ebx)
	switch (tf->tf_trapno) {
f010447c:	8b 46 28             	mov    0x28(%esi),%eax
f010447f:	83 f8 0e             	cmp    $0xe,%eax
f0104482:	74 5d                	je     f01044e1 <trap+0xe6>
f0104484:	83 f8 30             	cmp    $0x30,%eax
f0104487:	0f 84 9f 00 00 00    	je     f010452c <trap+0x131>
f010448d:	83 f8 03             	cmp    $0x3,%eax
f0104490:	0f 84 88 00 00 00    	je     f010451e <trap+0x123>
	print_trapframe(tf);
f0104496:	83 ec 0c             	sub    $0xc,%esp
f0104499:	56                   	push   %esi
f010449a:	e8 2a fd ff ff       	call   f01041c9 <print_trapframe>
	if (tf->tf_cs == GD_KT)
f010449f:	83 c4 10             	add    $0x10,%esp
f01044a2:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f01044a7:	0f 84 a0 00 00 00    	je     f010454d <trap+0x152>
		env_destroy(curenv);
f01044ad:	83 ec 0c             	sub    $0xc,%esp
f01044b0:	c7 c0 48 f3 18 f0    	mov    $0xf018f348,%eax
f01044b6:	ff 30                	pushl  (%eax)
f01044b8:	e8 93 f6 ff ff       	call   f0103b50 <env_destroy>
f01044bd:	83 c4 10             	add    $0x10,%esp
f01044c0:	eb 2b                	jmp    f01044ed <trap+0xf2>
		assert(curenv);
f01044c2:	8d 83 4d 9a f7 ff    	lea    -0x865b3(%ebx),%eax
f01044c8:	50                   	push   %eax
f01044c9:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f01044cf:	50                   	push   %eax
f01044d0:	68 f3 00 00 00       	push   $0xf3
f01044d5:	8d 83 0d 9a f7 ff    	lea    -0x865f3(%ebx),%eax
f01044db:	50                   	push   %eax
f01044dc:	e8 d0 bb ff ff       	call   f01000b1 <_panic>
			page_fault_handler(tf);
f01044e1:	83 ec 0c             	sub    $0xc,%esp
f01044e4:	56                   	push   %esi
f01044e5:	e8 9e fe ff ff       	call   f0104388 <page_fault_handler>
f01044ea:	83 c4 10             	add    $0x10,%esp
	assert(curenv && curenv->env_status == ENV_RUNNING);
f01044ed:	c7 c0 48 f3 18 f0    	mov    $0xf018f348,%eax
f01044f3:	8b 00                	mov    (%eax),%eax
f01044f5:	85 c0                	test   %eax,%eax
f01044f7:	74 06                	je     f01044ff <trap+0x104>
f01044f9:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01044fd:	74 69                	je     f0104568 <trap+0x16d>
f01044ff:	8d 83 d4 9b f7 ff    	lea    -0x8642c(%ebx),%eax
f0104505:	50                   	push   %eax
f0104506:	8d 83 9c 8c f7 ff    	lea    -0x87364(%ebx),%eax
f010450c:	50                   	push   %eax
f010450d:	68 05 01 00 00       	push   $0x105
f0104512:	8d 83 0d 9a f7 ff    	lea    -0x865f3(%ebx),%eax
f0104518:	50                   	push   %eax
f0104519:	e8 93 bb ff ff       	call   f01000b1 <_panic>
			monitor(tf);
f010451e:	83 ec 0c             	sub    $0xc,%esp
f0104521:	56                   	push   %esi
f0104522:	e8 27 c4 ff ff       	call   f010094e <monitor>
f0104527:	83 c4 10             	add    $0x10,%esp
f010452a:	eb c1                	jmp    f01044ed <trap+0xf2>
			tf->tf_regs.reg_eax = syscall(
f010452c:	83 ec 08             	sub    $0x8,%esp
f010452f:	ff 76 04             	pushl  0x4(%esi)
f0104532:	ff 36                	pushl  (%esi)
f0104534:	ff 76 10             	pushl  0x10(%esi)
f0104537:	ff 76 18             	pushl  0x18(%esi)
f010453a:	ff 76 14             	pushl  0x14(%esi)
f010453d:	ff 76 1c             	pushl  0x1c(%esi)
f0104540:	e8 a5 00 00 00       	call   f01045ea <syscall>
f0104545:	89 46 1c             	mov    %eax,0x1c(%esi)
f0104548:	83 c4 20             	add    $0x20,%esp
f010454b:	eb a0                	jmp    f01044ed <trap+0xf2>
		panic("unhandled trap in kernel");
f010454d:	83 ec 04             	sub    $0x4,%esp
f0104550:	8d 83 54 9a f7 ff    	lea    -0x865ac(%ebx),%eax
f0104556:	50                   	push   %eax
f0104557:	68 dc 00 00 00       	push   $0xdc
f010455c:	8d 83 0d 9a f7 ff    	lea    -0x865f3(%ebx),%eax
f0104562:	50                   	push   %eax
f0104563:	e8 49 bb ff ff       	call   f01000b1 <_panic>
	env_run(curenv);
f0104568:	83 ec 0c             	sub    $0xc,%esp
f010456b:	50                   	push   %eax
f010456c:	e8 4d f6 ff ff       	call   f0103bbe <env_run>
f0104571:	90                   	nop

f0104572 <DIVIDE>:
 */

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
TRAPHANDLER_NOEC(DIVIDE, T_DIVIDE)
f0104572:	6a 00                	push   $0x0
f0104574:	6a 00                	push   $0x0
f0104576:	eb 61                	jmp    f01045d9 <_alltraps>

f0104578 <DEBUG>:
TRAPHANDLER_NOEC(DEBUG, T_DEBUG)
f0104578:	6a 00                	push   $0x0
f010457a:	6a 01                	push   $0x1
f010457c:	eb 5b                	jmp    f01045d9 <_alltraps>

f010457e <NMI>:
TRAPHANDLER(NMI, T_NMI)
f010457e:	6a 02                	push   $0x2
f0104580:	eb 57                	jmp    f01045d9 <_alltraps>

f0104582 <BRKPT>:
TRAPHANDLER_NOEC(BRKPT, T_BRKPT)
f0104582:	6a 00                	push   $0x0
f0104584:	6a 03                	push   $0x3
f0104586:	eb 51                	jmp    f01045d9 <_alltraps>

f0104588 <OFLOW>:
TRAPHANDLER_NOEC(OFLOW, T_OFLOW)
f0104588:	6a 00                	push   $0x0
f010458a:	6a 04                	push   $0x4
f010458c:	eb 4b                	jmp    f01045d9 <_alltraps>

f010458e <BOUND>:
TRAPHANDLER_NOEC(BOUND, T_BOUND)
f010458e:	6a 00                	push   $0x0
f0104590:	6a 05                	push   $0x5
f0104592:	eb 45                	jmp    f01045d9 <_alltraps>

f0104594 <ILLOP>:
TRAPHANDLER_NOEC(ILLOP, T_ILLOP)
f0104594:	6a 00                	push   $0x0
f0104596:	6a 06                	push   $0x6
f0104598:	eb 3f                	jmp    f01045d9 <_alltraps>

f010459a <DEVICE>:
TRAPHANDLER_NOEC(DEVICE, T_DEVICE)
f010459a:	6a 00                	push   $0x0
f010459c:	6a 07                	push   $0x7
f010459e:	eb 39                	jmp    f01045d9 <_alltraps>

f01045a0 <DBLFLT>:
TRAPHANDLER(DBLFLT, T_DBLFLT)
f01045a0:	6a 08                	push   $0x8
f01045a2:	eb 35                	jmp    f01045d9 <_alltraps>

f01045a4 <TSS>:
TRAPHANDLER(TSS, T_TSS)
f01045a4:	6a 0a                	push   $0xa
f01045a6:	eb 31                	jmp    f01045d9 <_alltraps>

f01045a8 <SEGNP>:
TRAPHANDLER(SEGNP, T_SEGNP)
f01045a8:	6a 0b                	push   $0xb
f01045aa:	eb 2d                	jmp    f01045d9 <_alltraps>

f01045ac <STACK>:
TRAPHANDLER(STACK, T_STACK)
f01045ac:	6a 0c                	push   $0xc
f01045ae:	eb 29                	jmp    f01045d9 <_alltraps>

f01045b0 <GPFLT>:
TRAPHANDLER(GPFLT, T_GPFLT)
f01045b0:	6a 0d                	push   $0xd
f01045b2:	eb 25                	jmp    f01045d9 <_alltraps>

f01045b4 <PGFLT>:
TRAPHANDLER(PGFLT, T_PGFLT)
f01045b4:	6a 0e                	push   $0xe
f01045b6:	eb 21                	jmp    f01045d9 <_alltraps>

f01045b8 <FPERR>:
TRAPHANDLER_NOEC(FPERR, T_FPERR)
f01045b8:	6a 00                	push   $0x0
f01045ba:	6a 10                	push   $0x10
f01045bc:	eb 1b                	jmp    f01045d9 <_alltraps>

f01045be <ALIGN>:
TRAPHANDLER(ALIGN, T_ALIGN)
f01045be:	6a 11                	push   $0x11
f01045c0:	eb 17                	jmp    f01045d9 <_alltraps>

f01045c2 <MCHK>:
TRAPHANDLER(MCHK, T_MCHK)
f01045c2:	6a 12                	push   $0x12
f01045c4:	eb 13                	jmp    f01045d9 <_alltraps>

f01045c6 <SIMDERR>:
TRAPHANDLER(SIMDERR, T_SIMDERR)
f01045c6:	6a 13                	push   $0x13
f01045c8:	eb 0f                	jmp    f01045d9 <_alltraps>

f01045ca <SYSCALL>:
TRAPHANDLER_NOEC(SYSCALL, T_SYSCALL)
f01045ca:	6a 00                	push   $0x0
f01045cc:	6a 30                	push   $0x30
f01045ce:	eb 09                	jmp    f01045d9 <_alltraps>

f01045d0 <DEFAULT>:
TRAPHANDLER_NOEC(DEFAULT, T_DEFAULT)
f01045d0:	6a 00                	push   $0x0
f01045d2:	68 f4 01 00 00       	push   $0x1f4
f01045d7:	eb 00                	jmp    f01045d9 <_alltraps>

f01045d9 <_alltraps>:
  # Continue building trap frame.
  # Before entering _alltraps, ss, esp, eflags, cs, eip, error code and trapNo 
  # has already been pushed to the kernel stack. Check struct Trapframe, the
  # remaining register: ds, es and struct PushRegs.
  # pushal handles struct PushRegs. 
  pushl %ds
f01045d9:	1e                   	push   %ds
  pushl %es
f01045da:	06                   	push   %es
  pushal
f01045db:	60                   	pusha  

  # Set up %ds, %es, 16-bit register! Use movw.
  # Seems that you cannot move directly into %ds or %es, use %ax.
  movw $GD_KD, %ax
f01045dc:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
f01045e0:	8e d8                	mov    %eax,%ds
  movw %ax, %es
f01045e2:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
f01045e4:	54                   	push   %esp
  call trap     # Enter kernel code
f01045e5:	e8 11 fe ff ff       	call   f01043fb <trap>

f01045ea <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01045ea:	55                   	push   %ebp
f01045eb:	89 e5                	mov    %esp,%ebp
f01045ed:	53                   	push   %ebx
f01045ee:	83 ec 14             	sub    $0x14,%esp
f01045f1:	e8 71 bb ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01045f6:	81 c3 2a 8a 08 00    	add    $0x88a2a,%ebx
f01045fc:	8b 45 08             	mov    0x8(%ebp),%eax
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.
	int32_t res;

	switch (syscallno) {
f01045ff:	83 f8 01             	cmp    $0x1,%eax
f0104602:	74 4d                	je     f0104651 <syscall+0x67>
f0104604:	83 f8 01             	cmp    $0x1,%eax
f0104607:	72 11                	jb     f010461a <syscall+0x30>
f0104609:	83 f8 02             	cmp    $0x2,%eax
f010460c:	74 4a                	je     f0104658 <syscall+0x6e>
f010460e:	83 f8 03             	cmp    $0x3,%eax
f0104611:	74 52                	je     f0104665 <syscall+0x7b>
			break;
		case SYS_env_destroy:
			res = sys_env_destroy(a1);
			break;
		default:
			res = -E_INVAL;
f0104613:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}
	return res;
f0104618:	eb 32                	jmp    f010464c <syscall+0x62>
	user_mem_assert(curenv, s, len, PTE_P);
f010461a:	6a 01                	push   $0x1
f010461c:	ff 75 10             	pushl  0x10(%ebp)
f010461f:	ff 75 0c             	pushl  0xc(%ebp)
f0104622:	c7 c0 48 f3 18 f0    	mov    $0xf018f348,%eax
f0104628:	ff 30                	pushl  (%eax)
f010462a:	e8 b3 ed ff ff       	call   f01033e2 <user_mem_assert>
	cprintf("%.*s", len, s);
f010462f:	83 c4 0c             	add    $0xc,%esp
f0104632:	ff 75 0c             	pushl  0xc(%ebp)
f0104635:	ff 75 10             	pushl  0x10(%ebp)
f0104638:	8d 83 93 8a f7 ff    	lea    -0x8756d(%ebx),%eax
f010463e:	50                   	push   %eax
f010463f:	e8 7a f6 ff ff       	call   f0103cbe <cprintf>
f0104644:	83 c4 10             	add    $0x10,%esp
			res = 0;
f0104647:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010464c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010464f:	c9                   	leave  
f0104650:	c3                   	ret    
	return cons_getc();
f0104651:	e8 0c bf ff ff       	call   f0100562 <cons_getc>
			break;
f0104656:	eb f4                	jmp    f010464c <syscall+0x62>
	return curenv->env_id;
f0104658:	c7 c0 48 f3 18 f0    	mov    $0xf018f348,%eax
f010465e:	8b 00                	mov    (%eax),%eax
f0104660:	8b 40 48             	mov    0x48(%eax),%eax
			break;
f0104663:	eb e7                	jmp    f010464c <syscall+0x62>
	if ((r = envid2env(envid, &e, 1)) < 0)
f0104665:	83 ec 04             	sub    $0x4,%esp
f0104668:	6a 01                	push   $0x1
f010466a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010466d:	50                   	push   %eax
f010466e:	ff 75 0c             	pushl  0xc(%ebp)
f0104671:	e8 90 ee ff ff       	call   f0103506 <envid2env>
f0104676:	83 c4 10             	add    $0x10,%esp
f0104679:	85 c0                	test   %eax,%eax
f010467b:	78 cf                	js     f010464c <syscall+0x62>
	if (e == curenv)
f010467d:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0104680:	c7 c0 48 f3 18 f0    	mov    $0xf018f348,%eax
f0104686:	8b 00                	mov    (%eax),%eax
f0104688:	39 c2                	cmp    %eax,%edx
f010468a:	74 2d                	je     f01046b9 <syscall+0xcf>
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f010468c:	83 ec 04             	sub    $0x4,%esp
f010468f:	ff 72 48             	pushl  0x48(%edx)
f0104692:	ff 70 48             	pushl  0x48(%eax)
f0104695:	8d 83 1b 9c f7 ff    	lea    -0x863e5(%ebx),%eax
f010469b:	50                   	push   %eax
f010469c:	e8 1d f6 ff ff       	call   f0103cbe <cprintf>
f01046a1:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f01046a4:	83 ec 0c             	sub    $0xc,%esp
f01046a7:	ff 75 f4             	pushl  -0xc(%ebp)
f01046aa:	e8 a1 f4 ff ff       	call   f0103b50 <env_destroy>
f01046af:	83 c4 10             	add    $0x10,%esp
	return 0;
f01046b2:	b8 00 00 00 00       	mov    $0x0,%eax
			break;
f01046b7:	eb 93                	jmp    f010464c <syscall+0x62>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f01046b9:	83 ec 08             	sub    $0x8,%esp
f01046bc:	ff 70 48             	pushl  0x48(%eax)
f01046bf:	8d 83 00 9c f7 ff    	lea    -0x86400(%ebx),%eax
f01046c5:	50                   	push   %eax
f01046c6:	e8 f3 f5 ff ff       	call   f0103cbe <cprintf>
f01046cb:	83 c4 10             	add    $0x10,%esp
f01046ce:	eb d4                	jmp    f01046a4 <syscall+0xba>

f01046d0 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01046d0:	55                   	push   %ebp
f01046d1:	89 e5                	mov    %esp,%ebp
f01046d3:	57                   	push   %edi
f01046d4:	56                   	push   %esi
f01046d5:	53                   	push   %ebx
f01046d6:	83 ec 14             	sub    $0x14,%esp
f01046d9:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01046dc:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01046df:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01046e2:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01046e5:	8b 32                	mov    (%edx),%esi
f01046e7:	8b 01                	mov    (%ecx),%eax
f01046e9:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01046ec:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01046f3:	eb 2f                	jmp    f0104724 <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f01046f5:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f01046f8:	39 c6                	cmp    %eax,%esi
f01046fa:	7f 49                	jg     f0104745 <stab_binsearch+0x75>
f01046fc:	0f b6 0a             	movzbl (%edx),%ecx
f01046ff:	83 ea 0c             	sub    $0xc,%edx
f0104702:	39 f9                	cmp    %edi,%ecx
f0104704:	75 ef                	jne    f01046f5 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0104706:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104709:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010470c:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104710:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0104713:	73 35                	jae    f010474a <stab_binsearch+0x7a>
			*region_left = m;
f0104715:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104718:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f010471a:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f010471d:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f0104724:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0104727:	7f 4e                	jg     f0104777 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0104729:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010472c:	01 f0                	add    %esi,%eax
f010472e:	89 c3                	mov    %eax,%ebx
f0104730:	c1 eb 1f             	shr    $0x1f,%ebx
f0104733:	01 c3                	add    %eax,%ebx
f0104735:	d1 fb                	sar    %ebx
f0104737:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f010473a:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010473d:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f0104741:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f0104743:	eb b3                	jmp    f01046f8 <stab_binsearch+0x28>
			l = true_m + 1;
f0104745:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0104748:	eb da                	jmp    f0104724 <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f010474a:	3b 55 0c             	cmp    0xc(%ebp),%edx
f010474d:	76 14                	jbe    f0104763 <stab_binsearch+0x93>
			*region_right = m - 1;
f010474f:	83 e8 01             	sub    $0x1,%eax
f0104752:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104755:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104758:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f010475a:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104761:	eb c1                	jmp    f0104724 <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0104763:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104766:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0104768:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f010476c:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f010476e:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104775:	eb ad                	jmp    f0104724 <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0104777:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f010477b:	74 16                	je     f0104793 <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010477d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104780:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104782:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104785:	8b 0e                	mov    (%esi),%ecx
f0104787:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010478a:	8b 75 ec             	mov    -0x14(%ebp),%esi
f010478d:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f0104791:	eb 12                	jmp    f01047a5 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f0104793:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104796:	8b 00                	mov    (%eax),%eax
f0104798:	83 e8 01             	sub    $0x1,%eax
f010479b:	8b 7d e0             	mov    -0x20(%ebp),%edi
f010479e:	89 07                	mov    %eax,(%edi)
f01047a0:	eb 16                	jmp    f01047b8 <stab_binsearch+0xe8>
		     l--)
f01047a2:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f01047a5:	39 c1                	cmp    %eax,%ecx
f01047a7:	7d 0a                	jge    f01047b3 <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f01047a9:	0f b6 1a             	movzbl (%edx),%ebx
f01047ac:	83 ea 0c             	sub    $0xc,%edx
f01047af:	39 fb                	cmp    %edi,%ebx
f01047b1:	75 ef                	jne    f01047a2 <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f01047b3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01047b6:	89 07                	mov    %eax,(%edi)
	}
}
f01047b8:	83 c4 14             	add    $0x14,%esp
f01047bb:	5b                   	pop    %ebx
f01047bc:	5e                   	pop    %esi
f01047bd:	5f                   	pop    %edi
f01047be:	5d                   	pop    %ebp
f01047bf:	c3                   	ret    

f01047c0 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01047c0:	55                   	push   %ebp
f01047c1:	89 e5                	mov    %esp,%ebp
f01047c3:	57                   	push   %edi
f01047c4:	56                   	push   %esi
f01047c5:	53                   	push   %ebx
f01047c6:	83 ec 4c             	sub    $0x4c,%esp
f01047c9:	e8 99 b9 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01047ce:	81 c3 52 88 08 00    	add    $0x88852,%ebx
f01047d4:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01047d7:	8d 83 33 9c f7 ff    	lea    -0x863cd(%ebx),%eax
f01047dd:	89 07                	mov    %eax,(%edi)
	info->eip_line = 0;
f01047df:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f01047e6:	89 47 08             	mov    %eax,0x8(%edi)
	info->eip_fn_namelen = 9;
f01047e9:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f01047f0:	8b 45 08             	mov    0x8(%ebp),%eax
f01047f3:	89 47 10             	mov    %eax,0x10(%edi)
	info->eip_fn_narg = 0;
f01047f6:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01047fd:	3d ff ff 7f ef       	cmp    $0xef7fffff,%eax
f0104802:	0f 86 34 01 00 00    	jbe    f010493c <debuginfo_eip+0x17c>
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104808:	c7 c0 15 26 11 f0    	mov    $0xf0112615,%eax
f010480e:	89 45 b8             	mov    %eax,-0x48(%ebp)
		stabstr = __STABSTR_BEGIN__;
f0104811:	c7 c0 f1 fa 10 f0    	mov    $0xf010faf1,%eax
f0104817:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		stab_end = __STAB_END__;
f010481a:	c7 c6 f0 fa 10 f0    	mov    $0xf010faf0,%esi
		stabs = __STAB_BEGIN__;
f0104820:	c7 c0 50 6e 10 f0    	mov    $0xf0106e50,%eax
f0104826:	89 45 bc             	mov    %eax,-0x44(%ebp)
			return - 1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104829:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f010482c:	39 4d b4             	cmp    %ecx,-0x4c(%ebp)
f010482f:	0f 83 64 02 00 00    	jae    f0104a99 <debuginfo_eip+0x2d9>
f0104835:	80 79 ff 00          	cmpb   $0x0,-0x1(%ecx)
f0104839:	0f 85 61 02 00 00    	jne    f0104aa0 <debuginfo_eip+0x2e0>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010483f:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0104846:	2b 75 bc             	sub    -0x44(%ebp),%esi
f0104849:	c1 fe 02             	sar    $0x2,%esi
f010484c:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f0104852:	83 e8 01             	sub    $0x1,%eax
f0104855:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0104858:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f010485b:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010485e:	83 ec 08             	sub    $0x8,%esp
f0104861:	ff 75 08             	pushl  0x8(%ebp)
f0104864:	6a 64                	push   $0x64
f0104866:	8b 75 bc             	mov    -0x44(%ebp),%esi
f0104869:	89 f0                	mov    %esi,%eax
f010486b:	e8 60 fe ff ff       	call   f01046d0 <stab_binsearch>
	if (lfile == 0)
f0104870:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104873:	83 c4 10             	add    $0x10,%esp
f0104876:	85 c0                	test   %eax,%eax
f0104878:	0f 84 29 02 00 00    	je     f0104aa7 <debuginfo_eip+0x2e7>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010487e:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104881:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104884:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0104887:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010488a:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010488d:	83 ec 08             	sub    $0x8,%esp
f0104890:	ff 75 08             	pushl  0x8(%ebp)
f0104893:	6a 24                	push   $0x24
f0104895:	89 f0                	mov    %esi,%eax
f0104897:	e8 34 fe ff ff       	call   f01046d0 <stab_binsearch>

	if (lfun <= rfun) {
f010489c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010489f:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01048a2:	83 c4 10             	add    $0x10,%esp
f01048a5:	39 d0                	cmp    %edx,%eax
f01048a7:	0f 8f 1e 01 00 00    	jg     f01049cb <debuginfo_eip+0x20b>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01048ad:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f01048b0:	8d 34 8e             	lea    (%esi,%ecx,4),%esi
f01048b3:	89 75 c4             	mov    %esi,-0x3c(%ebp)
f01048b6:	8b 36                	mov    (%esi),%esi
f01048b8:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f01048bb:	2b 4d b4             	sub    -0x4c(%ebp),%ecx
f01048be:	39 ce                	cmp    %ecx,%esi
f01048c0:	73 06                	jae    f01048c8 <debuginfo_eip+0x108>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01048c2:	03 75 b4             	add    -0x4c(%ebp),%esi
f01048c5:	89 77 08             	mov    %esi,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f01048c8:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f01048cb:	8b 4e 08             	mov    0x8(%esi),%ecx
f01048ce:	89 4f 10             	mov    %ecx,0x10(%edi)
		addr -= info->eip_fn_addr;
f01048d1:	29 4d 08             	sub    %ecx,0x8(%ebp)
		// Search within the function definition for the line number.
		lline = lfun;
f01048d4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01048d7:	89 55 d0             	mov    %edx,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01048da:	83 ec 08             	sub    $0x8,%esp
f01048dd:	6a 3a                	push   $0x3a
f01048df:	ff 77 08             	pushl  0x8(%edi)
f01048e2:	e8 43 0a 00 00       	call   f010532a <strfind>
f01048e7:	2b 47 08             	sub    0x8(%edi),%eax
f01048ea:	89 47 0c             	mov    %eax,0xc(%edi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01048ed:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01048f0:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01048f3:	83 c4 08             	add    $0x8,%esp
f01048f6:	ff 75 08             	pushl  0x8(%ebp)
f01048f9:	6a 44                	push   $0x44
f01048fb:	8b 5d bc             	mov    -0x44(%ebp),%ebx
f01048fe:	89 d8                	mov    %ebx,%eax
f0104900:	e8 cb fd ff ff       	call   f01046d0 <stab_binsearch>
	if (lline <= rline) {
f0104905:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0104908:	83 c4 10             	add    $0x10,%esp
f010490b:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f010490e:	0f 8f 9a 01 00 00    	jg     f0104aae <debuginfo_eip+0x2ee>
        info->eip_line = stabs[lline].n_desc;
f0104914:	89 d0                	mov    %edx,%eax
f0104916:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104919:	c1 e2 02             	shl    $0x2,%edx
f010491c:	0f b7 4c 13 06       	movzwl 0x6(%ebx,%edx,1),%ecx
f0104921:	89 4f 04             	mov    %ecx,0x4(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104924:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104927:	8d 54 13 04          	lea    0x4(%ebx,%edx,1),%edx
f010492b:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f010492f:	bb 01 00 00 00       	mov    $0x1,%ebx
f0104934:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0104937:	e9 af 00 00 00       	jmp    f01049eb <debuginfo_eip+0x22b>
		if(user_mem_check(curenv, usd, sizeof(struct UserStabData), PTE_P | PTE_U) < 0) {
f010493c:	6a 05                	push   $0x5
f010493e:	6a 10                	push   $0x10
f0104940:	68 00 00 20 00       	push   $0x200000
f0104945:	c7 c0 48 f3 18 f0    	mov    $0xf018f348,%eax
f010494b:	ff 30                	pushl  (%eax)
f010494d:	e8 f3 e9 ff ff       	call   f0103345 <user_mem_check>
f0104952:	83 c4 10             	add    $0x10,%esp
f0104955:	85 c0                	test   %eax,%eax
f0104957:	0f 88 2e 01 00 00    	js     f0104a8b <debuginfo_eip+0x2cb>
		stabs = usd->stabs;
f010495d:	8b 0d 00 00 20 00    	mov    0x200000,%ecx
f0104963:	89 4d bc             	mov    %ecx,-0x44(%ebp)
		stab_end = usd->stab_end;
f0104966:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f010496c:	a1 08 00 20 00       	mov    0x200008,%eax
f0104971:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		stabstr_end = usd->stabstr_end;
f0104974:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f010497a:	89 55 b8             	mov    %edx,-0x48(%ebp)
		if(user_mem_check(curenv, stabs, (stab_end - stabs) * sizeof(struct Stab), PTE_P | PTE_U) < 0) {
f010497d:	6a 05                	push   $0x5
f010497f:	89 f0                	mov    %esi,%eax
f0104981:	29 c8                	sub    %ecx,%eax
f0104983:	50                   	push   %eax
f0104984:	51                   	push   %ecx
f0104985:	c7 c0 48 f3 18 f0    	mov    $0xf018f348,%eax
f010498b:	ff 30                	pushl  (%eax)
f010498d:	e8 b3 e9 ff ff       	call   f0103345 <user_mem_check>
f0104992:	83 c4 10             	add    $0x10,%esp
f0104995:	85 c0                	test   %eax,%eax
f0104997:	0f 88 f5 00 00 00    	js     f0104a92 <debuginfo_eip+0x2d2>
		if(user_mem_check(curenv, stabstr, (stabstr_end - stabstr), PTE_P | PTE_U) < 0) {
f010499d:	6a 05                	push   $0x5
f010499f:	8b 55 b8             	mov    -0x48(%ebp),%edx
f01049a2:	8b 4d b4             	mov    -0x4c(%ebp),%ecx
f01049a5:	29 ca                	sub    %ecx,%edx
f01049a7:	52                   	push   %edx
f01049a8:	51                   	push   %ecx
f01049a9:	c7 c0 48 f3 18 f0    	mov    $0xf018f348,%eax
f01049af:	ff 30                	pushl  (%eax)
f01049b1:	e8 8f e9 ff ff       	call   f0103345 <user_mem_check>
f01049b6:	83 c4 10             	add    $0x10,%esp
f01049b9:	85 c0                	test   %eax,%eax
f01049bb:	0f 89 68 fe ff ff    	jns    f0104829 <debuginfo_eip+0x69>
			return - 1;
f01049c1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01049c6:	e9 ef 00 00 00       	jmp    f0104aba <debuginfo_eip+0x2fa>
		info->eip_fn_addr = addr;
f01049cb:	8b 45 08             	mov    0x8(%ebp),%eax
f01049ce:	89 47 10             	mov    %eax,0x10(%edi)
		lline = lfile;
f01049d1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01049d4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01049d7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01049da:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01049dd:	e9 f8 fe ff ff       	jmp    f01048da <debuginfo_eip+0x11a>
f01049e2:	83 e8 01             	sub    $0x1,%eax
f01049e5:	83 ea 0c             	sub    $0xc,%edx
f01049e8:	88 5d c4             	mov    %bl,-0x3c(%ebp)
f01049eb:	89 45 c0             	mov    %eax,-0x40(%ebp)
	while (lline >= lfile
f01049ee:	39 c6                	cmp    %eax,%esi
f01049f0:	7f 24                	jg     f0104a16 <debuginfo_eip+0x256>
	       && stabs[lline].n_type != N_SOL
f01049f2:	0f b6 0a             	movzbl (%edx),%ecx
f01049f5:	80 f9 84             	cmp    $0x84,%cl
f01049f8:	74 46                	je     f0104a40 <debuginfo_eip+0x280>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01049fa:	80 f9 64             	cmp    $0x64,%cl
f01049fd:	75 e3                	jne    f01049e2 <debuginfo_eip+0x222>
f01049ff:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f0104a03:	74 dd                	je     f01049e2 <debuginfo_eip+0x222>
f0104a05:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104a08:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0104a0c:	74 3b                	je     f0104a49 <debuginfo_eip+0x289>
f0104a0e:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0104a11:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0104a14:	eb 33                	jmp    f0104a49 <debuginfo_eip+0x289>
f0104a16:	8b 7d 0c             	mov    0xc(%ebp),%edi
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104a19:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104a1c:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104a1f:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f0104a24:	39 da                	cmp    %ebx,%edx
f0104a26:	0f 8d 8e 00 00 00    	jge    f0104aba <debuginfo_eip+0x2fa>
		for (lline = lfun + 1;
f0104a2c:	83 c2 01             	add    $0x1,%edx
f0104a2f:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104a32:	89 d0                	mov    %edx,%eax
f0104a34:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104a37:	8b 75 bc             	mov    -0x44(%ebp),%esi
f0104a3a:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
f0104a3e:	eb 32                	jmp    f0104a72 <debuginfo_eip+0x2b2>
f0104a40:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104a43:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0104a47:	75 1d                	jne    f0104a66 <debuginfo_eip+0x2a6>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0104a49:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104a4c:	8b 75 bc             	mov    -0x44(%ebp),%esi
f0104a4f:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0104a52:	8b 45 b8             	mov    -0x48(%ebp),%eax
f0104a55:	8b 75 b4             	mov    -0x4c(%ebp),%esi
f0104a58:	29 f0                	sub    %esi,%eax
f0104a5a:	39 c2                	cmp    %eax,%edx
f0104a5c:	73 bb                	jae    f0104a19 <debuginfo_eip+0x259>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104a5e:	89 f0                	mov    %esi,%eax
f0104a60:	01 d0                	add    %edx,%eax
f0104a62:	89 07                	mov    %eax,(%edi)
f0104a64:	eb b3                	jmp    f0104a19 <debuginfo_eip+0x259>
f0104a66:	8b 75 c0             	mov    -0x40(%ebp),%esi
f0104a69:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0104a6c:	eb db                	jmp    f0104a49 <debuginfo_eip+0x289>
			info->eip_fn_narg++;
f0104a6e:	83 47 14 01          	addl   $0x1,0x14(%edi)
		for (lline = lfun + 1;
f0104a72:	39 c3                	cmp    %eax,%ebx
f0104a74:	7e 3f                	jle    f0104ab5 <debuginfo_eip+0x2f5>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104a76:	0f b6 0a             	movzbl (%edx),%ecx
f0104a79:	83 c0 01             	add    $0x1,%eax
f0104a7c:	83 c2 0c             	add    $0xc,%edx
f0104a7f:	80 f9 a0             	cmp    $0xa0,%cl
f0104a82:	74 ea                	je     f0104a6e <debuginfo_eip+0x2ae>
	return 0;
f0104a84:	b8 00 00 00 00       	mov    $0x0,%eax
f0104a89:	eb 2f                	jmp    f0104aba <debuginfo_eip+0x2fa>
			return -1;
f0104a8b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104a90:	eb 28                	jmp    f0104aba <debuginfo_eip+0x2fa>
			return -1;
f0104a92:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104a97:	eb 21                	jmp    f0104aba <debuginfo_eip+0x2fa>
		return -1;
f0104a99:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104a9e:	eb 1a                	jmp    f0104aba <debuginfo_eip+0x2fa>
f0104aa0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104aa5:	eb 13                	jmp    f0104aba <debuginfo_eip+0x2fa>
		return -1;
f0104aa7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104aac:	eb 0c                	jmp    f0104aba <debuginfo_eip+0x2fa>
        return -1;
f0104aae:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104ab3:	eb 05                	jmp    f0104aba <debuginfo_eip+0x2fa>
	return 0;
f0104ab5:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104aba:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104abd:	5b                   	pop    %ebx
f0104abe:	5e                   	pop    %esi
f0104abf:	5f                   	pop    %edi
f0104ac0:	5d                   	pop    %ebp
f0104ac1:	c3                   	ret    

f0104ac2 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104ac2:	55                   	push   %ebp
f0104ac3:	89 e5                	mov    %esp,%ebp
f0104ac5:	57                   	push   %edi
f0104ac6:	56                   	push   %esi
f0104ac7:	53                   	push   %ebx
f0104ac8:	83 ec 2c             	sub    $0x2c,%esp
f0104acb:	e8 6b e9 ff ff       	call   f010343b <__x86.get_pc_thunk.cx>
f0104ad0:	81 c1 50 85 08 00    	add    $0x88550,%ecx
f0104ad6:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0104ad9:	89 c7                	mov    %eax,%edi
f0104adb:	89 d6                	mov    %edx,%esi
f0104add:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ae0:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104ae3:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0104ae6:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104ae9:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104aec:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104af1:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f0104af4:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0104af7:	39 d3                	cmp    %edx,%ebx
f0104af9:	72 09                	jb     f0104b04 <printnum+0x42>
f0104afb:	39 45 10             	cmp    %eax,0x10(%ebp)
f0104afe:	0f 87 83 00 00 00    	ja     f0104b87 <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104b04:	83 ec 0c             	sub    $0xc,%esp
f0104b07:	ff 75 18             	pushl  0x18(%ebp)
f0104b0a:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b0d:	8d 58 ff             	lea    -0x1(%eax),%ebx
f0104b10:	53                   	push   %ebx
f0104b11:	ff 75 10             	pushl  0x10(%ebp)
f0104b14:	83 ec 08             	sub    $0x8,%esp
f0104b17:	ff 75 dc             	pushl  -0x24(%ebp)
f0104b1a:	ff 75 d8             	pushl  -0x28(%ebp)
f0104b1d:	ff 75 d4             	pushl  -0x2c(%ebp)
f0104b20:	ff 75 d0             	pushl  -0x30(%ebp)
f0104b23:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104b26:	e8 25 0a 00 00       	call   f0105550 <__udivdi3>
f0104b2b:	83 c4 18             	add    $0x18,%esp
f0104b2e:	52                   	push   %edx
f0104b2f:	50                   	push   %eax
f0104b30:	89 f2                	mov    %esi,%edx
f0104b32:	89 f8                	mov    %edi,%eax
f0104b34:	e8 89 ff ff ff       	call   f0104ac2 <printnum>
f0104b39:	83 c4 20             	add    $0x20,%esp
f0104b3c:	eb 13                	jmp    f0104b51 <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104b3e:	83 ec 08             	sub    $0x8,%esp
f0104b41:	56                   	push   %esi
f0104b42:	ff 75 18             	pushl  0x18(%ebp)
f0104b45:	ff d7                	call   *%edi
f0104b47:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0104b4a:	83 eb 01             	sub    $0x1,%ebx
f0104b4d:	85 db                	test   %ebx,%ebx
f0104b4f:	7f ed                	jg     f0104b3e <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104b51:	83 ec 08             	sub    $0x8,%esp
f0104b54:	56                   	push   %esi
f0104b55:	83 ec 04             	sub    $0x4,%esp
f0104b58:	ff 75 dc             	pushl  -0x24(%ebp)
f0104b5b:	ff 75 d8             	pushl  -0x28(%ebp)
f0104b5e:	ff 75 d4             	pushl  -0x2c(%ebp)
f0104b61:	ff 75 d0             	pushl  -0x30(%ebp)
f0104b64:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104b67:	89 f3                	mov    %esi,%ebx
f0104b69:	e8 02 0b 00 00       	call   f0105670 <__umoddi3>
f0104b6e:	83 c4 14             	add    $0x14,%esp
f0104b71:	0f be 84 06 3d 9c f7 	movsbl -0x863c3(%esi,%eax,1),%eax
f0104b78:	ff 
f0104b79:	50                   	push   %eax
f0104b7a:	ff d7                	call   *%edi
}
f0104b7c:	83 c4 10             	add    $0x10,%esp
f0104b7f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104b82:	5b                   	pop    %ebx
f0104b83:	5e                   	pop    %esi
f0104b84:	5f                   	pop    %edi
f0104b85:	5d                   	pop    %ebp
f0104b86:	c3                   	ret    
f0104b87:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0104b8a:	eb be                	jmp    f0104b4a <printnum+0x88>

f0104b8c <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104b8c:	55                   	push   %ebp
f0104b8d:	89 e5                	mov    %esp,%ebp
f0104b8f:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104b92:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104b96:	8b 10                	mov    (%eax),%edx
f0104b98:	3b 50 04             	cmp    0x4(%eax),%edx
f0104b9b:	73 0a                	jae    f0104ba7 <sprintputch+0x1b>
		*b->buf++ = ch;
f0104b9d:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104ba0:	89 08                	mov    %ecx,(%eax)
f0104ba2:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ba5:	88 02                	mov    %al,(%edx)
}
f0104ba7:	5d                   	pop    %ebp
f0104ba8:	c3                   	ret    

f0104ba9 <printfmt>:
{
f0104ba9:	55                   	push   %ebp
f0104baa:	89 e5                	mov    %esp,%ebp
f0104bac:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f0104baf:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104bb2:	50                   	push   %eax
f0104bb3:	ff 75 10             	pushl  0x10(%ebp)
f0104bb6:	ff 75 0c             	pushl  0xc(%ebp)
f0104bb9:	ff 75 08             	pushl  0x8(%ebp)
f0104bbc:	e8 05 00 00 00       	call   f0104bc6 <vprintfmt>
}
f0104bc1:	83 c4 10             	add    $0x10,%esp
f0104bc4:	c9                   	leave  
f0104bc5:	c3                   	ret    

f0104bc6 <vprintfmt>:
{
f0104bc6:	55                   	push   %ebp
f0104bc7:	89 e5                	mov    %esp,%ebp
f0104bc9:	57                   	push   %edi
f0104bca:	56                   	push   %esi
f0104bcb:	53                   	push   %ebx
f0104bcc:	83 ec 2c             	sub    $0x2c,%esp
f0104bcf:	e8 93 b5 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0104bd4:	81 c3 4c 84 08 00    	add    $0x8844c,%ebx
f0104bda:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104bdd:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104be0:	e9 63 03 00 00       	jmp    f0104f48 <.L34+0x40>
		padc = ' ';
f0104be5:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f0104be9:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f0104bf0:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
		width = -1;
f0104bf7:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f0104bfe:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104c03:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0104c06:	8d 47 01             	lea    0x1(%edi),%eax
f0104c09:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104c0c:	0f b6 17             	movzbl (%edi),%edx
f0104c0f:	8d 42 dd             	lea    -0x23(%edx),%eax
f0104c12:	3c 55                	cmp    $0x55,%al
f0104c14:	0f 87 15 04 00 00    	ja     f010502f <.L22>
f0104c1a:	0f b6 c0             	movzbl %al,%eax
f0104c1d:	89 d9                	mov    %ebx,%ecx
f0104c1f:	03 8c 83 c8 9c f7 ff 	add    -0x86338(%ebx,%eax,4),%ecx
f0104c26:	ff e1                	jmp    *%ecx

f0104c28 <.L70>:
f0104c28:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0104c2b:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f0104c2f:	eb d5                	jmp    f0104c06 <vprintfmt+0x40>

f0104c31 <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f0104c31:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f0104c34:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0104c38:	eb cc                	jmp    f0104c06 <vprintfmt+0x40>

f0104c3a <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f0104c3a:	0f b6 d2             	movzbl %dl,%edx
f0104c3d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f0104c40:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f0104c45:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0104c48:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f0104c4c:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f0104c4f:	8d 4a d0             	lea    -0x30(%edx),%ecx
f0104c52:	83 f9 09             	cmp    $0x9,%ecx
f0104c55:	77 55                	ja     f0104cac <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f0104c57:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f0104c5a:	eb e9                	jmp    f0104c45 <.L29+0xb>

f0104c5c <.L26>:
			precision = va_arg(ap, int);
f0104c5c:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c5f:	8b 00                	mov    (%eax),%eax
f0104c61:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0104c64:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c67:	8d 40 04             	lea    0x4(%eax),%eax
f0104c6a:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0104c6d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f0104c70:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104c74:	79 90                	jns    f0104c06 <vprintfmt+0x40>
				width = precision, precision = -1;
f0104c76:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0104c79:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104c7c:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f0104c83:	eb 81                	jmp    f0104c06 <vprintfmt+0x40>

f0104c85 <.L27>:
f0104c85:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104c88:	85 c0                	test   %eax,%eax
f0104c8a:	ba 00 00 00 00       	mov    $0x0,%edx
f0104c8f:	0f 49 d0             	cmovns %eax,%edx
f0104c92:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0104c95:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104c98:	e9 69 ff ff ff       	jmp    f0104c06 <vprintfmt+0x40>

f0104c9d <.L23>:
f0104c9d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f0104ca0:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0104ca7:	e9 5a ff ff ff       	jmp    f0104c06 <vprintfmt+0x40>
f0104cac:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0104caf:	eb bf                	jmp    f0104c70 <.L26+0x14>

f0104cb1 <.L33>:
			lflag++;
f0104cb1:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0104cb5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0104cb8:	e9 49 ff ff ff       	jmp    f0104c06 <vprintfmt+0x40>

f0104cbd <.L30>:
			putch(va_arg(ap, int), putdat);
f0104cbd:	8b 45 14             	mov    0x14(%ebp),%eax
f0104cc0:	8d 78 04             	lea    0x4(%eax),%edi
f0104cc3:	83 ec 08             	sub    $0x8,%esp
f0104cc6:	56                   	push   %esi
f0104cc7:	ff 30                	pushl  (%eax)
f0104cc9:	ff 55 08             	call   *0x8(%ebp)
			break;
f0104ccc:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0104ccf:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0104cd2:	e9 6e 02 00 00       	jmp    f0104f45 <.L34+0x3d>

f0104cd7 <.L32>:
			err = va_arg(ap, int);
f0104cd7:	8b 45 14             	mov    0x14(%ebp),%eax
f0104cda:	8d 78 04             	lea    0x4(%eax),%edi
f0104cdd:	8b 00                	mov    (%eax),%eax
f0104cdf:	99                   	cltd   
f0104ce0:	31 d0                	xor    %edx,%eax
f0104ce2:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104ce4:	83 f8 06             	cmp    $0x6,%eax
f0104ce7:	7f 27                	jg     f0104d10 <.L32+0x39>
f0104ce9:	8b 94 83 b0 20 00 00 	mov    0x20b0(%ebx,%eax,4),%edx
f0104cf0:	85 d2                	test   %edx,%edx
f0104cf2:	74 1c                	je     f0104d10 <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f0104cf4:	52                   	push   %edx
f0104cf5:	8d 83 ae 8c f7 ff    	lea    -0x87352(%ebx),%eax
f0104cfb:	50                   	push   %eax
f0104cfc:	56                   	push   %esi
f0104cfd:	ff 75 08             	pushl  0x8(%ebp)
f0104d00:	e8 a4 fe ff ff       	call   f0104ba9 <printfmt>
f0104d05:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0104d08:	89 7d 14             	mov    %edi,0x14(%ebp)
f0104d0b:	e9 35 02 00 00       	jmp    f0104f45 <.L34+0x3d>
				printfmt(putch, putdat, "error %d", err);
f0104d10:	50                   	push   %eax
f0104d11:	8d 83 55 9c f7 ff    	lea    -0x863ab(%ebx),%eax
f0104d17:	50                   	push   %eax
f0104d18:	56                   	push   %esi
f0104d19:	ff 75 08             	pushl  0x8(%ebp)
f0104d1c:	e8 88 fe ff ff       	call   f0104ba9 <printfmt>
f0104d21:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0104d24:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0104d27:	e9 19 02 00 00       	jmp    f0104f45 <.L34+0x3d>

f0104d2c <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f0104d2c:	8b 45 14             	mov    0x14(%ebp),%eax
f0104d2f:	83 c0 04             	add    $0x4,%eax
f0104d32:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0104d35:	8b 45 14             	mov    0x14(%ebp),%eax
f0104d38:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0104d3a:	85 ff                	test   %edi,%edi
f0104d3c:	8d 83 4e 9c f7 ff    	lea    -0x863b2(%ebx),%eax
f0104d42:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0104d45:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104d49:	0f 8e b5 00 00 00    	jle    f0104e04 <.L36+0xd8>
f0104d4f:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0104d53:	75 08                	jne    f0104d5d <.L36+0x31>
f0104d55:	89 75 0c             	mov    %esi,0xc(%ebp)
f0104d58:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0104d5b:	eb 6d                	jmp    f0104dca <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104d5d:	83 ec 08             	sub    $0x8,%esp
f0104d60:	ff 75 cc             	pushl  -0x34(%ebp)
f0104d63:	57                   	push   %edi
f0104d64:	e8 7d 04 00 00       	call   f01051e6 <strnlen>
f0104d69:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0104d6c:	29 c2                	sub    %eax,%edx
f0104d6e:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0104d71:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0104d74:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0104d78:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104d7b:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0104d7e:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0104d80:	eb 10                	jmp    f0104d92 <.L36+0x66>
					putch(padc, putdat);
f0104d82:	83 ec 08             	sub    $0x8,%esp
f0104d85:	56                   	push   %esi
f0104d86:	ff 75 e0             	pushl  -0x20(%ebp)
f0104d89:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0104d8c:	83 ef 01             	sub    $0x1,%edi
f0104d8f:	83 c4 10             	add    $0x10,%esp
f0104d92:	85 ff                	test   %edi,%edi
f0104d94:	7f ec                	jg     f0104d82 <.L36+0x56>
f0104d96:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104d99:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0104d9c:	85 d2                	test   %edx,%edx
f0104d9e:	b8 00 00 00 00       	mov    $0x0,%eax
f0104da3:	0f 49 c2             	cmovns %edx,%eax
f0104da6:	29 c2                	sub    %eax,%edx
f0104da8:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0104dab:	89 75 0c             	mov    %esi,0xc(%ebp)
f0104dae:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0104db1:	eb 17                	jmp    f0104dca <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f0104db3:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104db7:	75 30                	jne    f0104de9 <.L36+0xbd>
					putch(ch, putdat);
f0104db9:	83 ec 08             	sub    $0x8,%esp
f0104dbc:	ff 75 0c             	pushl  0xc(%ebp)
f0104dbf:	50                   	push   %eax
f0104dc0:	ff 55 08             	call   *0x8(%ebp)
f0104dc3:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104dc6:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f0104dca:	83 c7 01             	add    $0x1,%edi
f0104dcd:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0104dd1:	0f be c2             	movsbl %dl,%eax
f0104dd4:	85 c0                	test   %eax,%eax
f0104dd6:	74 52                	je     f0104e2a <.L36+0xfe>
f0104dd8:	85 f6                	test   %esi,%esi
f0104dda:	78 d7                	js     f0104db3 <.L36+0x87>
f0104ddc:	83 ee 01             	sub    $0x1,%esi
f0104ddf:	79 d2                	jns    f0104db3 <.L36+0x87>
f0104de1:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104de4:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104de7:	eb 32                	jmp    f0104e1b <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f0104de9:	0f be d2             	movsbl %dl,%edx
f0104dec:	83 ea 20             	sub    $0x20,%edx
f0104def:	83 fa 5e             	cmp    $0x5e,%edx
f0104df2:	76 c5                	jbe    f0104db9 <.L36+0x8d>
					putch('?', putdat);
f0104df4:	83 ec 08             	sub    $0x8,%esp
f0104df7:	ff 75 0c             	pushl  0xc(%ebp)
f0104dfa:	6a 3f                	push   $0x3f
f0104dfc:	ff 55 08             	call   *0x8(%ebp)
f0104dff:	83 c4 10             	add    $0x10,%esp
f0104e02:	eb c2                	jmp    f0104dc6 <.L36+0x9a>
f0104e04:	89 75 0c             	mov    %esi,0xc(%ebp)
f0104e07:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0104e0a:	eb be                	jmp    f0104dca <.L36+0x9e>
				putch(' ', putdat);
f0104e0c:	83 ec 08             	sub    $0x8,%esp
f0104e0f:	56                   	push   %esi
f0104e10:	6a 20                	push   $0x20
f0104e12:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f0104e15:	83 ef 01             	sub    $0x1,%edi
f0104e18:	83 c4 10             	add    $0x10,%esp
f0104e1b:	85 ff                	test   %edi,%edi
f0104e1d:	7f ed                	jg     f0104e0c <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f0104e1f:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104e22:	89 45 14             	mov    %eax,0x14(%ebp)
f0104e25:	e9 1b 01 00 00       	jmp    f0104f45 <.L34+0x3d>
f0104e2a:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104e2d:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104e30:	eb e9                	jmp    f0104e1b <.L36+0xef>

f0104e32 <.L31>:
f0104e32:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0104e35:	83 f9 01             	cmp    $0x1,%ecx
f0104e38:	7e 40                	jle    f0104e7a <.L31+0x48>
		return va_arg(*ap, long long);
f0104e3a:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e3d:	8b 50 04             	mov    0x4(%eax),%edx
f0104e40:	8b 00                	mov    (%eax),%eax
f0104e42:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104e45:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104e48:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e4b:	8d 40 08             	lea    0x8(%eax),%eax
f0104e4e:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0104e51:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104e55:	79 55                	jns    f0104eac <.L31+0x7a>
				putch('-', putdat);
f0104e57:	83 ec 08             	sub    $0x8,%esp
f0104e5a:	56                   	push   %esi
f0104e5b:	6a 2d                	push   $0x2d
f0104e5d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0104e60:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104e63:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0104e66:	f7 da                	neg    %edx
f0104e68:	83 d1 00             	adc    $0x0,%ecx
f0104e6b:	f7 d9                	neg    %ecx
f0104e6d:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0104e70:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104e75:	e9 b0 00 00 00       	jmp    f0104f2a <.L34+0x22>
	else if (lflag)
f0104e7a:	85 c9                	test   %ecx,%ecx
f0104e7c:	75 17                	jne    f0104e95 <.L31+0x63>
		return va_arg(*ap, int);
f0104e7e:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e81:	8b 00                	mov    (%eax),%eax
f0104e83:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104e86:	99                   	cltd   
f0104e87:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104e8a:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e8d:	8d 40 04             	lea    0x4(%eax),%eax
f0104e90:	89 45 14             	mov    %eax,0x14(%ebp)
f0104e93:	eb bc                	jmp    f0104e51 <.L31+0x1f>
		return va_arg(*ap, long);
f0104e95:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e98:	8b 00                	mov    (%eax),%eax
f0104e9a:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104e9d:	99                   	cltd   
f0104e9e:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104ea1:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ea4:	8d 40 04             	lea    0x4(%eax),%eax
f0104ea7:	89 45 14             	mov    %eax,0x14(%ebp)
f0104eaa:	eb a5                	jmp    f0104e51 <.L31+0x1f>
			num = getint(&ap, lflag);
f0104eac:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104eaf:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0104eb2:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104eb7:	eb 71                	jmp    f0104f2a <.L34+0x22>

f0104eb9 <.L37>:
f0104eb9:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0104ebc:	83 f9 01             	cmp    $0x1,%ecx
f0104ebf:	7e 15                	jle    f0104ed6 <.L37+0x1d>
		return va_arg(*ap, unsigned long long);
f0104ec1:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ec4:	8b 10                	mov    (%eax),%edx
f0104ec6:	8b 48 04             	mov    0x4(%eax),%ecx
f0104ec9:	8d 40 08             	lea    0x8(%eax),%eax
f0104ecc:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0104ecf:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104ed4:	eb 54                	jmp    f0104f2a <.L34+0x22>
	else if (lflag)
f0104ed6:	85 c9                	test   %ecx,%ecx
f0104ed8:	75 17                	jne    f0104ef1 <.L37+0x38>
		return va_arg(*ap, unsigned int);
f0104eda:	8b 45 14             	mov    0x14(%ebp),%eax
f0104edd:	8b 10                	mov    (%eax),%edx
f0104edf:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104ee4:	8d 40 04             	lea    0x4(%eax),%eax
f0104ee7:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0104eea:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104eef:	eb 39                	jmp    f0104f2a <.L34+0x22>
		return va_arg(*ap, unsigned long);
f0104ef1:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ef4:	8b 10                	mov    (%eax),%edx
f0104ef6:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104efb:	8d 40 04             	lea    0x4(%eax),%eax
f0104efe:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0104f01:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104f06:	eb 22                	jmp    f0104f2a <.L34+0x22>

f0104f08 <.L34>:
f0104f08:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0104f0b:	83 f9 01             	cmp    $0x1,%ecx
f0104f0e:	7e 5d                	jle    f0104f6d <.L34+0x65>
		return va_arg(*ap, long long);
f0104f10:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f13:	8b 50 04             	mov    0x4(%eax),%edx
f0104f16:	8b 00                	mov    (%eax),%eax
f0104f18:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0104f1b:	8d 49 08             	lea    0x8(%ecx),%ecx
f0104f1e:	89 4d 14             	mov    %ecx,0x14(%ebp)
			num = getint(&ap, lflag);
f0104f21:	89 d1                	mov    %edx,%ecx
f0104f23:	89 c2                	mov    %eax,%edx
			base = 8;
f0104f25:	b8 08 00 00 00       	mov    $0x8,%eax
			printnum(putch, putdat, num, base, width, padc);
f0104f2a:	83 ec 0c             	sub    $0xc,%esp
f0104f2d:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0104f31:	57                   	push   %edi
f0104f32:	ff 75 e0             	pushl  -0x20(%ebp)
f0104f35:	50                   	push   %eax
f0104f36:	51                   	push   %ecx
f0104f37:	52                   	push   %edx
f0104f38:	89 f2                	mov    %esi,%edx
f0104f3a:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f3d:	e8 80 fb ff ff       	call   f0104ac2 <printnum>
			break;
f0104f42:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0104f45:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104f48:	83 c7 01             	add    $0x1,%edi
f0104f4b:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104f4f:	83 f8 25             	cmp    $0x25,%eax
f0104f52:	0f 84 8d fc ff ff    	je     f0104be5 <vprintfmt+0x1f>
			if (ch == '\0')
f0104f58:	85 c0                	test   %eax,%eax
f0104f5a:	0f 84 f0 00 00 00    	je     f0105050 <.L22+0x21>
			putch(ch, putdat);
f0104f60:	83 ec 08             	sub    $0x8,%esp
f0104f63:	56                   	push   %esi
f0104f64:	50                   	push   %eax
f0104f65:	ff 55 08             	call   *0x8(%ebp)
f0104f68:	83 c4 10             	add    $0x10,%esp
f0104f6b:	eb db                	jmp    f0104f48 <.L34+0x40>
	else if (lflag)
f0104f6d:	85 c9                	test   %ecx,%ecx
f0104f6f:	75 13                	jne    f0104f84 <.L34+0x7c>
		return va_arg(*ap, int);
f0104f71:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f74:	8b 10                	mov    (%eax),%edx
f0104f76:	89 d0                	mov    %edx,%eax
f0104f78:	99                   	cltd   
f0104f79:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0104f7c:	8d 49 04             	lea    0x4(%ecx),%ecx
f0104f7f:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0104f82:	eb 9d                	jmp    f0104f21 <.L34+0x19>
		return va_arg(*ap, long);
f0104f84:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f87:	8b 10                	mov    (%eax),%edx
f0104f89:	89 d0                	mov    %edx,%eax
f0104f8b:	99                   	cltd   
f0104f8c:	8b 4d 14             	mov    0x14(%ebp),%ecx
f0104f8f:	8d 49 04             	lea    0x4(%ecx),%ecx
f0104f92:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0104f95:	eb 8a                	jmp    f0104f21 <.L34+0x19>

f0104f97 <.L35>:
			putch('0', putdat);
f0104f97:	83 ec 08             	sub    $0x8,%esp
f0104f9a:	56                   	push   %esi
f0104f9b:	6a 30                	push   $0x30
f0104f9d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0104fa0:	83 c4 08             	add    $0x8,%esp
f0104fa3:	56                   	push   %esi
f0104fa4:	6a 78                	push   $0x78
f0104fa6:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f0104fa9:	8b 45 14             	mov    0x14(%ebp),%eax
f0104fac:	8b 10                	mov    (%eax),%edx
f0104fae:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0104fb3:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0104fb6:	8d 40 04             	lea    0x4(%eax),%eax
f0104fb9:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104fbc:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0104fc1:	e9 64 ff ff ff       	jmp    f0104f2a <.L34+0x22>

f0104fc6 <.L38>:
f0104fc6:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0104fc9:	83 f9 01             	cmp    $0x1,%ecx
f0104fcc:	7e 18                	jle    f0104fe6 <.L38+0x20>
		return va_arg(*ap, unsigned long long);
f0104fce:	8b 45 14             	mov    0x14(%ebp),%eax
f0104fd1:	8b 10                	mov    (%eax),%edx
f0104fd3:	8b 48 04             	mov    0x4(%eax),%ecx
f0104fd6:	8d 40 08             	lea    0x8(%eax),%eax
f0104fd9:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104fdc:	b8 10 00 00 00       	mov    $0x10,%eax
f0104fe1:	e9 44 ff ff ff       	jmp    f0104f2a <.L34+0x22>
	else if (lflag)
f0104fe6:	85 c9                	test   %ecx,%ecx
f0104fe8:	75 1a                	jne    f0105004 <.L38+0x3e>
		return va_arg(*ap, unsigned int);
f0104fea:	8b 45 14             	mov    0x14(%ebp),%eax
f0104fed:	8b 10                	mov    (%eax),%edx
f0104fef:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104ff4:	8d 40 04             	lea    0x4(%eax),%eax
f0104ff7:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104ffa:	b8 10 00 00 00       	mov    $0x10,%eax
f0104fff:	e9 26 ff ff ff       	jmp    f0104f2a <.L34+0x22>
		return va_arg(*ap, unsigned long);
f0105004:	8b 45 14             	mov    0x14(%ebp),%eax
f0105007:	8b 10                	mov    (%eax),%edx
f0105009:	b9 00 00 00 00       	mov    $0x0,%ecx
f010500e:	8d 40 04             	lea    0x4(%eax),%eax
f0105011:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0105014:	b8 10 00 00 00       	mov    $0x10,%eax
f0105019:	e9 0c ff ff ff       	jmp    f0104f2a <.L34+0x22>

f010501e <.L25>:
			putch(ch, putdat);
f010501e:	83 ec 08             	sub    $0x8,%esp
f0105021:	56                   	push   %esi
f0105022:	6a 25                	push   $0x25
f0105024:	ff 55 08             	call   *0x8(%ebp)
			break;
f0105027:	83 c4 10             	add    $0x10,%esp
f010502a:	e9 16 ff ff ff       	jmp    f0104f45 <.L34+0x3d>

f010502f <.L22>:
			putch('%', putdat);
f010502f:	83 ec 08             	sub    $0x8,%esp
f0105032:	56                   	push   %esi
f0105033:	6a 25                	push   $0x25
f0105035:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0105038:	83 c4 10             	add    $0x10,%esp
f010503b:	89 f8                	mov    %edi,%eax
f010503d:	eb 03                	jmp    f0105042 <.L22+0x13>
f010503f:	83 e8 01             	sub    $0x1,%eax
f0105042:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0105046:	75 f7                	jne    f010503f <.L22+0x10>
f0105048:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010504b:	e9 f5 fe ff ff       	jmp    f0104f45 <.L34+0x3d>
}
f0105050:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105053:	5b                   	pop    %ebx
f0105054:	5e                   	pop    %esi
f0105055:	5f                   	pop    %edi
f0105056:	5d                   	pop    %ebp
f0105057:	c3                   	ret    

f0105058 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0105058:	55                   	push   %ebp
f0105059:	89 e5                	mov    %esp,%ebp
f010505b:	53                   	push   %ebx
f010505c:	83 ec 14             	sub    $0x14,%esp
f010505f:	e8 03 b1 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0105064:	81 c3 bc 7f 08 00    	add    $0x87fbc,%ebx
f010506a:	8b 45 08             	mov    0x8(%ebp),%eax
f010506d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0105070:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0105073:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0105077:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010507a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0105081:	85 c0                	test   %eax,%eax
f0105083:	74 2b                	je     f01050b0 <vsnprintf+0x58>
f0105085:	85 d2                	test   %edx,%edx
f0105087:	7e 27                	jle    f01050b0 <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0105089:	ff 75 14             	pushl  0x14(%ebp)
f010508c:	ff 75 10             	pushl  0x10(%ebp)
f010508f:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0105092:	50                   	push   %eax
f0105093:	8d 83 6c 7b f7 ff    	lea    -0x88494(%ebx),%eax
f0105099:	50                   	push   %eax
f010509a:	e8 27 fb ff ff       	call   f0104bc6 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010509f:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01050a2:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01050a5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01050a8:	83 c4 10             	add    $0x10,%esp
}
f01050ab:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01050ae:	c9                   	leave  
f01050af:	c3                   	ret    
		return -E_INVAL;
f01050b0:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01050b5:	eb f4                	jmp    f01050ab <vsnprintf+0x53>

f01050b7 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01050b7:	55                   	push   %ebp
f01050b8:	89 e5                	mov    %esp,%ebp
f01050ba:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01050bd:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01050c0:	50                   	push   %eax
f01050c1:	ff 75 10             	pushl  0x10(%ebp)
f01050c4:	ff 75 0c             	pushl  0xc(%ebp)
f01050c7:	ff 75 08             	pushl  0x8(%ebp)
f01050ca:	e8 89 ff ff ff       	call   f0105058 <vsnprintf>
	va_end(ap);

	return rc;
}
f01050cf:	c9                   	leave  
f01050d0:	c3                   	ret    

f01050d1 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01050d1:	55                   	push   %ebp
f01050d2:	89 e5                	mov    %esp,%ebp
f01050d4:	57                   	push   %edi
f01050d5:	56                   	push   %esi
f01050d6:	53                   	push   %ebx
f01050d7:	83 ec 1c             	sub    $0x1c,%esp
f01050da:	e8 88 b0 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01050df:	81 c3 41 7f 08 00    	add    $0x87f41,%ebx
f01050e5:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01050e8:	85 c0                	test   %eax,%eax
f01050ea:	74 13                	je     f01050ff <readline+0x2e>
		cprintf("%s", prompt);
f01050ec:	83 ec 08             	sub    $0x8,%esp
f01050ef:	50                   	push   %eax
f01050f0:	8d 83 ae 8c f7 ff    	lea    -0x87352(%ebx),%eax
f01050f6:	50                   	push   %eax
f01050f7:	e8 c2 eb ff ff       	call   f0103cbe <cprintf>
f01050fc:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f01050ff:	83 ec 0c             	sub    $0xc,%esp
f0105102:	6a 00                	push   $0x0
f0105104:	e8 f6 b5 ff ff       	call   f01006ff <iscons>
f0105109:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010510c:	83 c4 10             	add    $0x10,%esp
	i = 0;
f010510f:	bf 00 00 00 00       	mov    $0x0,%edi
f0105114:	eb 46                	jmp    f010515c <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0105116:	83 ec 08             	sub    $0x8,%esp
f0105119:	50                   	push   %eax
f010511a:	8d 83 20 9e f7 ff    	lea    -0x861e0(%ebx),%eax
f0105120:	50                   	push   %eax
f0105121:	e8 98 eb ff ff       	call   f0103cbe <cprintf>
			return NULL;
f0105126:	83 c4 10             	add    $0x10,%esp
f0105129:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f010512e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105131:	5b                   	pop    %ebx
f0105132:	5e                   	pop    %esi
f0105133:	5f                   	pop    %edi
f0105134:	5d                   	pop    %ebp
f0105135:	c3                   	ret    
			if (echoing)
f0105136:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010513a:	75 05                	jne    f0105141 <readline+0x70>
			i--;
f010513c:	83 ef 01             	sub    $0x1,%edi
f010513f:	eb 1b                	jmp    f010515c <readline+0x8b>
				cputchar('\b');
f0105141:	83 ec 0c             	sub    $0xc,%esp
f0105144:	6a 08                	push   $0x8
f0105146:	e8 93 b5 ff ff       	call   f01006de <cputchar>
f010514b:	83 c4 10             	add    $0x10,%esp
f010514e:	eb ec                	jmp    f010513c <readline+0x6b>
			buf[i++] = c;
f0105150:	89 f0                	mov    %esi,%eax
f0105152:	88 84 3b e0 2b 00 00 	mov    %al,0x2be0(%ebx,%edi,1)
f0105159:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f010515c:	e8 8d b5 ff ff       	call   f01006ee <getchar>
f0105161:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0105163:	85 c0                	test   %eax,%eax
f0105165:	78 af                	js     f0105116 <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0105167:	83 f8 08             	cmp    $0x8,%eax
f010516a:	0f 94 c2             	sete   %dl
f010516d:	83 f8 7f             	cmp    $0x7f,%eax
f0105170:	0f 94 c0             	sete   %al
f0105173:	08 c2                	or     %al,%dl
f0105175:	74 04                	je     f010517b <readline+0xaa>
f0105177:	85 ff                	test   %edi,%edi
f0105179:	7f bb                	jg     f0105136 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f010517b:	83 fe 1f             	cmp    $0x1f,%esi
f010517e:	7e 1c                	jle    f010519c <readline+0xcb>
f0105180:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0105186:	7f 14                	jg     f010519c <readline+0xcb>
			if (echoing)
f0105188:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010518c:	74 c2                	je     f0105150 <readline+0x7f>
				cputchar(c);
f010518e:	83 ec 0c             	sub    $0xc,%esp
f0105191:	56                   	push   %esi
f0105192:	e8 47 b5 ff ff       	call   f01006de <cputchar>
f0105197:	83 c4 10             	add    $0x10,%esp
f010519a:	eb b4                	jmp    f0105150 <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f010519c:	83 fe 0a             	cmp    $0xa,%esi
f010519f:	74 05                	je     f01051a6 <readline+0xd5>
f01051a1:	83 fe 0d             	cmp    $0xd,%esi
f01051a4:	75 b6                	jne    f010515c <readline+0x8b>
			if (echoing)
f01051a6:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01051aa:	75 13                	jne    f01051bf <readline+0xee>
			buf[i] = 0;
f01051ac:	c6 84 3b e0 2b 00 00 	movb   $0x0,0x2be0(%ebx,%edi,1)
f01051b3:	00 
			return buf;
f01051b4:	8d 83 e0 2b 00 00    	lea    0x2be0(%ebx),%eax
f01051ba:	e9 6f ff ff ff       	jmp    f010512e <readline+0x5d>
				cputchar('\n');
f01051bf:	83 ec 0c             	sub    $0xc,%esp
f01051c2:	6a 0a                	push   $0xa
f01051c4:	e8 15 b5 ff ff       	call   f01006de <cputchar>
f01051c9:	83 c4 10             	add    $0x10,%esp
f01051cc:	eb de                	jmp    f01051ac <readline+0xdb>

f01051ce <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01051ce:	55                   	push   %ebp
f01051cf:	89 e5                	mov    %esp,%ebp
f01051d1:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01051d4:	b8 00 00 00 00       	mov    $0x0,%eax
f01051d9:	eb 03                	jmp    f01051de <strlen+0x10>
		n++;
f01051db:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f01051de:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01051e2:	75 f7                	jne    f01051db <strlen+0xd>
	return n;
}
f01051e4:	5d                   	pop    %ebp
f01051e5:	c3                   	ret    

f01051e6 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01051e6:	55                   	push   %ebp
f01051e7:	89 e5                	mov    %esp,%ebp
f01051e9:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01051ec:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01051ef:	b8 00 00 00 00       	mov    $0x0,%eax
f01051f4:	eb 03                	jmp    f01051f9 <strnlen+0x13>
		n++;
f01051f6:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01051f9:	39 d0                	cmp    %edx,%eax
f01051fb:	74 06                	je     f0105203 <strnlen+0x1d>
f01051fd:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0105201:	75 f3                	jne    f01051f6 <strnlen+0x10>
	return n;
}
f0105203:	5d                   	pop    %ebp
f0105204:	c3                   	ret    

f0105205 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0105205:	55                   	push   %ebp
f0105206:	89 e5                	mov    %esp,%ebp
f0105208:	53                   	push   %ebx
f0105209:	8b 45 08             	mov    0x8(%ebp),%eax
f010520c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f010520f:	89 c2                	mov    %eax,%edx
f0105211:	83 c1 01             	add    $0x1,%ecx
f0105214:	83 c2 01             	add    $0x1,%edx
f0105217:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010521b:	88 5a ff             	mov    %bl,-0x1(%edx)
f010521e:	84 db                	test   %bl,%bl
f0105220:	75 ef                	jne    f0105211 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0105222:	5b                   	pop    %ebx
f0105223:	5d                   	pop    %ebp
f0105224:	c3                   	ret    

f0105225 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0105225:	55                   	push   %ebp
f0105226:	89 e5                	mov    %esp,%ebp
f0105228:	53                   	push   %ebx
f0105229:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f010522c:	53                   	push   %ebx
f010522d:	e8 9c ff ff ff       	call   f01051ce <strlen>
f0105232:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0105235:	ff 75 0c             	pushl  0xc(%ebp)
f0105238:	01 d8                	add    %ebx,%eax
f010523a:	50                   	push   %eax
f010523b:	e8 c5 ff ff ff       	call   f0105205 <strcpy>
	return dst;
}
f0105240:	89 d8                	mov    %ebx,%eax
f0105242:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0105245:	c9                   	leave  
f0105246:	c3                   	ret    

f0105247 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0105247:	55                   	push   %ebp
f0105248:	89 e5                	mov    %esp,%ebp
f010524a:	56                   	push   %esi
f010524b:	53                   	push   %ebx
f010524c:	8b 75 08             	mov    0x8(%ebp),%esi
f010524f:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105252:	89 f3                	mov    %esi,%ebx
f0105254:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105257:	89 f2                	mov    %esi,%edx
f0105259:	eb 0f                	jmp    f010526a <strncpy+0x23>
		*dst++ = *src;
f010525b:	83 c2 01             	add    $0x1,%edx
f010525e:	0f b6 01             	movzbl (%ecx),%eax
f0105261:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0105264:	80 39 01             	cmpb   $0x1,(%ecx)
f0105267:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f010526a:	39 da                	cmp    %ebx,%edx
f010526c:	75 ed                	jne    f010525b <strncpy+0x14>
	}
	return ret;
}
f010526e:	89 f0                	mov    %esi,%eax
f0105270:	5b                   	pop    %ebx
f0105271:	5e                   	pop    %esi
f0105272:	5d                   	pop    %ebp
f0105273:	c3                   	ret    

f0105274 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0105274:	55                   	push   %ebp
f0105275:	89 e5                	mov    %esp,%ebp
f0105277:	56                   	push   %esi
f0105278:	53                   	push   %ebx
f0105279:	8b 75 08             	mov    0x8(%ebp),%esi
f010527c:	8b 55 0c             	mov    0xc(%ebp),%edx
f010527f:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0105282:	89 f0                	mov    %esi,%eax
f0105284:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0105288:	85 c9                	test   %ecx,%ecx
f010528a:	75 0b                	jne    f0105297 <strlcpy+0x23>
f010528c:	eb 17                	jmp    f01052a5 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010528e:	83 c2 01             	add    $0x1,%edx
f0105291:	83 c0 01             	add    $0x1,%eax
f0105294:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0105297:	39 d8                	cmp    %ebx,%eax
f0105299:	74 07                	je     f01052a2 <strlcpy+0x2e>
f010529b:	0f b6 0a             	movzbl (%edx),%ecx
f010529e:	84 c9                	test   %cl,%cl
f01052a0:	75 ec                	jne    f010528e <strlcpy+0x1a>
		*dst = '\0';
f01052a2:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01052a5:	29 f0                	sub    %esi,%eax
}
f01052a7:	5b                   	pop    %ebx
f01052a8:	5e                   	pop    %esi
f01052a9:	5d                   	pop    %ebp
f01052aa:	c3                   	ret    

f01052ab <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01052ab:	55                   	push   %ebp
f01052ac:	89 e5                	mov    %esp,%ebp
f01052ae:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01052b1:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01052b4:	eb 06                	jmp    f01052bc <strcmp+0x11>
		p++, q++;
f01052b6:	83 c1 01             	add    $0x1,%ecx
f01052b9:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f01052bc:	0f b6 01             	movzbl (%ecx),%eax
f01052bf:	84 c0                	test   %al,%al
f01052c1:	74 04                	je     f01052c7 <strcmp+0x1c>
f01052c3:	3a 02                	cmp    (%edx),%al
f01052c5:	74 ef                	je     f01052b6 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01052c7:	0f b6 c0             	movzbl %al,%eax
f01052ca:	0f b6 12             	movzbl (%edx),%edx
f01052cd:	29 d0                	sub    %edx,%eax
}
f01052cf:	5d                   	pop    %ebp
f01052d0:	c3                   	ret    

f01052d1 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01052d1:	55                   	push   %ebp
f01052d2:	89 e5                	mov    %esp,%ebp
f01052d4:	53                   	push   %ebx
f01052d5:	8b 45 08             	mov    0x8(%ebp),%eax
f01052d8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01052db:	89 c3                	mov    %eax,%ebx
f01052dd:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01052e0:	eb 06                	jmp    f01052e8 <strncmp+0x17>
		n--, p++, q++;
f01052e2:	83 c0 01             	add    $0x1,%eax
f01052e5:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f01052e8:	39 d8                	cmp    %ebx,%eax
f01052ea:	74 16                	je     f0105302 <strncmp+0x31>
f01052ec:	0f b6 08             	movzbl (%eax),%ecx
f01052ef:	84 c9                	test   %cl,%cl
f01052f1:	74 04                	je     f01052f7 <strncmp+0x26>
f01052f3:	3a 0a                	cmp    (%edx),%cl
f01052f5:	74 eb                	je     f01052e2 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01052f7:	0f b6 00             	movzbl (%eax),%eax
f01052fa:	0f b6 12             	movzbl (%edx),%edx
f01052fd:	29 d0                	sub    %edx,%eax
}
f01052ff:	5b                   	pop    %ebx
f0105300:	5d                   	pop    %ebp
f0105301:	c3                   	ret    
		return 0;
f0105302:	b8 00 00 00 00       	mov    $0x0,%eax
f0105307:	eb f6                	jmp    f01052ff <strncmp+0x2e>

f0105309 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0105309:	55                   	push   %ebp
f010530a:	89 e5                	mov    %esp,%ebp
f010530c:	8b 45 08             	mov    0x8(%ebp),%eax
f010530f:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105313:	0f b6 10             	movzbl (%eax),%edx
f0105316:	84 d2                	test   %dl,%dl
f0105318:	74 09                	je     f0105323 <strchr+0x1a>
		if (*s == c)
f010531a:	38 ca                	cmp    %cl,%dl
f010531c:	74 0a                	je     f0105328 <strchr+0x1f>
	for (; *s; s++)
f010531e:	83 c0 01             	add    $0x1,%eax
f0105321:	eb f0                	jmp    f0105313 <strchr+0xa>
			return (char *) s;
	return 0;
f0105323:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105328:	5d                   	pop    %ebp
f0105329:	c3                   	ret    

f010532a <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010532a:	55                   	push   %ebp
f010532b:	89 e5                	mov    %esp,%ebp
f010532d:	8b 45 08             	mov    0x8(%ebp),%eax
f0105330:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105334:	eb 03                	jmp    f0105339 <strfind+0xf>
f0105336:	83 c0 01             	add    $0x1,%eax
f0105339:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010533c:	38 ca                	cmp    %cl,%dl
f010533e:	74 04                	je     f0105344 <strfind+0x1a>
f0105340:	84 d2                	test   %dl,%dl
f0105342:	75 f2                	jne    f0105336 <strfind+0xc>
			break;
	return (char *) s;
}
f0105344:	5d                   	pop    %ebp
f0105345:	c3                   	ret    

f0105346 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0105346:	55                   	push   %ebp
f0105347:	89 e5                	mov    %esp,%ebp
f0105349:	57                   	push   %edi
f010534a:	56                   	push   %esi
f010534b:	53                   	push   %ebx
f010534c:	8b 7d 08             	mov    0x8(%ebp),%edi
f010534f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0105352:	85 c9                	test   %ecx,%ecx
f0105354:	74 13                	je     f0105369 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0105356:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010535c:	75 05                	jne    f0105363 <memset+0x1d>
f010535e:	f6 c1 03             	test   $0x3,%cl
f0105361:	74 0d                	je     f0105370 <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0105363:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105366:	fc                   	cld    
f0105367:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0105369:	89 f8                	mov    %edi,%eax
f010536b:	5b                   	pop    %ebx
f010536c:	5e                   	pop    %esi
f010536d:	5f                   	pop    %edi
f010536e:	5d                   	pop    %ebp
f010536f:	c3                   	ret    
		c &= 0xFF;
f0105370:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0105374:	89 d3                	mov    %edx,%ebx
f0105376:	c1 e3 08             	shl    $0x8,%ebx
f0105379:	89 d0                	mov    %edx,%eax
f010537b:	c1 e0 18             	shl    $0x18,%eax
f010537e:	89 d6                	mov    %edx,%esi
f0105380:	c1 e6 10             	shl    $0x10,%esi
f0105383:	09 f0                	or     %esi,%eax
f0105385:	09 c2                	or     %eax,%edx
f0105387:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f0105389:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f010538c:	89 d0                	mov    %edx,%eax
f010538e:	fc                   	cld    
f010538f:	f3 ab                	rep stos %eax,%es:(%edi)
f0105391:	eb d6                	jmp    f0105369 <memset+0x23>

f0105393 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0105393:	55                   	push   %ebp
f0105394:	89 e5                	mov    %esp,%ebp
f0105396:	57                   	push   %edi
f0105397:	56                   	push   %esi
f0105398:	8b 45 08             	mov    0x8(%ebp),%eax
f010539b:	8b 75 0c             	mov    0xc(%ebp),%esi
f010539e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01053a1:	39 c6                	cmp    %eax,%esi
f01053a3:	73 35                	jae    f01053da <memmove+0x47>
f01053a5:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01053a8:	39 c2                	cmp    %eax,%edx
f01053aa:	76 2e                	jbe    f01053da <memmove+0x47>
		s += n;
		d += n;
f01053ac:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01053af:	89 d6                	mov    %edx,%esi
f01053b1:	09 fe                	or     %edi,%esi
f01053b3:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01053b9:	74 0c                	je     f01053c7 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01053bb:	83 ef 01             	sub    $0x1,%edi
f01053be:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f01053c1:	fd                   	std    
f01053c2:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01053c4:	fc                   	cld    
f01053c5:	eb 21                	jmp    f01053e8 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01053c7:	f6 c1 03             	test   $0x3,%cl
f01053ca:	75 ef                	jne    f01053bb <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01053cc:	83 ef 04             	sub    $0x4,%edi
f01053cf:	8d 72 fc             	lea    -0x4(%edx),%esi
f01053d2:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f01053d5:	fd                   	std    
f01053d6:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01053d8:	eb ea                	jmp    f01053c4 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01053da:	89 f2                	mov    %esi,%edx
f01053dc:	09 c2                	or     %eax,%edx
f01053de:	f6 c2 03             	test   $0x3,%dl
f01053e1:	74 09                	je     f01053ec <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01053e3:	89 c7                	mov    %eax,%edi
f01053e5:	fc                   	cld    
f01053e6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01053e8:	5e                   	pop    %esi
f01053e9:	5f                   	pop    %edi
f01053ea:	5d                   	pop    %ebp
f01053eb:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01053ec:	f6 c1 03             	test   $0x3,%cl
f01053ef:	75 f2                	jne    f01053e3 <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01053f1:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f01053f4:	89 c7                	mov    %eax,%edi
f01053f6:	fc                   	cld    
f01053f7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01053f9:	eb ed                	jmp    f01053e8 <memmove+0x55>

f01053fb <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01053fb:	55                   	push   %ebp
f01053fc:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01053fe:	ff 75 10             	pushl  0x10(%ebp)
f0105401:	ff 75 0c             	pushl  0xc(%ebp)
f0105404:	ff 75 08             	pushl  0x8(%ebp)
f0105407:	e8 87 ff ff ff       	call   f0105393 <memmove>
}
f010540c:	c9                   	leave  
f010540d:	c3                   	ret    

f010540e <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010540e:	55                   	push   %ebp
f010540f:	89 e5                	mov    %esp,%ebp
f0105411:	56                   	push   %esi
f0105412:	53                   	push   %ebx
f0105413:	8b 45 08             	mov    0x8(%ebp),%eax
f0105416:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105419:	89 c6                	mov    %eax,%esi
f010541b:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010541e:	39 f0                	cmp    %esi,%eax
f0105420:	74 1c                	je     f010543e <memcmp+0x30>
		if (*s1 != *s2)
f0105422:	0f b6 08             	movzbl (%eax),%ecx
f0105425:	0f b6 1a             	movzbl (%edx),%ebx
f0105428:	38 d9                	cmp    %bl,%cl
f010542a:	75 08                	jne    f0105434 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f010542c:	83 c0 01             	add    $0x1,%eax
f010542f:	83 c2 01             	add    $0x1,%edx
f0105432:	eb ea                	jmp    f010541e <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0105434:	0f b6 c1             	movzbl %cl,%eax
f0105437:	0f b6 db             	movzbl %bl,%ebx
f010543a:	29 d8                	sub    %ebx,%eax
f010543c:	eb 05                	jmp    f0105443 <memcmp+0x35>
	}

	return 0;
f010543e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105443:	5b                   	pop    %ebx
f0105444:	5e                   	pop    %esi
f0105445:	5d                   	pop    %ebp
f0105446:	c3                   	ret    

f0105447 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0105447:	55                   	push   %ebp
f0105448:	89 e5                	mov    %esp,%ebp
f010544a:	8b 45 08             	mov    0x8(%ebp),%eax
f010544d:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f0105450:	89 c2                	mov    %eax,%edx
f0105452:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0105455:	39 d0                	cmp    %edx,%eax
f0105457:	73 09                	jae    f0105462 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f0105459:	38 08                	cmp    %cl,(%eax)
f010545b:	74 05                	je     f0105462 <memfind+0x1b>
	for (; s < ends; s++)
f010545d:	83 c0 01             	add    $0x1,%eax
f0105460:	eb f3                	jmp    f0105455 <memfind+0xe>
			break;
	return (void *) s;
}
f0105462:	5d                   	pop    %ebp
f0105463:	c3                   	ret    

f0105464 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0105464:	55                   	push   %ebp
f0105465:	89 e5                	mov    %esp,%ebp
f0105467:	57                   	push   %edi
f0105468:	56                   	push   %esi
f0105469:	53                   	push   %ebx
f010546a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010546d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105470:	eb 03                	jmp    f0105475 <strtol+0x11>
		s++;
f0105472:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f0105475:	0f b6 01             	movzbl (%ecx),%eax
f0105478:	3c 20                	cmp    $0x20,%al
f010547a:	74 f6                	je     f0105472 <strtol+0xe>
f010547c:	3c 09                	cmp    $0x9,%al
f010547e:	74 f2                	je     f0105472 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f0105480:	3c 2b                	cmp    $0x2b,%al
f0105482:	74 2e                	je     f01054b2 <strtol+0x4e>
	int neg = 0;
f0105484:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f0105489:	3c 2d                	cmp    $0x2d,%al
f010548b:	74 2f                	je     f01054bc <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010548d:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0105493:	75 05                	jne    f010549a <strtol+0x36>
f0105495:	80 39 30             	cmpb   $0x30,(%ecx)
f0105498:	74 2c                	je     f01054c6 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f010549a:	85 db                	test   %ebx,%ebx
f010549c:	75 0a                	jne    f01054a8 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010549e:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f01054a3:	80 39 30             	cmpb   $0x30,(%ecx)
f01054a6:	74 28                	je     f01054d0 <strtol+0x6c>
		base = 10;
f01054a8:	b8 00 00 00 00       	mov    $0x0,%eax
f01054ad:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01054b0:	eb 50                	jmp    f0105502 <strtol+0x9e>
		s++;
f01054b2:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f01054b5:	bf 00 00 00 00       	mov    $0x0,%edi
f01054ba:	eb d1                	jmp    f010548d <strtol+0x29>
		s++, neg = 1;
f01054bc:	83 c1 01             	add    $0x1,%ecx
f01054bf:	bf 01 00 00 00       	mov    $0x1,%edi
f01054c4:	eb c7                	jmp    f010548d <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01054c6:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f01054ca:	74 0e                	je     f01054da <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f01054cc:	85 db                	test   %ebx,%ebx
f01054ce:	75 d8                	jne    f01054a8 <strtol+0x44>
		s++, base = 8;
f01054d0:	83 c1 01             	add    $0x1,%ecx
f01054d3:	bb 08 00 00 00       	mov    $0x8,%ebx
f01054d8:	eb ce                	jmp    f01054a8 <strtol+0x44>
		s += 2, base = 16;
f01054da:	83 c1 02             	add    $0x2,%ecx
f01054dd:	bb 10 00 00 00       	mov    $0x10,%ebx
f01054e2:	eb c4                	jmp    f01054a8 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f01054e4:	8d 72 9f             	lea    -0x61(%edx),%esi
f01054e7:	89 f3                	mov    %esi,%ebx
f01054e9:	80 fb 19             	cmp    $0x19,%bl
f01054ec:	77 29                	ja     f0105517 <strtol+0xb3>
			dig = *s - 'a' + 10;
f01054ee:	0f be d2             	movsbl %dl,%edx
f01054f1:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01054f4:	3b 55 10             	cmp    0x10(%ebp),%edx
f01054f7:	7d 30                	jge    f0105529 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f01054f9:	83 c1 01             	add    $0x1,%ecx
f01054fc:	0f af 45 10          	imul   0x10(%ebp),%eax
f0105500:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0105502:	0f b6 11             	movzbl (%ecx),%edx
f0105505:	8d 72 d0             	lea    -0x30(%edx),%esi
f0105508:	89 f3                	mov    %esi,%ebx
f010550a:	80 fb 09             	cmp    $0x9,%bl
f010550d:	77 d5                	ja     f01054e4 <strtol+0x80>
			dig = *s - '0';
f010550f:	0f be d2             	movsbl %dl,%edx
f0105512:	83 ea 30             	sub    $0x30,%edx
f0105515:	eb dd                	jmp    f01054f4 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0105517:	8d 72 bf             	lea    -0x41(%edx),%esi
f010551a:	89 f3                	mov    %esi,%ebx
f010551c:	80 fb 19             	cmp    $0x19,%bl
f010551f:	77 08                	ja     f0105529 <strtol+0xc5>
			dig = *s - 'A' + 10;
f0105521:	0f be d2             	movsbl %dl,%edx
f0105524:	83 ea 37             	sub    $0x37,%edx
f0105527:	eb cb                	jmp    f01054f4 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0105529:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010552d:	74 05                	je     f0105534 <strtol+0xd0>
		*endptr = (char *) s;
f010552f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105532:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0105534:	89 c2                	mov    %eax,%edx
f0105536:	f7 da                	neg    %edx
f0105538:	85 ff                	test   %edi,%edi
f010553a:	0f 45 c2             	cmovne %edx,%eax
}
f010553d:	5b                   	pop    %ebx
f010553e:	5e                   	pop    %esi
f010553f:	5f                   	pop    %edi
f0105540:	5d                   	pop    %ebp
f0105541:	c3                   	ret    
f0105542:	66 90                	xchg   %ax,%ax
f0105544:	66 90                	xchg   %ax,%ax
f0105546:	66 90                	xchg   %ax,%ax
f0105548:	66 90                	xchg   %ax,%ax
f010554a:	66 90                	xchg   %ax,%ax
f010554c:	66 90                	xchg   %ax,%ax
f010554e:	66 90                	xchg   %ax,%ax

f0105550 <__udivdi3>:
f0105550:	55                   	push   %ebp
f0105551:	57                   	push   %edi
f0105552:	56                   	push   %esi
f0105553:	53                   	push   %ebx
f0105554:	83 ec 1c             	sub    $0x1c,%esp
f0105557:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f010555b:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f010555f:	8b 74 24 34          	mov    0x34(%esp),%esi
f0105563:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f0105567:	85 d2                	test   %edx,%edx
f0105569:	75 35                	jne    f01055a0 <__udivdi3+0x50>
f010556b:	39 f3                	cmp    %esi,%ebx
f010556d:	0f 87 bd 00 00 00    	ja     f0105630 <__udivdi3+0xe0>
f0105573:	85 db                	test   %ebx,%ebx
f0105575:	89 d9                	mov    %ebx,%ecx
f0105577:	75 0b                	jne    f0105584 <__udivdi3+0x34>
f0105579:	b8 01 00 00 00       	mov    $0x1,%eax
f010557e:	31 d2                	xor    %edx,%edx
f0105580:	f7 f3                	div    %ebx
f0105582:	89 c1                	mov    %eax,%ecx
f0105584:	31 d2                	xor    %edx,%edx
f0105586:	89 f0                	mov    %esi,%eax
f0105588:	f7 f1                	div    %ecx
f010558a:	89 c6                	mov    %eax,%esi
f010558c:	89 e8                	mov    %ebp,%eax
f010558e:	89 f7                	mov    %esi,%edi
f0105590:	f7 f1                	div    %ecx
f0105592:	89 fa                	mov    %edi,%edx
f0105594:	83 c4 1c             	add    $0x1c,%esp
f0105597:	5b                   	pop    %ebx
f0105598:	5e                   	pop    %esi
f0105599:	5f                   	pop    %edi
f010559a:	5d                   	pop    %ebp
f010559b:	c3                   	ret    
f010559c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01055a0:	39 f2                	cmp    %esi,%edx
f01055a2:	77 7c                	ja     f0105620 <__udivdi3+0xd0>
f01055a4:	0f bd fa             	bsr    %edx,%edi
f01055a7:	83 f7 1f             	xor    $0x1f,%edi
f01055aa:	0f 84 98 00 00 00    	je     f0105648 <__udivdi3+0xf8>
f01055b0:	89 f9                	mov    %edi,%ecx
f01055b2:	b8 20 00 00 00       	mov    $0x20,%eax
f01055b7:	29 f8                	sub    %edi,%eax
f01055b9:	d3 e2                	shl    %cl,%edx
f01055bb:	89 54 24 08          	mov    %edx,0x8(%esp)
f01055bf:	89 c1                	mov    %eax,%ecx
f01055c1:	89 da                	mov    %ebx,%edx
f01055c3:	d3 ea                	shr    %cl,%edx
f01055c5:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f01055c9:	09 d1                	or     %edx,%ecx
f01055cb:	89 f2                	mov    %esi,%edx
f01055cd:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01055d1:	89 f9                	mov    %edi,%ecx
f01055d3:	d3 e3                	shl    %cl,%ebx
f01055d5:	89 c1                	mov    %eax,%ecx
f01055d7:	d3 ea                	shr    %cl,%edx
f01055d9:	89 f9                	mov    %edi,%ecx
f01055db:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01055df:	d3 e6                	shl    %cl,%esi
f01055e1:	89 eb                	mov    %ebp,%ebx
f01055e3:	89 c1                	mov    %eax,%ecx
f01055e5:	d3 eb                	shr    %cl,%ebx
f01055e7:	09 de                	or     %ebx,%esi
f01055e9:	89 f0                	mov    %esi,%eax
f01055eb:	f7 74 24 08          	divl   0x8(%esp)
f01055ef:	89 d6                	mov    %edx,%esi
f01055f1:	89 c3                	mov    %eax,%ebx
f01055f3:	f7 64 24 0c          	mull   0xc(%esp)
f01055f7:	39 d6                	cmp    %edx,%esi
f01055f9:	72 0c                	jb     f0105607 <__udivdi3+0xb7>
f01055fb:	89 f9                	mov    %edi,%ecx
f01055fd:	d3 e5                	shl    %cl,%ebp
f01055ff:	39 c5                	cmp    %eax,%ebp
f0105601:	73 5d                	jae    f0105660 <__udivdi3+0x110>
f0105603:	39 d6                	cmp    %edx,%esi
f0105605:	75 59                	jne    f0105660 <__udivdi3+0x110>
f0105607:	8d 43 ff             	lea    -0x1(%ebx),%eax
f010560a:	31 ff                	xor    %edi,%edi
f010560c:	89 fa                	mov    %edi,%edx
f010560e:	83 c4 1c             	add    $0x1c,%esp
f0105611:	5b                   	pop    %ebx
f0105612:	5e                   	pop    %esi
f0105613:	5f                   	pop    %edi
f0105614:	5d                   	pop    %ebp
f0105615:	c3                   	ret    
f0105616:	8d 76 00             	lea    0x0(%esi),%esi
f0105619:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0105620:	31 ff                	xor    %edi,%edi
f0105622:	31 c0                	xor    %eax,%eax
f0105624:	89 fa                	mov    %edi,%edx
f0105626:	83 c4 1c             	add    $0x1c,%esp
f0105629:	5b                   	pop    %ebx
f010562a:	5e                   	pop    %esi
f010562b:	5f                   	pop    %edi
f010562c:	5d                   	pop    %ebp
f010562d:	c3                   	ret    
f010562e:	66 90                	xchg   %ax,%ax
f0105630:	31 ff                	xor    %edi,%edi
f0105632:	89 e8                	mov    %ebp,%eax
f0105634:	89 f2                	mov    %esi,%edx
f0105636:	f7 f3                	div    %ebx
f0105638:	89 fa                	mov    %edi,%edx
f010563a:	83 c4 1c             	add    $0x1c,%esp
f010563d:	5b                   	pop    %ebx
f010563e:	5e                   	pop    %esi
f010563f:	5f                   	pop    %edi
f0105640:	5d                   	pop    %ebp
f0105641:	c3                   	ret    
f0105642:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105648:	39 f2                	cmp    %esi,%edx
f010564a:	72 06                	jb     f0105652 <__udivdi3+0x102>
f010564c:	31 c0                	xor    %eax,%eax
f010564e:	39 eb                	cmp    %ebp,%ebx
f0105650:	77 d2                	ja     f0105624 <__udivdi3+0xd4>
f0105652:	b8 01 00 00 00       	mov    $0x1,%eax
f0105657:	eb cb                	jmp    f0105624 <__udivdi3+0xd4>
f0105659:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105660:	89 d8                	mov    %ebx,%eax
f0105662:	31 ff                	xor    %edi,%edi
f0105664:	eb be                	jmp    f0105624 <__udivdi3+0xd4>
f0105666:	66 90                	xchg   %ax,%ax
f0105668:	66 90                	xchg   %ax,%ax
f010566a:	66 90                	xchg   %ax,%ax
f010566c:	66 90                	xchg   %ax,%ax
f010566e:	66 90                	xchg   %ax,%ax

f0105670 <__umoddi3>:
f0105670:	55                   	push   %ebp
f0105671:	57                   	push   %edi
f0105672:	56                   	push   %esi
f0105673:	53                   	push   %ebx
f0105674:	83 ec 1c             	sub    $0x1c,%esp
f0105677:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f010567b:	8b 74 24 30          	mov    0x30(%esp),%esi
f010567f:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f0105683:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105687:	85 ed                	test   %ebp,%ebp
f0105689:	89 f0                	mov    %esi,%eax
f010568b:	89 da                	mov    %ebx,%edx
f010568d:	75 19                	jne    f01056a8 <__umoddi3+0x38>
f010568f:	39 df                	cmp    %ebx,%edi
f0105691:	0f 86 b1 00 00 00    	jbe    f0105748 <__umoddi3+0xd8>
f0105697:	f7 f7                	div    %edi
f0105699:	89 d0                	mov    %edx,%eax
f010569b:	31 d2                	xor    %edx,%edx
f010569d:	83 c4 1c             	add    $0x1c,%esp
f01056a0:	5b                   	pop    %ebx
f01056a1:	5e                   	pop    %esi
f01056a2:	5f                   	pop    %edi
f01056a3:	5d                   	pop    %ebp
f01056a4:	c3                   	ret    
f01056a5:	8d 76 00             	lea    0x0(%esi),%esi
f01056a8:	39 dd                	cmp    %ebx,%ebp
f01056aa:	77 f1                	ja     f010569d <__umoddi3+0x2d>
f01056ac:	0f bd cd             	bsr    %ebp,%ecx
f01056af:	83 f1 1f             	xor    $0x1f,%ecx
f01056b2:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01056b6:	0f 84 b4 00 00 00    	je     f0105770 <__umoddi3+0x100>
f01056bc:	b8 20 00 00 00       	mov    $0x20,%eax
f01056c1:	89 c2                	mov    %eax,%edx
f01056c3:	8b 44 24 04          	mov    0x4(%esp),%eax
f01056c7:	29 c2                	sub    %eax,%edx
f01056c9:	89 c1                	mov    %eax,%ecx
f01056cb:	89 f8                	mov    %edi,%eax
f01056cd:	d3 e5                	shl    %cl,%ebp
f01056cf:	89 d1                	mov    %edx,%ecx
f01056d1:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01056d5:	d3 e8                	shr    %cl,%eax
f01056d7:	09 c5                	or     %eax,%ebp
f01056d9:	8b 44 24 04          	mov    0x4(%esp),%eax
f01056dd:	89 c1                	mov    %eax,%ecx
f01056df:	d3 e7                	shl    %cl,%edi
f01056e1:	89 d1                	mov    %edx,%ecx
f01056e3:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01056e7:	89 df                	mov    %ebx,%edi
f01056e9:	d3 ef                	shr    %cl,%edi
f01056eb:	89 c1                	mov    %eax,%ecx
f01056ed:	89 f0                	mov    %esi,%eax
f01056ef:	d3 e3                	shl    %cl,%ebx
f01056f1:	89 d1                	mov    %edx,%ecx
f01056f3:	89 fa                	mov    %edi,%edx
f01056f5:	d3 e8                	shr    %cl,%eax
f01056f7:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01056fc:	09 d8                	or     %ebx,%eax
f01056fe:	f7 f5                	div    %ebp
f0105700:	d3 e6                	shl    %cl,%esi
f0105702:	89 d1                	mov    %edx,%ecx
f0105704:	f7 64 24 08          	mull   0x8(%esp)
f0105708:	39 d1                	cmp    %edx,%ecx
f010570a:	89 c3                	mov    %eax,%ebx
f010570c:	89 d7                	mov    %edx,%edi
f010570e:	72 06                	jb     f0105716 <__umoddi3+0xa6>
f0105710:	75 0e                	jne    f0105720 <__umoddi3+0xb0>
f0105712:	39 c6                	cmp    %eax,%esi
f0105714:	73 0a                	jae    f0105720 <__umoddi3+0xb0>
f0105716:	2b 44 24 08          	sub    0x8(%esp),%eax
f010571a:	19 ea                	sbb    %ebp,%edx
f010571c:	89 d7                	mov    %edx,%edi
f010571e:	89 c3                	mov    %eax,%ebx
f0105720:	89 ca                	mov    %ecx,%edx
f0105722:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0105727:	29 de                	sub    %ebx,%esi
f0105729:	19 fa                	sbb    %edi,%edx
f010572b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f010572f:	89 d0                	mov    %edx,%eax
f0105731:	d3 e0                	shl    %cl,%eax
f0105733:	89 d9                	mov    %ebx,%ecx
f0105735:	d3 ee                	shr    %cl,%esi
f0105737:	d3 ea                	shr    %cl,%edx
f0105739:	09 f0                	or     %esi,%eax
f010573b:	83 c4 1c             	add    $0x1c,%esp
f010573e:	5b                   	pop    %ebx
f010573f:	5e                   	pop    %esi
f0105740:	5f                   	pop    %edi
f0105741:	5d                   	pop    %ebp
f0105742:	c3                   	ret    
f0105743:	90                   	nop
f0105744:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105748:	85 ff                	test   %edi,%edi
f010574a:	89 f9                	mov    %edi,%ecx
f010574c:	75 0b                	jne    f0105759 <__umoddi3+0xe9>
f010574e:	b8 01 00 00 00       	mov    $0x1,%eax
f0105753:	31 d2                	xor    %edx,%edx
f0105755:	f7 f7                	div    %edi
f0105757:	89 c1                	mov    %eax,%ecx
f0105759:	89 d8                	mov    %ebx,%eax
f010575b:	31 d2                	xor    %edx,%edx
f010575d:	f7 f1                	div    %ecx
f010575f:	89 f0                	mov    %esi,%eax
f0105761:	f7 f1                	div    %ecx
f0105763:	e9 31 ff ff ff       	jmp    f0105699 <__umoddi3+0x29>
f0105768:	90                   	nop
f0105769:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105770:	39 dd                	cmp    %ebx,%ebp
f0105772:	72 08                	jb     f010577c <__umoddi3+0x10c>
f0105774:	39 f7                	cmp    %esi,%edi
f0105776:	0f 87 21 ff ff ff    	ja     f010569d <__umoddi3+0x2d>
f010577c:	89 da                	mov    %ebx,%edx
f010577e:	89 f0                	mov    %esi,%eax
f0105780:	29 f8                	sub    %edi,%eax
f0105782:	19 ea                	sbb    %ebp,%edx
f0105784:	e9 14 ff ff ff       	jmp    f010569d <__umoddi3+0x2d>
