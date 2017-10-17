
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
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 d0 11 00       	mov    $0x11d000,%eax
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
f0100034:	bc 00 d0 11 f0       	mov    $0xf011d000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 70 f9 11 f0       	mov    $0xf011f970,%eax
f010004b:	2d 00 f3 11 f0       	sub    $0xf011f300,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 00 f3 11 f0 	movl   $0xf011f300,(%esp)
f0100063:	e8 4e 37 00 00       	call   f01037b6 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 70 04 00 00       	call   f01004dd <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 00 3c 10 f0 	movl   $0xf0103c00,(%esp)
f010007c:	e8 c9 2c 00 00       	call   f0102d4a <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 73 10 00 00       	call   f01010f9 <mem_init>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 6c 06 00 00       	call   f01006fe <monitor>
f0100092:	eb f2                	jmp    f0100086 <i386_init+0x46>

f0100094 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	56                   	push   %esi
f0100098:	53                   	push   %ebx
f0100099:	83 ec 10             	sub    $0x10,%esp
f010009c:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010009f:	83 3d 60 f9 11 f0 00 	cmpl   $0x0,0xf011f960
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 60 f9 11 f0    	mov    %esi,0xf011f960

	// Be extra sure that the machine is in as reasonable state
	asm volatile("cli; cld");
f01000ae:	fa                   	cli    
f01000af:	fc                   	cld    

	va_start(ap, fmt);
f01000b0:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01000bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000c1:	c7 04 24 1b 3c 10 f0 	movl   $0xf0103c1b,(%esp)
f01000c8:	e8 7d 2c 00 00       	call   f0102d4a <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 3e 2c 00 00       	call   f0102d17 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 3c 4b 10 f0 	movl   $0xf0104b3c,(%esp)
f01000e0:	e8 65 2c 00 00       	call   f0102d4a <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 0d 06 00 00       	call   f01006fe <monitor>
f01000f1:	eb f2                	jmp    f01000e5 <_panic+0x51>

f01000f3 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f3:	55                   	push   %ebp
f01000f4:	89 e5                	mov    %esp,%ebp
f01000f6:	53                   	push   %ebx
f01000f7:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fa:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100100:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100104:	8b 45 08             	mov    0x8(%ebp),%eax
f0100107:	89 44 24 04          	mov    %eax,0x4(%esp)
f010010b:	c7 04 24 33 3c 10 f0 	movl   $0xf0103c33,(%esp)
f0100112:	e8 33 2c 00 00       	call   f0102d4a <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 f1 2b 00 00       	call   f0102d17 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 3c 4b 10 f0 	movl   $0xf0104b3c,(%esp)
f010012d:	e8 18 2c 00 00       	call   f0102d4a <cprintf>
	va_end(ap);
}
f0100132:	83 c4 14             	add    $0x14,%esp
f0100135:	5b                   	pop    %ebx
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    

f0100138 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100138:	55                   	push   %ebp
f0100139:	89 e5                	mov    %esp,%ebp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010013b:	ba 84 00 00 00       	mov    $0x84,%edx
f0100140:	ec                   	in     (%dx),%al
f0100141:	ec                   	in     (%dx),%al
f0100142:	ec                   	in     (%dx),%al
f0100143:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f0100144:	5d                   	pop    %ebp
f0100145:	c3                   	ret    

f0100146 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100146:	55                   	push   %ebp
f0100147:	89 e5                	mov    %esp,%ebp
f0100149:	ba fd 03 00 00       	mov    $0x3fd,%edx
f010014e:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010014f:	a8 01                	test   $0x1,%al
f0100151:	74 08                	je     f010015b <serial_proc_data+0x15>
f0100153:	b2 f8                	mov    $0xf8,%dl
f0100155:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100156:	0f b6 c0             	movzbl %al,%eax
f0100159:	eb 05                	jmp    f0100160 <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010015b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100160:	5d                   	pop    %ebp
f0100161:	c3                   	ret    

f0100162 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100162:	55                   	push   %ebp
f0100163:	89 e5                	mov    %esp,%ebp
f0100165:	53                   	push   %ebx
f0100166:	83 ec 04             	sub    $0x4,%esp
f0100169:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010016b:	eb 29                	jmp    f0100196 <cons_intr+0x34>
		if (c == 0)
f010016d:	85 c0                	test   %eax,%eax
f010016f:	74 25                	je     f0100196 <cons_intr+0x34>
			continue;
		cons.buf[cons.wpos++] = c;
f0100171:	8b 15 24 f5 11 f0    	mov    0xf011f524,%edx
f0100177:	88 82 20 f3 11 f0    	mov    %al,-0xfee0ce0(%edx)
f010017d:	8d 42 01             	lea    0x1(%edx),%eax
f0100180:	a3 24 f5 11 f0       	mov    %eax,0xf011f524
		if (cons.wpos == CONSBUFSIZE)
f0100185:	3d 00 02 00 00       	cmp    $0x200,%eax
f010018a:	75 0a                	jne    f0100196 <cons_intr+0x34>
			cons.wpos = 0;
f010018c:	c7 05 24 f5 11 f0 00 	movl   $0x0,0xf011f524
f0100193:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100196:	ff d3                	call   *%ebx
f0100198:	83 f8 ff             	cmp    $0xffffffff,%eax
f010019b:	75 d0                	jne    f010016d <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010019d:	83 c4 04             	add    $0x4,%esp
f01001a0:	5b                   	pop    %ebx
f01001a1:	5d                   	pop    %ebp
f01001a2:	c3                   	ret    

f01001a3 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01001a3:	55                   	push   %ebp
f01001a4:	89 e5                	mov    %esp,%ebp
f01001a6:	57                   	push   %edi
f01001a7:	56                   	push   %esi
f01001a8:	53                   	push   %ebx
f01001a9:	83 ec 2c             	sub    $0x2c,%esp
f01001ac:	89 c6                	mov    %eax,%esi
f01001ae:	bb 01 32 00 00       	mov    $0x3201,%ebx
f01001b3:	bf fd 03 00 00       	mov    $0x3fd,%edi
f01001b8:	eb 05                	jmp    f01001bf <cons_putc+0x1c>
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01001ba:	e8 79 ff ff ff       	call   f0100138 <delay>
f01001bf:	89 fa                	mov    %edi,%edx
f01001c1:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01001c2:	a8 20                	test   $0x20,%al
f01001c4:	75 03                	jne    f01001c9 <cons_putc+0x26>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01001c6:	4b                   	dec    %ebx
f01001c7:	75 f1                	jne    f01001ba <cons_putc+0x17>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01001c9:	89 f2                	mov    %esi,%edx
f01001cb:	89 f0                	mov    %esi,%eax
f01001cd:	88 55 e7             	mov    %dl,-0x19(%ebp)
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01001d0:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001d5:	ee                   	out    %al,(%dx)
f01001d6:	bb 01 32 00 00       	mov    $0x3201,%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001db:	bf 79 03 00 00       	mov    $0x379,%edi
f01001e0:	eb 05                	jmp    f01001e7 <cons_putc+0x44>
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
		delay();
f01001e2:	e8 51 ff ff ff       	call   f0100138 <delay>
f01001e7:	89 fa                	mov    %edi,%edx
f01001e9:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01001ea:	84 c0                	test   %al,%al
f01001ec:	78 03                	js     f01001f1 <cons_putc+0x4e>
f01001ee:	4b                   	dec    %ebx
f01001ef:	75 f1                	jne    f01001e2 <cons_putc+0x3f>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01001f1:	ba 78 03 00 00       	mov    $0x378,%edx
f01001f6:	8a 45 e7             	mov    -0x19(%ebp),%al
f01001f9:	ee                   	out    %al,(%dx)
f01001fa:	b2 7a                	mov    $0x7a,%dl
f01001fc:	b0 0d                	mov    $0xd,%al
f01001fe:	ee                   	out    %al,(%dx)
f01001ff:	b0 08                	mov    $0x8,%al
f0100201:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100202:	f7 c6 00 ff ff ff    	test   $0xffffff00,%esi
f0100208:	75 06                	jne    f0100210 <cons_putc+0x6d>
		c |= 0x0700;
f010020a:	81 ce 00 07 00 00    	or     $0x700,%esi

	switch (c & 0xff) {
f0100210:	89 f0                	mov    %esi,%eax
f0100212:	25 ff 00 00 00       	and    $0xff,%eax
f0100217:	83 f8 09             	cmp    $0x9,%eax
f010021a:	74 78                	je     f0100294 <cons_putc+0xf1>
f010021c:	83 f8 09             	cmp    $0x9,%eax
f010021f:	7f 0b                	jg     f010022c <cons_putc+0x89>
f0100221:	83 f8 08             	cmp    $0x8,%eax
f0100224:	0f 85 9e 00 00 00    	jne    f01002c8 <cons_putc+0x125>
f010022a:	eb 10                	jmp    f010023c <cons_putc+0x99>
f010022c:	83 f8 0a             	cmp    $0xa,%eax
f010022f:	74 39                	je     f010026a <cons_putc+0xc7>
f0100231:	83 f8 0d             	cmp    $0xd,%eax
f0100234:	0f 85 8e 00 00 00    	jne    f01002c8 <cons_putc+0x125>
f010023a:	eb 36                	jmp    f0100272 <cons_putc+0xcf>
	case '\b':
		if (crt_pos > 0) {
f010023c:	66 a1 34 f5 11 f0    	mov    0xf011f534,%ax
f0100242:	66 85 c0             	test   %ax,%ax
f0100245:	0f 84 e2 00 00 00    	je     f010032d <cons_putc+0x18a>
			crt_pos--;
f010024b:	48                   	dec    %eax
f010024c:	66 a3 34 f5 11 f0    	mov    %ax,0xf011f534
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100252:	0f b7 c0             	movzwl %ax,%eax
f0100255:	81 e6 00 ff ff ff    	and    $0xffffff00,%esi
f010025b:	83 ce 20             	or     $0x20,%esi
f010025e:	8b 15 30 f5 11 f0    	mov    0xf011f530,%edx
f0100264:	66 89 34 42          	mov    %si,(%edx,%eax,2)
f0100268:	eb 78                	jmp    f01002e2 <cons_putc+0x13f>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010026a:	66 83 05 34 f5 11 f0 	addw   $0x50,0xf011f534
f0100271:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100272:	66 8b 0d 34 f5 11 f0 	mov    0xf011f534,%cx
f0100279:	bb 50 00 00 00       	mov    $0x50,%ebx
f010027e:	89 c8                	mov    %ecx,%eax
f0100280:	ba 00 00 00 00       	mov    $0x0,%edx
f0100285:	66 f7 f3             	div    %bx
f0100288:	66 29 d1             	sub    %dx,%cx
f010028b:	66 89 0d 34 f5 11 f0 	mov    %cx,0xf011f534
f0100292:	eb 4e                	jmp    f01002e2 <cons_putc+0x13f>
		break;
	case '\t':
		cons_putc(' ');
f0100294:	b8 20 00 00 00       	mov    $0x20,%eax
f0100299:	e8 05 ff ff ff       	call   f01001a3 <cons_putc>
		cons_putc(' ');
f010029e:	b8 20 00 00 00       	mov    $0x20,%eax
f01002a3:	e8 fb fe ff ff       	call   f01001a3 <cons_putc>
		cons_putc(' ');
f01002a8:	b8 20 00 00 00       	mov    $0x20,%eax
f01002ad:	e8 f1 fe ff ff       	call   f01001a3 <cons_putc>
		cons_putc(' ');
f01002b2:	b8 20 00 00 00       	mov    $0x20,%eax
f01002b7:	e8 e7 fe ff ff       	call   f01001a3 <cons_putc>
		cons_putc(' ');
f01002bc:	b8 20 00 00 00       	mov    $0x20,%eax
f01002c1:	e8 dd fe ff ff       	call   f01001a3 <cons_putc>
f01002c6:	eb 1a                	jmp    f01002e2 <cons_putc+0x13f>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01002c8:	66 a1 34 f5 11 f0    	mov    0xf011f534,%ax
f01002ce:	0f b7 c8             	movzwl %ax,%ecx
f01002d1:	8b 15 30 f5 11 f0    	mov    0xf011f530,%edx
f01002d7:	66 89 34 4a          	mov    %si,(%edx,%ecx,2)
f01002db:	40                   	inc    %eax
f01002dc:	66 a3 34 f5 11 f0    	mov    %ax,0xf011f534
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01002e2:	66 81 3d 34 f5 11 f0 	cmpw   $0x7cf,0xf011f534
f01002e9:	cf 07 
f01002eb:	76 40                	jbe    f010032d <cons_putc+0x18a>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01002ed:	a1 30 f5 11 f0       	mov    0xf011f530,%eax
f01002f2:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f01002f9:	00 
f01002fa:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100300:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100304:	89 04 24             	mov    %eax,(%esp)
f0100307:	e8 f4 34 00 00       	call   f0103800 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010030c:	8b 15 30 f5 11 f0    	mov    0xf011f530,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100312:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100317:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010031d:	40                   	inc    %eax
f010031e:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100323:	75 f2                	jne    f0100317 <cons_putc+0x174>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f0100325:	66 83 2d 34 f5 11 f0 	subw   $0x50,0xf011f534
f010032c:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f010032d:	8b 0d 2c f5 11 f0    	mov    0xf011f52c,%ecx
f0100333:	b0 0e                	mov    $0xe,%al
f0100335:	89 ca                	mov    %ecx,%edx
f0100337:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100338:	66 8b 35 34 f5 11 f0 	mov    0xf011f534,%si
f010033f:	8d 59 01             	lea    0x1(%ecx),%ebx
f0100342:	89 f0                	mov    %esi,%eax
f0100344:	66 c1 e8 08          	shr    $0x8,%ax
f0100348:	89 da                	mov    %ebx,%edx
f010034a:	ee                   	out    %al,(%dx)
f010034b:	b0 0f                	mov    $0xf,%al
f010034d:	89 ca                	mov    %ecx,%edx
f010034f:	ee                   	out    %al,(%dx)
f0100350:	89 f0                	mov    %esi,%eax
f0100352:	89 da                	mov    %ebx,%edx
f0100354:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100355:	83 c4 2c             	add    $0x2c,%esp
f0100358:	5b                   	pop    %ebx
f0100359:	5e                   	pop    %esi
f010035a:	5f                   	pop    %edi
f010035b:	5d                   	pop    %ebp
f010035c:	c3                   	ret    

f010035d <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f010035d:	55                   	push   %ebp
f010035e:	89 e5                	mov    %esp,%ebp
f0100360:	53                   	push   %ebx
f0100361:	83 ec 14             	sub    $0x14,%esp

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100364:	ba 64 00 00 00       	mov    $0x64,%edx
f0100369:	ec                   	in     (%dx),%al
	int c;
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
f010036a:	0f b6 c0             	movzbl %al,%eax
f010036d:	a8 01                	test   $0x1,%al
f010036f:	0f 84 e0 00 00 00    	je     f0100455 <kbd_proc_data+0xf8>
		return -1;
	// Ignore data from mouse.
	if (stat & KBS_TERR)
f0100375:	a8 20                	test   $0x20,%al
f0100377:	0f 85 df 00 00 00    	jne    f010045c <kbd_proc_data+0xff>
f010037d:	b2 60                	mov    $0x60,%dl
f010037f:	ec                   	in     (%dx),%al
f0100380:	88 c2                	mov    %al,%dl
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100382:	3c e0                	cmp    $0xe0,%al
f0100384:	75 11                	jne    f0100397 <kbd_proc_data+0x3a>
		// E0 escape character
		shift |= E0ESC;
f0100386:	83 0d 28 f5 11 f0 40 	orl    $0x40,0xf011f528
		return 0;
f010038d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100392:	e9 ca 00 00 00       	jmp    f0100461 <kbd_proc_data+0x104>
	} else if (data & 0x80) {
f0100397:	84 c0                	test   %al,%al
f0100399:	79 33                	jns    f01003ce <kbd_proc_data+0x71>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010039b:	8b 0d 28 f5 11 f0    	mov    0xf011f528,%ecx
f01003a1:	f6 c1 40             	test   $0x40,%cl
f01003a4:	75 05                	jne    f01003ab <kbd_proc_data+0x4e>
f01003a6:	88 c2                	mov    %al,%dl
f01003a8:	83 e2 7f             	and    $0x7f,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01003ab:	0f b6 d2             	movzbl %dl,%edx
f01003ae:	8a 82 80 3c 10 f0    	mov    -0xfefc380(%edx),%al
f01003b4:	83 c8 40             	or     $0x40,%eax
f01003b7:	0f b6 c0             	movzbl %al,%eax
f01003ba:	f7 d0                	not    %eax
f01003bc:	21 c1                	and    %eax,%ecx
f01003be:	89 0d 28 f5 11 f0    	mov    %ecx,0xf011f528
		return 0;
f01003c4:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003c9:	e9 93 00 00 00       	jmp    f0100461 <kbd_proc_data+0x104>
	} else if (shift & E0ESC) {
f01003ce:	8b 0d 28 f5 11 f0    	mov    0xf011f528,%ecx
f01003d4:	f6 c1 40             	test   $0x40,%cl
f01003d7:	74 0e                	je     f01003e7 <kbd_proc_data+0x8a>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01003d9:	88 c2                	mov    %al,%dl
f01003db:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f01003de:	83 e1 bf             	and    $0xffffffbf,%ecx
f01003e1:	89 0d 28 f5 11 f0    	mov    %ecx,0xf011f528
	}

	shift |= shiftcode[data];
f01003e7:	0f b6 d2             	movzbl %dl,%edx
f01003ea:	0f b6 82 80 3c 10 f0 	movzbl -0xfefc380(%edx),%eax
f01003f1:	0b 05 28 f5 11 f0    	or     0xf011f528,%eax
	shift ^= togglecode[data];
f01003f7:	0f b6 8a 80 3d 10 f0 	movzbl -0xfefc280(%edx),%ecx
f01003fe:	31 c8                	xor    %ecx,%eax
f0100400:	a3 28 f5 11 f0       	mov    %eax,0xf011f528

	c = charcode[shift & (CTL | SHIFT)][data];
f0100405:	89 c1                	mov    %eax,%ecx
f0100407:	83 e1 03             	and    $0x3,%ecx
f010040a:	8b 0c 8d 80 3e 10 f0 	mov    -0xfefc180(,%ecx,4),%ecx
f0100411:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f0100415:	a8 08                	test   $0x8,%al
f0100417:	74 18                	je     f0100431 <kbd_proc_data+0xd4>
		if ('a' <= c && c <= 'z')
f0100419:	8d 53 9f             	lea    -0x61(%ebx),%edx
f010041c:	83 fa 19             	cmp    $0x19,%edx
f010041f:	77 05                	ja     f0100426 <kbd_proc_data+0xc9>
			c += 'A' - 'a';
f0100421:	83 eb 20             	sub    $0x20,%ebx
f0100424:	eb 0b                	jmp    f0100431 <kbd_proc_data+0xd4>
		else if ('A' <= c && c <= 'Z')
f0100426:	8d 53 bf             	lea    -0x41(%ebx),%edx
f0100429:	83 fa 19             	cmp    $0x19,%edx
f010042c:	77 03                	ja     f0100431 <kbd_proc_data+0xd4>
			c += 'a' - 'A';
f010042e:	83 c3 20             	add    $0x20,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100431:	f7 d0                	not    %eax
f0100433:	a8 06                	test   $0x6,%al
f0100435:	75 2a                	jne    f0100461 <kbd_proc_data+0x104>
f0100437:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010043d:	75 22                	jne    f0100461 <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f010043f:	c7 04 24 4d 3c 10 f0 	movl   $0xf0103c4d,(%esp)
f0100446:	e8 ff 28 00 00       	call   f0102d4a <cprintf>
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010044b:	ba 92 00 00 00       	mov    $0x92,%edx
f0100450:	b0 03                	mov    $0x3,%al
f0100452:	ee                   	out    %al,(%dx)
f0100453:	eb 0c                	jmp    f0100461 <kbd_proc_data+0x104>
	uint8_t stat, data;
	static uint32_t shift;

	stat = inb(KBSTATP);
	if ((stat & KBS_DIB) == 0)
		return -1;
f0100455:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
f010045a:	eb 05                	jmp    f0100461 <kbd_proc_data+0x104>
	// Ignore data from mouse.
	if (stat & KBS_TERR)
		return -1;
f010045c:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100461:	89 d8                	mov    %ebx,%eax
f0100463:	83 c4 14             	add    $0x14,%esp
f0100466:	5b                   	pop    %ebx
f0100467:	5d                   	pop    %ebp
f0100468:	c3                   	ret    

f0100469 <serial_intr>:
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100469:	55                   	push   %ebp
f010046a:	89 e5                	mov    %esp,%ebp
f010046c:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f010046f:	80 3d 00 f3 11 f0 00 	cmpb   $0x0,0xf011f300
f0100476:	74 0a                	je     f0100482 <serial_intr+0x19>
		cons_intr(serial_proc_data);
f0100478:	b8 46 01 10 f0       	mov    $0xf0100146,%eax
f010047d:	e8 e0 fc ff ff       	call   f0100162 <cons_intr>
}
f0100482:	c9                   	leave  
f0100483:	c3                   	ret    

f0100484 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100484:	55                   	push   %ebp
f0100485:	89 e5                	mov    %esp,%ebp
f0100487:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f010048a:	b8 5d 03 10 f0       	mov    $0xf010035d,%eax
f010048f:	e8 ce fc ff ff       	call   f0100162 <cons_intr>
}
f0100494:	c9                   	leave  
f0100495:	c3                   	ret    

f0100496 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100496:	55                   	push   %ebp
f0100497:	89 e5                	mov    %esp,%ebp
f0100499:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010049c:	e8 c8 ff ff ff       	call   f0100469 <serial_intr>
	kbd_intr();
f01004a1:	e8 de ff ff ff       	call   f0100484 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004a6:	8b 15 20 f5 11 f0    	mov    0xf011f520,%edx
f01004ac:	3b 15 24 f5 11 f0    	cmp    0xf011f524,%edx
f01004b2:	74 22                	je     f01004d6 <cons_getc+0x40>
		c = cons.buf[cons.rpos++];
f01004b4:	0f b6 82 20 f3 11 f0 	movzbl -0xfee0ce0(%edx),%eax
f01004bb:	42                   	inc    %edx
f01004bc:	89 15 20 f5 11 f0    	mov    %edx,0xf011f520
		if (cons.rpos == CONSBUFSIZE)
f01004c2:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004c8:	75 11                	jne    f01004db <cons_getc+0x45>
			cons.rpos = 0;
f01004ca:	c7 05 20 f5 11 f0 00 	movl   $0x0,0xf011f520
f01004d1:	00 00 00 
f01004d4:	eb 05                	jmp    f01004db <cons_getc+0x45>
		return c;
	}
	return 0;
f01004d6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01004db:	c9                   	leave  
f01004dc:	c3                   	ret    

f01004dd <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f01004dd:	55                   	push   %ebp
f01004de:	89 e5                	mov    %esp,%ebp
f01004e0:	57                   	push   %edi
f01004e1:	56                   	push   %esi
f01004e2:	53                   	push   %ebx
f01004e3:	83 ec 2c             	sub    $0x2c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01004e6:	66 8b 15 00 80 0b f0 	mov    0xf00b8000,%dx
	*cp = (uint16_t) 0xA55A;
f01004ed:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01004f4:	5a a5 
	if (*cp != 0xA55A) {
f01004f6:	66 a1 00 80 0b f0    	mov    0xf00b8000,%ax
f01004fc:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100500:	74 11                	je     f0100513 <cons_init+0x36>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f0100502:	c7 05 2c f5 11 f0 b4 	movl   $0x3b4,0xf011f52c
f0100509:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010050c:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100511:	eb 16                	jmp    f0100529 <cons_init+0x4c>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100513:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010051a:	c7 05 2c f5 11 f0 d4 	movl   $0x3d4,0xf011f52c
f0100521:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f0100524:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100529:	8b 0d 2c f5 11 f0    	mov    0xf011f52c,%ecx
f010052f:	b0 0e                	mov    $0xe,%al
f0100531:	89 ca                	mov    %ecx,%edx
f0100533:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f0100534:	8d 59 01             	lea    0x1(%ecx),%ebx

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100537:	89 da                	mov    %ebx,%edx
f0100539:	ec                   	in     (%dx),%al
f010053a:	0f b6 f8             	movzbl %al,%edi
f010053d:	c1 e7 08             	shl    $0x8,%edi
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100540:	b0 0f                	mov    $0xf,%al
f0100542:	89 ca                	mov    %ecx,%edx
f0100544:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100545:	89 da                	mov    %ebx,%edx
f0100547:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100548:	89 35 30 f5 11 f0    	mov    %esi,0xf011f530

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f010054e:	0f b6 d8             	movzbl %al,%ebx
f0100551:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100553:	66 89 3d 34 f5 11 f0 	mov    %di,0xf011f534
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010055a:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f010055f:	b0 00                	mov    $0x0,%al
f0100561:	89 da                	mov    %ebx,%edx
f0100563:	ee                   	out    %al,(%dx)
f0100564:	b2 fb                	mov    $0xfb,%dl
f0100566:	b0 80                	mov    $0x80,%al
f0100568:	ee                   	out    %al,(%dx)
f0100569:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f010056e:	b0 0c                	mov    $0xc,%al
f0100570:	89 ca                	mov    %ecx,%edx
f0100572:	ee                   	out    %al,(%dx)
f0100573:	b2 f9                	mov    $0xf9,%dl
f0100575:	b0 00                	mov    $0x0,%al
f0100577:	ee                   	out    %al,(%dx)
f0100578:	b2 fb                	mov    $0xfb,%dl
f010057a:	b0 03                	mov    $0x3,%al
f010057c:	ee                   	out    %al,(%dx)
f010057d:	b2 fc                	mov    $0xfc,%dl
f010057f:	b0 00                	mov    $0x0,%al
f0100581:	ee                   	out    %al,(%dx)
f0100582:	b2 f9                	mov    $0xf9,%dl
f0100584:	b0 01                	mov    $0x1,%al
f0100586:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100587:	b2 fd                	mov    $0xfd,%dl
f0100589:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010058a:	3c ff                	cmp    $0xff,%al
f010058c:	0f 95 45 e7          	setne  -0x19(%ebp)
f0100590:	8a 45 e7             	mov    -0x19(%ebp),%al
f0100593:	a2 00 f3 11 f0       	mov    %al,0xf011f300
f0100598:	89 da                	mov    %ebx,%edx
f010059a:	ec                   	in     (%dx),%al
f010059b:	89 ca                	mov    %ecx,%edx
f010059d:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010059e:	80 7d e7 00          	cmpb   $0x0,-0x19(%ebp)
f01005a2:	75 0c                	jne    f01005b0 <cons_init+0xd3>
		cprintf("Serial port does not exist!\n");
f01005a4:	c7 04 24 59 3c 10 f0 	movl   $0xf0103c59,(%esp)
f01005ab:	e8 9a 27 00 00       	call   f0102d4a <cprintf>
}
f01005b0:	83 c4 2c             	add    $0x2c,%esp
f01005b3:	5b                   	pop    %ebx
f01005b4:	5e                   	pop    %esi
f01005b5:	5f                   	pop    %edi
f01005b6:	5d                   	pop    %ebp
f01005b7:	c3                   	ret    

f01005b8 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005b8:	55                   	push   %ebp
f01005b9:	89 e5                	mov    %esp,%ebp
f01005bb:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005be:	8b 45 08             	mov    0x8(%ebp),%eax
f01005c1:	e8 dd fb ff ff       	call   f01001a3 <cons_putc>
}
f01005c6:	c9                   	leave  
f01005c7:	c3                   	ret    

f01005c8 <getchar>:

int
getchar(void)
{
f01005c8:	55                   	push   %ebp
f01005c9:	89 e5                	mov    %esp,%ebp
f01005cb:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01005ce:	e8 c3 fe ff ff       	call   f0100496 <cons_getc>
f01005d3:	85 c0                	test   %eax,%eax
f01005d5:	74 f7                	je     f01005ce <getchar+0x6>
		/* do nothing */;
	return c;
}
f01005d7:	c9                   	leave  
f01005d8:	c3                   	ret    

f01005d9 <iscons>:

int
iscons(int fdnum)
{
f01005d9:	55                   	push   %ebp
f01005da:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01005dc:	b8 01 00 00 00       	mov    $0x1,%eax
f01005e1:	5d                   	pop    %ebp
f01005e2:	c3                   	ret    
	...

f01005e4 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01005e4:	55                   	push   %ebp
f01005e5:	89 e5                	mov    %esp,%ebp
f01005e7:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01005ea:	c7 04 24 90 3e 10 f0 	movl   $0xf0103e90,(%esp)
f01005f1:	e8 54 27 00 00       	call   f0102d4a <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01005f6:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01005fd:	00 
f01005fe:	c7 04 24 1c 3f 10 f0 	movl   $0xf0103f1c,(%esp)
f0100605:	e8 40 27 00 00       	call   f0102d4a <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f010060a:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f0100611:	00 
f0100612:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100619:	f0 
f010061a:	c7 04 24 44 3f 10 f0 	movl   $0xf0103f44,(%esp)
f0100621:	e8 24 27 00 00       	call   f0102d4a <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100626:	c7 44 24 08 fa 3b 10 	movl   $0x103bfa,0x8(%esp)
f010062d:	00 
f010062e:	c7 44 24 04 fa 3b 10 	movl   $0xf0103bfa,0x4(%esp)
f0100635:	f0 
f0100636:	c7 04 24 68 3f 10 f0 	movl   $0xf0103f68,(%esp)
f010063d:	e8 08 27 00 00       	call   f0102d4a <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100642:	c7 44 24 08 00 f3 11 	movl   $0x11f300,0x8(%esp)
f0100649:	00 
f010064a:	c7 44 24 04 00 f3 11 	movl   $0xf011f300,0x4(%esp)
f0100651:	f0 
f0100652:	c7 04 24 8c 3f 10 f0 	movl   $0xf0103f8c,(%esp)
f0100659:	e8 ec 26 00 00       	call   f0102d4a <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010065e:	c7 44 24 08 70 f9 11 	movl   $0x11f970,0x8(%esp)
f0100665:	00 
f0100666:	c7 44 24 04 70 f9 11 	movl   $0xf011f970,0x4(%esp)
f010066d:	f0 
f010066e:	c7 04 24 b0 3f 10 f0 	movl   $0xf0103fb0,(%esp)
f0100675:	e8 d0 26 00 00       	call   f0102d4a <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f010067a:	b8 6f fd 11 f0       	mov    $0xf011fd6f,%eax
f010067f:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100684:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100689:	89 c2                	mov    %eax,%edx
f010068b:	85 c0                	test   %eax,%eax
f010068d:	79 06                	jns    f0100695 <mon_kerninfo+0xb1>
f010068f:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f0100695:	c1 fa 0a             	sar    $0xa,%edx
f0100698:	89 54 24 04          	mov    %edx,0x4(%esp)
f010069c:	c7 04 24 d4 3f 10 f0 	movl   $0xf0103fd4,(%esp)
f01006a3:	e8 a2 26 00 00       	call   f0102d4a <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01006a8:	b8 00 00 00 00       	mov    $0x0,%eax
f01006ad:	c9                   	leave  
f01006ae:	c3                   	ret    

f01006af <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006af:	55                   	push   %ebp
f01006b0:	89 e5                	mov    %esp,%ebp
f01006b2:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < ARRAY_SIZE(commands); i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01006b5:	c7 44 24 08 a9 3e 10 	movl   $0xf0103ea9,0x8(%esp)
f01006bc:	f0 
f01006bd:	c7 44 24 04 c7 3e 10 	movl   $0xf0103ec7,0x4(%esp)
f01006c4:	f0 
f01006c5:	c7 04 24 cc 3e 10 f0 	movl   $0xf0103ecc,(%esp)
f01006cc:	e8 79 26 00 00       	call   f0102d4a <cprintf>
f01006d1:	c7 44 24 08 00 40 10 	movl   $0xf0104000,0x8(%esp)
f01006d8:	f0 
f01006d9:	c7 44 24 04 d5 3e 10 	movl   $0xf0103ed5,0x4(%esp)
f01006e0:	f0 
f01006e1:	c7 04 24 cc 3e 10 f0 	movl   $0xf0103ecc,(%esp)
f01006e8:	e8 5d 26 00 00       	call   f0102d4a <cprintf>
	return 0;
}
f01006ed:	b8 00 00 00 00       	mov    $0x0,%eax
f01006f2:	c9                   	leave  
f01006f3:	c3                   	ret    

f01006f4 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01006f4:	55                   	push   %ebp
f01006f5:	89 e5                	mov    %esp,%ebp
	// Your code here.
	return 0;
}
f01006f7:	b8 00 00 00 00       	mov    $0x0,%eax
f01006fc:	5d                   	pop    %ebp
f01006fd:	c3                   	ret    

f01006fe <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01006fe:	55                   	push   %ebp
f01006ff:	89 e5                	mov    %esp,%ebp
f0100701:	57                   	push   %edi
f0100702:	56                   	push   %esi
f0100703:	53                   	push   %ebx
f0100704:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100707:	c7 04 24 28 40 10 f0 	movl   $0xf0104028,(%esp)
f010070e:	e8 37 26 00 00       	call   f0102d4a <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100713:	c7 04 24 4c 40 10 f0 	movl   $0xf010404c,(%esp)
f010071a:	e8 2b 26 00 00       	call   f0102d4a <cprintf>
	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
f010071f:	8d 7d a8             	lea    -0x58(%ebp),%edi
	cprintf("Welcome to the JOS kernel monitor!\n");
	cprintf("Type 'help' for a list of commands.\n");


	while (1) {
		buf = readline("K> ");
f0100722:	c7 04 24 de 3e 10 f0 	movl   $0xf0103ede,(%esp)
f0100729:	e8 5e 2e 00 00       	call   f010358c <readline>
f010072e:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100730:	85 c0                	test   %eax,%eax
f0100732:	74 ee                	je     f0100722 <monitor+0x24>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100734:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f010073b:	be 00 00 00 00       	mov    $0x0,%esi
f0100740:	eb 04                	jmp    f0100746 <monitor+0x48>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100742:	c6 03 00             	movb   $0x0,(%ebx)
f0100745:	43                   	inc    %ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100746:	8a 03                	mov    (%ebx),%al
f0100748:	84 c0                	test   %al,%al
f010074a:	74 5e                	je     f01007aa <monitor+0xac>
f010074c:	0f be c0             	movsbl %al,%eax
f010074f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100753:	c7 04 24 e2 3e 10 f0 	movl   $0xf0103ee2,(%esp)
f010075a:	e8 22 30 00 00       	call   f0103781 <strchr>
f010075f:	85 c0                	test   %eax,%eax
f0100761:	75 df                	jne    f0100742 <monitor+0x44>
			*buf++ = 0;
		if (*buf == 0)
f0100763:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100766:	74 42                	je     f01007aa <monitor+0xac>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100768:	83 fe 0f             	cmp    $0xf,%esi
f010076b:	75 16                	jne    f0100783 <monitor+0x85>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010076d:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100774:	00 
f0100775:	c7 04 24 e7 3e 10 f0 	movl   $0xf0103ee7,(%esp)
f010077c:	e8 c9 25 00 00       	call   f0102d4a <cprintf>
f0100781:	eb 9f                	jmp    f0100722 <monitor+0x24>
			return 0;
		}
		argv[argc++] = buf;
f0100783:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100787:	46                   	inc    %esi
f0100788:	eb 01                	jmp    f010078b <monitor+0x8d>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f010078a:	43                   	inc    %ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f010078b:	8a 03                	mov    (%ebx),%al
f010078d:	84 c0                	test   %al,%al
f010078f:	74 b5                	je     f0100746 <monitor+0x48>
f0100791:	0f be c0             	movsbl %al,%eax
f0100794:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100798:	c7 04 24 e2 3e 10 f0 	movl   $0xf0103ee2,(%esp)
f010079f:	e8 dd 2f 00 00       	call   f0103781 <strchr>
f01007a4:	85 c0                	test   %eax,%eax
f01007a6:	74 e2                	je     f010078a <monitor+0x8c>
f01007a8:	eb 9c                	jmp    f0100746 <monitor+0x48>
			buf++;
	}
	argv[argc] = 0;
f01007aa:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01007b1:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01007b2:	85 f6                	test   %esi,%esi
f01007b4:	0f 84 68 ff ff ff    	je     f0100722 <monitor+0x24>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01007ba:	c7 44 24 04 c7 3e 10 	movl   $0xf0103ec7,0x4(%esp)
f01007c1:	f0 
f01007c2:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01007c5:	89 04 24             	mov    %eax,(%esp)
f01007c8:	e8 61 2f 00 00       	call   f010372e <strcmp>
f01007cd:	85 c0                	test   %eax,%eax
f01007cf:	74 1b                	je     f01007ec <monitor+0xee>
f01007d1:	c7 44 24 04 d5 3e 10 	movl   $0xf0103ed5,0x4(%esp)
f01007d8:	f0 
f01007d9:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01007dc:	89 04 24             	mov    %eax,(%esp)
f01007df:	e8 4a 2f 00 00       	call   f010372e <strcmp>
f01007e4:	85 c0                	test   %eax,%eax
f01007e6:	75 2c                	jne    f0100814 <monitor+0x116>
f01007e8:	b0 01                	mov    $0x1,%al
f01007ea:	eb 05                	jmp    f01007f1 <monitor+0xf3>
f01007ec:	b8 00 00 00 00       	mov    $0x0,%eax
			return commands[i].func(argc, argv, tf);
f01007f1:	8d 14 00             	lea    (%eax,%eax,1),%edx
f01007f4:	01 d0                	add    %edx,%eax
f01007f6:	8b 55 08             	mov    0x8(%ebp),%edx
f01007f9:	89 54 24 08          	mov    %edx,0x8(%esp)
f01007fd:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0100801:	89 34 24             	mov    %esi,(%esp)
f0100804:	ff 14 85 7c 40 10 f0 	call   *-0xfefbf84(,%eax,4)


	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f010080b:	85 c0                	test   %eax,%eax
f010080d:	78 1d                	js     f010082c <monitor+0x12e>
f010080f:	e9 0e ff ff ff       	jmp    f0100722 <monitor+0x24>
		return 0;
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100814:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100817:	89 44 24 04          	mov    %eax,0x4(%esp)
f010081b:	c7 04 24 04 3f 10 f0 	movl   $0xf0103f04,(%esp)
f0100822:	e8 23 25 00 00       	call   f0102d4a <cprintf>
f0100827:	e9 f6 fe ff ff       	jmp    f0100722 <monitor+0x24>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f010082c:	83 c4 5c             	add    $0x5c,%esp
f010082f:	5b                   	pop    %ebx
f0100830:	5e                   	pop    %esi
f0100831:	5f                   	pop    %edi
f0100832:	5d                   	pop    %ebp
f0100833:	c3                   	ret    

f0100834 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100834:	55                   	push   %ebp
f0100835:	89 e5                	mov    %esp,%ebp
f0100837:	83 ec 18             	sub    $0x18,%esp
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f010083a:	89 d1                	mov    %edx,%ecx
f010083c:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f010083f:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100842:	a8 01                	test   $0x1,%al
f0100844:	74 4d                	je     f0100893 <check_va2pa+0x5f>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100846:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010084b:	89 c1                	mov    %eax,%ecx
f010084d:	c1 e9 0c             	shr    $0xc,%ecx
f0100850:	3b 0d 64 f9 11 f0    	cmp    0xf011f964,%ecx
f0100856:	72 20                	jb     f0100878 <check_va2pa+0x44>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100858:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010085c:	c7 44 24 08 8c 40 10 	movl   $0xf010408c,0x8(%esp)
f0100863:	f0 
f0100864:	c7 44 24 04 ef 02 00 	movl   $0x2ef,0x4(%esp)
f010086b:	00 
f010086c:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0100873:	e8 1c f8 ff ff       	call   f0100094 <_panic>
	if (!(p[PTX(va)] & PTE_P))
f0100878:	c1 ea 0c             	shr    $0xc,%edx
f010087b:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100881:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100888:	a8 01                	test   $0x1,%al
f010088a:	74 0e                	je     f010089a <check_va2pa+0x66>
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f010088c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100891:	eb 0c                	jmp    f010089f <check_va2pa+0x6b>
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100893:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100898:	eb 05                	jmp    f010089f <check_va2pa+0x6b>
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
f010089a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return PTE_ADDR(p[PTX(va)]);
}
f010089f:	c9                   	leave  
f01008a0:	c3                   	ret    

f01008a1 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01008a1:	55                   	push   %ebp
f01008a2:	89 e5                	mov    %esp,%ebp
f01008a4:	83 ec 18             	sub    $0x18,%esp
f01008a7:	89 c2                	mov    %eax,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01008a9:	83 3d 3c f5 11 f0 00 	cmpl   $0x0,0xf011f53c
f01008b0:	75 0f                	jne    f01008c1 <boot_alloc+0x20>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f01008b2:	b8 6f 09 12 f0       	mov    $0xf012096f,%eax
f01008b7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01008bc:	a3 3c f5 11 f0       	mov    %eax,0xf011f53c
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result = nextfree;
f01008c1:	a1 3c f5 11 f0       	mov    0xf011f53c,%eax
	if (n > 0) {
f01008c6:	85 d2                	test   %edx,%edx
f01008c8:	74 13                	je     f01008dd <boot_alloc+0x3c>
		nextfree = ROUNDUP(nextfree + n, PGSIZE);
f01008ca:	8d 94 10 ff 0f 00 00 	lea    0xfff(%eax,%edx,1),%edx
f01008d1:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01008d7:	89 15 3c f5 11 f0    	mov    %edx,0xf011f53c
	}
	if ((uint32_t)nextfree - KERNBASE > (npages*PGSIZE))
f01008dd:	8b 0d 3c f5 11 f0    	mov    0xf011f53c,%ecx
f01008e3:	81 c1 00 00 00 10    	add    $0x10000000,%ecx
f01008e9:	8b 15 64 f9 11 f0    	mov    0xf011f964,%edx
f01008ef:	c1 e2 0c             	shl    $0xc,%edx
f01008f2:	39 d1                	cmp    %edx,%ecx
f01008f4:	76 1c                	jbe    f0100912 <boot_alloc+0x71>
		panic("out of memory\n"); 
f01008f6:	c7 44 24 08 40 48 10 	movl   $0xf0104840,0x8(%esp)
f01008fd:	f0 
f01008fe:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
f0100905:	00 
f0100906:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f010090d:	e8 82 f7 ff ff       	call   f0100094 <_panic>
	
	return result;
}
f0100912:	c9                   	leave  
f0100913:	c3                   	ret    

f0100914 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100914:	55                   	push   %ebp
f0100915:	89 e5                	mov    %esp,%ebp
f0100917:	56                   	push   %esi
f0100918:	53                   	push   %ebx
f0100919:	83 ec 10             	sub    $0x10,%esp
f010091c:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010091e:	89 04 24             	mov    %eax,(%esp)
f0100921:	e8 b6 23 00 00       	call   f0102cdc <mc146818_read>
f0100926:	89 c6                	mov    %eax,%esi
f0100928:	43                   	inc    %ebx
f0100929:	89 1c 24             	mov    %ebx,(%esp)
f010092c:	e8 ab 23 00 00       	call   f0102cdc <mc146818_read>
f0100931:	c1 e0 08             	shl    $0x8,%eax
f0100934:	09 f0                	or     %esi,%eax
}
f0100936:	83 c4 10             	add    $0x10,%esp
f0100939:	5b                   	pop    %ebx
f010093a:	5e                   	pop    %esi
f010093b:	5d                   	pop    %ebp
f010093c:	c3                   	ret    

f010093d <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
	static void
check_page_free_list(bool only_low_memory)
{
f010093d:	55                   	push   %ebp
f010093e:	89 e5                	mov    %esp,%ebp
f0100940:	57                   	push   %edi
f0100941:	56                   	push   %esi
f0100942:	53                   	push   %ebx
f0100943:	83 ec 4c             	sub    $0x4c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100946:	3c 01                	cmp    $0x1,%al
f0100948:	19 f6                	sbb    %esi,%esi
f010094a:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f0100950:	46                   	inc    %esi
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100951:	8b 15 40 f5 11 f0    	mov    0xf011f540,%edx
f0100957:	85 d2                	test   %edx,%edx
f0100959:	75 1c                	jne    f0100977 <check_page_free_list+0x3a>
		panic("'page_free_list' is a null pointer!");
f010095b:	c7 44 24 08 b0 40 10 	movl   $0xf01040b0,0x8(%esp)
f0100962:	f0 
f0100963:	c7 44 24 04 32 02 00 	movl   $0x232,0x4(%esp)
f010096a:	00 
f010096b:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0100972:	e8 1d f7 ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
f0100977:	84 c0                	test   %al,%al
f0100979:	74 4b                	je     f01009c6 <check_page_free_list+0x89>
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f010097b:	8d 45 e0             	lea    -0x20(%ebp),%eax
f010097e:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100981:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100984:	89 45 dc             	mov    %eax,-0x24(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100987:	89 d0                	mov    %edx,%eax
f0100989:	2b 05 6c f9 11 f0    	sub    0xf011f96c,%eax
f010098f:	c1 e0 09             	shl    $0x9,%eax
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100992:	c1 e8 16             	shr    $0x16,%eax
f0100995:	39 c6                	cmp    %eax,%esi
f0100997:	0f 96 c0             	setbe  %al
f010099a:	0f b6 c0             	movzbl %al,%eax
			*tp[pagetype] = pp;
f010099d:	8b 4c 85 d8          	mov    -0x28(%ebp,%eax,4),%ecx
f01009a1:	89 11                	mov    %edx,(%ecx)
			tp[pagetype] = &pp->pp_link;
f01009a3:	89 54 85 d8          	mov    %edx,-0x28(%ebp,%eax,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f01009a7:	8b 12                	mov    (%edx),%edx
f01009a9:	85 d2                	test   %edx,%edx
f01009ab:	75 da                	jne    f0100987 <check_page_free_list+0x4a>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f01009ad:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01009b0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f01009b6:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01009b9:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01009bc:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f01009be:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01009c1:	a3 40 f5 11 f0       	mov    %eax,0xf011f540
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01009c6:	8b 1d 40 f5 11 f0    	mov    0xf011f540,%ebx
f01009cc:	eb 63                	jmp    f0100a31 <check_page_free_list+0xf4>
f01009ce:	89 d8                	mov    %ebx,%eax
f01009d0:	2b 05 6c f9 11 f0    	sub    0xf011f96c,%eax
f01009d6:	c1 f8 03             	sar    $0x3,%eax
f01009d9:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f01009dc:	89 c2                	mov    %eax,%edx
f01009de:	c1 ea 16             	shr    $0x16,%edx
f01009e1:	39 d6                	cmp    %edx,%esi
f01009e3:	76 4a                	jbe    f0100a2f <check_page_free_list+0xf2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01009e5:	89 c2                	mov    %eax,%edx
f01009e7:	c1 ea 0c             	shr    $0xc,%edx
f01009ea:	3b 15 64 f9 11 f0    	cmp    0xf011f964,%edx
f01009f0:	72 20                	jb     f0100a12 <check_page_free_list+0xd5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01009f2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01009f6:	c7 44 24 08 8c 40 10 	movl   $0xf010408c,0x8(%esp)
f01009fd:	f0 
f01009fe:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100a05:	00 
f0100a06:	c7 04 24 4f 48 10 f0 	movl   $0xf010484f,(%esp)
f0100a0d:	e8 82 f6 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100a12:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100a19:	00 
f0100a1a:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100a21:	00 
	return (void *)(pa + KERNBASE);
f0100a22:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100a27:	89 04 24             	mov    %eax,(%esp)
f0100a2a:	e8 87 2d 00 00       	call   f01037b6 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100a2f:	8b 1b                	mov    (%ebx),%ebx
f0100a31:	85 db                	test   %ebx,%ebx
f0100a33:	75 99                	jne    f01009ce <check_page_free_list+0x91>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100a35:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a3a:	e8 62 fe ff ff       	call   f01008a1 <boot_alloc>
f0100a3f:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a42:	8b 15 40 f5 11 f0    	mov    0xf011f540,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a48:	8b 0d 6c f9 11 f0    	mov    0xf011f96c,%ecx
		assert(pp < pages + npages);
f0100a4e:	a1 64 f9 11 f0       	mov    0xf011f964,%eax
f0100a53:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0100a56:	8d 34 c1             	lea    (%ecx,%eax,8),%esi
	static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100a59:	c7 45 d0 00 00 00 00 	movl   $0x0,-0x30(%ebp)
f0100a60:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f0100a67:	89 4d c0             	mov    %ecx,-0x40(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100a6a:	e9 93 01 00 00       	jmp    f0100c02 <check_page_free_list+0x2c5>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100a6f:	39 ca                	cmp    %ecx,%edx
f0100a71:	73 24                	jae    f0100a97 <check_page_free_list+0x15a>
f0100a73:	c7 44 24 0c 5d 48 10 	movl   $0xf010485d,0xc(%esp)
f0100a7a:	f0 
f0100a7b:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0100a82:	f0 
f0100a83:	c7 44 24 04 4c 02 00 	movl   $0x24c,0x4(%esp)
f0100a8a:	00 
f0100a8b:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0100a92:	e8 fd f5 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100a97:	39 f2                	cmp    %esi,%edx
f0100a99:	72 24                	jb     f0100abf <check_page_free_list+0x182>
f0100a9b:	c7 44 24 0c 7e 48 10 	movl   $0xf010487e,0xc(%esp)
f0100aa2:	f0 
f0100aa3:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0100aaa:	f0 
f0100aab:	c7 44 24 04 4d 02 00 	movl   $0x24d,0x4(%esp)
f0100ab2:	00 
f0100ab3:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0100aba:	e8 d5 f5 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100abf:	89 d0                	mov    %edx,%eax
f0100ac1:	2b 45 c0             	sub    -0x40(%ebp),%eax
f0100ac4:	a8 07                	test   $0x7,%al
f0100ac6:	74 24                	je     f0100aec <check_page_free_list+0x1af>
f0100ac8:	c7 44 24 0c d4 40 10 	movl   $0xf01040d4,0xc(%esp)
f0100acf:	f0 
f0100ad0:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0100ad7:	f0 
f0100ad8:	c7 44 24 04 4e 02 00 	movl   $0x24e,0x4(%esp)
f0100adf:	00 
f0100ae0:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0100ae7:	e8 a8 f5 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100aec:	c1 f8 03             	sar    $0x3,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100aef:	c1 e0 0c             	shl    $0xc,%eax
f0100af2:	75 24                	jne    f0100b18 <check_page_free_list+0x1db>
f0100af4:	c7 44 24 0c 92 48 10 	movl   $0xf0104892,0xc(%esp)
f0100afb:	f0 
f0100afc:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0100b03:	f0 
f0100b04:	c7 44 24 04 51 02 00 	movl   $0x251,0x4(%esp)
f0100b0b:	00 
f0100b0c:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0100b13:	e8 7c f5 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100b18:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100b1d:	75 24                	jne    f0100b43 <check_page_free_list+0x206>
f0100b1f:	c7 44 24 0c a3 48 10 	movl   $0xf01048a3,0xc(%esp)
f0100b26:	f0 
f0100b27:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0100b2e:	f0 
f0100b2f:	c7 44 24 04 52 02 00 	movl   $0x252,0x4(%esp)
f0100b36:	00 
f0100b37:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0100b3e:	e8 51 f5 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100b43:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100b48:	75 24                	jne    f0100b6e <check_page_free_list+0x231>
f0100b4a:	c7 44 24 0c 08 41 10 	movl   $0xf0104108,0xc(%esp)
f0100b51:	f0 
f0100b52:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0100b59:	f0 
f0100b5a:	c7 44 24 04 53 02 00 	movl   $0x253,0x4(%esp)
f0100b61:	00 
f0100b62:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0100b69:	e8 26 f5 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100b6e:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100b73:	75 24                	jne    f0100b99 <check_page_free_list+0x25c>
f0100b75:	c7 44 24 0c bc 48 10 	movl   $0xf01048bc,0xc(%esp)
f0100b7c:	f0 
f0100b7d:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0100b84:	f0 
f0100b85:	c7 44 24 04 54 02 00 	movl   $0x254,0x4(%esp)
f0100b8c:	00 
f0100b8d:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0100b94:	e8 fb f4 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100b99:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100b9e:	76 58                	jbe    f0100bf8 <check_page_free_list+0x2bb>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ba0:	89 c3                	mov    %eax,%ebx
f0100ba2:	c1 eb 0c             	shr    $0xc,%ebx
f0100ba5:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100ba8:	77 20                	ja     f0100bca <check_page_free_list+0x28d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100baa:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100bae:	c7 44 24 08 8c 40 10 	movl   $0xf010408c,0x8(%esp)
f0100bb5:	f0 
f0100bb6:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100bbd:	00 
f0100bbe:	c7 04 24 4f 48 10 f0 	movl   $0xf010484f,(%esp)
f0100bc5:	e8 ca f4 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100bca:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bcf:	39 45 c4             	cmp    %eax,-0x3c(%ebp)
f0100bd2:	76 29                	jbe    f0100bfd <check_page_free_list+0x2c0>
f0100bd4:	c7 44 24 0c 2c 41 10 	movl   $0xf010412c,0xc(%esp)
f0100bdb:	f0 
f0100bdc:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0100be3:	f0 
f0100be4:	c7 44 24 04 55 02 00 	movl   $0x255,0x4(%esp)
f0100beb:	00 
f0100bec:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0100bf3:	e8 9c f4 ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100bf8:	ff 45 d4             	incl   -0x2c(%ebp)
f0100bfb:	eb 03                	jmp    f0100c00 <check_page_free_list+0x2c3>
		else
			++nfree_extmem;
f0100bfd:	ff 45 d0             	incl   -0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c00:	8b 12                	mov    (%edx),%edx
f0100c02:	85 d2                	test   %edx,%edx
f0100c04:	0f 85 65 fe ff ff    	jne    f0100a6f <check_page_free_list+0x132>
		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
		else
			++nfree_extmem;
	}
	cprintf("nfree_basemem = %x, nfree_extmem = %x\n", nfree_basemem, nfree_extmem);
f0100c0a:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0100c0d:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0100c11:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0100c14:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100c18:	c7 04 24 74 41 10 f0 	movl   $0xf0104174,(%esp)
f0100c1f:	e8 26 21 00 00       	call   f0102d4a <cprintf>
	assert(nfree_basemem > 0);
f0100c24:	85 db                	test   %ebx,%ebx
f0100c26:	7f 24                	jg     f0100c4c <check_page_free_list+0x30f>
f0100c28:	c7 44 24 0c d6 48 10 	movl   $0xf01048d6,0xc(%esp)
f0100c2f:	f0 
f0100c30:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0100c37:	f0 
f0100c38:	c7 44 24 04 5d 02 00 	movl   $0x25d,0x4(%esp)
f0100c3f:	00 
f0100c40:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0100c47:	e8 48 f4 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0100c4c:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0100c50:	7f 24                	jg     f0100c76 <check_page_free_list+0x339>
f0100c52:	c7 44 24 0c e8 48 10 	movl   $0xf01048e8,0xc(%esp)
f0100c59:	f0 
f0100c5a:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0100c61:	f0 
f0100c62:	c7 44 24 04 5e 02 00 	movl   $0x25e,0x4(%esp)
f0100c69:	00 
f0100c6a:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0100c71:	e8 1e f4 ff ff       	call   f0100094 <_panic>
}
f0100c76:	83 c4 4c             	add    $0x4c,%esp
f0100c79:	5b                   	pop    %ebx
f0100c7a:	5e                   	pop    %esi
f0100c7b:	5f                   	pop    %edi
f0100c7c:	5d                   	pop    %ebp
f0100c7d:	c3                   	ret    

f0100c7e <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100c7e:	55                   	push   %ebp
f0100c7f:	89 e5                	mov    %esp,%ebp
f0100c81:	56                   	push   %esi
f0100c82:	53                   	push   %ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	pages[0].pp_ref = 1;
f0100c83:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
f0100c88:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
	for (i = 1; i < npages_basemem; i++) {
f0100c8e:	8b 35 38 f5 11 f0    	mov    0xf011f538,%esi
f0100c94:	8b 0d 40 f5 11 f0    	mov    0xf011f540,%ecx
f0100c9a:	bb 01 00 00 00       	mov    $0x1,%ebx
f0100c9f:	eb 20                	jmp    f0100cc1 <page_init+0x43>
		pages[i].pp_ref = 0;
f0100ca1:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
f0100ca8:	8b 15 6c f9 11 f0    	mov    0xf011f96c,%edx
f0100cae:	66 c7 44 02 04 00 00 	movw   $0x0,0x4(%edx,%eax,1)
		pages[i].pp_link = page_free_list;
f0100cb5:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
		page_free_list = &pages[i];
f0100cb8:	89 c1                	mov    %eax,%ecx
f0100cba:	03 0d 6c f9 11 f0    	add    0xf011f96c,%ecx
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	pages[0].pp_ref = 1;
	for (i = 1; i < npages_basemem; i++) {
f0100cc0:	43                   	inc    %ebx
f0100cc1:	39 f3                	cmp    %esi,%ebx
f0100cc3:	72 dc                	jb     f0100ca1 <page_init+0x23>
f0100cc5:	89 0d 40 f5 11 f0    	mov    %ecx,0xf011f540
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
	//cprintf("basemem page = %x\n", i);
//	panic("test 2\n");
	uint32_t boot_end = (uint32_t)boot_alloc(0);
f0100ccb:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cd0:	e8 cc fb ff ff       	call   f01008a1 <boot_alloc>
	for (; i < ((npages_basemem + (boot_end - KERNBASE) / PGSIZE) + ((EXTPHYSMEM - IOPHYSMEM) / PGSIZE)); i++) {
f0100cd5:	05 00 00 00 10       	add    $0x10000000,%eax
f0100cda:	c1 e8 0c             	shr    $0xc,%eax
f0100cdd:	8d 44 06 60          	lea    0x60(%esi,%eax,1),%eax
		pages[i].pp_ref = 1;
f0100ce1:	8b 15 6c f9 11 f0    	mov    0xf011f96c,%edx
		page_free_list = &pages[i];
	}
	//cprintf("basemem page = %x\n", i);
//	panic("test 2\n");
	uint32_t boot_end = (uint32_t)boot_alloc(0);
	for (; i < ((npages_basemem + (boot_end - KERNBASE) / PGSIZE) + ((EXTPHYSMEM - IOPHYSMEM) / PGSIZE)); i++) {
f0100ce7:	eb 08                	jmp    f0100cf1 <page_init+0x73>
		pages[i].pp_ref = 1;
f0100ce9:	66 c7 44 da 04 01 00 	movw   $0x1,0x4(%edx,%ebx,8)
		page_free_list = &pages[i];
	}
	//cprintf("basemem page = %x\n", i);
//	panic("test 2\n");
	uint32_t boot_end = (uint32_t)boot_alloc(0);
	for (; i < ((npages_basemem + (boot_end - KERNBASE) / PGSIZE) + ((EXTPHYSMEM - IOPHYSMEM) / PGSIZE)); i++) {
f0100cf0:	43                   	inc    %ebx
f0100cf1:	39 c3                	cmp    %eax,%ebx
f0100cf3:	72 f4                	jb     f0100ce9 <page_init+0x6b>
f0100cf5:	8b 0d 40 f5 11 f0    	mov    0xf011f540,%ecx
f0100cfb:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
f0100d02:	eb 1c                	jmp    f0100d20 <page_init+0xa2>
        }
	//cprintf("ref_page = %x\n", boot_end);
	//cprintf("occupied page = %x\n", npages_basemem + ((boot_end - KERNBASE) / PGSIZE) + 96);
//	panic("test 3\n");
        for (; i < npages; i++) {
		pages[i].pp_ref = 0;
f0100d04:	8b 15 6c f9 11 f0    	mov    0xf011f96c,%edx
f0100d0a:	66 c7 44 02 04 00 00 	movw   $0x0,0x4(%edx,%eax,1)
                pages[i].pp_link = page_free_list;
f0100d11:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
                page_free_list = &pages[i];
f0100d14:	89 c1                	mov    %eax,%ecx
f0100d16:	03 0d 6c f9 11 f0    	add    0xf011f96c,%ecx
		pages[i].pp_ref = 1;
        }
	//cprintf("ref_page = %x\n", boot_end);
	//cprintf("occupied page = %x\n", npages_basemem + ((boot_end - KERNBASE) / PGSIZE) + 96);
//	panic("test 3\n");
        for (; i < npages; i++) {
f0100d1c:	43                   	inc    %ebx
f0100d1d:	83 c0 08             	add    $0x8,%eax
f0100d20:	3b 1d 64 f9 11 f0    	cmp    0xf011f964,%ebx
f0100d26:	72 dc                	jb     f0100d04 <page_init+0x86>
f0100d28:	89 0d 40 f5 11 f0    	mov    %ecx,0xf011f540
                pages[i].pp_link = page_free_list;
                page_free_list = &pages[i];
        }
	//cprintf("total page = %x\n", i);
//	panic("test 4\n");
}
f0100d2e:	5b                   	pop    %ebx
f0100d2f:	5e                   	pop    %esi
f0100d30:	5d                   	pop    %ebp
f0100d31:	c3                   	ret    

f0100d32 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d32:	55                   	push   %ebp
f0100d33:	89 e5                	mov    %esp,%ebp
f0100d35:	53                   	push   %ebx
f0100d36:	83 ec 14             	sub    $0x14,%esp
	// Fill this function in
	struct PageInfo *result;
	if (page_free_list == NULL) {
f0100d39:	8b 1d 40 f5 11 f0    	mov    0xf011f540,%ebx
f0100d3f:	85 db                	test   %ebx,%ebx
f0100d41:	74 6b                	je     f0100dae <page_alloc+0x7c>
		return NULL;
	}
	result = page_free_list;
	page_free_list = result->pp_link;
f0100d43:	8b 03                	mov    (%ebx),%eax
f0100d45:	a3 40 f5 11 f0       	mov    %eax,0xf011f540
	result->pp_link = NULL;
f0100d4a:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags & ALLOC_ZERO) {
f0100d50:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100d54:	74 58                	je     f0100dae <page_alloc+0x7c>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d56:	89 d8                	mov    %ebx,%eax
f0100d58:	2b 05 6c f9 11 f0    	sub    0xf011f96c,%eax
f0100d5e:	c1 f8 03             	sar    $0x3,%eax
f0100d61:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d64:	89 c2                	mov    %eax,%edx
f0100d66:	c1 ea 0c             	shr    $0xc,%edx
f0100d69:	3b 15 64 f9 11 f0    	cmp    0xf011f964,%edx
f0100d6f:	72 20                	jb     f0100d91 <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d71:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d75:	c7 44 24 08 8c 40 10 	movl   $0xf010408c,0x8(%esp)
f0100d7c:	f0 
f0100d7d:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100d84:	00 
f0100d85:	c7 04 24 4f 48 10 f0 	movl   $0xf010484f,(%esp)
f0100d8c:	e8 03 f3 ff ff       	call   f0100094 <_panic>
//		cprintf("alloc va addr = %x\n",page2kva(result));
		memset(page2kva(result), 0, PGSIZE);
f0100d91:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100d98:	00 
f0100d99:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100da0:	00 
	return (void *)(pa + KERNBASE);
f0100da1:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100da6:	89 04 24             	mov    %eax,(%esp)
f0100da9:	e8 08 2a 00 00       	call   f01037b6 <memset>
	}
	return result;
}
f0100dae:	89 d8                	mov    %ebx,%eax
f0100db0:	83 c4 14             	add    $0x14,%esp
f0100db3:	5b                   	pop    %ebx
f0100db4:	5d                   	pop    %ebp
f0100db5:	c3                   	ret    

f0100db6 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100db6:	55                   	push   %ebp
f0100db7:	89 e5                	mov    %esp,%ebp
f0100db9:	83 ec 18             	sub    $0x18,%esp
f0100dbc:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	assert(pp->pp_ref == 0); 
f0100dbf:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100dc4:	74 24                	je     f0100dea <page_free+0x34>
f0100dc6:	c7 44 24 0c f9 48 10 	movl   $0xf01048f9,0xc(%esp)
f0100dcd:	f0 
f0100dce:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0100dd5:	f0 
f0100dd6:	c7 44 24 04 4d 01 00 	movl   $0x14d,0x4(%esp)
f0100ddd:	00 
f0100dde:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0100de5:	e8 aa f2 ff ff       	call   f0100094 <_panic>
	assert(pp->pp_link == NULL);
f0100dea:	83 38 00             	cmpl   $0x0,(%eax)
f0100ded:	74 24                	je     f0100e13 <page_free+0x5d>
f0100def:	c7 44 24 0c 09 49 10 	movl   $0xf0104909,0xc(%esp)
f0100df6:	f0 
f0100df7:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0100dfe:	f0 
f0100dff:	c7 44 24 04 4e 01 00 	movl   $0x14e,0x4(%esp)
f0100e06:	00 
f0100e07:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0100e0e:	e8 81 f2 ff ff       	call   f0100094 <_panic>
	
	pp->pp_link = page_free_list;
f0100e13:	8b 15 40 f5 11 f0    	mov    0xf011f540,%edx
f0100e19:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100e1b:	a3 40 f5 11 f0       	mov    %eax,0xf011f540
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	// pp->pp_link is not NULL.
}
f0100e20:	c9                   	leave  
f0100e21:	c3                   	ret    

f0100e22 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e22:	55                   	push   %ebp
f0100e23:	89 e5                	mov    %esp,%ebp
f0100e25:	83 ec 18             	sub    $0x18,%esp
f0100e28:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100e2b:	8b 50 04             	mov    0x4(%eax),%edx
f0100e2e:	4a                   	dec    %edx
f0100e2f:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100e33:	66 85 d2             	test   %dx,%dx
f0100e36:	75 08                	jne    f0100e40 <page_decref+0x1e>
		page_free(pp);
f0100e38:	89 04 24             	mov    %eax,(%esp)
f0100e3b:	e8 76 ff ff ff       	call   f0100db6 <page_free>
}
f0100e40:	c9                   	leave  
f0100e41:	c3                   	ret    

f0100e42 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e42:	55                   	push   %ebp
f0100e43:	89 e5                	mov    %esp,%ebp
f0100e45:	56                   	push   %esi
f0100e46:	53                   	push   %ebx
f0100e47:	83 ec 10             	sub    $0x10,%esp
f0100e4a:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	pde_t pde = pgdir[PDX(va)];
f0100e4d:	89 f3                	mov    %esi,%ebx
f0100e4f:	c1 eb 16             	shr    $0x16,%ebx
f0100e52:	c1 e3 02             	shl    $0x2,%ebx
f0100e55:	03 5d 08             	add    0x8(%ebp),%ebx
f0100e58:	8b 03                	mov    (%ebx),%eax
	if (pde & PTE_P)
f0100e5a:	a8 01                	test   $0x1,%al
f0100e5c:	74 47                	je     f0100ea5 <pgdir_walk+0x63>
	{
		return (pte_t *) KADDR(PTE_ADDR(pde)) + PTX(va);
f0100e5e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e63:	89 c2                	mov    %eax,%edx
f0100e65:	c1 ea 0c             	shr    $0xc,%edx
f0100e68:	3b 15 64 f9 11 f0    	cmp    0xf011f964,%edx
f0100e6e:	72 20                	jb     f0100e90 <pgdir_walk+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e70:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e74:	c7 44 24 08 8c 40 10 	movl   $0xf010408c,0x8(%esp)
f0100e7b:	f0 
f0100e7c:	c7 44 24 04 7e 01 00 	movl   $0x17e,0x4(%esp)
f0100e83:	00 
f0100e84:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0100e8b:	e8 04 f2 ff ff       	call   f0100094 <_panic>
f0100e90:	c1 ee 0a             	shr    $0xa,%esi
f0100e93:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0100e99:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0100ea0:	e9 84 00 00 00       	jmp    f0100f29 <pgdir_walk+0xe7>
	}

	if (create)
f0100ea5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100ea9:	74 72                	je     f0100f1d <pgdir_walk+0xdb>
	{
		struct PageInfo *pp = page_alloc(ALLOC_ZERO);
f0100eab:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0100eb2:	e8 7b fe ff ff       	call   f0100d32 <page_alloc>
		if (!pp)
f0100eb7:	85 c0                	test   %eax,%eax
f0100eb9:	74 69                	je     f0100f24 <pgdir_walk+0xe2>
		{
			return NULL;
		}
		pp->pp_ref ++;
f0100ebb:	66 ff 40 04          	incw   0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ebf:	89 c2                	mov    %eax,%edx
f0100ec1:	2b 15 6c f9 11 f0    	sub    0xf011f96c,%edx
f0100ec7:	c1 fa 03             	sar    $0x3,%edx
f0100eca:	c1 e2 0c             	shl    $0xc,%edx
		pgdir[PDX(va)] = page2pa(pp) | PTE_P | PTE_W | PTE_U;
f0100ecd:	83 ca 07             	or     $0x7,%edx
f0100ed0:	89 13                	mov    %edx,(%ebx)
f0100ed2:	2b 05 6c f9 11 f0    	sub    0xf011f96c,%eax
f0100ed8:	c1 f8 03             	sar    $0x3,%eax
f0100edb:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ede:	89 c2                	mov    %eax,%edx
f0100ee0:	c1 ea 0c             	shr    $0xc,%edx
f0100ee3:	3b 15 64 f9 11 f0    	cmp    0xf011f964,%edx
f0100ee9:	72 20                	jb     f0100f0b <pgdir_walk+0xc9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100eeb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100eef:	c7 44 24 08 8c 40 10 	movl   $0xf010408c,0x8(%esp)
f0100ef6:	f0 
f0100ef7:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100efe:	00 
f0100eff:	c7 04 24 4f 48 10 f0 	movl   $0xf010484f,(%esp)
f0100f06:	e8 89 f1 ff ff       	call   f0100094 <_panic>
		return (pte_t *) page2kva(pp) + PTX(va);
f0100f0b:	c1 ee 0a             	shr    $0xa,%esi
f0100f0e:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0100f14:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0100f1b:	eb 0c                	jmp    f0100f29 <pgdir_walk+0xe7>
	}
	else
	{
		return NULL;
f0100f1d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f22:	eb 05                	jmp    f0100f29 <pgdir_walk+0xe7>
	if (create)
	{
		struct PageInfo *pp = page_alloc(ALLOC_ZERO);
		if (!pp)
		{
			return NULL;
f0100f24:	b8 00 00 00 00       	mov    $0x0,%eax
	}
	else
	{
		return NULL;
	}
}
f0100f29:	83 c4 10             	add    $0x10,%esp
f0100f2c:	5b                   	pop    %ebx
f0100f2d:	5e                   	pop    %esi
f0100f2e:	5d                   	pop    %ebp
f0100f2f:	c3                   	ret    

f0100f30 <boot_map_region>:
// mapped pages.
//
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0100f30:	55                   	push   %ebp
f0100f31:	89 e5                	mov    %esp,%ebp
f0100f33:	57                   	push   %edi
f0100f34:	56                   	push   %esi
f0100f35:	53                   	push   %ebx
f0100f36:	83 ec 2c             	sub    $0x2c,%esp
f0100f39:	89 c7                	mov    %eax,%edi
f0100f3b:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0100f3e:	8b 75 08             	mov    0x8(%ebp),%esi
	// Fill this function in
//	size_t index = 0;
	uintptr_t va_start = va;
	uintptr_t va_end = va + size;
f0100f41:	01 d1                	add    %edx,%ecx
f0100f43:	89 4d e0             	mov    %ecx,-0x20(%ebp)
	//cprintf("size = %x, PGSIZE = %x\n", size, PGSIZE);
	for (; va < va_end && va >= va_start; va += PGSIZE, pa += PGSIZE)
f0100f46:	89 d3                	mov    %edx,%ebx
	{
		cprintf("va = %x\n", (uint32_t)va);
		pte_t *pte = pgdir_walk(pgdir, (void *)va, true);
		*pte = pa | perm | PTE_P;
f0100f48:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f4b:	83 c8 01             	or     $0x1,%eax
f0100f4e:	89 45 dc             	mov    %eax,-0x24(%ebp)
	// Fill this function in
//	size_t index = 0;
	uintptr_t va_start = va;
	uintptr_t va_end = va + size;
	//cprintf("size = %x, PGSIZE = %x\n", size, PGSIZE);
	for (; va < va_end && va >= va_start; va += PGSIZE, pa += PGSIZE)
f0100f51:	eb 37                	jmp    f0100f8a <boot_map_region+0x5a>
	{
		cprintf("va = %x\n", (uint32_t)va);
f0100f53:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f57:	c7 04 24 1d 49 10 f0 	movl   $0xf010491d,(%esp)
f0100f5e:	e8 e7 1d 00 00       	call   f0102d4a <cprintf>
		pte_t *pte = pgdir_walk(pgdir, (void *)va, true);
f0100f63:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0100f6a:	00 
f0100f6b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100f6f:	89 3c 24             	mov    %edi,(%esp)
f0100f72:	e8 cb fe ff ff       	call   f0100e42 <pgdir_walk>
		*pte = pa | perm | PTE_P;
f0100f77:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100f7a:	09 f2                	or     %esi,%edx
f0100f7c:	89 10                	mov    %edx,(%eax)
	// Fill this function in
//	size_t index = 0;
	uintptr_t va_start = va;
	uintptr_t va_end = va + size;
	//cprintf("size = %x, PGSIZE = %x\n", size, PGSIZE);
	for (; va < va_end && va >= va_start; va += PGSIZE, pa += PGSIZE)
f0100f7e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100f84:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0100f8a:	3b 5d e0             	cmp    -0x20(%ebp),%ebx
f0100f8d:	73 05                	jae    f0100f94 <boot_map_region+0x64>
f0100f8f:	3b 5d e4             	cmp    -0x1c(%ebp),%ebx
f0100f92:	73 bf                	jae    f0100f53 <boot_map_region+0x23>
	{
		cprintf("va = %x\n", (uint32_t)va);
		pte_t *pte = pgdir_walk(pgdir, (void *)va, true);
		*pte = pa | perm | PTE_P;
	}
}
f0100f94:	83 c4 2c             	add    $0x2c,%esp
f0100f97:	5b                   	pop    %ebx
f0100f98:	5e                   	pop    %esi
f0100f99:	5f                   	pop    %edi
f0100f9a:	5d                   	pop    %ebp
f0100f9b:	c3                   	ret    

f0100f9c <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
	struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100f9c:	55                   	push   %ebp
f0100f9d:	89 e5                	mov    %esp,%ebp
f0100f9f:	53                   	push   %ebx
f0100fa0:	83 ec 14             	sub    $0x14,%esp
f0100fa3:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, false);
f0100fa6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100fad:	00 
f0100fae:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100fb1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100fb5:	8b 45 08             	mov    0x8(%ebp),%eax
f0100fb8:	89 04 24             	mov    %eax,(%esp)
f0100fbb:	e8 82 fe ff ff       	call   f0100e42 <pgdir_walk>
	if (*pte & PTE_P && NULL != pte)
f0100fc0:	f6 00 01             	testb  $0x1,(%eax)
f0100fc3:	74 3e                	je     f0101003 <page_lookup+0x67>
f0100fc5:	85 c0                	test   %eax,%eax
f0100fc7:	74 41                	je     f010100a <page_lookup+0x6e>
	{
		*pte_store = pte;
f0100fc9:	89 03                	mov    %eax,(%ebx)
		if (NULL == pte_store)
f0100fcb:	85 db                	test   %ebx,%ebx
f0100fcd:	74 42                	je     f0101011 <page_lookup+0x75>
		{
			return NULL;
		}
		return pa2page(PTE_ADDR(*pte));
f0100fcf:	8b 00                	mov    (%eax),%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fd1:	c1 e8 0c             	shr    $0xc,%eax
f0100fd4:	3b 05 64 f9 11 f0    	cmp    0xf011f964,%eax
f0100fda:	72 1c                	jb     f0100ff8 <page_lookup+0x5c>
		panic("pa2page called with invalid pa");
f0100fdc:	c7 44 24 08 9c 41 10 	movl   $0xf010419c,0x8(%esp)
f0100fe3:	f0 
f0100fe4:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f0100feb:	00 
f0100fec:	c7 04 24 4f 48 10 f0 	movl   $0xf010484f,(%esp)
f0100ff3:	e8 9c f0 ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f0100ff8:	c1 e0 03             	shl    $0x3,%eax
f0100ffb:	03 05 6c f9 11 f0    	add    0xf011f96c,%eax
f0101001:	eb 13                	jmp    f0101016 <page_lookup+0x7a>
	}
	else {
		return NULL;
f0101003:	b8 00 00 00 00       	mov    $0x0,%eax
f0101008:	eb 0c                	jmp    f0101016 <page_lookup+0x7a>
f010100a:	b8 00 00 00 00       	mov    $0x0,%eax
f010100f:	eb 05                	jmp    f0101016 <page_lookup+0x7a>
	if (*pte & PTE_P && NULL != pte)
	{
		*pte_store = pte;
		if (NULL == pte_store)
		{
			return NULL;
f0101011:	b8 00 00 00 00       	mov    $0x0,%eax
		return pa2page(PTE_ADDR(*pte));
	}
	else {
		return NULL;
	}
}
f0101016:	83 c4 14             	add    $0x14,%esp
f0101019:	5b                   	pop    %ebx
f010101a:	5d                   	pop    %ebp
f010101b:	c3                   	ret    

f010101c <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
	void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010101c:	55                   	push   %ebp
f010101d:	89 e5                	mov    %esp,%ebp
}

static inline void
invlpg(void *addr)
{
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010101f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101022:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0101025:	5d                   	pop    %ebp
f0101026:	c3                   	ret    

f0101027 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
	void
page_remove(pde_t *pgdir, void *va)
{
f0101027:	55                   	push   %ebp
f0101028:	89 e5                	mov    %esp,%ebp
f010102a:	56                   	push   %esi
f010102b:	53                   	push   %ebx
f010102c:	83 ec 20             	sub    $0x20,%esp
f010102f:	8b 75 08             	mov    0x8(%ebp),%esi
f0101032:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *pte;
	struct PageInfo *pp = page_lookup(pgdir, va, &pte);
f0101035:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101038:	89 44 24 08          	mov    %eax,0x8(%esp)
f010103c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101040:	89 34 24             	mov    %esi,(%esp)
f0101043:	e8 54 ff ff ff       	call   f0100f9c <page_lookup>
	if (pp != NULL)
f0101048:	85 c0                	test   %eax,%eax
f010104a:	74 1d                	je     f0101069 <page_remove+0x42>
	{
		page_decref(pp);
f010104c:	89 04 24             	mov    %eax,(%esp)
f010104f:	e8 ce fd ff ff       	call   f0100e22 <page_decref>
		*pte = 0;
f0101054:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101057:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		tlb_invalidate(pgdir, va);
f010105d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101061:	89 34 24             	mov    %esi,(%esp)
f0101064:	e8 b3 ff ff ff       	call   f010101c <tlb_invalidate>
	}
}
f0101069:	83 c4 20             	add    $0x20,%esp
f010106c:	5b                   	pop    %ebx
f010106d:	5e                   	pop    %esi
f010106e:	5d                   	pop    %ebp
f010106f:	c3                   	ret    

f0101070 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
	int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101070:	55                   	push   %ebp
f0101071:	89 e5                	mov    %esp,%ebp
f0101073:	57                   	push   %edi
f0101074:	56                   	push   %esi
f0101075:	53                   	push   %ebx
f0101076:	83 ec 1c             	sub    $0x1c,%esp
f0101079:	8b 7d 08             	mov    0x8(%ebp),%edi
f010107c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, true);
f010107f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101086:	00 
f0101087:	8b 45 10             	mov    0x10(%ebp),%eax
f010108a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010108e:	89 3c 24             	mov    %edi,(%esp)
f0101091:	e8 ac fd ff ff       	call   f0100e42 <pgdir_walk>
f0101096:	89 c6                	mov    %eax,%esi
	if (NULL == pte)
f0101098:	85 c0                	test   %eax,%eax
f010109a:	74 50                	je     f01010ec <page_insert+0x7c>
	{
		return -E_NO_MEM;
	}
	pp->pp_ref++; 
f010109c:	66 ff 43 04          	incw   0x4(%ebx)
	if(*pte & PTE_P)
f01010a0:	f6 00 01             	testb  $0x1,(%eax)
f01010a3:	74 1e                	je     f01010c3 <page_insert+0x53>
	{
		tlb_invalidate(pgdir, va);
f01010a5:	8b 55 10             	mov    0x10(%ebp),%edx
f01010a8:	89 54 24 04          	mov    %edx,0x4(%esp)
f01010ac:	89 3c 24             	mov    %edi,(%esp)
f01010af:	e8 68 ff ff ff       	call   f010101c <tlb_invalidate>
		page_remove(pgdir, va);
f01010b4:	8b 45 10             	mov    0x10(%ebp),%eax
f01010b7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010bb:	89 3c 24             	mov    %edi,(%esp)
f01010be:	e8 64 ff ff ff       	call   f0101027 <page_remove>
	}
	*pte = page2pa(pp) | perm | PTE_P;
f01010c3:	8b 45 14             	mov    0x14(%ebp),%eax
f01010c6:	83 c8 01             	or     $0x1,%eax
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01010c9:	2b 1d 6c f9 11 f0    	sub    0xf011f96c,%ebx
f01010cf:	c1 fb 03             	sar    $0x3,%ebx
f01010d2:	c1 e3 0c             	shl    $0xc,%ebx
f01010d5:	09 c3                	or     %eax,%ebx
f01010d7:	89 1e                	mov    %ebx,(%esi)
	pgdir[PDX(va)] |= perm;
f01010d9:	8b 45 10             	mov    0x10(%ebp),%eax
f01010dc:	c1 e8 16             	shr    $0x16,%eax
f01010df:	8b 55 14             	mov    0x14(%ebp),%edx
f01010e2:	09 14 87             	or     %edx,(%edi,%eax,4)
	return 0;
f01010e5:	b8 00 00 00 00       	mov    $0x0,%eax
f01010ea:	eb 05                	jmp    f01010f1 <page_insert+0x81>
{
	// Fill this function in
	pte_t *pte = pgdir_walk(pgdir, va, true);
	if (NULL == pte)
	{
		return -E_NO_MEM;
f01010ec:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		page_remove(pgdir, va);
	}
	*pte = page2pa(pp) | perm | PTE_P;
	pgdir[PDX(va)] |= perm;
	return 0;
}
f01010f1:	83 c4 1c             	add    $0x1c,%esp
f01010f4:	5b                   	pop    %ebx
f01010f5:	5e                   	pop    %esi
f01010f6:	5f                   	pop    %edi
f01010f7:	5d                   	pop    %ebp
f01010f8:	c3                   	ret    

f01010f9 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01010f9:	55                   	push   %ebp
f01010fa:	89 e5                	mov    %esp,%ebp
f01010fc:	57                   	push   %edi
f01010fd:	56                   	push   %esi
f01010fe:	53                   	push   %ebx
f01010ff:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t basemem, extmem, ext16mem, totalmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	basemem = nvram_read(NVRAM_BASELO);
f0101102:	b8 15 00 00 00       	mov    $0x15,%eax
f0101107:	e8 08 f8 ff ff       	call   f0100914 <nvram_read>
f010110c:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f010110e:	b8 17 00 00 00       	mov    $0x17,%eax
f0101113:	e8 fc f7 ff ff       	call   f0100914 <nvram_read>
f0101118:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f010111a:	b8 34 00 00 00       	mov    $0x34,%eax
f010111f:	e8 f0 f7 ff ff       	call   f0100914 <nvram_read>

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (ext16mem)
f0101124:	c1 e0 06             	shl    $0x6,%eax
f0101127:	74 08                	je     f0101131 <mem_init+0x38>
		totalmem = 16 * 1024 + ext16mem;
f0101129:	8d b0 00 40 00 00    	lea    0x4000(%eax),%esi
f010112f:	eb 0e                	jmp    f010113f <mem_init+0x46>
	else if (extmem)
f0101131:	85 f6                	test   %esi,%esi
f0101133:	74 08                	je     f010113d <mem_init+0x44>
		totalmem = 1 * 1024 + extmem;
f0101135:	81 c6 00 04 00 00    	add    $0x400,%esi
f010113b:	eb 02                	jmp    f010113f <mem_init+0x46>
	else
		totalmem = basemem;
f010113d:	89 de                	mov    %ebx,%esi

	npages = totalmem / (PGSIZE / 1024);
f010113f:	89 f0                	mov    %esi,%eax
f0101141:	c1 e8 02             	shr    $0x2,%eax
f0101144:	a3 64 f9 11 f0       	mov    %eax,0xf011f964
	npages_basemem = basemem / (PGSIZE / 1024);
f0101149:	89 d8                	mov    %ebx,%eax
f010114b:	c1 e8 02             	shr    $0x2,%eax
f010114e:	a3 38 f5 11 f0       	mov    %eax,0xf011f538

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101153:	89 f0                	mov    %esi,%eax
f0101155:	29 d8                	sub    %ebx,%eax
f0101157:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010115b:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f010115f:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101163:	c7 04 24 bc 41 10 f0 	movl   $0xf01041bc,(%esp)
f010116a:	e8 db 1b 00 00       	call   f0102d4a <cprintf>
		totalmem, basemem, totalmem - basemem);
	extern char end[];
	cprintf("end = %x, npages = %x, npages_basemem = %x\n", (uint32_t)end, (uint32_t)npages, (uint32_t)npages_basemem);
f010116f:	a1 38 f5 11 f0       	mov    0xf011f538,%eax
f0101174:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101178:	a1 64 f9 11 f0       	mov    0xf011f964,%eax
f010117d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101181:	c7 44 24 04 70 f9 11 	movl   $0xf011f970,0x4(%esp)
f0101188:	f0 
f0101189:	c7 04 24 f8 41 10 f0 	movl   $0xf01041f8,(%esp)
f0101190:	e8 b5 1b 00 00       	call   f0102d4a <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101195:	b8 00 10 00 00       	mov    $0x1000,%eax
f010119a:	e8 02 f7 ff ff       	call   f01008a1 <boot_alloc>
f010119f:	a3 68 f9 11 f0       	mov    %eax,0xf011f968
	memset(kern_pgdir, 0, PGSIZE);
f01011a4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01011ab:	00 
f01011ac:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01011b3:	00 
f01011b4:	89 04 24             	mov    %eax,(%esp)
f01011b7:	e8 fa 25 00 00       	call   f01037b6 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01011bc:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01011c1:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01011c6:	77 20                	ja     f01011e8 <mem_init+0xef>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01011c8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01011cc:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f01011d3:	f0 
f01011d4:	c7 44 24 04 96 00 00 	movl   $0x96,0x4(%esp)
f01011db:	00 
f01011dc:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f01011e3:	e8 ac ee ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01011e8:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01011ee:	83 ca 05             	or     $0x5,%edx
f01011f1:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Your code goes here:
	pages = (struct PageInfo *) boot_alloc(npages * sizeof(struct PageInfo));
f01011f7:	a1 64 f9 11 f0       	mov    0xf011f964,%eax
f01011fc:	c1 e0 03             	shl    $0x3,%eax
f01011ff:	e8 9d f6 ff ff       	call   f01008a1 <boot_alloc>
f0101204:	a3 6c f9 11 f0       	mov    %eax,0xf011f96c
	//panic("boot_alloc success\n");
	memset(pages, 0, npages * sizeof(struct PageInfo));
f0101209:	8b 15 64 f9 11 f0    	mov    0xf011f964,%edx
f010120f:	c1 e2 03             	shl    $0x3,%edx
f0101212:	89 54 24 08          	mov    %edx,0x8(%esp)
f0101216:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010121d:	00 
f010121e:	89 04 24             	mov    %eax,(%esp)
f0101221:	e8 90 25 00 00       	call   f01037b6 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101226:	e8 53 fa ff ff       	call   f0100c7e <page_init>
	//panic("page_init success");
	check_page_free_list(1);
f010122b:	b8 01 00 00 00       	mov    $0x1,%eax
f0101230:	e8 08 f7 ff ff       	call   f010093d <check_page_free_list>
	struct PageInfo *pp, *pp0, *pp1, *pp2;
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;
	cprintf("check_page_alloc() start!\n");
f0101235:	c7 04 24 26 49 10 f0 	movl   $0xf0104926,(%esp)
f010123c:	e8 09 1b 00 00       	call   f0102d4a <cprintf>
	if (!pages)
f0101241:	83 3d 6c f9 11 f0 00 	cmpl   $0x0,0xf011f96c
f0101248:	75 1c                	jne    f0101266 <mem_init+0x16d>
		panic("'pages' is a null pointer!");
f010124a:	c7 44 24 08 41 49 10 	movl   $0xf0104941,0x8(%esp)
f0101251:	f0 
f0101252:	c7 44 24 04 6f 02 00 	movl   $0x26f,0x4(%esp)
f0101259:	00 
f010125a:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101261:	e8 2e ee ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101266:	a1 40 f5 11 f0       	mov    0xf011f540,%eax
f010126b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101270:	eb 03                	jmp    f0101275 <mem_init+0x17c>
		++nfree;
f0101272:	43                   	inc    %ebx
	cprintf("check_page_alloc() start!\n");
	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101273:	8b 00                	mov    (%eax),%eax
f0101275:	85 c0                	test   %eax,%eax
f0101277:	75 f9                	jne    f0101272 <mem_init+0x179>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101279:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101280:	e8 ad fa ff ff       	call   f0100d32 <page_alloc>
f0101285:	89 c6                	mov    %eax,%esi
f0101287:	85 c0                	test   %eax,%eax
f0101289:	75 24                	jne    f01012af <mem_init+0x1b6>
f010128b:	c7 44 24 0c 5c 49 10 	movl   $0xf010495c,0xc(%esp)
f0101292:	f0 
f0101293:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f010129a:	f0 
f010129b:	c7 44 24 04 77 02 00 	movl   $0x277,0x4(%esp)
f01012a2:	00 
f01012a3:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f01012aa:	e8 e5 ed ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01012af:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01012b6:	e8 77 fa ff ff       	call   f0100d32 <page_alloc>
f01012bb:	89 c7                	mov    %eax,%edi
f01012bd:	85 c0                	test   %eax,%eax
f01012bf:	75 24                	jne    f01012e5 <mem_init+0x1ec>
f01012c1:	c7 44 24 0c 72 49 10 	movl   $0xf0104972,0xc(%esp)
f01012c8:	f0 
f01012c9:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f01012d0:	f0 
f01012d1:	c7 44 24 04 78 02 00 	movl   $0x278,0x4(%esp)
f01012d8:	00 
f01012d9:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f01012e0:	e8 af ed ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01012e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01012ec:	e8 41 fa ff ff       	call   f0100d32 <page_alloc>
f01012f1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01012f4:	85 c0                	test   %eax,%eax
f01012f6:	75 24                	jne    f010131c <mem_init+0x223>
f01012f8:	c7 44 24 0c 88 49 10 	movl   $0xf0104988,0xc(%esp)
f01012ff:	f0 
f0101300:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101307:	f0 
f0101308:	c7 44 24 04 79 02 00 	movl   $0x279,0x4(%esp)
f010130f:	00 
f0101310:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101317:	e8 78 ed ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010131c:	39 fe                	cmp    %edi,%esi
f010131e:	75 24                	jne    f0101344 <mem_init+0x24b>
f0101320:	c7 44 24 0c 9e 49 10 	movl   $0xf010499e,0xc(%esp)
f0101327:	f0 
f0101328:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f010132f:	f0 
f0101330:	c7 44 24 04 7c 02 00 	movl   $0x27c,0x4(%esp)
f0101337:	00 
f0101338:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f010133f:	e8 50 ed ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101344:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101347:	74 05                	je     f010134e <mem_init+0x255>
f0101349:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f010134c:	75 24                	jne    f0101372 <mem_init+0x279>
f010134e:	c7 44 24 0c 48 42 10 	movl   $0xf0104248,0xc(%esp)
f0101355:	f0 
f0101356:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f010135d:	f0 
f010135e:	c7 44 24 04 7d 02 00 	movl   $0x27d,0x4(%esp)
f0101365:	00 
f0101366:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f010136d:	e8 22 ed ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101372:	8b 15 6c f9 11 f0    	mov    0xf011f96c,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101378:	a1 64 f9 11 f0       	mov    0xf011f964,%eax
f010137d:	c1 e0 0c             	shl    $0xc,%eax
f0101380:	89 f1                	mov    %esi,%ecx
f0101382:	29 d1                	sub    %edx,%ecx
f0101384:	c1 f9 03             	sar    $0x3,%ecx
f0101387:	c1 e1 0c             	shl    $0xc,%ecx
f010138a:	39 c1                	cmp    %eax,%ecx
f010138c:	72 24                	jb     f01013b2 <mem_init+0x2b9>
f010138e:	c7 44 24 0c b0 49 10 	movl   $0xf01049b0,0xc(%esp)
f0101395:	f0 
f0101396:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f010139d:	f0 
f010139e:	c7 44 24 04 7e 02 00 	movl   $0x27e,0x4(%esp)
f01013a5:	00 
f01013a6:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f01013ad:	e8 e2 ec ff ff       	call   f0100094 <_panic>
f01013b2:	89 f9                	mov    %edi,%ecx
f01013b4:	29 d1                	sub    %edx,%ecx
f01013b6:	c1 f9 03             	sar    $0x3,%ecx
f01013b9:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f01013bc:	39 c8                	cmp    %ecx,%eax
f01013be:	77 24                	ja     f01013e4 <mem_init+0x2eb>
f01013c0:	c7 44 24 0c cd 49 10 	movl   $0xf01049cd,0xc(%esp)
f01013c7:	f0 
f01013c8:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f01013cf:	f0 
f01013d0:	c7 44 24 04 7f 02 00 	movl   $0x27f,0x4(%esp)
f01013d7:	00 
f01013d8:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f01013df:	e8 b0 ec ff ff       	call   f0100094 <_panic>
f01013e4:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01013e7:	29 d1                	sub    %edx,%ecx
f01013e9:	89 ca                	mov    %ecx,%edx
f01013eb:	c1 fa 03             	sar    $0x3,%edx
f01013ee:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f01013f1:	39 d0                	cmp    %edx,%eax
f01013f3:	77 24                	ja     f0101419 <mem_init+0x320>
f01013f5:	c7 44 24 0c ea 49 10 	movl   $0xf01049ea,0xc(%esp)
f01013fc:	f0 
f01013fd:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101404:	f0 
f0101405:	c7 44 24 04 80 02 00 	movl   $0x280,0x4(%esp)
f010140c:	00 
f010140d:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101414:	e8 7b ec ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101419:	a1 40 f5 11 f0       	mov    0xf011f540,%eax
f010141e:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101421:	c7 05 40 f5 11 f0 00 	movl   $0x0,0xf011f540
f0101428:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010142b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101432:	e8 fb f8 ff ff       	call   f0100d32 <page_alloc>
f0101437:	85 c0                	test   %eax,%eax
f0101439:	74 24                	je     f010145f <mem_init+0x366>
f010143b:	c7 44 24 0c 07 4a 10 	movl   $0xf0104a07,0xc(%esp)
f0101442:	f0 
f0101443:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f010144a:	f0 
f010144b:	c7 44 24 04 87 02 00 	movl   $0x287,0x4(%esp)
f0101452:	00 
f0101453:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f010145a:	e8 35 ec ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f010145f:	89 34 24             	mov    %esi,(%esp)
f0101462:	e8 4f f9 ff ff       	call   f0100db6 <page_free>
	page_free(pp1);
f0101467:	89 3c 24             	mov    %edi,(%esp)
f010146a:	e8 47 f9 ff ff       	call   f0100db6 <page_free>
	page_free(pp2);
f010146f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101472:	89 04 24             	mov    %eax,(%esp)
f0101475:	e8 3c f9 ff ff       	call   f0100db6 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010147a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101481:	e8 ac f8 ff ff       	call   f0100d32 <page_alloc>
f0101486:	89 c6                	mov    %eax,%esi
f0101488:	85 c0                	test   %eax,%eax
f010148a:	75 24                	jne    f01014b0 <mem_init+0x3b7>
f010148c:	c7 44 24 0c 5c 49 10 	movl   $0xf010495c,0xc(%esp)
f0101493:	f0 
f0101494:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f010149b:	f0 
f010149c:	c7 44 24 04 8e 02 00 	movl   $0x28e,0x4(%esp)
f01014a3:	00 
f01014a4:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f01014ab:	e8 e4 eb ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01014b0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014b7:	e8 76 f8 ff ff       	call   f0100d32 <page_alloc>
f01014bc:	89 c7                	mov    %eax,%edi
f01014be:	85 c0                	test   %eax,%eax
f01014c0:	75 24                	jne    f01014e6 <mem_init+0x3ed>
f01014c2:	c7 44 24 0c 72 49 10 	movl   $0xf0104972,0xc(%esp)
f01014c9:	f0 
f01014ca:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f01014d1:	f0 
f01014d2:	c7 44 24 04 8f 02 00 	movl   $0x28f,0x4(%esp)
f01014d9:	00 
f01014da:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f01014e1:	e8 ae eb ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01014e6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014ed:	e8 40 f8 ff ff       	call   f0100d32 <page_alloc>
f01014f2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01014f5:	85 c0                	test   %eax,%eax
f01014f7:	75 24                	jne    f010151d <mem_init+0x424>
f01014f9:	c7 44 24 0c 88 49 10 	movl   $0xf0104988,0xc(%esp)
f0101500:	f0 
f0101501:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101508:	f0 
f0101509:	c7 44 24 04 90 02 00 	movl   $0x290,0x4(%esp)
f0101510:	00 
f0101511:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101518:	e8 77 eb ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010151d:	39 fe                	cmp    %edi,%esi
f010151f:	75 24                	jne    f0101545 <mem_init+0x44c>
f0101521:	c7 44 24 0c 9e 49 10 	movl   $0xf010499e,0xc(%esp)
f0101528:	f0 
f0101529:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101530:	f0 
f0101531:	c7 44 24 04 92 02 00 	movl   $0x292,0x4(%esp)
f0101538:	00 
f0101539:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101540:	e8 4f eb ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101545:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101548:	74 05                	je     f010154f <mem_init+0x456>
f010154a:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f010154d:	75 24                	jne    f0101573 <mem_init+0x47a>
f010154f:	c7 44 24 0c 48 42 10 	movl   $0xf0104248,0xc(%esp)
f0101556:	f0 
f0101557:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f010155e:	f0 
f010155f:	c7 44 24 04 93 02 00 	movl   $0x293,0x4(%esp)
f0101566:	00 
f0101567:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f010156e:	e8 21 eb ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f0101573:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010157a:	e8 b3 f7 ff ff       	call   f0100d32 <page_alloc>
f010157f:	85 c0                	test   %eax,%eax
f0101581:	74 24                	je     f01015a7 <mem_init+0x4ae>
f0101583:	c7 44 24 0c 07 4a 10 	movl   $0xf0104a07,0xc(%esp)
f010158a:	f0 
f010158b:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101592:	f0 
f0101593:	c7 44 24 04 94 02 00 	movl   $0x294,0x4(%esp)
f010159a:	00 
f010159b:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f01015a2:	e8 ed ea ff ff       	call   f0100094 <_panic>
f01015a7:	89 f0                	mov    %esi,%eax
f01015a9:	2b 05 6c f9 11 f0    	sub    0xf011f96c,%eax
f01015af:	c1 f8 03             	sar    $0x3,%eax
f01015b2:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01015b5:	89 c2                	mov    %eax,%edx
f01015b7:	c1 ea 0c             	shr    $0xc,%edx
f01015ba:	3b 15 64 f9 11 f0    	cmp    0xf011f964,%edx
f01015c0:	72 20                	jb     f01015e2 <mem_init+0x4e9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01015c2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01015c6:	c7 44 24 08 8c 40 10 	movl   $0xf010408c,0x8(%esp)
f01015cd:	f0 
f01015ce:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01015d5:	00 
f01015d6:	c7 04 24 4f 48 10 f0 	movl   $0xf010484f,(%esp)
f01015dd:	e8 b2 ea ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01015e2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01015e9:	00 
f01015ea:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01015f1:	00 
	return (void *)(pa + KERNBASE);
f01015f2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01015f7:	89 04 24             	mov    %eax,(%esp)
f01015fa:	e8 b7 21 00 00       	call   f01037b6 <memset>
	page_free(pp0);
f01015ff:	89 34 24             	mov    %esi,(%esp)
f0101602:	e8 af f7 ff ff       	call   f0100db6 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101607:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010160e:	e8 1f f7 ff ff       	call   f0100d32 <page_alloc>
f0101613:	85 c0                	test   %eax,%eax
f0101615:	75 24                	jne    f010163b <mem_init+0x542>
f0101617:	c7 44 24 0c 16 4a 10 	movl   $0xf0104a16,0xc(%esp)
f010161e:	f0 
f010161f:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101626:	f0 
f0101627:	c7 44 24 04 99 02 00 	movl   $0x299,0x4(%esp)
f010162e:	00 
f010162f:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101636:	e8 59 ea ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f010163b:	39 c6                	cmp    %eax,%esi
f010163d:	74 24                	je     f0101663 <mem_init+0x56a>
f010163f:	c7 44 24 0c 34 4a 10 	movl   $0xf0104a34,0xc(%esp)
f0101646:	f0 
f0101647:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f010164e:	f0 
f010164f:	c7 44 24 04 9a 02 00 	movl   $0x29a,0x4(%esp)
f0101656:	00 
f0101657:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f010165e:	e8 31 ea ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101663:	89 f2                	mov    %esi,%edx
f0101665:	2b 15 6c f9 11 f0    	sub    0xf011f96c,%edx
f010166b:	c1 fa 03             	sar    $0x3,%edx
f010166e:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101671:	89 d0                	mov    %edx,%eax
f0101673:	c1 e8 0c             	shr    $0xc,%eax
f0101676:	3b 05 64 f9 11 f0    	cmp    0xf011f964,%eax
f010167c:	72 20                	jb     f010169e <mem_init+0x5a5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010167e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101682:	c7 44 24 08 8c 40 10 	movl   $0xf010408c,0x8(%esp)
f0101689:	f0 
f010168a:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101691:	00 
f0101692:	c7 04 24 4f 48 10 f0 	movl   $0xf010484f,(%esp)
f0101699:	e8 f6 e9 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f010169e:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01016a4:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01016aa:	80 38 00             	cmpb   $0x0,(%eax)
f01016ad:	74 24                	je     f01016d3 <mem_init+0x5da>
f01016af:	c7 44 24 0c 44 4a 10 	movl   $0xf0104a44,0xc(%esp)
f01016b6:	f0 
f01016b7:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f01016be:	f0 
f01016bf:	c7 44 24 04 9d 02 00 	movl   $0x29d,0x4(%esp)
f01016c6:	00 
f01016c7:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f01016ce:	e8 c1 e9 ff ff       	call   f0100094 <_panic>
f01016d3:	40                   	inc    %eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01016d4:	39 d0                	cmp    %edx,%eax
f01016d6:	75 d2                	jne    f01016aa <mem_init+0x5b1>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01016d8:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01016db:	89 15 40 f5 11 f0    	mov    %edx,0xf011f540

	// free the pages we took
	page_free(pp0);
f01016e1:	89 34 24             	mov    %esi,(%esp)
f01016e4:	e8 cd f6 ff ff       	call   f0100db6 <page_free>
	page_free(pp1);
f01016e9:	89 3c 24             	mov    %edi,(%esp)
f01016ec:	e8 c5 f6 ff ff       	call   f0100db6 <page_free>
	page_free(pp2);
f01016f1:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01016f4:	89 04 24             	mov    %eax,(%esp)
f01016f7:	e8 ba f6 ff ff       	call   f0100db6 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01016fc:	a1 40 f5 11 f0       	mov    0xf011f540,%eax
f0101701:	eb 03                	jmp    f0101706 <mem_init+0x60d>
		--nfree;
f0101703:	4b                   	dec    %ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101704:	8b 00                	mov    (%eax),%eax
f0101706:	85 c0                	test   %eax,%eax
f0101708:	75 f9                	jne    f0101703 <mem_init+0x60a>
		--nfree;
	assert(nfree == 0);
f010170a:	85 db                	test   %ebx,%ebx
f010170c:	74 24                	je     f0101732 <mem_init+0x639>
f010170e:	c7 44 24 0c 4e 4a 10 	movl   $0xf0104a4e,0xc(%esp)
f0101715:	f0 
f0101716:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f010171d:	f0 
f010171e:	c7 44 24 04 aa 02 00 	movl   $0x2aa,0x4(%esp)
f0101725:	00 
f0101726:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f010172d:	e8 62 e9 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101732:	c7 04 24 68 42 10 f0 	movl   $0xf0104268,(%esp)
f0101739:	e8 0c 16 00 00       	call   f0102d4a <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010173e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101745:	e8 e8 f5 ff ff       	call   f0100d32 <page_alloc>
f010174a:	89 c7                	mov    %eax,%edi
f010174c:	85 c0                	test   %eax,%eax
f010174e:	75 24                	jne    f0101774 <mem_init+0x67b>
f0101750:	c7 44 24 0c 5c 49 10 	movl   $0xf010495c,0xc(%esp)
f0101757:	f0 
f0101758:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f010175f:	f0 
f0101760:	c7 44 24 04 03 03 00 	movl   $0x303,0x4(%esp)
f0101767:	00 
f0101768:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f010176f:	e8 20 e9 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101774:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010177b:	e8 b2 f5 ff ff       	call   f0100d32 <page_alloc>
f0101780:	89 c6                	mov    %eax,%esi
f0101782:	85 c0                	test   %eax,%eax
f0101784:	75 24                	jne    f01017aa <mem_init+0x6b1>
f0101786:	c7 44 24 0c 72 49 10 	movl   $0xf0104972,0xc(%esp)
f010178d:	f0 
f010178e:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101795:	f0 
f0101796:	c7 44 24 04 04 03 00 	movl   $0x304,0x4(%esp)
f010179d:	00 
f010179e:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f01017a5:	e8 ea e8 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01017aa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017b1:	e8 7c f5 ff ff       	call   f0100d32 <page_alloc>
f01017b6:	89 c3                	mov    %eax,%ebx
f01017b8:	85 c0                	test   %eax,%eax
f01017ba:	75 24                	jne    f01017e0 <mem_init+0x6e7>
f01017bc:	c7 44 24 0c 88 49 10 	movl   $0xf0104988,0xc(%esp)
f01017c3:	f0 
f01017c4:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f01017cb:	f0 
f01017cc:	c7 44 24 04 05 03 00 	movl   $0x305,0x4(%esp)
f01017d3:	00 
f01017d4:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f01017db:	e8 b4 e8 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01017e0:	39 f7                	cmp    %esi,%edi
f01017e2:	75 24                	jne    f0101808 <mem_init+0x70f>
f01017e4:	c7 44 24 0c 9e 49 10 	movl   $0xf010499e,0xc(%esp)
f01017eb:	f0 
f01017ec:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f01017f3:	f0 
f01017f4:	c7 44 24 04 08 03 00 	movl   $0x308,0x4(%esp)
f01017fb:	00 
f01017fc:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101803:	e8 8c e8 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101808:	39 c6                	cmp    %eax,%esi
f010180a:	74 04                	je     f0101810 <mem_init+0x717>
f010180c:	39 c7                	cmp    %eax,%edi
f010180e:	75 24                	jne    f0101834 <mem_init+0x73b>
f0101810:	c7 44 24 0c 48 42 10 	movl   $0xf0104248,0xc(%esp)
f0101817:	f0 
f0101818:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f010181f:	f0 
f0101820:	c7 44 24 04 09 03 00 	movl   $0x309,0x4(%esp)
f0101827:	00 
f0101828:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f010182f:	e8 60 e8 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101834:	8b 15 40 f5 11 f0    	mov    0xf011f540,%edx
f010183a:	89 55 cc             	mov    %edx,-0x34(%ebp)
	page_free_list = 0;
f010183d:	c7 05 40 f5 11 f0 00 	movl   $0x0,0xf011f540
f0101844:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101847:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010184e:	e8 df f4 ff ff       	call   f0100d32 <page_alloc>
f0101853:	85 c0                	test   %eax,%eax
f0101855:	74 24                	je     f010187b <mem_init+0x782>
f0101857:	c7 44 24 0c 07 4a 10 	movl   $0xf0104a07,0xc(%esp)
f010185e:	f0 
f010185f:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101866:	f0 
f0101867:	c7 44 24 04 10 03 00 	movl   $0x310,0x4(%esp)
f010186e:	00 
f010186f:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101876:	e8 19 e8 ff ff       	call   f0100094 <_panic>
	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010187b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010187e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101882:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101889:	00 
f010188a:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f010188f:	89 04 24             	mov    %eax,(%esp)
f0101892:	e8 05 f7 ff ff       	call   f0100f9c <page_lookup>
f0101897:	85 c0                	test   %eax,%eax
f0101899:	74 24                	je     f01018bf <mem_init+0x7c6>
f010189b:	c7 44 24 0c 88 42 10 	movl   $0xf0104288,0xc(%esp)
f01018a2:	f0 
f01018a3:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f01018aa:	f0 
f01018ab:	c7 44 24 04 12 03 00 	movl   $0x312,0x4(%esp)
f01018b2:	00 
f01018b3:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f01018ba:	e8 d5 e7 ff ff       	call   f0100094 <_panic>
	//panic("lookup success\n");
	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f01018bf:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01018c6:	00 
f01018c7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01018ce:	00 
f01018cf:	89 74 24 04          	mov    %esi,0x4(%esp)
f01018d3:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f01018d8:	89 04 24             	mov    %eax,(%esp)
f01018db:	e8 90 f7 ff ff       	call   f0101070 <page_insert>
f01018e0:	85 c0                	test   %eax,%eax
f01018e2:	78 24                	js     f0101908 <mem_init+0x80f>
f01018e4:	c7 44 24 0c c0 42 10 	movl   $0xf01042c0,0xc(%esp)
f01018eb:	f0 
f01018ec:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f01018f3:	f0 
f01018f4:	c7 44 24 04 15 03 00 	movl   $0x315,0x4(%esp)
f01018fb:	00 
f01018fc:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101903:	e8 8c e7 ff ff       	call   f0100094 <_panic>
	//panic("insert success\n");
	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101908:	89 3c 24             	mov    %edi,(%esp)
f010190b:	e8 a6 f4 ff ff       	call   f0100db6 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101910:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101917:	00 
f0101918:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010191f:	00 
f0101920:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101924:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f0101929:	89 04 24             	mov    %eax,(%esp)
f010192c:	e8 3f f7 ff ff       	call   f0101070 <page_insert>
f0101931:	85 c0                	test   %eax,%eax
f0101933:	74 24                	je     f0101959 <mem_init+0x860>
f0101935:	c7 44 24 0c f0 42 10 	movl   $0xf01042f0,0xc(%esp)
f010193c:	f0 
f010193d:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101944:	f0 
f0101945:	c7 44 24 04 19 03 00 	movl   $0x319,0x4(%esp)
f010194c:	00 
f010194d:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101954:	e8 3b e7 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101959:	8b 0d 68 f9 11 f0    	mov    0xf011f968,%ecx
f010195f:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101962:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
f0101967:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010196a:	8b 11                	mov    (%ecx),%edx
f010196c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101972:	89 f8                	mov    %edi,%eax
f0101974:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101977:	c1 f8 03             	sar    $0x3,%eax
f010197a:	c1 e0 0c             	shl    $0xc,%eax
f010197d:	39 c2                	cmp    %eax,%edx
f010197f:	74 24                	je     f01019a5 <mem_init+0x8ac>
f0101981:	c7 44 24 0c 20 43 10 	movl   $0xf0104320,0xc(%esp)
f0101988:	f0 
f0101989:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101990:	f0 
f0101991:	c7 44 24 04 1a 03 00 	movl   $0x31a,0x4(%esp)
f0101998:	00 
f0101999:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f01019a0:	e8 ef e6 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01019a5:	ba 00 00 00 00       	mov    $0x0,%edx
f01019aa:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019ad:	e8 82 ee ff ff       	call   f0100834 <check_va2pa>
f01019b2:	89 f2                	mov    %esi,%edx
f01019b4:	2b 55 d0             	sub    -0x30(%ebp),%edx
f01019b7:	c1 fa 03             	sar    $0x3,%edx
f01019ba:	c1 e2 0c             	shl    $0xc,%edx
f01019bd:	39 d0                	cmp    %edx,%eax
f01019bf:	74 24                	je     f01019e5 <mem_init+0x8ec>
f01019c1:	c7 44 24 0c 48 43 10 	movl   $0xf0104348,0xc(%esp)
f01019c8:	f0 
f01019c9:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f01019d0:	f0 
f01019d1:	c7 44 24 04 1b 03 00 	movl   $0x31b,0x4(%esp)
f01019d8:	00 
f01019d9:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f01019e0:	e8 af e6 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f01019e5:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01019ea:	74 24                	je     f0101a10 <mem_init+0x917>
f01019ec:	c7 44 24 0c 59 4a 10 	movl   $0xf0104a59,0xc(%esp)
f01019f3:	f0 
f01019f4:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f01019fb:	f0 
f01019fc:	c7 44 24 04 1c 03 00 	movl   $0x31c,0x4(%esp)
f0101a03:	00 
f0101a04:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101a0b:	e8 84 e6 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101a10:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101a15:	74 24                	je     f0101a3b <mem_init+0x942>
f0101a17:	c7 44 24 0c 6a 4a 10 	movl   $0xf0104a6a,0xc(%esp)
f0101a1e:	f0 
f0101a1f:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101a26:	f0 
f0101a27:	c7 44 24 04 1d 03 00 	movl   $0x31d,0x4(%esp)
f0101a2e:	00 
f0101a2f:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101a36:	e8 59 e6 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101a3b:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101a42:	00 
f0101a43:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101a4a:	00 
f0101a4b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101a4f:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101a52:	89 14 24             	mov    %edx,(%esp)
f0101a55:	e8 16 f6 ff ff       	call   f0101070 <page_insert>
f0101a5a:	85 c0                	test   %eax,%eax
f0101a5c:	74 24                	je     f0101a82 <mem_init+0x989>
f0101a5e:	c7 44 24 0c 78 43 10 	movl   $0xf0104378,0xc(%esp)
f0101a65:	f0 
f0101a66:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101a6d:	f0 
f0101a6e:	c7 44 24 04 20 03 00 	movl   $0x320,0x4(%esp)
f0101a75:	00 
f0101a76:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101a7d:	e8 12 e6 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101a82:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101a87:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f0101a8c:	e8 a3 ed ff ff       	call   f0100834 <check_va2pa>
f0101a91:	89 da                	mov    %ebx,%edx
f0101a93:	2b 15 6c f9 11 f0    	sub    0xf011f96c,%edx
f0101a99:	c1 fa 03             	sar    $0x3,%edx
f0101a9c:	c1 e2 0c             	shl    $0xc,%edx
f0101a9f:	39 d0                	cmp    %edx,%eax
f0101aa1:	74 24                	je     f0101ac7 <mem_init+0x9ce>
f0101aa3:	c7 44 24 0c b4 43 10 	movl   $0xf01043b4,0xc(%esp)
f0101aaa:	f0 
f0101aab:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101ab2:	f0 
f0101ab3:	c7 44 24 04 21 03 00 	movl   $0x321,0x4(%esp)
f0101aba:	00 
f0101abb:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101ac2:	e8 cd e5 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101ac7:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101acc:	74 24                	je     f0101af2 <mem_init+0x9f9>
f0101ace:	c7 44 24 0c 7b 4a 10 	movl   $0xf0104a7b,0xc(%esp)
f0101ad5:	f0 
f0101ad6:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101add:	f0 
f0101ade:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f0101ae5:	00 
f0101ae6:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101aed:	e8 a2 e5 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101af2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101af9:	e8 34 f2 ff ff       	call   f0100d32 <page_alloc>
f0101afe:	85 c0                	test   %eax,%eax
f0101b00:	74 24                	je     f0101b26 <mem_init+0xa2d>
f0101b02:	c7 44 24 0c 07 4a 10 	movl   $0xf0104a07,0xc(%esp)
f0101b09:	f0 
f0101b0a:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101b11:	f0 
f0101b12:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
f0101b19:	00 
f0101b1a:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101b21:	e8 6e e5 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b26:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101b2d:	00 
f0101b2e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101b35:	00 
f0101b36:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101b3a:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f0101b3f:	89 04 24             	mov    %eax,(%esp)
f0101b42:	e8 29 f5 ff ff       	call   f0101070 <page_insert>
f0101b47:	85 c0                	test   %eax,%eax
f0101b49:	74 24                	je     f0101b6f <mem_init+0xa76>
f0101b4b:	c7 44 24 0c 78 43 10 	movl   $0xf0104378,0xc(%esp)
f0101b52:	f0 
f0101b53:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101b5a:	f0 
f0101b5b:	c7 44 24 04 28 03 00 	movl   $0x328,0x4(%esp)
f0101b62:	00 
f0101b63:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101b6a:	e8 25 e5 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b6f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b74:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f0101b79:	e8 b6 ec ff ff       	call   f0100834 <check_va2pa>
f0101b7e:	89 da                	mov    %ebx,%edx
f0101b80:	2b 15 6c f9 11 f0    	sub    0xf011f96c,%edx
f0101b86:	c1 fa 03             	sar    $0x3,%edx
f0101b89:	c1 e2 0c             	shl    $0xc,%edx
f0101b8c:	39 d0                	cmp    %edx,%eax
f0101b8e:	74 24                	je     f0101bb4 <mem_init+0xabb>
f0101b90:	c7 44 24 0c b4 43 10 	movl   $0xf01043b4,0xc(%esp)
f0101b97:	f0 
f0101b98:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101b9f:	f0 
f0101ba0:	c7 44 24 04 29 03 00 	movl   $0x329,0x4(%esp)
f0101ba7:	00 
f0101ba8:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101baf:	e8 e0 e4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101bb4:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101bb9:	74 24                	je     f0101bdf <mem_init+0xae6>
f0101bbb:	c7 44 24 0c 7b 4a 10 	movl   $0xf0104a7b,0xc(%esp)
f0101bc2:	f0 
f0101bc3:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101bca:	f0 
f0101bcb:	c7 44 24 04 2a 03 00 	movl   $0x32a,0x4(%esp)
f0101bd2:	00 
f0101bd3:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101bda:	e8 b5 e4 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101bdf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101be6:	e8 47 f1 ff ff       	call   f0100d32 <page_alloc>
f0101beb:	85 c0                	test   %eax,%eax
f0101bed:	74 24                	je     f0101c13 <mem_init+0xb1a>
f0101bef:	c7 44 24 0c 07 4a 10 	movl   $0xf0104a07,0xc(%esp)
f0101bf6:	f0 
f0101bf7:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101bfe:	f0 
f0101bff:	c7 44 24 04 2e 03 00 	movl   $0x32e,0x4(%esp)
f0101c06:	00 
f0101c07:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101c0e:	e8 81 e4 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101c13:	8b 15 68 f9 11 f0    	mov    0xf011f968,%edx
f0101c19:	8b 02                	mov    (%edx),%eax
f0101c1b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101c20:	89 c1                	mov    %eax,%ecx
f0101c22:	c1 e9 0c             	shr    $0xc,%ecx
f0101c25:	3b 0d 64 f9 11 f0    	cmp    0xf011f964,%ecx
f0101c2b:	72 20                	jb     f0101c4d <mem_init+0xb54>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101c2d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101c31:	c7 44 24 08 8c 40 10 	movl   $0xf010408c,0x8(%esp)
f0101c38:	f0 
f0101c39:	c7 44 24 04 31 03 00 	movl   $0x331,0x4(%esp)
f0101c40:	00 
f0101c41:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101c48:	e8 47 e4 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101c4d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101c52:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101c55:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101c5c:	00 
f0101c5d:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101c64:	00 
f0101c65:	89 14 24             	mov    %edx,(%esp)
f0101c68:	e8 d5 f1 ff ff       	call   f0100e42 <pgdir_walk>
f0101c6d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101c70:	83 c2 04             	add    $0x4,%edx
f0101c73:	39 d0                	cmp    %edx,%eax
f0101c75:	74 24                	je     f0101c9b <mem_init+0xba2>
f0101c77:	c7 44 24 0c e4 43 10 	movl   $0xf01043e4,0xc(%esp)
f0101c7e:	f0 
f0101c7f:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101c86:	f0 
f0101c87:	c7 44 24 04 32 03 00 	movl   $0x332,0x4(%esp)
f0101c8e:	00 
f0101c8f:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101c96:	e8 f9 e3 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101c9b:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101ca2:	00 
f0101ca3:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101caa:	00 
f0101cab:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101caf:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f0101cb4:	89 04 24             	mov    %eax,(%esp)
f0101cb7:	e8 b4 f3 ff ff       	call   f0101070 <page_insert>
f0101cbc:	85 c0                	test   %eax,%eax
f0101cbe:	74 24                	je     f0101ce4 <mem_init+0xbeb>
f0101cc0:	c7 44 24 0c 24 44 10 	movl   $0xf0104424,0xc(%esp)
f0101cc7:	f0 
f0101cc8:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101ccf:	f0 
f0101cd0:	c7 44 24 04 35 03 00 	movl   $0x335,0x4(%esp)
f0101cd7:	00 
f0101cd8:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101cdf:	e8 b0 e3 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ce4:	8b 0d 68 f9 11 f0    	mov    0xf011f968,%ecx
f0101cea:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0101ced:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101cf2:	89 c8                	mov    %ecx,%eax
f0101cf4:	e8 3b eb ff ff       	call   f0100834 <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101cf9:	89 da                	mov    %ebx,%edx
f0101cfb:	2b 15 6c f9 11 f0    	sub    0xf011f96c,%edx
f0101d01:	c1 fa 03             	sar    $0x3,%edx
f0101d04:	c1 e2 0c             	shl    $0xc,%edx
f0101d07:	39 d0                	cmp    %edx,%eax
f0101d09:	74 24                	je     f0101d2f <mem_init+0xc36>
f0101d0b:	c7 44 24 0c b4 43 10 	movl   $0xf01043b4,0xc(%esp)
f0101d12:	f0 
f0101d13:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101d1a:	f0 
f0101d1b:	c7 44 24 04 36 03 00 	movl   $0x336,0x4(%esp)
f0101d22:	00 
f0101d23:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101d2a:	e8 65 e3 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101d2f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d34:	74 24                	je     f0101d5a <mem_init+0xc61>
f0101d36:	c7 44 24 0c 7b 4a 10 	movl   $0xf0104a7b,0xc(%esp)
f0101d3d:	f0 
f0101d3e:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101d45:	f0 
f0101d46:	c7 44 24 04 37 03 00 	movl   $0x337,0x4(%esp)
f0101d4d:	00 
f0101d4e:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101d55:	e8 3a e3 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101d5a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101d61:	00 
f0101d62:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101d69:	00 
f0101d6a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d6d:	89 04 24             	mov    %eax,(%esp)
f0101d70:	e8 cd f0 ff ff       	call   f0100e42 <pgdir_walk>
f0101d75:	f6 00 04             	testb  $0x4,(%eax)
f0101d78:	75 24                	jne    f0101d9e <mem_init+0xca5>
f0101d7a:	c7 44 24 0c 64 44 10 	movl   $0xf0104464,0xc(%esp)
f0101d81:	f0 
f0101d82:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101d89:	f0 
f0101d8a:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
f0101d91:	00 
f0101d92:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101d99:	e8 f6 e2 ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101d9e:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f0101da3:	f6 00 04             	testb  $0x4,(%eax)
f0101da6:	75 24                	jne    f0101dcc <mem_init+0xcd3>
f0101da8:	c7 44 24 0c 8c 4a 10 	movl   $0xf0104a8c,0xc(%esp)
f0101daf:	f0 
f0101db0:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101db7:	f0 
f0101db8:	c7 44 24 04 39 03 00 	movl   $0x339,0x4(%esp)
f0101dbf:	00 
f0101dc0:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101dc7:	e8 c8 e2 ff ff       	call   f0100094 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101dcc:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101dd3:	00 
f0101dd4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101ddb:	00 
f0101ddc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101de0:	89 04 24             	mov    %eax,(%esp)
f0101de3:	e8 88 f2 ff ff       	call   f0101070 <page_insert>
f0101de8:	85 c0                	test   %eax,%eax
f0101dea:	74 24                	je     f0101e10 <mem_init+0xd17>
f0101dec:	c7 44 24 0c 78 43 10 	movl   $0xf0104378,0xc(%esp)
f0101df3:	f0 
f0101df4:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101dfb:	f0 
f0101dfc:	c7 44 24 04 3c 03 00 	movl   $0x33c,0x4(%esp)
f0101e03:	00 
f0101e04:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101e0b:	e8 84 e2 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101e10:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e17:	00 
f0101e18:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101e1f:	00 
f0101e20:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f0101e25:	89 04 24             	mov    %eax,(%esp)
f0101e28:	e8 15 f0 ff ff       	call   f0100e42 <pgdir_walk>
f0101e2d:	f6 00 02             	testb  $0x2,(%eax)
f0101e30:	75 24                	jne    f0101e56 <mem_init+0xd5d>
f0101e32:	c7 44 24 0c 98 44 10 	movl   $0xf0104498,0xc(%esp)
f0101e39:	f0 
f0101e3a:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101e41:	f0 
f0101e42:	c7 44 24 04 3d 03 00 	movl   $0x33d,0x4(%esp)
f0101e49:	00 
f0101e4a:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101e51:	e8 3e e2 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101e56:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e5d:	00 
f0101e5e:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101e65:	00 
f0101e66:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f0101e6b:	89 04 24             	mov    %eax,(%esp)
f0101e6e:	e8 cf ef ff ff       	call   f0100e42 <pgdir_walk>
f0101e73:	f6 00 04             	testb  $0x4,(%eax)
f0101e76:	74 24                	je     f0101e9c <mem_init+0xda3>
f0101e78:	c7 44 24 0c cc 44 10 	movl   $0xf01044cc,0xc(%esp)
f0101e7f:	f0 
f0101e80:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101e87:	f0 
f0101e88:	c7 44 24 04 3e 03 00 	movl   $0x33e,0x4(%esp)
f0101e8f:	00 
f0101e90:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101e97:	e8 f8 e1 ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101e9c:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101ea3:	00 
f0101ea4:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0101eab:	00 
f0101eac:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101eb0:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f0101eb5:	89 04 24             	mov    %eax,(%esp)
f0101eb8:	e8 b3 f1 ff ff       	call   f0101070 <page_insert>
f0101ebd:	85 c0                	test   %eax,%eax
f0101ebf:	78 24                	js     f0101ee5 <mem_init+0xdec>
f0101ec1:	c7 44 24 0c 04 45 10 	movl   $0xf0104504,0xc(%esp)
f0101ec8:	f0 
f0101ec9:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101ed0:	f0 
f0101ed1:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f0101ed8:	00 
f0101ed9:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101ee0:	e8 af e1 ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101ee5:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101eec:	00 
f0101eed:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101ef4:	00 
f0101ef5:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101ef9:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f0101efe:	89 04 24             	mov    %eax,(%esp)
f0101f01:	e8 6a f1 ff ff       	call   f0101070 <page_insert>
f0101f06:	85 c0                	test   %eax,%eax
f0101f08:	74 24                	je     f0101f2e <mem_init+0xe35>
f0101f0a:	c7 44 24 0c 3c 45 10 	movl   $0xf010453c,0xc(%esp)
f0101f11:	f0 
f0101f12:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101f19:	f0 
f0101f1a:	c7 44 24 04 44 03 00 	movl   $0x344,0x4(%esp)
f0101f21:	00 
f0101f22:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101f29:	e8 66 e1 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101f2e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f35:	00 
f0101f36:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f3d:	00 
f0101f3e:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f0101f43:	89 04 24             	mov    %eax,(%esp)
f0101f46:	e8 f7 ee ff ff       	call   f0100e42 <pgdir_walk>
f0101f4b:	f6 00 04             	testb  $0x4,(%eax)
f0101f4e:	74 24                	je     f0101f74 <mem_init+0xe7b>
f0101f50:	c7 44 24 0c cc 44 10 	movl   $0xf01044cc,0xc(%esp)
f0101f57:	f0 
f0101f58:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101f5f:	f0 
f0101f60:	c7 44 24 04 45 03 00 	movl   $0x345,0x4(%esp)
f0101f67:	00 
f0101f68:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101f6f:	e8 20 e1 ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101f74:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f0101f79:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101f7c:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f81:	e8 ae e8 ff ff       	call   f0100834 <check_va2pa>
f0101f86:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101f89:	89 f0                	mov    %esi,%eax
f0101f8b:	2b 05 6c f9 11 f0    	sub    0xf011f96c,%eax
f0101f91:	c1 f8 03             	sar    $0x3,%eax
f0101f94:	c1 e0 0c             	shl    $0xc,%eax
f0101f97:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101f9a:	74 24                	je     f0101fc0 <mem_init+0xec7>
f0101f9c:	c7 44 24 0c 78 45 10 	movl   $0xf0104578,0xc(%esp)
f0101fa3:	f0 
f0101fa4:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101fab:	f0 
f0101fac:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f0101fb3:	00 
f0101fb4:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101fbb:	e8 d4 e0 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101fc0:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fc5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101fc8:	e8 67 e8 ff ff       	call   f0100834 <check_va2pa>
f0101fcd:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101fd0:	74 24                	je     f0101ff6 <mem_init+0xefd>
f0101fd2:	c7 44 24 0c a4 45 10 	movl   $0xf01045a4,0xc(%esp)
f0101fd9:	f0 
f0101fda:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0101fe1:	f0 
f0101fe2:	c7 44 24 04 49 03 00 	movl   $0x349,0x4(%esp)
f0101fe9:	00 
f0101fea:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0101ff1:	e8 9e e0 ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101ff6:	66 83 7e 04 02       	cmpw   $0x2,0x4(%esi)
f0101ffb:	74 24                	je     f0102021 <mem_init+0xf28>
f0101ffd:	c7 44 24 0c a2 4a 10 	movl   $0xf0104aa2,0xc(%esp)
f0102004:	f0 
f0102005:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f010200c:	f0 
f010200d:	c7 44 24 04 4b 03 00 	movl   $0x34b,0x4(%esp)
f0102014:	00 
f0102015:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f010201c:	e8 73 e0 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102021:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102026:	74 24                	je     f010204c <mem_init+0xf53>
f0102028:	c7 44 24 0c b3 4a 10 	movl   $0xf0104ab3,0xc(%esp)
f010202f:	f0 
f0102030:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0102037:	f0 
f0102038:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f010203f:	00 
f0102040:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0102047:	e8 48 e0 ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f010204c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102053:	e8 da ec ff ff       	call   f0100d32 <page_alloc>
f0102058:	85 c0                	test   %eax,%eax
f010205a:	74 04                	je     f0102060 <mem_init+0xf67>
f010205c:	39 c3                	cmp    %eax,%ebx
f010205e:	74 24                	je     f0102084 <mem_init+0xf8b>
f0102060:	c7 44 24 0c d4 45 10 	movl   $0xf01045d4,0xc(%esp)
f0102067:	f0 
f0102068:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f010206f:	f0 
f0102070:	c7 44 24 04 4f 03 00 	movl   $0x34f,0x4(%esp)
f0102077:	00 
f0102078:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f010207f:	e8 10 e0 ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102084:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010208b:	00 
f010208c:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f0102091:	89 04 24             	mov    %eax,(%esp)
f0102094:	e8 8e ef ff ff       	call   f0101027 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102099:	8b 15 68 f9 11 f0    	mov    0xf011f968,%edx
f010209f:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01020a2:	ba 00 00 00 00       	mov    $0x0,%edx
f01020a7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020aa:	e8 85 e7 ff ff       	call   f0100834 <check_va2pa>
f01020af:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020b2:	74 24                	je     f01020d8 <mem_init+0xfdf>
f01020b4:	c7 44 24 0c f8 45 10 	movl   $0xf01045f8,0xc(%esp)
f01020bb:	f0 
f01020bc:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f01020c3:	f0 
f01020c4:	c7 44 24 04 53 03 00 	movl   $0x353,0x4(%esp)
f01020cb:	00 
f01020cc:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f01020d3:	e8 bc df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01020d8:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020dd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020e0:	e8 4f e7 ff ff       	call   f0100834 <check_va2pa>
f01020e5:	89 f2                	mov    %esi,%edx
f01020e7:	2b 15 6c f9 11 f0    	sub    0xf011f96c,%edx
f01020ed:	c1 fa 03             	sar    $0x3,%edx
f01020f0:	c1 e2 0c             	shl    $0xc,%edx
f01020f3:	39 d0                	cmp    %edx,%eax
f01020f5:	74 24                	je     f010211b <mem_init+0x1022>
f01020f7:	c7 44 24 0c a4 45 10 	movl   $0xf01045a4,0xc(%esp)
f01020fe:	f0 
f01020ff:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0102106:	f0 
f0102107:	c7 44 24 04 54 03 00 	movl   $0x354,0x4(%esp)
f010210e:	00 
f010210f:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0102116:	e8 79 df ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f010211b:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102120:	74 24                	je     f0102146 <mem_init+0x104d>
f0102122:	c7 44 24 0c 59 4a 10 	movl   $0xf0104a59,0xc(%esp)
f0102129:	f0 
f010212a:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0102131:	f0 
f0102132:	c7 44 24 04 55 03 00 	movl   $0x355,0x4(%esp)
f0102139:	00 
f010213a:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0102141:	e8 4e df ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102146:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010214b:	74 24                	je     f0102171 <mem_init+0x1078>
f010214d:	c7 44 24 0c b3 4a 10 	movl   $0xf0104ab3,0xc(%esp)
f0102154:	f0 
f0102155:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f010215c:	f0 
f010215d:	c7 44 24 04 56 03 00 	movl   $0x356,0x4(%esp)
f0102164:	00 
f0102165:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f010216c:	e8 23 df ff ff       	call   f0100094 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102171:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f0102178:	00 
f0102179:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102180:	00 
f0102181:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102185:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102188:	89 0c 24             	mov    %ecx,(%esp)
f010218b:	e8 e0 ee ff ff       	call   f0101070 <page_insert>
f0102190:	85 c0                	test   %eax,%eax
f0102192:	74 24                	je     f01021b8 <mem_init+0x10bf>
f0102194:	c7 44 24 0c 1c 46 10 	movl   $0xf010461c,0xc(%esp)
f010219b:	f0 
f010219c:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f01021a3:	f0 
f01021a4:	c7 44 24 04 59 03 00 	movl   $0x359,0x4(%esp)
f01021ab:	00 
f01021ac:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f01021b3:	e8 dc de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref);
f01021b8:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01021bd:	75 24                	jne    f01021e3 <mem_init+0x10ea>
f01021bf:	c7 44 24 0c c4 4a 10 	movl   $0xf0104ac4,0xc(%esp)
f01021c6:	f0 
f01021c7:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f01021ce:	f0 
f01021cf:	c7 44 24 04 5a 03 00 	movl   $0x35a,0x4(%esp)
f01021d6:	00 
f01021d7:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f01021de:	e8 b1 de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_link == NULL);
f01021e3:	83 3e 00             	cmpl   $0x0,(%esi)
f01021e6:	74 24                	je     f010220c <mem_init+0x1113>
f01021e8:	c7 44 24 0c d0 4a 10 	movl   $0xf0104ad0,0xc(%esp)
f01021ef:	f0 
f01021f0:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f01021f7:	f0 
f01021f8:	c7 44 24 04 5b 03 00 	movl   $0x35b,0x4(%esp)
f01021ff:	00 
f0102200:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0102207:	e8 88 de ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f010220c:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102213:	00 
f0102214:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f0102219:	89 04 24             	mov    %eax,(%esp)
f010221c:	e8 06 ee ff ff       	call   f0101027 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102221:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f0102226:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102229:	ba 00 00 00 00       	mov    $0x0,%edx
f010222e:	e8 01 e6 ff ff       	call   f0100834 <check_va2pa>
f0102233:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102236:	74 24                	je     f010225c <mem_init+0x1163>
f0102238:	c7 44 24 0c f8 45 10 	movl   $0xf01045f8,0xc(%esp)
f010223f:	f0 
f0102240:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0102247:	f0 
f0102248:	c7 44 24 04 5f 03 00 	movl   $0x35f,0x4(%esp)
f010224f:	00 
f0102250:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0102257:	e8 38 de ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010225c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102261:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102264:	e8 cb e5 ff ff       	call   f0100834 <check_va2pa>
f0102269:	83 f8 ff             	cmp    $0xffffffff,%eax
f010226c:	74 24                	je     f0102292 <mem_init+0x1199>
f010226e:	c7 44 24 0c 54 46 10 	movl   $0xf0104654,0xc(%esp)
f0102275:	f0 
f0102276:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f010227d:	f0 
f010227e:	c7 44 24 04 60 03 00 	movl   $0x360,0x4(%esp)
f0102285:	00 
f0102286:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f010228d:	e8 02 de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102292:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102297:	74 24                	je     f01022bd <mem_init+0x11c4>
f0102299:	c7 44 24 0c e5 4a 10 	movl   $0xf0104ae5,0xc(%esp)
f01022a0:	f0 
f01022a1:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f01022a8:	f0 
f01022a9:	c7 44 24 04 61 03 00 	movl   $0x361,0x4(%esp)
f01022b0:	00 
f01022b1:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f01022b8:	e8 d7 dd ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01022bd:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01022c2:	74 24                	je     f01022e8 <mem_init+0x11ef>
f01022c4:	c7 44 24 0c b3 4a 10 	movl   $0xf0104ab3,0xc(%esp)
f01022cb:	f0 
f01022cc:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f01022d3:	f0 
f01022d4:	c7 44 24 04 62 03 00 	movl   $0x362,0x4(%esp)
f01022db:	00 
f01022dc:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f01022e3:	e8 ac dd ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f01022e8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01022ef:	e8 3e ea ff ff       	call   f0100d32 <page_alloc>
f01022f4:	85 c0                	test   %eax,%eax
f01022f6:	74 04                	je     f01022fc <mem_init+0x1203>
f01022f8:	39 c6                	cmp    %eax,%esi
f01022fa:	74 24                	je     f0102320 <mem_init+0x1227>
f01022fc:	c7 44 24 0c 7c 46 10 	movl   $0xf010467c,0xc(%esp)
f0102303:	f0 
f0102304:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f010230b:	f0 
f010230c:	c7 44 24 04 65 03 00 	movl   $0x365,0x4(%esp)
f0102313:	00 
f0102314:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f010231b:	e8 74 dd ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102320:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102327:	e8 06 ea ff ff       	call   f0100d32 <page_alloc>
f010232c:	85 c0                	test   %eax,%eax
f010232e:	74 24                	je     f0102354 <mem_init+0x125b>
f0102330:	c7 44 24 0c 07 4a 10 	movl   $0xf0104a07,0xc(%esp)
f0102337:	f0 
f0102338:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f010233f:	f0 
f0102340:	c7 44 24 04 68 03 00 	movl   $0x368,0x4(%esp)
f0102347:	00 
f0102348:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f010234f:	e8 40 dd ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102354:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f0102359:	8b 08                	mov    (%eax),%ecx
f010235b:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102361:	89 fa                	mov    %edi,%edx
f0102363:	2b 15 6c f9 11 f0    	sub    0xf011f96c,%edx
f0102369:	c1 fa 03             	sar    $0x3,%edx
f010236c:	c1 e2 0c             	shl    $0xc,%edx
f010236f:	39 d1                	cmp    %edx,%ecx
f0102371:	74 24                	je     f0102397 <mem_init+0x129e>
f0102373:	c7 44 24 0c 20 43 10 	movl   $0xf0104320,0xc(%esp)
f010237a:	f0 
f010237b:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0102382:	f0 
f0102383:	c7 44 24 04 6b 03 00 	movl   $0x36b,0x4(%esp)
f010238a:	00 
f010238b:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0102392:	e8 fd dc ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102397:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f010239d:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01023a2:	74 24                	je     f01023c8 <mem_init+0x12cf>
f01023a4:	c7 44 24 0c 6a 4a 10 	movl   $0xf0104a6a,0xc(%esp)
f01023ab:	f0 
f01023ac:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f01023b3:	f0 
f01023b4:	c7 44 24 04 6d 03 00 	movl   $0x36d,0x4(%esp)
f01023bb:	00 
f01023bc:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f01023c3:	e8 cc dc ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f01023c8:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01023ce:	89 3c 24             	mov    %edi,(%esp)
f01023d1:	e8 e0 e9 ff ff       	call   f0100db6 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01023d6:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01023dd:	00 
f01023de:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f01023e5:	00 
f01023e6:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f01023eb:	89 04 24             	mov    %eax,(%esp)
f01023ee:	e8 4f ea ff ff       	call   f0100e42 <pgdir_walk>
f01023f3:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01023f6:	8b 0d 68 f9 11 f0    	mov    0xf011f968,%ecx
f01023fc:	8b 51 04             	mov    0x4(%ecx),%edx
f01023ff:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102405:	89 55 d4             	mov    %edx,-0x2c(%ebp)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102408:	8b 15 64 f9 11 f0    	mov    0xf011f964,%edx
f010240e:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0102411:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102414:	c1 ea 0c             	shr    $0xc,%edx
f0102417:	89 55 d0             	mov    %edx,-0x30(%ebp)
f010241a:	8b 55 c8             	mov    -0x38(%ebp),%edx
f010241d:	39 55 d0             	cmp    %edx,-0x30(%ebp)
f0102420:	72 23                	jb     f0102445 <mem_init+0x134c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102422:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102425:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0102429:	c7 44 24 08 8c 40 10 	movl   $0xf010408c,0x8(%esp)
f0102430:	f0 
f0102431:	c7 44 24 04 74 03 00 	movl   $0x374,0x4(%esp)
f0102438:	00 
f0102439:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0102440:	e8 4f dc ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102445:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102448:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f010244e:	39 d0                	cmp    %edx,%eax
f0102450:	74 24                	je     f0102476 <mem_init+0x137d>
f0102452:	c7 44 24 0c f6 4a 10 	movl   $0xf0104af6,0xc(%esp)
f0102459:	f0 
f010245a:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0102461:	f0 
f0102462:	c7 44 24 04 75 03 00 	movl   $0x375,0x4(%esp)
f0102469:	00 
f010246a:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0102471:	e8 1e dc ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102476:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f010247d:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102483:	89 f8                	mov    %edi,%eax
f0102485:	2b 05 6c f9 11 f0    	sub    0xf011f96c,%eax
f010248b:	c1 f8 03             	sar    $0x3,%eax
f010248e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102491:	89 c1                	mov    %eax,%ecx
f0102493:	c1 e9 0c             	shr    $0xc,%ecx
f0102496:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0102499:	77 20                	ja     f01024bb <mem_init+0x13c2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010249b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010249f:	c7 44 24 08 8c 40 10 	movl   $0xf010408c,0x8(%esp)
f01024a6:	f0 
f01024a7:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01024ae:	00 
f01024af:	c7 04 24 4f 48 10 f0 	movl   $0xf010484f,(%esp)
f01024b6:	e8 d9 db ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01024bb:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01024c2:	00 
f01024c3:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f01024ca:	00 
	return (void *)(pa + KERNBASE);
f01024cb:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024d0:	89 04 24             	mov    %eax,(%esp)
f01024d3:	e8 de 12 00 00       	call   f01037b6 <memset>
	page_free(pp0);
f01024d8:	89 3c 24             	mov    %edi,(%esp)
f01024db:	e8 d6 e8 ff ff       	call   f0100db6 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01024e0:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01024e7:	00 
f01024e8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01024ef:	00 
f01024f0:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f01024f5:	89 04 24             	mov    %eax,(%esp)
f01024f8:	e8 45 e9 ff ff       	call   f0100e42 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01024fd:	89 fa                	mov    %edi,%edx
f01024ff:	2b 15 6c f9 11 f0    	sub    0xf011f96c,%edx
f0102505:	c1 fa 03             	sar    $0x3,%edx
f0102508:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010250b:	89 d0                	mov    %edx,%eax
f010250d:	c1 e8 0c             	shr    $0xc,%eax
f0102510:	3b 05 64 f9 11 f0    	cmp    0xf011f964,%eax
f0102516:	72 20                	jb     f0102538 <mem_init+0x143f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102518:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010251c:	c7 44 24 08 8c 40 10 	movl   $0xf010408c,0x8(%esp)
f0102523:	f0 
f0102524:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010252b:	00 
f010252c:	c7 04 24 4f 48 10 f0 	movl   $0xf010484f,(%esp)
f0102533:	e8 5c db ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0102538:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010253e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102541:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102547:	f6 00 01             	testb  $0x1,(%eax)
f010254a:	74 24                	je     f0102570 <mem_init+0x1477>
f010254c:	c7 44 24 0c 0e 4b 10 	movl   $0xf0104b0e,0xc(%esp)
f0102553:	f0 
f0102554:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f010255b:	f0 
f010255c:	c7 44 24 04 7f 03 00 	movl   $0x37f,0x4(%esp)
f0102563:	00 
f0102564:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f010256b:	e8 24 db ff ff       	call   f0100094 <_panic>
f0102570:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102573:	39 d0                	cmp    %edx,%eax
f0102575:	75 d0                	jne    f0102547 <mem_init+0x144e>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102577:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f010257c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102582:	66 c7 47 04 00 00    	movw   $0x0,0x4(%edi)

	// give free list back
	page_free_list = fl;
f0102588:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f010258b:	89 0d 40 f5 11 f0    	mov    %ecx,0xf011f540

	// free the pages we took
	page_free(pp0);
f0102591:	89 3c 24             	mov    %edi,(%esp)
f0102594:	e8 1d e8 ff ff       	call   f0100db6 <page_free>
	page_free(pp1);
f0102599:	89 34 24             	mov    %esi,(%esp)
f010259c:	e8 15 e8 ff ff       	call   f0100db6 <page_free>
	page_free(pp2);
f01025a1:	89 1c 24             	mov    %ebx,(%esp)
f01025a4:	e8 0d e8 ff ff       	call   f0100db6 <page_free>

	cprintf("check_page() succeeded!\n");
f01025a9:	c7 04 24 25 4b 10 f0 	movl   $0xf0104b25,(%esp)
f01025b0:	e8 95 07 00 00       	call   f0102d4a <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, PTSIZE, PADDR(pages), PTE_U);
f01025b5:	a1 6c f9 11 f0       	mov    0xf011f96c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01025ba:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01025bf:	77 20                	ja     f01025e1 <mem_init+0x14e8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01025c1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01025c5:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f01025cc:	f0 
f01025cd:	c7 44 24 04 bb 00 00 	movl   $0xbb,0x4(%esp)
f01025d4:	00 
f01025d5:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f01025dc:	e8 b3 da ff ff       	call   f0100094 <_panic>
f01025e1:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
f01025e8:	00 
	return (physaddr_t)kva - KERNBASE;
f01025e9:	05 00 00 00 10       	add    $0x10000000,%eax
f01025ee:	89 04 24             	mov    %eax,(%esp)
f01025f1:	b9 00 00 40 00       	mov    $0x400000,%ecx
f01025f6:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01025fb:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f0102600:	e8 2b e9 ff ff       	call   f0100f30 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102605:	b8 00 50 11 f0       	mov    $0xf0115000,%eax
f010260a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010260f:	77 20                	ja     f0102631 <mem_init+0x1538>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102611:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102615:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f010261c:	f0 
f010261d:	c7 44 24 04 c8 00 00 	movl   $0xc8,0x4(%esp)
f0102624:	00 
f0102625:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f010262c:	e8 63 da ff ff       	call   f0100094 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, PTSIZE, PADDR(bootstack), PTE_W);
f0102631:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102638:	00 
f0102639:	c7 04 24 00 50 11 00 	movl   $0x115000,(%esp)
f0102640:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102645:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010264a:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f010264f:	e8 dc e8 ff ff       	call   f0100f30 <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	//boot_map_region(kern_pgdir, KERNBASE, (uint32_t)(-1) - KERNBASE, 0, PTE_W);
	boot_map_region(kern_pgdir, KERNBASE, 0xffffffff - KERNBASE, 0, PTE_W);
f0102654:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f010265b:	00 
f010265c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102663:	b9 ff ff ff 0f       	mov    $0xfffffff,%ecx
f0102668:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f010266d:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f0102672:	e8 b9 e8 ff ff       	call   f0100f30 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102677:	8b 1d 68 f9 11 f0    	mov    0xf011f968,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010267d:	8b 15 64 f9 11 f0    	mov    0xf011f964,%edx
f0102683:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0102686:	8d 3c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%edi
f010268d:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
	for (i = 0; i < n; i += PGSIZE)
f0102693:	be 00 00 00 00       	mov    $0x0,%esi
f0102698:	eb 70                	jmp    f010270a <mem_init+0x1611>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010269a:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f01026a0:	89 d8                	mov    %ebx,%eax
f01026a2:	e8 8d e1 ff ff       	call   f0100834 <check_va2pa>
f01026a7:	8b 15 6c f9 11 f0    	mov    0xf011f96c,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026ad:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f01026b3:	77 20                	ja     f01026d5 <mem_init+0x15dc>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026b5:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01026b9:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f01026c0:	f0 
f01026c1:	c7 44 24 04 c2 02 00 	movl   $0x2c2,0x4(%esp)
f01026c8:	00 
f01026c9:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f01026d0:	e8 bf d9 ff ff       	call   f0100094 <_panic>
f01026d5:	8d 94 32 00 00 00 10 	lea    0x10000000(%edx,%esi,1),%edx
f01026dc:	39 d0                	cmp    %edx,%eax
f01026de:	74 24                	je     f0102704 <mem_init+0x160b>
f01026e0:	c7 44 24 0c a0 46 10 	movl   $0xf01046a0,0xc(%esp)
f01026e7:	f0 
f01026e8:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f01026ef:	f0 
f01026f0:	c7 44 24 04 c2 02 00 	movl   $0x2c2,0x4(%esp)
f01026f7:	00 
f01026f8:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f01026ff:	e8 90 d9 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102704:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010270a:	39 f7                	cmp    %esi,%edi
f010270c:	77 8c                	ja     f010269a <mem_init+0x15a1>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010270e:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102711:	c1 e7 0c             	shl    $0xc,%edi
f0102714:	be 00 00 00 00       	mov    $0x0,%esi
f0102719:	eb 3b                	jmp    f0102756 <mem_init+0x165d>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010271b:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102721:	89 d8                	mov    %ebx,%eax
f0102723:	e8 0c e1 ff ff       	call   f0100834 <check_va2pa>
f0102728:	39 c6                	cmp    %eax,%esi
f010272a:	74 24                	je     f0102750 <mem_init+0x1657>
f010272c:	c7 44 24 0c d4 46 10 	movl   $0xf01046d4,0xc(%esp)
f0102733:	f0 
f0102734:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f010273b:	f0 
f010273c:	c7 44 24 04 c7 02 00 	movl   $0x2c7,0x4(%esp)
f0102743:	00 
f0102744:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f010274b:	e8 44 d9 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102750:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102756:	39 fe                	cmp    %edi,%esi
f0102758:	72 c1                	jb     f010271b <mem_init+0x1622>
f010275a:	be 00 80 ff ef       	mov    $0xefff8000,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010275f:	bf 00 50 11 f0       	mov    $0xf0115000,%edi
f0102764:	81 c7 00 80 00 20    	add    $0x20008000,%edi
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010276a:	89 f2                	mov    %esi,%edx
f010276c:	89 d8                	mov    %ebx,%eax
f010276e:	e8 c1 e0 ff ff       	call   f0100834 <check_va2pa>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102773:	8d 14 37             	lea    (%edi,%esi,1),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102776:	39 d0                	cmp    %edx,%eax
f0102778:	74 24                	je     f010279e <mem_init+0x16a5>
f010277a:	c7 44 24 0c fc 46 10 	movl   $0xf01046fc,0xc(%esp)
f0102781:	f0 
f0102782:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0102789:	f0 
f010278a:	c7 44 24 04 cb 02 00 	movl   $0x2cb,0x4(%esp)
f0102791:	00 
f0102792:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0102799:	e8 f6 d8 ff ff       	call   f0100094 <_panic>
f010279e:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01027a4:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f01027aa:	75 be                	jne    f010276a <mem_init+0x1671>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01027ac:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01027b1:	89 d8                	mov    %ebx,%eax
f01027b3:	e8 7c e0 ff ff       	call   f0100834 <check_va2pa>
f01027b8:	83 f8 ff             	cmp    $0xffffffff,%eax
f01027bb:	74 24                	je     f01027e1 <mem_init+0x16e8>
f01027bd:	c7 44 24 0c 44 47 10 	movl   $0xf0104744,0xc(%esp)
f01027c4:	f0 
f01027c5:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f01027cc:	f0 
f01027cd:	c7 44 24 04 cc 02 00 	movl   $0x2cc,0x4(%esp)
f01027d4:	00 
f01027d5:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f01027dc:	e8 b3 d8 ff ff       	call   f0100094 <_panic>
f01027e1:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01027e6:	3d bc 03 00 00       	cmp    $0x3bc,%eax
f01027eb:	72 3c                	jb     f0102829 <mem_init+0x1730>
f01027ed:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f01027f2:	76 07                	jbe    f01027fb <mem_init+0x1702>
f01027f4:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01027f9:	75 2e                	jne    f0102829 <mem_init+0x1730>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f01027fb:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f01027ff:	0f 85 aa 00 00 00    	jne    f01028af <mem_init+0x17b6>
f0102805:	c7 44 24 0c 3e 4b 10 	movl   $0xf0104b3e,0xc(%esp)
f010280c:	f0 
f010280d:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0102814:	f0 
f0102815:	c7 44 24 04 d4 02 00 	movl   $0x2d4,0x4(%esp)
f010281c:	00 
f010281d:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0102824:	e8 6b d8 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102829:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f010282e:	76 55                	jbe    f0102885 <mem_init+0x178c>
				assert(pgdir[i] & PTE_P);
f0102830:	8b 14 83             	mov    (%ebx,%eax,4),%edx
f0102833:	f6 c2 01             	test   $0x1,%dl
f0102836:	75 24                	jne    f010285c <mem_init+0x1763>
f0102838:	c7 44 24 0c 3e 4b 10 	movl   $0xf0104b3e,0xc(%esp)
f010283f:	f0 
f0102840:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0102847:	f0 
f0102848:	c7 44 24 04 d8 02 00 	movl   $0x2d8,0x4(%esp)
f010284f:	00 
f0102850:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0102857:	e8 38 d8 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f010285c:	f6 c2 02             	test   $0x2,%dl
f010285f:	75 4e                	jne    f01028af <mem_init+0x17b6>
f0102861:	c7 44 24 0c 4f 4b 10 	movl   $0xf0104b4f,0xc(%esp)
f0102868:	f0 
f0102869:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0102870:	f0 
f0102871:	c7 44 24 04 d9 02 00 	movl   $0x2d9,0x4(%esp)
f0102878:	00 
f0102879:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0102880:	e8 0f d8 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102885:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102889:	74 24                	je     f01028af <mem_init+0x17b6>
f010288b:	c7 44 24 0c 60 4b 10 	movl   $0xf0104b60,0xc(%esp)
f0102892:	f0 
f0102893:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f010289a:	f0 
f010289b:	c7 44 24 04 db 02 00 	movl   $0x2db,0x4(%esp)
f01028a2:	00 
f01028a3:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f01028aa:	e8 e5 d7 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01028af:	40                   	inc    %eax
f01028b0:	3d 00 04 00 00       	cmp    $0x400,%eax
f01028b5:	0f 85 2b ff ff ff    	jne    f01027e6 <mem_init+0x16ed>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01028bb:	c7 04 24 74 47 10 f0 	movl   $0xf0104774,(%esp)
f01028c2:	e8 83 04 00 00       	call   f0102d4a <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01028c7:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01028cc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01028d1:	77 20                	ja     f01028f3 <mem_init+0x17fa>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028d3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01028d7:	c7 44 24 08 24 42 10 	movl   $0xf0104224,0x8(%esp)
f01028de:	f0 
f01028df:	c7 44 24 04 df 00 00 	movl   $0xdf,0x4(%esp)
f01028e6:	00 
f01028e7:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f01028ee:	e8 a1 d7 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01028f3:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline void
lcr3(uint32_t val)
{
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01028f8:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01028fb:	b8 00 00 00 00       	mov    $0x0,%eax
f0102900:	e8 38 e0 ff ff       	call   f010093d <check_page_free_list>

static inline uint32_t
rcr0(void)
{
	uint32_t val;
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102905:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
f0102908:	0d 23 00 05 80       	or     $0x80050023,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f010290d:	83 e0 f3             	and    $0xfffffff3,%eax
}

static inline void
lcr0(uint32_t val)
{
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102910:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102913:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010291a:	e8 13 e4 ff ff       	call   f0100d32 <page_alloc>
f010291f:	89 c6                	mov    %eax,%esi
f0102921:	85 c0                	test   %eax,%eax
f0102923:	75 24                	jne    f0102949 <mem_init+0x1850>
f0102925:	c7 44 24 0c 5c 49 10 	movl   $0xf010495c,0xc(%esp)
f010292c:	f0 
f010292d:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0102934:	f0 
f0102935:	c7 44 24 04 9a 03 00 	movl   $0x39a,0x4(%esp)
f010293c:	00 
f010293d:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0102944:	e8 4b d7 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0102949:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102950:	e8 dd e3 ff ff       	call   f0100d32 <page_alloc>
f0102955:	89 c7                	mov    %eax,%edi
f0102957:	85 c0                	test   %eax,%eax
f0102959:	75 24                	jne    f010297f <mem_init+0x1886>
f010295b:	c7 44 24 0c 72 49 10 	movl   $0xf0104972,0xc(%esp)
f0102962:	f0 
f0102963:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f010296a:	f0 
f010296b:	c7 44 24 04 9b 03 00 	movl   $0x39b,0x4(%esp)
f0102972:	00 
f0102973:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f010297a:	e8 15 d7 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f010297f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102986:	e8 a7 e3 ff ff       	call   f0100d32 <page_alloc>
f010298b:	89 c3                	mov    %eax,%ebx
f010298d:	85 c0                	test   %eax,%eax
f010298f:	75 24                	jne    f01029b5 <mem_init+0x18bc>
f0102991:	c7 44 24 0c 88 49 10 	movl   $0xf0104988,0xc(%esp)
f0102998:	f0 
f0102999:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f01029a0:	f0 
f01029a1:	c7 44 24 04 9c 03 00 	movl   $0x39c,0x4(%esp)
f01029a8:	00 
f01029a9:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f01029b0:	e8 df d6 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f01029b5:	89 34 24             	mov    %esi,(%esp)
f01029b8:	e8 f9 e3 ff ff       	call   f0100db6 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01029bd:	89 f8                	mov    %edi,%eax
f01029bf:	2b 05 6c f9 11 f0    	sub    0xf011f96c,%eax
f01029c5:	c1 f8 03             	sar    $0x3,%eax
f01029c8:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01029cb:	89 c2                	mov    %eax,%edx
f01029cd:	c1 ea 0c             	shr    $0xc,%edx
f01029d0:	3b 15 64 f9 11 f0    	cmp    0xf011f964,%edx
f01029d6:	72 20                	jb     f01029f8 <mem_init+0x18ff>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01029d8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01029dc:	c7 44 24 08 8c 40 10 	movl   $0xf010408c,0x8(%esp)
f01029e3:	f0 
f01029e4:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01029eb:	00 
f01029ec:	c7 04 24 4f 48 10 f0 	movl   $0xf010484f,(%esp)
f01029f3:	e8 9c d6 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f01029f8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01029ff:	00 
f0102a00:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102a07:	00 
	return (void *)(pa + KERNBASE);
f0102a08:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102a0d:	89 04 24             	mov    %eax,(%esp)
f0102a10:	e8 a1 0d 00 00       	call   f01037b6 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a15:	89 d8                	mov    %ebx,%eax
f0102a17:	2b 05 6c f9 11 f0    	sub    0xf011f96c,%eax
f0102a1d:	c1 f8 03             	sar    $0x3,%eax
f0102a20:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a23:	89 c2                	mov    %eax,%edx
f0102a25:	c1 ea 0c             	shr    $0xc,%edx
f0102a28:	3b 15 64 f9 11 f0    	cmp    0xf011f964,%edx
f0102a2e:	72 20                	jb     f0102a50 <mem_init+0x1957>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a30:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102a34:	c7 44 24 08 8c 40 10 	movl   $0xf010408c,0x8(%esp)
f0102a3b:	f0 
f0102a3c:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102a43:	00 
f0102a44:	c7 04 24 4f 48 10 f0 	movl   $0xf010484f,(%esp)
f0102a4b:	e8 44 d6 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102a50:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102a57:	00 
f0102a58:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102a5f:	00 
	return (void *)(pa + KERNBASE);
f0102a60:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102a65:	89 04 24             	mov    %eax,(%esp)
f0102a68:	e8 49 0d 00 00       	call   f01037b6 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102a6d:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102a74:	00 
f0102a75:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102a7c:	00 
f0102a7d:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102a81:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f0102a86:	89 04 24             	mov    %eax,(%esp)
f0102a89:	e8 e2 e5 ff ff       	call   f0101070 <page_insert>
	assert(pp1->pp_ref == 1);
f0102a8e:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102a93:	74 24                	je     f0102ab9 <mem_init+0x19c0>
f0102a95:	c7 44 24 0c 59 4a 10 	movl   $0xf0104a59,0xc(%esp)
f0102a9c:	f0 
f0102a9d:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0102aa4:	f0 
f0102aa5:	c7 44 24 04 a1 03 00 	movl   $0x3a1,0x4(%esp)
f0102aac:	00 
f0102aad:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0102ab4:	e8 db d5 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102ab9:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102ac0:	01 01 01 
f0102ac3:	74 24                	je     f0102ae9 <mem_init+0x19f0>
f0102ac5:	c7 44 24 0c 94 47 10 	movl   $0xf0104794,0xc(%esp)
f0102acc:	f0 
f0102acd:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0102ad4:	f0 
f0102ad5:	c7 44 24 04 a2 03 00 	movl   $0x3a2,0x4(%esp)
f0102adc:	00 
f0102add:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0102ae4:	e8 ab d5 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102ae9:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102af0:	00 
f0102af1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102af8:	00 
f0102af9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102afd:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f0102b02:	89 04 24             	mov    %eax,(%esp)
f0102b05:	e8 66 e5 ff ff       	call   f0101070 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102b0a:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102b11:	02 02 02 
f0102b14:	74 24                	je     f0102b3a <mem_init+0x1a41>
f0102b16:	c7 44 24 0c b8 47 10 	movl   $0xf01047b8,0xc(%esp)
f0102b1d:	f0 
f0102b1e:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0102b25:	f0 
f0102b26:	c7 44 24 04 a4 03 00 	movl   $0x3a4,0x4(%esp)
f0102b2d:	00 
f0102b2e:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0102b35:	e8 5a d5 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102b3a:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102b3f:	74 24                	je     f0102b65 <mem_init+0x1a6c>
f0102b41:	c7 44 24 0c 7b 4a 10 	movl   $0xf0104a7b,0xc(%esp)
f0102b48:	f0 
f0102b49:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0102b50:	f0 
f0102b51:	c7 44 24 04 a5 03 00 	movl   $0x3a5,0x4(%esp)
f0102b58:	00 
f0102b59:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0102b60:	e8 2f d5 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102b65:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102b6a:	74 24                	je     f0102b90 <mem_init+0x1a97>
f0102b6c:	c7 44 24 0c e5 4a 10 	movl   $0xf0104ae5,0xc(%esp)
f0102b73:	f0 
f0102b74:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0102b7b:	f0 
f0102b7c:	c7 44 24 04 a6 03 00 	movl   $0x3a6,0x4(%esp)
f0102b83:	00 
f0102b84:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0102b8b:	e8 04 d5 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102b90:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102b97:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102b9a:	89 d8                	mov    %ebx,%eax
f0102b9c:	2b 05 6c f9 11 f0    	sub    0xf011f96c,%eax
f0102ba2:	c1 f8 03             	sar    $0x3,%eax
f0102ba5:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102ba8:	89 c2                	mov    %eax,%edx
f0102baa:	c1 ea 0c             	shr    $0xc,%edx
f0102bad:	3b 15 64 f9 11 f0    	cmp    0xf011f964,%edx
f0102bb3:	72 20                	jb     f0102bd5 <mem_init+0x1adc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102bb5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102bb9:	c7 44 24 08 8c 40 10 	movl   $0xf010408c,0x8(%esp)
f0102bc0:	f0 
f0102bc1:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102bc8:	00 
f0102bc9:	c7 04 24 4f 48 10 f0 	movl   $0xf010484f,(%esp)
f0102bd0:	e8 bf d4 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102bd5:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102bdc:	03 03 03 
f0102bdf:	74 24                	je     f0102c05 <mem_init+0x1b0c>
f0102be1:	c7 44 24 0c dc 47 10 	movl   $0xf01047dc,0xc(%esp)
f0102be8:	f0 
f0102be9:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0102bf0:	f0 
f0102bf1:	c7 44 24 04 a8 03 00 	movl   $0x3a8,0x4(%esp)
f0102bf8:	00 
f0102bf9:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0102c00:	e8 8f d4 ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102c05:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102c0c:	00 
f0102c0d:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f0102c12:	89 04 24             	mov    %eax,(%esp)
f0102c15:	e8 0d e4 ff ff       	call   f0101027 <page_remove>
	assert(pp2->pp_ref == 0);
f0102c1a:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102c1f:	74 24                	je     f0102c45 <mem_init+0x1b4c>
f0102c21:	c7 44 24 0c b3 4a 10 	movl   $0xf0104ab3,0xc(%esp)
f0102c28:	f0 
f0102c29:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0102c30:	f0 
f0102c31:	c7 44 24 04 aa 03 00 	movl   $0x3aa,0x4(%esp)
f0102c38:	00 
f0102c39:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0102c40:	e8 4f d4 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102c45:	a1 68 f9 11 f0       	mov    0xf011f968,%eax
f0102c4a:	8b 08                	mov    (%eax),%ecx
f0102c4c:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c52:	89 f2                	mov    %esi,%edx
f0102c54:	2b 15 6c f9 11 f0    	sub    0xf011f96c,%edx
f0102c5a:	c1 fa 03             	sar    $0x3,%edx
f0102c5d:	c1 e2 0c             	shl    $0xc,%edx
f0102c60:	39 d1                	cmp    %edx,%ecx
f0102c62:	74 24                	je     f0102c88 <mem_init+0x1b8f>
f0102c64:	c7 44 24 0c 20 43 10 	movl   $0xf0104320,0xc(%esp)
f0102c6b:	f0 
f0102c6c:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0102c73:	f0 
f0102c74:	c7 44 24 04 ad 03 00 	movl   $0x3ad,0x4(%esp)
f0102c7b:	00 
f0102c7c:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0102c83:	e8 0c d4 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102c88:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102c8e:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102c93:	74 24                	je     f0102cb9 <mem_init+0x1bc0>
f0102c95:	c7 44 24 0c 6a 4a 10 	movl   $0xf0104a6a,0xc(%esp)
f0102c9c:	f0 
f0102c9d:	c7 44 24 08 69 48 10 	movl   $0xf0104869,0x8(%esp)
f0102ca4:	f0 
f0102ca5:	c7 44 24 04 af 03 00 	movl   $0x3af,0x4(%esp)
f0102cac:	00 
f0102cad:	c7 04 24 34 48 10 f0 	movl   $0xf0104834,(%esp)
f0102cb4:	e8 db d3 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102cb9:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102cbf:	89 34 24             	mov    %esi,(%esp)
f0102cc2:	e8 ef e0 ff ff       	call   f0100db6 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102cc7:	c7 04 24 08 48 10 f0 	movl   $0xf0104808,(%esp)
f0102cce:	e8 77 00 00 00       	call   f0102d4a <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102cd3:	83 c4 3c             	add    $0x3c,%esp
f0102cd6:	5b                   	pop    %ebx
f0102cd7:	5e                   	pop    %esi
f0102cd8:	5f                   	pop    %edi
f0102cd9:	5d                   	pop    %ebp
f0102cda:	c3                   	ret    
	...

f0102cdc <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102cdc:	55                   	push   %ebp
f0102cdd:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102cdf:	ba 70 00 00 00       	mov    $0x70,%edx
f0102ce4:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ce7:	ee                   	out    %al,(%dx)

static inline uint8_t
inb(int port)
{
	uint8_t data;
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102ce8:	b2 71                	mov    $0x71,%dl
f0102cea:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102ceb:	0f b6 c0             	movzbl %al,%eax
}
f0102cee:	5d                   	pop    %ebp
f0102cef:	c3                   	ret    

f0102cf0 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102cf0:	55                   	push   %ebp
f0102cf1:	89 e5                	mov    %esp,%ebp
}

static inline void
outb(int port, uint8_t data)
{
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102cf3:	ba 70 00 00 00       	mov    $0x70,%edx
f0102cf8:	8b 45 08             	mov    0x8(%ebp),%eax
f0102cfb:	ee                   	out    %al,(%dx)
f0102cfc:	b2 71                	mov    $0x71,%dl
f0102cfe:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d01:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102d02:	5d                   	pop    %ebp
f0102d03:	c3                   	ret    

f0102d04 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102d04:	55                   	push   %ebp
f0102d05:	89 e5                	mov    %esp,%ebp
f0102d07:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102d0a:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d0d:	89 04 24             	mov    %eax,(%esp)
f0102d10:	e8 a3 d8 ff ff       	call   f01005b8 <cputchar>
	*cnt++;
}
f0102d15:	c9                   	leave  
f0102d16:	c3                   	ret    

f0102d17 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102d17:	55                   	push   %ebp
f0102d18:	89 e5                	mov    %esp,%ebp
f0102d1a:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0102d1d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102d24:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102d27:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d2b:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d2e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102d32:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102d35:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d39:	c7 04 24 04 2d 10 f0 	movl   $0xf0102d04,(%esp)
f0102d40:	e8 11 04 00 00       	call   f0103156 <vprintfmt>
	return cnt;
}
f0102d45:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102d48:	c9                   	leave  
f0102d49:	c3                   	ret    

f0102d4a <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102d4a:	55                   	push   %ebp
f0102d4b:	89 e5                	mov    %esp,%ebp
f0102d4d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102d50:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102d53:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d57:	8b 45 08             	mov    0x8(%ebp),%eax
f0102d5a:	89 04 24             	mov    %eax,(%esp)
f0102d5d:	e8 b5 ff ff ff       	call   f0102d17 <vcprintf>
	va_end(ap);

	return cnt;
}
f0102d62:	c9                   	leave  
f0102d63:	c3                   	ret    

f0102d64 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102d64:	55                   	push   %ebp
f0102d65:	89 e5                	mov    %esp,%ebp
f0102d67:	57                   	push   %edi
f0102d68:	56                   	push   %esi
f0102d69:	53                   	push   %ebx
f0102d6a:	83 ec 10             	sub    $0x10,%esp
f0102d6d:	89 c3                	mov    %eax,%ebx
f0102d6f:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102d72:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0102d75:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102d78:	8b 0a                	mov    (%edx),%ecx
f0102d7a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102d7d:	8b 00                	mov    (%eax),%eax
f0102d7f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102d82:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0102d89:	eb 77                	jmp    f0102e02 <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f0102d8b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102d8e:	01 c8                	add    %ecx,%eax
f0102d90:	bf 02 00 00 00       	mov    $0x2,%edi
f0102d95:	99                   	cltd   
f0102d96:	f7 ff                	idiv   %edi
f0102d98:	89 c2                	mov    %eax,%edx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102d9a:	eb 01                	jmp    f0102d9d <stab_binsearch+0x39>
			m--;
f0102d9c:	4a                   	dec    %edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102d9d:	39 ca                	cmp    %ecx,%edx
f0102d9f:	7c 1d                	jl     f0102dbe <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102da1:	6b fa 0c             	imul   $0xc,%edx,%edi

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102da4:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0102da9:	39 f7                	cmp    %esi,%edi
f0102dab:	75 ef                	jne    f0102d9c <stab_binsearch+0x38>
f0102dad:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102db0:	6b fa 0c             	imul   $0xc,%edx,%edi
f0102db3:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0102db7:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0102dba:	73 18                	jae    f0102dd4 <stab_binsearch+0x70>
f0102dbc:	eb 05                	jmp    f0102dc3 <stab_binsearch+0x5f>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102dbe:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0102dc1:	eb 3f                	jmp    f0102e02 <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0102dc3:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0102dc6:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0102dc8:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102dcb:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102dd2:	eb 2e                	jmp    f0102e02 <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0102dd4:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0102dd7:	76 15                	jbe    f0102dee <stab_binsearch+0x8a>
			*region_right = m - 1;
f0102dd9:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0102ddc:	4f                   	dec    %edi
f0102ddd:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0102de0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102de3:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102de5:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0102dec:	eb 14                	jmp    f0102e02 <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0102dee:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0102df1:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0102df4:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0102df6:	ff 45 0c             	incl   0xc(%ebp)
f0102df9:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102dfb:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0102e02:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0102e05:	7e 84                	jle    f0102d8b <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0102e07:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102e0b:	75 0d                	jne    f0102e1a <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0102e0d:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102e10:	8b 02                	mov    (%edx),%eax
f0102e12:	48                   	dec    %eax
f0102e13:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102e16:	89 01                	mov    %eax,(%ecx)
f0102e18:	eb 22                	jmp    f0102e3c <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102e1a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102e1d:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102e1f:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102e22:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102e24:	eb 01                	jmp    f0102e27 <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0102e26:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102e27:	39 c1                	cmp    %eax,%ecx
f0102e29:	7d 0c                	jge    f0102e37 <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102e2b:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0102e2e:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0102e33:	39 f2                	cmp    %esi,%edx
f0102e35:	75 ef                	jne    f0102e26 <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0102e37:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102e3a:	89 02                	mov    %eax,(%edx)
	}
}
f0102e3c:	83 c4 10             	add    $0x10,%esp
f0102e3f:	5b                   	pop    %ebx
f0102e40:	5e                   	pop    %esi
f0102e41:	5f                   	pop    %edi
f0102e42:	5d                   	pop    %ebp
f0102e43:	c3                   	ret    

f0102e44 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0102e44:	55                   	push   %ebp
f0102e45:	89 e5                	mov    %esp,%ebp
f0102e47:	57                   	push   %edi
f0102e48:	56                   	push   %esi
f0102e49:	53                   	push   %ebx
f0102e4a:	83 ec 2c             	sub    $0x2c,%esp
f0102e4d:	8b 75 08             	mov    0x8(%ebp),%esi
f0102e50:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102e53:	c7 03 6e 4b 10 f0    	movl   $0xf0104b6e,(%ebx)
	info->eip_line = 0;
f0102e59:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0102e60:	c7 43 08 6e 4b 10 f0 	movl   $0xf0104b6e,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102e67:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0102e6e:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0102e71:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102e78:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102e7e:	76 12                	jbe    f0102e92 <debuginfo_eip+0x4e>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102e80:	b8 82 48 11 f0       	mov    $0xf0114882,%eax
f0102e85:	3d 59 b7 10 f0       	cmp    $0xf010b759,%eax
f0102e8a:	0f 86 50 01 00 00    	jbe    f0102fe0 <debuginfo_eip+0x19c>
f0102e90:	eb 1c                	jmp    f0102eae <debuginfo_eip+0x6a>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0102e92:	c7 44 24 08 78 4b 10 	movl   $0xf0104b78,0x8(%esp)
f0102e99:	f0 
f0102e9a:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0102ea1:	00 
f0102ea2:	c7 04 24 85 4b 10 f0 	movl   $0xf0104b85,(%esp)
f0102ea9:	e8 e6 d1 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102eae:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0102eb3:	80 3d 81 48 11 f0 00 	cmpb   $0x0,0xf0114881
f0102eba:	0f 85 2c 01 00 00    	jne    f0102fec <debuginfo_eip+0x1a8>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0102ec0:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0102ec7:	b8 58 b7 10 f0       	mov    $0xf010b758,%eax
f0102ecc:	2d a4 4d 10 f0       	sub    $0xf0104da4,%eax
f0102ed1:	c1 f8 02             	sar    $0x2,%eax
f0102ed4:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0102eda:	48                   	dec    %eax
f0102edb:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0102ede:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102ee2:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0102ee9:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0102eec:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0102eef:	b8 a4 4d 10 f0       	mov    $0xf0104da4,%eax
f0102ef4:	e8 6b fe ff ff       	call   f0102d64 <stab_binsearch>
	if (lfile == 0)
f0102ef9:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0102efc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0102f01:	85 d2                	test   %edx,%edx
f0102f03:	0f 84 e3 00 00 00    	je     f0102fec <debuginfo_eip+0x1a8>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102f09:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0102f0c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102f0f:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102f12:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102f16:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0102f1d:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102f20:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102f23:	b8 a4 4d 10 f0       	mov    $0xf0104da4,%eax
f0102f28:	e8 37 fe ff ff       	call   f0102d64 <stab_binsearch>

	if (lfun <= rfun) {
f0102f2d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0102f30:	3b 7d d8             	cmp    -0x28(%ebp),%edi
f0102f33:	7f 2e                	jg     f0102f63 <debuginfo_eip+0x11f>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102f35:	6b c7 0c             	imul   $0xc,%edi,%eax
f0102f38:	8d 90 a4 4d 10 f0    	lea    -0xfefb25c(%eax),%edx
f0102f3e:	8b 80 a4 4d 10 f0    	mov    -0xfefb25c(%eax),%eax
f0102f44:	b9 82 48 11 f0       	mov    $0xf0114882,%ecx
f0102f49:	81 e9 59 b7 10 f0    	sub    $0xf010b759,%ecx
f0102f4f:	39 c8                	cmp    %ecx,%eax
f0102f51:	73 08                	jae    f0102f5b <debuginfo_eip+0x117>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102f53:	05 59 b7 10 f0       	add    $0xf010b759,%eax
f0102f58:	89 43 08             	mov    %eax,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102f5b:	8b 42 08             	mov    0x8(%edx),%eax
f0102f5e:	89 43 10             	mov    %eax,0x10(%ebx)
f0102f61:	eb 06                	jmp    f0102f69 <debuginfo_eip+0x125>
		lline = lfun;
		rline = rfun;
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102f63:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102f66:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102f69:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0102f70:	00 
f0102f71:	8b 43 08             	mov    0x8(%ebx),%eax
f0102f74:	89 04 24             	mov    %eax,(%esp)
f0102f77:	e8 22 08 00 00       	call   f010379e <strfind>
f0102f7c:	2b 43 08             	sub    0x8(%ebx),%eax
f0102f7f:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102f82:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102f85:	eb 01                	jmp    f0102f88 <debuginfo_eip+0x144>
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0102f87:	4f                   	dec    %edi
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102f88:	39 cf                	cmp    %ecx,%edi
f0102f8a:	7c 24                	jl     f0102fb0 <debuginfo_eip+0x16c>
	       && stabs[lline].n_type != N_SOL
f0102f8c:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0102f8f:	8d 14 85 a4 4d 10 f0 	lea    -0xfefb25c(,%eax,4),%edx
f0102f96:	8a 42 04             	mov    0x4(%edx),%al
f0102f99:	3c 84                	cmp    $0x84,%al
f0102f9b:	74 57                	je     f0102ff4 <debuginfo_eip+0x1b0>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102f9d:	3c 64                	cmp    $0x64,%al
f0102f9f:	75 e6                	jne    f0102f87 <debuginfo_eip+0x143>
f0102fa1:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0102fa5:	74 e0                	je     f0102f87 <debuginfo_eip+0x143>
f0102fa7:	eb 4b                	jmp    f0102ff4 <debuginfo_eip+0x1b0>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102fa9:	05 59 b7 10 f0       	add    $0xf010b759,%eax
f0102fae:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102fb0:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0102fb3:	8b 55 d8             	mov    -0x28(%ebp),%edx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102fb6:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102fbb:	39 d1                	cmp    %edx,%ecx
f0102fbd:	7d 2d                	jge    f0102fec <debuginfo_eip+0x1a8>
		for (lline = lfun + 1;
f0102fbf:	8d 41 01             	lea    0x1(%ecx),%eax
f0102fc2:	eb 04                	jmp    f0102fc8 <debuginfo_eip+0x184>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0102fc4:	ff 43 14             	incl   0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0102fc7:	40                   	inc    %eax


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102fc8:	39 d0                	cmp    %edx,%eax
f0102fca:	74 1b                	je     f0102fe7 <debuginfo_eip+0x1a3>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102fcc:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f0102fcf:	80 3c 8d a8 4d 10 f0 	cmpb   $0xa0,-0xfefb258(,%ecx,4)
f0102fd6:	a0 
f0102fd7:	74 eb                	je     f0102fc4 <debuginfo_eip+0x180>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102fd9:	b8 00 00 00 00       	mov    $0x0,%eax
f0102fde:	eb 0c                	jmp    f0102fec <debuginfo_eip+0x1a8>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0102fe0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102fe5:	eb 05                	jmp    f0102fec <debuginfo_eip+0x1a8>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102fe7:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102fec:	83 c4 2c             	add    $0x2c,%esp
f0102fef:	5b                   	pop    %ebx
f0102ff0:	5e                   	pop    %esi
f0102ff1:	5f                   	pop    %edi
f0102ff2:	5d                   	pop    %ebp
f0102ff3:	c3                   	ret    
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0102ff4:	6b ff 0c             	imul   $0xc,%edi,%edi
f0102ff7:	8b 87 a4 4d 10 f0    	mov    -0xfefb25c(%edi),%eax
f0102ffd:	ba 82 48 11 f0       	mov    $0xf0114882,%edx
f0103002:	81 ea 59 b7 10 f0    	sub    $0xf010b759,%edx
f0103008:	39 d0                	cmp    %edx,%eax
f010300a:	72 9d                	jb     f0102fa9 <debuginfo_eip+0x165>
f010300c:	eb a2                	jmp    f0102fb0 <debuginfo_eip+0x16c>
	...

f0103010 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103010:	55                   	push   %ebp
f0103011:	89 e5                	mov    %esp,%ebp
f0103013:	57                   	push   %edi
f0103014:	56                   	push   %esi
f0103015:	53                   	push   %ebx
f0103016:	83 ec 3c             	sub    $0x3c,%esp
f0103019:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010301c:	89 d7                	mov    %edx,%edi
f010301e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103021:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103024:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103027:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010302a:	8b 5d 14             	mov    0x14(%ebp),%ebx
f010302d:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103030:	85 c0                	test   %eax,%eax
f0103032:	75 08                	jne    f010303c <printnum+0x2c>
f0103034:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103037:	39 45 10             	cmp    %eax,0x10(%ebp)
f010303a:	77 57                	ja     f0103093 <printnum+0x83>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010303c:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103040:	4b                   	dec    %ebx
f0103041:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103045:	8b 45 10             	mov    0x10(%ebp),%eax
f0103048:	89 44 24 08          	mov    %eax,0x8(%esp)
f010304c:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0103050:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0103054:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010305b:	00 
f010305c:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010305f:	89 04 24             	mov    %eax,(%esp)
f0103062:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103065:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103069:	e8 3e 09 00 00       	call   f01039ac <__udivdi3>
f010306e:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103072:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103076:	89 04 24             	mov    %eax,(%esp)
f0103079:	89 54 24 04          	mov    %edx,0x4(%esp)
f010307d:	89 fa                	mov    %edi,%edx
f010307f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103082:	e8 89 ff ff ff       	call   f0103010 <printnum>
f0103087:	eb 0f                	jmp    f0103098 <printnum+0x88>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0103089:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010308d:	89 34 24             	mov    %esi,(%esp)
f0103090:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103093:	4b                   	dec    %ebx
f0103094:	85 db                	test   %ebx,%ebx
f0103096:	7f f1                	jg     f0103089 <printnum+0x79>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103098:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010309c:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01030a0:	8b 45 10             	mov    0x10(%ebp),%eax
f01030a3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01030a7:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01030ae:	00 
f01030af:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01030b2:	89 04 24             	mov    %eax,(%esp)
f01030b5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01030b8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01030bc:	e8 0b 0a 00 00       	call   f0103acc <__umoddi3>
f01030c1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01030c5:	0f be 80 93 4b 10 f0 	movsbl -0xfefb46d(%eax),%eax
f01030cc:	89 04 24             	mov    %eax,(%esp)
f01030cf:	ff 55 e4             	call   *-0x1c(%ebp)
}
f01030d2:	83 c4 3c             	add    $0x3c,%esp
f01030d5:	5b                   	pop    %ebx
f01030d6:	5e                   	pop    %esi
f01030d7:	5f                   	pop    %edi
f01030d8:	5d                   	pop    %ebp
f01030d9:	c3                   	ret    

f01030da <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01030da:	55                   	push   %ebp
f01030db:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01030dd:	83 fa 01             	cmp    $0x1,%edx
f01030e0:	7e 0e                	jle    f01030f0 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01030e2:	8b 10                	mov    (%eax),%edx
f01030e4:	8d 4a 08             	lea    0x8(%edx),%ecx
f01030e7:	89 08                	mov    %ecx,(%eax)
f01030e9:	8b 02                	mov    (%edx),%eax
f01030eb:	8b 52 04             	mov    0x4(%edx),%edx
f01030ee:	eb 22                	jmp    f0103112 <getuint+0x38>
	else if (lflag)
f01030f0:	85 d2                	test   %edx,%edx
f01030f2:	74 10                	je     f0103104 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01030f4:	8b 10                	mov    (%eax),%edx
f01030f6:	8d 4a 04             	lea    0x4(%edx),%ecx
f01030f9:	89 08                	mov    %ecx,(%eax)
f01030fb:	8b 02                	mov    (%edx),%eax
f01030fd:	ba 00 00 00 00       	mov    $0x0,%edx
f0103102:	eb 0e                	jmp    f0103112 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103104:	8b 10                	mov    (%eax),%edx
f0103106:	8d 4a 04             	lea    0x4(%edx),%ecx
f0103109:	89 08                	mov    %ecx,(%eax)
f010310b:	8b 02                	mov    (%edx),%eax
f010310d:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103112:	5d                   	pop    %ebp
f0103113:	c3                   	ret    

f0103114 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103114:	55                   	push   %ebp
f0103115:	89 e5                	mov    %esp,%ebp
f0103117:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010311a:	ff 40 08             	incl   0x8(%eax)
	if (b->buf < b->ebuf)
f010311d:	8b 10                	mov    (%eax),%edx
f010311f:	3b 50 04             	cmp    0x4(%eax),%edx
f0103122:	73 08                	jae    f010312c <sprintputch+0x18>
		*b->buf++ = ch;
f0103124:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103127:	88 0a                	mov    %cl,(%edx)
f0103129:	42                   	inc    %edx
f010312a:	89 10                	mov    %edx,(%eax)
}
f010312c:	5d                   	pop    %ebp
f010312d:	c3                   	ret    

f010312e <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f010312e:	55                   	push   %ebp
f010312f:	89 e5                	mov    %esp,%ebp
f0103131:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0103134:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103137:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010313b:	8b 45 10             	mov    0x10(%ebp),%eax
f010313e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103142:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103145:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103149:	8b 45 08             	mov    0x8(%ebp),%eax
f010314c:	89 04 24             	mov    %eax,(%esp)
f010314f:	e8 02 00 00 00       	call   f0103156 <vprintfmt>
	va_end(ap);
}
f0103154:	c9                   	leave  
f0103155:	c3                   	ret    

f0103156 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103156:	55                   	push   %ebp
f0103157:	89 e5                	mov    %esp,%ebp
f0103159:	57                   	push   %edi
f010315a:	56                   	push   %esi
f010315b:	53                   	push   %ebx
f010315c:	83 ec 4c             	sub    $0x4c,%esp
f010315f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103162:	8b 75 10             	mov    0x10(%ebp),%esi
f0103165:	eb 12                	jmp    f0103179 <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103167:	85 c0                	test   %eax,%eax
f0103169:	0f 84 8b 03 00 00    	je     f01034fa <vprintfmt+0x3a4>
				return;
			putch(ch, putdat);
f010316f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103173:	89 04 24             	mov    %eax,(%esp)
f0103176:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103179:	0f b6 06             	movzbl (%esi),%eax
f010317c:	46                   	inc    %esi
f010317d:	83 f8 25             	cmp    $0x25,%eax
f0103180:	75 e5                	jne    f0103167 <vprintfmt+0x11>
f0103182:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0103186:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f010318d:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0103192:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0103199:	b9 00 00 00 00       	mov    $0x0,%ecx
f010319e:	eb 26                	jmp    f01031c6 <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01031a0:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f01031a3:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f01031a7:	eb 1d                	jmp    f01031c6 <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01031a9:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01031ac:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f01031b0:	eb 14                	jmp    f01031c6 <vprintfmt+0x70>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01031b2:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f01031b5:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f01031bc:	eb 08                	jmp    f01031c6 <vprintfmt+0x70>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f01031be:	89 7d e4             	mov    %edi,-0x1c(%ebp)
f01031c1:	bf ff ff ff ff       	mov    $0xffffffff,%edi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01031c6:	0f b6 06             	movzbl (%esi),%eax
f01031c9:	8d 56 01             	lea    0x1(%esi),%edx
f01031cc:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01031cf:	8a 16                	mov    (%esi),%dl
f01031d1:	83 ea 23             	sub    $0x23,%edx
f01031d4:	80 fa 55             	cmp    $0x55,%dl
f01031d7:	0f 87 01 03 00 00    	ja     f01034de <vprintfmt+0x388>
f01031dd:	0f b6 d2             	movzbl %dl,%edx
f01031e0:	ff 24 95 20 4c 10 f0 	jmp    *-0xfefb3e0(,%edx,4)
f01031e7:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01031ea:	bf 00 00 00 00       	mov    $0x0,%edi
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01031ef:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f01031f2:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f01031f6:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f01031f9:	8d 50 d0             	lea    -0x30(%eax),%edx
f01031fc:	83 fa 09             	cmp    $0x9,%edx
f01031ff:	77 2a                	ja     f010322b <vprintfmt+0xd5>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103201:	46                   	inc    %esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0103202:	eb eb                	jmp    f01031ef <vprintfmt+0x99>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103204:	8b 45 14             	mov    0x14(%ebp),%eax
f0103207:	8d 50 04             	lea    0x4(%eax),%edx
f010320a:	89 55 14             	mov    %edx,0x14(%ebp)
f010320d:	8b 38                	mov    (%eax),%edi
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010320f:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103212:	eb 17                	jmp    f010322b <vprintfmt+0xd5>

		case '.':
			if (width < 0)
f0103214:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103218:	78 98                	js     f01031b2 <vprintfmt+0x5c>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010321a:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010321d:	eb a7                	jmp    f01031c6 <vprintfmt+0x70>
f010321f:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103222:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0103229:	eb 9b                	jmp    f01031c6 <vprintfmt+0x70>

		process_precision:
			if (width < 0)
f010322b:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010322f:	79 95                	jns    f01031c6 <vprintfmt+0x70>
f0103231:	eb 8b                	jmp    f01031be <vprintfmt+0x68>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103233:	41                   	inc    %ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103234:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103237:	eb 8d                	jmp    f01031c6 <vprintfmt+0x70>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103239:	8b 45 14             	mov    0x14(%ebp),%eax
f010323c:	8d 50 04             	lea    0x4(%eax),%edx
f010323f:	89 55 14             	mov    %edx,0x14(%ebp)
f0103242:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103246:	8b 00                	mov    (%eax),%eax
f0103248:	89 04 24             	mov    %eax,(%esp)
f010324b:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010324e:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103251:	e9 23 ff ff ff       	jmp    f0103179 <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103256:	8b 45 14             	mov    0x14(%ebp),%eax
f0103259:	8d 50 04             	lea    0x4(%eax),%edx
f010325c:	89 55 14             	mov    %edx,0x14(%ebp)
f010325f:	8b 00                	mov    (%eax),%eax
f0103261:	85 c0                	test   %eax,%eax
f0103263:	79 02                	jns    f0103267 <vprintfmt+0x111>
f0103265:	f7 d8                	neg    %eax
f0103267:	89 c2                	mov    %eax,%edx
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103269:	83 f8 06             	cmp    $0x6,%eax
f010326c:	7f 0b                	jg     f0103279 <vprintfmt+0x123>
f010326e:	8b 04 85 78 4d 10 f0 	mov    -0xfefb288(,%eax,4),%eax
f0103275:	85 c0                	test   %eax,%eax
f0103277:	75 23                	jne    f010329c <vprintfmt+0x146>
				printfmt(putch, putdat, "error %d", err);
f0103279:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010327d:	c7 44 24 08 ab 4b 10 	movl   $0xf0104bab,0x8(%esp)
f0103284:	f0 
f0103285:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103289:	8b 45 08             	mov    0x8(%ebp),%eax
f010328c:	89 04 24             	mov    %eax,(%esp)
f010328f:	e8 9a fe ff ff       	call   f010312e <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103294:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103297:	e9 dd fe ff ff       	jmp    f0103179 <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f010329c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01032a0:	c7 44 24 08 7b 48 10 	movl   $0xf010487b,0x8(%esp)
f01032a7:	f0 
f01032a8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01032ac:	8b 55 08             	mov    0x8(%ebp),%edx
f01032af:	89 14 24             	mov    %edx,(%esp)
f01032b2:	e8 77 fe ff ff       	call   f010312e <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01032b7:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01032ba:	e9 ba fe ff ff       	jmp    f0103179 <vprintfmt+0x23>
f01032bf:	89 f9                	mov    %edi,%ecx
f01032c1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01032c4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01032c7:	8b 45 14             	mov    0x14(%ebp),%eax
f01032ca:	8d 50 04             	lea    0x4(%eax),%edx
f01032cd:	89 55 14             	mov    %edx,0x14(%ebp)
f01032d0:	8b 30                	mov    (%eax),%esi
f01032d2:	85 f6                	test   %esi,%esi
f01032d4:	75 05                	jne    f01032db <vprintfmt+0x185>
				p = "(null)";
f01032d6:	be a4 4b 10 f0       	mov    $0xf0104ba4,%esi
			if (width > 0 && padc != '-')
f01032db:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01032df:	0f 8e 84 00 00 00    	jle    f0103369 <vprintfmt+0x213>
f01032e5:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f01032e9:	74 7e                	je     f0103369 <vprintfmt+0x213>
				for (width -= strnlen(p, precision); width > 0; width--)
f01032eb:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01032ef:	89 34 24             	mov    %esi,(%esp)
f01032f2:	e8 73 03 00 00       	call   f010366a <strnlen>
f01032f7:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01032fa:	29 c2                	sub    %eax,%edx
f01032fc:	89 55 e4             	mov    %edx,-0x1c(%ebp)
					putch(padc, putdat);
f01032ff:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0103303:	89 75 d0             	mov    %esi,-0x30(%ebp)
f0103306:	89 7d cc             	mov    %edi,-0x34(%ebp)
f0103309:	89 de                	mov    %ebx,%esi
f010330b:	89 d3                	mov    %edx,%ebx
f010330d:	89 c7                	mov    %eax,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010330f:	eb 0b                	jmp    f010331c <vprintfmt+0x1c6>
					putch(padc, putdat);
f0103311:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103315:	89 3c 24             	mov    %edi,(%esp)
f0103318:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010331b:	4b                   	dec    %ebx
f010331c:	85 db                	test   %ebx,%ebx
f010331e:	7f f1                	jg     f0103311 <vprintfmt+0x1bb>
f0103320:	8b 7d cc             	mov    -0x34(%ebp),%edi
f0103323:	89 f3                	mov    %esi,%ebx
f0103325:	8b 75 d0             	mov    -0x30(%ebp),%esi

// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
f0103328:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010332b:	85 c0                	test   %eax,%eax
f010332d:	79 05                	jns    f0103334 <vprintfmt+0x1de>
f010332f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103334:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103337:	29 c2                	sub    %eax,%edx
f0103339:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010333c:	eb 2b                	jmp    f0103369 <vprintfmt+0x213>
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010333e:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103342:	74 18                	je     f010335c <vprintfmt+0x206>
f0103344:	8d 50 e0             	lea    -0x20(%eax),%edx
f0103347:	83 fa 5e             	cmp    $0x5e,%edx
f010334a:	76 10                	jbe    f010335c <vprintfmt+0x206>
					putch('?', putdat);
f010334c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103350:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0103357:	ff 55 08             	call   *0x8(%ebp)
f010335a:	eb 0a                	jmp    f0103366 <vprintfmt+0x210>
				else
					putch(ch, putdat);
f010335c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103360:	89 04 24             	mov    %eax,(%esp)
f0103363:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103366:	ff 4d e4             	decl   -0x1c(%ebp)
f0103369:	0f be 06             	movsbl (%esi),%eax
f010336c:	46                   	inc    %esi
f010336d:	85 c0                	test   %eax,%eax
f010336f:	74 21                	je     f0103392 <vprintfmt+0x23c>
f0103371:	85 ff                	test   %edi,%edi
f0103373:	78 c9                	js     f010333e <vprintfmt+0x1e8>
f0103375:	4f                   	dec    %edi
f0103376:	79 c6                	jns    f010333e <vprintfmt+0x1e8>
f0103378:	8b 7d 08             	mov    0x8(%ebp),%edi
f010337b:	89 de                	mov    %ebx,%esi
f010337d:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103380:	eb 18                	jmp    f010339a <vprintfmt+0x244>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103382:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103386:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f010338d:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f010338f:	4b                   	dec    %ebx
f0103390:	eb 08                	jmp    f010339a <vprintfmt+0x244>
f0103392:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103395:	89 de                	mov    %ebx,%esi
f0103397:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010339a:	85 db                	test   %ebx,%ebx
f010339c:	7f e4                	jg     f0103382 <vprintfmt+0x22c>
f010339e:	89 7d 08             	mov    %edi,0x8(%ebp)
f01033a1:	89 f3                	mov    %esi,%ebx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01033a3:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01033a6:	e9 ce fd ff ff       	jmp    f0103179 <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01033ab:	83 f9 01             	cmp    $0x1,%ecx
f01033ae:	7e 10                	jle    f01033c0 <vprintfmt+0x26a>
		return va_arg(*ap, long long);
f01033b0:	8b 45 14             	mov    0x14(%ebp),%eax
f01033b3:	8d 50 08             	lea    0x8(%eax),%edx
f01033b6:	89 55 14             	mov    %edx,0x14(%ebp)
f01033b9:	8b 30                	mov    (%eax),%esi
f01033bb:	8b 78 04             	mov    0x4(%eax),%edi
f01033be:	eb 26                	jmp    f01033e6 <vprintfmt+0x290>
	else if (lflag)
f01033c0:	85 c9                	test   %ecx,%ecx
f01033c2:	74 12                	je     f01033d6 <vprintfmt+0x280>
		return va_arg(*ap, long);
f01033c4:	8b 45 14             	mov    0x14(%ebp),%eax
f01033c7:	8d 50 04             	lea    0x4(%eax),%edx
f01033ca:	89 55 14             	mov    %edx,0x14(%ebp)
f01033cd:	8b 30                	mov    (%eax),%esi
f01033cf:	89 f7                	mov    %esi,%edi
f01033d1:	c1 ff 1f             	sar    $0x1f,%edi
f01033d4:	eb 10                	jmp    f01033e6 <vprintfmt+0x290>
	else
		return va_arg(*ap, int);
f01033d6:	8b 45 14             	mov    0x14(%ebp),%eax
f01033d9:	8d 50 04             	lea    0x4(%eax),%edx
f01033dc:	89 55 14             	mov    %edx,0x14(%ebp)
f01033df:	8b 30                	mov    (%eax),%esi
f01033e1:	89 f7                	mov    %esi,%edi
f01033e3:	c1 ff 1f             	sar    $0x1f,%edi
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01033e6:	85 ff                	test   %edi,%edi
f01033e8:	78 0a                	js     f01033f4 <vprintfmt+0x29e>
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01033ea:	b8 0a 00 00 00       	mov    $0xa,%eax
f01033ef:	e9 ac 00 00 00       	jmp    f01034a0 <vprintfmt+0x34a>

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
f01033f4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01033f8:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01033ff:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0103402:	f7 de                	neg    %esi
f0103404:	83 d7 00             	adc    $0x0,%edi
f0103407:	f7 df                	neg    %edi
			}
			base = 10;
f0103409:	b8 0a 00 00 00       	mov    $0xa,%eax
f010340e:	e9 8d 00 00 00       	jmp    f01034a0 <vprintfmt+0x34a>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103413:	89 ca                	mov    %ecx,%edx
f0103415:	8d 45 14             	lea    0x14(%ebp),%eax
f0103418:	e8 bd fc ff ff       	call   f01030da <getuint>
f010341d:	89 c6                	mov    %eax,%esi
f010341f:	89 d7                	mov    %edx,%edi
			base = 10;
f0103421:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f0103426:	eb 78                	jmp    f01034a0 <vprintfmt+0x34a>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
f0103428:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010342c:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0103433:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f0103436:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010343a:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f0103441:	ff 55 08             	call   *0x8(%ebp)
			putch('X', putdat);
f0103444:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103448:	c7 04 24 58 00 00 00 	movl   $0x58,(%esp)
f010344f:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103452:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'o':
			// Replace this with your code.
			putch('X', putdat);
			putch('X', putdat);
			putch('X', putdat);
			break;
f0103455:	e9 1f fd ff ff       	jmp    f0103179 <vprintfmt+0x23>

		// pointer
		case 'p':
			putch('0', putdat);
f010345a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010345e:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0103465:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0103468:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010346c:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0103473:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103476:	8b 45 14             	mov    0x14(%ebp),%eax
f0103479:	8d 50 04             	lea    0x4(%eax),%edx
f010347c:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f010347f:	8b 30                	mov    (%eax),%esi
f0103481:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0103486:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f010348b:	eb 13                	jmp    f01034a0 <vprintfmt+0x34a>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f010348d:	89 ca                	mov    %ecx,%edx
f010348f:	8d 45 14             	lea    0x14(%ebp),%eax
f0103492:	e8 43 fc ff ff       	call   f01030da <getuint>
f0103497:	89 c6                	mov    %eax,%esi
f0103499:	89 d7                	mov    %edx,%edi
			base = 16;
f010349b:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f01034a0:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f01034a4:	89 54 24 10          	mov    %edx,0x10(%esp)
f01034a8:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01034ab:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01034af:	89 44 24 08          	mov    %eax,0x8(%esp)
f01034b3:	89 34 24             	mov    %esi,(%esp)
f01034b6:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01034ba:	89 da                	mov    %ebx,%edx
f01034bc:	8b 45 08             	mov    0x8(%ebp),%eax
f01034bf:	e8 4c fb ff ff       	call   f0103010 <printnum>
			break;
f01034c4:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01034c7:	e9 ad fc ff ff       	jmp    f0103179 <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01034cc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01034d0:	89 04 24             	mov    %eax,(%esp)
f01034d3:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01034d6:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01034d9:	e9 9b fc ff ff       	jmp    f0103179 <vprintfmt+0x23>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01034de:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01034e2:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01034e9:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01034ec:	eb 01                	jmp    f01034ef <vprintfmt+0x399>
f01034ee:	4e                   	dec    %esi
f01034ef:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f01034f3:	75 f9                	jne    f01034ee <vprintfmt+0x398>
f01034f5:	e9 7f fc ff ff       	jmp    f0103179 <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f01034fa:	83 c4 4c             	add    $0x4c,%esp
f01034fd:	5b                   	pop    %ebx
f01034fe:	5e                   	pop    %esi
f01034ff:	5f                   	pop    %edi
f0103500:	5d                   	pop    %ebp
f0103501:	c3                   	ret    

f0103502 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103502:	55                   	push   %ebp
f0103503:	89 e5                	mov    %esp,%ebp
f0103505:	83 ec 28             	sub    $0x28,%esp
f0103508:	8b 45 08             	mov    0x8(%ebp),%eax
f010350b:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f010350e:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103511:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103515:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103518:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010351f:	85 c0                	test   %eax,%eax
f0103521:	74 30                	je     f0103553 <vsnprintf+0x51>
f0103523:	85 d2                	test   %edx,%edx
f0103525:	7e 33                	jle    f010355a <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103527:	8b 45 14             	mov    0x14(%ebp),%eax
f010352a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010352e:	8b 45 10             	mov    0x10(%ebp),%eax
f0103531:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103535:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103538:	89 44 24 04          	mov    %eax,0x4(%esp)
f010353c:	c7 04 24 14 31 10 f0 	movl   $0xf0103114,(%esp)
f0103543:	e8 0e fc ff ff       	call   f0103156 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103548:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010354b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010354e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103551:	eb 0c                	jmp    f010355f <vsnprintf+0x5d>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103553:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0103558:	eb 05                	jmp    f010355f <vsnprintf+0x5d>
f010355a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010355f:	c9                   	leave  
f0103560:	c3                   	ret    

f0103561 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103561:	55                   	push   %ebp
f0103562:	89 e5                	mov    %esp,%ebp
f0103564:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103567:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f010356a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010356e:	8b 45 10             	mov    0x10(%ebp),%eax
f0103571:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103575:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103578:	89 44 24 04          	mov    %eax,0x4(%esp)
f010357c:	8b 45 08             	mov    0x8(%ebp),%eax
f010357f:	89 04 24             	mov    %eax,(%esp)
f0103582:	e8 7b ff ff ff       	call   f0103502 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103587:	c9                   	leave  
f0103588:	c3                   	ret    
f0103589:	00 00                	add    %al,(%eax)
	...

f010358c <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f010358c:	55                   	push   %ebp
f010358d:	89 e5                	mov    %esp,%ebp
f010358f:	57                   	push   %edi
f0103590:	56                   	push   %esi
f0103591:	53                   	push   %ebx
f0103592:	83 ec 1c             	sub    $0x1c,%esp
f0103595:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103598:	85 c0                	test   %eax,%eax
f010359a:	74 10                	je     f01035ac <readline+0x20>
		cprintf("%s", prompt);
f010359c:	89 44 24 04          	mov    %eax,0x4(%esp)
f01035a0:	c7 04 24 7b 48 10 f0 	movl   $0xf010487b,(%esp)
f01035a7:	e8 9e f7 ff ff       	call   f0102d4a <cprintf>

	i = 0;
	echoing = iscons(0);
f01035ac:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01035b3:	e8 21 d0 ff ff       	call   f01005d9 <iscons>
f01035b8:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01035ba:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01035bf:	e8 04 d0 ff ff       	call   f01005c8 <getchar>
f01035c4:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01035c6:	85 c0                	test   %eax,%eax
f01035c8:	79 17                	jns    f01035e1 <readline+0x55>
			cprintf("read error: %e\n", c);
f01035ca:	89 44 24 04          	mov    %eax,0x4(%esp)
f01035ce:	c7 04 24 94 4d 10 f0 	movl   $0xf0104d94,(%esp)
f01035d5:	e8 70 f7 ff ff       	call   f0102d4a <cprintf>
			return NULL;
f01035da:	b8 00 00 00 00       	mov    $0x0,%eax
f01035df:	eb 69                	jmp    f010364a <readline+0xbe>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01035e1:	83 f8 08             	cmp    $0x8,%eax
f01035e4:	74 05                	je     f01035eb <readline+0x5f>
f01035e6:	83 f8 7f             	cmp    $0x7f,%eax
f01035e9:	75 17                	jne    f0103602 <readline+0x76>
f01035eb:	85 f6                	test   %esi,%esi
f01035ed:	7e 13                	jle    f0103602 <readline+0x76>
			if (echoing)
f01035ef:	85 ff                	test   %edi,%edi
f01035f1:	74 0c                	je     f01035ff <readline+0x73>
				cputchar('\b');
f01035f3:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01035fa:	e8 b9 cf ff ff       	call   f01005b8 <cputchar>
			i--;
f01035ff:	4e                   	dec    %esi
f0103600:	eb bd                	jmp    f01035bf <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103602:	83 fb 1f             	cmp    $0x1f,%ebx
f0103605:	7e 1d                	jle    f0103624 <readline+0x98>
f0103607:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010360d:	7f 15                	jg     f0103624 <readline+0x98>
			if (echoing)
f010360f:	85 ff                	test   %edi,%edi
f0103611:	74 08                	je     f010361b <readline+0x8f>
				cputchar(c);
f0103613:	89 1c 24             	mov    %ebx,(%esp)
f0103616:	e8 9d cf ff ff       	call   f01005b8 <cputchar>
			buf[i++] = c;
f010361b:	88 9e 60 f5 11 f0    	mov    %bl,-0xfee0aa0(%esi)
f0103621:	46                   	inc    %esi
f0103622:	eb 9b                	jmp    f01035bf <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0103624:	83 fb 0a             	cmp    $0xa,%ebx
f0103627:	74 05                	je     f010362e <readline+0xa2>
f0103629:	83 fb 0d             	cmp    $0xd,%ebx
f010362c:	75 91                	jne    f01035bf <readline+0x33>
			if (echoing)
f010362e:	85 ff                	test   %edi,%edi
f0103630:	74 0c                	je     f010363e <readline+0xb2>
				cputchar('\n');
f0103632:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0103639:	e8 7a cf ff ff       	call   f01005b8 <cputchar>
			buf[i] = 0;
f010363e:	c6 86 60 f5 11 f0 00 	movb   $0x0,-0xfee0aa0(%esi)
			return buf;
f0103645:	b8 60 f5 11 f0       	mov    $0xf011f560,%eax
		}
	}
}
f010364a:	83 c4 1c             	add    $0x1c,%esp
f010364d:	5b                   	pop    %ebx
f010364e:	5e                   	pop    %esi
f010364f:	5f                   	pop    %edi
f0103650:	5d                   	pop    %ebp
f0103651:	c3                   	ret    
	...

f0103654 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103654:	55                   	push   %ebp
f0103655:	89 e5                	mov    %esp,%ebp
f0103657:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f010365a:	b8 00 00 00 00       	mov    $0x0,%eax
f010365f:	eb 01                	jmp    f0103662 <strlen+0xe>
		n++;
f0103661:	40                   	inc    %eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103662:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103666:	75 f9                	jne    f0103661 <strlen+0xd>
		n++;
	return n;
}
f0103668:	5d                   	pop    %ebp
f0103669:	c3                   	ret    

f010366a <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010366a:	55                   	push   %ebp
f010366b:	89 e5                	mov    %esp,%ebp
f010366d:	8b 4d 08             	mov    0x8(%ebp),%ecx
		n++;
	return n;
}

int
strnlen(const char *s, size_t size)
f0103670:	8b 55 0c             	mov    0xc(%ebp),%edx
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103673:	b8 00 00 00 00       	mov    $0x0,%eax
f0103678:	eb 01                	jmp    f010367b <strnlen+0x11>
		n++;
f010367a:	40                   	inc    %eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010367b:	39 d0                	cmp    %edx,%eax
f010367d:	74 06                	je     f0103685 <strnlen+0x1b>
f010367f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0103683:	75 f5                	jne    f010367a <strnlen+0x10>
		n++;
	return n;
}
f0103685:	5d                   	pop    %ebp
f0103686:	c3                   	ret    

f0103687 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103687:	55                   	push   %ebp
f0103688:	89 e5                	mov    %esp,%ebp
f010368a:	53                   	push   %ebx
f010368b:	8b 45 08             	mov    0x8(%ebp),%eax
f010368e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103691:	ba 00 00 00 00       	mov    $0x0,%edx
f0103696:	8a 0c 13             	mov    (%ebx,%edx,1),%cl
f0103699:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f010369c:	42                   	inc    %edx
f010369d:	84 c9                	test   %cl,%cl
f010369f:	75 f5                	jne    f0103696 <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f01036a1:	5b                   	pop    %ebx
f01036a2:	5d                   	pop    %ebp
f01036a3:	c3                   	ret    

f01036a4 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01036a4:	55                   	push   %ebp
f01036a5:	89 e5                	mov    %esp,%ebp
f01036a7:	53                   	push   %ebx
f01036a8:	83 ec 08             	sub    $0x8,%esp
f01036ab:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01036ae:	89 1c 24             	mov    %ebx,(%esp)
f01036b1:	e8 9e ff ff ff       	call   f0103654 <strlen>
	strcpy(dst + len, src);
f01036b6:	8b 55 0c             	mov    0xc(%ebp),%edx
f01036b9:	89 54 24 04          	mov    %edx,0x4(%esp)
f01036bd:	01 d8                	add    %ebx,%eax
f01036bf:	89 04 24             	mov    %eax,(%esp)
f01036c2:	e8 c0 ff ff ff       	call   f0103687 <strcpy>
	return dst;
}
f01036c7:	89 d8                	mov    %ebx,%eax
f01036c9:	83 c4 08             	add    $0x8,%esp
f01036cc:	5b                   	pop    %ebx
f01036cd:	5d                   	pop    %ebp
f01036ce:	c3                   	ret    

f01036cf <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01036cf:	55                   	push   %ebp
f01036d0:	89 e5                	mov    %esp,%ebp
f01036d2:	56                   	push   %esi
f01036d3:	53                   	push   %ebx
f01036d4:	8b 45 08             	mov    0x8(%ebp),%eax
f01036d7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01036da:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01036dd:	b9 00 00 00 00       	mov    $0x0,%ecx
f01036e2:	eb 0c                	jmp    f01036f0 <strncpy+0x21>
		*dst++ = *src;
f01036e4:	8a 1a                	mov    (%edx),%bl
f01036e6:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01036e9:	80 3a 01             	cmpb   $0x1,(%edx)
f01036ec:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01036ef:	41                   	inc    %ecx
f01036f0:	39 f1                	cmp    %esi,%ecx
f01036f2:	75 f0                	jne    f01036e4 <strncpy+0x15>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01036f4:	5b                   	pop    %ebx
f01036f5:	5e                   	pop    %esi
f01036f6:	5d                   	pop    %ebp
f01036f7:	c3                   	ret    

f01036f8 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01036f8:	55                   	push   %ebp
f01036f9:	89 e5                	mov    %esp,%ebp
f01036fb:	56                   	push   %esi
f01036fc:	53                   	push   %ebx
f01036fd:	8b 75 08             	mov    0x8(%ebp),%esi
f0103700:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103703:	8b 55 10             	mov    0x10(%ebp),%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103706:	85 d2                	test   %edx,%edx
f0103708:	75 0a                	jne    f0103714 <strlcpy+0x1c>
f010370a:	89 f0                	mov    %esi,%eax
f010370c:	eb 1a                	jmp    f0103728 <strlcpy+0x30>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010370e:	88 18                	mov    %bl,(%eax)
f0103710:	40                   	inc    %eax
f0103711:	41                   	inc    %ecx
f0103712:	eb 02                	jmp    f0103716 <strlcpy+0x1e>
strlcpy(char *dst, const char *src, size_t size)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103714:	89 f0                	mov    %esi,%eax
		while (--size > 0 && *src != '\0')
f0103716:	4a                   	dec    %edx
f0103717:	74 0a                	je     f0103723 <strlcpy+0x2b>
f0103719:	8a 19                	mov    (%ecx),%bl
f010371b:	84 db                	test   %bl,%bl
f010371d:	75 ef                	jne    f010370e <strlcpy+0x16>
f010371f:	89 c2                	mov    %eax,%edx
f0103721:	eb 02                	jmp    f0103725 <strlcpy+0x2d>
f0103723:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0103725:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0103728:	29 f0                	sub    %esi,%eax
}
f010372a:	5b                   	pop    %ebx
f010372b:	5e                   	pop    %esi
f010372c:	5d                   	pop    %ebp
f010372d:	c3                   	ret    

f010372e <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010372e:	55                   	push   %ebp
f010372f:	89 e5                	mov    %esp,%ebp
f0103731:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103734:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103737:	eb 02                	jmp    f010373b <strcmp+0xd>
		p++, q++;
f0103739:	41                   	inc    %ecx
f010373a:	42                   	inc    %edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010373b:	8a 01                	mov    (%ecx),%al
f010373d:	84 c0                	test   %al,%al
f010373f:	74 04                	je     f0103745 <strcmp+0x17>
f0103741:	3a 02                	cmp    (%edx),%al
f0103743:	74 f4                	je     f0103739 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103745:	0f b6 c0             	movzbl %al,%eax
f0103748:	0f b6 12             	movzbl (%edx),%edx
f010374b:	29 d0                	sub    %edx,%eax
}
f010374d:	5d                   	pop    %ebp
f010374e:	c3                   	ret    

f010374f <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010374f:	55                   	push   %ebp
f0103750:	89 e5                	mov    %esp,%ebp
f0103752:	53                   	push   %ebx
f0103753:	8b 45 08             	mov    0x8(%ebp),%eax
f0103756:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103759:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
f010375c:	eb 03                	jmp    f0103761 <strncmp+0x12>
		n--, p++, q++;
f010375e:	4a                   	dec    %edx
f010375f:	40                   	inc    %eax
f0103760:	41                   	inc    %ecx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103761:	85 d2                	test   %edx,%edx
f0103763:	74 14                	je     f0103779 <strncmp+0x2a>
f0103765:	8a 18                	mov    (%eax),%bl
f0103767:	84 db                	test   %bl,%bl
f0103769:	74 04                	je     f010376f <strncmp+0x20>
f010376b:	3a 19                	cmp    (%ecx),%bl
f010376d:	74 ef                	je     f010375e <strncmp+0xf>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010376f:	0f b6 00             	movzbl (%eax),%eax
f0103772:	0f b6 11             	movzbl (%ecx),%edx
f0103775:	29 d0                	sub    %edx,%eax
f0103777:	eb 05                	jmp    f010377e <strncmp+0x2f>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103779:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f010377e:	5b                   	pop    %ebx
f010377f:	5d                   	pop    %ebp
f0103780:	c3                   	ret    

f0103781 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103781:	55                   	push   %ebp
f0103782:	89 e5                	mov    %esp,%ebp
f0103784:	8b 45 08             	mov    0x8(%ebp),%eax
f0103787:	8a 4d 0c             	mov    0xc(%ebp),%cl
	for (; *s; s++)
f010378a:	eb 05                	jmp    f0103791 <strchr+0x10>
		if (*s == c)
f010378c:	38 ca                	cmp    %cl,%dl
f010378e:	74 0c                	je     f010379c <strchr+0x1b>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103790:	40                   	inc    %eax
f0103791:	8a 10                	mov    (%eax),%dl
f0103793:	84 d2                	test   %dl,%dl
f0103795:	75 f5                	jne    f010378c <strchr+0xb>
		if (*s == c)
			return (char *) s;
	return 0;
f0103797:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010379c:	5d                   	pop    %ebp
f010379d:	c3                   	ret    

f010379e <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010379e:	55                   	push   %ebp
f010379f:	89 e5                	mov    %esp,%ebp
f01037a1:	8b 45 08             	mov    0x8(%ebp),%eax
f01037a4:	8a 4d 0c             	mov    0xc(%ebp),%cl
	for (; *s; s++)
f01037a7:	eb 05                	jmp    f01037ae <strfind+0x10>
		if (*s == c)
f01037a9:	38 ca                	cmp    %cl,%dl
f01037ab:	74 07                	je     f01037b4 <strfind+0x16>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01037ad:	40                   	inc    %eax
f01037ae:	8a 10                	mov    (%eax),%dl
f01037b0:	84 d2                	test   %dl,%dl
f01037b2:	75 f5                	jne    f01037a9 <strfind+0xb>
		if (*s == c)
			break;
	return (char *) s;
}
f01037b4:	5d                   	pop    %ebp
f01037b5:	c3                   	ret    

f01037b6 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01037b6:	55                   	push   %ebp
f01037b7:	89 e5                	mov    %esp,%ebp
f01037b9:	57                   	push   %edi
f01037ba:	56                   	push   %esi
f01037bb:	53                   	push   %ebx
f01037bc:	8b 7d 08             	mov    0x8(%ebp),%edi
f01037bf:	8b 45 0c             	mov    0xc(%ebp),%eax
f01037c2:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01037c5:	85 c9                	test   %ecx,%ecx
f01037c7:	74 30                	je     f01037f9 <memset+0x43>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01037c9:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01037cf:	75 25                	jne    f01037f6 <memset+0x40>
f01037d1:	f6 c1 03             	test   $0x3,%cl
f01037d4:	75 20                	jne    f01037f6 <memset+0x40>
		c &= 0xFF;
f01037d6:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01037d9:	89 d3                	mov    %edx,%ebx
f01037db:	c1 e3 08             	shl    $0x8,%ebx
f01037de:	89 d6                	mov    %edx,%esi
f01037e0:	c1 e6 18             	shl    $0x18,%esi
f01037e3:	89 d0                	mov    %edx,%eax
f01037e5:	c1 e0 10             	shl    $0x10,%eax
f01037e8:	09 f0                	or     %esi,%eax
f01037ea:	09 d0                	or     %edx,%eax
f01037ec:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01037ee:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01037f1:	fc                   	cld    
f01037f2:	f3 ab                	rep stos %eax,%es:(%edi)
f01037f4:	eb 03                	jmp    f01037f9 <memset+0x43>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01037f6:	fc                   	cld    
f01037f7:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01037f9:	89 f8                	mov    %edi,%eax
f01037fb:	5b                   	pop    %ebx
f01037fc:	5e                   	pop    %esi
f01037fd:	5f                   	pop    %edi
f01037fe:	5d                   	pop    %ebp
f01037ff:	c3                   	ret    

f0103800 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103800:	55                   	push   %ebp
f0103801:	89 e5                	mov    %esp,%ebp
f0103803:	57                   	push   %edi
f0103804:	56                   	push   %esi
f0103805:	8b 45 08             	mov    0x8(%ebp),%eax
f0103808:	8b 75 0c             	mov    0xc(%ebp),%esi
f010380b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010380e:	39 c6                	cmp    %eax,%esi
f0103810:	73 34                	jae    f0103846 <memmove+0x46>
f0103812:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103815:	39 d0                	cmp    %edx,%eax
f0103817:	73 2d                	jae    f0103846 <memmove+0x46>
		s += n;
		d += n;
f0103819:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010381c:	f6 c2 03             	test   $0x3,%dl
f010381f:	75 1b                	jne    f010383c <memmove+0x3c>
f0103821:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103827:	75 13                	jne    f010383c <memmove+0x3c>
f0103829:	f6 c1 03             	test   $0x3,%cl
f010382c:	75 0e                	jne    f010383c <memmove+0x3c>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f010382e:	83 ef 04             	sub    $0x4,%edi
f0103831:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103834:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0103837:	fd                   	std    
f0103838:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010383a:	eb 07                	jmp    f0103843 <memmove+0x43>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010383c:	4f                   	dec    %edi
f010383d:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103840:	fd                   	std    
f0103841:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103843:	fc                   	cld    
f0103844:	eb 20                	jmp    f0103866 <memmove+0x66>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103846:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010384c:	75 13                	jne    f0103861 <memmove+0x61>
f010384e:	a8 03                	test   $0x3,%al
f0103850:	75 0f                	jne    f0103861 <memmove+0x61>
f0103852:	f6 c1 03             	test   $0x3,%cl
f0103855:	75 0a                	jne    f0103861 <memmove+0x61>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103857:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010385a:	89 c7                	mov    %eax,%edi
f010385c:	fc                   	cld    
f010385d:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010385f:	eb 05                	jmp    f0103866 <memmove+0x66>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103861:	89 c7                	mov    %eax,%edi
f0103863:	fc                   	cld    
f0103864:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103866:	5e                   	pop    %esi
f0103867:	5f                   	pop    %edi
f0103868:	5d                   	pop    %ebp
f0103869:	c3                   	ret    

f010386a <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010386a:	55                   	push   %ebp
f010386b:	89 e5                	mov    %esp,%ebp
f010386d:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0103870:	8b 45 10             	mov    0x10(%ebp),%eax
f0103873:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103877:	8b 45 0c             	mov    0xc(%ebp),%eax
f010387a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010387e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103881:	89 04 24             	mov    %eax,(%esp)
f0103884:	e8 77 ff ff ff       	call   f0103800 <memmove>
}
f0103889:	c9                   	leave  
f010388a:	c3                   	ret    

f010388b <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010388b:	55                   	push   %ebp
f010388c:	89 e5                	mov    %esp,%ebp
f010388e:	57                   	push   %edi
f010388f:	56                   	push   %esi
f0103890:	53                   	push   %ebx
f0103891:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103894:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103897:	8b 5d 10             	mov    0x10(%ebp),%ebx
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010389a:	ba 00 00 00 00       	mov    $0x0,%edx
f010389f:	eb 16                	jmp    f01038b7 <memcmp+0x2c>
		if (*s1 != *s2)
f01038a1:	8a 04 17             	mov    (%edi,%edx,1),%al
f01038a4:	42                   	inc    %edx
f01038a5:	8a 4c 16 ff          	mov    -0x1(%esi,%edx,1),%cl
f01038a9:	38 c8                	cmp    %cl,%al
f01038ab:	74 0a                	je     f01038b7 <memcmp+0x2c>
			return (int) *s1 - (int) *s2;
f01038ad:	0f b6 c0             	movzbl %al,%eax
f01038b0:	0f b6 c9             	movzbl %cl,%ecx
f01038b3:	29 c8                	sub    %ecx,%eax
f01038b5:	eb 09                	jmp    f01038c0 <memcmp+0x35>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01038b7:	39 da                	cmp    %ebx,%edx
f01038b9:	75 e6                	jne    f01038a1 <memcmp+0x16>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01038bb:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01038c0:	5b                   	pop    %ebx
f01038c1:	5e                   	pop    %esi
f01038c2:	5f                   	pop    %edi
f01038c3:	5d                   	pop    %ebp
f01038c4:	c3                   	ret    

f01038c5 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01038c5:	55                   	push   %ebp
f01038c6:	89 e5                	mov    %esp,%ebp
f01038c8:	8b 45 08             	mov    0x8(%ebp),%eax
f01038cb:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01038ce:	89 c2                	mov    %eax,%edx
f01038d0:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01038d3:	eb 05                	jmp    f01038da <memfind+0x15>
		if (*(const unsigned char *) s == (unsigned char) c)
f01038d5:	38 08                	cmp    %cl,(%eax)
f01038d7:	74 05                	je     f01038de <memfind+0x19>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01038d9:	40                   	inc    %eax
f01038da:	39 d0                	cmp    %edx,%eax
f01038dc:	72 f7                	jb     f01038d5 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01038de:	5d                   	pop    %ebp
f01038df:	c3                   	ret    

f01038e0 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01038e0:	55                   	push   %ebp
f01038e1:	89 e5                	mov    %esp,%ebp
f01038e3:	57                   	push   %edi
f01038e4:	56                   	push   %esi
f01038e5:	53                   	push   %ebx
f01038e6:	8b 55 08             	mov    0x8(%ebp),%edx
f01038e9:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01038ec:	eb 01                	jmp    f01038ef <strtol+0xf>
		s++;
f01038ee:	42                   	inc    %edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01038ef:	8a 02                	mov    (%edx),%al
f01038f1:	3c 20                	cmp    $0x20,%al
f01038f3:	74 f9                	je     f01038ee <strtol+0xe>
f01038f5:	3c 09                	cmp    $0x9,%al
f01038f7:	74 f5                	je     f01038ee <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01038f9:	3c 2b                	cmp    $0x2b,%al
f01038fb:	75 08                	jne    f0103905 <strtol+0x25>
		s++;
f01038fd:	42                   	inc    %edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01038fe:	bf 00 00 00 00       	mov    $0x0,%edi
f0103903:	eb 13                	jmp    f0103918 <strtol+0x38>
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103905:	3c 2d                	cmp    $0x2d,%al
f0103907:	75 0a                	jne    f0103913 <strtol+0x33>
		s++, neg = 1;
f0103909:	8d 52 01             	lea    0x1(%edx),%edx
f010390c:	bf 01 00 00 00       	mov    $0x1,%edi
f0103911:	eb 05                	jmp    f0103918 <strtol+0x38>
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103913:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103918:	85 db                	test   %ebx,%ebx
f010391a:	74 05                	je     f0103921 <strtol+0x41>
f010391c:	83 fb 10             	cmp    $0x10,%ebx
f010391f:	75 28                	jne    f0103949 <strtol+0x69>
f0103921:	8a 02                	mov    (%edx),%al
f0103923:	3c 30                	cmp    $0x30,%al
f0103925:	75 10                	jne    f0103937 <strtol+0x57>
f0103927:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f010392b:	75 0a                	jne    f0103937 <strtol+0x57>
		s += 2, base = 16;
f010392d:	83 c2 02             	add    $0x2,%edx
f0103930:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103935:	eb 12                	jmp    f0103949 <strtol+0x69>
	else if (base == 0 && s[0] == '0')
f0103937:	85 db                	test   %ebx,%ebx
f0103939:	75 0e                	jne    f0103949 <strtol+0x69>
f010393b:	3c 30                	cmp    $0x30,%al
f010393d:	75 05                	jne    f0103944 <strtol+0x64>
		s++, base = 8;
f010393f:	42                   	inc    %edx
f0103940:	b3 08                	mov    $0x8,%bl
f0103942:	eb 05                	jmp    f0103949 <strtol+0x69>
	else if (base == 0)
		base = 10;
f0103944:	bb 0a 00 00 00       	mov    $0xa,%ebx
f0103949:	b8 00 00 00 00       	mov    $0x0,%eax
f010394e:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103950:	8a 0a                	mov    (%edx),%cl
f0103952:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0103955:	80 fb 09             	cmp    $0x9,%bl
f0103958:	77 08                	ja     f0103962 <strtol+0x82>
			dig = *s - '0';
f010395a:	0f be c9             	movsbl %cl,%ecx
f010395d:	83 e9 30             	sub    $0x30,%ecx
f0103960:	eb 1e                	jmp    f0103980 <strtol+0xa0>
		else if (*s >= 'a' && *s <= 'z')
f0103962:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0103965:	80 fb 19             	cmp    $0x19,%bl
f0103968:	77 08                	ja     f0103972 <strtol+0x92>
			dig = *s - 'a' + 10;
f010396a:	0f be c9             	movsbl %cl,%ecx
f010396d:	83 e9 57             	sub    $0x57,%ecx
f0103970:	eb 0e                	jmp    f0103980 <strtol+0xa0>
		else if (*s >= 'A' && *s <= 'Z')
f0103972:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0103975:	80 fb 19             	cmp    $0x19,%bl
f0103978:	77 12                	ja     f010398c <strtol+0xac>
			dig = *s - 'A' + 10;
f010397a:	0f be c9             	movsbl %cl,%ecx
f010397d:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0103980:	39 f1                	cmp    %esi,%ecx
f0103982:	7d 0c                	jge    f0103990 <strtol+0xb0>
			break;
		s++, val = (val * base) + dig;
f0103984:	42                   	inc    %edx
f0103985:	0f af c6             	imul   %esi,%eax
f0103988:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f010398a:	eb c4                	jmp    f0103950 <strtol+0x70>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f010398c:	89 c1                	mov    %eax,%ecx
f010398e:	eb 02                	jmp    f0103992 <strtol+0xb2>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103990:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0103992:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103996:	74 05                	je     f010399d <strtol+0xbd>
		*endptr = (char *) s;
f0103998:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010399b:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f010399d:	85 ff                	test   %edi,%edi
f010399f:	74 04                	je     f01039a5 <strtol+0xc5>
f01039a1:	89 c8                	mov    %ecx,%eax
f01039a3:	f7 d8                	neg    %eax
}
f01039a5:	5b                   	pop    %ebx
f01039a6:	5e                   	pop    %esi
f01039a7:	5f                   	pop    %edi
f01039a8:	5d                   	pop    %ebp
f01039a9:	c3                   	ret    
	...

f01039ac <__udivdi3>:
#endif

#ifdef L_udivdi3
UDWtype
__udivdi3 (UDWtype n, UDWtype d)
{
f01039ac:	55                   	push   %ebp
f01039ad:	57                   	push   %edi
f01039ae:	56                   	push   %esi
f01039af:	83 ec 10             	sub    $0x10,%esp
f01039b2:	8b 74 24 20          	mov    0x20(%esp),%esi
f01039b6:	8b 4c 24 28          	mov    0x28(%esp),%ecx
static inline __attribute__ ((__always_inline__))
#endif
UDWtype
__udivmoddi4 (UDWtype n, UDWtype d, UDWtype *rp)
{
  const DWunion nn = {.ll = n};
f01039ba:	89 74 24 04          	mov    %esi,0x4(%esp)
f01039be:	8b 7c 24 24          	mov    0x24(%esp),%edi
  const DWunion dd = {.ll = d};
f01039c2:	89 cd                	mov    %ecx,%ebp
f01039c4:	8b 44 24 2c          	mov    0x2c(%esp),%eax
  d1 = dd.s.high;
  n0 = nn.s.low;
  n1 = nn.s.high;

#if !UDIV_NEEDS_NORMALIZATION
  if (d1 == 0)
f01039c8:	85 c0                	test   %eax,%eax
f01039ca:	75 2c                	jne    f01039f8 <__udivdi3+0x4c>
    {
      if (d0 > n1)
f01039cc:	39 f9                	cmp    %edi,%ecx
f01039ce:	77 68                	ja     f0103a38 <__udivdi3+0x8c>
	}
      else
	{
	  /* qq = NN / 0d */

	  if (d0 == 0)
f01039d0:	85 c9                	test   %ecx,%ecx
f01039d2:	75 0b                	jne    f01039df <__udivdi3+0x33>
	    d0 = 1 / d0;	/* Divide intentionally by zero.  */
f01039d4:	b8 01 00 00 00       	mov    $0x1,%eax
f01039d9:	31 d2                	xor    %edx,%edx
f01039db:	f7 f1                	div    %ecx
f01039dd:	89 c1                	mov    %eax,%ecx

	  udiv_qrnnd (q1, n1, 0, n1, d0);
f01039df:	31 d2                	xor    %edx,%edx
f01039e1:	89 f8                	mov    %edi,%eax
f01039e3:	f7 f1                	div    %ecx
f01039e5:	89 c7                	mov    %eax,%edi
	  udiv_qrnnd (q0, n0, n1, n0, d0);
f01039e7:	89 f0                	mov    %esi,%eax
f01039e9:	f7 f1                	div    %ecx
f01039eb:	89 c6                	mov    %eax,%esi
		}
	    }
	}
    }

  const DWunion ww = {{.low = q0, .high = q1}};
f01039ed:	89 f0                	mov    %esi,%eax
f01039ef:	89 fa                	mov    %edi,%edx
#ifdef L_udivdi3
UDWtype
__udivdi3 (UDWtype n, UDWtype d)
{
  return __udivmoddi4 (n, d, (UDWtype *) 0);
}
f01039f1:	83 c4 10             	add    $0x10,%esp
f01039f4:	5e                   	pop    %esi
f01039f5:	5f                   	pop    %edi
f01039f6:	5d                   	pop    %ebp
f01039f7:	c3                   	ret    
    }
#endif /* UDIV_NEEDS_NORMALIZATION */

  else
    {
      if (d1 > n1)
f01039f8:	39 f8                	cmp    %edi,%eax
f01039fa:	77 2c                	ja     f0103a28 <__udivdi3+0x7c>
	}
      else
	{
	  /* 0q = NN / dd */

	  count_leading_zeros (bm, d1);
f01039fc:	0f bd f0             	bsr    %eax,%esi
	  if (bm == 0)
f01039ff:	83 f6 1f             	xor    $0x1f,%esi
f0103a02:	75 4c                	jne    f0103a50 <__udivdi3+0xa4>

		 This special case is necessary, not an optimization.  */

	      /* The condition on the next line takes advantage of that
		 n1 >= d1 (true due to program flow).  */
	      if (n1 > d1 || n0 >= d0)
f0103a04:	39 f8                	cmp    %edi,%eax
		{
		  q0 = 1;
		  sub_ddmmss (n1, n0, n1, n0, d1, d0);
f0103a06:	bf 00 00 00 00       	mov    $0x0,%edi

		 This special case is necessary, not an optimization.  */

	      /* The condition on the next line takes advantage of that
		 n1 >= d1 (true due to program flow).  */
	      if (n1 > d1 || n0 >= d0)
f0103a0b:	72 0a                	jb     f0103a17 <__udivdi3+0x6b>
f0103a0d:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f0103a11:	0f 87 ad 00 00 00    	ja     f0103ac4 <__udivdi3+0x118>
		{
		  q0 = 1;
		  sub_ddmmss (n1, n0, n1, n0, d1, d0);
f0103a17:	be 01 00 00 00       	mov    $0x1,%esi
		}
	    }
	}
    }

  const DWunion ww = {{.low = q0, .high = q1}};
f0103a1c:	89 f0                	mov    %esi,%eax
f0103a1e:	89 fa                	mov    %edi,%edx
#ifdef L_udivdi3
UDWtype
__udivdi3 (UDWtype n, UDWtype d)
{
  return __udivmoddi4 (n, d, (UDWtype *) 0);
}
f0103a20:	83 c4 10             	add    $0x10,%esp
f0103a23:	5e                   	pop    %esi
f0103a24:	5f                   	pop    %edi
f0103a25:	5d                   	pop    %ebp
f0103a26:	c3                   	ret    
f0103a27:	90                   	nop
    }
#endif /* UDIV_NEEDS_NORMALIZATION */

  else
    {
      if (d1 > n1)
f0103a28:	31 ff                	xor    %edi,%edi
f0103a2a:	31 f6                	xor    %esi,%esi
		}
	    }
	}
    }

  const DWunion ww = {{.low = q0, .high = q1}};
f0103a2c:	89 f0                	mov    %esi,%eax
f0103a2e:	89 fa                	mov    %edi,%edx
#ifdef L_udivdi3
UDWtype
__udivdi3 (UDWtype n, UDWtype d)
{
  return __udivmoddi4 (n, d, (UDWtype *) 0);
}
f0103a30:	83 c4 10             	add    $0x10,%esp
f0103a33:	5e                   	pop    %esi
f0103a34:	5f                   	pop    %edi
f0103a35:	5d                   	pop    %ebp
f0103a36:	c3                   	ret    
f0103a37:	90                   	nop
    {
      if (d0 > n1)
	{
	  /* 0q = nn / 0D */

	  udiv_qrnnd (q0, n0, n1, n0, d0);
f0103a38:	89 fa                	mov    %edi,%edx
f0103a3a:	89 f0                	mov    %esi,%eax
f0103a3c:	f7 f1                	div    %ecx
f0103a3e:	89 c6                	mov    %eax,%esi
f0103a40:	31 ff                	xor    %edi,%edi
		}
	    }
	}
    }

  const DWunion ww = {{.low = q0, .high = q1}};
f0103a42:	89 f0                	mov    %esi,%eax
f0103a44:	89 fa                	mov    %edi,%edx
#ifdef L_udivdi3
UDWtype
__udivdi3 (UDWtype n, UDWtype d)
{
  return __udivmoddi4 (n, d, (UDWtype *) 0);
}
f0103a46:	83 c4 10             	add    $0x10,%esp
f0103a49:	5e                   	pop    %esi
f0103a4a:	5f                   	pop    %edi
f0103a4b:	5d                   	pop    %ebp
f0103a4c:	c3                   	ret    
f0103a4d:	8d 76 00             	lea    0x0(%esi),%esi
	      UWtype m1, m0;
	      /* Normalize.  */

	      b = W_TYPE_SIZE - bm;

	      d1 = (d1 << bm) | (d0 >> b);
f0103a50:	89 f1                	mov    %esi,%ecx
f0103a52:	d3 e0                	shl    %cl,%eax
f0103a54:	89 44 24 0c          	mov    %eax,0xc(%esp)
	  else
	    {
	      UWtype m1, m0;
	      /* Normalize.  */

	      b = W_TYPE_SIZE - bm;
f0103a58:	b8 20 00 00 00       	mov    $0x20,%eax
f0103a5d:	29 f0                	sub    %esi,%eax

	      d1 = (d1 << bm) | (d0 >> b);
f0103a5f:	89 ea                	mov    %ebp,%edx
f0103a61:	88 c1                	mov    %al,%cl
f0103a63:	d3 ea                	shr    %cl,%edx
f0103a65:	8b 4c 24 0c          	mov    0xc(%esp),%ecx
f0103a69:	09 ca                	or     %ecx,%edx
f0103a6b:	89 54 24 08          	mov    %edx,0x8(%esp)
	      d0 = d0 << bm;
f0103a6f:	89 f1                	mov    %esi,%ecx
f0103a71:	d3 e5                	shl    %cl,%ebp
f0103a73:	89 6c 24 0c          	mov    %ebp,0xc(%esp)
	      n2 = n1 >> b;
f0103a77:	89 fd                	mov    %edi,%ebp
f0103a79:	88 c1                	mov    %al,%cl
f0103a7b:	d3 ed                	shr    %cl,%ebp
	      n1 = (n1 << bm) | (n0 >> b);
f0103a7d:	89 fa                	mov    %edi,%edx
f0103a7f:	89 f1                	mov    %esi,%ecx
f0103a81:	d3 e2                	shl    %cl,%edx
f0103a83:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103a87:	88 c1                	mov    %al,%cl
f0103a89:	d3 ef                	shr    %cl,%edi
f0103a8b:	09 d7                	or     %edx,%edi
	      n0 = n0 << bm;

	      udiv_qrnnd (q0, n1, n2, n1, d1);
f0103a8d:	89 f8                	mov    %edi,%eax
f0103a8f:	89 ea                	mov    %ebp,%edx
f0103a91:	f7 74 24 08          	divl   0x8(%esp)
f0103a95:	89 d1                	mov    %edx,%ecx
f0103a97:	89 c7                	mov    %eax,%edi
	      umul_ppmm (m1, m0, q0, d0);
f0103a99:	f7 64 24 0c          	mull   0xc(%esp)

	      if (m1 > n1 || (m1 == n1 && m0 > n0))
f0103a9d:	39 d1                	cmp    %edx,%ecx
f0103a9f:	72 17                	jb     f0103ab8 <__udivdi3+0x10c>
f0103aa1:	74 09                	je     f0103aac <__udivdi3+0x100>
f0103aa3:	89 fe                	mov    %edi,%esi
f0103aa5:	31 ff                	xor    %edi,%edi
f0103aa7:	e9 41 ff ff ff       	jmp    f01039ed <__udivdi3+0x41>

	      d1 = (d1 << bm) | (d0 >> b);
	      d0 = d0 << bm;
	      n2 = n1 >> b;
	      n1 = (n1 << bm) | (n0 >> b);
	      n0 = n0 << bm;
f0103aac:	8b 54 24 04          	mov    0x4(%esp),%edx
f0103ab0:	89 f1                	mov    %esi,%ecx
f0103ab2:	d3 e2                	shl    %cl,%edx

	      udiv_qrnnd (q0, n1, n2, n1, d1);
	      umul_ppmm (m1, m0, q0, d0);

	      if (m1 > n1 || (m1 == n1 && m0 > n0))
f0103ab4:	39 c2                	cmp    %eax,%edx
f0103ab6:	73 eb                	jae    f0103aa3 <__udivdi3+0xf7>
		{
		  q0--;
f0103ab8:	8d 77 ff             	lea    -0x1(%edi),%esi
		  sub_ddmmss (m1, m0, m1, m0, d1, d0);
f0103abb:	31 ff                	xor    %edi,%edi
f0103abd:	e9 2b ff ff ff       	jmp    f01039ed <__udivdi3+0x41>
f0103ac2:	66 90                	xchg   %ax,%ax

		 This special case is necessary, not an optimization.  */

	      /* The condition on the next line takes advantage of that
		 n1 >= d1 (true due to program flow).  */
	      if (n1 > d1 || n0 >= d0)
f0103ac4:	31 f6                	xor    %esi,%esi
f0103ac6:	e9 22 ff ff ff       	jmp    f01039ed <__udivdi3+0x41>
	...

f0103acc <__umoddi3>:
#endif

#ifdef L_umoddi3
UDWtype
__umoddi3 (UDWtype u, UDWtype v)
{
f0103acc:	55                   	push   %ebp
f0103acd:	57                   	push   %edi
f0103ace:	56                   	push   %esi
f0103acf:	83 ec 20             	sub    $0x20,%esp
f0103ad2:	8b 44 24 30          	mov    0x30(%esp),%eax
f0103ad6:	8b 4c 24 38          	mov    0x38(%esp),%ecx
static inline __attribute__ ((__always_inline__))
#endif
UDWtype
__udivmoddi4 (UDWtype n, UDWtype d, UDWtype *rp)
{
  const DWunion nn = {.ll = n};
f0103ada:	89 44 24 14          	mov    %eax,0x14(%esp)
f0103ade:	8b 74 24 34          	mov    0x34(%esp),%esi
  const DWunion dd = {.ll = d};
f0103ae2:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103ae6:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
  UWtype q0, q1;
  UWtype b, bm;

  d0 = dd.s.low;
  d1 = dd.s.high;
  n0 = nn.s.low;
f0103aea:	89 c7                	mov    %eax,%edi
  n1 = nn.s.high;
f0103aec:	89 f2                	mov    %esi,%edx

#if !UDIV_NEEDS_NORMALIZATION
  if (d1 == 0)
f0103aee:	85 ed                	test   %ebp,%ebp
f0103af0:	75 16                	jne    f0103b08 <__umoddi3+0x3c>
    {
      if (d0 > n1)
f0103af2:	39 f1                	cmp    %esi,%ecx
f0103af4:	0f 86 a6 00 00 00    	jbe    f0103ba0 <__umoddi3+0xd4>

	  if (d0 == 0)
	    d0 = 1 / d0;	/* Divide intentionally by zero.  */

	  udiv_qrnnd (q1, n1, 0, n1, d0);
	  udiv_qrnnd (q0, n0, n1, n0, d0);
f0103afa:	f7 f1                	div    %ecx

      if (rp != 0)
	{
	  rr.s.low = n0;
	  rr.s.high = 0;
	  *rp = rr.ll;
f0103afc:	89 d0                	mov    %edx,%eax
f0103afe:	31 d2                	xor    %edx,%edx
  UDWtype w;

  (void) __udivmoddi4 (u, v, &w);

  return w;
}
f0103b00:	83 c4 20             	add    $0x20,%esp
f0103b03:	5e                   	pop    %esi
f0103b04:	5f                   	pop    %edi
f0103b05:	5d                   	pop    %ebp
f0103b06:	c3                   	ret    
f0103b07:	90                   	nop
    }
#endif /* UDIV_NEEDS_NORMALIZATION */

  else
    {
      if (d1 > n1)
f0103b08:	39 f5                	cmp    %esi,%ebp
f0103b0a:	0f 87 ac 00 00 00    	ja     f0103bbc <__umoddi3+0xf0>
	}
      else
	{
	  /* 0q = NN / dd */

	  count_leading_zeros (bm, d1);
f0103b10:	0f bd c5             	bsr    %ebp,%eax
	  if (bm == 0)
f0103b13:	83 f0 1f             	xor    $0x1f,%eax
f0103b16:	89 44 24 10          	mov    %eax,0x10(%esp)
f0103b1a:	0f 84 a8 00 00 00    	je     f0103bc8 <__umoddi3+0xfc>
	      UWtype m1, m0;
	      /* Normalize.  */

	      b = W_TYPE_SIZE - bm;

	      d1 = (d1 << bm) | (d0 >> b);
f0103b20:	8a 4c 24 10          	mov    0x10(%esp),%cl
f0103b24:	d3 e5                	shl    %cl,%ebp
	  else
	    {
	      UWtype m1, m0;
	      /* Normalize.  */

	      b = W_TYPE_SIZE - bm;
f0103b26:	bf 20 00 00 00       	mov    $0x20,%edi
f0103b2b:	2b 7c 24 10          	sub    0x10(%esp),%edi

	      d1 = (d1 << bm) | (d0 >> b);
f0103b2f:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0103b33:	89 f9                	mov    %edi,%ecx
f0103b35:	d3 e8                	shr    %cl,%eax
f0103b37:	09 e8                	or     %ebp,%eax
f0103b39:	89 44 24 18          	mov    %eax,0x18(%esp)
	      d0 = d0 << bm;
f0103b3d:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0103b41:	8a 4c 24 10          	mov    0x10(%esp),%cl
f0103b45:	d3 e0                	shl    %cl,%eax
f0103b47:	89 44 24 0c          	mov    %eax,0xc(%esp)
	      n2 = n1 >> b;
	      n1 = (n1 << bm) | (n0 >> b);
f0103b4b:	89 f2                	mov    %esi,%edx
f0103b4d:	d3 e2                	shl    %cl,%edx
	      n0 = n0 << bm;
f0103b4f:	8b 44 24 14          	mov    0x14(%esp),%eax
f0103b53:	d3 e0                	shl    %cl,%eax
f0103b55:	89 44 24 1c          	mov    %eax,0x1c(%esp)
	      b = W_TYPE_SIZE - bm;

	      d1 = (d1 << bm) | (d0 >> b);
	      d0 = d0 << bm;
	      n2 = n1 >> b;
	      n1 = (n1 << bm) | (n0 >> b);
f0103b59:	8b 44 24 14          	mov    0x14(%esp),%eax
f0103b5d:	89 f9                	mov    %edi,%ecx
f0103b5f:	d3 e8                	shr    %cl,%eax
f0103b61:	09 d0                	or     %edx,%eax

	      b = W_TYPE_SIZE - bm;

	      d1 = (d1 << bm) | (d0 >> b);
	      d0 = d0 << bm;
	      n2 = n1 >> b;
f0103b63:	d3 ee                	shr    %cl,%esi
	      n1 = (n1 << bm) | (n0 >> b);
	      n0 = n0 << bm;

	      udiv_qrnnd (q0, n1, n2, n1, d1);
f0103b65:	89 f2                	mov    %esi,%edx
f0103b67:	f7 74 24 18          	divl   0x18(%esp)
f0103b6b:	89 d6                	mov    %edx,%esi
	      umul_ppmm (m1, m0, q0, d0);
f0103b6d:	f7 64 24 0c          	mull   0xc(%esp)
f0103b71:	89 c5                	mov    %eax,%ebp
f0103b73:	89 d1                	mov    %edx,%ecx

	      if (m1 > n1 || (m1 == n1 && m0 > n0))
f0103b75:	39 d6                	cmp    %edx,%esi
f0103b77:	72 67                	jb     f0103be0 <__umoddi3+0x114>
f0103b79:	74 75                	je     f0103bf0 <__umoddi3+0x124>
	      q1 = 0;

	      /* Remainder in (n1n0 - m1m0) >> bm.  */
	      if (rp != 0)
		{
		  sub_ddmmss (n1, n0, n1, n0, m1, m0);
f0103b7b:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f0103b7f:	29 e8                	sub    %ebp,%eax
f0103b81:	19 ce                	sbb    %ecx,%esi
		  rr.s.low = (n1 << b) | (n0 >> bm);
f0103b83:	8a 4c 24 10          	mov    0x10(%esp),%cl
f0103b87:	d3 e8                	shr    %cl,%eax
f0103b89:	89 f2                	mov    %esi,%edx
f0103b8b:	89 f9                	mov    %edi,%ecx
f0103b8d:	d3 e2                	shl    %cl,%edx
		  rr.s.high = n1 >> bm;
		  *rp = rr.ll;
f0103b8f:	09 d0                	or     %edx,%eax
f0103b91:	89 f2                	mov    %esi,%edx
f0103b93:	8a 4c 24 10          	mov    0x10(%esp),%cl
f0103b97:	d3 ea                	shr    %cl,%edx
  UDWtype w;

  (void) __udivmoddi4 (u, v, &w);

  return w;
}
f0103b99:	83 c4 20             	add    $0x20,%esp
f0103b9c:	5e                   	pop    %esi
f0103b9d:	5f                   	pop    %edi
f0103b9e:	5d                   	pop    %ebp
f0103b9f:	c3                   	ret    
	}
      else
	{
	  /* qq = NN / 0d */

	  if (d0 == 0)
f0103ba0:	85 c9                	test   %ecx,%ecx
f0103ba2:	75 0b                	jne    f0103baf <__umoddi3+0xe3>
	    d0 = 1 / d0;	/* Divide intentionally by zero.  */
f0103ba4:	b8 01 00 00 00       	mov    $0x1,%eax
f0103ba9:	31 d2                	xor    %edx,%edx
f0103bab:	f7 f1                	div    %ecx
f0103bad:	89 c1                	mov    %eax,%ecx

	  udiv_qrnnd (q1, n1, 0, n1, d0);
f0103baf:	89 f0                	mov    %esi,%eax
f0103bb1:	31 d2                	xor    %edx,%edx
f0103bb3:	f7 f1                	div    %ecx
	  udiv_qrnnd (q0, n0, n1, n0, d0);
f0103bb5:	89 f8                	mov    %edi,%eax
f0103bb7:	e9 3e ff ff ff       	jmp    f0103afa <__umoddi3+0x2e>
	  /* Remainder in n1n0.  */
	  if (rp != 0)
	    {
	      rr.s.low = n0;
	      rr.s.high = n1;
	      *rp = rr.ll;
f0103bbc:	89 f2                	mov    %esi,%edx
  UDWtype w;

  (void) __udivmoddi4 (u, v, &w);

  return w;
}
f0103bbe:	83 c4 20             	add    $0x20,%esp
f0103bc1:	5e                   	pop    %esi
f0103bc2:	5f                   	pop    %edi
f0103bc3:	5d                   	pop    %ebp
f0103bc4:	c3                   	ret    
f0103bc5:	8d 76 00             	lea    0x0(%esi),%esi

		 This special case is necessary, not an optimization.  */

	      /* The condition on the next line takes advantage of that
		 n1 >= d1 (true due to program flow).  */
	      if (n1 > d1 || n0 >= d0)
f0103bc8:	39 f5                	cmp    %esi,%ebp
f0103bca:	72 04                	jb     f0103bd0 <__umoddi3+0x104>
f0103bcc:	39 f9                	cmp    %edi,%ecx
f0103bce:	77 06                	ja     f0103bd6 <__umoddi3+0x10a>
		{
		  q0 = 1;
		  sub_ddmmss (n1, n0, n1, n0, d1, d0);
f0103bd0:	89 f2                	mov    %esi,%edx
f0103bd2:	29 cf                	sub    %ecx,%edi
f0103bd4:	19 ea                	sbb    %ebp,%edx

	      if (rp != 0)
		{
		  rr.s.low = n0;
		  rr.s.high = n1;
		  *rp = rr.ll;
f0103bd6:	89 f8                	mov    %edi,%eax
  UDWtype w;

  (void) __udivmoddi4 (u, v, &w);

  return w;
}
f0103bd8:	83 c4 20             	add    $0x20,%esp
f0103bdb:	5e                   	pop    %esi
f0103bdc:	5f                   	pop    %edi
f0103bdd:	5d                   	pop    %ebp
f0103bde:	c3                   	ret    
f0103bdf:	90                   	nop
	      umul_ppmm (m1, m0, q0, d0);

	      if (m1 > n1 || (m1 == n1 && m0 > n0))
		{
		  q0--;
		  sub_ddmmss (m1, m0, m1, m0, d1, d0);
f0103be0:	89 d1                	mov    %edx,%ecx
f0103be2:	89 c5                	mov    %eax,%ebp
f0103be4:	2b 6c 24 0c          	sub    0xc(%esp),%ebp
f0103be8:	1b 4c 24 18          	sbb    0x18(%esp),%ecx
f0103bec:	eb 8d                	jmp    f0103b7b <__umoddi3+0xaf>
f0103bee:	66 90                	xchg   %ax,%ax
	      n0 = n0 << bm;

	      udiv_qrnnd (q0, n1, n2, n1, d1);
	      umul_ppmm (m1, m0, q0, d0);

	      if (m1 > n1 || (m1 == n1 && m0 > n0))
f0103bf0:	39 44 24 1c          	cmp    %eax,0x1c(%esp)
f0103bf4:	72 ea                	jb     f0103be0 <__umoddi3+0x114>
f0103bf6:	89 f1                	mov    %esi,%ecx
f0103bf8:	eb 81                	jmp    f0103b7b <__umoddi3+0xaf>
