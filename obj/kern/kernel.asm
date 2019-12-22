
obj/kern/kernel：     文件格式 elf32-i386


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
f0100052:	c7 c0 e0 ff 18 f0    	mov    $0xf018ffe0,%eax
f0100058:	c7 c2 e0 f0 18 f0    	mov    $0xf018f0e0,%edx
f010005e:	29 d0                	sub    %edx,%eax
f0100060:	50                   	push   %eax
f0100061:	6a 00                	push   $0x0
f0100063:	52                   	push   %edx
f0100064:	e8 2c 50 00 00       	call   f0105095 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100069:	e8 4e 05 00 00       	call   f01005bc <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f010006e:	83 c4 08             	add    $0x8,%esp
f0100071:	68 ac 1a 00 00       	push   $0x1aac
f0100076:	8d 83 c0 84 f7 ff    	lea    -0x87b40(%ebx),%eax
f010007c:	50                   	push   %eax
f010007d:	e8 d6 3a 00 00       	call   f0103b58 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100082:	e8 0b 13 00 00       	call   f0101392 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f0100087:	e8 15 34 00 00       	call   f01034a1 <env_init>
	trap_init();
f010008c:	e8 7a 3b 00 00       	call   f0103c0b <trap_init>

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f0100091:	83 c4 08             	add    $0x8,%esp
f0100094:	6a 00                	push   $0x0
f0100096:	ff b3 f4 ff ff ff    	pushl  -0xc(%ebx)
f010009c:	e8 02 36 00 00       	call   f01036a3 <env_create>
	// Touch all you want.
	ENV_CREATE(user_hello, ENV_TYPE_USER);
#endif // TEST*

	// We only have one user environment for now, so just run it.
	env_run(&envs[0]);
f01000a1:	83 c4 04             	add    $0x4,%esp
f01000a4:	c7 c0 2c f3 18 f0    	mov    $0xf018f32c,%eax
f01000aa:	ff 30                	pushl  (%eax)
f01000ac:	e8 ab 39 00 00       	call   f0103a5c <env_run>

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
f01000c8:	c7 c0 e4 ff 18 f0    	mov    $0xf018ffe4,%eax
f01000ce:	83 38 00             	cmpl   $0x0,(%eax)
f01000d1:	74 0f                	je     f01000e2 <_panic+0x31>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000d3:	83 ec 0c             	sub    $0xc,%esp
f01000d6:	6a 00                	push   $0x0
f01000d8:	e8 31 08 00 00       	call   f010090e <monitor>
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
f01000f2:	8d 83 db 84 f7 ff    	lea    -0x87b25(%ebx),%eax
f01000f8:	50                   	push   %eax
f01000f9:	e8 5a 3a 00 00       	call   f0103b58 <cprintf>
	vcprintf(fmt, ap);
f01000fe:	83 c4 08             	add    $0x8,%esp
f0100101:	56                   	push   %esi
f0100102:	57                   	push   %edi
f0100103:	e8 19 3a 00 00       	call   f0103b21 <vcprintf>
	cprintf("\n");
f0100108:	8d 83 55 94 f7 ff    	lea    -0x86bab(%ebx),%eax
f010010e:	89 04 24             	mov    %eax,(%esp)
f0100111:	e8 42 3a 00 00       	call   f0103b58 <cprintf>
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
f0100137:	8d 83 f3 84 f7 ff    	lea    -0x87b0d(%ebx),%eax
f010013d:	50                   	push   %eax
f010013e:	e8 15 3a 00 00       	call   f0103b58 <cprintf>
	vcprintf(fmt, ap);
f0100143:	83 c4 08             	add    $0x8,%esp
f0100146:	56                   	push   %esi
f0100147:	ff 75 10             	pushl  0x10(%ebp)
f010014a:	e8 d2 39 00 00       	call   f0103b21 <vcprintf>
	cprintf("\n");
f010014f:	8d 83 55 94 f7 ff    	lea    -0x86bab(%ebx),%eax
f0100155:	89 04 24             	mov    %eax,(%esp)
f0100158:	e8 fb 39 00 00       	call   f0103b58 <cprintf>
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
f01001a7:	8b 8b e4 22 00 00    	mov    0x22e4(%ebx),%ecx
f01001ad:	8d 51 01             	lea    0x1(%ecx),%edx
f01001b0:	89 93 e4 22 00 00    	mov    %edx,0x22e4(%ebx)
f01001b6:	88 84 0b e0 20 00 00 	mov    %al,0x20e0(%ebx,%ecx,1)
		if (cons.wpos == CONSBUFSIZE)
f01001bd:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01001c3:	75 d7                	jne    f010019c <cons_intr+0x12>
			cons.wpos = 0;
f01001c5:	c7 83 e4 22 00 00 00 	movl   $0x0,0x22e4(%ebx)
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
f0100213:	8b 8b c0 20 00 00    	mov    0x20c0(%ebx),%ecx
f0100219:	f6 c1 40             	test   $0x40,%cl
f010021c:	74 0e                	je     f010022c <kbd_proc_data+0x57>
		data |= 0x80;
f010021e:	83 c8 80             	or     $0xffffff80,%eax
f0100221:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100223:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100226:	89 8b c0 20 00 00    	mov    %ecx,0x20c0(%ebx)
	shift |= shiftcode[data];
f010022c:	0f b6 d2             	movzbl %dl,%edx
f010022f:	0f b6 84 13 40 86 f7 	movzbl -0x879c0(%ebx,%edx,1),%eax
f0100236:	ff 
f0100237:	0b 83 c0 20 00 00    	or     0x20c0(%ebx),%eax
	shift ^= togglecode[data];
f010023d:	0f b6 8c 13 40 85 f7 	movzbl -0x87ac0(%ebx,%edx,1),%ecx
f0100244:	ff 
f0100245:	31 c8                	xor    %ecx,%eax
f0100247:	89 83 c0 20 00 00    	mov    %eax,0x20c0(%ebx)
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
f0100282:	8d 83 0d 85 f7 ff    	lea    -0x87af3(%ebx),%eax
f0100288:	50                   	push   %eax
f0100289:	e8 ca 38 00 00       	call   f0103b58 <cprintf>
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
f010029e:	83 8b c0 20 00 00 40 	orl    $0x40,0x20c0(%ebx)
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
f01002b3:	8b 8b c0 20 00 00    	mov    0x20c0(%ebx),%ecx
f01002b9:	89 ce                	mov    %ecx,%esi
f01002bb:	83 e6 40             	and    $0x40,%esi
f01002be:	83 e0 7f             	and    $0x7f,%eax
f01002c1:	85 f6                	test   %esi,%esi
f01002c3:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01002c6:	0f b6 d2             	movzbl %dl,%edx
f01002c9:	0f b6 84 13 40 86 f7 	movzbl -0x879c0(%ebx,%edx,1),%eax
f01002d0:	ff 
f01002d1:	83 c8 40             	or     $0x40,%eax
f01002d4:	0f b6 c0             	movzbl %al,%eax
f01002d7:	f7 d0                	not    %eax
f01002d9:	21 c8                	and    %ecx,%eax
f01002db:	89 83 c0 20 00 00    	mov    %eax,0x20c0(%ebx)
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
f01003d4:	0f b7 83 e8 22 00 00 	movzwl 0x22e8(%ebx),%eax
f01003db:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01003e1:	c1 e8 16             	shr    $0x16,%eax
f01003e4:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01003e7:	c1 e0 04             	shl    $0x4,%eax
f01003ea:	66 89 83 e8 22 00 00 	mov    %ax,0x22e8(%ebx)
	if (crt_pos >= CRT_SIZE) {
f01003f1:	66 81 bb e8 22 00 00 	cmpw   $0x7cf,0x22e8(%ebx)
f01003f8:	cf 07 
f01003fa:	0f 87 d4 00 00 00    	ja     f01004d4 <cons_putc+0x1cd>
	outb(addr_6845, 14);
f0100400:	8b 8b f0 22 00 00    	mov    0x22f0(%ebx),%ecx
f0100406:	b8 0e 00 00 00       	mov    $0xe,%eax
f010040b:	89 ca                	mov    %ecx,%edx
f010040d:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010040e:	0f b7 9b e8 22 00 00 	movzwl 0x22e8(%ebx),%ebx
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
f010043b:	0f b7 83 e8 22 00 00 	movzwl 0x22e8(%ebx),%eax
f0100442:	66 85 c0             	test   %ax,%ax
f0100445:	74 b9                	je     f0100400 <cons_putc+0xf9>
			crt_pos--;
f0100447:	83 e8 01             	sub    $0x1,%eax
f010044a:	66 89 83 e8 22 00 00 	mov    %ax,0x22e8(%ebx)
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100451:	0f b7 c0             	movzwl %ax,%eax
f0100454:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
f0100458:	b2 00                	mov    $0x0,%dl
f010045a:	83 ca 20             	or     $0x20,%edx
f010045d:	8b 8b ec 22 00 00    	mov    0x22ec(%ebx),%ecx
f0100463:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f0100467:	eb 88                	jmp    f01003f1 <cons_putc+0xea>
		crt_pos += CRT_COLS;
f0100469:	66 83 83 e8 22 00 00 	addw   $0x50,0x22e8(%ebx)
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
f01004ad:	0f b7 83 e8 22 00 00 	movzwl 0x22e8(%ebx),%eax
f01004b4:	8d 50 01             	lea    0x1(%eax),%edx
f01004b7:	66 89 93 e8 22 00 00 	mov    %dx,0x22e8(%ebx)
f01004be:	0f b7 c0             	movzwl %ax,%eax
f01004c1:	8b 93 ec 22 00 00    	mov    0x22ec(%ebx),%edx
f01004c7:	0f b7 7d e4          	movzwl -0x1c(%ebp),%edi
f01004cb:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004cf:	e9 1d ff ff ff       	jmp    f01003f1 <cons_putc+0xea>
		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01004d4:	8b 83 ec 22 00 00    	mov    0x22ec(%ebx),%eax
f01004da:	83 ec 04             	sub    $0x4,%esp
f01004dd:	68 00 0f 00 00       	push   $0xf00
f01004e2:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01004e8:	52                   	push   %edx
f01004e9:	50                   	push   %eax
f01004ea:	e8 f3 4b 00 00       	call   f01050e2 <memmove>
			crt_buf[i] = 0x0700 | ' ';
f01004ef:	8b 93 ec 22 00 00    	mov    0x22ec(%ebx),%edx
f01004f5:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f01004fb:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f0100501:	83 c4 10             	add    $0x10,%esp
f0100504:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100509:	83 c0 02             	add    $0x2,%eax
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010050c:	39 d0                	cmp    %edx,%eax
f010050e:	75 f4                	jne    f0100504 <cons_putc+0x1fd>
		crt_pos -= CRT_COLS;
f0100510:	66 83 ab e8 22 00 00 	subw   $0x50,0x22e8(%ebx)
f0100517:	50 
f0100518:	e9 e3 fe ff ff       	jmp    f0100400 <cons_putc+0xf9>

f010051d <serial_intr>:
{
f010051d:	e8 e7 01 00 00       	call   f0100709 <__x86.get_pc_thunk.ax>
f0100522:	05 fe ca 08 00       	add    $0x8cafe,%eax
	if (serial_exists)
f0100527:	80 b8 f4 22 00 00 00 	cmpb   $0x0,0x22f4(%eax)
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
f010057e:	8b 93 e0 22 00 00    	mov    0x22e0(%ebx),%edx
	return 0;
f0100584:	b8 00 00 00 00       	mov    $0x0,%eax
	if (cons.rpos != cons.wpos) {
f0100589:	3b 93 e4 22 00 00    	cmp    0x22e4(%ebx),%edx
f010058f:	74 19                	je     f01005aa <cons_getc+0x48>
		c = cons.buf[cons.rpos++];
f0100591:	8d 4a 01             	lea    0x1(%edx),%ecx
f0100594:	89 8b e0 22 00 00    	mov    %ecx,0x22e0(%ebx)
f010059a:	0f b6 84 13 e0 20 00 	movzbl 0x20e0(%ebx,%edx,1),%eax
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
f01005b0:	c7 83 e0 22 00 00 00 	movl   $0x0,0x22e0(%ebx)
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
f01005f1:	c7 83 f0 22 00 00 b4 	movl   $0x3b4,0x22f0(%ebx)
f01005f8:	03 00 00 
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01005fb:	c7 45 e4 00 00 0b f0 	movl   $0xf00b0000,-0x1c(%ebp)
	outb(addr_6845, 14);
f0100602:	8b bb f0 22 00 00    	mov    0x22f0(%ebx),%edi
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
f010062a:	89 bb ec 22 00 00    	mov    %edi,0x22ec(%ebx)
	pos |= inb(addr_6845 + 1);
f0100630:	0f b6 c0             	movzbl %al,%eax
f0100633:	09 c6                	or     %eax,%esi
	crt_pos = pos;
f0100635:	66 89 b3 e8 22 00 00 	mov    %si,0x22e8(%ebx)
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
f010068d:	0f 95 83 f4 22 00 00 	setne  0x22f4(%ebx)
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
f01006b4:	c7 83 f0 22 00 00 d4 	movl   $0x3d4,0x22f0(%ebx)
f01006bb:	03 00 00 
	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006be:	c7 45 e4 00 80 0b f0 	movl   $0xf00b8000,-0x1c(%ebp)
f01006c5:	e9 38 ff ff ff       	jmp    f0100602 <cons_init+0x46>
		cprintf("Serial port does not exist!\n");
f01006ca:	83 ec 0c             	sub    $0xc,%esp
f01006cd:	8d 83 19 85 f7 ff    	lea    -0x87ae7(%ebx),%eax
f01006d3:	50                   	push   %eax
f01006d4:	e8 7f 34 00 00       	call   f0103b58 <cprintf>
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
f0100720:	8d 83 40 87 f7 ff    	lea    -0x878c0(%ebx),%eax
f0100726:	50                   	push   %eax
f0100727:	8d 83 5e 87 f7 ff    	lea    -0x878a2(%ebx),%eax
f010072d:	50                   	push   %eax
f010072e:	8d b3 63 87 f7 ff    	lea    -0x8789d(%ebx),%esi
f0100734:	56                   	push   %esi
f0100735:	e8 1e 34 00 00       	call   f0103b58 <cprintf>
f010073a:	83 c4 0c             	add    $0xc,%esp
f010073d:	8d 83 0c 88 f7 ff    	lea    -0x877f4(%ebx),%eax
f0100743:	50                   	push   %eax
f0100744:	8d 83 6c 87 f7 ff    	lea    -0x87894(%ebx),%eax
f010074a:	50                   	push   %eax
f010074b:	56                   	push   %esi
f010074c:	e8 07 34 00 00       	call   f0103b58 <cprintf>
	return 0;
}
f0100751:	b8 00 00 00 00       	mov    $0x0,%eax
f0100756:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100759:	5b                   	pop    %ebx
f010075a:	5e                   	pop    %esi
f010075b:	5d                   	pop    %ebp
f010075c:	c3                   	ret    

f010075d <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f010075d:	55                   	push   %ebp
f010075e:	89 e5                	mov    %esp,%ebp
f0100760:	57                   	push   %edi
f0100761:	56                   	push   %esi
f0100762:	53                   	push   %ebx
f0100763:	83 ec 18             	sub    $0x18,%esp
f0100766:	e8 fc f9 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010076b:	81 c3 b5 c8 08 00    	add    $0x8c8b5,%ebx
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100771:	8d 83 75 87 f7 ff    	lea    -0x8788b(%ebx),%eax
f0100777:	50                   	push   %eax
f0100778:	e8 db 33 00 00       	call   f0103b58 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f010077d:	83 c4 08             	add    $0x8,%esp
f0100780:	ff b3 f8 ff ff ff    	pushl  -0x8(%ebx)
f0100786:	8d 83 34 88 f7 ff    	lea    -0x877cc(%ebx),%eax
f010078c:	50                   	push   %eax
f010078d:	e8 c6 33 00 00       	call   f0103b58 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100792:	83 c4 0c             	add    $0xc,%esp
f0100795:	c7 c7 0c 00 10 f0    	mov    $0xf010000c,%edi
f010079b:	8d 87 00 00 00 10    	lea    0x10000000(%edi),%eax
f01007a1:	50                   	push   %eax
f01007a2:	57                   	push   %edi
f01007a3:	8d 83 5c 88 f7 ff    	lea    -0x877a4(%ebx),%eax
f01007a9:	50                   	push   %eax
f01007aa:	e8 a9 33 00 00       	call   f0103b58 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007af:	83 c4 0c             	add    $0xc,%esp
f01007b2:	c7 c0 d9 54 10 f0    	mov    $0xf01054d9,%eax
f01007b8:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007be:	52                   	push   %edx
f01007bf:	50                   	push   %eax
f01007c0:	8d 83 80 88 f7 ff    	lea    -0x87780(%ebx),%eax
f01007c6:	50                   	push   %eax
f01007c7:	e8 8c 33 00 00       	call   f0103b58 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01007cc:	83 c4 0c             	add    $0xc,%esp
f01007cf:	c7 c0 e0 f0 18 f0    	mov    $0xf018f0e0,%eax
f01007d5:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01007db:	52                   	push   %edx
f01007dc:	50                   	push   %eax
f01007dd:	8d 83 a4 88 f7 ff    	lea    -0x8775c(%ebx),%eax
f01007e3:	50                   	push   %eax
f01007e4:	e8 6f 33 00 00       	call   f0103b58 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01007e9:	83 c4 0c             	add    $0xc,%esp
f01007ec:	c7 c6 e0 ff 18 f0    	mov    $0xf018ffe0,%esi
f01007f2:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f01007f8:	50                   	push   %eax
f01007f9:	56                   	push   %esi
f01007fa:	8d 83 c8 88 f7 ff    	lea    -0x87738(%ebx),%eax
f0100800:	50                   	push   %eax
f0100801:	e8 52 33 00 00       	call   f0103b58 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100806:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100809:	81 c6 ff 03 00 00    	add    $0x3ff,%esi
f010080f:	29 fe                	sub    %edi,%esi
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100811:	c1 fe 0a             	sar    $0xa,%esi
f0100814:	56                   	push   %esi
f0100815:	8d 83 ec 88 f7 ff    	lea    -0x87714(%ebx),%eax
f010081b:	50                   	push   %eax
f010081c:	e8 37 33 00 00       	call   f0103b58 <cprintf>
	return 0;
}
f0100821:	b8 00 00 00 00       	mov    $0x0,%eax
f0100826:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100829:	5b                   	pop    %ebx
f010082a:	5e                   	pop    %esi
f010082b:	5f                   	pop    %edi
f010082c:	5d                   	pop    %ebp
f010082d:	c3                   	ret    

f010082e <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010082e:	55                   	push   %ebp
f010082f:	89 e5                	mov    %esp,%ebp
f0100831:	57                   	push   %edi
f0100832:	56                   	push   %esi
f0100833:	53                   	push   %ebx
f0100834:	83 ec 48             	sub    $0x48,%esp
f0100837:	e8 2b f9 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010083c:	81 c3 e4 c7 08 00    	add    $0x8c7e4,%ebx
	// Your code here.
	struct Eipdebuginfo info;
	cprintf("Stack backtrace:\n");
f0100842:	8d 83 8e 87 f7 ff    	lea    -0x87872(%ebx),%eax
f0100848:	50                   	push   %eax
f0100849:	e8 0a 33 00 00       	call   f0103b58 <cprintf>

static inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	asm volatile("movl %%ebp,%0" : "=r" (ebp));
f010084e:	89 ee                	mov    %ebp,%esi
	uint32_t *  ebp=(uint32_t *)read_ebp();
	while(ebp!=0x0){
f0100850:	83 c4 10             	add    $0x10,%esp
	debuginfo_eip(*(ebp+1),&info);
f0100853:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100856:	89 45 c4             	mov    %eax,-0x3c(%ebp)
	cprintf("ebp %08x eip %08x",ebp,*(ebp+1));
f0100859:	8d 83 a0 87 f7 ff    	lea    -0x87860(%ebx),%eax
f010085f:	89 45 c0             	mov    %eax,-0x40(%ebp)
	while(ebp!=0x0){
f0100862:	e9 92 00 00 00       	jmp    f01008f9 <mon_backtrace+0xcb>
	debuginfo_eip(*(ebp+1),&info);
f0100867:	83 ec 08             	sub    $0x8,%esp
f010086a:	ff 75 c4             	pushl  -0x3c(%ebp)
f010086d:	ff 76 04             	pushl  0x4(%esi)
f0100870:	e8 36 3d 00 00       	call   f01045ab <debuginfo_eip>
	cprintf("ebp %08x eip %08x",ebp,*(ebp+1));
f0100875:	83 c4 0c             	add    $0xc,%esp
f0100878:	ff 76 04             	pushl  0x4(%esi)
f010087b:	56                   	push   %esi
f010087c:	ff 75 c0             	pushl  -0x40(%ebp)
f010087f:	e8 d4 32 00 00       	call   f0103b58 <cprintf>
	cprintf(" args %08x",*(ebp+2));
f0100884:	83 c4 08             	add    $0x8,%esp
f0100887:	ff 76 08             	pushl  0x8(%esi)
f010088a:	8d 83 b2 87 f7 ff    	lea    -0x8784e(%ebx),%eax
f0100890:	50                   	push   %eax
f0100891:	e8 c2 32 00 00       	call   f0103b58 <cprintf>
	cprintf(" %08x",*(ebp+3));
f0100896:	83 c4 08             	add    $0x8,%esp
f0100899:	ff 76 0c             	pushl  0xc(%esi)
f010089c:	8d bb ac 87 f7 ff    	lea    -0x87854(%ebx),%edi
f01008a2:	57                   	push   %edi
f01008a3:	e8 b0 32 00 00       	call   f0103b58 <cprintf>
	cprintf(" %08x",*(ebp+4));
f01008a8:	83 c4 08             	add    $0x8,%esp
f01008ab:	ff 76 10             	pushl  0x10(%esi)
f01008ae:	57                   	push   %edi
f01008af:	e8 a4 32 00 00       	call   f0103b58 <cprintf>
	cprintf(" %08x",*(ebp+5));
f01008b4:	83 c4 08             	add    $0x8,%esp
f01008b7:	ff 76 14             	pushl  0x14(%esi)
f01008ba:	57                   	push   %edi
f01008bb:	e8 98 32 00 00       	call   f0103b58 <cprintf>
	cprintf(" %08x\n",*(ebp+6));
f01008c0:	83 c4 08             	add    $0x8,%esp
f01008c3:	ff 76 18             	pushl  0x18(%esi)
f01008c6:	8d 83 a9 99 f7 ff    	lea    -0x86657(%ebx),%eax
f01008cc:	50                   	push   %eax
f01008cd:	e8 86 32 00 00       	call   f0103b58 <cprintf>
	cprintf("%s:%d: %.*s+%d\n",info.eip_file,info.eip_line,info.eip_fn_namelen,info.eip_fn_name,*(ebp+1)-info.eip_fn_addr);
f01008d2:	83 c4 08             	add    $0x8,%esp
f01008d5:	8b 46 04             	mov    0x4(%esi),%eax
f01008d8:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01008db:	50                   	push   %eax
f01008dc:	ff 75 d8             	pushl  -0x28(%ebp)
f01008df:	ff 75 dc             	pushl  -0x24(%ebp)
f01008e2:	ff 75 d4             	pushl  -0x2c(%ebp)
f01008e5:	ff 75 d0             	pushl  -0x30(%ebp)
f01008e8:	8d 83 bd 87 f7 ff    	lea    -0x87843(%ebx),%eax
f01008ee:	50                   	push   %eax
f01008ef:	e8 64 32 00 00       	call   f0103b58 <cprintf>
	ebp=(uint32_t *) *(ebp);
f01008f4:	8b 36                	mov    (%esi),%esi
f01008f6:	83 c4 20             	add    $0x20,%esp
	while(ebp!=0x0){
f01008f9:	85 f6                	test   %esi,%esi
f01008fb:	0f 85 66 ff ff ff    	jne    f0100867 <mon_backtrace+0x39>
	}
 
	return 0;
}
f0100901:	b8 00 00 00 00       	mov    $0x0,%eax
f0100906:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100909:	5b                   	pop    %ebx
f010090a:	5e                   	pop    %esi
f010090b:	5f                   	pop    %edi
f010090c:	5d                   	pop    %ebp
f010090d:	c3                   	ret    

f010090e <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f010090e:	55                   	push   %ebp
f010090f:	89 e5                	mov    %esp,%ebp
f0100911:	57                   	push   %edi
f0100912:	56                   	push   %esi
f0100913:	53                   	push   %ebx
f0100914:	83 ec 68             	sub    $0x68,%esp
f0100917:	e8 4b f8 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010091c:	81 c3 04 c7 08 00    	add    $0x8c704,%ebx
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100922:	8d 83 18 89 f7 ff    	lea    -0x876e8(%ebx),%eax
f0100928:	50                   	push   %eax
f0100929:	e8 2a 32 00 00       	call   f0103b58 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010092e:	8d 83 3c 89 f7 ff    	lea    -0x876c4(%ebx),%eax
f0100934:	89 04 24             	mov    %eax,(%esp)
f0100937:	e8 1c 32 00 00       	call   f0103b58 <cprintf>

	if (tf != NULL)
f010093c:	83 c4 10             	add    $0x10,%esp
f010093f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100943:	74 0e                	je     f0100953 <monitor+0x45>
		print_trapframe(tf);
f0100945:	83 ec 0c             	sub    $0xc,%esp
f0100948:	ff 75 08             	pushl  0x8(%ebp)
f010094b:	e8 5b 36 00 00       	call   f0103fab <print_trapframe>
f0100950:	83 c4 10             	add    $0x10,%esp
		while (*buf && strchr(WHITESPACE, *buf))
f0100953:	8d bb d1 87 f7 ff    	lea    -0x8782f(%ebx),%edi
f0100959:	eb 4a                	jmp    f01009a5 <monitor+0x97>
f010095b:	83 ec 08             	sub    $0x8,%esp
f010095e:	0f be c0             	movsbl %al,%eax
f0100961:	50                   	push   %eax
f0100962:	57                   	push   %edi
f0100963:	e8 f0 46 00 00       	call   f0105058 <strchr>
f0100968:	83 c4 10             	add    $0x10,%esp
f010096b:	85 c0                	test   %eax,%eax
f010096d:	74 08                	je     f0100977 <monitor+0x69>
			*buf++ = 0;
f010096f:	c6 06 00             	movb   $0x0,(%esi)
f0100972:	8d 76 01             	lea    0x1(%esi),%esi
f0100975:	eb 79                	jmp    f01009f0 <monitor+0xe2>
		if (*buf == 0)
f0100977:	80 3e 00             	cmpb   $0x0,(%esi)
f010097a:	74 7f                	je     f01009fb <monitor+0xed>
		if (argc == MAXARGS-1) {
f010097c:	83 7d a4 0f          	cmpl   $0xf,-0x5c(%ebp)
f0100980:	74 0f                	je     f0100991 <monitor+0x83>
		argv[argc++] = buf;
f0100982:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100985:	8d 48 01             	lea    0x1(%eax),%ecx
f0100988:	89 4d a4             	mov    %ecx,-0x5c(%ebp)
f010098b:	89 74 85 a8          	mov    %esi,-0x58(%ebp,%eax,4)
f010098f:	eb 44                	jmp    f01009d5 <monitor+0xc7>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100991:	83 ec 08             	sub    $0x8,%esp
f0100994:	6a 10                	push   $0x10
f0100996:	8d 83 d6 87 f7 ff    	lea    -0x8782a(%ebx),%eax
f010099c:	50                   	push   %eax
f010099d:	e8 b6 31 00 00       	call   f0103b58 <cprintf>
f01009a2:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f01009a5:	8d 83 cd 87 f7 ff    	lea    -0x87833(%ebx),%eax
f01009ab:	89 45 a4             	mov    %eax,-0x5c(%ebp)
f01009ae:	83 ec 0c             	sub    $0xc,%esp
f01009b1:	ff 75 a4             	pushl  -0x5c(%ebp)
f01009b4:	e8 67 44 00 00       	call   f0104e20 <readline>
f01009b9:	89 c6                	mov    %eax,%esi
		if (buf != NULL)
f01009bb:	83 c4 10             	add    $0x10,%esp
f01009be:	85 c0                	test   %eax,%eax
f01009c0:	74 ec                	je     f01009ae <monitor+0xa0>
	argv[argc] = 0;
f01009c2:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	argc = 0;
f01009c9:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
f01009d0:	eb 1e                	jmp    f01009f0 <monitor+0xe2>
			buf++;
f01009d2:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f01009d5:	0f b6 06             	movzbl (%esi),%eax
f01009d8:	84 c0                	test   %al,%al
f01009da:	74 14                	je     f01009f0 <monitor+0xe2>
f01009dc:	83 ec 08             	sub    $0x8,%esp
f01009df:	0f be c0             	movsbl %al,%eax
f01009e2:	50                   	push   %eax
f01009e3:	57                   	push   %edi
f01009e4:	e8 6f 46 00 00       	call   f0105058 <strchr>
f01009e9:	83 c4 10             	add    $0x10,%esp
f01009ec:	85 c0                	test   %eax,%eax
f01009ee:	74 e2                	je     f01009d2 <monitor+0xc4>
		while (*buf && strchr(WHITESPACE, *buf))
f01009f0:	0f b6 06             	movzbl (%esi),%eax
f01009f3:	84 c0                	test   %al,%al
f01009f5:	0f 85 60 ff ff ff    	jne    f010095b <monitor+0x4d>
	argv[argc] = 0;
f01009fb:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f01009fe:	c7 44 85 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%eax,4)
f0100a05:	00 
	if (argc == 0)
f0100a06:	85 c0                	test   %eax,%eax
f0100a08:	74 9b                	je     f01009a5 <monitor+0x97>
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a0a:	83 ec 08             	sub    $0x8,%esp
f0100a0d:	8d 83 5e 87 f7 ff    	lea    -0x878a2(%ebx),%eax
f0100a13:	50                   	push   %eax
f0100a14:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a17:	e8 de 45 00 00       	call   f0104ffa <strcmp>
f0100a1c:	83 c4 10             	add    $0x10,%esp
f0100a1f:	85 c0                	test   %eax,%eax
f0100a21:	74 38                	je     f0100a5b <monitor+0x14d>
f0100a23:	83 ec 08             	sub    $0x8,%esp
f0100a26:	8d 83 6c 87 f7 ff    	lea    -0x87894(%ebx),%eax
f0100a2c:	50                   	push   %eax
f0100a2d:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a30:	e8 c5 45 00 00       	call   f0104ffa <strcmp>
f0100a35:	83 c4 10             	add    $0x10,%esp
f0100a38:	85 c0                	test   %eax,%eax
f0100a3a:	74 1a                	je     f0100a56 <monitor+0x148>
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a3c:	83 ec 08             	sub    $0x8,%esp
f0100a3f:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a42:	8d 83 f3 87 f7 ff    	lea    -0x8780d(%ebx),%eax
f0100a48:	50                   	push   %eax
f0100a49:	e8 0a 31 00 00       	call   f0103b58 <cprintf>
f0100a4e:	83 c4 10             	add    $0x10,%esp
f0100a51:	e9 4f ff ff ff       	jmp    f01009a5 <monitor+0x97>
	for (i = 0; i < ARRAY_SIZE(commands); i++) {
f0100a56:	b8 01 00 00 00       	mov    $0x1,%eax
			return commands[i].func(argc, argv, tf);
f0100a5b:	83 ec 04             	sub    $0x4,%esp
f0100a5e:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0100a61:	ff 75 08             	pushl  0x8(%ebp)
f0100a64:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a67:	52                   	push   %edx
f0100a68:	ff 75 a4             	pushl  -0x5c(%ebp)
f0100a6b:	ff 94 83 18 20 00 00 	call   *0x2018(%ebx,%eax,4)
			if (runcmd(buf, tf) < 0)
f0100a72:	83 c4 10             	add    $0x10,%esp
f0100a75:	85 c0                	test   %eax,%eax
f0100a77:	0f 89 28 ff ff ff    	jns    f01009a5 <monitor+0x97>
				break;
	}
}
f0100a7d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a80:	5b                   	pop    %ebx
f0100a81:	5e                   	pop    %esi
f0100a82:	5f                   	pop    %edi
f0100a83:	5d                   	pop    %ebp
f0100a84:	c3                   	ret    

f0100a85 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100a85:	55                   	push   %ebp
f0100a86:	89 e5                	mov    %esp,%ebp
f0100a88:	e8 a1 28 00 00       	call   f010332e <__x86.get_pc_thunk.dx>
f0100a8d:	81 c2 93 c5 08 00    	add    $0x8c593,%edx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100a93:	83 ba f8 22 00 00 00 	cmpl   $0x0,0x22f8(%edx)
f0100a9a:	74 20                	je     f0100abc <boot_alloc+0x37>
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	if (n == 0)
f0100a9c:	85 c0                	test   %eax,%eax
f0100a9e:	74 36                	je     f0100ad6 <boot_alloc+0x51>
		return nextfree;
	result = nextfree;
f0100aa0:	8b 8a f8 22 00 00    	mov    0x22f8(%edx),%ecx
	nextfree += n;
	nextfree = ROUNDUP((char*)nextfree,PGSIZE);
f0100aa6:	8d 84 01 ff 0f 00 00 	lea    0xfff(%ecx,%eax,1),%eax
f0100aad:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100ab2:	89 82 f8 22 00 00    	mov    %eax,0x22f8(%edx)
	return result;
}
f0100ab8:	89 c8                	mov    %ecx,%eax
f0100aba:	5d                   	pop    %ebp
f0100abb:	c3                   	ret    
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100abc:	c7 c1 e0 ff 18 f0    	mov    $0xf018ffe0,%ecx
f0100ac2:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
f0100ac8:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100ace:	89 8a f8 22 00 00    	mov    %ecx,0x22f8(%edx)
f0100ad4:	eb c6                	jmp    f0100a9c <boot_alloc+0x17>
		return nextfree;
f0100ad6:	8b 8a f8 22 00 00    	mov    0x22f8(%edx),%ecx
f0100adc:	eb da                	jmp    f0100ab8 <boot_alloc+0x33>

f0100ade <nvram_read>:
{
f0100ade:	55                   	push   %ebp
f0100adf:	89 e5                	mov    %esp,%ebp
f0100ae1:	57                   	push   %edi
f0100ae2:	56                   	push   %esi
f0100ae3:	53                   	push   %ebx
f0100ae4:	83 ec 18             	sub    $0x18,%esp
f0100ae7:	e8 7b f6 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0100aec:	81 c3 34 c5 08 00    	add    $0x8c534,%ebx
f0100af2:	89 c7                	mov    %eax,%edi
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100af4:	50                   	push   %eax
f0100af5:	e8 d7 2f 00 00       	call   f0103ad1 <mc146818_read>
f0100afa:	89 c6                	mov    %eax,%esi
f0100afc:	83 c7 01             	add    $0x1,%edi
f0100aff:	89 3c 24             	mov    %edi,(%esp)
f0100b02:	e8 ca 2f 00 00       	call   f0103ad1 <mc146818_read>
f0100b07:	c1 e0 08             	shl    $0x8,%eax
f0100b0a:	09 f0                	or     %esi,%eax
}
f0100b0c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100b0f:	5b                   	pop    %ebx
f0100b10:	5e                   	pop    %esi
f0100b11:	5f                   	pop    %edi
f0100b12:	5d                   	pop    %ebp
f0100b13:	c3                   	ret    

f0100b14 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100b14:	55                   	push   %ebp
f0100b15:	89 e5                	mov    %esp,%ebp
f0100b17:	56                   	push   %esi
f0100b18:	53                   	push   %ebx
f0100b19:	e8 14 28 00 00       	call   f0103332 <__x86.get_pc_thunk.cx>
f0100b1e:	81 c1 02 c5 08 00    	add    $0x8c502,%ecx
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100b24:	89 d3                	mov    %edx,%ebx
f0100b26:	c1 eb 16             	shr    $0x16,%ebx
	if (!(*pgdir & PTE_P))
f0100b29:	8b 04 98             	mov    (%eax,%ebx,4),%eax
f0100b2c:	a8 01                	test   $0x1,%al
f0100b2e:	74 5a                	je     f0100b8a <check_va2pa+0x76>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100b30:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b35:	89 c6                	mov    %eax,%esi
f0100b37:	c1 ee 0c             	shr    $0xc,%esi
f0100b3a:	c7 c3 e8 ff 18 f0    	mov    $0xf018ffe8,%ebx
f0100b40:	3b 33                	cmp    (%ebx),%esi
f0100b42:	73 2b                	jae    f0100b6f <check_va2pa+0x5b>
	if (!(p[PTX(va)] & PTE_P))
f0100b44:	c1 ea 0c             	shr    $0xc,%edx
f0100b47:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100b4d:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100b54:	89 c2                	mov    %eax,%edx
f0100b56:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b59:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b5e:	85 d2                	test   %edx,%edx
f0100b60:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100b65:	0f 44 c2             	cmove  %edx,%eax
}
f0100b68:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0100b6b:	5b                   	pop    %ebx
f0100b6c:	5e                   	pop    %esi
f0100b6d:	5d                   	pop    %ebp
f0100b6e:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b6f:	50                   	push   %eax
f0100b70:	8d 81 64 89 f7 ff    	lea    -0x8769c(%ecx),%eax
f0100b76:	50                   	push   %eax
f0100b77:	68 36 03 00 00       	push   $0x336
f0100b7c:	8d 81 8d 91 f7 ff    	lea    -0x86e73(%ecx),%eax
f0100b82:	50                   	push   %eax
f0100b83:	89 cb                	mov    %ecx,%ebx
f0100b85:	e8 27 f5 ff ff       	call   f01000b1 <_panic>
		return ~0;
f0100b8a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100b8f:	eb d7                	jmp    f0100b68 <check_va2pa+0x54>

f0100b91 <check_page_free_list>:
{
f0100b91:	55                   	push   %ebp
f0100b92:	89 e5                	mov    %esp,%ebp
f0100b94:	57                   	push   %edi
f0100b95:	56                   	push   %esi
f0100b96:	53                   	push   %ebx
f0100b97:	83 ec 3c             	sub    $0x3c,%esp
f0100b9a:	e8 9b 27 00 00       	call   f010333a <__x86.get_pc_thunk.di>
f0100b9f:	81 c7 81 c4 08 00    	add    $0x8c481,%edi
f0100ba5:	89 7d c4             	mov    %edi,-0x3c(%ebp)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ba8:	84 c0                	test   %al,%al
f0100baa:	0f 85 dd 02 00 00    	jne    f0100e8d <check_page_free_list+0x2fc>
	if (!page_free_list)
f0100bb0:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100bb3:	83 b8 00 23 00 00 00 	cmpl   $0x0,0x2300(%eax)
f0100bba:	74 0c                	je     f0100bc8 <check_page_free_list+0x37>
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100bbc:	c7 45 d4 00 04 00 00 	movl   $0x400,-0x2c(%ebp)
f0100bc3:	e9 2f 03 00 00       	jmp    f0100ef7 <check_page_free_list+0x366>
		panic("'page_free_list' is a null pointer!");
f0100bc8:	83 ec 04             	sub    $0x4,%esp
f0100bcb:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100bce:	8d 83 88 89 f7 ff    	lea    -0x87678(%ebx),%eax
f0100bd4:	50                   	push   %eax
f0100bd5:	68 72 02 00 00       	push   $0x272
f0100bda:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0100be0:	50                   	push   %eax
f0100be1:	e8 cb f4 ff ff       	call   f01000b1 <_panic>
f0100be6:	50                   	push   %eax
f0100be7:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100bea:	8d 83 64 89 f7 ff    	lea    -0x8769c(%ebx),%eax
f0100bf0:	50                   	push   %eax
f0100bf1:	6a 56                	push   $0x56
f0100bf3:	8d 83 99 91 f7 ff    	lea    -0x86e67(%ebx),%eax
f0100bf9:	50                   	push   %eax
f0100bfa:	e8 b2 f4 ff ff       	call   f01000b1 <_panic>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100bff:	8b 36                	mov    (%esi),%esi
f0100c01:	85 f6                	test   %esi,%esi
f0100c03:	74 40                	je     f0100c45 <check_page_free_list+0xb4>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c05:	89 f0                	mov    %esi,%eax
f0100c07:	2b 07                	sub    (%edi),%eax
f0100c09:	c1 f8 03             	sar    $0x3,%eax
f0100c0c:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100c0f:	89 c2                	mov    %eax,%edx
f0100c11:	c1 ea 16             	shr    $0x16,%edx
f0100c14:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100c17:	73 e6                	jae    f0100bff <check_page_free_list+0x6e>
	if (PGNUM(pa) >= npages)
f0100c19:	89 c2                	mov    %eax,%edx
f0100c1b:	c1 ea 0c             	shr    $0xc,%edx
f0100c1e:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0100c21:	3b 11                	cmp    (%ecx),%edx
f0100c23:	73 c1                	jae    f0100be6 <check_page_free_list+0x55>
			memset(page2kva(pp), 0x97, 128);
f0100c25:	83 ec 04             	sub    $0x4,%esp
f0100c28:	68 80 00 00 00       	push   $0x80
f0100c2d:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100c32:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100c37:	50                   	push   %eax
f0100c38:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c3b:	e8 55 44 00 00       	call   f0105095 <memset>
f0100c40:	83 c4 10             	add    $0x10,%esp
f0100c43:	eb ba                	jmp    f0100bff <check_page_free_list+0x6e>
	first_free_page = (char *) boot_alloc(0);
f0100c45:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c4a:	e8 36 fe ff ff       	call   f0100a85 <boot_alloc>
f0100c4f:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c52:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100c55:	8b 97 00 23 00 00    	mov    0x2300(%edi),%edx
		assert(pp >= pages);
f0100c5b:	c7 c0 f0 ff 18 f0    	mov    $0xf018fff0,%eax
f0100c61:	8b 08                	mov    (%eax),%ecx
		assert(pp < pages + npages);
f0100c63:	c7 c0 e8 ff 18 f0    	mov    $0xf018ffe8,%eax
f0100c69:	8b 00                	mov    (%eax),%eax
f0100c6b:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100c6e:	8d 1c c1             	lea    (%ecx,%eax,8),%ebx
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c71:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c74:	bf 00 00 00 00       	mov    $0x0,%edi
f0100c79:	89 75 d0             	mov    %esi,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c7c:	e9 08 01 00 00       	jmp    f0100d89 <check_page_free_list+0x1f8>
		assert(pp >= pages);
f0100c81:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100c84:	8d 83 a7 91 f7 ff    	lea    -0x86e59(%ebx),%eax
f0100c8a:	50                   	push   %eax
f0100c8b:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0100c91:	50                   	push   %eax
f0100c92:	68 8c 02 00 00       	push   $0x28c
f0100c97:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0100c9d:	50                   	push   %eax
f0100c9e:	e8 0e f4 ff ff       	call   f01000b1 <_panic>
		assert(pp < pages + npages);
f0100ca3:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100ca6:	8d 83 c8 91 f7 ff    	lea    -0x86e38(%ebx),%eax
f0100cac:	50                   	push   %eax
f0100cad:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0100cb3:	50                   	push   %eax
f0100cb4:	68 8d 02 00 00       	push   $0x28d
f0100cb9:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0100cbf:	50                   	push   %eax
f0100cc0:	e8 ec f3 ff ff       	call   f01000b1 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100cc5:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100cc8:	8d 83 ac 89 f7 ff    	lea    -0x87654(%ebx),%eax
f0100cce:	50                   	push   %eax
f0100ccf:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0100cd5:	50                   	push   %eax
f0100cd6:	68 8e 02 00 00       	push   $0x28e
f0100cdb:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0100ce1:	50                   	push   %eax
f0100ce2:	e8 ca f3 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != 0);
f0100ce7:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100cea:	8d 83 dc 91 f7 ff    	lea    -0x86e24(%ebx),%eax
f0100cf0:	50                   	push   %eax
f0100cf1:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0100cf7:	50                   	push   %eax
f0100cf8:	68 91 02 00 00       	push   $0x291
f0100cfd:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0100d03:	50                   	push   %eax
f0100d04:	e8 a8 f3 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100d09:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d0c:	8d 83 ed 91 f7 ff    	lea    -0x86e13(%ebx),%eax
f0100d12:	50                   	push   %eax
f0100d13:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0100d19:	50                   	push   %eax
f0100d1a:	68 92 02 00 00       	push   $0x292
f0100d1f:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0100d25:	50                   	push   %eax
f0100d26:	e8 86 f3 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100d2b:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d2e:	8d 83 e0 89 f7 ff    	lea    -0x87620(%ebx),%eax
f0100d34:	50                   	push   %eax
f0100d35:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0100d3b:	50                   	push   %eax
f0100d3c:	68 93 02 00 00       	push   $0x293
f0100d41:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0100d47:	50                   	push   %eax
f0100d48:	e8 64 f3 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100d4d:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100d50:	8d 83 06 92 f7 ff    	lea    -0x86dfa(%ebx),%eax
f0100d56:	50                   	push   %eax
f0100d57:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0100d5d:	50                   	push   %eax
f0100d5e:	68 94 02 00 00       	push   $0x294
f0100d63:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0100d69:	50                   	push   %eax
f0100d6a:	e8 42 f3 ff ff       	call   f01000b1 <_panic>
	if (PGNUM(pa) >= npages)
f0100d6f:	89 c6                	mov    %eax,%esi
f0100d71:	c1 ee 0c             	shr    $0xc,%esi
f0100d74:	39 75 cc             	cmp    %esi,-0x34(%ebp)
f0100d77:	76 70                	jbe    f0100de9 <check_page_free_list+0x258>
	return (void *)(pa + KERNBASE);
f0100d79:	2d 00 00 00 10       	sub    $0x10000000,%eax
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d7e:	39 45 c8             	cmp    %eax,-0x38(%ebp)
f0100d81:	77 7f                	ja     f0100e02 <check_page_free_list+0x271>
			++nfree_extmem;
f0100d83:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d87:	8b 12                	mov    (%edx),%edx
f0100d89:	85 d2                	test   %edx,%edx
f0100d8b:	0f 84 93 00 00 00    	je     f0100e24 <check_page_free_list+0x293>
		assert(pp >= pages);
f0100d91:	39 d1                	cmp    %edx,%ecx
f0100d93:	0f 87 e8 fe ff ff    	ja     f0100c81 <check_page_free_list+0xf0>
		assert(pp < pages + npages);
f0100d99:	39 d3                	cmp    %edx,%ebx
f0100d9b:	0f 86 02 ff ff ff    	jbe    f0100ca3 <check_page_free_list+0x112>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100da1:	89 d0                	mov    %edx,%eax
f0100da3:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100da6:	a8 07                	test   $0x7,%al
f0100da8:	0f 85 17 ff ff ff    	jne    f0100cc5 <check_page_free_list+0x134>
	return (pp - pages) << PGSHIFT;
f0100dae:	c1 f8 03             	sar    $0x3,%eax
f0100db1:	c1 e0 0c             	shl    $0xc,%eax
		assert(page2pa(pp) != 0);
f0100db4:	85 c0                	test   %eax,%eax
f0100db6:	0f 84 2b ff ff ff    	je     f0100ce7 <check_page_free_list+0x156>
		assert(page2pa(pp) != IOPHYSMEM);
f0100dbc:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100dc1:	0f 84 42 ff ff ff    	je     f0100d09 <check_page_free_list+0x178>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100dc7:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100dcc:	0f 84 59 ff ff ff    	je     f0100d2b <check_page_free_list+0x19a>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100dd2:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100dd7:	0f 84 70 ff ff ff    	je     f0100d4d <check_page_free_list+0x1bc>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100ddd:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100de2:	77 8b                	ja     f0100d6f <check_page_free_list+0x1de>
			++nfree_basemem;
f0100de4:	83 c7 01             	add    $0x1,%edi
f0100de7:	eb 9e                	jmp    f0100d87 <check_page_free_list+0x1f6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100de9:	50                   	push   %eax
f0100dea:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100ded:	8d 83 64 89 f7 ff    	lea    -0x8769c(%ebx),%eax
f0100df3:	50                   	push   %eax
f0100df4:	6a 56                	push   $0x56
f0100df6:	8d 83 99 91 f7 ff    	lea    -0x86e67(%ebx),%eax
f0100dfc:	50                   	push   %eax
f0100dfd:	e8 af f2 ff ff       	call   f01000b1 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e02:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e05:	8d 83 04 8a f7 ff    	lea    -0x875fc(%ebx),%eax
f0100e0b:	50                   	push   %eax
f0100e0c:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0100e12:	50                   	push   %eax
f0100e13:	68 95 02 00 00       	push   $0x295
f0100e18:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0100e1e:	50                   	push   %eax
f0100e1f:	e8 8d f2 ff ff       	call   f01000b1 <_panic>
f0100e24:	8b 75 d0             	mov    -0x30(%ebp),%esi
	assert(nfree_basemem > 0);
f0100e27:	85 ff                	test   %edi,%edi
f0100e29:	7e 1e                	jle    f0100e49 <check_page_free_list+0x2b8>
	assert(nfree_extmem > 0);
f0100e2b:	85 f6                	test   %esi,%esi
f0100e2d:	7e 3c                	jle    f0100e6b <check_page_free_list+0x2da>
	cprintf("check_page_free_list() succeeded!\n");
f0100e2f:	83 ec 0c             	sub    $0xc,%esp
f0100e32:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e35:	8d 83 4c 8a f7 ff    	lea    -0x875b4(%ebx),%eax
f0100e3b:	50                   	push   %eax
f0100e3c:	e8 17 2d 00 00       	call   f0103b58 <cprintf>
}
f0100e41:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e44:	5b                   	pop    %ebx
f0100e45:	5e                   	pop    %esi
f0100e46:	5f                   	pop    %edi
f0100e47:	5d                   	pop    %ebp
f0100e48:	c3                   	ret    
	assert(nfree_basemem > 0);
f0100e49:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e4c:	8d 83 20 92 f7 ff    	lea    -0x86de0(%ebx),%eax
f0100e52:	50                   	push   %eax
f0100e53:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0100e59:	50                   	push   %eax
f0100e5a:	68 9d 02 00 00       	push   $0x29d
f0100e5f:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0100e65:	50                   	push   %eax
f0100e66:	e8 46 f2 ff ff       	call   f01000b1 <_panic>
	assert(nfree_extmem > 0);
f0100e6b:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0100e6e:	8d 83 32 92 f7 ff    	lea    -0x86dce(%ebx),%eax
f0100e74:	50                   	push   %eax
f0100e75:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0100e7b:	50                   	push   %eax
f0100e7c:	68 9e 02 00 00       	push   $0x29e
f0100e81:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0100e87:	50                   	push   %eax
f0100e88:	e8 24 f2 ff ff       	call   f01000b1 <_panic>
	if (!page_free_list)
f0100e8d:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100e90:	8b 80 00 23 00 00    	mov    0x2300(%eax),%eax
f0100e96:	85 c0                	test   %eax,%eax
f0100e98:	0f 84 2a fd ff ff    	je     f0100bc8 <check_page_free_list+0x37>
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100e9e:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100ea1:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100ea4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100ea7:	89 55 e4             	mov    %edx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0100eaa:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100ead:	c7 c3 f0 ff 18 f0    	mov    $0xf018fff0,%ebx
f0100eb3:	89 c2                	mov    %eax,%edx
f0100eb5:	2b 13                	sub    (%ebx),%edx
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100eb7:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100ebd:	0f 95 c2             	setne  %dl
f0100ec0:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100ec3:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100ec7:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100ec9:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ecd:	8b 00                	mov    (%eax),%eax
f0100ecf:	85 c0                	test   %eax,%eax
f0100ed1:	75 e0                	jne    f0100eb3 <check_page_free_list+0x322>
		*tp[1] = 0;
f0100ed3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ed6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100edc:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100edf:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ee2:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100ee4:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ee7:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0100eea:	89 87 00 23 00 00    	mov    %eax,0x2300(%edi)
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ef0:	c7 45 d4 01 00 00 00 	movl   $0x1,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ef7:	8b 45 c4             	mov    -0x3c(%ebp),%eax
f0100efa:	8b b0 00 23 00 00    	mov    0x2300(%eax),%esi
f0100f00:	c7 c7 f0 ff 18 f0    	mov    $0xf018fff0,%edi
	if (PGNUM(pa) >= npages)
f0100f06:	c7 c0 e8 ff 18 f0    	mov    $0xf018ffe8,%eax
f0100f0c:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0100f0f:	e9 ed fc ff ff       	jmp    f0100c01 <check_page_free_list+0x70>

f0100f14 <page_init>:
{
f0100f14:	55                   	push   %ebp
f0100f15:	89 e5                	mov    %esp,%ebp
f0100f17:	57                   	push   %edi
f0100f18:	56                   	push   %esi
f0100f19:	53                   	push   %ebx
f0100f1a:	83 ec 08             	sub    $0x8,%esp
f0100f1d:	e8 14 24 00 00       	call   f0103336 <__x86.get_pc_thunk.si>
f0100f22:	81 c6 fe c0 08 00    	add    $0x8c0fe,%esi
	for (i = 0; i < npages; i++) {
f0100f28:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100f2d:	c7 c7 e8 ff 18 f0    	mov    $0xf018ffe8,%edi
			pages[i].pp_ref = 0;
f0100f33:	c7 c0 f0 ff 18 f0    	mov    $0xf018fff0,%eax
f0100f39:	89 45 ec             	mov    %eax,-0x14(%ebp)
	for (i = 0; i < npages; i++) {
f0100f3c:	eb 38                	jmp    f0100f76 <page_init+0x62>
		else if(i>=1 && i<npages_basemem)
f0100f3e:	39 9e 04 23 00 00    	cmp    %ebx,0x2304(%esi)
f0100f44:	76 52                	jbe    f0100f98 <page_init+0x84>
f0100f46:	8d 0c dd 00 00 00 00 	lea    0x0(,%ebx,8),%ecx
			pages[i].pp_ref = 0;
f0100f4d:	c7 c0 f0 ff 18 f0    	mov    $0xf018fff0,%eax
f0100f53:	89 ca                	mov    %ecx,%edx
f0100f55:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100f58:	03 10                	add    (%eax),%edx
f0100f5a:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
			pages[i].pp_link = page_free_list; 
f0100f60:	8b 86 00 23 00 00    	mov    0x2300(%esi),%eax
f0100f66:	89 02                	mov    %eax,(%edx)
			page_free_list = &pages[i];
f0100f68:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100f6b:	03 08                	add    (%eax),%ecx
f0100f6d:	89 8e 00 23 00 00    	mov    %ecx,0x2300(%esi)
	for (i = 0; i < npages; i++) {
f0100f73:	83 c3 01             	add    $0x1,%ebx
f0100f76:	39 1f                	cmp    %ebx,(%edi)
f0100f78:	0f 86 a1 00 00 00    	jbe    f010101f <page_init+0x10b>
		if(i == 0)
f0100f7e:	85 db                	test   %ebx,%ebx
f0100f80:	75 bc                	jne    f0100f3e <page_init+0x2a>
			pages[i].pp_ref = 1;
f0100f82:	c7 c0 f0 ff 18 f0    	mov    $0xf018fff0,%eax
f0100f88:	8b 00                	mov    (%eax),%eax
f0100f8a:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100f90:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100f96:	eb db                	jmp    f0100f73 <page_init+0x5f>
		else if(i>=IOPHYSMEM/PGSIZE && i< EXTPHYSMEM/PGSIZE )
f0100f98:	8d 83 60 ff ff ff    	lea    -0xa0(%ebx),%eax
f0100f9e:	83 f8 5f             	cmp    $0x5f,%eax
f0100fa1:	77 19                	ja     f0100fbc <page_init+0xa8>
			pages[i].pp_ref = 1;
f0100fa3:	c7 c0 f0 ff 18 f0    	mov    $0xf018fff0,%eax
f0100fa9:	8b 00                	mov    (%eax),%eax
f0100fab:	8d 04 d8             	lea    (%eax,%ebx,8),%eax
f0100fae:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link = NULL;
f0100fb4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f0100fba:	eb b7                	jmp    f0100f73 <page_init+0x5f>
		else if(i>=EXTPHYSMEM/PGSIZE && i<((int)(boot_alloc(0))-KERNBASE)/PGSIZE)
f0100fbc:	81 fb ff 00 00 00    	cmp    $0xff,%ebx
f0100fc2:	77 29                	ja     f0100fed <page_init+0xd9>
f0100fc4:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
			pages[i].pp_ref = 0;
f0100fcb:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100fce:	89 c2                	mov    %eax,%edx
f0100fd0:	03 11                	add    (%ecx),%edx
f0100fd2:	66 c7 42 04 00 00    	movw   $0x0,0x4(%edx)
			pages[i].pp_link = page_free_list;
f0100fd8:	8b 8e 00 23 00 00    	mov    0x2300(%esi),%ecx
f0100fde:	89 0a                	mov    %ecx,(%edx)
			page_free_list = &pages[i];
f0100fe0:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0100fe3:	03 01                	add    (%ecx),%eax
f0100fe5:	89 86 00 23 00 00    	mov    %eax,0x2300(%esi)
f0100feb:	eb 86                	jmp    f0100f73 <page_init+0x5f>
		else if(i>=EXTPHYSMEM/PGSIZE && i<((int)(boot_alloc(0))-KERNBASE)/PGSIZE)
f0100fed:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ff2:	e8 8e fa ff ff       	call   f0100a85 <boot_alloc>
f0100ff7:	05 00 00 00 10       	add    $0x10000000,%eax
f0100ffc:	c1 e8 0c             	shr    $0xc,%eax
f0100fff:	39 d8                	cmp    %ebx,%eax
f0101001:	76 c1                	jbe    f0100fc4 <page_init+0xb0>
			pages[i].pp_ref = 1;
f0101003:	c7 c0 f0 ff 18 f0    	mov    $0xf018fff0,%eax
f0101009:	8b 00                	mov    (%eax),%eax
f010100b:	8d 04 d8             	lea    (%eax,%ebx,8),%eax
f010100e:	66 c7 40 04 01 00    	movw   $0x1,0x4(%eax)
			pages[i].pp_link =NULL;
f0101014:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
f010101a:	e9 54 ff ff ff       	jmp    f0100f73 <page_init+0x5f>
}
f010101f:	83 c4 08             	add    $0x8,%esp
f0101022:	5b                   	pop    %ebx
f0101023:	5e                   	pop    %esi
f0101024:	5f                   	pop    %edi
f0101025:	5d                   	pop    %ebp
f0101026:	c3                   	ret    

f0101027 <page_alloc>:
{
f0101027:	55                   	push   %ebp
f0101028:	89 e5                	mov    %esp,%ebp
f010102a:	56                   	push   %esi
f010102b:	53                   	push   %ebx
f010102c:	e8 36 f1 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0101031:	81 c3 ef bf 08 00    	add    $0x8bfef,%ebx
	if(page_free_list == NULL)
f0101037:	8b b3 00 23 00 00    	mov    0x2300(%ebx),%esi
f010103d:	85 f6                	test   %esi,%esi
f010103f:	74 14                	je     f0101055 <page_alloc+0x2e>
	page_free_list = page->pp_link;
f0101041:	8b 06                	mov    (%esi),%eax
f0101043:	89 83 00 23 00 00    	mov    %eax,0x2300(%ebx)
	page->pp_link = 0;
f0101049:	c7 06 00 00 00 00    	movl   $0x0,(%esi)
	if(alloc_flags & ALLOC_ZERO)
f010104f:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0101053:	75 09                	jne    f010105e <page_alloc+0x37>
}
f0101055:	89 f0                	mov    %esi,%eax
f0101057:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010105a:	5b                   	pop    %ebx
f010105b:	5e                   	pop    %esi
f010105c:	5d                   	pop    %ebp
f010105d:	c3                   	ret    
	return (pp - pages) << PGSHIFT;
f010105e:	c7 c0 f0 ff 18 f0    	mov    $0xf018fff0,%eax
f0101064:	89 f2                	mov    %esi,%edx
f0101066:	2b 10                	sub    (%eax),%edx
f0101068:	89 d0                	mov    %edx,%eax
f010106a:	c1 f8 03             	sar    $0x3,%eax
f010106d:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0101070:	89 c1                	mov    %eax,%ecx
f0101072:	c1 e9 0c             	shr    $0xc,%ecx
f0101075:	c7 c2 e8 ff 18 f0    	mov    $0xf018ffe8,%edx
f010107b:	3b 0a                	cmp    (%edx),%ecx
f010107d:	73 1a                	jae    f0101099 <page_alloc+0x72>
		memset(page2kva(page), 0, PGSIZE);
f010107f:	83 ec 04             	sub    $0x4,%esp
f0101082:	68 00 10 00 00       	push   $0x1000
f0101087:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0101089:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010108e:	50                   	push   %eax
f010108f:	e8 01 40 00 00       	call   f0105095 <memset>
f0101094:	83 c4 10             	add    $0x10,%esp
f0101097:	eb bc                	jmp    f0101055 <page_alloc+0x2e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101099:	50                   	push   %eax
f010109a:	8d 83 64 89 f7 ff    	lea    -0x8769c(%ebx),%eax
f01010a0:	50                   	push   %eax
f01010a1:	6a 56                	push   $0x56
f01010a3:	8d 83 99 91 f7 ff    	lea    -0x86e67(%ebx),%eax
f01010a9:	50                   	push   %eax
f01010aa:	e8 02 f0 ff ff       	call   f01000b1 <_panic>

f01010af <page_free>:
{
f01010af:	55                   	push   %ebp
f01010b0:	89 e5                	mov    %esp,%ebp
f01010b2:	53                   	push   %ebx
f01010b3:	83 ec 04             	sub    $0x4,%esp
f01010b6:	e8 ac f0 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01010bb:	81 c3 65 bf 08 00    	add    $0x8bf65,%ebx
f01010c1:	8b 45 08             	mov    0x8(%ebp),%eax
	if(pp->pp_link != 0  || pp->pp_ref != 0)
f01010c4:	83 38 00             	cmpl   $0x0,(%eax)
f01010c7:	75 1a                	jne    f01010e3 <page_free+0x34>
f01010c9:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f01010ce:	75 13                	jne    f01010e3 <page_free+0x34>
	pp->pp_link = page_free_list;
f01010d0:	8b 8b 00 23 00 00    	mov    0x2300(%ebx),%ecx
f01010d6:	89 08                	mov    %ecx,(%eax)
	page_free_list = pp;
f01010d8:	89 83 00 23 00 00    	mov    %eax,0x2300(%ebx)
}
f01010de:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01010e1:	c9                   	leave  
f01010e2:	c3                   	ret    
		panic("page_free is not right");
f01010e3:	83 ec 04             	sub    $0x4,%esp
f01010e6:	8d 83 43 92 f7 ff    	lea    -0x86dbd(%ebx),%eax
f01010ec:	50                   	push   %eax
f01010ed:	68 61 01 00 00       	push   $0x161
f01010f2:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01010f8:	50                   	push   %eax
f01010f9:	e8 b3 ef ff ff       	call   f01000b1 <_panic>

f01010fe <page_decref>:
{
f01010fe:	55                   	push   %ebp
f01010ff:	89 e5                	mov    %esp,%ebp
f0101101:	83 ec 08             	sub    $0x8,%esp
f0101104:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101107:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f010110b:	83 e8 01             	sub    $0x1,%eax
f010110e:	66 89 42 04          	mov    %ax,0x4(%edx)
f0101112:	66 85 c0             	test   %ax,%ax
f0101115:	74 02                	je     f0101119 <page_decref+0x1b>
}
f0101117:	c9                   	leave  
f0101118:	c3                   	ret    
		page_free(pp);
f0101119:	83 ec 0c             	sub    $0xc,%esp
f010111c:	52                   	push   %edx
f010111d:	e8 8d ff ff ff       	call   f01010af <page_free>
f0101122:	83 c4 10             	add    $0x10,%esp
}
f0101125:	eb f0                	jmp    f0101117 <page_decref+0x19>

f0101127 <pgdir_walk>:
{
f0101127:	55                   	push   %ebp
f0101128:	89 e5                	mov    %esp,%ebp
f010112a:	57                   	push   %edi
f010112b:	56                   	push   %esi
f010112c:	53                   	push   %ebx
f010112d:	83 ec 0c             	sub    $0xc,%esp
f0101130:	e8 32 f0 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0101135:	81 c3 eb be 08 00    	add    $0x8beeb,%ebx
f010113b:	8b 75 0c             	mov    0xc(%ebp),%esi
	int pdeIndex = (unsigned int)va >>22;
f010113e:	89 f7                	mov    %esi,%edi
f0101140:	c1 ef 16             	shr    $0x16,%edi
	if(pgdir[pdeIndex] == 0 && create == 0)
f0101143:	c1 e7 02             	shl    $0x2,%edi
f0101146:	03 7d 08             	add    0x8(%ebp),%edi
f0101149:	8b 07                	mov    (%edi),%eax
f010114b:	89 c2                	mov    %eax,%edx
f010114d:	0b 55 10             	or     0x10(%ebp),%edx
f0101150:	74 76                	je     f01011c8 <pgdir_walk+0xa1>
	if(pgdir[pdeIndex] == 0){
f0101152:	85 c0                	test   %eax,%eax
f0101154:	74 2e                	je     f0101184 <pgdir_walk+0x5d>
	pte_t pgAdd = pgdir[pdeIndex];
f0101156:	8b 07                	mov    (%edi),%eax
	int pteIndex =(pte_t)va >>12 & 0x3ff;
f0101158:	c1 ee 0a             	shr    $0xa,%esi
	pte_t * pte =(pte_t*) pgAdd + pteIndex;
f010115b:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
	pgAdd = pgAdd>>12<<12;
f0101161:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	pte_t * pte =(pte_t*) pgAdd + pteIndex;
f0101166:	01 f0                	add    %esi,%eax
	if (PGNUM(pa) >= npages)
f0101168:	89 c1                	mov    %eax,%ecx
f010116a:	c1 e9 0c             	shr    $0xc,%ecx
f010116d:	c7 c2 e8 ff 18 f0    	mov    $0xf018ffe8,%edx
f0101173:	3b 0a                	cmp    (%edx),%ecx
f0101175:	73 38                	jae    f01011af <pgdir_walk+0x88>
	return (void *)(pa + KERNBASE);
f0101177:	2d 00 00 00 10       	sub    $0x10000000,%eax
}
f010117c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010117f:	5b                   	pop    %ebx
f0101180:	5e                   	pop    %esi
f0101181:	5f                   	pop    %edi
f0101182:	5d                   	pop    %ebp
f0101183:	c3                   	ret    
		struct PageInfo* page = page_alloc(1);
f0101184:	83 ec 0c             	sub    $0xc,%esp
f0101187:	6a 01                	push   $0x1
f0101189:	e8 99 fe ff ff       	call   f0101027 <page_alloc>
		if(page == NULL)
f010118e:	83 c4 10             	add    $0x10,%esp
f0101191:	85 c0                	test   %eax,%eax
f0101193:	74 3a                	je     f01011cf <pgdir_walk+0xa8>
		page->pp_ref++;
f0101195:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
	return (pp - pages) << PGSHIFT;
f010119a:	c7 c2 f0 ff 18 f0    	mov    $0xf018fff0,%edx
f01011a0:	2b 02                	sub    (%edx),%eax
f01011a2:	c1 f8 03             	sar    $0x3,%eax
f01011a5:	c1 e0 0c             	shl    $0xc,%eax
		pgAddress |= PTE_W;
f01011a8:	83 c8 07             	or     $0x7,%eax
f01011ab:	89 07                	mov    %eax,(%edi)
f01011ad:	eb a7                	jmp    f0101156 <pgdir_walk+0x2f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01011af:	50                   	push   %eax
f01011b0:	8d 83 64 89 f7 ff    	lea    -0x8769c(%ebx),%eax
f01011b6:	50                   	push   %eax
f01011b7:	68 9e 01 00 00       	push   $0x19e
f01011bc:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01011c2:	50                   	push   %eax
f01011c3:	e8 e9 ee ff ff       	call   f01000b1 <_panic>
		return NULL;
f01011c8:	b8 00 00 00 00       	mov    $0x0,%eax
f01011cd:	eb ad                	jmp    f010117c <pgdir_walk+0x55>
			return NULL;
f01011cf:	b8 00 00 00 00       	mov    $0x0,%eax
f01011d4:	eb a6                	jmp    f010117c <pgdir_walk+0x55>

f01011d6 <boot_map_region>:
{
f01011d6:	55                   	push   %ebp
f01011d7:	89 e5                	mov    %esp,%ebp
f01011d9:	57                   	push   %edi
f01011da:	56                   	push   %esi
f01011db:	53                   	push   %ebx
f01011dc:	83 ec 1c             	sub    $0x1c,%esp
f01011df:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01011e2:	89 ce                	mov    %ecx,%esi
f01011e4:	8b 45 08             	mov    0x8(%ebp),%eax
	while(size)
f01011e7:	89 c3                	mov    %eax,%ebx
		pte_t* pte = pgdir_walk(pgdir, (void* )va, 1);
f01011e9:	89 d7                	mov    %edx,%edi
f01011eb:	29 c7                	sub    %eax,%edi
		*pte= pa |perm|PTE_P;
f01011ed:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011f0:	83 c8 01             	or     $0x1,%eax
f01011f3:	89 45 e0             	mov    %eax,-0x20(%ebp)
	while(size)
f01011f6:	85 f6                	test   %esi,%esi
f01011f8:	74 2d                	je     f0101227 <boot_map_region+0x51>
		pte_t* pte = pgdir_walk(pgdir, (void* )va, 1);
f01011fa:	83 ec 04             	sub    $0x4,%esp
f01011fd:	6a 01                	push   $0x1
f01011ff:	8d 04 1f             	lea    (%edi,%ebx,1),%eax
f0101202:	50                   	push   %eax
f0101203:	ff 75 e4             	pushl  -0x1c(%ebp)
f0101206:	e8 1c ff ff ff       	call   f0101127 <pgdir_walk>
		if(pte == NULL)
f010120b:	83 c4 10             	add    $0x10,%esp
f010120e:	85 c0                	test   %eax,%eax
f0101210:	74 15                	je     f0101227 <boot_map_region+0x51>
		*pte= pa |perm|PTE_P;
f0101212:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0101215:	09 da                	or     %ebx,%edx
f0101217:	89 10                	mov    %edx,(%eax)
		size -= PGSIZE;
f0101219:	81 ee 00 10 00 00    	sub    $0x1000,%esi
		pa  += PGSIZE;
f010121f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101225:	eb cf                	jmp    f01011f6 <boot_map_region+0x20>
}
f0101227:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010122a:	5b                   	pop    %ebx
f010122b:	5e                   	pop    %esi
f010122c:	5f                   	pop    %edi
f010122d:	5d                   	pop    %ebp
f010122e:	c3                   	ret    

f010122f <page_lookup>:
{
f010122f:	55                   	push   %ebp
f0101230:	89 e5                	mov    %esp,%ebp
f0101232:	56                   	push   %esi
f0101233:	53                   	push   %ebx
f0101234:	e8 2e ef ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0101239:	81 c3 e7 bd 08 00    	add    $0x8bde7,%ebx
f010123f:	8b 75 10             	mov    0x10(%ebp),%esi
	pte_t* pte = pgdir_walk(pgdir, va, 0);
f0101242:	83 ec 04             	sub    $0x4,%esp
f0101245:	6a 00                	push   $0x0
f0101247:	ff 75 0c             	pushl  0xc(%ebp)
f010124a:	ff 75 08             	pushl  0x8(%ebp)
f010124d:	e8 d5 fe ff ff       	call   f0101127 <pgdir_walk>
	if(pte == NULL)
f0101252:	83 c4 10             	add    $0x10,%esp
f0101255:	85 c0                	test   %eax,%eax
f0101257:	74 41                	je     f010129a <page_lookup+0x6b>
	pte_t pa =  *pte>>12<<12;
f0101259:	8b 10                	mov    (%eax),%edx
	if(pte_store != 0)
f010125b:	85 f6                	test   %esi,%esi
f010125d:	74 02                	je     f0101261 <page_lookup+0x32>
		*pte_store = pte ;
f010125f:	89 06                	mov    %eax,(%esi)
f0101261:	89 d0                	mov    %edx,%eax
f0101263:	c1 e8 0c             	shr    $0xc,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101266:	c7 c2 e8 ff 18 f0    	mov    $0xf018ffe8,%edx
f010126c:	39 02                	cmp    %eax,(%edx)
f010126e:	76 12                	jbe    f0101282 <page_lookup+0x53>
		panic("pa2page called with invalid pa");
	return &pages[PGNUM(pa)];
f0101270:	c7 c2 f0 ff 18 f0    	mov    $0xf018fff0,%edx
f0101276:	8b 12                	mov    (%edx),%edx
f0101278:	8d 04 c2             	lea    (%edx,%eax,8),%eax
}
f010127b:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010127e:	5b                   	pop    %ebx
f010127f:	5e                   	pop    %esi
f0101280:	5d                   	pop    %ebp
f0101281:	c3                   	ret    
		panic("pa2page called with invalid pa");
f0101282:	83 ec 04             	sub    $0x4,%esp
f0101285:	8d 83 70 8a f7 ff    	lea    -0x87590(%ebx),%eax
f010128b:	50                   	push   %eax
f010128c:	6a 4f                	push   $0x4f
f010128e:	8d 83 99 91 f7 ff    	lea    -0x86e67(%ebx),%eax
f0101294:	50                   	push   %eax
f0101295:	e8 17 ee ff ff       	call   f01000b1 <_panic>
		return NULL;
f010129a:	b8 00 00 00 00       	mov    $0x0,%eax
f010129f:	eb da                	jmp    f010127b <page_lookup+0x4c>

f01012a1 <page_remove>:
{
f01012a1:	55                   	push   %ebp
f01012a2:	89 e5                	mov    %esp,%ebp
f01012a4:	53                   	push   %ebx
f01012a5:	83 ec 18             	sub    $0x18,%esp
f01012a8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	struct PageInfo* page = page_lookup(pgdir, va, &pte);
f01012ab:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01012ae:	50                   	push   %eax
f01012af:	53                   	push   %ebx
f01012b0:	ff 75 08             	pushl  0x8(%ebp)
f01012b3:	e8 77 ff ff ff       	call   f010122f <page_lookup>
	if(page == 0)
f01012b8:	83 c4 10             	add    $0x10,%esp
f01012bb:	85 c0                	test   %eax,%eax
f01012bd:	74 1c                	je     f01012db <page_remove+0x3a>
	*pte = 0;
f01012bf:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01012c2:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
	page->pp_ref--;
f01012c8:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f01012cc:	8d 51 ff             	lea    -0x1(%ecx),%edx
f01012cf:	66 89 50 04          	mov    %dx,0x4(%eax)
	if(page->pp_ref ==0)
f01012d3:	66 85 d2             	test   %dx,%dx
f01012d6:	74 08                	je     f01012e0 <page_remove+0x3f>
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01012d8:	0f 01 3b             	invlpg (%ebx)
}
f01012db:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01012de:	c9                   	leave  
f01012df:	c3                   	ret    
		page_free(page);
f01012e0:	83 ec 0c             	sub    $0xc,%esp
f01012e3:	50                   	push   %eax
f01012e4:	e8 c6 fd ff ff       	call   f01010af <page_free>
f01012e9:	83 c4 10             	add    $0x10,%esp
f01012ec:	eb ea                	jmp    f01012d8 <page_remove+0x37>

f01012ee <page_insert>:
{
f01012ee:	55                   	push   %ebp
f01012ef:	89 e5                	mov    %esp,%ebp
f01012f1:	57                   	push   %edi
f01012f2:	56                   	push   %esi
f01012f3:	53                   	push   %ebx
f01012f4:	83 ec 20             	sub    $0x20,%esp
f01012f7:	e8 3e 20 00 00       	call   f010333a <__x86.get_pc_thunk.di>
f01012fc:	81 c7 24 bd 08 00    	add    $0x8bd24,%edi
f0101302:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	pte_t* pte = pgdir_walk(pgdir, va, 1);
f0101305:	6a 01                	push   $0x1
f0101307:	ff 75 10             	pushl  0x10(%ebp)
f010130a:	ff 75 08             	pushl  0x8(%ebp)
f010130d:	e8 15 fe ff ff       	call   f0101127 <pgdir_walk>
	if(pte == NULL)
f0101312:	83 c4 10             	add    $0x10,%esp
f0101315:	85 c0                	test   %eax,%eax
f0101317:	74 72                	je     f010138b <page_insert+0x9d>
f0101319:	89 c6                	mov    %eax,%esi
	if( (pte[0] &  ~0xfff) == page2pa(pp))
f010131b:	8b 10                	mov    (%eax),%edx
f010131d:	89 d1                	mov    %edx,%ecx
f010131f:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0101325:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	return (pp - pages) << PGSHIFT;
f0101328:	c7 c0 f0 ff 18 f0    	mov    $0xf018fff0,%eax
f010132e:	89 d9                	mov    %ebx,%ecx
f0101330:	2b 08                	sub    (%eax),%ecx
f0101332:	89 c8                	mov    %ecx,%eax
f0101334:	c1 f8 03             	sar    $0x3,%eax
f0101337:	c1 e0 0c             	shl    $0xc,%eax
f010133a:	39 45 e4             	cmp    %eax,-0x1c(%ebp)
f010133d:	74 32                	je     f0101371 <page_insert+0x83>
	else if(*pte != 0)
f010133f:	85 d2                	test   %edx,%edx
f0101341:	75 35                	jne    f0101378 <page_insert+0x8a>
f0101343:	c7 c0 f0 ff 18 f0    	mov    $0xf018fff0,%eax
f0101349:	89 df                	mov    %ebx,%edi
f010134b:	2b 38                	sub    (%eax),%edi
f010134d:	89 f8                	mov    %edi,%eax
f010134f:	c1 f8 03             	sar    $0x3,%eax
f0101352:	c1 e0 0c             	shl    $0xc,%eax
	*pte = (page2pa(pp) & ~0xfff) | perm | PTE_P;
f0101355:	8b 55 14             	mov    0x14(%ebp),%edx
f0101358:	83 ca 01             	or     $0x1,%edx
f010135b:	09 d0                	or     %edx,%eax
f010135d:	89 06                	mov    %eax,(%esi)
	pp->pp_ref++;
f010135f:	66 83 43 04 01       	addw   $0x1,0x4(%ebx)
	return 0;
f0101364:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101369:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010136c:	5b                   	pop    %ebx
f010136d:	5e                   	pop    %esi
f010136e:	5f                   	pop    %edi
f010136f:	5d                   	pop    %ebp
f0101370:	c3                   	ret    
		pp->pp_ref--;
f0101371:	66 83 6b 04 01       	subw   $0x1,0x4(%ebx)
f0101376:	eb cb                	jmp    f0101343 <page_insert+0x55>
		page_remove(pgdir, va);
f0101378:	83 ec 08             	sub    $0x8,%esp
f010137b:	ff 75 10             	pushl  0x10(%ebp)
f010137e:	ff 75 08             	pushl  0x8(%ebp)
f0101381:	e8 1b ff ff ff       	call   f01012a1 <page_remove>
f0101386:	83 c4 10             	add    $0x10,%esp
f0101389:	eb b8                	jmp    f0101343 <page_insert+0x55>
		return -E_NO_MEM;
f010138b:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0101390:	eb d7                	jmp    f0101369 <page_insert+0x7b>

f0101392 <mem_init>:
{
f0101392:	55                   	push   %ebp
f0101393:	89 e5                	mov    %esp,%ebp
f0101395:	57                   	push   %edi
f0101396:	56                   	push   %esi
f0101397:	53                   	push   %ebx
f0101398:	83 ec 3c             	sub    $0x3c,%esp
f010139b:	e8 69 f3 ff ff       	call   f0100709 <__x86.get_pc_thunk.ax>
f01013a0:	05 80 bc 08 00       	add    $0x8bc80,%eax
f01013a5:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	basemem = nvram_read(NVRAM_BASELO);
f01013a8:	b8 15 00 00 00       	mov    $0x15,%eax
f01013ad:	e8 2c f7 ff ff       	call   f0100ade <nvram_read>
f01013b2:	89 c3                	mov    %eax,%ebx
	extmem = nvram_read(NVRAM_EXTLO);
f01013b4:	b8 17 00 00 00       	mov    $0x17,%eax
f01013b9:	e8 20 f7 ff ff       	call   f0100ade <nvram_read>
f01013be:	89 c6                	mov    %eax,%esi
	ext16mem = nvram_read(NVRAM_EXT16LO) * 64;
f01013c0:	b8 34 00 00 00       	mov    $0x34,%eax
f01013c5:	e8 14 f7 ff ff       	call   f0100ade <nvram_read>
f01013ca:	c1 e0 06             	shl    $0x6,%eax
	if (ext16mem)
f01013cd:	85 c0                	test   %eax,%eax
f01013cf:	0f 85 f3 00 00 00    	jne    f01014c8 <mem_init+0x136>
		totalmem = 1 * 1024 + extmem;
f01013d5:	8d 86 00 04 00 00    	lea    0x400(%esi),%eax
f01013db:	85 f6                	test   %esi,%esi
f01013dd:	0f 44 c3             	cmove  %ebx,%eax
	npages = totalmem / (PGSIZE / 1024);
f01013e0:	89 c1                	mov    %eax,%ecx
f01013e2:	c1 e9 02             	shr    $0x2,%ecx
f01013e5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01013e8:	c7 c2 e8 ff 18 f0    	mov    $0xf018ffe8,%edx
f01013ee:	89 0a                	mov    %ecx,(%edx)
	npages_basemem = basemem / (PGSIZE / 1024);
f01013f0:	89 da                	mov    %ebx,%edx
f01013f2:	c1 ea 02             	shr    $0x2,%edx
f01013f5:	89 97 04 23 00 00    	mov    %edx,0x2304(%edi)
	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01013fb:	89 c2                	mov    %eax,%edx
f01013fd:	29 da                	sub    %ebx,%edx
f01013ff:	52                   	push   %edx
f0101400:	53                   	push   %ebx
f0101401:	50                   	push   %eax
f0101402:	8d 87 90 8a f7 ff    	lea    -0x87570(%edi),%eax
f0101408:	50                   	push   %eax
f0101409:	89 fb                	mov    %edi,%ebx
f010140b:	e8 48 27 00 00       	call   f0103b58 <cprintf>
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101410:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101415:	e8 6b f6 ff ff       	call   f0100a85 <boot_alloc>
f010141a:	c7 c6 ec ff 18 f0    	mov    $0xf018ffec,%esi
f0101420:	89 06                	mov    %eax,(%esi)
	memset(kern_pgdir, 0, PGSIZE);
f0101422:	83 c4 0c             	add    $0xc,%esp
f0101425:	68 00 10 00 00       	push   $0x1000
f010142a:	6a 00                	push   $0x0
f010142c:	50                   	push   %eax
f010142d:	e8 63 3c 00 00       	call   f0105095 <memset>
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101432:	8b 06                	mov    (%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f0101434:	83 c4 10             	add    $0x10,%esp
f0101437:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010143c:	0f 86 90 00 00 00    	jbe    f01014d2 <mem_init+0x140>
	return (physaddr_t)kva - KERNBASE;
f0101442:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101448:	83 ca 05             	or     $0x5,%edx
f010144b:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	pages = boot_alloc(npages * sizeof (struct PageInfo));
f0101451:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101454:	c7 c3 e8 ff 18 f0    	mov    $0xf018ffe8,%ebx
f010145a:	8b 03                	mov    (%ebx),%eax
f010145c:	c1 e0 03             	shl    $0x3,%eax
f010145f:	e8 21 f6 ff ff       	call   f0100a85 <boot_alloc>
f0101464:	c7 c6 f0 ff 18 f0    	mov    $0xf018fff0,%esi
f010146a:	89 06                	mov    %eax,(%esi)
	memset(pages, 0, npages*sizeof(struct PageInfo));
f010146c:	83 ec 04             	sub    $0x4,%esp
f010146f:	8b 13                	mov    (%ebx),%edx
f0101471:	c1 e2 03             	shl    $0x3,%edx
f0101474:	52                   	push   %edx
f0101475:	6a 00                	push   $0x0
f0101477:	50                   	push   %eax
f0101478:	89 fb                	mov    %edi,%ebx
f010147a:	e8 16 3c 00 00       	call   f0105095 <memset>
	envs = (struct Env*)boot_alloc(NENV*sizeof(struct Env));
f010147f:	b8 00 80 01 00       	mov    $0x18000,%eax
f0101484:	e8 fc f5 ff ff       	call   f0100a85 <boot_alloc>
f0101489:	c7 c2 2c f3 18 f0    	mov    $0xf018f32c,%edx
f010148f:	89 02                	mov    %eax,(%edx)
	memset(envs, 0, NENV * sizeof(struct Env));
f0101491:	83 c4 0c             	add    $0xc,%esp
f0101494:	68 00 80 01 00       	push   $0x18000
f0101499:	6a 00                	push   $0x0
f010149b:	50                   	push   %eax
f010149c:	e8 f4 3b 00 00       	call   f0105095 <memset>
	page_init();
f01014a1:	e8 6e fa ff ff       	call   f0100f14 <page_init>
	check_page_free_list(1);
f01014a6:	b8 01 00 00 00       	mov    $0x1,%eax
f01014ab:	e8 e1 f6 ff ff       	call   f0100b91 <check_page_free_list>
	if (!pages)
f01014b0:	83 c4 10             	add    $0x10,%esp
f01014b3:	83 3e 00             	cmpl   $0x0,(%esi)
f01014b6:	74 36                	je     f01014ee <mem_init+0x15c>
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01014b8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01014bb:	8b 80 00 23 00 00    	mov    0x2300(%eax),%eax
f01014c1:	be 00 00 00 00       	mov    $0x0,%esi
f01014c6:	eb 49                	jmp    f0101511 <mem_init+0x17f>
		totalmem = 16 * 1024 + ext16mem;
f01014c8:	05 00 40 00 00       	add    $0x4000,%eax
f01014cd:	e9 0e ff ff ff       	jmp    f01013e0 <mem_init+0x4e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01014d2:	50                   	push   %eax
f01014d3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01014d6:	8d 83 cc 8a f7 ff    	lea    -0x87534(%ebx),%eax
f01014dc:	50                   	push   %eax
f01014dd:	68 92 00 00 00       	push   $0x92
f01014e2:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01014e8:	50                   	push   %eax
f01014e9:	e8 c3 eb ff ff       	call   f01000b1 <_panic>
		panic("'pages' is a null pointer!");
f01014ee:	83 ec 04             	sub    $0x4,%esp
f01014f1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01014f4:	8d 83 5a 92 f7 ff    	lea    -0x86da6(%ebx),%eax
f01014fa:	50                   	push   %eax
f01014fb:	68 b1 02 00 00       	push   $0x2b1
f0101500:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0101506:	50                   	push   %eax
f0101507:	e8 a5 eb ff ff       	call   f01000b1 <_panic>
		++nfree;
f010150c:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010150f:	8b 00                	mov    (%eax),%eax
f0101511:	85 c0                	test   %eax,%eax
f0101513:	75 f7                	jne    f010150c <mem_init+0x17a>
	assert((pp0 = page_alloc(0)));
f0101515:	83 ec 0c             	sub    $0xc,%esp
f0101518:	6a 00                	push   $0x0
f010151a:	e8 08 fb ff ff       	call   f0101027 <page_alloc>
f010151f:	89 c3                	mov    %eax,%ebx
f0101521:	83 c4 10             	add    $0x10,%esp
f0101524:	85 c0                	test   %eax,%eax
f0101526:	0f 84 3b 02 00 00    	je     f0101767 <mem_init+0x3d5>
	assert((pp1 = page_alloc(0)));
f010152c:	83 ec 0c             	sub    $0xc,%esp
f010152f:	6a 00                	push   $0x0
f0101531:	e8 f1 fa ff ff       	call   f0101027 <page_alloc>
f0101536:	89 c7                	mov    %eax,%edi
f0101538:	83 c4 10             	add    $0x10,%esp
f010153b:	85 c0                	test   %eax,%eax
f010153d:	0f 84 46 02 00 00    	je     f0101789 <mem_init+0x3f7>
	assert((pp2 = page_alloc(0)));
f0101543:	83 ec 0c             	sub    $0xc,%esp
f0101546:	6a 00                	push   $0x0
f0101548:	e8 da fa ff ff       	call   f0101027 <page_alloc>
f010154d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101550:	83 c4 10             	add    $0x10,%esp
f0101553:	85 c0                	test   %eax,%eax
f0101555:	0f 84 50 02 00 00    	je     f01017ab <mem_init+0x419>
	assert(pp1 && pp1 != pp0);
f010155b:	39 fb                	cmp    %edi,%ebx
f010155d:	0f 84 6a 02 00 00    	je     f01017cd <mem_init+0x43b>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101563:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101566:	39 c7                	cmp    %eax,%edi
f0101568:	0f 84 81 02 00 00    	je     f01017ef <mem_init+0x45d>
f010156e:	39 c3                	cmp    %eax,%ebx
f0101570:	0f 84 79 02 00 00    	je     f01017ef <mem_init+0x45d>
	return (pp - pages) << PGSHIFT;
f0101576:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101579:	c7 c0 f0 ff 18 f0    	mov    $0xf018fff0,%eax
f010157f:	8b 08                	mov    (%eax),%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101581:	c7 c0 e8 ff 18 f0    	mov    $0xf018ffe8,%eax
f0101587:	8b 10                	mov    (%eax),%edx
f0101589:	c1 e2 0c             	shl    $0xc,%edx
f010158c:	89 d8                	mov    %ebx,%eax
f010158e:	29 c8                	sub    %ecx,%eax
f0101590:	c1 f8 03             	sar    $0x3,%eax
f0101593:	c1 e0 0c             	shl    $0xc,%eax
f0101596:	39 d0                	cmp    %edx,%eax
f0101598:	0f 83 73 02 00 00    	jae    f0101811 <mem_init+0x47f>
f010159e:	89 f8                	mov    %edi,%eax
f01015a0:	29 c8                	sub    %ecx,%eax
f01015a2:	c1 f8 03             	sar    $0x3,%eax
f01015a5:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f01015a8:	39 c2                	cmp    %eax,%edx
f01015aa:	0f 86 83 02 00 00    	jbe    f0101833 <mem_init+0x4a1>
f01015b0:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01015b3:	29 c8                	sub    %ecx,%eax
f01015b5:	c1 f8 03             	sar    $0x3,%eax
f01015b8:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f01015bb:	39 c2                	cmp    %eax,%edx
f01015bd:	0f 86 92 02 00 00    	jbe    f0101855 <mem_init+0x4c3>
	fl = page_free_list;
f01015c3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015c6:	8b 88 00 23 00 00    	mov    0x2300(%eax),%ecx
f01015cc:	89 4d c8             	mov    %ecx,-0x38(%ebp)
	page_free_list = 0;
f01015cf:	c7 80 00 23 00 00 00 	movl   $0x0,0x2300(%eax)
f01015d6:	00 00 00 
	assert(!page_alloc(0));
f01015d9:	83 ec 0c             	sub    $0xc,%esp
f01015dc:	6a 00                	push   $0x0
f01015de:	e8 44 fa ff ff       	call   f0101027 <page_alloc>
f01015e3:	83 c4 10             	add    $0x10,%esp
f01015e6:	85 c0                	test   %eax,%eax
f01015e8:	0f 85 89 02 00 00    	jne    f0101877 <mem_init+0x4e5>
	page_free(pp0);
f01015ee:	83 ec 0c             	sub    $0xc,%esp
f01015f1:	53                   	push   %ebx
f01015f2:	e8 b8 fa ff ff       	call   f01010af <page_free>
	page_free(pp1);
f01015f7:	89 3c 24             	mov    %edi,(%esp)
f01015fa:	e8 b0 fa ff ff       	call   f01010af <page_free>
	page_free(pp2);
f01015ff:	83 c4 04             	add    $0x4,%esp
f0101602:	ff 75 d0             	pushl  -0x30(%ebp)
f0101605:	e8 a5 fa ff ff       	call   f01010af <page_free>
	assert((pp0 = page_alloc(0)));
f010160a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101611:	e8 11 fa ff ff       	call   f0101027 <page_alloc>
f0101616:	89 c7                	mov    %eax,%edi
f0101618:	83 c4 10             	add    $0x10,%esp
f010161b:	85 c0                	test   %eax,%eax
f010161d:	0f 84 76 02 00 00    	je     f0101899 <mem_init+0x507>
	assert((pp1 = page_alloc(0)));
f0101623:	83 ec 0c             	sub    $0xc,%esp
f0101626:	6a 00                	push   $0x0
f0101628:	e8 fa f9 ff ff       	call   f0101027 <page_alloc>
f010162d:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101630:	83 c4 10             	add    $0x10,%esp
f0101633:	85 c0                	test   %eax,%eax
f0101635:	0f 84 80 02 00 00    	je     f01018bb <mem_init+0x529>
	assert((pp2 = page_alloc(0)));
f010163b:	83 ec 0c             	sub    $0xc,%esp
f010163e:	6a 00                	push   $0x0
f0101640:	e8 e2 f9 ff ff       	call   f0101027 <page_alloc>
f0101645:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101648:	83 c4 10             	add    $0x10,%esp
f010164b:	85 c0                	test   %eax,%eax
f010164d:	0f 84 8a 02 00 00    	je     f01018dd <mem_init+0x54b>
	assert(pp1 && pp1 != pp0);
f0101653:	3b 7d d0             	cmp    -0x30(%ebp),%edi
f0101656:	0f 84 a3 02 00 00    	je     f01018ff <mem_init+0x56d>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010165c:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010165f:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101662:	0f 84 b9 02 00 00    	je     f0101921 <mem_init+0x58f>
f0101668:	39 c7                	cmp    %eax,%edi
f010166a:	0f 84 b1 02 00 00    	je     f0101921 <mem_init+0x58f>
	assert(!page_alloc(0));
f0101670:	83 ec 0c             	sub    $0xc,%esp
f0101673:	6a 00                	push   $0x0
f0101675:	e8 ad f9 ff ff       	call   f0101027 <page_alloc>
f010167a:	83 c4 10             	add    $0x10,%esp
f010167d:	85 c0                	test   %eax,%eax
f010167f:	0f 85 be 02 00 00    	jne    f0101943 <mem_init+0x5b1>
f0101685:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101688:	c7 c0 f0 ff 18 f0    	mov    $0xf018fff0,%eax
f010168e:	89 f9                	mov    %edi,%ecx
f0101690:	2b 08                	sub    (%eax),%ecx
f0101692:	89 c8                	mov    %ecx,%eax
f0101694:	c1 f8 03             	sar    $0x3,%eax
f0101697:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f010169a:	89 c1                	mov    %eax,%ecx
f010169c:	c1 e9 0c             	shr    $0xc,%ecx
f010169f:	c7 c2 e8 ff 18 f0    	mov    $0xf018ffe8,%edx
f01016a5:	3b 0a                	cmp    (%edx),%ecx
f01016a7:	0f 83 b8 02 00 00    	jae    f0101965 <mem_init+0x5d3>
	memset(page2kva(pp0), 1, PGSIZE);
f01016ad:	83 ec 04             	sub    $0x4,%esp
f01016b0:	68 00 10 00 00       	push   $0x1000
f01016b5:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f01016b7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01016bc:	50                   	push   %eax
f01016bd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01016c0:	e8 d0 39 00 00       	call   f0105095 <memset>
	page_free(pp0);
f01016c5:	89 3c 24             	mov    %edi,(%esp)
f01016c8:	e8 e2 f9 ff ff       	call   f01010af <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01016cd:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01016d4:	e8 4e f9 ff ff       	call   f0101027 <page_alloc>
f01016d9:	83 c4 10             	add    $0x10,%esp
f01016dc:	85 c0                	test   %eax,%eax
f01016de:	0f 84 97 02 00 00    	je     f010197b <mem_init+0x5e9>
	assert(pp && pp0 == pp);
f01016e4:	39 c7                	cmp    %eax,%edi
f01016e6:	0f 85 b1 02 00 00    	jne    f010199d <mem_init+0x60b>
	return (pp - pages) << PGSHIFT;
f01016ec:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01016ef:	c7 c0 f0 ff 18 f0    	mov    $0xf018fff0,%eax
f01016f5:	89 fa                	mov    %edi,%edx
f01016f7:	2b 10                	sub    (%eax),%edx
f01016f9:	c1 fa 03             	sar    $0x3,%edx
f01016fc:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01016ff:	89 d1                	mov    %edx,%ecx
f0101701:	c1 e9 0c             	shr    $0xc,%ecx
f0101704:	c7 c0 e8 ff 18 f0    	mov    $0xf018ffe8,%eax
f010170a:	3b 08                	cmp    (%eax),%ecx
f010170c:	0f 83 ad 02 00 00    	jae    f01019bf <mem_init+0x62d>
	return (void *)(pa + KERNBASE);
f0101712:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
f0101718:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
		assert(c[i] == 0);
f010171e:	80 38 00             	cmpb   $0x0,(%eax)
f0101721:	0f 85 ae 02 00 00    	jne    f01019d5 <mem_init+0x643>
f0101727:	83 c0 01             	add    $0x1,%eax
	for (i = 0; i < PGSIZE; i++)
f010172a:	39 d0                	cmp    %edx,%eax
f010172c:	75 f0                	jne    f010171e <mem_init+0x38c>
	page_free_list = fl;
f010172e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101731:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0101734:	89 8b 00 23 00 00    	mov    %ecx,0x2300(%ebx)
	page_free(pp0);
f010173a:	83 ec 0c             	sub    $0xc,%esp
f010173d:	57                   	push   %edi
f010173e:	e8 6c f9 ff ff       	call   f01010af <page_free>
	page_free(pp1);
f0101743:	83 c4 04             	add    $0x4,%esp
f0101746:	ff 75 d0             	pushl  -0x30(%ebp)
f0101749:	e8 61 f9 ff ff       	call   f01010af <page_free>
	page_free(pp2);
f010174e:	83 c4 04             	add    $0x4,%esp
f0101751:	ff 75 cc             	pushl  -0x34(%ebp)
f0101754:	e8 56 f9 ff ff       	call   f01010af <page_free>
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101759:	8b 83 00 23 00 00    	mov    0x2300(%ebx),%eax
f010175f:	83 c4 10             	add    $0x10,%esp
f0101762:	e9 95 02 00 00       	jmp    f01019fc <mem_init+0x66a>
	assert((pp0 = page_alloc(0)));
f0101767:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010176a:	8d 83 75 92 f7 ff    	lea    -0x86d8b(%ebx),%eax
f0101770:	50                   	push   %eax
f0101771:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0101777:	50                   	push   %eax
f0101778:	68 b9 02 00 00       	push   $0x2b9
f010177d:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0101783:	50                   	push   %eax
f0101784:	e8 28 e9 ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f0101789:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010178c:	8d 83 8b 92 f7 ff    	lea    -0x86d75(%ebx),%eax
f0101792:	50                   	push   %eax
f0101793:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0101799:	50                   	push   %eax
f010179a:	68 ba 02 00 00       	push   $0x2ba
f010179f:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01017a5:	50                   	push   %eax
f01017a6:	e8 06 e9 ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f01017ab:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017ae:	8d 83 a1 92 f7 ff    	lea    -0x86d5f(%ebx),%eax
f01017b4:	50                   	push   %eax
f01017b5:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01017bb:	50                   	push   %eax
f01017bc:	68 bb 02 00 00       	push   $0x2bb
f01017c1:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01017c7:	50                   	push   %eax
f01017c8:	e8 e4 e8 ff ff       	call   f01000b1 <_panic>
	assert(pp1 && pp1 != pp0);
f01017cd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017d0:	8d 83 b7 92 f7 ff    	lea    -0x86d49(%ebx),%eax
f01017d6:	50                   	push   %eax
f01017d7:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01017dd:	50                   	push   %eax
f01017de:	68 be 02 00 00       	push   $0x2be
f01017e3:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01017e9:	50                   	push   %eax
f01017ea:	e8 c2 e8 ff ff       	call   f01000b1 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01017ef:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01017f2:	8d 83 f0 8a f7 ff    	lea    -0x87510(%ebx),%eax
f01017f8:	50                   	push   %eax
f01017f9:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01017ff:	50                   	push   %eax
f0101800:	68 bf 02 00 00       	push   $0x2bf
f0101805:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f010180b:	50                   	push   %eax
f010180c:	e8 a0 e8 ff ff       	call   f01000b1 <_panic>
	assert(page2pa(pp0) < npages*PGSIZE);
f0101811:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101814:	8d 83 c9 92 f7 ff    	lea    -0x86d37(%ebx),%eax
f010181a:	50                   	push   %eax
f010181b:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0101821:	50                   	push   %eax
f0101822:	68 c0 02 00 00       	push   $0x2c0
f0101827:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f010182d:	50                   	push   %eax
f010182e:	e8 7e e8 ff ff       	call   f01000b1 <_panic>
	assert(page2pa(pp1) < npages*PGSIZE);
f0101833:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101836:	8d 83 e6 92 f7 ff    	lea    -0x86d1a(%ebx),%eax
f010183c:	50                   	push   %eax
f010183d:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0101843:	50                   	push   %eax
f0101844:	68 c1 02 00 00       	push   $0x2c1
f0101849:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f010184f:	50                   	push   %eax
f0101850:	e8 5c e8 ff ff       	call   f01000b1 <_panic>
	assert(page2pa(pp2) < npages*PGSIZE);
f0101855:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101858:	8d 83 03 93 f7 ff    	lea    -0x86cfd(%ebx),%eax
f010185e:	50                   	push   %eax
f010185f:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0101865:	50                   	push   %eax
f0101866:	68 c2 02 00 00       	push   $0x2c2
f010186b:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0101871:	50                   	push   %eax
f0101872:	e8 3a e8 ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f0101877:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010187a:	8d 83 20 93 f7 ff    	lea    -0x86ce0(%ebx),%eax
f0101880:	50                   	push   %eax
f0101881:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0101887:	50                   	push   %eax
f0101888:	68 c9 02 00 00       	push   $0x2c9
f010188d:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0101893:	50                   	push   %eax
f0101894:	e8 18 e8 ff ff       	call   f01000b1 <_panic>
	assert((pp0 = page_alloc(0)));
f0101899:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010189c:	8d 83 75 92 f7 ff    	lea    -0x86d8b(%ebx),%eax
f01018a2:	50                   	push   %eax
f01018a3:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01018a9:	50                   	push   %eax
f01018aa:	68 d0 02 00 00       	push   $0x2d0
f01018af:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01018b5:	50                   	push   %eax
f01018b6:	e8 f6 e7 ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f01018bb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018be:	8d 83 8b 92 f7 ff    	lea    -0x86d75(%ebx),%eax
f01018c4:	50                   	push   %eax
f01018c5:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01018cb:	50                   	push   %eax
f01018cc:	68 d1 02 00 00       	push   $0x2d1
f01018d1:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01018d7:	50                   	push   %eax
f01018d8:	e8 d4 e7 ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f01018dd:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01018e0:	8d 83 a1 92 f7 ff    	lea    -0x86d5f(%ebx),%eax
f01018e6:	50                   	push   %eax
f01018e7:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01018ed:	50                   	push   %eax
f01018ee:	68 d2 02 00 00       	push   $0x2d2
f01018f3:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01018f9:	50                   	push   %eax
f01018fa:	e8 b2 e7 ff ff       	call   f01000b1 <_panic>
	assert(pp1 && pp1 != pp0);
f01018ff:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101902:	8d 83 b7 92 f7 ff    	lea    -0x86d49(%ebx),%eax
f0101908:	50                   	push   %eax
f0101909:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f010190f:	50                   	push   %eax
f0101910:	68 d4 02 00 00       	push   $0x2d4
f0101915:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f010191b:	50                   	push   %eax
f010191c:	e8 90 e7 ff ff       	call   f01000b1 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101921:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101924:	8d 83 f0 8a f7 ff    	lea    -0x87510(%ebx),%eax
f010192a:	50                   	push   %eax
f010192b:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0101931:	50                   	push   %eax
f0101932:	68 d5 02 00 00       	push   $0x2d5
f0101937:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f010193d:	50                   	push   %eax
f010193e:	e8 6e e7 ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f0101943:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101946:	8d 83 20 93 f7 ff    	lea    -0x86ce0(%ebx),%eax
f010194c:	50                   	push   %eax
f010194d:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0101953:	50                   	push   %eax
f0101954:	68 d6 02 00 00       	push   $0x2d6
f0101959:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f010195f:	50                   	push   %eax
f0101960:	e8 4c e7 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101965:	50                   	push   %eax
f0101966:	8d 83 64 89 f7 ff    	lea    -0x8769c(%ebx),%eax
f010196c:	50                   	push   %eax
f010196d:	6a 56                	push   $0x56
f010196f:	8d 83 99 91 f7 ff    	lea    -0x86e67(%ebx),%eax
f0101975:	50                   	push   %eax
f0101976:	e8 36 e7 ff ff       	call   f01000b1 <_panic>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010197b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010197e:	8d 83 2f 93 f7 ff    	lea    -0x86cd1(%ebx),%eax
f0101984:	50                   	push   %eax
f0101985:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f010198b:	50                   	push   %eax
f010198c:	68 db 02 00 00       	push   $0x2db
f0101991:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0101997:	50                   	push   %eax
f0101998:	e8 14 e7 ff ff       	call   f01000b1 <_panic>
	assert(pp && pp0 == pp);
f010199d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01019a0:	8d 83 4d 93 f7 ff    	lea    -0x86cb3(%ebx),%eax
f01019a6:	50                   	push   %eax
f01019a7:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01019ad:	50                   	push   %eax
f01019ae:	68 dc 02 00 00       	push   $0x2dc
f01019b3:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01019b9:	50                   	push   %eax
f01019ba:	e8 f2 e6 ff ff       	call   f01000b1 <_panic>
f01019bf:	52                   	push   %edx
f01019c0:	8d 83 64 89 f7 ff    	lea    -0x8769c(%ebx),%eax
f01019c6:	50                   	push   %eax
f01019c7:	6a 56                	push   $0x56
f01019c9:	8d 83 99 91 f7 ff    	lea    -0x86e67(%ebx),%eax
f01019cf:	50                   	push   %eax
f01019d0:	e8 dc e6 ff ff       	call   f01000b1 <_panic>
		assert(c[i] == 0);
f01019d5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01019d8:	8d 83 5d 93 f7 ff    	lea    -0x86ca3(%ebx),%eax
f01019de:	50                   	push   %eax
f01019df:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01019e5:	50                   	push   %eax
f01019e6:	68 df 02 00 00       	push   $0x2df
f01019eb:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01019f1:	50                   	push   %eax
f01019f2:	e8 ba e6 ff ff       	call   f01000b1 <_panic>
		--nfree;
f01019f7:	83 ee 01             	sub    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01019fa:	8b 00                	mov    (%eax),%eax
f01019fc:	85 c0                	test   %eax,%eax
f01019fe:	75 f7                	jne    f01019f7 <mem_init+0x665>
	assert(nfree == 0);
f0101a00:	85 f6                	test   %esi,%esi
f0101a02:	0f 85 f3 07 00 00    	jne    f01021fb <mem_init+0xe69>
	cprintf("check_page_alloc() succeeded!\n");
f0101a08:	83 ec 0c             	sub    $0xc,%esp
f0101a0b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101a0e:	8d 83 10 8b f7 ff    	lea    -0x874f0(%ebx),%eax
f0101a14:	50                   	push   %eax
f0101a15:	e8 3e 21 00 00       	call   f0103b58 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101a1a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a21:	e8 01 f6 ff ff       	call   f0101027 <page_alloc>
f0101a26:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101a29:	83 c4 10             	add    $0x10,%esp
f0101a2c:	85 c0                	test   %eax,%eax
f0101a2e:	0f 84 e9 07 00 00    	je     f010221d <mem_init+0xe8b>
	assert((pp1 = page_alloc(0)));
f0101a34:	83 ec 0c             	sub    $0xc,%esp
f0101a37:	6a 00                	push   $0x0
f0101a39:	e8 e9 f5 ff ff       	call   f0101027 <page_alloc>
f0101a3e:	89 c7                	mov    %eax,%edi
f0101a40:	83 c4 10             	add    $0x10,%esp
f0101a43:	85 c0                	test   %eax,%eax
f0101a45:	0f 84 f4 07 00 00    	je     f010223f <mem_init+0xead>
	assert((pp2 = page_alloc(0)));
f0101a4b:	83 ec 0c             	sub    $0xc,%esp
f0101a4e:	6a 00                	push   $0x0
f0101a50:	e8 d2 f5 ff ff       	call   f0101027 <page_alloc>
f0101a55:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101a58:	83 c4 10             	add    $0x10,%esp
f0101a5b:	85 c0                	test   %eax,%eax
f0101a5d:	0f 84 fe 07 00 00    	je     f0102261 <mem_init+0xecf>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101a63:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0101a66:	0f 84 17 08 00 00    	je     f0102283 <mem_init+0xef1>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a6c:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101a6f:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101a72:	0f 84 2d 08 00 00    	je     f01022a5 <mem_init+0xf13>
f0101a78:	39 c7                	cmp    %eax,%edi
f0101a7a:	0f 84 25 08 00 00    	je     f01022a5 <mem_init+0xf13>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101a80:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a83:	8b 88 00 23 00 00    	mov    0x2300(%eax),%ecx
f0101a89:	89 4d c4             	mov    %ecx,-0x3c(%ebp)
	page_free_list = 0;
f0101a8c:	c7 80 00 23 00 00 00 	movl   $0x0,0x2300(%eax)
f0101a93:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101a96:	83 ec 0c             	sub    $0xc,%esp
f0101a99:	6a 00                	push   $0x0
f0101a9b:	e8 87 f5 ff ff       	call   f0101027 <page_alloc>
f0101aa0:	83 c4 10             	add    $0x10,%esp
f0101aa3:	85 c0                	test   %eax,%eax
f0101aa5:	0f 85 1c 08 00 00    	jne    f01022c7 <mem_init+0xf35>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101aab:	83 ec 04             	sub    $0x4,%esp
f0101aae:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101ab1:	50                   	push   %eax
f0101ab2:	6a 00                	push   $0x0
f0101ab4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ab7:	c7 c0 ec ff 18 f0    	mov    $0xf018ffec,%eax
f0101abd:	ff 30                	pushl  (%eax)
f0101abf:	e8 6b f7 ff ff       	call   f010122f <page_lookup>
f0101ac4:	83 c4 10             	add    $0x10,%esp
f0101ac7:	85 c0                	test   %eax,%eax
f0101ac9:	0f 85 1a 08 00 00    	jne    f01022e9 <mem_init+0xf57>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101acf:	6a 02                	push   $0x2
f0101ad1:	6a 00                	push   $0x0
f0101ad3:	57                   	push   %edi
f0101ad4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ad7:	c7 c0 ec ff 18 f0    	mov    $0xf018ffec,%eax
f0101add:	ff 30                	pushl  (%eax)
f0101adf:	e8 0a f8 ff ff       	call   f01012ee <page_insert>
f0101ae4:	83 c4 10             	add    $0x10,%esp
f0101ae7:	85 c0                	test   %eax,%eax
f0101ae9:	0f 89 1c 08 00 00    	jns    f010230b <mem_init+0xf79>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101aef:	83 ec 0c             	sub    $0xc,%esp
f0101af2:	ff 75 cc             	pushl  -0x34(%ebp)
f0101af5:	e8 b5 f5 ff ff       	call   f01010af <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101afa:	6a 02                	push   $0x2
f0101afc:	6a 00                	push   $0x0
f0101afe:	57                   	push   %edi
f0101aff:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b02:	c7 c0 ec ff 18 f0    	mov    $0xf018ffec,%eax
f0101b08:	ff 30                	pushl  (%eax)
f0101b0a:	e8 df f7 ff ff       	call   f01012ee <page_insert>
f0101b0f:	83 c4 20             	add    $0x20,%esp
f0101b12:	85 c0                	test   %eax,%eax
f0101b14:	0f 85 13 08 00 00    	jne    f010232d <mem_init+0xf9b>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101b1a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101b1d:	c7 c0 ec ff 18 f0    	mov    $0xf018ffec,%eax
f0101b23:	8b 18                	mov    (%eax),%ebx
	return (pp - pages) << PGSHIFT;
f0101b25:	c7 c0 f0 ff 18 f0    	mov    $0xf018fff0,%eax
f0101b2b:	8b 30                	mov    (%eax),%esi
f0101b2d:	8b 13                	mov    (%ebx),%edx
f0101b2f:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101b35:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101b38:	29 f0                	sub    %esi,%eax
f0101b3a:	c1 f8 03             	sar    $0x3,%eax
f0101b3d:	c1 e0 0c             	shl    $0xc,%eax
f0101b40:	39 c2                	cmp    %eax,%edx
f0101b42:	0f 85 07 08 00 00    	jne    f010234f <mem_init+0xfbd>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101b48:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b4d:	89 d8                	mov    %ebx,%eax
f0101b4f:	e8 c0 ef ff ff       	call   f0100b14 <check_va2pa>
f0101b54:	89 fa                	mov    %edi,%edx
f0101b56:	29 f2                	sub    %esi,%edx
f0101b58:	c1 fa 03             	sar    $0x3,%edx
f0101b5b:	c1 e2 0c             	shl    $0xc,%edx
f0101b5e:	39 d0                	cmp    %edx,%eax
f0101b60:	0f 85 0a 08 00 00    	jne    f0102370 <mem_init+0xfde>
	assert(pp1->pp_ref == 1);
f0101b66:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101b6b:	0f 85 21 08 00 00    	jne    f0102392 <mem_init+0x1000>
	assert(pp0->pp_ref == 1);
f0101b71:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0101b74:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b79:	0f 85 35 08 00 00    	jne    f01023b4 <mem_init+0x1022>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101b7f:	6a 02                	push   $0x2
f0101b81:	68 00 10 00 00       	push   $0x1000
f0101b86:	ff 75 d0             	pushl  -0x30(%ebp)
f0101b89:	53                   	push   %ebx
f0101b8a:	e8 5f f7 ff ff       	call   f01012ee <page_insert>
f0101b8f:	83 c4 10             	add    $0x10,%esp
f0101b92:	85 c0                	test   %eax,%eax
f0101b94:	0f 85 3c 08 00 00    	jne    f01023d6 <mem_init+0x1044>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b9a:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b9f:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0101ba2:	c7 c0 ec ff 18 f0    	mov    $0xf018ffec,%eax
f0101ba8:	8b 00                	mov    (%eax),%eax
f0101baa:	e8 65 ef ff ff       	call   f0100b14 <check_va2pa>
f0101baf:	c7 c2 f0 ff 18 f0    	mov    $0xf018fff0,%edx
f0101bb5:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101bb8:	2b 0a                	sub    (%edx),%ecx
f0101bba:	89 ca                	mov    %ecx,%edx
f0101bbc:	c1 fa 03             	sar    $0x3,%edx
f0101bbf:	c1 e2 0c             	shl    $0xc,%edx
f0101bc2:	39 d0                	cmp    %edx,%eax
f0101bc4:	0f 85 2e 08 00 00    	jne    f01023f8 <mem_init+0x1066>
	assert(pp2->pp_ref == 1);
f0101bca:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101bcd:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101bd2:	0f 85 42 08 00 00    	jne    f010241a <mem_init+0x1088>

	// should be no free memory
	assert(!page_alloc(0));
f0101bd8:	83 ec 0c             	sub    $0xc,%esp
f0101bdb:	6a 00                	push   $0x0
f0101bdd:	e8 45 f4 ff ff       	call   f0101027 <page_alloc>
f0101be2:	83 c4 10             	add    $0x10,%esp
f0101be5:	85 c0                	test   %eax,%eax
f0101be7:	0f 85 4f 08 00 00    	jne    f010243c <mem_init+0x10aa>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101bed:	6a 02                	push   $0x2
f0101bef:	68 00 10 00 00       	push   $0x1000
f0101bf4:	ff 75 d0             	pushl  -0x30(%ebp)
f0101bf7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101bfa:	c7 c0 ec ff 18 f0    	mov    $0xf018ffec,%eax
f0101c00:	ff 30                	pushl  (%eax)
f0101c02:	e8 e7 f6 ff ff       	call   f01012ee <page_insert>
f0101c07:	83 c4 10             	add    $0x10,%esp
f0101c0a:	85 c0                	test   %eax,%eax
f0101c0c:	0f 85 4c 08 00 00    	jne    f010245e <mem_init+0x10cc>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c12:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c17:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0101c1a:	c7 c0 ec ff 18 f0    	mov    $0xf018ffec,%eax
f0101c20:	8b 00                	mov    (%eax),%eax
f0101c22:	e8 ed ee ff ff       	call   f0100b14 <check_va2pa>
f0101c27:	c7 c2 f0 ff 18 f0    	mov    $0xf018fff0,%edx
f0101c2d:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101c30:	2b 0a                	sub    (%edx),%ecx
f0101c32:	89 ca                	mov    %ecx,%edx
f0101c34:	c1 fa 03             	sar    $0x3,%edx
f0101c37:	c1 e2 0c             	shl    $0xc,%edx
f0101c3a:	39 d0                	cmp    %edx,%eax
f0101c3c:	0f 85 3e 08 00 00    	jne    f0102480 <mem_init+0x10ee>
	assert(pp2->pp_ref == 1);
f0101c42:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101c45:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101c4a:	0f 85 52 08 00 00    	jne    f01024a2 <mem_init+0x1110>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101c50:	83 ec 0c             	sub    $0xc,%esp
f0101c53:	6a 00                	push   $0x0
f0101c55:	e8 cd f3 ff ff       	call   f0101027 <page_alloc>
f0101c5a:	83 c4 10             	add    $0x10,%esp
f0101c5d:	85 c0                	test   %eax,%eax
f0101c5f:	0f 85 5f 08 00 00    	jne    f01024c4 <mem_init+0x1132>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101c65:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101c68:	c7 c0 ec ff 18 f0    	mov    $0xf018ffec,%eax
f0101c6e:	8b 10                	mov    (%eax),%edx
f0101c70:	8b 02                	mov    (%edx),%eax
f0101c72:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f0101c77:	89 c3                	mov    %eax,%ebx
f0101c79:	c1 eb 0c             	shr    $0xc,%ebx
f0101c7c:	c7 c1 e8 ff 18 f0    	mov    $0xf018ffe8,%ecx
f0101c82:	3b 19                	cmp    (%ecx),%ebx
f0101c84:	0f 83 5c 08 00 00    	jae    f01024e6 <mem_init+0x1154>
	return (void *)(pa + KERNBASE);
f0101c8a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101c8f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101c92:	83 ec 04             	sub    $0x4,%esp
f0101c95:	6a 00                	push   $0x0
f0101c97:	68 00 10 00 00       	push   $0x1000
f0101c9c:	52                   	push   %edx
f0101c9d:	e8 85 f4 ff ff       	call   f0101127 <pgdir_walk>
f0101ca2:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101ca5:	8d 51 04             	lea    0x4(%ecx),%edx
f0101ca8:	83 c4 10             	add    $0x10,%esp
f0101cab:	39 d0                	cmp    %edx,%eax
f0101cad:	0f 85 4f 08 00 00    	jne    f0102502 <mem_init+0x1170>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101cb3:	6a 06                	push   $0x6
f0101cb5:	68 00 10 00 00       	push   $0x1000
f0101cba:	ff 75 d0             	pushl  -0x30(%ebp)
f0101cbd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101cc0:	c7 c0 ec ff 18 f0    	mov    $0xf018ffec,%eax
f0101cc6:	ff 30                	pushl  (%eax)
f0101cc8:	e8 21 f6 ff ff       	call   f01012ee <page_insert>
f0101ccd:	83 c4 10             	add    $0x10,%esp
f0101cd0:	85 c0                	test   %eax,%eax
f0101cd2:	0f 85 4c 08 00 00    	jne    f0102524 <mem_init+0x1192>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101cd8:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0101cdb:	c7 c0 ec ff 18 f0    	mov    $0xf018ffec,%eax
f0101ce1:	8b 18                	mov    (%eax),%ebx
f0101ce3:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ce8:	89 d8                	mov    %ebx,%eax
f0101cea:	e8 25 ee ff ff       	call   f0100b14 <check_va2pa>
	return (pp - pages) << PGSHIFT;
f0101cef:	c7 c2 f0 ff 18 f0    	mov    $0xf018fff0,%edx
f0101cf5:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101cf8:	2b 0a                	sub    (%edx),%ecx
f0101cfa:	89 ca                	mov    %ecx,%edx
f0101cfc:	c1 fa 03             	sar    $0x3,%edx
f0101cff:	c1 e2 0c             	shl    $0xc,%edx
f0101d02:	39 d0                	cmp    %edx,%eax
f0101d04:	0f 85 3c 08 00 00    	jne    f0102546 <mem_init+0x11b4>
	assert(pp2->pp_ref == 1);
f0101d0a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101d0d:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101d12:	0f 85 50 08 00 00    	jne    f0102568 <mem_init+0x11d6>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101d18:	83 ec 04             	sub    $0x4,%esp
f0101d1b:	6a 00                	push   $0x0
f0101d1d:	68 00 10 00 00       	push   $0x1000
f0101d22:	53                   	push   %ebx
f0101d23:	e8 ff f3 ff ff       	call   f0101127 <pgdir_walk>
f0101d28:	83 c4 10             	add    $0x10,%esp
f0101d2b:	f6 00 04             	testb  $0x4,(%eax)
f0101d2e:	0f 84 56 08 00 00    	je     f010258a <mem_init+0x11f8>
	assert(kern_pgdir[0] & PTE_U);
f0101d34:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d37:	c7 c0 ec ff 18 f0    	mov    $0xf018ffec,%eax
f0101d3d:	8b 00                	mov    (%eax),%eax
f0101d3f:	f6 00 04             	testb  $0x4,(%eax)
f0101d42:	0f 84 64 08 00 00    	je     f01025ac <mem_init+0x121a>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101d48:	6a 02                	push   $0x2
f0101d4a:	68 00 10 00 00       	push   $0x1000
f0101d4f:	ff 75 d0             	pushl  -0x30(%ebp)
f0101d52:	50                   	push   %eax
f0101d53:	e8 96 f5 ff ff       	call   f01012ee <page_insert>
f0101d58:	83 c4 10             	add    $0x10,%esp
f0101d5b:	85 c0                	test   %eax,%eax
f0101d5d:	0f 85 6b 08 00 00    	jne    f01025ce <mem_init+0x123c>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101d63:	83 ec 04             	sub    $0x4,%esp
f0101d66:	6a 00                	push   $0x0
f0101d68:	68 00 10 00 00       	push   $0x1000
f0101d6d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d70:	c7 c0 ec ff 18 f0    	mov    $0xf018ffec,%eax
f0101d76:	ff 30                	pushl  (%eax)
f0101d78:	e8 aa f3 ff ff       	call   f0101127 <pgdir_walk>
f0101d7d:	83 c4 10             	add    $0x10,%esp
f0101d80:	f6 00 02             	testb  $0x2,(%eax)
f0101d83:	0f 84 67 08 00 00    	je     f01025f0 <mem_init+0x125e>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101d89:	83 ec 04             	sub    $0x4,%esp
f0101d8c:	6a 00                	push   $0x0
f0101d8e:	68 00 10 00 00       	push   $0x1000
f0101d93:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d96:	c7 c0 ec ff 18 f0    	mov    $0xf018ffec,%eax
f0101d9c:	ff 30                	pushl  (%eax)
f0101d9e:	e8 84 f3 ff ff       	call   f0101127 <pgdir_walk>
f0101da3:	83 c4 10             	add    $0x10,%esp
f0101da6:	f6 00 04             	testb  $0x4,(%eax)
f0101da9:	0f 85 63 08 00 00    	jne    f0102612 <mem_init+0x1280>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101daf:	6a 02                	push   $0x2
f0101db1:	68 00 00 40 00       	push   $0x400000
f0101db6:	ff 75 cc             	pushl  -0x34(%ebp)
f0101db9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101dbc:	c7 c0 ec ff 18 f0    	mov    $0xf018ffec,%eax
f0101dc2:	ff 30                	pushl  (%eax)
f0101dc4:	e8 25 f5 ff ff       	call   f01012ee <page_insert>
f0101dc9:	83 c4 10             	add    $0x10,%esp
f0101dcc:	85 c0                	test   %eax,%eax
f0101dce:	0f 89 60 08 00 00    	jns    f0102634 <mem_init+0x12a2>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101dd4:	6a 02                	push   $0x2
f0101dd6:	68 00 10 00 00       	push   $0x1000
f0101ddb:	57                   	push   %edi
f0101ddc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ddf:	c7 c0 ec ff 18 f0    	mov    $0xf018ffec,%eax
f0101de5:	ff 30                	pushl  (%eax)
f0101de7:	e8 02 f5 ff ff       	call   f01012ee <page_insert>
f0101dec:	83 c4 10             	add    $0x10,%esp
f0101def:	85 c0                	test   %eax,%eax
f0101df1:	0f 85 5f 08 00 00    	jne    f0102656 <mem_init+0x12c4>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101df7:	83 ec 04             	sub    $0x4,%esp
f0101dfa:	6a 00                	push   $0x0
f0101dfc:	68 00 10 00 00       	push   $0x1000
f0101e01:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e04:	c7 c0 ec ff 18 f0    	mov    $0xf018ffec,%eax
f0101e0a:	ff 30                	pushl  (%eax)
f0101e0c:	e8 16 f3 ff ff       	call   f0101127 <pgdir_walk>
f0101e11:	83 c4 10             	add    $0x10,%esp
f0101e14:	f6 00 04             	testb  $0x4,(%eax)
f0101e17:	0f 85 5b 08 00 00    	jne    f0102678 <mem_init+0x12e6>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101e1d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e20:	c7 c0 ec ff 18 f0    	mov    $0xf018ffec,%eax
f0101e26:	8b 30                	mov    (%eax),%esi
f0101e28:	ba 00 00 00 00       	mov    $0x0,%edx
f0101e2d:	89 f0                	mov    %esi,%eax
f0101e2f:	e8 e0 ec ff ff       	call   f0100b14 <check_va2pa>
f0101e34:	89 c3                	mov    %eax,%ebx
f0101e36:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e39:	c7 c0 f0 ff 18 f0    	mov    $0xf018fff0,%eax
f0101e3f:	89 f9                	mov    %edi,%ecx
f0101e41:	2b 08                	sub    (%eax),%ecx
f0101e43:	89 c8                	mov    %ecx,%eax
f0101e45:	c1 f8 03             	sar    $0x3,%eax
f0101e48:	c1 e0 0c             	shl    $0xc,%eax
f0101e4b:	39 c3                	cmp    %eax,%ebx
f0101e4d:	0f 85 47 08 00 00    	jne    f010269a <mem_init+0x1308>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101e53:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e58:	89 f0                	mov    %esi,%eax
f0101e5a:	e8 b5 ec ff ff       	call   f0100b14 <check_va2pa>
f0101e5f:	39 c3                	cmp    %eax,%ebx
f0101e61:	0f 85 55 08 00 00    	jne    f01026bc <mem_init+0x132a>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101e67:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0101e6c:	0f 85 6c 08 00 00    	jne    f01026de <mem_init+0x134c>
	assert(pp2->pp_ref == 0);
f0101e72:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101e75:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101e7a:	0f 85 80 08 00 00    	jne    f0102700 <mem_init+0x136e>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0101e80:	83 ec 0c             	sub    $0xc,%esp
f0101e83:	6a 00                	push   $0x0
f0101e85:	e8 9d f1 ff ff       	call   f0101027 <page_alloc>
f0101e8a:	83 c4 10             	add    $0x10,%esp
f0101e8d:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0101e90:	0f 85 8c 08 00 00    	jne    f0102722 <mem_init+0x1390>
f0101e96:	85 c0                	test   %eax,%eax
f0101e98:	0f 84 84 08 00 00    	je     f0102722 <mem_init+0x1390>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0101e9e:	83 ec 08             	sub    $0x8,%esp
f0101ea1:	6a 00                	push   $0x0
f0101ea3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ea6:	c7 c3 ec ff 18 f0    	mov    $0xf018ffec,%ebx
f0101eac:	ff 33                	pushl  (%ebx)
f0101eae:	e8 ee f3 ff ff       	call   f01012a1 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101eb3:	8b 1b                	mov    (%ebx),%ebx
f0101eb5:	ba 00 00 00 00       	mov    $0x0,%edx
f0101eba:	89 d8                	mov    %ebx,%eax
f0101ebc:	e8 53 ec ff ff       	call   f0100b14 <check_va2pa>
f0101ec1:	83 c4 10             	add    $0x10,%esp
f0101ec4:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101ec7:	0f 85 77 08 00 00    	jne    f0102744 <mem_init+0x13b2>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ecd:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ed2:	89 d8                	mov    %ebx,%eax
f0101ed4:	e8 3b ec ff ff       	call   f0100b14 <check_va2pa>
f0101ed9:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101edc:	c7 c2 f0 ff 18 f0    	mov    $0xf018fff0,%edx
f0101ee2:	89 f9                	mov    %edi,%ecx
f0101ee4:	2b 0a                	sub    (%edx),%ecx
f0101ee6:	89 ca                	mov    %ecx,%edx
f0101ee8:	c1 fa 03             	sar    $0x3,%edx
f0101eeb:	c1 e2 0c             	shl    $0xc,%edx
f0101eee:	39 d0                	cmp    %edx,%eax
f0101ef0:	0f 85 70 08 00 00    	jne    f0102766 <mem_init+0x13d4>
	assert(pp1->pp_ref == 1);
f0101ef6:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101efb:	0f 85 87 08 00 00    	jne    f0102788 <mem_init+0x13f6>
	assert(pp2->pp_ref == 0);
f0101f01:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101f04:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101f09:	0f 85 9b 08 00 00    	jne    f01027aa <mem_init+0x1418>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0101f0f:	6a 00                	push   $0x0
f0101f11:	68 00 10 00 00       	push   $0x1000
f0101f16:	57                   	push   %edi
f0101f17:	53                   	push   %ebx
f0101f18:	e8 d1 f3 ff ff       	call   f01012ee <page_insert>
f0101f1d:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0101f20:	83 c4 10             	add    $0x10,%esp
f0101f23:	85 c0                	test   %eax,%eax
f0101f25:	0f 85 a1 08 00 00    	jne    f01027cc <mem_init+0x143a>
	assert(pp1->pp_ref);
f0101f2b:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101f30:	0f 84 b8 08 00 00    	je     f01027ee <mem_init+0x145c>
	assert(pp1->pp_link == NULL);
f0101f36:	83 3f 00             	cmpl   $0x0,(%edi)
f0101f39:	0f 85 d1 08 00 00    	jne    f0102810 <mem_init+0x147e>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0101f3f:	83 ec 08             	sub    $0x8,%esp
f0101f42:	68 00 10 00 00       	push   $0x1000
f0101f47:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f4a:	c7 c3 ec ff 18 f0    	mov    $0xf018ffec,%ebx
f0101f50:	ff 33                	pushl  (%ebx)
f0101f52:	e8 4a f3 ff ff       	call   f01012a1 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0101f57:	8b 1b                	mov    (%ebx),%ebx
f0101f59:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f5e:	89 d8                	mov    %ebx,%eax
f0101f60:	e8 af eb ff ff       	call   f0100b14 <check_va2pa>
f0101f65:	83 c4 10             	add    $0x10,%esp
f0101f68:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f6b:	0f 85 c1 08 00 00    	jne    f0102832 <mem_init+0x14a0>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0101f71:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101f76:	89 d8                	mov    %ebx,%eax
f0101f78:	e8 97 eb ff ff       	call   f0100b14 <check_va2pa>
f0101f7d:	83 f8 ff             	cmp    $0xffffffff,%eax
f0101f80:	0f 85 ce 08 00 00    	jne    f0102854 <mem_init+0x14c2>
	assert(pp1->pp_ref == 0);
f0101f86:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0101f8b:	0f 85 e5 08 00 00    	jne    f0102876 <mem_init+0x14e4>
	assert(pp2->pp_ref == 0);
f0101f91:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101f94:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101f99:	0f 85 f9 08 00 00    	jne    f0102898 <mem_init+0x1506>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0101f9f:	83 ec 0c             	sub    $0xc,%esp
f0101fa2:	6a 00                	push   $0x0
f0101fa4:	e8 7e f0 ff ff       	call   f0101027 <page_alloc>
f0101fa9:	83 c4 10             	add    $0x10,%esp
f0101fac:	85 c0                	test   %eax,%eax
f0101fae:	0f 84 06 09 00 00    	je     f01028ba <mem_init+0x1528>
f0101fb4:	39 c7                	cmp    %eax,%edi
f0101fb6:	0f 85 fe 08 00 00    	jne    f01028ba <mem_init+0x1528>

	// should be no free memory
	assert(!page_alloc(0));
f0101fbc:	83 ec 0c             	sub    $0xc,%esp
f0101fbf:	6a 00                	push   $0x0
f0101fc1:	e8 61 f0 ff ff       	call   f0101027 <page_alloc>
f0101fc6:	83 c4 10             	add    $0x10,%esp
f0101fc9:	85 c0                	test   %eax,%eax
f0101fcb:	0f 85 0b 09 00 00    	jne    f01028dc <mem_init+0x154a>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101fd1:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0101fd4:	c7 c0 ec ff 18 f0    	mov    $0xf018ffec,%eax
f0101fda:	8b 08                	mov    (%eax),%ecx
f0101fdc:	8b 11                	mov    (%ecx),%edx
f0101fde:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101fe4:	c7 c0 f0 ff 18 f0    	mov    $0xf018fff0,%eax
f0101fea:	8b 5d cc             	mov    -0x34(%ebp),%ebx
f0101fed:	2b 18                	sub    (%eax),%ebx
f0101fef:	89 d8                	mov    %ebx,%eax
f0101ff1:	c1 f8 03             	sar    $0x3,%eax
f0101ff4:	c1 e0 0c             	shl    $0xc,%eax
f0101ff7:	39 c2                	cmp    %eax,%edx
f0101ff9:	0f 85 ff 08 00 00    	jne    f01028fe <mem_init+0x156c>
	kern_pgdir[0] = 0;
f0101fff:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102005:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102008:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f010200d:	0f 85 0d 09 00 00    	jne    f0102920 <mem_init+0x158e>
	pp0->pp_ref = 0;
f0102013:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102016:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f010201c:	83 ec 0c             	sub    $0xc,%esp
f010201f:	50                   	push   %eax
f0102020:	e8 8a f0 ff ff       	call   f01010af <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102025:	83 c4 0c             	add    $0xc,%esp
f0102028:	6a 01                	push   $0x1
f010202a:	68 00 10 40 00       	push   $0x401000
f010202f:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0102032:	c7 c3 ec ff 18 f0    	mov    $0xf018ffec,%ebx
f0102038:	ff 33                	pushl  (%ebx)
f010203a:	e8 e8 f0 ff ff       	call   f0101127 <pgdir_walk>
f010203f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102042:	8b 0b                	mov    (%ebx),%ecx
f0102044:	8b 51 04             	mov    0x4(%ecx),%edx
f0102047:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	if (PGNUM(pa) >= npages)
f010204d:	c7 c3 e8 ff 18 f0    	mov    $0xf018ffe8,%ebx
f0102053:	8b 1b                	mov    (%ebx),%ebx
f0102055:	89 d6                	mov    %edx,%esi
f0102057:	c1 ee 0c             	shr    $0xc,%esi
f010205a:	83 c4 10             	add    $0x10,%esp
f010205d:	39 de                	cmp    %ebx,%esi
f010205f:	0f 83 dd 08 00 00    	jae    f0102942 <mem_init+0x15b0>
	assert(ptep == ptep1 + PTX(va));
f0102065:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f010206b:	39 d0                	cmp    %edx,%eax
f010206d:	0f 85 eb 08 00 00    	jne    f010295e <mem_init+0x15cc>
	kern_pgdir[PDX(va)] = 0;
f0102073:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f010207a:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f010207d:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
	return (pp - pages) << PGSHIFT;
f0102083:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102086:	c7 c0 f0 ff 18 f0    	mov    $0xf018fff0,%eax
f010208c:	2b 08                	sub    (%eax),%ecx
f010208e:	89 c8                	mov    %ecx,%eax
f0102090:	c1 f8 03             	sar    $0x3,%eax
f0102093:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102096:	89 c2                	mov    %eax,%edx
f0102098:	c1 ea 0c             	shr    $0xc,%edx
f010209b:	39 d3                	cmp    %edx,%ebx
f010209d:	0f 86 dd 08 00 00    	jbe    f0102980 <mem_init+0x15ee>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01020a3:	83 ec 04             	sub    $0x4,%esp
f01020a6:	68 00 10 00 00       	push   $0x1000
f01020ab:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f01020b0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01020b5:	50                   	push   %eax
f01020b6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01020b9:	e8 d7 2f 00 00       	call   f0105095 <memset>
	page_free(pp0);
f01020be:	8b 75 cc             	mov    -0x34(%ebp),%esi
f01020c1:	89 34 24             	mov    %esi,(%esp)
f01020c4:	e8 e6 ef ff ff       	call   f01010af <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01020c9:	83 c4 0c             	add    $0xc,%esp
f01020cc:	6a 01                	push   $0x1
f01020ce:	6a 00                	push   $0x0
f01020d0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01020d3:	c7 c0 ec ff 18 f0    	mov    $0xf018ffec,%eax
f01020d9:	ff 30                	pushl  (%eax)
f01020db:	e8 47 f0 ff ff       	call   f0101127 <pgdir_walk>
	return (pp - pages) << PGSHIFT;
f01020e0:	c7 c0 f0 ff 18 f0    	mov    $0xf018fff0,%eax
f01020e6:	89 f2                	mov    %esi,%edx
f01020e8:	2b 10                	sub    (%eax),%edx
f01020ea:	c1 fa 03             	sar    $0x3,%edx
f01020ed:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f01020f0:	89 d1                	mov    %edx,%ecx
f01020f2:	c1 e9 0c             	shr    $0xc,%ecx
f01020f5:	83 c4 10             	add    $0x10,%esp
f01020f8:	c7 c0 e8 ff 18 f0    	mov    $0xf018ffe8,%eax
f01020fe:	3b 08                	cmp    (%eax),%ecx
f0102100:	0f 83 93 08 00 00    	jae    f0102999 <mem_init+0x1607>
	return (void *)(pa + KERNBASE);
f0102106:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f010210c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010210f:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
f0102115:	8b 75 c8             	mov    -0x38(%ebp),%esi
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102118:	f6 00 01             	testb  $0x1,(%eax)
f010211b:	0f 85 91 08 00 00    	jne    f01029b2 <mem_init+0x1620>
f0102121:	83 c0 04             	add    $0x4,%eax
	for(i=0; i<NPTENTRIES; i++)
f0102124:	39 d0                	cmp    %edx,%eax
f0102126:	75 f0                	jne    f0102118 <mem_init+0xd86>
f0102128:	89 75 c8             	mov    %esi,-0x38(%ebp)
	kern_pgdir[0] = 0;
f010212b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010212e:	c7 c0 ec ff 18 f0    	mov    $0xf018ffec,%eax
f0102134:	8b 00                	mov    (%eax),%eax
f0102136:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010213c:	8b 45 cc             	mov    -0x34(%ebp),%eax
f010213f:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102145:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0102148:	89 b3 00 23 00 00    	mov    %esi,0x2300(%ebx)

	// free the pages we took
	page_free(pp0);
f010214e:	83 ec 0c             	sub    $0xc,%esp
f0102151:	50                   	push   %eax
f0102152:	e8 58 ef ff ff       	call   f01010af <page_free>
	page_free(pp1);
f0102157:	89 3c 24             	mov    %edi,(%esp)
f010215a:	e8 50 ef ff ff       	call   f01010af <page_free>
	page_free(pp2);
f010215f:	83 c4 04             	add    $0x4,%esp
f0102162:	ff 75 d0             	pushl  -0x30(%ebp)
f0102165:	e8 45 ef ff ff       	call   f01010af <page_free>

	cprintf("check_page() succeeded!\n");
f010216a:	8d 83 3e 94 f7 ff    	lea    -0x86bc2(%ebx),%eax
f0102170:	89 04 24             	mov    %eax,(%esp)
f0102173:	89 df                	mov    %ebx,%edi
f0102175:	e8 de 19 00 00       	call   f0103b58 <cprintf>
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f010217a:	c7 c0 e8 ff 18 f0    	mov    $0xf018ffe8,%eax
f0102180:	8b 00                	mov    (%eax),%eax
f0102182:	8d 1c c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%ebx
f0102189:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	for(i=0; i<n; i= i+PGSIZE)
f010218f:	83 c4 10             	add    $0x10,%esp
		page_insert(kern_pgdir, pa2page(PADDR(pages) + i), (void *) (UPAGES +i), perm);
f0102192:	c7 c0 f0 ff 18 f0    	mov    $0xf018fff0,%eax
f0102198:	89 45 d0             	mov    %eax,-0x30(%ebp)
	if (PGNUM(pa) >= npages)
f010219b:	c7 c0 e8 ff 18 f0    	mov    $0xf018ffe8,%eax
f01021a1:	89 c7                	mov    %eax,%edi
f01021a3:	8b 75 c8             	mov    -0x38(%ebp),%esi
	for(i=0; i<n; i= i+PGSIZE)
f01021a6:	89 f0                	mov    %esi,%eax
f01021a8:	39 de                	cmp    %ebx,%esi
f01021aa:	0f 83 5b 08 00 00    	jae    f0102a0b <mem_init+0x1679>
f01021b0:	8d 8e 00 00 00 ef    	lea    -0x11000000(%esi),%ecx
		page_insert(kern_pgdir, pa2page(PADDR(pages) + i), (void *) (UPAGES +i), perm);
f01021b6:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01021b9:	8b 12                	mov    (%edx),%edx
	if ((uint32_t)kva < KERNBASE)
f01021bb:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f01021c1:	0f 86 0d 08 00 00    	jbe    f01029d4 <mem_init+0x1642>
f01021c7:	8d 84 02 00 00 00 10 	lea    0x10000000(%edx,%eax,1),%eax
	if (PGNUM(pa) >= npages)
f01021ce:	c1 e8 0c             	shr    $0xc,%eax
f01021d1:	3b 07                	cmp    (%edi),%eax
f01021d3:	0f 83 17 08 00 00    	jae    f01029f0 <mem_init+0x165e>
f01021d9:	6a 05                	push   $0x5
f01021db:	51                   	push   %ecx
	return &pages[PGNUM(pa)];
f01021dc:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f01021df:	50                   	push   %eax
f01021e0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021e3:	c7 c0 ec ff 18 f0    	mov    $0xf018ffec,%eax
f01021e9:	ff 30                	pushl  (%eax)
f01021eb:	e8 fe f0 ff ff       	call   f01012ee <page_insert>
	for(i=0; i<n; i= i+PGSIZE)
f01021f0:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01021f6:	83 c4 10             	add    $0x10,%esp
f01021f9:	eb ab                	jmp    f01021a6 <mem_init+0xe14>
	assert(nfree == 0);
f01021fb:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01021fe:	8d 83 67 93 f7 ff    	lea    -0x86c99(%ebx),%eax
f0102204:	50                   	push   %eax
f0102205:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f010220b:	50                   	push   %eax
f010220c:	68 ec 02 00 00       	push   $0x2ec
f0102211:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102217:	50                   	push   %eax
f0102218:	e8 94 de ff ff       	call   f01000b1 <_panic>
	assert((pp0 = page_alloc(0)));
f010221d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102220:	8d 83 75 92 f7 ff    	lea    -0x86d8b(%ebx),%eax
f0102226:	50                   	push   %eax
f0102227:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f010222d:	50                   	push   %eax
f010222e:	68 4a 03 00 00       	push   $0x34a
f0102233:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102239:	50                   	push   %eax
f010223a:	e8 72 de ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f010223f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102242:	8d 83 8b 92 f7 ff    	lea    -0x86d75(%ebx),%eax
f0102248:	50                   	push   %eax
f0102249:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f010224f:	50                   	push   %eax
f0102250:	68 4b 03 00 00       	push   $0x34b
f0102255:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f010225b:	50                   	push   %eax
f010225c:	e8 50 de ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f0102261:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102264:	8d 83 a1 92 f7 ff    	lea    -0x86d5f(%ebx),%eax
f010226a:	50                   	push   %eax
f010226b:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102271:	50                   	push   %eax
f0102272:	68 4c 03 00 00       	push   $0x34c
f0102277:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f010227d:	50                   	push   %eax
f010227e:	e8 2e de ff ff       	call   f01000b1 <_panic>
	assert(pp1 && pp1 != pp0);
f0102283:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102286:	8d 83 b7 92 f7 ff    	lea    -0x86d49(%ebx),%eax
f010228c:	50                   	push   %eax
f010228d:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102293:	50                   	push   %eax
f0102294:	68 4f 03 00 00       	push   $0x34f
f0102299:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f010229f:	50                   	push   %eax
f01022a0:	e8 0c de ff ff       	call   f01000b1 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01022a5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022a8:	8d 83 f0 8a f7 ff    	lea    -0x87510(%ebx),%eax
f01022ae:	50                   	push   %eax
f01022af:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01022b5:	50                   	push   %eax
f01022b6:	68 50 03 00 00       	push   $0x350
f01022bb:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01022c1:	50                   	push   %eax
f01022c2:	e8 ea dd ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f01022c7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022ca:	8d 83 20 93 f7 ff    	lea    -0x86ce0(%ebx),%eax
f01022d0:	50                   	push   %eax
f01022d1:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01022d7:	50                   	push   %eax
f01022d8:	68 57 03 00 00       	push   $0x357
f01022dd:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01022e3:	50                   	push   %eax
f01022e4:	e8 c8 dd ff ff       	call   f01000b1 <_panic>
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f01022e9:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01022ec:	8d 83 30 8b f7 ff    	lea    -0x874d0(%ebx),%eax
f01022f2:	50                   	push   %eax
f01022f3:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01022f9:	50                   	push   %eax
f01022fa:	68 5a 03 00 00       	push   $0x35a
f01022ff:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102305:	50                   	push   %eax
f0102306:	e8 a6 dd ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010230b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010230e:	8d 83 68 8b f7 ff    	lea    -0x87498(%ebx),%eax
f0102314:	50                   	push   %eax
f0102315:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f010231b:	50                   	push   %eax
f010231c:	68 5d 03 00 00       	push   $0x35d
f0102321:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102327:	50                   	push   %eax
f0102328:	e8 84 dd ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f010232d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102330:	8d 83 98 8b f7 ff    	lea    -0x87468(%ebx),%eax
f0102336:	50                   	push   %eax
f0102337:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f010233d:	50                   	push   %eax
f010233e:	68 61 03 00 00       	push   $0x361
f0102343:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102349:	50                   	push   %eax
f010234a:	e8 62 dd ff ff       	call   f01000b1 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010234f:	89 cb                	mov    %ecx,%ebx
f0102351:	8d 81 c8 8b f7 ff    	lea    -0x87438(%ecx),%eax
f0102357:	50                   	push   %eax
f0102358:	8d 81 b3 91 f7 ff    	lea    -0x86e4d(%ecx),%eax
f010235e:	50                   	push   %eax
f010235f:	68 62 03 00 00       	push   $0x362
f0102364:	8d 81 8d 91 f7 ff    	lea    -0x86e73(%ecx),%eax
f010236a:	50                   	push   %eax
f010236b:	e8 41 dd ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0102370:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102373:	8d 83 f0 8b f7 ff    	lea    -0x87410(%ebx),%eax
f0102379:	50                   	push   %eax
f010237a:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102380:	50                   	push   %eax
f0102381:	68 63 03 00 00       	push   $0x363
f0102386:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f010238c:	50                   	push   %eax
f010238d:	e8 1f dd ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 1);
f0102392:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102395:	8d 83 72 93 f7 ff    	lea    -0x86c8e(%ebx),%eax
f010239b:	50                   	push   %eax
f010239c:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01023a2:	50                   	push   %eax
f01023a3:	68 64 03 00 00       	push   $0x364
f01023a8:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01023ae:	50                   	push   %eax
f01023af:	e8 fd dc ff ff       	call   f01000b1 <_panic>
	assert(pp0->pp_ref == 1);
f01023b4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023b7:	8d 83 83 93 f7 ff    	lea    -0x86c7d(%ebx),%eax
f01023bd:	50                   	push   %eax
f01023be:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01023c4:	50                   	push   %eax
f01023c5:	68 65 03 00 00       	push   $0x365
f01023ca:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01023d0:	50                   	push   %eax
f01023d1:	e8 db dc ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01023d6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023d9:	8d 83 20 8c f7 ff    	lea    -0x873e0(%ebx),%eax
f01023df:	50                   	push   %eax
f01023e0:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01023e6:	50                   	push   %eax
f01023e7:	68 68 03 00 00       	push   $0x368
f01023ec:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01023f2:	50                   	push   %eax
f01023f3:	e8 b9 dc ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01023f8:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01023fb:	8d 83 5c 8c f7 ff    	lea    -0x873a4(%ebx),%eax
f0102401:	50                   	push   %eax
f0102402:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102408:	50                   	push   %eax
f0102409:	68 69 03 00 00       	push   $0x369
f010240e:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102414:	50                   	push   %eax
f0102415:	e8 97 dc ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f010241a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010241d:	8d 83 94 93 f7 ff    	lea    -0x86c6c(%ebx),%eax
f0102423:	50                   	push   %eax
f0102424:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f010242a:	50                   	push   %eax
f010242b:	68 6a 03 00 00       	push   $0x36a
f0102430:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102436:	50                   	push   %eax
f0102437:	e8 75 dc ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f010243c:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010243f:	8d 83 20 93 f7 ff    	lea    -0x86ce0(%ebx),%eax
f0102445:	50                   	push   %eax
f0102446:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f010244c:	50                   	push   %eax
f010244d:	68 6d 03 00 00       	push   $0x36d
f0102452:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102458:	50                   	push   %eax
f0102459:	e8 53 dc ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010245e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102461:	8d 83 20 8c f7 ff    	lea    -0x873e0(%ebx),%eax
f0102467:	50                   	push   %eax
f0102468:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f010246e:	50                   	push   %eax
f010246f:	68 70 03 00 00       	push   $0x370
f0102474:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f010247a:	50                   	push   %eax
f010247b:	e8 31 dc ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102480:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102483:	8d 83 5c 8c f7 ff    	lea    -0x873a4(%ebx),%eax
f0102489:	50                   	push   %eax
f010248a:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102490:	50                   	push   %eax
f0102491:	68 71 03 00 00       	push   $0x371
f0102496:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f010249c:	50                   	push   %eax
f010249d:	e8 0f dc ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f01024a2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024a5:	8d 83 94 93 f7 ff    	lea    -0x86c6c(%ebx),%eax
f01024ab:	50                   	push   %eax
f01024ac:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01024b2:	50                   	push   %eax
f01024b3:	68 72 03 00 00       	push   $0x372
f01024b8:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01024be:	50                   	push   %eax
f01024bf:	e8 ed db ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f01024c4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024c7:	8d 83 20 93 f7 ff    	lea    -0x86ce0(%ebx),%eax
f01024cd:	50                   	push   %eax
f01024ce:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01024d4:	50                   	push   %eax
f01024d5:	68 76 03 00 00       	push   $0x376
f01024da:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01024e0:	50                   	push   %eax
f01024e1:	e8 cb db ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024e6:	50                   	push   %eax
f01024e7:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01024ea:	8d 83 64 89 f7 ff    	lea    -0x8769c(%ebx),%eax
f01024f0:	50                   	push   %eax
f01024f1:	68 79 03 00 00       	push   $0x379
f01024f6:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01024fc:	50                   	push   %eax
f01024fd:	e8 af db ff ff       	call   f01000b1 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102502:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102505:	8d 83 8c 8c f7 ff    	lea    -0x87374(%ebx),%eax
f010250b:	50                   	push   %eax
f010250c:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102512:	50                   	push   %eax
f0102513:	68 7a 03 00 00       	push   $0x37a
f0102518:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f010251e:	50                   	push   %eax
f010251f:	e8 8d db ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102524:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102527:	8d 83 cc 8c f7 ff    	lea    -0x87334(%ebx),%eax
f010252d:	50                   	push   %eax
f010252e:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102534:	50                   	push   %eax
f0102535:	68 7d 03 00 00       	push   $0x37d
f010253a:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102540:	50                   	push   %eax
f0102541:	e8 6b db ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102546:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102549:	8d 83 5c 8c f7 ff    	lea    -0x873a4(%ebx),%eax
f010254f:	50                   	push   %eax
f0102550:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102556:	50                   	push   %eax
f0102557:	68 7e 03 00 00       	push   $0x37e
f010255c:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102562:	50                   	push   %eax
f0102563:	e8 49 db ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f0102568:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010256b:	8d 83 94 93 f7 ff    	lea    -0x86c6c(%ebx),%eax
f0102571:	50                   	push   %eax
f0102572:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102578:	50                   	push   %eax
f0102579:	68 7f 03 00 00       	push   $0x37f
f010257e:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102584:	50                   	push   %eax
f0102585:	e8 27 db ff ff       	call   f01000b1 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f010258a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010258d:	8d 83 0c 8d f7 ff    	lea    -0x872f4(%ebx),%eax
f0102593:	50                   	push   %eax
f0102594:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f010259a:	50                   	push   %eax
f010259b:	68 80 03 00 00       	push   $0x380
f01025a0:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01025a6:	50                   	push   %eax
f01025a7:	e8 05 db ff ff       	call   f01000b1 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01025ac:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025af:	8d 83 a5 93 f7 ff    	lea    -0x86c5b(%ebx),%eax
f01025b5:	50                   	push   %eax
f01025b6:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01025bc:	50                   	push   %eax
f01025bd:	68 81 03 00 00       	push   $0x381
f01025c2:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01025c8:	50                   	push   %eax
f01025c9:	e8 e3 da ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01025ce:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025d1:	8d 83 20 8c f7 ff    	lea    -0x873e0(%ebx),%eax
f01025d7:	50                   	push   %eax
f01025d8:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01025de:	50                   	push   %eax
f01025df:	68 84 03 00 00       	push   $0x384
f01025e4:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01025ea:	50                   	push   %eax
f01025eb:	e8 c1 da ff ff       	call   f01000b1 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01025f0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01025f3:	8d 83 40 8d f7 ff    	lea    -0x872c0(%ebx),%eax
f01025f9:	50                   	push   %eax
f01025fa:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102600:	50                   	push   %eax
f0102601:	68 85 03 00 00       	push   $0x385
f0102606:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f010260c:	50                   	push   %eax
f010260d:	e8 9f da ff ff       	call   f01000b1 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102612:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102615:	8d 83 74 8d f7 ff    	lea    -0x8728c(%ebx),%eax
f010261b:	50                   	push   %eax
f010261c:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102622:	50                   	push   %eax
f0102623:	68 86 03 00 00       	push   $0x386
f0102628:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f010262e:	50                   	push   %eax
f010262f:	e8 7d da ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102634:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102637:	8d 83 ac 8d f7 ff    	lea    -0x87254(%ebx),%eax
f010263d:	50                   	push   %eax
f010263e:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102644:	50                   	push   %eax
f0102645:	68 89 03 00 00       	push   $0x389
f010264a:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102650:	50                   	push   %eax
f0102651:	e8 5b da ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102656:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102659:	8d 83 e4 8d f7 ff    	lea    -0x8721c(%ebx),%eax
f010265f:	50                   	push   %eax
f0102660:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102666:	50                   	push   %eax
f0102667:	68 8c 03 00 00       	push   $0x38c
f010266c:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102672:	50                   	push   %eax
f0102673:	e8 39 da ff ff       	call   f01000b1 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102678:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010267b:	8d 83 74 8d f7 ff    	lea    -0x8728c(%ebx),%eax
f0102681:	50                   	push   %eax
f0102682:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102688:	50                   	push   %eax
f0102689:	68 8d 03 00 00       	push   $0x38d
f010268e:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102694:	50                   	push   %eax
f0102695:	e8 17 da ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010269a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010269d:	8d 83 20 8e f7 ff    	lea    -0x871e0(%ebx),%eax
f01026a3:	50                   	push   %eax
f01026a4:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01026aa:	50                   	push   %eax
f01026ab:	68 90 03 00 00       	push   $0x390
f01026b0:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01026b6:	50                   	push   %eax
f01026b7:	e8 f5 d9 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01026bc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026bf:	8d 83 4c 8e f7 ff    	lea    -0x871b4(%ebx),%eax
f01026c5:	50                   	push   %eax
f01026c6:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01026cc:	50                   	push   %eax
f01026cd:	68 91 03 00 00       	push   $0x391
f01026d2:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01026d8:	50                   	push   %eax
f01026d9:	e8 d3 d9 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 2);
f01026de:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01026e1:	8d 83 bb 93 f7 ff    	lea    -0x86c45(%ebx),%eax
f01026e7:	50                   	push   %eax
f01026e8:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01026ee:	50                   	push   %eax
f01026ef:	68 93 03 00 00       	push   $0x393
f01026f4:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01026fa:	50                   	push   %eax
f01026fb:	e8 b1 d9 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f0102700:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102703:	8d 83 cc 93 f7 ff    	lea    -0x86c34(%ebx),%eax
f0102709:	50                   	push   %eax
f010270a:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102710:	50                   	push   %eax
f0102711:	68 94 03 00 00       	push   $0x394
f0102716:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f010271c:	50                   	push   %eax
f010271d:	e8 8f d9 ff ff       	call   f01000b1 <_panic>
	assert((pp = page_alloc(0)) && pp == pp2);
f0102722:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102725:	8d 83 7c 8e f7 ff    	lea    -0x87184(%ebx),%eax
f010272b:	50                   	push   %eax
f010272c:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102732:	50                   	push   %eax
f0102733:	68 97 03 00 00       	push   $0x397
f0102738:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f010273e:	50                   	push   %eax
f010273f:	e8 6d d9 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102744:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102747:	8d 83 a0 8e f7 ff    	lea    -0x87160(%ebx),%eax
f010274d:	50                   	push   %eax
f010274e:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102754:	50                   	push   %eax
f0102755:	68 9b 03 00 00       	push   $0x39b
f010275a:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102760:	50                   	push   %eax
f0102761:	e8 4b d9 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102766:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102769:	8d 83 4c 8e f7 ff    	lea    -0x871b4(%ebx),%eax
f010276f:	50                   	push   %eax
f0102770:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102776:	50                   	push   %eax
f0102777:	68 9c 03 00 00       	push   $0x39c
f010277c:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102782:	50                   	push   %eax
f0102783:	e8 29 d9 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 1);
f0102788:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010278b:	8d 83 72 93 f7 ff    	lea    -0x86c8e(%ebx),%eax
f0102791:	50                   	push   %eax
f0102792:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102798:	50                   	push   %eax
f0102799:	68 9d 03 00 00       	push   $0x39d
f010279e:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01027a4:	50                   	push   %eax
f01027a5:	e8 07 d9 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f01027aa:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027ad:	8d 83 cc 93 f7 ff    	lea    -0x86c34(%ebx),%eax
f01027b3:	50                   	push   %eax
f01027b4:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01027ba:	50                   	push   %eax
f01027bb:	68 9e 03 00 00       	push   $0x39e
f01027c0:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01027c6:	50                   	push   %eax
f01027c7:	e8 e5 d8 ff ff       	call   f01000b1 <_panic>
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f01027cc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027cf:	8d 83 c4 8e f7 ff    	lea    -0x8713c(%ebx),%eax
f01027d5:	50                   	push   %eax
f01027d6:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01027dc:	50                   	push   %eax
f01027dd:	68 a1 03 00 00       	push   $0x3a1
f01027e2:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01027e8:	50                   	push   %eax
f01027e9:	e8 c3 d8 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref);
f01027ee:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01027f1:	8d 83 dd 93 f7 ff    	lea    -0x86c23(%ebx),%eax
f01027f7:	50                   	push   %eax
f01027f8:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01027fe:	50                   	push   %eax
f01027ff:	68 a2 03 00 00       	push   $0x3a2
f0102804:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f010280a:	50                   	push   %eax
f010280b:	e8 a1 d8 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_link == NULL);
f0102810:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102813:	8d 83 e9 93 f7 ff    	lea    -0x86c17(%ebx),%eax
f0102819:	50                   	push   %eax
f010281a:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102820:	50                   	push   %eax
f0102821:	68 a3 03 00 00       	push   $0x3a3
f0102826:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f010282c:	50                   	push   %eax
f010282d:	e8 7f d8 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102832:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102835:	8d 83 a0 8e f7 ff    	lea    -0x87160(%ebx),%eax
f010283b:	50                   	push   %eax
f010283c:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102842:	50                   	push   %eax
f0102843:	68 a7 03 00 00       	push   $0x3a7
f0102848:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f010284e:	50                   	push   %eax
f010284f:	e8 5d d8 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102854:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102857:	8d 83 fc 8e f7 ff    	lea    -0x87104(%ebx),%eax
f010285d:	50                   	push   %eax
f010285e:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102864:	50                   	push   %eax
f0102865:	68 a8 03 00 00       	push   $0x3a8
f010286a:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102870:	50                   	push   %eax
f0102871:	e8 3b d8 ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 0);
f0102876:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102879:	8d 83 fe 93 f7 ff    	lea    -0x86c02(%ebx),%eax
f010287f:	50                   	push   %eax
f0102880:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102886:	50                   	push   %eax
f0102887:	68 a9 03 00 00       	push   $0x3a9
f010288c:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102892:	50                   	push   %eax
f0102893:	e8 19 d8 ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f0102898:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010289b:	8d 83 cc 93 f7 ff    	lea    -0x86c34(%ebx),%eax
f01028a1:	50                   	push   %eax
f01028a2:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01028a8:	50                   	push   %eax
f01028a9:	68 aa 03 00 00       	push   $0x3aa
f01028ae:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01028b4:	50                   	push   %eax
f01028b5:	e8 f7 d7 ff ff       	call   f01000b1 <_panic>
	assert((pp = page_alloc(0)) && pp == pp1);
f01028ba:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028bd:	8d 83 24 8f f7 ff    	lea    -0x870dc(%ebx),%eax
f01028c3:	50                   	push   %eax
f01028c4:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01028ca:	50                   	push   %eax
f01028cb:	68 ad 03 00 00       	push   $0x3ad
f01028d0:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01028d6:	50                   	push   %eax
f01028d7:	e8 d5 d7 ff ff       	call   f01000b1 <_panic>
	assert(!page_alloc(0));
f01028dc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01028df:	8d 83 20 93 f7 ff    	lea    -0x86ce0(%ebx),%eax
f01028e5:	50                   	push   %eax
f01028e6:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01028ec:	50                   	push   %eax
f01028ed:	68 b0 03 00 00       	push   $0x3b0
f01028f2:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01028f8:	50                   	push   %eax
f01028f9:	e8 b3 d7 ff ff       	call   f01000b1 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01028fe:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102901:	8d 83 c8 8b f7 ff    	lea    -0x87438(%ebx),%eax
f0102907:	50                   	push   %eax
f0102908:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f010290e:	50                   	push   %eax
f010290f:	68 b3 03 00 00       	push   $0x3b3
f0102914:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f010291a:	50                   	push   %eax
f010291b:	e8 91 d7 ff ff       	call   f01000b1 <_panic>
	assert(pp0->pp_ref == 1);
f0102920:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102923:	8d 83 83 93 f7 ff    	lea    -0x86c7d(%ebx),%eax
f0102929:	50                   	push   %eax
f010292a:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102930:	50                   	push   %eax
f0102931:	68 b5 03 00 00       	push   $0x3b5
f0102936:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f010293c:	50                   	push   %eax
f010293d:	e8 6f d7 ff ff       	call   f01000b1 <_panic>
f0102942:	52                   	push   %edx
f0102943:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102946:	8d 83 64 89 f7 ff    	lea    -0x8769c(%ebx),%eax
f010294c:	50                   	push   %eax
f010294d:	68 bc 03 00 00       	push   $0x3bc
f0102952:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102958:	50                   	push   %eax
f0102959:	e8 53 d7 ff ff       	call   f01000b1 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010295e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102961:	8d 83 0f 94 f7 ff    	lea    -0x86bf1(%ebx),%eax
f0102967:	50                   	push   %eax
f0102968:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f010296e:	50                   	push   %eax
f010296f:	68 bd 03 00 00       	push   $0x3bd
f0102974:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f010297a:	50                   	push   %eax
f010297b:	e8 31 d7 ff ff       	call   f01000b1 <_panic>
f0102980:	50                   	push   %eax
f0102981:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102984:	8d 83 64 89 f7 ff    	lea    -0x8769c(%ebx),%eax
f010298a:	50                   	push   %eax
f010298b:	6a 56                	push   $0x56
f010298d:	8d 83 99 91 f7 ff    	lea    -0x86e67(%ebx),%eax
f0102993:	50                   	push   %eax
f0102994:	e8 18 d7 ff ff       	call   f01000b1 <_panic>
f0102999:	52                   	push   %edx
f010299a:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010299d:	8d 83 64 89 f7 ff    	lea    -0x8769c(%ebx),%eax
f01029a3:	50                   	push   %eax
f01029a4:	6a 56                	push   $0x56
f01029a6:	8d 83 99 91 f7 ff    	lea    -0x86e67(%ebx),%eax
f01029ac:	50                   	push   %eax
f01029ad:	e8 ff d6 ff ff       	call   f01000b1 <_panic>
		assert((ptep[i] & PTE_P) == 0);
f01029b2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029b5:	8d 83 27 94 f7 ff    	lea    -0x86bd9(%ebx),%eax
f01029bb:	50                   	push   %eax
f01029bc:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01029c2:	50                   	push   %eax
f01029c3:	68 c7 03 00 00       	push   $0x3c7
f01029c8:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01029ce:	50                   	push   %eax
f01029cf:	e8 dd d6 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01029d4:	52                   	push   %edx
f01029d5:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029d8:	8d 83 cc 8a f7 ff    	lea    -0x87534(%ebx),%eax
f01029de:	50                   	push   %eax
f01029df:	68 bd 00 00 00       	push   $0xbd
f01029e4:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01029ea:	50                   	push   %eax
f01029eb:	e8 c1 d6 ff ff       	call   f01000b1 <_panic>
		panic("pa2page called with invalid pa");
f01029f0:	83 ec 04             	sub    $0x4,%esp
f01029f3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01029f6:	8d 83 70 8a f7 ff    	lea    -0x87590(%ebx),%eax
f01029fc:	50                   	push   %eax
f01029fd:	6a 4f                	push   $0x4f
f01029ff:	8d 83 99 91 f7 ff    	lea    -0x86e67(%ebx),%eax
f0102a05:	50                   	push   %eax
f0102a06:	e8 a6 d6 ff ff       	call   f01000b1 <_panic>
	boot_map_region(kern_pgdir, UENVS, PTSIZE, PADDR(envs), PTE_U);
f0102a0b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a0e:	c7 c0 2c f3 18 f0    	mov    $0xf018f32c,%eax
f0102a14:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102a16:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102a1b:	0f 86 e2 00 00 00    	jbe    f0102b03 <mem_init+0x1771>
f0102a21:	83 ec 08             	sub    $0x8,%esp
f0102a24:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f0102a26:	05 00 00 00 10       	add    $0x10000000,%eax
f0102a2b:	50                   	push   %eax
f0102a2c:	b9 00 00 40 00       	mov    $0x400000,%ecx
f0102a31:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102a36:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102a39:	c7 c0 ec ff 18 f0    	mov    $0xf018ffec,%eax
f0102a3f:	8b 00                	mov    (%eax),%eax
f0102a41:	e8 90 e7 ff ff       	call   f01011d6 <boot_map_region>
	if ((uint32_t)kva < KERNBASE)
f0102a46:	c7 c0 00 30 11 f0    	mov    $0xf0113000,%eax
f0102a4c:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0102a4f:	83 c4 10             	add    $0x10,%esp
f0102a52:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102a57:	0f 86 c2 00 00 00    	jbe    f0102b1f <mem_init+0x178d>
	boot_map_region(kern_pgdir, KSTACKTOP-KSTKSIZE, ROUNDUP(KSTKSIZE, PGSIZE), PADDR(bootstack), perm);
f0102a5d:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102a60:	c7 c3 ec ff 18 f0    	mov    $0xf018ffec,%ebx
f0102a66:	83 ec 08             	sub    $0x8,%esp
f0102a69:	6a 03                	push   $0x3
	return (physaddr_t)kva - KERNBASE;
f0102a6b:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0102a6e:	05 00 00 00 10       	add    $0x10000000,%eax
f0102a73:	50                   	push   %eax
f0102a74:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102a79:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102a7e:	8b 03                	mov    (%ebx),%eax
f0102a80:	e8 51 e7 ff ff       	call   f01011d6 <boot_map_region>
	boot_map_region(kern_pgdir, KERNBASE, size, 0, perm);
f0102a85:	83 c4 08             	add    $0x8,%esp
f0102a88:	6a 03                	push   $0x3
f0102a8a:	6a 00                	push   $0x0
f0102a8c:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102a91:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102a96:	8b 03                	mov    (%ebx),%eax
f0102a98:	e8 39 e7 ff ff       	call   f01011d6 <boot_map_region>
	pgdir = kern_pgdir;
f0102a9d:	8b 33                	mov    (%ebx),%esi
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102a9f:	c7 c0 e8 ff 18 f0    	mov    $0xf018ffe8,%eax
f0102aa5:	8b 00                	mov    (%eax),%eax
f0102aa7:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0102aaa:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102ab1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102ab6:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102ab9:	c7 c0 f0 ff 18 f0    	mov    $0xf018fff0,%eax
f0102abf:	8b 00                	mov    (%eax),%eax
f0102ac1:	89 45 c0             	mov    %eax,-0x40(%ebp)
	if ((uint32_t)kva < KERNBASE)
f0102ac4:	89 45 cc             	mov    %eax,-0x34(%ebp)
	return (physaddr_t)kva - KERNBASE;
f0102ac7:	8d b8 00 00 00 10    	lea    0x10000000(%eax),%edi
f0102acd:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < n; i += PGSIZE)
f0102ad0:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102ad5:	39 5d d0             	cmp    %ebx,-0x30(%ebp)
f0102ad8:	0f 86 a2 00 00 00    	jbe    f0102b80 <mem_init+0x17ee>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102ade:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
f0102ae4:	89 f0                	mov    %esi,%eax
f0102ae6:	e8 29 e0 ff ff       	call   f0100b14 <check_va2pa>
	if ((uint32_t)kva < KERNBASE)
f0102aeb:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f0102af2:	76 4c                	jbe    f0102b40 <mem_init+0x17ae>
f0102af4:	8d 14 3b             	lea    (%ebx,%edi,1),%edx
f0102af7:	39 d0                	cmp    %edx,%eax
f0102af9:	75 63                	jne    f0102b5e <mem_init+0x17cc>
	for (i = 0; i < n; i += PGSIZE)
f0102afb:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102b01:	eb d2                	jmp    f0102ad5 <mem_init+0x1743>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102b03:	50                   	push   %eax
f0102b04:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b07:	8d 83 cc 8a f7 ff    	lea    -0x87534(%ebx),%eax
f0102b0d:	50                   	push   %eax
f0102b0e:	68 c5 00 00 00       	push   $0xc5
f0102b13:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102b19:	50                   	push   %eax
f0102b1a:	e8 92 d5 ff ff       	call   f01000b1 <_panic>
f0102b1f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b22:	ff b3 fc ff ff ff    	pushl  -0x4(%ebx)
f0102b28:	8d 83 cc 8a f7 ff    	lea    -0x87534(%ebx),%eax
f0102b2e:	50                   	push   %eax
f0102b2f:	68 d3 00 00 00       	push   $0xd3
f0102b34:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102b3a:	50                   	push   %eax
f0102b3b:	e8 71 d5 ff ff       	call   f01000b1 <_panic>
f0102b40:	ff 75 c0             	pushl  -0x40(%ebp)
f0102b43:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b46:	8d 83 cc 8a f7 ff    	lea    -0x87534(%ebx),%eax
f0102b4c:	50                   	push   %eax
f0102b4d:	68 04 03 00 00       	push   $0x304
f0102b52:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102b58:	50                   	push   %eax
f0102b59:	e8 53 d5 ff ff       	call   f01000b1 <_panic>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102b5e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102b61:	8d 83 48 8f f7 ff    	lea    -0x870b8(%ebx),%eax
f0102b67:	50                   	push   %eax
f0102b68:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102b6e:	50                   	push   %eax
f0102b6f:	68 04 03 00 00       	push   $0x304
f0102b74:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102b7a:	50                   	push   %eax
f0102b7b:	e8 31 d5 ff ff       	call   f01000b1 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102b80:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102b83:	c7 c0 2c f3 18 f0    	mov    $0xf018f32c,%eax
f0102b89:	8b 00                	mov    (%eax),%eax
f0102b8b:	89 45 cc             	mov    %eax,-0x34(%ebp)
	if ((uint32_t)kva < KERNBASE)
f0102b8e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102b91:	bf 00 00 c0 ee       	mov    $0xeec00000,%edi
f0102b96:	8d 98 00 00 40 21    	lea    0x21400000(%eax),%ebx
f0102b9c:	89 fa                	mov    %edi,%edx
f0102b9e:	89 f0                	mov    %esi,%eax
f0102ba0:	e8 6f df ff ff       	call   f0100b14 <check_va2pa>
f0102ba5:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102bac:	76 3d                	jbe    f0102beb <mem_init+0x1859>
f0102bae:	8d 14 3b             	lea    (%ebx,%edi,1),%edx
f0102bb1:	39 d0                	cmp    %edx,%eax
f0102bb3:	75 54                	jne    f0102c09 <mem_init+0x1877>
f0102bb5:	81 c7 00 10 00 00    	add    $0x1000,%edi
	for (i = 0; i < n; i += PGSIZE)
f0102bbb:	81 ff 00 80 c1 ee    	cmp    $0xeec18000,%edi
f0102bc1:	75 d9                	jne    f0102b9c <mem_init+0x180a>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102bc3:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0102bc6:	c1 e7 0c             	shl    $0xc,%edi
f0102bc9:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102bce:	39 fb                	cmp    %edi,%ebx
f0102bd0:	73 7b                	jae    f0102c4d <mem_init+0x18bb>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102bd2:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
f0102bd8:	89 f0                	mov    %esi,%eax
f0102bda:	e8 35 df ff ff       	call   f0100b14 <check_va2pa>
f0102bdf:	39 c3                	cmp    %eax,%ebx
f0102be1:	75 48                	jne    f0102c2b <mem_init+0x1899>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102be3:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102be9:	eb e3                	jmp    f0102bce <mem_init+0x183c>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102beb:	ff 75 cc             	pushl  -0x34(%ebp)
f0102bee:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102bf1:	8d 83 cc 8a f7 ff    	lea    -0x87534(%ebx),%eax
f0102bf7:	50                   	push   %eax
f0102bf8:	68 09 03 00 00       	push   $0x309
f0102bfd:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102c03:	50                   	push   %eax
f0102c04:	e8 a8 d4 ff ff       	call   f01000b1 <_panic>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102c09:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c0c:	8d 83 7c 8f f7 ff    	lea    -0x87084(%ebx),%eax
f0102c12:	50                   	push   %eax
f0102c13:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102c19:	50                   	push   %eax
f0102c1a:	68 09 03 00 00       	push   $0x309
f0102c1f:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102c25:	50                   	push   %eax
f0102c26:	e8 86 d4 ff ff       	call   f01000b1 <_panic>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102c2b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c2e:	8d 83 b0 8f f7 ff    	lea    -0x87050(%ebx),%eax
f0102c34:	50                   	push   %eax
f0102c35:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102c3b:	50                   	push   %eax
f0102c3c:	68 0d 03 00 00       	push   $0x30d
f0102c41:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102c47:	50                   	push   %eax
f0102c48:	e8 64 d4 ff ff       	call   f01000b1 <_panic>
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102c4d:	bb 00 80 ff ef       	mov    $0xefff8000,%ebx
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102c52:	8b 7d c8             	mov    -0x38(%ebp),%edi
f0102c55:	81 c7 00 80 00 20    	add    $0x20008000,%edi
f0102c5b:	89 da                	mov    %ebx,%edx
f0102c5d:	89 f0                	mov    %esi,%eax
f0102c5f:	e8 b0 de ff ff       	call   f0100b14 <check_va2pa>
f0102c64:	8d 14 1f             	lea    (%edi,%ebx,1),%edx
f0102c67:	39 c2                	cmp    %eax,%edx
f0102c69:	75 26                	jne    f0102c91 <mem_init+0x18ff>
f0102c6b:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102c71:	81 fb 00 00 00 f0    	cmp    $0xf0000000,%ebx
f0102c77:	75 e2                	jne    f0102c5b <mem_init+0x18c9>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102c79:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102c7e:	89 f0                	mov    %esi,%eax
f0102c80:	e8 8f de ff ff       	call   f0100b14 <check_va2pa>
f0102c85:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102c88:	75 29                	jne    f0102cb3 <mem_init+0x1921>
	for (i = 0; i < NPDENTRIES; i++) {
f0102c8a:	b8 00 00 00 00       	mov    $0x0,%eax
f0102c8f:	eb 6d                	jmp    f0102cfe <mem_init+0x196c>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102c91:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102c94:	8d 83 d8 8f f7 ff    	lea    -0x87028(%ebx),%eax
f0102c9a:	50                   	push   %eax
f0102c9b:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102ca1:	50                   	push   %eax
f0102ca2:	68 11 03 00 00       	push   $0x311
f0102ca7:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102cad:	50                   	push   %eax
f0102cae:	e8 fe d3 ff ff       	call   f01000b1 <_panic>
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102cb3:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102cb6:	8d 83 20 90 f7 ff    	lea    -0x86fe0(%ebx),%eax
f0102cbc:	50                   	push   %eax
f0102cbd:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102cc3:	50                   	push   %eax
f0102cc4:	68 12 03 00 00       	push   $0x312
f0102cc9:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102ccf:	50                   	push   %eax
f0102cd0:	e8 dc d3 ff ff       	call   f01000b1 <_panic>
			assert(pgdir[i] & PTE_P);
f0102cd5:	f6 04 86 01          	testb  $0x1,(%esi,%eax,4)
f0102cd9:	74 52                	je     f0102d2d <mem_init+0x199b>
	for (i = 0; i < NPDENTRIES; i++) {
f0102cdb:	83 c0 01             	add    $0x1,%eax
f0102cde:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102ce3:	0f 87 bb 00 00 00    	ja     f0102da4 <mem_init+0x1a12>
		switch (i) {
f0102ce9:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f0102cee:	72 0e                	jb     f0102cfe <mem_init+0x196c>
f0102cf0:	3d bd 03 00 00       	cmp    $0x3bd,%eax
f0102cf5:	76 de                	jbe    f0102cd5 <mem_init+0x1943>
f0102cf7:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102cfc:	74 d7                	je     f0102cd5 <mem_init+0x1943>
			if (i >= PDX(KERNBASE)) {
f0102cfe:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102d03:	77 4a                	ja     f0102d4f <mem_init+0x19bd>
				assert(pgdir[i] == 0);
f0102d05:	83 3c 86 00          	cmpl   $0x0,(%esi,%eax,4)
f0102d09:	74 d0                	je     f0102cdb <mem_init+0x1949>
f0102d0b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d0e:	8d 83 79 94 f7 ff    	lea    -0x86b87(%ebx),%eax
f0102d14:	50                   	push   %eax
f0102d15:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102d1b:	50                   	push   %eax
f0102d1c:	68 22 03 00 00       	push   $0x322
f0102d21:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102d27:	50                   	push   %eax
f0102d28:	e8 84 d3 ff ff       	call   f01000b1 <_panic>
			assert(pgdir[i] & PTE_P);
f0102d2d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d30:	8d 83 57 94 f7 ff    	lea    -0x86ba9(%ebx),%eax
f0102d36:	50                   	push   %eax
f0102d37:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102d3d:	50                   	push   %eax
f0102d3e:	68 1b 03 00 00       	push   $0x31b
f0102d43:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102d49:	50                   	push   %eax
f0102d4a:	e8 62 d3 ff ff       	call   f01000b1 <_panic>
				assert(pgdir[i] & PTE_P);
f0102d4f:	8b 14 86             	mov    (%esi,%eax,4),%edx
f0102d52:	f6 c2 01             	test   $0x1,%dl
f0102d55:	74 2b                	je     f0102d82 <mem_init+0x19f0>
				assert(pgdir[i] & PTE_W);
f0102d57:	f6 c2 02             	test   $0x2,%dl
f0102d5a:	0f 85 7b ff ff ff    	jne    f0102cdb <mem_init+0x1949>
f0102d60:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d63:	8d 83 68 94 f7 ff    	lea    -0x86b98(%ebx),%eax
f0102d69:	50                   	push   %eax
f0102d6a:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102d70:	50                   	push   %eax
f0102d71:	68 20 03 00 00       	push   $0x320
f0102d76:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102d7c:	50                   	push   %eax
f0102d7d:	e8 2f d3 ff ff       	call   f01000b1 <_panic>
				assert(pgdir[i] & PTE_P);
f0102d82:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102d85:	8d 83 57 94 f7 ff    	lea    -0x86ba9(%ebx),%eax
f0102d8b:	50                   	push   %eax
f0102d8c:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0102d92:	50                   	push   %eax
f0102d93:	68 1f 03 00 00       	push   $0x31f
f0102d98:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0102d9e:	50                   	push   %eax
f0102d9f:	e8 0d d3 ff ff       	call   f01000b1 <_panic>
	cprintf("check_kern_pgdir() succeeded!\n");
f0102da4:	83 ec 0c             	sub    $0xc,%esp
f0102da7:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102daa:	8d 87 50 90 f7 ff    	lea    -0x86fb0(%edi),%eax
f0102db0:	50                   	push   %eax
f0102db1:	89 fb                	mov    %edi,%ebx
f0102db3:	e8 a0 0d 00 00       	call   f0103b58 <cprintf>
	lcr3(PADDR(kern_pgdir));
f0102db8:	c7 c0 ec ff 18 f0    	mov    $0xf018ffec,%eax
f0102dbe:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f0102dc0:	83 c4 10             	add    $0x10,%esp
f0102dc3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102dc8:	0f 86 44 02 00 00    	jbe    f0103012 <mem_init+0x1c80>
	return (physaddr_t)kva - KERNBASE;
f0102dce:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f0102dd3:	0f 22 d8             	mov    %eax,%cr3
	check_page_free_list(0);
f0102dd6:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ddb:	e8 b1 dd ff ff       	call   f0100b91 <check_page_free_list>
	asm volatile("movl %%cr0,%0" : "=r" (val));
f0102de0:	0f 20 c0             	mov    %cr0,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102de3:	83 e0 f3             	and    $0xfffffff3,%eax
f0102de6:	0d 23 00 05 80       	or     $0x80050023,%eax
	asm volatile("movl %0,%%cr0" : : "r" (val));
f0102deb:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102dee:	83 ec 0c             	sub    $0xc,%esp
f0102df1:	6a 00                	push   $0x0
f0102df3:	e8 2f e2 ff ff       	call   f0101027 <page_alloc>
f0102df8:	89 c6                	mov    %eax,%esi
f0102dfa:	83 c4 10             	add    $0x10,%esp
f0102dfd:	85 c0                	test   %eax,%eax
f0102dff:	0f 84 29 02 00 00    	je     f010302e <mem_init+0x1c9c>
	assert((pp1 = page_alloc(0)));
f0102e05:	83 ec 0c             	sub    $0xc,%esp
f0102e08:	6a 00                	push   $0x0
f0102e0a:	e8 18 e2 ff ff       	call   f0101027 <page_alloc>
f0102e0f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102e12:	83 c4 10             	add    $0x10,%esp
f0102e15:	85 c0                	test   %eax,%eax
f0102e17:	0f 84 33 02 00 00    	je     f0103050 <mem_init+0x1cbe>
	assert((pp2 = page_alloc(0)));
f0102e1d:	83 ec 0c             	sub    $0xc,%esp
f0102e20:	6a 00                	push   $0x0
f0102e22:	e8 00 e2 ff ff       	call   f0101027 <page_alloc>
f0102e27:	89 c7                	mov    %eax,%edi
f0102e29:	83 c4 10             	add    $0x10,%esp
f0102e2c:	85 c0                	test   %eax,%eax
f0102e2e:	0f 84 3e 02 00 00    	je     f0103072 <mem_init+0x1ce0>
	page_free(pp0);
f0102e34:	83 ec 0c             	sub    $0xc,%esp
f0102e37:	56                   	push   %esi
f0102e38:	e8 72 e2 ff ff       	call   f01010af <page_free>
	return (pp - pages) << PGSHIFT;
f0102e3d:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e40:	c7 c0 f0 ff 18 f0    	mov    $0xf018fff0,%eax
f0102e46:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102e49:	2b 08                	sub    (%eax),%ecx
f0102e4b:	89 c8                	mov    %ecx,%eax
f0102e4d:	c1 f8 03             	sar    $0x3,%eax
f0102e50:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102e53:	89 c1                	mov    %eax,%ecx
f0102e55:	c1 e9 0c             	shr    $0xc,%ecx
f0102e58:	83 c4 10             	add    $0x10,%esp
f0102e5b:	c7 c2 e8 ff 18 f0    	mov    $0xf018ffe8,%edx
f0102e61:	3b 0a                	cmp    (%edx),%ecx
f0102e63:	0f 83 2b 02 00 00    	jae    f0103094 <mem_init+0x1d02>
	memset(page2kva(pp1), 1, PGSIZE);
f0102e69:	83 ec 04             	sub    $0x4,%esp
f0102e6c:	68 00 10 00 00       	push   $0x1000
f0102e71:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102e73:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102e78:	50                   	push   %eax
f0102e79:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e7c:	e8 14 22 00 00       	call   f0105095 <memset>
	return (pp - pages) << PGSHIFT;
f0102e81:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102e84:	c7 c0 f0 ff 18 f0    	mov    $0xf018fff0,%eax
f0102e8a:	89 f9                	mov    %edi,%ecx
f0102e8c:	2b 08                	sub    (%eax),%ecx
f0102e8e:	89 c8                	mov    %ecx,%eax
f0102e90:	c1 f8 03             	sar    $0x3,%eax
f0102e93:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102e96:	89 c1                	mov    %eax,%ecx
f0102e98:	c1 e9 0c             	shr    $0xc,%ecx
f0102e9b:	83 c4 10             	add    $0x10,%esp
f0102e9e:	c7 c2 e8 ff 18 f0    	mov    $0xf018ffe8,%edx
f0102ea4:	3b 0a                	cmp    (%edx),%ecx
f0102ea6:	0f 83 fe 01 00 00    	jae    f01030aa <mem_init+0x1d18>
	memset(page2kva(pp2), 2, PGSIZE);
f0102eac:	83 ec 04             	sub    $0x4,%esp
f0102eaf:	68 00 10 00 00       	push   $0x1000
f0102eb4:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102eb6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102ebb:	50                   	push   %eax
f0102ebc:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ebf:	e8 d1 21 00 00       	call   f0105095 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102ec4:	6a 02                	push   $0x2
f0102ec6:	68 00 10 00 00       	push   $0x1000
f0102ecb:	8b 5d d0             	mov    -0x30(%ebp),%ebx
f0102ece:	53                   	push   %ebx
f0102ecf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ed2:	c7 c0 ec ff 18 f0    	mov    $0xf018ffec,%eax
f0102ed8:	ff 30                	pushl  (%eax)
f0102eda:	e8 0f e4 ff ff       	call   f01012ee <page_insert>
	assert(pp1->pp_ref == 1);
f0102edf:	83 c4 20             	add    $0x20,%esp
f0102ee2:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102ee7:	0f 85 d3 01 00 00    	jne    f01030c0 <mem_init+0x1d2e>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102eed:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102ef4:	01 01 01 
f0102ef7:	0f 85 e5 01 00 00    	jne    f01030e2 <mem_init+0x1d50>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102efd:	6a 02                	push   $0x2
f0102eff:	68 00 10 00 00       	push   $0x1000
f0102f04:	57                   	push   %edi
f0102f05:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102f08:	c7 c0 ec ff 18 f0    	mov    $0xf018ffec,%eax
f0102f0e:	ff 30                	pushl  (%eax)
f0102f10:	e8 d9 e3 ff ff       	call   f01012ee <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102f15:	83 c4 10             	add    $0x10,%esp
f0102f18:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102f1f:	02 02 02 
f0102f22:	0f 85 dc 01 00 00    	jne    f0103104 <mem_init+0x1d72>
	assert(pp2->pp_ref == 1);
f0102f28:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102f2d:	0f 85 f3 01 00 00    	jne    f0103126 <mem_init+0x1d94>
	assert(pp1->pp_ref == 0);
f0102f33:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102f36:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0102f3b:	0f 85 07 02 00 00    	jne    f0103148 <mem_init+0x1db6>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102f41:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102f48:	03 03 03 
	return (pp - pages) << PGSHIFT;
f0102f4b:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102f4e:	c7 c0 f0 ff 18 f0    	mov    $0xf018fff0,%eax
f0102f54:	89 f9                	mov    %edi,%ecx
f0102f56:	2b 08                	sub    (%eax),%ecx
f0102f58:	89 c8                	mov    %ecx,%eax
f0102f5a:	c1 f8 03             	sar    $0x3,%eax
f0102f5d:	c1 e0 0c             	shl    $0xc,%eax
	if (PGNUM(pa) >= npages)
f0102f60:	89 c1                	mov    %eax,%ecx
f0102f62:	c1 e9 0c             	shr    $0xc,%ecx
f0102f65:	c7 c2 e8 ff 18 f0    	mov    $0xf018ffe8,%edx
f0102f6b:	3b 0a                	cmp    (%edx),%ecx
f0102f6d:	0f 83 f7 01 00 00    	jae    f010316a <mem_init+0x1dd8>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102f73:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102f7a:	03 03 03 
f0102f7d:	0f 85 fd 01 00 00    	jne    f0103180 <mem_init+0x1dee>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102f83:	83 ec 08             	sub    $0x8,%esp
f0102f86:	68 00 10 00 00       	push   $0x1000
f0102f8b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102f8e:	c7 c0 ec ff 18 f0    	mov    $0xf018ffec,%eax
f0102f94:	ff 30                	pushl  (%eax)
f0102f96:	e8 06 e3 ff ff       	call   f01012a1 <page_remove>
	assert(pp2->pp_ref == 0);
f0102f9b:	83 c4 10             	add    $0x10,%esp
f0102f9e:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102fa3:	0f 85 f9 01 00 00    	jne    f01031a2 <mem_init+0x1e10>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102fa9:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102fac:	c7 c0 ec ff 18 f0    	mov    $0xf018ffec,%eax
f0102fb2:	8b 08                	mov    (%eax),%ecx
f0102fb4:	8b 11                	mov    (%ecx),%edx
f0102fb6:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	return (pp - pages) << PGSHIFT;
f0102fbc:	c7 c0 f0 ff 18 f0    	mov    $0xf018fff0,%eax
f0102fc2:	89 f7                	mov    %esi,%edi
f0102fc4:	2b 38                	sub    (%eax),%edi
f0102fc6:	89 f8                	mov    %edi,%eax
f0102fc8:	c1 f8 03             	sar    $0x3,%eax
f0102fcb:	c1 e0 0c             	shl    $0xc,%eax
f0102fce:	39 c2                	cmp    %eax,%edx
f0102fd0:	0f 85 ee 01 00 00    	jne    f01031c4 <mem_init+0x1e32>
	kern_pgdir[0] = 0;
f0102fd6:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102fdc:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102fe1:	0f 85 ff 01 00 00    	jne    f01031e6 <mem_init+0x1e54>
	pp0->pp_ref = 0;
f0102fe7:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102fed:	83 ec 0c             	sub    $0xc,%esp
f0102ff0:	56                   	push   %esi
f0102ff1:	e8 b9 e0 ff ff       	call   f01010af <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102ff6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0102ff9:	8d 83 e4 90 f7 ff    	lea    -0x86f1c(%ebx),%eax
f0102fff:	89 04 24             	mov    %eax,(%esp)
f0103002:	e8 51 0b 00 00       	call   f0103b58 <cprintf>
}
f0103007:	83 c4 10             	add    $0x10,%esp
f010300a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010300d:	5b                   	pop    %ebx
f010300e:	5e                   	pop    %esi
f010300f:	5f                   	pop    %edi
f0103010:	5d                   	pop    %ebp
f0103011:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103012:	50                   	push   %eax
f0103013:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103016:	8d 83 cc 8a f7 ff    	lea    -0x87534(%ebx),%eax
f010301c:	50                   	push   %eax
f010301d:	68 ec 00 00 00       	push   $0xec
f0103022:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0103028:	50                   	push   %eax
f0103029:	e8 83 d0 ff ff       	call   f01000b1 <_panic>
	assert((pp0 = page_alloc(0)));
f010302e:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103031:	8d 83 75 92 f7 ff    	lea    -0x86d8b(%ebx),%eax
f0103037:	50                   	push   %eax
f0103038:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f010303e:	50                   	push   %eax
f010303f:	68 e2 03 00 00       	push   $0x3e2
f0103044:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f010304a:	50                   	push   %eax
f010304b:	e8 61 d0 ff ff       	call   f01000b1 <_panic>
	assert((pp1 = page_alloc(0)));
f0103050:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103053:	8d 83 8b 92 f7 ff    	lea    -0x86d75(%ebx),%eax
f0103059:	50                   	push   %eax
f010305a:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0103060:	50                   	push   %eax
f0103061:	68 e3 03 00 00       	push   $0x3e3
f0103066:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f010306c:	50                   	push   %eax
f010306d:	e8 3f d0 ff ff       	call   f01000b1 <_panic>
	assert((pp2 = page_alloc(0)));
f0103072:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103075:	8d 83 a1 92 f7 ff    	lea    -0x86d5f(%ebx),%eax
f010307b:	50                   	push   %eax
f010307c:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0103082:	50                   	push   %eax
f0103083:	68 e4 03 00 00       	push   $0x3e4
f0103088:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f010308e:	50                   	push   %eax
f010308f:	e8 1d d0 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103094:	50                   	push   %eax
f0103095:	8d 83 64 89 f7 ff    	lea    -0x8769c(%ebx),%eax
f010309b:	50                   	push   %eax
f010309c:	6a 56                	push   $0x56
f010309e:	8d 83 99 91 f7 ff    	lea    -0x86e67(%ebx),%eax
f01030a4:	50                   	push   %eax
f01030a5:	e8 07 d0 ff ff       	call   f01000b1 <_panic>
f01030aa:	50                   	push   %eax
f01030ab:	8d 83 64 89 f7 ff    	lea    -0x8769c(%ebx),%eax
f01030b1:	50                   	push   %eax
f01030b2:	6a 56                	push   $0x56
f01030b4:	8d 83 99 91 f7 ff    	lea    -0x86e67(%ebx),%eax
f01030ba:	50                   	push   %eax
f01030bb:	e8 f1 cf ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 1);
f01030c0:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01030c3:	8d 83 72 93 f7 ff    	lea    -0x86c8e(%ebx),%eax
f01030c9:	50                   	push   %eax
f01030ca:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01030d0:	50                   	push   %eax
f01030d1:	68 e9 03 00 00       	push   $0x3e9
f01030d6:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01030dc:	50                   	push   %eax
f01030dd:	e8 cf cf ff ff       	call   f01000b1 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01030e2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01030e5:	8d 83 70 90 f7 ff    	lea    -0x86f90(%ebx),%eax
f01030eb:	50                   	push   %eax
f01030ec:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01030f2:	50                   	push   %eax
f01030f3:	68 ea 03 00 00       	push   $0x3ea
f01030f8:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01030fe:	50                   	push   %eax
f01030ff:	e8 ad cf ff ff       	call   f01000b1 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0103104:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103107:	8d 83 94 90 f7 ff    	lea    -0x86f6c(%ebx),%eax
f010310d:	50                   	push   %eax
f010310e:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0103114:	50                   	push   %eax
f0103115:	68 ec 03 00 00       	push   $0x3ec
f010311a:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0103120:	50                   	push   %eax
f0103121:	e8 8b cf ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 1);
f0103126:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103129:	8d 83 94 93 f7 ff    	lea    -0x86c6c(%ebx),%eax
f010312f:	50                   	push   %eax
f0103130:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0103136:	50                   	push   %eax
f0103137:	68 ed 03 00 00       	push   $0x3ed
f010313c:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0103142:	50                   	push   %eax
f0103143:	e8 69 cf ff ff       	call   f01000b1 <_panic>
	assert(pp1->pp_ref == 0);
f0103148:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f010314b:	8d 83 fe 93 f7 ff    	lea    -0x86c02(%ebx),%eax
f0103151:	50                   	push   %eax
f0103152:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0103158:	50                   	push   %eax
f0103159:	68 ee 03 00 00       	push   $0x3ee
f010315e:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0103164:	50                   	push   %eax
f0103165:	e8 47 cf ff ff       	call   f01000b1 <_panic>
f010316a:	50                   	push   %eax
f010316b:	8d 83 64 89 f7 ff    	lea    -0x8769c(%ebx),%eax
f0103171:	50                   	push   %eax
f0103172:	6a 56                	push   $0x56
f0103174:	8d 83 99 91 f7 ff    	lea    -0x86e67(%ebx),%eax
f010317a:	50                   	push   %eax
f010317b:	e8 31 cf ff ff       	call   f01000b1 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0103180:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0103183:	8d 83 b8 90 f7 ff    	lea    -0x86f48(%ebx),%eax
f0103189:	50                   	push   %eax
f010318a:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0103190:	50                   	push   %eax
f0103191:	68 f0 03 00 00       	push   $0x3f0
f0103196:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f010319c:	50                   	push   %eax
f010319d:	e8 0f cf ff ff       	call   f01000b1 <_panic>
	assert(pp2->pp_ref == 0);
f01031a2:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01031a5:	8d 83 cc 93 f7 ff    	lea    -0x86c34(%ebx),%eax
f01031ab:	50                   	push   %eax
f01031ac:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01031b2:	50                   	push   %eax
f01031b3:	68 f2 03 00 00       	push   $0x3f2
f01031b8:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01031be:	50                   	push   %eax
f01031bf:	e8 ed ce ff ff       	call   f01000b1 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01031c4:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01031c7:	8d 83 c8 8b f7 ff    	lea    -0x87438(%ebx),%eax
f01031cd:	50                   	push   %eax
f01031ce:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01031d4:	50                   	push   %eax
f01031d5:	68 f5 03 00 00       	push   $0x3f5
f01031da:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f01031e0:	50                   	push   %eax
f01031e1:	e8 cb ce ff ff       	call   f01000b1 <_panic>
	assert(pp0->pp_ref == 1);
f01031e6:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01031e9:	8d 83 83 93 f7 ff    	lea    -0x86c7d(%ebx),%eax
f01031ef:	50                   	push   %eax
f01031f0:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01031f6:	50                   	push   %eax
f01031f7:	68 f7 03 00 00       	push   $0x3f7
f01031fc:	8d 83 8d 91 f7 ff    	lea    -0x86e73(%ebx),%eax
f0103202:	50                   	push   %eax
f0103203:	e8 a9 ce ff ff       	call   f01000b1 <_panic>

f0103208 <tlb_invalidate>:
{
f0103208:	55                   	push   %ebp
f0103209:	89 e5                	mov    %esp,%ebp
	asm volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010320b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010320e:	0f 01 38             	invlpg (%eax)
}
f0103211:	5d                   	pop    %ebp
f0103212:	c3                   	ret    

f0103213 <user_mem_check>:
{
f0103213:	55                   	push   %ebp
f0103214:	89 e5                	mov    %esp,%ebp
f0103216:	57                   	push   %edi
f0103217:	56                   	push   %esi
f0103218:	53                   	push   %ebx
f0103219:	83 ec 20             	sub    $0x20,%esp
f010321c:	e8 46 cf ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103221:	81 c3 ff 9d 08 00    	add    $0x89dff,%ebx
f0103227:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
f010322a:	8b 75 14             	mov    0x14(%ebp),%esi
    	cprintf("user_mem_check va: %x, len: %x\n", va, len);
f010322d:	ff 75 10             	pushl  0x10(%ebp)
f0103230:	ff 75 0c             	pushl  0xc(%ebp)
f0103233:	8d 83 10 91 f7 ff    	lea    -0x86ef0(%ebx),%eax
f0103239:	50                   	push   %eax
f010323a:	e8 19 09 00 00       	call   f0103b58 <cprintf>
    	uint32_t begin = (uint32_t) ROUNDDOWN(va, PGSIZE); 
f010323f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103242:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
    	uint32_t end = (uint32_t) ROUNDUP(va+len, PGSIZE);
f0103248:	8b 45 0c             	mov    0xc(%ebp),%eax
f010324b:	8b 55 10             	mov    0x10(%ebp),%edx
f010324e:	8d bc 10 ff 0f 00 00 	lea    0xfff(%eax,%edx,1),%edi
f0103255:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
    	for (i = (uint32_t)begin; i < end; i += PGSIZE) {
f010325b:	83 c4 10             	add    $0x10,%esp
f010325e:	39 fb                	cmp    %edi,%ebx
f0103260:	73 51                	jae    f01032b3 <user_mem_check+0xa0>
        	pte_t *pte = pgdir_walk(env->env_pgdir, (void*)i, 0);
f0103262:	83 ec 04             	sub    $0x4,%esp
f0103265:	6a 00                	push   $0x0
f0103267:	53                   	push   %ebx
f0103268:	8b 45 08             	mov    0x8(%ebp),%eax
f010326b:	ff 70 5c             	pushl  0x5c(%eax)
f010326e:	e8 b4 de ff ff       	call   f0101127 <pgdir_walk>
        	if ((i >= ULIM) || !pte || !(*pte & PTE_P) || ((*pte & perm) != perm)) {        
f0103273:	83 c4 10             	add    $0x10,%esp
f0103276:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f010327c:	77 18                	ja     f0103296 <user_mem_check+0x83>
f010327e:	85 c0                	test   %eax,%eax
f0103280:	74 14                	je     f0103296 <user_mem_check+0x83>
f0103282:	8b 00                	mov    (%eax),%eax
f0103284:	a8 01                	test   $0x1,%al
f0103286:	74 0e                	je     f0103296 <user_mem_check+0x83>
f0103288:	21 f0                	and    %esi,%eax
f010328a:	39 c6                	cmp    %eax,%esi
f010328c:	75 08                	jne    f0103296 <user_mem_check+0x83>
    	for (i = (uint32_t)begin; i < end; i += PGSIZE) {
f010328e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0103294:	eb c8                	jmp    f010325e <user_mem_check+0x4b>
            		user_mem_check_addr = (i < (uint32_t)va ? (uint32_t)va : i);
f0103296:	3b 5d 0c             	cmp    0xc(%ebp),%ebx
f0103299:	0f 42 5d 0c          	cmovb  0xc(%ebp),%ebx
f010329d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01032a0:	89 98 fc 22 00 00    	mov    %ebx,0x22fc(%eax)
            	return -E_FAULT;
f01032a6:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
}
f01032ab:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01032ae:	5b                   	pop    %ebx
f01032af:	5e                   	pop    %esi
f01032b0:	5f                   	pop    %edi
f01032b1:	5d                   	pop    %ebp
f01032b2:	c3                   	ret    
    	cprintf("user_mem_check success va: %x, len: %x\n", va, len);
f01032b3:	83 ec 04             	sub    $0x4,%esp
f01032b6:	ff 75 10             	pushl  0x10(%ebp)
f01032b9:	ff 75 0c             	pushl  0xc(%ebp)
f01032bc:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01032bf:	8d 83 30 91 f7 ff    	lea    -0x86ed0(%ebx),%eax
f01032c5:	50                   	push   %eax
f01032c6:	e8 8d 08 00 00       	call   f0103b58 <cprintf>
	return 0;
f01032cb:	83 c4 10             	add    $0x10,%esp
f01032ce:	b8 00 00 00 00       	mov    $0x0,%eax
f01032d3:	eb d6                	jmp    f01032ab <user_mem_check+0x98>

f01032d5 <user_mem_assert>:
{
f01032d5:	55                   	push   %ebp
f01032d6:	89 e5                	mov    %esp,%ebp
f01032d8:	56                   	push   %esi
f01032d9:	53                   	push   %ebx
f01032da:	e8 88 ce ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01032df:	81 c3 41 9d 08 00    	add    $0x89d41,%ebx
f01032e5:	8b 75 08             	mov    0x8(%ebp),%esi
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f01032e8:	8b 45 14             	mov    0x14(%ebp),%eax
f01032eb:	83 c8 04             	or     $0x4,%eax
f01032ee:	50                   	push   %eax
f01032ef:	ff 75 10             	pushl  0x10(%ebp)
f01032f2:	ff 75 0c             	pushl  0xc(%ebp)
f01032f5:	56                   	push   %esi
f01032f6:	e8 18 ff ff ff       	call   f0103213 <user_mem_check>
f01032fb:	83 c4 10             	add    $0x10,%esp
f01032fe:	85 c0                	test   %eax,%eax
f0103300:	78 07                	js     f0103309 <user_mem_assert+0x34>
}
f0103302:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103305:	5b                   	pop    %ebx
f0103306:	5e                   	pop    %esi
f0103307:	5d                   	pop    %ebp
f0103308:	c3                   	ret    
		cprintf("[%08x] user_mem_check assertion failure for "
f0103309:	83 ec 04             	sub    $0x4,%esp
f010330c:	ff b3 fc 22 00 00    	pushl  0x22fc(%ebx)
f0103312:	ff 76 48             	pushl  0x48(%esi)
f0103315:	8d 83 58 91 f7 ff    	lea    -0x86ea8(%ebx),%eax
f010331b:	50                   	push   %eax
f010331c:	e8 37 08 00 00       	call   f0103b58 <cprintf>
		env_destroy(env);	// may not return
f0103321:	89 34 24             	mov    %esi,(%esp)
f0103324:	e8 c5 06 00 00       	call   f01039ee <env_destroy>
f0103329:	83 c4 10             	add    $0x10,%esp
}
f010332c:	eb d4                	jmp    f0103302 <user_mem_assert+0x2d>

f010332e <__x86.get_pc_thunk.dx>:
f010332e:	8b 14 24             	mov    (%esp),%edx
f0103331:	c3                   	ret    

f0103332 <__x86.get_pc_thunk.cx>:
f0103332:	8b 0c 24             	mov    (%esp),%ecx
f0103335:	c3                   	ret    

f0103336 <__x86.get_pc_thunk.si>:
f0103336:	8b 34 24             	mov    (%esp),%esi
f0103339:	c3                   	ret    

f010333a <__x86.get_pc_thunk.di>:
f010333a:	8b 3c 24             	mov    (%esp),%edi
f010333d:	c3                   	ret    

f010333e <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f010333e:	55                   	push   %ebp
f010333f:	89 e5                	mov    %esp,%ebp
f0103341:	57                   	push   %edi
f0103342:	56                   	push   %esi
f0103343:	53                   	push   %ebx
f0103344:	83 ec 1c             	sub    $0x1c,%esp
f0103347:	e8 1b ce ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f010334c:	81 c3 d4 9c 08 00    	add    $0x89cd4,%ebx
f0103352:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	void* start = (void *)ROUNDDOWN((uint32_t)va, PGSIZE);
f0103354:	89 d6                	mov    %edx,%esi
f0103356:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
    	void* end = (void *)ROUNDUP((uint32_t)va+len, PGSIZE);
f010335c:	8d 84 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%eax
f0103363:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0103368:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    	struct PageInfo *p = NULL;
    	void* i;
    	int r;
    	for(i = start; i < end; i += PGSIZE){
f010336b:	3b 75 e4             	cmp    -0x1c(%ebp),%esi
f010336e:	73 62                	jae    f01033d2 <region_alloc+0x94>
        	p = page_alloc(0);
f0103370:	83 ec 0c             	sub    $0xc,%esp
f0103373:	6a 00                	push   $0x0
f0103375:	e8 ad dc ff ff       	call   f0101027 <page_alloc>
        	if(p == NULL)
f010337a:	83 c4 10             	add    $0x10,%esp
f010337d:	85 c0                	test   %eax,%eax
f010337f:	74 1b                	je     f010339c <region_alloc+0x5e>
           		panic(" region alloc failed: allocation failed.\n");

        	r = page_insert(e->env_pgdir, p, i, PTE_W | PTE_U);
f0103381:	6a 06                	push   $0x6
f0103383:	56                   	push   %esi
f0103384:	50                   	push   %eax
f0103385:	ff 77 5c             	pushl  0x5c(%edi)
f0103388:	e8 61 df ff ff       	call   f01012ee <page_insert>
        	if(r != 0)
f010338d:	83 c4 10             	add    $0x10,%esp
f0103390:	85 c0                	test   %eax,%eax
f0103392:	75 23                	jne    f01033b7 <region_alloc+0x79>
    	for(i = start; i < end; i += PGSIZE){
f0103394:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010339a:	eb cf                	jmp    f010336b <region_alloc+0x2d>
           		panic(" region alloc failed: allocation failed.\n");
f010339c:	83 ec 04             	sub    $0x4,%esp
f010339f:	8d 83 88 94 f7 ff    	lea    -0x86b78(%ebx),%eax
f01033a5:	50                   	push   %eax
f01033a6:	68 23 01 00 00       	push   $0x123
f01033ab:	8d 83 7a 95 f7 ff    	lea    -0x86a86(%ebx),%eax
f01033b1:	50                   	push   %eax
f01033b2:	e8 fa cc ff ff       	call   f01000b1 <_panic>
            		panic("region alloc failed.\n");
f01033b7:	83 ec 04             	sub    $0x4,%esp
f01033ba:	8d 83 85 95 f7 ff    	lea    -0x86a7b(%ebx),%eax
f01033c0:	50                   	push   %eax
f01033c1:	68 27 01 00 00       	push   $0x127
f01033c6:	8d 83 7a 95 f7 ff    	lea    -0x86a86(%ebx),%eax
f01033cc:	50                   	push   %eax
f01033cd:	e8 df cc ff ff       	call   f01000b1 <_panic>
    	}
}
f01033d2:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01033d5:	5b                   	pop    %ebx
f01033d6:	5e                   	pop    %esi
f01033d7:	5f                   	pop    %edi
f01033d8:	5d                   	pop    %ebp
f01033d9:	c3                   	ret    

f01033da <envid2env>:
{
f01033da:	55                   	push   %ebp
f01033db:	89 e5                	mov    %esp,%ebp
f01033dd:	53                   	push   %ebx
f01033de:	e8 4f ff ff ff       	call   f0103332 <__x86.get_pc_thunk.cx>
f01033e3:	81 c1 3d 9c 08 00    	add    $0x89c3d,%ecx
f01033e9:	8b 55 08             	mov    0x8(%ebp),%edx
f01033ec:	8b 5d 10             	mov    0x10(%ebp),%ebx
	if (envid == 0) {
f01033ef:	85 d2                	test   %edx,%edx
f01033f1:	74 41                	je     f0103434 <envid2env+0x5a>
	e = &envs[ENVX(envid)];
f01033f3:	89 d0                	mov    %edx,%eax
f01033f5:	25 ff 03 00 00       	and    $0x3ff,%eax
f01033fa:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01033fd:	c1 e0 05             	shl    $0x5,%eax
f0103400:	03 81 0c 23 00 00    	add    0x230c(%ecx),%eax
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103406:	83 78 54 00          	cmpl   $0x0,0x54(%eax)
f010340a:	74 3a                	je     f0103446 <envid2env+0x6c>
f010340c:	39 50 48             	cmp    %edx,0x48(%eax)
f010340f:	75 35                	jne    f0103446 <envid2env+0x6c>
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0103411:	84 db                	test   %bl,%bl
f0103413:	74 12                	je     f0103427 <envid2env+0x4d>
f0103415:	8b 91 08 23 00 00    	mov    0x2308(%ecx),%edx
f010341b:	39 c2                	cmp    %eax,%edx
f010341d:	74 08                	je     f0103427 <envid2env+0x4d>
f010341f:	8b 5a 48             	mov    0x48(%edx),%ebx
f0103422:	39 58 4c             	cmp    %ebx,0x4c(%eax)
f0103425:	75 2f                	jne    f0103456 <envid2env+0x7c>
	*env_store = e;
f0103427:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010342a:	89 03                	mov    %eax,(%ebx)
	return 0;
f010342c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103431:	5b                   	pop    %ebx
f0103432:	5d                   	pop    %ebp
f0103433:	c3                   	ret    
		*env_store = curenv;
f0103434:	8b 81 08 23 00 00    	mov    0x2308(%ecx),%eax
f010343a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010343d:	89 01                	mov    %eax,(%ecx)
		return 0;
f010343f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103444:	eb eb                	jmp    f0103431 <envid2env+0x57>
		*env_store = 0;
f0103446:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103449:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010344f:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103454:	eb db                	jmp    f0103431 <envid2env+0x57>
		*env_store = 0;
f0103456:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103459:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010345f:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103464:	eb cb                	jmp    f0103431 <envid2env+0x57>

f0103466 <env_init_percpu>:
{
f0103466:	55                   	push   %ebp
f0103467:	89 e5                	mov    %esp,%ebp
f0103469:	e8 9b d2 ff ff       	call   f0100709 <__x86.get_pc_thunk.ax>
f010346e:	05 b2 9b 08 00       	add    $0x89bb2,%eax
	asm volatile("lgdt (%0)" : : "r" (p));
f0103473:	8d 80 e0 1f 00 00    	lea    0x1fe0(%eax),%eax
f0103479:	0f 01 10             	lgdtl  (%eax)
	asm volatile("movw %%ax,%%gs" : : "a" (GD_UD|3));
f010347c:	b8 23 00 00 00       	mov    $0x23,%eax
f0103481:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" : : "a" (GD_UD|3));
f0103483:	8e e0                	mov    %eax,%fs
	asm volatile("movw %%ax,%%es" : : "a" (GD_KD));
f0103485:	b8 10 00 00 00       	mov    $0x10,%eax
f010348a:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" : : "a" (GD_KD));
f010348c:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" : : "a" (GD_KD));
f010348e:	8e d0                	mov    %eax,%ss
	asm volatile("ljmp %0,$1f\n 1:\n" : : "i" (GD_KT));
f0103490:	ea 97 34 10 f0 08 00 	ljmp   $0x8,$0xf0103497
	asm volatile("lldt %0" : : "r" (sel));
f0103497:	b8 00 00 00 00       	mov    $0x0,%eax
f010349c:	0f 00 d0             	lldt   %ax
}
f010349f:	5d                   	pop    %ebp
f01034a0:	c3                   	ret    

f01034a1 <env_init>:
{
f01034a1:	55                   	push   %ebp
f01034a2:	89 e5                	mov    %esp,%ebp
f01034a4:	57                   	push   %edi
f01034a5:	56                   	push   %esi
f01034a6:	53                   	push   %ebx
f01034a7:	e8 8e fe ff ff       	call   f010333a <__x86.get_pc_thunk.di>
f01034ac:	81 c7 74 9b 08 00    	add    $0x89b74,%edi
        	envs[i].env_id = 0;
f01034b2:	8b b7 0c 23 00 00    	mov    0x230c(%edi),%esi
f01034b8:	8d 86 a0 7f 01 00    	lea    0x17fa0(%esi),%eax
f01034be:	8d 5e a0             	lea    -0x60(%esi),%ebx
f01034c1:	ba 00 00 00 00       	mov    $0x0,%edx
f01034c6:	89 c1                	mov    %eax,%ecx
f01034c8:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
        	envs[i].env_status = ENV_FREE;
f01034cf:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
        	envs[i].env_link = env_free_list;
f01034d6:	89 50 44             	mov    %edx,0x44(%eax)
f01034d9:	83 e8 60             	sub    $0x60,%eax
        	env_free_list = &envs[i];
f01034dc:	89 ca                	mov    %ecx,%edx
    	for (i=NENV-1; i>=0; i--){
f01034de:	39 d8                	cmp    %ebx,%eax
f01034e0:	75 e4                	jne    f01034c6 <env_init+0x25>
f01034e2:	89 b7 10 23 00 00    	mov    %esi,0x2310(%edi)
	env_init_percpu();
f01034e8:	e8 79 ff ff ff       	call   f0103466 <env_init_percpu>
}
f01034ed:	5b                   	pop    %ebx
f01034ee:	5e                   	pop    %esi
f01034ef:	5f                   	pop    %edi
f01034f0:	5d                   	pop    %ebp
f01034f1:	c3                   	ret    

f01034f2 <env_alloc>:
{
f01034f2:	55                   	push   %ebp
f01034f3:	89 e5                	mov    %esp,%ebp
f01034f5:	57                   	push   %edi
f01034f6:	56                   	push   %esi
f01034f7:	53                   	push   %ebx
f01034f8:	83 ec 0c             	sub    $0xc,%esp
f01034fb:	e8 67 cc ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103500:	81 c3 20 9b 08 00    	add    $0x89b20,%ebx
	if (!(e = env_free_list))
f0103506:	8b b3 10 23 00 00    	mov    0x2310(%ebx),%esi
f010350c:	85 f6                	test   %esi,%esi
f010350e:	0f 84 81 01 00 00    	je     f0103695 <env_alloc+0x1a3>
	if (!(p = page_alloc(ALLOC_ZERO)))
f0103514:	83 ec 0c             	sub    $0xc,%esp
f0103517:	6a 01                	push   $0x1
f0103519:	e8 09 db ff ff       	call   f0101027 <page_alloc>
f010351e:	83 c4 10             	add    $0x10,%esp
f0103521:	85 c0                	test   %eax,%eax
f0103523:	0f 84 73 01 00 00    	je     f010369c <env_alloc+0x1aa>
	return (pp - pages) << PGSHIFT;
f0103529:	c7 c2 f0 ff 18 f0    	mov    $0xf018fff0,%edx
f010352f:	89 c7                	mov    %eax,%edi
f0103531:	2b 3a                	sub    (%edx),%edi
f0103533:	89 fa                	mov    %edi,%edx
f0103535:	c1 fa 03             	sar    $0x3,%edx
f0103538:	c1 e2 0c             	shl    $0xc,%edx
	if (PGNUM(pa) >= npages)
f010353b:	89 d7                	mov    %edx,%edi
f010353d:	c1 ef 0c             	shr    $0xc,%edi
f0103540:	c7 c1 e8 ff 18 f0    	mov    $0xf018ffe8,%ecx
f0103546:	3b 39                	cmp    (%ecx),%edi
f0103548:	0f 83 18 01 00 00    	jae    f0103666 <env_alloc+0x174>
	return (void *)(pa + KERNBASE);
f010354e:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0103554:	89 56 5c             	mov    %edx,0x5c(%esi)
     	p->pp_ref++;
f0103557:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
f010355c:	b8 00 00 00 00       	mov    $0x0,%eax
         	e->env_pgdir[i] = 0; 
f0103561:	8b 56 5c             	mov    0x5c(%esi),%edx
f0103564:	c7 04 02 00 00 00 00 	movl   $0x0,(%edx,%eax,1)
f010356b:	83 c0 04             	add    $0x4,%eax
     	for (i = 0; i < PDX(UTOP); i++)
f010356e:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f0103573:	75 ec                	jne    f0103561 <env_alloc+0x6f>
         	e->env_pgdir[i] = kern_pgdir[i];
f0103575:	c7 c7 ec ff 18 f0    	mov    $0xf018ffec,%edi
f010357b:	8b 17                	mov    (%edi),%edx
f010357d:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f0103580:	8b 56 5c             	mov    0x5c(%esi),%edx
f0103583:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f0103586:	83 c0 04             	add    $0x4,%eax
	for (i = PDX(UTOP); i < NPDENTRIES; i++) {
f0103589:	3d 00 10 00 00       	cmp    $0x1000,%eax
f010358e:	75 eb                	jne    f010357b <env_alloc+0x89>
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0103590:	8b 46 5c             	mov    0x5c(%esi),%eax
	if ((uint32_t)kva < KERNBASE)
f0103593:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103598:	0f 86 de 00 00 00    	jbe    f010367c <env_alloc+0x18a>
	return (physaddr_t)kva - KERNBASE;
f010359e:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01035a4:	83 ca 05             	or     $0x5,%edx
f01035a7:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01035ad:	8b 46 48             	mov    0x48(%esi),%eax
f01035b0:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01035b5:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f01035ba:	ba 00 10 00 00       	mov    $0x1000,%edx
f01035bf:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01035c2:	89 f2                	mov    %esi,%edx
f01035c4:	2b 93 0c 23 00 00    	sub    0x230c(%ebx),%edx
f01035ca:	c1 fa 05             	sar    $0x5,%edx
f01035cd:	69 d2 ab aa aa aa    	imul   $0xaaaaaaab,%edx,%edx
f01035d3:	09 d0                	or     %edx,%eax
f01035d5:	89 46 48             	mov    %eax,0x48(%esi)
	e->env_parent_id = parent_id;
f01035d8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01035db:	89 46 4c             	mov    %eax,0x4c(%esi)
	e->env_type = ENV_TYPE_USER;
f01035de:	c7 46 50 00 00 00 00 	movl   $0x0,0x50(%esi)
	e->env_status = ENV_RUNNABLE;
f01035e5:	c7 46 54 02 00 00 00 	movl   $0x2,0x54(%esi)
	e->env_runs = 0;
f01035ec:	c7 46 58 00 00 00 00 	movl   $0x0,0x58(%esi)
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f01035f3:	83 ec 04             	sub    $0x4,%esp
f01035f6:	6a 44                	push   $0x44
f01035f8:	6a 00                	push   $0x0
f01035fa:	56                   	push   %esi
f01035fb:	e8 95 1a 00 00       	call   f0105095 <memset>
	e->env_tf.tf_ds = GD_UD | 3;
f0103600:	66 c7 46 24 23 00    	movw   $0x23,0x24(%esi)
	e->env_tf.tf_es = GD_UD | 3;
f0103606:	66 c7 46 20 23 00    	movw   $0x23,0x20(%esi)
	e->env_tf.tf_ss = GD_UD | 3;
f010360c:	66 c7 46 40 23 00    	movw   $0x23,0x40(%esi)
	e->env_tf.tf_esp = USTACKTOP;
f0103612:	c7 46 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%esi)
	e->env_tf.tf_cs = GD_UT | 3;
f0103619:	66 c7 46 34 1b 00    	movw   $0x1b,0x34(%esi)
	env_free_list = e->env_link;
f010361f:	8b 46 44             	mov    0x44(%esi),%eax
f0103622:	89 83 10 23 00 00    	mov    %eax,0x2310(%ebx)
	*newenv_store = e;
f0103628:	8b 45 08             	mov    0x8(%ebp),%eax
f010362b:	89 30                	mov    %esi,(%eax)
	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f010362d:	8b 4e 48             	mov    0x48(%esi),%ecx
f0103630:	8b 83 08 23 00 00    	mov    0x2308(%ebx),%eax
f0103636:	83 c4 10             	add    $0x10,%esp
f0103639:	ba 00 00 00 00       	mov    $0x0,%edx
f010363e:	85 c0                	test   %eax,%eax
f0103640:	74 03                	je     f0103645 <env_alloc+0x153>
f0103642:	8b 50 48             	mov    0x48(%eax),%edx
f0103645:	83 ec 04             	sub    $0x4,%esp
f0103648:	51                   	push   %ecx
f0103649:	52                   	push   %edx
f010364a:	8d 83 9b 95 f7 ff    	lea    -0x86a65(%ebx),%eax
f0103650:	50                   	push   %eax
f0103651:	e8 02 05 00 00       	call   f0103b58 <cprintf>
	return 0;
f0103656:	83 c4 10             	add    $0x10,%esp
f0103659:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010365e:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103661:	5b                   	pop    %ebx
f0103662:	5e                   	pop    %esi
f0103663:	5f                   	pop    %edi
f0103664:	5d                   	pop    %ebp
f0103665:	c3                   	ret    
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103666:	52                   	push   %edx
f0103667:	8d 83 64 89 f7 ff    	lea    -0x8769c(%ebx),%eax
f010366d:	50                   	push   %eax
f010366e:	6a 56                	push   $0x56
f0103670:	8d 83 99 91 f7 ff    	lea    -0x86e67(%ebx),%eax
f0103676:	50                   	push   %eax
f0103677:	e8 35 ca ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010367c:	50                   	push   %eax
f010367d:	8d 83 cc 8a f7 ff    	lea    -0x87534(%ebx),%eax
f0103683:	50                   	push   %eax
f0103684:	68 c6 00 00 00       	push   $0xc6
f0103689:	8d 83 7a 95 f7 ff    	lea    -0x86a86(%ebx),%eax
f010368f:	50                   	push   %eax
f0103690:	e8 1c ca ff ff       	call   f01000b1 <_panic>
		return -E_NO_FREE_ENV;
f0103695:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f010369a:	eb c2                	jmp    f010365e <env_alloc+0x16c>
		return -E_NO_MEM;
f010369c:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f01036a1:	eb bb                	jmp    f010365e <env_alloc+0x16c>

f01036a3 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f01036a3:	55                   	push   %ebp
f01036a4:	89 e5                	mov    %esp,%ebp
f01036a6:	57                   	push   %edi
f01036a7:	56                   	push   %esi
f01036a8:	53                   	push   %ebx
f01036a9:	83 ec 34             	sub    $0x34,%esp
f01036ac:	e8 b6 ca ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01036b1:	81 c3 6f 99 08 00    	add    $0x8996f,%ebx
	// LAB 3: Your code here.
	struct Env *e;
    	int rc;
    	if ((rc = env_alloc(&e, 0)) != 0)
f01036b7:	6a 00                	push   $0x0
f01036b9:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01036bc:	50                   	push   %eax
f01036bd:	e8 30 fe ff ff       	call   f01034f2 <env_alloc>
f01036c2:	83 c4 10             	add    $0x10,%esp
f01036c5:	85 c0                	test   %eax,%eax
f01036c7:	75 46                	jne    f010370f <env_create+0x6c>
          	panic("env_create failed: env_alloc failed.\n");

     	load_icode(e, binary);
f01036c9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01036cc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
    	if (header->e_magic != ELF_MAGIC) 
f01036cf:	8b 45 08             	mov    0x8(%ebp),%eax
f01036d2:	81 38 7f 45 4c 46    	cmpl   $0x464c457f,(%eax)
f01036d8:	75 50                	jne    f010372a <env_create+0x87>
    	if (header->e_entry == 0)
f01036da:	8b 45 08             	mov    0x8(%ebp),%eax
f01036dd:	8b 40 18             	mov    0x18(%eax),%eax
f01036e0:	85 c0                	test   %eax,%eax
f01036e2:	74 61                	je     f0103745 <env_create+0xa2>
   	e->env_tf.tf_eip = header->e_entry;
f01036e4:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01036e7:	89 41 30             	mov    %eax,0x30(%ecx)
   	lcr3(PADDR(e->env_pgdir));   //load user pgdir
f01036ea:	8b 41 5c             	mov    0x5c(%ecx),%eax
	if ((uint32_t)kva < KERNBASE)
f01036ed:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01036f2:	76 6c                	jbe    f0103760 <env_create+0xbd>
	return (physaddr_t)kva - KERNBASE;
f01036f4:	05 00 00 00 10       	add    $0x10000000,%eax
	asm volatile("movl %0,%%cr3" : : "r" (val));
f01036f9:	0f 22 d8             	mov    %eax,%cr3
   	ph = (struct Proghdr* )((uint8_t *)header + header->e_phoff);
f01036fc:	8b 45 08             	mov    0x8(%ebp),%eax
f01036ff:	89 c6                	mov    %eax,%esi
f0103701:	03 70 1c             	add    0x1c(%eax),%esi
   	eph = ph + header->e_phnum;
f0103704:	0f b7 78 2c          	movzwl 0x2c(%eax),%edi
f0103708:	c1 e7 05             	shl    $0x5,%edi
f010370b:	01 f7                	add    %esi,%edi
f010370d:	eb 6d                	jmp    f010377c <env_create+0xd9>
          	panic("env_create failed: env_alloc failed.\n");
f010370f:	83 ec 04             	sub    $0x4,%esp
f0103712:	8d 83 b4 94 f7 ff    	lea    -0x86b4c(%ebx),%eax
f0103718:	50                   	push   %eax
f0103719:	68 8f 01 00 00       	push   $0x18f
f010371e:	8d 83 7a 95 f7 ff    	lea    -0x86a86(%ebx),%eax
f0103724:	50                   	push   %eax
f0103725:	e8 87 c9 ff ff       	call   f01000b1 <_panic>
        	panic("load_icode failed: The binary we load is not elf.\n");
f010372a:	83 ec 04             	sub    $0x4,%esp
f010372d:	8d 83 dc 94 f7 ff    	lea    -0x86b24(%ebx),%eax
f0103733:	50                   	push   %eax
f0103734:	68 64 01 00 00       	push   $0x164
f0103739:	8d 83 7a 95 f7 ff    	lea    -0x86a86(%ebx),%eax
f010373f:	50                   	push   %eax
f0103740:	e8 6c c9 ff ff       	call   f01000b1 <_panic>
        	panic("load_icode failed: The elf file can't be excuterd.\n");
f0103745:	83 ec 04             	sub    $0x4,%esp
f0103748:	8d 83 10 95 f7 ff    	lea    -0x86af0(%ebx),%eax
f010374e:	50                   	push   %eax
f010374f:	68 67 01 00 00       	push   $0x167
f0103754:	8d 83 7a 95 f7 ff    	lea    -0x86a86(%ebx),%eax
f010375a:	50                   	push   %eax
f010375b:	e8 51 c9 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103760:	50                   	push   %eax
f0103761:	8d 83 cc 8a f7 ff    	lea    -0x87534(%ebx),%eax
f0103767:	50                   	push   %eax
f0103768:	68 6b 01 00 00       	push   $0x16b
f010376d:	8d 83 7a 95 f7 ff    	lea    -0x86a86(%ebx),%eax
f0103773:	50                   	push   %eax
f0103774:	e8 38 c9 ff ff       	call   f01000b1 <_panic>
    	for(; ph < eph; ph++) {
f0103779:	83 c6 20             	add    $0x20,%esi
f010377c:	39 f7                	cmp    %esi,%edi
f010377e:	76 44                	jbe    f01037c4 <env_create+0x121>
        	if(ph->p_type == ELF_PROG_LOAD) {
f0103780:	83 3e 01             	cmpl   $0x1,(%esi)
f0103783:	75 f4                	jne    f0103779 <env_create+0xd6>
           		region_alloc(e, (void *)ph->p_va, ph->p_memsz);
f0103785:	8b 4e 14             	mov    0x14(%esi),%ecx
f0103788:	8b 56 08             	mov    0x8(%esi),%edx
f010378b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010378e:	e8 ab fb ff ff       	call   f010333e <region_alloc>
            		memmove((void *)ph->p_va, binary + ph->p_offset, ph->p_filesz);
f0103793:	83 ec 04             	sub    $0x4,%esp
f0103796:	ff 76 10             	pushl  0x10(%esi)
f0103799:	8b 45 08             	mov    0x8(%ebp),%eax
f010379c:	03 46 04             	add    0x4(%esi),%eax
f010379f:	50                   	push   %eax
f01037a0:	ff 76 08             	pushl  0x8(%esi)
f01037a3:	e8 3a 19 00 00       	call   f01050e2 <memmove>
            		memset((void *)(ph->p_va + ph->p_filesz), 0, ph->p_memsz - ph->p_filesz);
f01037a8:	8b 46 10             	mov    0x10(%esi),%eax
f01037ab:	83 c4 0c             	add    $0xc,%esp
f01037ae:	8b 56 14             	mov    0x14(%esi),%edx
f01037b1:	29 c2                	sub    %eax,%edx
f01037b3:	52                   	push   %edx
f01037b4:	6a 00                	push   $0x0
f01037b6:	03 46 08             	add    0x8(%esi),%eax
f01037b9:	50                   	push   %eax
f01037ba:	e8 d6 18 00 00       	call   f0105095 <memset>
f01037bf:	83 c4 10             	add    $0x10,%esp
f01037c2:	eb b5                	jmp    f0103779 <env_create+0xd6>
	region_alloc(e,(void *)(USTACKTOP-PGSIZE), PGSIZE);
f01037c4:	b9 00 10 00 00       	mov    $0x1000,%ecx
f01037c9:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f01037ce:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01037d1:	e8 68 fb ff ff       	call   f010333e <region_alloc>
     	e->env_type = type;
f01037d6:	8b 55 0c             	mov    0xc(%ebp),%edx
f01037d9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01037dc:	89 50 50             	mov    %edx,0x50(%eax)
}
f01037df:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01037e2:	5b                   	pop    %ebx
f01037e3:	5e                   	pop    %esi
f01037e4:	5f                   	pop    %edi
f01037e5:	5d                   	pop    %ebp
f01037e6:	c3                   	ret    

f01037e7 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01037e7:	55                   	push   %ebp
f01037e8:	89 e5                	mov    %esp,%ebp
f01037ea:	57                   	push   %edi
f01037eb:	56                   	push   %esi
f01037ec:	53                   	push   %ebx
f01037ed:	83 ec 2c             	sub    $0x2c,%esp
f01037f0:	e8 72 c9 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01037f5:	81 c3 2b 98 08 00    	add    $0x8982b,%ebx
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01037fb:	8b 93 08 23 00 00    	mov    0x2308(%ebx),%edx
f0103801:	3b 55 08             	cmp    0x8(%ebp),%edx
f0103804:	75 17                	jne    f010381d <env_free+0x36>
		lcr3(PADDR(kern_pgdir));
f0103806:	c7 c0 ec ff 18 f0    	mov    $0xf018ffec,%eax
f010380c:	8b 00                	mov    (%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f010380e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103813:	76 46                	jbe    f010385b <env_free+0x74>
	return (physaddr_t)kva - KERNBASE;
f0103815:	05 00 00 00 10       	add    $0x10000000,%eax
f010381a:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f010381d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103820:	8b 48 48             	mov    0x48(%eax),%ecx
f0103823:	b8 00 00 00 00       	mov    $0x0,%eax
f0103828:	85 d2                	test   %edx,%edx
f010382a:	74 03                	je     f010382f <env_free+0x48>
f010382c:	8b 42 48             	mov    0x48(%edx),%eax
f010382f:	83 ec 04             	sub    $0x4,%esp
f0103832:	51                   	push   %ecx
f0103833:	50                   	push   %eax
f0103834:	8d 83 b0 95 f7 ff    	lea    -0x86a50(%ebx),%eax
f010383a:	50                   	push   %eax
f010383b:	e8 18 03 00 00       	call   f0103b58 <cprintf>
f0103840:	83 c4 10             	add    $0x10,%esp
f0103843:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
	if (PGNUM(pa) >= npages)
f010384a:	c7 c0 e8 ff 18 f0    	mov    $0xf018ffe8,%eax
f0103850:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	if (PGNUM(pa) >= npages)
f0103853:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0103856:	e9 9f 00 00 00       	jmp    f01038fa <env_free+0x113>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010385b:	50                   	push   %eax
f010385c:	8d 83 cc 8a f7 ff    	lea    -0x87534(%ebx),%eax
f0103862:	50                   	push   %eax
f0103863:	68 a3 01 00 00       	push   $0x1a3
f0103868:	8d 83 7a 95 f7 ff    	lea    -0x86a86(%ebx),%eax
f010386e:	50                   	push   %eax
f010386f:	e8 3d c8 ff ff       	call   f01000b1 <_panic>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103874:	50                   	push   %eax
f0103875:	8d 83 64 89 f7 ff    	lea    -0x8769c(%ebx),%eax
f010387b:	50                   	push   %eax
f010387c:	68 b2 01 00 00       	push   $0x1b2
f0103881:	8d 83 7a 95 f7 ff    	lea    -0x86a86(%ebx),%eax
f0103887:	50                   	push   %eax
f0103888:	e8 24 c8 ff ff       	call   f01000b1 <_panic>
f010388d:	83 c6 04             	add    $0x4,%esi
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103890:	39 fe                	cmp    %edi,%esi
f0103892:	74 24                	je     f01038b8 <env_free+0xd1>
			if (pt[pteno] & PTE_P)
f0103894:	f6 06 01             	testb  $0x1,(%esi)
f0103897:	74 f4                	je     f010388d <env_free+0xa6>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103899:	83 ec 08             	sub    $0x8,%esp
f010389c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010389f:	01 f0                	add    %esi,%eax
f01038a1:	c1 e0 0a             	shl    $0xa,%eax
f01038a4:	0b 45 e4             	or     -0x1c(%ebp),%eax
f01038a7:	50                   	push   %eax
f01038a8:	8b 45 08             	mov    0x8(%ebp),%eax
f01038ab:	ff 70 5c             	pushl  0x5c(%eax)
f01038ae:	e8 ee d9 ff ff       	call   f01012a1 <page_remove>
f01038b3:	83 c4 10             	add    $0x10,%esp
f01038b6:	eb d5                	jmp    f010388d <env_free+0xa6>
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f01038b8:	8b 45 08             	mov    0x8(%ebp),%eax
f01038bb:	8b 40 5c             	mov    0x5c(%eax),%eax
f01038be:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01038c1:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
	if (PGNUM(pa) >= npages)
f01038c8:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01038cb:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01038ce:	3b 10                	cmp    (%eax),%edx
f01038d0:	73 6f                	jae    f0103941 <env_free+0x15a>
		page_decref(pa2page(pa));
f01038d2:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f01038d5:	c7 c0 f0 ff 18 f0    	mov    $0xf018fff0,%eax
f01038db:	8b 00                	mov    (%eax),%eax
f01038dd:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01038e0:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f01038e3:	50                   	push   %eax
f01038e4:	e8 15 d8 ff ff       	call   f01010fe <page_decref>
f01038e9:	83 c4 10             	add    $0x10,%esp
f01038ec:	83 45 dc 04          	addl   $0x4,-0x24(%ebp)
f01038f0:	8b 45 dc             	mov    -0x24(%ebp),%eax
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01038f3:	3d ec 0e 00 00       	cmp    $0xeec,%eax
f01038f8:	74 5f                	je     f0103959 <env_free+0x172>
		if (!(e->env_pgdir[pdeno] & PTE_P))
f01038fa:	8b 45 08             	mov    0x8(%ebp),%eax
f01038fd:	8b 40 5c             	mov    0x5c(%eax),%eax
f0103900:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103903:	8b 04 10             	mov    (%eax,%edx,1),%eax
f0103906:	a8 01                	test   $0x1,%al
f0103908:	74 e2                	je     f01038ec <env_free+0x105>
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f010390a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	if (PGNUM(pa) >= npages)
f010390f:	89 c2                	mov    %eax,%edx
f0103911:	c1 ea 0c             	shr    $0xc,%edx
f0103914:	89 55 d8             	mov    %edx,-0x28(%ebp)
f0103917:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010391a:	39 11                	cmp    %edx,(%ecx)
f010391c:	0f 86 52 ff ff ff    	jbe    f0103874 <env_free+0x8d>
	return (void *)(pa + KERNBASE);
f0103922:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103928:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010392b:	c1 e2 14             	shl    $0x14,%edx
f010392e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103931:	8d b8 00 10 00 f0    	lea    -0xffff000(%eax),%edi
f0103937:	f7 d8                	neg    %eax
f0103939:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010393c:	e9 53 ff ff ff       	jmp    f0103894 <env_free+0xad>
		panic("pa2page called with invalid pa");
f0103941:	83 ec 04             	sub    $0x4,%esp
f0103944:	8d 83 70 8a f7 ff    	lea    -0x87590(%ebx),%eax
f010394a:	50                   	push   %eax
f010394b:	6a 4f                	push   $0x4f
f010394d:	8d 83 99 91 f7 ff    	lea    -0x86e67(%ebx),%eax
f0103953:	50                   	push   %eax
f0103954:	e8 58 c7 ff ff       	call   f01000b1 <_panic>
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103959:	8b 45 08             	mov    0x8(%ebp),%eax
f010395c:	8b 40 5c             	mov    0x5c(%eax),%eax
	if ((uint32_t)kva < KERNBASE)
f010395f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103964:	76 57                	jbe    f01039bd <env_free+0x1d6>
	e->env_pgdir = 0;
f0103966:	8b 55 08             	mov    0x8(%ebp),%edx
f0103969:	c7 42 5c 00 00 00 00 	movl   $0x0,0x5c(%edx)
	return (physaddr_t)kva - KERNBASE;
f0103970:	05 00 00 00 10       	add    $0x10000000,%eax
	if (PGNUM(pa) >= npages)
f0103975:	c1 e8 0c             	shr    $0xc,%eax
f0103978:	c7 c2 e8 ff 18 f0    	mov    $0xf018ffe8,%edx
f010397e:	3b 02                	cmp    (%edx),%eax
f0103980:	73 54                	jae    f01039d6 <env_free+0x1ef>
	page_decref(pa2page(pa));
f0103982:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0103985:	c7 c2 f0 ff 18 f0    	mov    $0xf018fff0,%edx
f010398b:	8b 12                	mov    (%edx),%edx
f010398d:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0103990:	50                   	push   %eax
f0103991:	e8 68 d7 ff ff       	call   f01010fe <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103996:	8b 45 08             	mov    0x8(%ebp),%eax
f0103999:	c7 40 54 00 00 00 00 	movl   $0x0,0x54(%eax)
	e->env_link = env_free_list;
f01039a0:	8b 83 10 23 00 00    	mov    0x2310(%ebx),%eax
f01039a6:	8b 55 08             	mov    0x8(%ebp),%edx
f01039a9:	89 42 44             	mov    %eax,0x44(%edx)
	env_free_list = e;
f01039ac:	89 93 10 23 00 00    	mov    %edx,0x2310(%ebx)
}
f01039b2:	83 c4 10             	add    $0x10,%esp
f01039b5:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01039b8:	5b                   	pop    %ebx
f01039b9:	5e                   	pop    %esi
f01039ba:	5f                   	pop    %edi
f01039bb:	5d                   	pop    %ebp
f01039bc:	c3                   	ret    
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01039bd:	50                   	push   %eax
f01039be:	8d 83 cc 8a f7 ff    	lea    -0x87534(%ebx),%eax
f01039c4:	50                   	push   %eax
f01039c5:	68 c0 01 00 00       	push   $0x1c0
f01039ca:	8d 83 7a 95 f7 ff    	lea    -0x86a86(%ebx),%eax
f01039d0:	50                   	push   %eax
f01039d1:	e8 db c6 ff ff       	call   f01000b1 <_panic>
		panic("pa2page called with invalid pa");
f01039d6:	83 ec 04             	sub    $0x4,%esp
f01039d9:	8d 83 70 8a f7 ff    	lea    -0x87590(%ebx),%eax
f01039df:	50                   	push   %eax
f01039e0:	6a 4f                	push   $0x4f
f01039e2:	8d 83 99 91 f7 ff    	lea    -0x86e67(%ebx),%eax
f01039e8:	50                   	push   %eax
f01039e9:	e8 c3 c6 ff ff       	call   f01000b1 <_panic>

f01039ee <env_destroy>:
//
// Frees environment e.
//
void
env_destroy(struct Env *e)
{
f01039ee:	55                   	push   %ebp
f01039ef:	89 e5                	mov    %esp,%ebp
f01039f1:	53                   	push   %ebx
f01039f2:	83 ec 10             	sub    $0x10,%esp
f01039f5:	e8 6d c7 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01039fa:	81 c3 26 96 08 00    	add    $0x89626,%ebx
	env_free(e);
f0103a00:	ff 75 08             	pushl  0x8(%ebp)
f0103a03:	e8 df fd ff ff       	call   f01037e7 <env_free>

	cprintf("Destroyed the only environment - nothing more to do!\n");
f0103a08:	8d 83 44 95 f7 ff    	lea    -0x86abc(%ebx),%eax
f0103a0e:	89 04 24             	mov    %eax,(%esp)
f0103a11:	e8 42 01 00 00       	call   f0103b58 <cprintf>
f0103a16:	83 c4 10             	add    $0x10,%esp
	while (1)
		monitor(NULL);
f0103a19:	83 ec 0c             	sub    $0xc,%esp
f0103a1c:	6a 00                	push   $0x0
f0103a1e:	e8 eb ce ff ff       	call   f010090e <monitor>
f0103a23:	83 c4 10             	add    $0x10,%esp
f0103a26:	eb f1                	jmp    f0103a19 <env_destroy+0x2b>

f0103a28 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103a28:	55                   	push   %ebp
f0103a29:	89 e5                	mov    %esp,%ebp
f0103a2b:	53                   	push   %ebx
f0103a2c:	83 ec 08             	sub    $0x8,%esp
f0103a2f:	e8 33 c7 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103a34:	81 c3 ec 95 08 00    	add    $0x895ec,%ebx
	asm volatile(
f0103a3a:	8b 65 08             	mov    0x8(%ebp),%esp
f0103a3d:	61                   	popa   
f0103a3e:	07                   	pop    %es
f0103a3f:	1f                   	pop    %ds
f0103a40:	83 c4 08             	add    $0x8,%esp
f0103a43:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret\n"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103a44:	8d 83 c6 95 f7 ff    	lea    -0x86a3a(%ebx),%eax
f0103a4a:	50                   	push   %eax
f0103a4b:	68 e9 01 00 00       	push   $0x1e9
f0103a50:	8d 83 7a 95 f7 ff    	lea    -0x86a86(%ebx),%eax
f0103a56:	50                   	push   %eax
f0103a57:	e8 55 c6 ff ff       	call   f01000b1 <_panic>

f0103a5c <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103a5c:	55                   	push   %ebp
f0103a5d:	89 e5                	mov    %esp,%ebp
f0103a5f:	53                   	push   %ebx
f0103a60:	83 ec 04             	sub    $0x4,%esp
f0103a63:	e8 ff c6 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103a68:	81 c3 b8 95 08 00    	add    $0x895b8,%ebx
f0103a6e:	8b 45 08             	mov    0x8(%ebp),%eax
	//	e->env_tf.  Go back through the code you wrote above
	//	and make sure you have set the relevant parts of
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.
	if(curenv != NULL && curenv->env_status == ENV_RUNNING)
f0103a71:	8b 93 08 23 00 00    	mov    0x2308(%ebx),%edx
f0103a77:	85 d2                	test   %edx,%edx
f0103a79:	74 06                	je     f0103a81 <env_run+0x25>
f0103a7b:	83 7a 54 03          	cmpl   $0x3,0x54(%edx)
f0103a7f:	74 35                	je     f0103ab6 <env_run+0x5a>
        	curenv->env_status = ENV_RUNNABLE;

    	curenv = e;    
f0103a81:	89 83 08 23 00 00    	mov    %eax,0x2308(%ebx)
    	curenv->env_status = ENV_RUNNING;
f0103a87:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
    	curenv->env_runs++;
f0103a8e:	83 40 58 01          	addl   $0x1,0x58(%eax)
    	lcr3(PADDR(curenv->env_pgdir));
f0103a92:	8b 50 5c             	mov    0x5c(%eax),%edx
	if ((uint32_t)kva < KERNBASE)
f0103a95:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0103a9b:	77 22                	ja     f0103abf <env_run+0x63>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103a9d:	52                   	push   %edx
f0103a9e:	8d 83 cc 8a f7 ff    	lea    -0x87534(%ebx),%eax
f0103aa4:	50                   	push   %eax
f0103aa5:	68 0d 02 00 00       	push   $0x20d
f0103aaa:	8d 83 7a 95 f7 ff    	lea    -0x86a86(%ebx),%eax
f0103ab0:	50                   	push   %eax
f0103ab1:	e8 fb c5 ff ff       	call   f01000b1 <_panic>
        	curenv->env_status = ENV_RUNNABLE;
f0103ab6:	c7 42 54 02 00 00 00 	movl   $0x2,0x54(%edx)
f0103abd:	eb c2                	jmp    f0103a81 <env_run+0x25>
	return (physaddr_t)kva - KERNBASE;
f0103abf:	81 c2 00 00 00 10    	add    $0x10000000,%edx
f0103ac5:	0f 22 da             	mov    %edx,%cr3

    	env_pop_tf(&curenv->env_tf);
f0103ac8:	83 ec 0c             	sub    $0xc,%esp
f0103acb:	50                   	push   %eax
f0103acc:	e8 57 ff ff ff       	call   f0103a28 <env_pop_tf>

f0103ad1 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103ad1:	55                   	push   %ebp
f0103ad2:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103ad4:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ad7:	ba 70 00 00 00       	mov    $0x70,%edx
f0103adc:	ee                   	out    %al,(%dx)
	asm volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103add:	ba 71 00 00 00       	mov    $0x71,%edx
f0103ae2:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103ae3:	0f b6 c0             	movzbl %al,%eax
}
f0103ae6:	5d                   	pop    %ebp
f0103ae7:	c3                   	ret    

f0103ae8 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103ae8:	55                   	push   %ebp
f0103ae9:	89 e5                	mov    %esp,%ebp
	asm volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103aeb:	8b 45 08             	mov    0x8(%ebp),%eax
f0103aee:	ba 70 00 00 00       	mov    $0x70,%edx
f0103af3:	ee                   	out    %al,(%dx)
f0103af4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103af7:	ba 71 00 00 00       	mov    $0x71,%edx
f0103afc:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103afd:	5d                   	pop    %ebp
f0103afe:	c3                   	ret    

f0103aff <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103aff:	55                   	push   %ebp
f0103b00:	89 e5                	mov    %esp,%ebp
f0103b02:	53                   	push   %ebx
f0103b03:	83 ec 10             	sub    $0x10,%esp
f0103b06:	e8 5c c6 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103b0b:	81 c3 15 95 08 00    	add    $0x89515,%ebx
	cputchar(ch);
f0103b11:	ff 75 08             	pushl  0x8(%ebp)
f0103b14:	e8 c5 cb ff ff       	call   f01006de <cputchar>
	*cnt++;
}
f0103b19:	83 c4 10             	add    $0x10,%esp
f0103b1c:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103b1f:	c9                   	leave  
f0103b20:	c3                   	ret    

f0103b21 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103b21:	55                   	push   %ebp
f0103b22:	89 e5                	mov    %esp,%ebp
f0103b24:	53                   	push   %ebx
f0103b25:	83 ec 14             	sub    $0x14,%esp
f0103b28:	e8 3a c6 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103b2d:	81 c3 f3 94 08 00    	add    $0x894f3,%ebx
	int cnt = 0;
f0103b33:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103b3a:	ff 75 0c             	pushl  0xc(%ebp)
f0103b3d:	ff 75 08             	pushl  0x8(%ebp)
f0103b40:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103b43:	50                   	push   %eax
f0103b44:	8d 83 df 6a f7 ff    	lea    -0x89521(%ebx),%eax
f0103b4a:	50                   	push   %eax
f0103b4b:	e8 c4 0d 00 00       	call   f0104914 <vprintfmt>
	return cnt;
}
f0103b50:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103b53:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103b56:	c9                   	leave  
f0103b57:	c3                   	ret    

f0103b58 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103b58:	55                   	push   %ebp
f0103b59:	89 e5                	mov    %esp,%ebp
f0103b5b:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103b5e:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103b61:	50                   	push   %eax
f0103b62:	ff 75 08             	pushl  0x8(%ebp)
f0103b65:	e8 b7 ff ff ff       	call   f0103b21 <vcprintf>
	va_end(ap);

	return cnt;
}
f0103b6a:	c9                   	leave  
f0103b6b:	c3                   	ret    

f0103b6c <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103b6c:	55                   	push   %ebp
f0103b6d:	89 e5                	mov    %esp,%ebp
f0103b6f:	57                   	push   %edi
f0103b70:	56                   	push   %esi
f0103b71:	53                   	push   %ebx
f0103b72:	83 ec 04             	sub    $0x4,%esp
f0103b75:	e8 ed c5 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103b7a:	81 c3 a6 94 08 00    	add    $0x894a6,%ebx
	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f0103b80:	c7 83 44 2b 00 00 00 	movl   $0xf0000000,0x2b44(%ebx)
f0103b87:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f0103b8a:	66 c7 83 48 2b 00 00 	movw   $0x10,0x2b48(%ebx)
f0103b91:	10 00 
	ts.ts_iomb = sizeof(struct Taskstate);
f0103b93:	66 c7 83 a6 2b 00 00 	movw   $0x68,0x2ba6(%ebx)
f0103b9a:	68 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0103b9c:	c7 c0 00 c3 11 f0    	mov    $0xf011c300,%eax
f0103ba2:	66 c7 40 28 67 00    	movw   $0x67,0x28(%eax)
f0103ba8:	8d b3 40 2b 00 00    	lea    0x2b40(%ebx),%esi
f0103bae:	66 89 70 2a          	mov    %si,0x2a(%eax)
f0103bb2:	89 f2                	mov    %esi,%edx
f0103bb4:	c1 ea 10             	shr    $0x10,%edx
f0103bb7:	88 50 2c             	mov    %dl,0x2c(%eax)
f0103bba:	0f b6 50 2d          	movzbl 0x2d(%eax),%edx
f0103bbe:	83 e2 f0             	and    $0xfffffff0,%edx
f0103bc1:	83 ca 09             	or     $0x9,%edx
f0103bc4:	83 e2 9f             	and    $0xffffff9f,%edx
f0103bc7:	83 ca 80             	or     $0xffffff80,%edx
f0103bca:	88 55 f3             	mov    %dl,-0xd(%ebp)
f0103bcd:	88 50 2d             	mov    %dl,0x2d(%eax)
f0103bd0:	0f b6 48 2e          	movzbl 0x2e(%eax),%ecx
f0103bd4:	83 e1 c0             	and    $0xffffffc0,%ecx
f0103bd7:	83 c9 40             	or     $0x40,%ecx
f0103bda:	83 e1 7f             	and    $0x7f,%ecx
f0103bdd:	88 48 2e             	mov    %cl,0x2e(%eax)
f0103be0:	c1 ee 18             	shr    $0x18,%esi
f0103be3:	89 f1                	mov    %esi,%ecx
f0103be5:	88 48 2f             	mov    %cl,0x2f(%eax)
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0103be8:	0f b6 55 f3          	movzbl -0xd(%ebp),%edx
f0103bec:	83 e2 ef             	and    $0xffffffef,%edx
f0103bef:	88 50 2d             	mov    %dl,0x2d(%eax)
	asm volatile("ltr %0" : : "r" (sel));
f0103bf2:	b8 28 00 00 00       	mov    $0x28,%eax
f0103bf7:	0f 00 d8             	ltr    %ax
	asm volatile("lidt (%0)" : : "r" (p));
f0103bfa:	8d 83 e8 1f 00 00    	lea    0x1fe8(%ebx),%eax
f0103c00:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f0103c03:	83 c4 04             	add    $0x4,%esp
f0103c06:	5b                   	pop    %ebx
f0103c07:	5e                   	pop    %esi
f0103c08:	5f                   	pop    %edi
f0103c09:	5d                   	pop    %ebp
f0103c0a:	c3                   	ret    

f0103c0b <trap_init>:
{
f0103c0b:	55                   	push   %ebp
f0103c0c:	89 e5                	mov    %esp,%ebp
f0103c0e:	e8 f6 ca ff ff       	call   f0100709 <__x86.get_pc_thunk.ax>
f0103c13:	05 0d 94 08 00       	add    $0x8940d,%eax
	SETGATE(idt[0], 0, GD_KT, th0, 0);
f0103c18:	c7 c2 72 43 10 f0    	mov    $0xf0104372,%edx
f0103c1e:	66 89 90 20 23 00 00 	mov    %dx,0x2320(%eax)
f0103c25:	66 c7 80 22 23 00 00 	movw   $0x8,0x2322(%eax)
f0103c2c:	08 00 
f0103c2e:	c6 80 24 23 00 00 00 	movb   $0x0,0x2324(%eax)
f0103c35:	c6 80 25 23 00 00 8e 	movb   $0x8e,0x2325(%eax)
f0103c3c:	c1 ea 10             	shr    $0x10,%edx
f0103c3f:	66 89 90 26 23 00 00 	mov    %dx,0x2326(%eax)
	SETGATE(idt[1], 0, GD_KT, th1, 0);
f0103c46:	c7 c2 78 43 10 f0    	mov    $0xf0104378,%edx
f0103c4c:	66 89 90 28 23 00 00 	mov    %dx,0x2328(%eax)
f0103c53:	66 c7 80 2a 23 00 00 	movw   $0x8,0x232a(%eax)
f0103c5a:	08 00 
f0103c5c:	c6 80 2c 23 00 00 00 	movb   $0x0,0x232c(%eax)
f0103c63:	c6 80 2d 23 00 00 8e 	movb   $0x8e,0x232d(%eax)
f0103c6a:	c1 ea 10             	shr    $0x10,%edx
f0103c6d:	66 89 90 2e 23 00 00 	mov    %dx,0x232e(%eax)
	SETGATE(idt[3], 0, GD_KT, th3, 3);
f0103c74:	c7 c2 7e 43 10 f0    	mov    $0xf010437e,%edx
f0103c7a:	66 89 90 38 23 00 00 	mov    %dx,0x2338(%eax)
f0103c81:	66 c7 80 3a 23 00 00 	movw   $0x8,0x233a(%eax)
f0103c88:	08 00 
f0103c8a:	c6 80 3c 23 00 00 00 	movb   $0x0,0x233c(%eax)
f0103c91:	c6 80 3d 23 00 00 ee 	movb   $0xee,0x233d(%eax)
f0103c98:	c1 ea 10             	shr    $0x10,%edx
f0103c9b:	66 89 90 3e 23 00 00 	mov    %dx,0x233e(%eax)
	SETGATE(idt[4], 0, GD_KT, th4, 0);
f0103ca2:	c7 c2 84 43 10 f0    	mov    $0xf0104384,%edx
f0103ca8:	66 89 90 40 23 00 00 	mov    %dx,0x2340(%eax)
f0103caf:	66 c7 80 42 23 00 00 	movw   $0x8,0x2342(%eax)
f0103cb6:	08 00 
f0103cb8:	c6 80 44 23 00 00 00 	movb   $0x0,0x2344(%eax)
f0103cbf:	c6 80 45 23 00 00 8e 	movb   $0x8e,0x2345(%eax)
f0103cc6:	c1 ea 10             	shr    $0x10,%edx
f0103cc9:	66 89 90 46 23 00 00 	mov    %dx,0x2346(%eax)
	SETGATE(idt[5], 0, GD_KT, th5, 0);
f0103cd0:	c7 c2 8a 43 10 f0    	mov    $0xf010438a,%edx
f0103cd6:	66 89 90 48 23 00 00 	mov    %dx,0x2348(%eax)
f0103cdd:	66 c7 80 4a 23 00 00 	movw   $0x8,0x234a(%eax)
f0103ce4:	08 00 
f0103ce6:	c6 80 4c 23 00 00 00 	movb   $0x0,0x234c(%eax)
f0103ced:	c6 80 4d 23 00 00 8e 	movb   $0x8e,0x234d(%eax)
f0103cf4:	c1 ea 10             	shr    $0x10,%edx
f0103cf7:	66 89 90 4e 23 00 00 	mov    %dx,0x234e(%eax)
	SETGATE(idt[6], 0, GD_KT, th6, 0);
f0103cfe:	c7 c2 90 43 10 f0    	mov    $0xf0104390,%edx
f0103d04:	66 89 90 50 23 00 00 	mov    %dx,0x2350(%eax)
f0103d0b:	66 c7 80 52 23 00 00 	movw   $0x8,0x2352(%eax)
f0103d12:	08 00 
f0103d14:	c6 80 54 23 00 00 00 	movb   $0x0,0x2354(%eax)
f0103d1b:	c6 80 55 23 00 00 8e 	movb   $0x8e,0x2355(%eax)
f0103d22:	c1 ea 10             	shr    $0x10,%edx
f0103d25:	66 89 90 56 23 00 00 	mov    %dx,0x2356(%eax)
	SETGATE(idt[7], 0, GD_KT, th7, 0);
f0103d2c:	c7 c2 96 43 10 f0    	mov    $0xf0104396,%edx
f0103d32:	66 89 90 58 23 00 00 	mov    %dx,0x2358(%eax)
f0103d39:	66 c7 80 5a 23 00 00 	movw   $0x8,0x235a(%eax)
f0103d40:	08 00 
f0103d42:	c6 80 5c 23 00 00 00 	movb   $0x0,0x235c(%eax)
f0103d49:	c6 80 5d 23 00 00 8e 	movb   $0x8e,0x235d(%eax)
f0103d50:	c1 ea 10             	shr    $0x10,%edx
f0103d53:	66 89 90 5e 23 00 00 	mov    %dx,0x235e(%eax)
	SETGATE(idt[8], 0, GD_KT, th8, 0);
f0103d5a:	c7 c2 9c 43 10 f0    	mov    $0xf010439c,%edx
f0103d60:	66 89 90 60 23 00 00 	mov    %dx,0x2360(%eax)
f0103d67:	66 c7 80 62 23 00 00 	movw   $0x8,0x2362(%eax)
f0103d6e:	08 00 
f0103d70:	c6 80 64 23 00 00 00 	movb   $0x0,0x2364(%eax)
f0103d77:	c6 80 65 23 00 00 8e 	movb   $0x8e,0x2365(%eax)
f0103d7e:	c1 ea 10             	shr    $0x10,%edx
f0103d81:	66 89 90 66 23 00 00 	mov    %dx,0x2366(%eax)
	SETGATE(idt[9], 0, GD_KT, th9, 0);
f0103d88:	c7 c2 a0 43 10 f0    	mov    $0xf01043a0,%edx
f0103d8e:	66 89 90 68 23 00 00 	mov    %dx,0x2368(%eax)
f0103d95:	66 c7 80 6a 23 00 00 	movw   $0x8,0x236a(%eax)
f0103d9c:	08 00 
f0103d9e:	c6 80 6c 23 00 00 00 	movb   $0x0,0x236c(%eax)
f0103da5:	c6 80 6d 23 00 00 8e 	movb   $0x8e,0x236d(%eax)
f0103dac:	c1 ea 10             	shr    $0x10,%edx
f0103daf:	66 89 90 6e 23 00 00 	mov    %dx,0x236e(%eax)
	SETGATE(idt[10], 0, GD_KT, th10, 0);
f0103db6:	c7 c2 a6 43 10 f0    	mov    $0xf01043a6,%edx
f0103dbc:	66 89 90 70 23 00 00 	mov    %dx,0x2370(%eax)
f0103dc3:	66 c7 80 72 23 00 00 	movw   $0x8,0x2372(%eax)
f0103dca:	08 00 
f0103dcc:	c6 80 74 23 00 00 00 	movb   $0x0,0x2374(%eax)
f0103dd3:	c6 80 75 23 00 00 8e 	movb   $0x8e,0x2375(%eax)
f0103dda:	c1 ea 10             	shr    $0x10,%edx
f0103ddd:	66 89 90 76 23 00 00 	mov    %dx,0x2376(%eax)
	SETGATE(idt[11], 0, GD_KT, th11, 0);
f0103de4:	c7 c2 aa 43 10 f0    	mov    $0xf01043aa,%edx
f0103dea:	66 89 90 78 23 00 00 	mov    %dx,0x2378(%eax)
f0103df1:	66 c7 80 7a 23 00 00 	movw   $0x8,0x237a(%eax)
f0103df8:	08 00 
f0103dfa:	c6 80 7c 23 00 00 00 	movb   $0x0,0x237c(%eax)
f0103e01:	c6 80 7d 23 00 00 8e 	movb   $0x8e,0x237d(%eax)
f0103e08:	c1 ea 10             	shr    $0x10,%edx
f0103e0b:	66 89 90 7e 23 00 00 	mov    %dx,0x237e(%eax)
	SETGATE(idt[12], 0, GD_KT, th12, 0);
f0103e12:	c7 c2 ae 43 10 f0    	mov    $0xf01043ae,%edx
f0103e18:	66 89 90 80 23 00 00 	mov    %dx,0x2380(%eax)
f0103e1f:	66 c7 80 82 23 00 00 	movw   $0x8,0x2382(%eax)
f0103e26:	08 00 
f0103e28:	c6 80 84 23 00 00 00 	movb   $0x0,0x2384(%eax)
f0103e2f:	c6 80 85 23 00 00 8e 	movb   $0x8e,0x2385(%eax)
f0103e36:	c1 ea 10             	shr    $0x10,%edx
f0103e39:	66 89 90 86 23 00 00 	mov    %dx,0x2386(%eax)
	SETGATE(idt[13], 0, GD_KT, th13, 0);
f0103e40:	c7 c2 b2 43 10 f0    	mov    $0xf01043b2,%edx
f0103e46:	66 89 90 88 23 00 00 	mov    %dx,0x2388(%eax)
f0103e4d:	66 c7 80 8a 23 00 00 	movw   $0x8,0x238a(%eax)
f0103e54:	08 00 
f0103e56:	c6 80 8c 23 00 00 00 	movb   $0x0,0x238c(%eax)
f0103e5d:	c6 80 8d 23 00 00 8e 	movb   $0x8e,0x238d(%eax)
f0103e64:	c1 ea 10             	shr    $0x10,%edx
f0103e67:	66 89 90 8e 23 00 00 	mov    %dx,0x238e(%eax)
	SETGATE(idt[14], 0, GD_KT, th14, 0);
f0103e6e:	c7 c2 b6 43 10 f0    	mov    $0xf01043b6,%edx
f0103e74:	66 89 90 90 23 00 00 	mov    %dx,0x2390(%eax)
f0103e7b:	66 c7 80 92 23 00 00 	movw   $0x8,0x2392(%eax)
f0103e82:	08 00 
f0103e84:	c6 80 94 23 00 00 00 	movb   $0x0,0x2394(%eax)
f0103e8b:	c6 80 95 23 00 00 8e 	movb   $0x8e,0x2395(%eax)
f0103e92:	c1 ea 10             	shr    $0x10,%edx
f0103e95:	66 89 90 96 23 00 00 	mov    %dx,0x2396(%eax)
	SETGATE(idt[16], 0, GD_KT, th16, 0);
f0103e9c:	c7 c2 ba 43 10 f0    	mov    $0xf01043ba,%edx
f0103ea2:	66 89 90 a0 23 00 00 	mov    %dx,0x23a0(%eax)
f0103ea9:	66 c7 80 a2 23 00 00 	movw   $0x8,0x23a2(%eax)
f0103eb0:	08 00 
f0103eb2:	c6 80 a4 23 00 00 00 	movb   $0x0,0x23a4(%eax)
f0103eb9:	c6 80 a5 23 00 00 8e 	movb   $0x8e,0x23a5(%eax)
f0103ec0:	c1 ea 10             	shr    $0x10,%edx
f0103ec3:	66 89 90 a6 23 00 00 	mov    %dx,0x23a6(%eax)
	SETGATE(idt[T_SYSCALL], 0, GD_KT, th_syscall, 3);
f0103eca:	c7 c2 c0 43 10 f0    	mov    $0xf01043c0,%edx
f0103ed0:	66 89 90 a0 24 00 00 	mov    %dx,0x24a0(%eax)
f0103ed7:	66 c7 80 a2 24 00 00 	movw   $0x8,0x24a2(%eax)
f0103ede:	08 00 
f0103ee0:	c6 80 a4 24 00 00 00 	movb   $0x0,0x24a4(%eax)
f0103ee7:	c6 80 a5 24 00 00 ee 	movb   $0xee,0x24a5(%eax)
f0103eee:	c1 ea 10             	shr    $0x10,%edx
f0103ef1:	66 89 90 a6 24 00 00 	mov    %dx,0x24a6(%eax)
	trap_init_percpu();
f0103ef8:	e8 6f fc ff ff       	call   f0103b6c <trap_init_percpu>
}
f0103efd:	5d                   	pop    %ebp
f0103efe:	c3                   	ret    

f0103eff <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0103eff:	55                   	push   %ebp
f0103f00:	89 e5                	mov    %esp,%ebp
f0103f02:	56                   	push   %esi
f0103f03:	53                   	push   %ebx
f0103f04:	e8 5e c2 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103f09:	81 c3 17 91 08 00    	add    $0x89117,%ebx
f0103f0f:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0103f12:	83 ec 08             	sub    $0x8,%esp
f0103f15:	ff 36                	pushl  (%esi)
f0103f17:	8d 83 d2 95 f7 ff    	lea    -0x86a2e(%ebx),%eax
f0103f1d:	50                   	push   %eax
f0103f1e:	e8 35 fc ff ff       	call   f0103b58 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0103f23:	83 c4 08             	add    $0x8,%esp
f0103f26:	ff 76 04             	pushl  0x4(%esi)
f0103f29:	8d 83 e1 95 f7 ff    	lea    -0x86a1f(%ebx),%eax
f0103f2f:	50                   	push   %eax
f0103f30:	e8 23 fc ff ff       	call   f0103b58 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0103f35:	83 c4 08             	add    $0x8,%esp
f0103f38:	ff 76 08             	pushl  0x8(%esi)
f0103f3b:	8d 83 f0 95 f7 ff    	lea    -0x86a10(%ebx),%eax
f0103f41:	50                   	push   %eax
f0103f42:	e8 11 fc ff ff       	call   f0103b58 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0103f47:	83 c4 08             	add    $0x8,%esp
f0103f4a:	ff 76 0c             	pushl  0xc(%esi)
f0103f4d:	8d 83 ff 95 f7 ff    	lea    -0x86a01(%ebx),%eax
f0103f53:	50                   	push   %eax
f0103f54:	e8 ff fb ff ff       	call   f0103b58 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103f59:	83 c4 08             	add    $0x8,%esp
f0103f5c:	ff 76 10             	pushl  0x10(%esi)
f0103f5f:	8d 83 0e 96 f7 ff    	lea    -0x869f2(%ebx),%eax
f0103f65:	50                   	push   %eax
f0103f66:	e8 ed fb ff ff       	call   f0103b58 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103f6b:	83 c4 08             	add    $0x8,%esp
f0103f6e:	ff 76 14             	pushl  0x14(%esi)
f0103f71:	8d 83 1d 96 f7 ff    	lea    -0x869e3(%ebx),%eax
f0103f77:	50                   	push   %eax
f0103f78:	e8 db fb ff ff       	call   f0103b58 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103f7d:	83 c4 08             	add    $0x8,%esp
f0103f80:	ff 76 18             	pushl  0x18(%esi)
f0103f83:	8d 83 2c 96 f7 ff    	lea    -0x869d4(%ebx),%eax
f0103f89:	50                   	push   %eax
f0103f8a:	e8 c9 fb ff ff       	call   f0103b58 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103f8f:	83 c4 08             	add    $0x8,%esp
f0103f92:	ff 76 1c             	pushl  0x1c(%esi)
f0103f95:	8d 83 3b 96 f7 ff    	lea    -0x869c5(%ebx),%eax
f0103f9b:	50                   	push   %eax
f0103f9c:	e8 b7 fb ff ff       	call   f0103b58 <cprintf>
}
f0103fa1:	83 c4 10             	add    $0x10,%esp
f0103fa4:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103fa7:	5b                   	pop    %ebx
f0103fa8:	5e                   	pop    %esi
f0103fa9:	5d                   	pop    %ebp
f0103faa:	c3                   	ret    

f0103fab <print_trapframe>:
{
f0103fab:	55                   	push   %ebp
f0103fac:	89 e5                	mov    %esp,%ebp
f0103fae:	57                   	push   %edi
f0103faf:	56                   	push   %esi
f0103fb0:	53                   	push   %ebx
f0103fb1:	83 ec 14             	sub    $0x14,%esp
f0103fb4:	e8 ae c1 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0103fb9:	81 c3 67 90 08 00    	add    $0x89067,%ebx
f0103fbf:	8b 75 08             	mov    0x8(%ebp),%esi
	cprintf("TRAP frame at %p\n", tf);
f0103fc2:	56                   	push   %esi
f0103fc3:	8d 83 71 97 f7 ff    	lea    -0x8688f(%ebx),%eax
f0103fc9:	50                   	push   %eax
f0103fca:	e8 89 fb ff ff       	call   f0103b58 <cprintf>
	print_regs(&tf->tf_regs);
f0103fcf:	89 34 24             	mov    %esi,(%esp)
f0103fd2:	e8 28 ff ff ff       	call   f0103eff <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103fd7:	83 c4 08             	add    $0x8,%esp
f0103fda:	0f b7 46 20          	movzwl 0x20(%esi),%eax
f0103fde:	50                   	push   %eax
f0103fdf:	8d 83 8c 96 f7 ff    	lea    -0x86974(%ebx),%eax
f0103fe5:	50                   	push   %eax
f0103fe6:	e8 6d fb ff ff       	call   f0103b58 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103feb:	83 c4 08             	add    $0x8,%esp
f0103fee:	0f b7 46 24          	movzwl 0x24(%esi),%eax
f0103ff2:	50                   	push   %eax
f0103ff3:	8d 83 9f 96 f7 ff    	lea    -0x86961(%ebx),%eax
f0103ff9:	50                   	push   %eax
f0103ffa:	e8 59 fb ff ff       	call   f0103b58 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103fff:	8b 56 28             	mov    0x28(%esi),%edx
	if (trapno < ARRAY_SIZE(excnames))
f0104002:	83 c4 10             	add    $0x10,%esp
f0104005:	83 fa 13             	cmp    $0x13,%edx
f0104008:	0f 86 e9 00 00 00    	jbe    f01040f7 <print_trapframe+0x14c>
	return "(unknown trap)";
f010400e:	83 fa 30             	cmp    $0x30,%edx
f0104011:	8d 83 4a 96 f7 ff    	lea    -0x869b6(%ebx),%eax
f0104017:	8d 8b 56 96 f7 ff    	lea    -0x869aa(%ebx),%ecx
f010401d:	0f 45 c1             	cmovne %ecx,%eax
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0104020:	83 ec 04             	sub    $0x4,%esp
f0104023:	50                   	push   %eax
f0104024:	52                   	push   %edx
f0104025:	8d 83 b2 96 f7 ff    	lea    -0x8694e(%ebx),%eax
f010402b:	50                   	push   %eax
f010402c:	e8 27 fb ff ff       	call   f0103b58 <cprintf>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0104031:	83 c4 10             	add    $0x10,%esp
f0104034:	39 b3 20 2b 00 00    	cmp    %esi,0x2b20(%ebx)
f010403a:	0f 84 c3 00 00 00    	je     f0104103 <print_trapframe+0x158>
	cprintf("  err  0x%08x", tf->tf_err);
f0104040:	83 ec 08             	sub    $0x8,%esp
f0104043:	ff 76 2c             	pushl  0x2c(%esi)
f0104046:	8d 83 d3 96 f7 ff    	lea    -0x8692d(%ebx),%eax
f010404c:	50                   	push   %eax
f010404d:	e8 06 fb ff ff       	call   f0103b58 <cprintf>
	if (tf->tf_trapno == T_PGFLT)
f0104052:	83 c4 10             	add    $0x10,%esp
f0104055:	83 7e 28 0e          	cmpl   $0xe,0x28(%esi)
f0104059:	0f 85 c9 00 00 00    	jne    f0104128 <print_trapframe+0x17d>
			tf->tf_err & 1 ? "protection" : "not-present");
f010405f:	8b 46 2c             	mov    0x2c(%esi),%eax
		cprintf(" [%s, %s, %s]\n",
f0104062:	89 c2                	mov    %eax,%edx
f0104064:	83 e2 01             	and    $0x1,%edx
f0104067:	8d 8b 65 96 f7 ff    	lea    -0x8699b(%ebx),%ecx
f010406d:	8d 93 70 96 f7 ff    	lea    -0x86990(%ebx),%edx
f0104073:	0f 44 ca             	cmove  %edx,%ecx
f0104076:	89 c2                	mov    %eax,%edx
f0104078:	83 e2 02             	and    $0x2,%edx
f010407b:	8d 93 7c 96 f7 ff    	lea    -0x86984(%ebx),%edx
f0104081:	8d bb 82 96 f7 ff    	lea    -0x8697e(%ebx),%edi
f0104087:	0f 44 d7             	cmove  %edi,%edx
f010408a:	83 e0 04             	and    $0x4,%eax
f010408d:	8d 83 87 96 f7 ff    	lea    -0x86979(%ebx),%eax
f0104093:	8d bb a9 97 f7 ff    	lea    -0x86857(%ebx),%edi
f0104099:	0f 44 c7             	cmove  %edi,%eax
f010409c:	51                   	push   %ecx
f010409d:	52                   	push   %edx
f010409e:	50                   	push   %eax
f010409f:	8d 83 e1 96 f7 ff    	lea    -0x8691f(%ebx),%eax
f01040a5:	50                   	push   %eax
f01040a6:	e8 ad fa ff ff       	call   f0103b58 <cprintf>
f01040ab:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f01040ae:	83 ec 08             	sub    $0x8,%esp
f01040b1:	ff 76 30             	pushl  0x30(%esi)
f01040b4:	8d 83 f0 96 f7 ff    	lea    -0x86910(%ebx),%eax
f01040ba:	50                   	push   %eax
f01040bb:	e8 98 fa ff ff       	call   f0103b58 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f01040c0:	83 c4 08             	add    $0x8,%esp
f01040c3:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f01040c7:	50                   	push   %eax
f01040c8:	8d 83 ff 96 f7 ff    	lea    -0x86901(%ebx),%eax
f01040ce:	50                   	push   %eax
f01040cf:	e8 84 fa ff ff       	call   f0103b58 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f01040d4:	83 c4 08             	add    $0x8,%esp
f01040d7:	ff 76 38             	pushl  0x38(%esi)
f01040da:	8d 83 12 97 f7 ff    	lea    -0x868ee(%ebx),%eax
f01040e0:	50                   	push   %eax
f01040e1:	e8 72 fa ff ff       	call   f0103b58 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f01040e6:	83 c4 10             	add    $0x10,%esp
f01040e9:	f6 46 34 03          	testb  $0x3,0x34(%esi)
f01040ed:	75 50                	jne    f010413f <print_trapframe+0x194>
}
f01040ef:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01040f2:	5b                   	pop    %ebx
f01040f3:	5e                   	pop    %esi
f01040f4:	5f                   	pop    %edi
f01040f5:	5d                   	pop    %ebp
f01040f6:	c3                   	ret    
		return excnames[trapno];
f01040f7:	8b 84 93 40 20 00 00 	mov    0x2040(%ebx,%edx,4),%eax
f01040fe:	e9 1d ff ff ff       	jmp    f0104020 <print_trapframe+0x75>
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0104103:	83 7e 28 0e          	cmpl   $0xe,0x28(%esi)
f0104107:	0f 85 33 ff ff ff    	jne    f0104040 <print_trapframe+0x95>
	asm volatile("movl %%cr2,%0" : "=r" (val));
f010410d:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0104110:	83 ec 08             	sub    $0x8,%esp
f0104113:	50                   	push   %eax
f0104114:	8d 83 c4 96 f7 ff    	lea    -0x8693c(%ebx),%eax
f010411a:	50                   	push   %eax
f010411b:	e8 38 fa ff ff       	call   f0103b58 <cprintf>
f0104120:	83 c4 10             	add    $0x10,%esp
f0104123:	e9 18 ff ff ff       	jmp    f0104040 <print_trapframe+0x95>
		cprintf("\n");
f0104128:	83 ec 0c             	sub    $0xc,%esp
f010412b:	8d 83 55 94 f7 ff    	lea    -0x86bab(%ebx),%eax
f0104131:	50                   	push   %eax
f0104132:	e8 21 fa ff ff       	call   f0103b58 <cprintf>
f0104137:	83 c4 10             	add    $0x10,%esp
f010413a:	e9 6f ff ff ff       	jmp    f01040ae <print_trapframe+0x103>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f010413f:	83 ec 08             	sub    $0x8,%esp
f0104142:	ff 76 3c             	pushl  0x3c(%esi)
f0104145:	8d 83 21 97 f7 ff    	lea    -0x868df(%ebx),%eax
f010414b:	50                   	push   %eax
f010414c:	e8 07 fa ff ff       	call   f0103b58 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0104151:	83 c4 08             	add    $0x8,%esp
f0104154:	0f b7 46 40          	movzwl 0x40(%esi),%eax
f0104158:	50                   	push   %eax
f0104159:	8d 83 30 97 f7 ff    	lea    -0x868d0(%ebx),%eax
f010415f:	50                   	push   %eax
f0104160:	e8 f3 f9 ff ff       	call   f0103b58 <cprintf>
f0104165:	83 c4 10             	add    $0x10,%esp
}
f0104168:	eb 85                	jmp    f01040ef <print_trapframe+0x144>

f010416a <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f010416a:	55                   	push   %ebp
f010416b:	89 e5                	mov    %esp,%ebp
f010416d:	57                   	push   %edi
f010416e:	56                   	push   %esi
f010416f:	53                   	push   %ebx
f0104170:	83 ec 0c             	sub    $0xc,%esp
f0104173:	e8 ef bf ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0104178:	81 c3 a8 8e 08 00    	add    $0x88ea8,%ebx
f010417e:	8b 75 08             	mov    0x8(%ebp),%esi
f0104181:	0f 20 d0             	mov    %cr2,%eax
	fault_va = rcr2();

	// Handle kernel-mode page faults.

	// LAB 3: Your code here.
    	if ((tf->tf_cs & 3) == 0)
f0104184:	f6 46 34 03          	testb  $0x3,0x34(%esi)
f0104188:	74 38                	je     f01041c2 <page_fault_handler+0x58>
        	panic("page_fault_handler():page fault in kernel mode!\n");
	// We've already handled kernel-mode exceptions, so if we get here,
	// the page fault happened in user mode.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f010418a:	ff 76 30             	pushl  0x30(%esi)
f010418d:	50                   	push   %eax
f010418e:	c7 c7 28 f3 18 f0    	mov    $0xf018f328,%edi
f0104194:	8b 07                	mov    (%edi),%eax
f0104196:	ff 70 48             	pushl  0x48(%eax)
f0104199:	8d 83 28 99 f7 ff    	lea    -0x866d8(%ebx),%eax
f010419f:	50                   	push   %eax
f01041a0:	e8 b3 f9 ff ff       	call   f0103b58 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f01041a5:	89 34 24             	mov    %esi,(%esp)
f01041a8:	e8 fe fd ff ff       	call   f0103fab <print_trapframe>
	env_destroy(curenv);
f01041ad:	83 c4 04             	add    $0x4,%esp
f01041b0:	ff 37                	pushl  (%edi)
f01041b2:	e8 37 f8 ff ff       	call   f01039ee <env_destroy>
}
f01041b7:	83 c4 10             	add    $0x10,%esp
f01041ba:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01041bd:	5b                   	pop    %ebx
f01041be:	5e                   	pop    %esi
f01041bf:	5f                   	pop    %edi
f01041c0:	5d                   	pop    %ebp
f01041c1:	c3                   	ret    
        	panic("page_fault_handler():page fault in kernel mode!\n");
f01041c2:	83 ec 04             	sub    $0x4,%esp
f01041c5:	8d 83 f4 98 f7 ff    	lea    -0x8670c(%ebx),%eax
f01041cb:	50                   	push   %eax
f01041cc:	68 fe 00 00 00       	push   $0xfe
f01041d1:	8d 83 43 97 f7 ff    	lea    -0x868bd(%ebx),%eax
f01041d7:	50                   	push   %eax
f01041d8:	e8 d4 be ff ff       	call   f01000b1 <_panic>

f01041dd <trap>:
{
f01041dd:	55                   	push   %ebp
f01041de:	89 e5                	mov    %esp,%ebp
f01041e0:	57                   	push   %edi
f01041e1:	56                   	push   %esi
f01041e2:	53                   	push   %ebx
f01041e3:	83 ec 0c             	sub    $0xc,%esp
f01041e6:	e8 7c bf ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01041eb:	81 c3 35 8e 08 00    	add    $0x88e35,%ebx
f01041f1:	8b 75 08             	mov    0x8(%ebp),%esi
	asm volatile("cld" ::: "cc");
f01041f4:	fc                   	cld    
	asm volatile("pushfl; popl %0" : "=r" (eflags));
f01041f5:	9c                   	pushf  
f01041f6:	58                   	pop    %eax
	assert(!(read_eflags() & FL_IF));
f01041f7:	f6 c4 02             	test   $0x2,%ah
f01041fa:	74 1f                	je     f010421b <trap+0x3e>
f01041fc:	8d 83 4f 97 f7 ff    	lea    -0x868b1(%ebx),%eax
f0104202:	50                   	push   %eax
f0104203:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f0104209:	50                   	push   %eax
f010420a:	68 d5 00 00 00       	push   $0xd5
f010420f:	8d 83 43 97 f7 ff    	lea    -0x868bd(%ebx),%eax
f0104215:	50                   	push   %eax
f0104216:	e8 96 be ff ff       	call   f01000b1 <_panic>
	cprintf("Incoming TRAP frame at %p\n", tf);
f010421b:	83 ec 08             	sub    $0x8,%esp
f010421e:	56                   	push   %esi
f010421f:	8d 83 68 97 f7 ff    	lea    -0x86898(%ebx),%eax
f0104225:	50                   	push   %eax
f0104226:	e8 2d f9 ff ff       	call   f0103b58 <cprintf>
	if ((tf->tf_cs & 3) == 3) {
f010422b:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f010422f:	83 e0 03             	and    $0x3,%eax
f0104232:	83 c4 10             	add    $0x10,%esp
f0104235:	66 83 f8 03          	cmp    $0x3,%ax
f0104239:	75 21                	jne    f010425c <trap+0x7f>
		assert(curenv);
f010423b:	c7 c0 28 f3 18 f0    	mov    $0xf018f328,%eax
f0104241:	8b 00                	mov    (%eax),%eax
f0104243:	85 c0                	test   %eax,%eax
f0104245:	0f 84 94 00 00 00    	je     f01042df <trap+0x102>
		curenv->env_tf = *tf;
f010424b:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104250:	89 c7                	mov    %eax,%edi
f0104252:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		tf = &curenv->env_tf;
f0104254:	c7 c0 28 f3 18 f0    	mov    $0xf018f328,%eax
f010425a:	8b 30                	mov    (%eax),%esi
	last_tf = tf;
f010425c:	89 b3 20 2b 00 00    	mov    %esi,0x2b20(%ebx)
	if (tf->tf_trapno == T_PGFLT) {
f0104262:	8b 46 28             	mov    0x28(%esi),%eax
f0104265:	83 f8 0e             	cmp    $0xe,%eax
f0104268:	0f 84 90 00 00 00    	je     f01042fe <trap+0x121>
	if (tf->tf_trapno == T_BRKPT) {
f010426e:	83 f8 03             	cmp    $0x3,%eax
f0104271:	0f 84 95 00 00 00    	je     f010430c <trap+0x12f>
	if (tf->tf_trapno == T_SYSCALL) {
f0104277:	83 f8 30             	cmp    $0x30,%eax
f010427a:	0f 84 9a 00 00 00    	je     f010431a <trap+0x13d>
	print_trapframe(tf);
f0104280:	83 ec 0c             	sub    $0xc,%esp
f0104283:	56                   	push   %esi
f0104284:	e8 22 fd ff ff       	call   f0103fab <print_trapframe>
	if (tf->tf_cs == GD_KT)
f0104289:	83 c4 10             	add    $0x10,%esp
f010428c:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0104291:	0f 84 b6 00 00 00    	je     f010434d <trap+0x170>
		env_destroy(curenv);
f0104297:	83 ec 0c             	sub    $0xc,%esp
f010429a:	c7 c0 28 f3 18 f0    	mov    $0xf018f328,%eax
f01042a0:	ff 30                	pushl  (%eax)
f01042a2:	e8 47 f7 ff ff       	call   f01039ee <env_destroy>
f01042a7:	83 c4 10             	add    $0x10,%esp
	assert(curenv && curenv->env_status == ENV_RUNNING);
f01042aa:	c7 c0 28 f3 18 f0    	mov    $0xf018f328,%eax
f01042b0:	8b 00                	mov    (%eax),%eax
f01042b2:	85 c0                	test   %eax,%eax
f01042b4:	74 0a                	je     f01042c0 <trap+0xe3>
f01042b6:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01042ba:	0f 84 a8 00 00 00    	je     f0104368 <trap+0x18b>
f01042c0:	8d 83 4c 99 f7 ff    	lea    -0x866b4(%ebx),%eax
f01042c6:	50                   	push   %eax
f01042c7:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01042cd:	50                   	push   %eax
f01042ce:	68 ed 00 00 00       	push   $0xed
f01042d3:	8d 83 43 97 f7 ff    	lea    -0x868bd(%ebx),%eax
f01042d9:	50                   	push   %eax
f01042da:	e8 d2 bd ff ff       	call   f01000b1 <_panic>
		assert(curenv);
f01042df:	8d 83 83 97 f7 ff    	lea    -0x8687d(%ebx),%eax
f01042e5:	50                   	push   %eax
f01042e6:	8d 83 b3 91 f7 ff    	lea    -0x86e4d(%ebx),%eax
f01042ec:	50                   	push   %eax
f01042ed:	68 db 00 00 00       	push   $0xdb
f01042f2:	8d 83 43 97 f7 ff    	lea    -0x868bd(%ebx),%eax
f01042f8:	50                   	push   %eax
f01042f9:	e8 b3 bd ff ff       	call   f01000b1 <_panic>
		page_fault_handler(tf);
f01042fe:	83 ec 0c             	sub    $0xc,%esp
f0104301:	56                   	push   %esi
f0104302:	e8 63 fe ff ff       	call   f010416a <page_fault_handler>
f0104307:	83 c4 10             	add    $0x10,%esp
f010430a:	eb 9e                	jmp    f01042aa <trap+0xcd>
		monitor(tf);
f010430c:	83 ec 0c             	sub    $0xc,%esp
f010430f:	56                   	push   %esi
f0104310:	e8 f9 c5 ff ff       	call   f010090e <monitor>
f0104315:	83 c4 10             	add    $0x10,%esp
f0104318:	eb 90                	jmp    f01042aa <trap+0xcd>
		cprintf("SYSTEM CALL\n");
f010431a:	83 ec 0c             	sub    $0xc,%esp
f010431d:	8d 83 8a 97 f7 ff    	lea    -0x86876(%ebx),%eax
f0104323:	50                   	push   %eax
f0104324:	e8 2f f8 ff ff       	call   f0103b58 <cprintf>
			syscall(tf->tf_regs.reg_eax, tf->tf_regs.reg_edx, tf->tf_regs.reg_ecx,
f0104329:	83 c4 08             	add    $0x8,%esp
f010432c:	ff 76 04             	pushl  0x4(%esi)
f010432f:	ff 36                	pushl  (%esi)
f0104331:	ff 76 10             	pushl  0x10(%esi)
f0104334:	ff 76 18             	pushl  0x18(%esi)
f0104337:	ff 76 14             	pushl  0x14(%esi)
f010433a:	ff 76 1c             	pushl  0x1c(%esi)
f010433d:	e8 93 00 00 00       	call   f01043d5 <syscall>
		tf->tf_regs.reg_eax = 
f0104342:	89 46 1c             	mov    %eax,0x1c(%esi)
f0104345:	83 c4 20             	add    $0x20,%esp
f0104348:	e9 5d ff ff ff       	jmp    f01042aa <trap+0xcd>
		panic("unhandled trap in kernel");
f010434d:	83 ec 04             	sub    $0x4,%esp
f0104350:	8d 83 97 97 f7 ff    	lea    -0x86869(%ebx),%eax
f0104356:	50                   	push   %eax
f0104357:	68 c4 00 00 00       	push   $0xc4
f010435c:	8d 83 43 97 f7 ff    	lea    -0x868bd(%ebx),%eax
f0104362:	50                   	push   %eax
f0104363:	e8 49 bd ff ff       	call   f01000b1 <_panic>
	env_run(curenv);
f0104368:	83 ec 0c             	sub    $0xc,%esp
f010436b:	50                   	push   %eax
f010436c:	e8 eb f6 ff ff       	call   f0103a5c <env_run>
f0104371:	90                   	nop

f0104372 <th0>:
.text

/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
	TRAPHANDLER_NOEC(th0, 0)
f0104372:	6a 00                	push   $0x0
f0104374:	6a 00                	push   $0x0
f0104376:	eb 4e                	jmp    f01043c6 <_alltraps>

f0104378 <th1>:
	TRAPHANDLER_NOEC(th1, 1)
f0104378:	6a 00                	push   $0x0
f010437a:	6a 01                	push   $0x1
f010437c:	eb 48                	jmp    f01043c6 <_alltraps>

f010437e <th3>:
	TRAPHANDLER_NOEC(th3, 3)
f010437e:	6a 00                	push   $0x0
f0104380:	6a 03                	push   $0x3
f0104382:	eb 42                	jmp    f01043c6 <_alltraps>

f0104384 <th4>:
	TRAPHANDLER_NOEC(th4, 4)
f0104384:	6a 00                	push   $0x0
f0104386:	6a 04                	push   $0x4
f0104388:	eb 3c                	jmp    f01043c6 <_alltraps>

f010438a <th5>:
	TRAPHANDLER_NOEC(th5, 5)
f010438a:	6a 00                	push   $0x0
f010438c:	6a 05                	push   $0x5
f010438e:	eb 36                	jmp    f01043c6 <_alltraps>

f0104390 <th6>:
	TRAPHANDLER_NOEC(th6, 6)
f0104390:	6a 00                	push   $0x0
f0104392:	6a 06                	push   $0x6
f0104394:	eb 30                	jmp    f01043c6 <_alltraps>

f0104396 <th7>:
	TRAPHANDLER_NOEC(th7, 7)
f0104396:	6a 00                	push   $0x0
f0104398:	6a 07                	push   $0x7
f010439a:	eb 2a                	jmp    f01043c6 <_alltraps>

f010439c <th8>:
	TRAPHANDLER(th8, 8)
f010439c:	6a 08                	push   $0x8
f010439e:	eb 26                	jmp    f01043c6 <_alltraps>

f01043a0 <th9>:
	TRAPHANDLER_NOEC(th9, 9)
f01043a0:	6a 00                	push   $0x0
f01043a2:	6a 09                	push   $0x9
f01043a4:	eb 20                	jmp    f01043c6 <_alltraps>

f01043a6 <th10>:
	TRAPHANDLER(th10, 10)
f01043a6:	6a 0a                	push   $0xa
f01043a8:	eb 1c                	jmp    f01043c6 <_alltraps>

f01043aa <th11>:
	TRAPHANDLER(th11, 11)
f01043aa:	6a 0b                	push   $0xb
f01043ac:	eb 18                	jmp    f01043c6 <_alltraps>

f01043ae <th12>:
	TRAPHANDLER(th12, 12)
f01043ae:	6a 0c                	push   $0xc
f01043b0:	eb 14                	jmp    f01043c6 <_alltraps>

f01043b2 <th13>:
	TRAPHANDLER(th13, 13)
f01043b2:	6a 0d                	push   $0xd
f01043b4:	eb 10                	jmp    f01043c6 <_alltraps>

f01043b6 <th14>:
	TRAPHANDLER(th14, 14)
f01043b6:	6a 0e                	push   $0xe
f01043b8:	eb 0c                	jmp    f01043c6 <_alltraps>

f01043ba <th16>:
	TRAPHANDLER_NOEC(th16, 16)
f01043ba:	6a 00                	push   $0x0
f01043bc:	6a 10                	push   $0x10
f01043be:	eb 06                	jmp    f01043c6 <_alltraps>

f01043c0 <th_syscall>:
	TRAPHANDLER_NOEC(th_syscall, T_SYSCALL)
f01043c0:	6a 00                	push   $0x0
f01043c2:	6a 30                	push   $0x30
f01043c4:	eb 00                	jmp    f01043c6 <_alltraps>

f01043c6 <_alltraps>:

/*
 * Lab 3: Your code here for _alltraps
 */
_alltraps:
	pushl %ds
f01043c6:	1e                   	push   %ds
	pushl %es
f01043c7:	06                   	push   %es
	pushal
f01043c8:	60                   	pusha  
	pushl $GD_KD
f01043c9:	6a 10                	push   $0x10
	popl %ds
f01043cb:	1f                   	pop    %ds
	pushl $GD_KD
f01043cc:	6a 10                	push   $0x10
	popl %es
f01043ce:	07                   	pop    %es
	pushl %esp
f01043cf:	54                   	push   %esp
	call trap
f01043d0:	e8 08 fe ff ff       	call   f01041dd <trap>

f01043d5 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f01043d5:	55                   	push   %ebp
f01043d6:	89 e5                	mov    %esp,%ebp
f01043d8:	53                   	push   %ebx
f01043d9:	83 ec 14             	sub    $0x14,%esp
f01043dc:	e8 86 bd ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f01043e1:	81 c3 3f 8c 08 00    	add    $0x88c3f,%ebx
f01043e7:	8b 45 08             	mov    0x8(%ebp),%eax
	// Call the function corresponding to the 'syscallno' parameter.
	// Return any appropriate return value.
	// LAB 3: Your code here.
	int ret = 0;
	switch (syscallno) {
f01043ea:	83 f8 01             	cmp    $0x1,%eax
f01043ed:	74 4d                	je     f010443c <syscall+0x67>
f01043ef:	83 f8 01             	cmp    $0x1,%eax
f01043f2:	72 11                	jb     f0104405 <syscall+0x30>
f01043f4:	83 f8 02             	cmp    $0x2,%eax
f01043f7:	74 4a                	je     f0104443 <syscall+0x6e>
f01043f9:	83 f8 03             	cmp    $0x3,%eax
f01043fc:	74 52                	je     f0104450 <syscall+0x7b>
		case SYS_env_destroy:
			sys_env_destroy(a1);
			ret = 0;
			break;
		default:
			ret = -E_INVAL;
f01043fe:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	}
	return ret;	
f0104403:	eb 32                	jmp    f0104437 <syscall+0x62>
	user_mem_assert(curenv, s, len, 0);
f0104405:	6a 00                	push   $0x0
f0104407:	ff 75 10             	pushl  0x10(%ebp)
f010440a:	ff 75 0c             	pushl  0xc(%ebp)
f010440d:	c7 c0 28 f3 18 f0    	mov    $0xf018f328,%eax
f0104413:	ff 30                	pushl  (%eax)
f0104415:	e8 bb ee ff ff       	call   f01032d5 <user_mem_assert>
	cprintf("%.*s", len, s);
f010441a:	83 c4 0c             	add    $0xc,%esp
f010441d:	ff 75 0c             	pushl  0xc(%ebp)
f0104420:	ff 75 10             	pushl  0x10(%ebp)
f0104423:	8d 83 78 99 f7 ff    	lea    -0x86688(%ebx),%eax
f0104429:	50                   	push   %eax
f010442a:	e8 29 f7 ff ff       	call   f0103b58 <cprintf>
f010442f:	83 c4 10             	add    $0x10,%esp
			ret = 0;
f0104432:	b8 00 00 00 00       	mov    $0x0,%eax
	panic("syscall not implemented");
}
f0104437:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010443a:	c9                   	leave  
f010443b:	c3                   	ret    
	return cons_getc();
f010443c:	e8 21 c1 ff ff       	call   f0100562 <cons_getc>
			break;
f0104441:	eb f4                	jmp    f0104437 <syscall+0x62>
	return curenv->env_id;
f0104443:	c7 c0 28 f3 18 f0    	mov    $0xf018f328,%eax
f0104449:	8b 00                	mov    (%eax),%eax
f010444b:	8b 40 48             	mov    0x48(%eax),%eax
			break;
f010444e:	eb e7                	jmp    f0104437 <syscall+0x62>
	if ((r = envid2env(envid, &e, 1)) < 0)
f0104450:	83 ec 04             	sub    $0x4,%esp
f0104453:	6a 01                	push   $0x1
f0104455:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104458:	50                   	push   %eax
f0104459:	ff 75 0c             	pushl  0xc(%ebp)
f010445c:	e8 79 ef ff ff       	call   f01033da <envid2env>
f0104461:	83 c4 10             	add    $0x10,%esp
f0104464:	85 c0                	test   %eax,%eax
f0104466:	78 35                	js     f010449d <syscall+0xc8>
	if (e == curenv)
f0104468:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010446b:	c7 c0 28 f3 18 f0    	mov    $0xf018f328,%eax
f0104471:	8b 00                	mov    (%eax),%eax
f0104473:	39 c2                	cmp    %eax,%edx
f0104475:	74 2d                	je     f01044a4 <syscall+0xcf>
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0104477:	83 ec 04             	sub    $0x4,%esp
f010447a:	ff 72 48             	pushl  0x48(%edx)
f010447d:	ff 70 48             	pushl  0x48(%eax)
f0104480:	8d 83 98 99 f7 ff    	lea    -0x86668(%ebx),%eax
f0104486:	50                   	push   %eax
f0104487:	e8 cc f6 ff ff       	call   f0103b58 <cprintf>
f010448c:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f010448f:	83 ec 0c             	sub    $0xc,%esp
f0104492:	ff 75 f4             	pushl  -0xc(%ebp)
f0104495:	e8 54 f5 ff ff       	call   f01039ee <env_destroy>
f010449a:	83 c4 10             	add    $0x10,%esp
			ret = 0;
f010449d:	b8 00 00 00 00       	mov    $0x0,%eax
f01044a2:	eb 93                	jmp    f0104437 <syscall+0x62>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f01044a4:	83 ec 08             	sub    $0x8,%esp
f01044a7:	ff 70 48             	pushl  0x48(%eax)
f01044aa:	8d 83 7d 99 f7 ff    	lea    -0x86683(%ebx),%eax
f01044b0:	50                   	push   %eax
f01044b1:	e8 a2 f6 ff ff       	call   f0103b58 <cprintf>
f01044b6:	83 c4 10             	add    $0x10,%esp
f01044b9:	eb d4                	jmp    f010448f <syscall+0xba>

f01044bb <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01044bb:	55                   	push   %ebp
f01044bc:	89 e5                	mov    %esp,%ebp
f01044be:	57                   	push   %edi
f01044bf:	56                   	push   %esi
f01044c0:	53                   	push   %ebx
f01044c1:	83 ec 14             	sub    $0x14,%esp
f01044c4:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01044c7:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01044ca:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f01044cd:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01044d0:	8b 32                	mov    (%edx),%esi
f01044d2:	8b 01                	mov    (%ecx),%eax
f01044d4:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01044d7:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01044de:	eb 2f                	jmp    f010450f <stab_binsearch+0x54>
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
f01044e0:	83 e8 01             	sub    $0x1,%eax
		while (m >= l && stabs[m].n_type != type)
f01044e3:	39 c6                	cmp    %eax,%esi
f01044e5:	7f 49                	jg     f0104530 <stab_binsearch+0x75>
f01044e7:	0f b6 0a             	movzbl (%edx),%ecx
f01044ea:	83 ea 0c             	sub    $0xc,%edx
f01044ed:	39 f9                	cmp    %edi,%ecx
f01044ef:	75 ef                	jne    f01044e0 <stab_binsearch+0x25>
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01044f1:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01044f4:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01044f7:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01044fb:	3b 55 0c             	cmp    0xc(%ebp),%edx
f01044fe:	73 35                	jae    f0104535 <stab_binsearch+0x7a>
			*region_left = m;
f0104500:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104503:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
f0104505:	8d 73 01             	lea    0x1(%ebx),%esi
		any_matches = 1;
f0104508:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
	while (l <= r) {
f010450f:	3b 75 f0             	cmp    -0x10(%ebp),%esi
f0104512:	7f 4e                	jg     f0104562 <stab_binsearch+0xa7>
		int true_m = (l + r) / 2, m = true_m;
f0104514:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104517:	01 f0                	add    %esi,%eax
f0104519:	89 c3                	mov    %eax,%ebx
f010451b:	c1 eb 1f             	shr    $0x1f,%ebx
f010451e:	01 c3                	add    %eax,%ebx
f0104520:	d1 fb                	sar    %ebx
f0104522:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0104525:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104528:	8d 54 81 04          	lea    0x4(%ecx,%eax,4),%edx
f010452c:	89 d8                	mov    %ebx,%eax
		while (m >= l && stabs[m].n_type != type)
f010452e:	eb b3                	jmp    f01044e3 <stab_binsearch+0x28>
			l = true_m + 1;
f0104530:	8d 73 01             	lea    0x1(%ebx),%esi
			continue;
f0104533:	eb da                	jmp    f010450f <stab_binsearch+0x54>
		} else if (stabs[m].n_value > addr) {
f0104535:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0104538:	76 14                	jbe    f010454e <stab_binsearch+0x93>
			*region_right = m - 1;
f010453a:	83 e8 01             	sub    $0x1,%eax
f010453d:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104540:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104543:	89 03                	mov    %eax,(%ebx)
		any_matches = 1;
f0104545:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010454c:	eb c1                	jmp    f010450f <stab_binsearch+0x54>
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010454e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104551:	89 06                	mov    %eax,(%esi)
			l = m;
			addr++;
f0104553:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104557:	89 c6                	mov    %eax,%esi
		any_matches = 1;
f0104559:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104560:	eb ad                	jmp    f010450f <stab_binsearch+0x54>
		}
	}

	if (!any_matches)
f0104562:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0104566:	74 16                	je     f010457e <stab_binsearch+0xc3>
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104568:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010456b:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010456d:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104570:	8b 0e                	mov    (%esi),%ecx
f0104572:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104575:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0104578:	8d 54 96 04          	lea    0x4(%esi,%edx,4),%edx
		for (l = *region_right;
f010457c:	eb 12                	jmp    f0104590 <stab_binsearch+0xd5>
		*region_right = *region_left - 1;
f010457e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104581:	8b 00                	mov    (%eax),%eax
f0104583:	83 e8 01             	sub    $0x1,%eax
f0104586:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104589:	89 07                	mov    %eax,(%edi)
f010458b:	eb 16                	jmp    f01045a3 <stab_binsearch+0xe8>
		     l--)
f010458d:	83 e8 01             	sub    $0x1,%eax
		for (l = *region_right;
f0104590:	39 c1                	cmp    %eax,%ecx
f0104592:	7d 0a                	jge    f010459e <stab_binsearch+0xe3>
		     l > *region_left && stabs[l].n_type != type;
f0104594:	0f b6 1a             	movzbl (%edx),%ebx
f0104597:	83 ea 0c             	sub    $0xc,%edx
f010459a:	39 fb                	cmp    %edi,%ebx
f010459c:	75 ef                	jne    f010458d <stab_binsearch+0xd2>
			/* do nothing */;
		*region_left = l;
f010459e:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01045a1:	89 07                	mov    %eax,(%edi)
	}
}
f01045a3:	83 c4 14             	add    $0x14,%esp
f01045a6:	5b                   	pop    %ebx
f01045a7:	5e                   	pop    %esi
f01045a8:	5f                   	pop    %edi
f01045a9:	5d                   	pop    %ebp
f01045aa:	c3                   	ret    

f01045ab <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01045ab:	55                   	push   %ebp
f01045ac:	89 e5                	mov    %esp,%ebp
f01045ae:	57                   	push   %edi
f01045af:	56                   	push   %esi
f01045b0:	53                   	push   %ebx
f01045b1:	83 ec 4c             	sub    $0x4c,%esp
f01045b4:	e8 81 ed ff ff       	call   f010333a <__x86.get_pc_thunk.di>
f01045b9:	81 c7 67 8a 08 00    	add    $0x88a67,%edi
f01045bf:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f01045c2:	8d 87 b0 99 f7 ff    	lea    -0x86650(%edi),%eax
f01045c8:	89 06                	mov    %eax,(%esi)
	info->eip_line = 0;
f01045ca:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f01045d1:	89 46 08             	mov    %eax,0x8(%esi)
	info->eip_fn_namelen = 9;
f01045d4:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f01045db:	8b 45 08             	mov    0x8(%ebp),%eax
f01045de:	89 46 10             	mov    %eax,0x10(%esi)
	info->eip_fn_narg = 0;
f01045e1:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01045e8:	3d ff ff 7f ef       	cmp    $0xef7fffff,%eax
f01045ed:	77 21                	ja     f0104610 <debuginfo_eip+0x65>

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.

		stabs = usd->stabs;
f01045ef:	a1 00 00 20 00       	mov    0x200000,%eax
f01045f4:	89 45 b8             	mov    %eax,-0x48(%ebp)
		stab_end = usd->stab_end;
f01045f7:	a1 04 00 20 00       	mov    0x200004,%eax
		stabstr = usd->stabstr;
f01045fc:	8b 1d 08 00 20 00    	mov    0x200008,%ebx
f0104602:	89 5d b4             	mov    %ebx,-0x4c(%ebp)
		stabstr_end = usd->stabstr_end;
f0104605:	8b 1d 0c 00 20 00    	mov    0x20000c,%ebx
f010460b:	89 5d bc             	mov    %ebx,-0x44(%ebp)
f010460e:	eb 21                	jmp    f0104631 <debuginfo_eip+0x86>
		stabstr_end = __STABSTR_END__;
f0104610:	c7 c0 4b 21 11 f0    	mov    $0xf011214b,%eax
f0104616:	89 45 bc             	mov    %eax,-0x44(%ebp)
		stabstr = __STABSTR_BEGIN__;
f0104619:	c7 c0 75 f6 10 f0    	mov    $0xf010f675,%eax
f010461f:	89 45 b4             	mov    %eax,-0x4c(%ebp)
		stab_end = __STAB_END__;
f0104622:	c7 c0 74 f6 10 f0    	mov    $0xf010f674,%eax
		stabs = __STAB_BEGIN__;
f0104628:	c7 c3 cc 6b 10 f0    	mov    $0xf0106bcc,%ebx
f010462e:	89 5d b8             	mov    %ebx,-0x48(%ebp)
		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104631:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0104634:	39 4d b4             	cmp    %ecx,-0x4c(%ebp)
f0104637:	0f 83 b1 01 00 00    	jae    f01047ee <debuginfo_eip+0x243>
f010463d:	80 79 ff 00          	cmpb   $0x0,-0x1(%ecx)
f0104641:	0f 85 ae 01 00 00    	jne    f01047f5 <debuginfo_eip+0x24a>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104647:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010464e:	8b 5d b8             	mov    -0x48(%ebp),%ebx
f0104651:	29 d8                	sub    %ebx,%eax
f0104653:	c1 f8 02             	sar    $0x2,%eax
f0104656:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f010465c:	83 e8 01             	sub    $0x1,%eax
f010465f:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0104662:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0104665:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104668:	ff 75 08             	pushl  0x8(%ebp)
f010466b:	6a 64                	push   $0x64
f010466d:	89 d8                	mov    %ebx,%eax
f010466f:	e8 47 fe ff ff       	call   f01044bb <stab_binsearch>
	if (lfile == 0)
f0104674:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104677:	83 c4 08             	add    $0x8,%esp
f010467a:	85 c0                	test   %eax,%eax
f010467c:	0f 84 7a 01 00 00    	je     f01047fc <debuginfo_eip+0x251>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0104682:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104685:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104688:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010468b:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010468e:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0104691:	ff 75 08             	pushl  0x8(%ebp)
f0104694:	6a 24                	push   $0x24
f0104696:	89 d8                	mov    %ebx,%eax
f0104698:	e8 1e fe ff ff       	call   f01044bb <stab_binsearch>

	if (lfun <= rfun) {
f010469d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01046a0:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01046a3:	83 c4 08             	add    $0x8,%esp
f01046a6:	39 d0                	cmp    %edx,%eax
f01046a8:	0f 8f 85 00 00 00    	jg     f0104733 <debuginfo_eip+0x188>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01046ae:	8d 0c 40             	lea    (%eax,%eax,2),%ecx
f01046b1:	8d 1c 8b             	lea    (%ebx,%ecx,4),%ebx
f01046b4:	89 5d c4             	mov    %ebx,-0x3c(%ebp)
f01046b7:	8b 0b                	mov    (%ebx),%ecx
f01046b9:	89 cb                	mov    %ecx,%ebx
f01046bb:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f01046be:	2b 4d b4             	sub    -0x4c(%ebp),%ecx
f01046c1:	39 cb                	cmp    %ecx,%ebx
f01046c3:	73 06                	jae    f01046cb <debuginfo_eip+0x120>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01046c5:	03 5d b4             	add    -0x4c(%ebp),%ebx
f01046c8:	89 5e 08             	mov    %ebx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f01046cb:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f01046ce:	8b 4b 08             	mov    0x8(%ebx),%ecx
f01046d1:	89 4e 10             	mov    %ecx,0x10(%esi)
		addr -= info->eip_fn_addr;
f01046d4:	29 4d 08             	sub    %ecx,0x8(%ebp)
		// Search within the function definition for the line number.
		lline = lfun;
f01046d7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01046da:	89 55 d0             	mov    %edx,-0x30(%ebp)
		info->eip_fn_addr = addr;
		lline = lfile;
		rline = rfile;
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01046dd:	83 ec 08             	sub    $0x8,%esp
f01046e0:	6a 3a                	push   $0x3a
f01046e2:	ff 76 08             	pushl  0x8(%esi)
f01046e5:	89 fb                	mov    %edi,%ebx
f01046e7:	e8 8d 09 00 00       	call   f0105079 <strfind>
f01046ec:	2b 46 08             	sub    0x8(%esi),%eax
f01046ef:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01046f2:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01046f5:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01046f8:	83 c4 08             	add    $0x8,%esp
f01046fb:	ff 75 08             	pushl  0x8(%ebp)
f01046fe:	6a 44                	push   $0x44
f0104700:	8b 7d b8             	mov    -0x48(%ebp),%edi
f0104703:	89 f8                	mov    %edi,%eax
f0104705:	e8 b1 fd ff ff       	call   f01044bb <stab_binsearch>
	info->eip_line = stabs[lline].n_desc;
f010470a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010470d:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104710:	c1 e2 02             	shl    $0x2,%edx
f0104713:	0f b7 4c 17 06       	movzwl 0x6(%edi,%edx,1),%ecx
f0104718:	89 4e 04             	mov    %ecx,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010471b:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010471e:	8d 54 17 04          	lea    0x4(%edi,%edx,1),%edx
f0104722:	83 c4 10             	add    $0x10,%esp
f0104725:	c6 45 c4 00          	movb   $0x0,-0x3c(%ebp)
f0104729:	bf 01 00 00 00       	mov    $0x1,%edi
f010472e:	89 75 0c             	mov    %esi,0xc(%ebp)
f0104731:	eb 1f                	jmp    f0104752 <debuginfo_eip+0x1a7>
		info->eip_fn_addr = addr;
f0104733:	8b 45 08             	mov    0x8(%ebp),%eax
f0104736:	89 46 10             	mov    %eax,0x10(%esi)
		lline = lfile;
f0104739:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010473c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f010473f:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104742:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0104745:	eb 96                	jmp    f01046dd <debuginfo_eip+0x132>
f0104747:	83 e8 01             	sub    $0x1,%eax
f010474a:	83 ea 0c             	sub    $0xc,%edx
f010474d:	89 f9                	mov    %edi,%ecx
f010474f:	88 4d c4             	mov    %cl,-0x3c(%ebp)
f0104752:	89 45 c0             	mov    %eax,-0x40(%ebp)
	while (lline >= lfile
f0104755:	39 c3                	cmp    %eax,%ebx
f0104757:	7f 24                	jg     f010477d <debuginfo_eip+0x1d2>
	       && stabs[lline].n_type != N_SOL
f0104759:	0f b6 0a             	movzbl (%edx),%ecx
f010475c:	80 f9 84             	cmp    $0x84,%cl
f010475f:	74 42                	je     f01047a3 <debuginfo_eip+0x1f8>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104761:	80 f9 64             	cmp    $0x64,%cl
f0104764:	75 e1                	jne    f0104747 <debuginfo_eip+0x19c>
f0104766:	83 7a 04 00          	cmpl   $0x0,0x4(%edx)
f010476a:	74 db                	je     f0104747 <debuginfo_eip+0x19c>
f010476c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010476f:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f0104773:	74 37                	je     f01047ac <debuginfo_eip+0x201>
f0104775:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0104778:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f010477b:	eb 2f                	jmp    f01047ac <debuginfo_eip+0x201>
f010477d:	8b 75 0c             	mov    0xc(%ebp),%esi
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104780:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104783:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104786:	b8 00 00 00 00       	mov    $0x0,%eax
	if (lfun < rfun)
f010478b:	39 da                	cmp    %ebx,%edx
f010478d:	7d 79                	jge    f0104808 <debuginfo_eip+0x25d>
		for (lline = lfun + 1;
f010478f:	83 c2 01             	add    $0x1,%edx
f0104792:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104795:	89 d0                	mov    %edx,%eax
f0104797:	8d 14 52             	lea    (%edx,%edx,2),%edx
f010479a:	8b 7d b8             	mov    -0x48(%ebp),%edi
f010479d:	8d 54 97 04          	lea    0x4(%edi,%edx,4),%edx
f01047a1:	eb 32                	jmp    f01047d5 <debuginfo_eip+0x22a>
f01047a3:	8b 75 0c             	mov    0xc(%ebp),%esi
f01047a6:	80 7d c4 00          	cmpb   $0x0,-0x3c(%ebp)
f01047aa:	75 1d                	jne    f01047c9 <debuginfo_eip+0x21e>
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01047ac:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01047af:	8b 7d b8             	mov    -0x48(%ebp),%edi
f01047b2:	8b 14 87             	mov    (%edi,%eax,4),%edx
f01047b5:	8b 45 bc             	mov    -0x44(%ebp),%eax
f01047b8:	8b 7d b4             	mov    -0x4c(%ebp),%edi
f01047bb:	29 f8                	sub    %edi,%eax
f01047bd:	39 c2                	cmp    %eax,%edx
f01047bf:	73 bf                	jae    f0104780 <debuginfo_eip+0x1d5>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01047c1:	89 f8                	mov    %edi,%eax
f01047c3:	01 d0                	add    %edx,%eax
f01047c5:	89 06                	mov    %eax,(%esi)
f01047c7:	eb b7                	jmp    f0104780 <debuginfo_eip+0x1d5>
f01047c9:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01047cc:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01047cf:	eb db                	jmp    f01047ac <debuginfo_eip+0x201>
			info->eip_fn_narg++;
f01047d1:	83 46 14 01          	addl   $0x1,0x14(%esi)
		for (lline = lfun + 1;
f01047d5:	39 c3                	cmp    %eax,%ebx
f01047d7:	7e 2a                	jle    f0104803 <debuginfo_eip+0x258>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01047d9:	0f b6 0a             	movzbl (%edx),%ecx
f01047dc:	83 c0 01             	add    $0x1,%eax
f01047df:	83 c2 0c             	add    $0xc,%edx
f01047e2:	80 f9 a0             	cmp    $0xa0,%cl
f01047e5:	74 ea                	je     f01047d1 <debuginfo_eip+0x226>
	return 0;
f01047e7:	b8 00 00 00 00       	mov    $0x0,%eax
f01047ec:	eb 1a                	jmp    f0104808 <debuginfo_eip+0x25d>
		return -1;
f01047ee:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01047f3:	eb 13                	jmp    f0104808 <debuginfo_eip+0x25d>
f01047f5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01047fa:	eb 0c                	jmp    f0104808 <debuginfo_eip+0x25d>
		return -1;
f01047fc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104801:	eb 05                	jmp    f0104808 <debuginfo_eip+0x25d>
	return 0;
f0104803:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104808:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010480b:	5b                   	pop    %ebx
f010480c:	5e                   	pop    %esi
f010480d:	5f                   	pop    %edi
f010480e:	5d                   	pop    %ebp
f010480f:	c3                   	ret    

f0104810 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104810:	55                   	push   %ebp
f0104811:	89 e5                	mov    %esp,%ebp
f0104813:	57                   	push   %edi
f0104814:	56                   	push   %esi
f0104815:	53                   	push   %ebx
f0104816:	83 ec 2c             	sub    $0x2c,%esp
f0104819:	e8 14 eb ff ff       	call   f0103332 <__x86.get_pc_thunk.cx>
f010481e:	81 c1 02 88 08 00    	add    $0x88802,%ecx
f0104824:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0104827:	89 c7                	mov    %eax,%edi
f0104829:	89 d6                	mov    %edx,%esi
f010482b:	8b 45 08             	mov    0x8(%ebp),%eax
f010482e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104831:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0104834:	89 55 d4             	mov    %edx,-0x2c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104837:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010483a:	bb 00 00 00 00       	mov    $0x0,%ebx
f010483f:	89 4d d8             	mov    %ecx,-0x28(%ebp)
f0104842:	89 5d dc             	mov    %ebx,-0x24(%ebp)
f0104845:	39 d3                	cmp    %edx,%ebx
f0104847:	72 09                	jb     f0104852 <printnum+0x42>
f0104849:	39 45 10             	cmp    %eax,0x10(%ebp)
f010484c:	0f 87 83 00 00 00    	ja     f01048d5 <printnum+0xc5>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104852:	83 ec 0c             	sub    $0xc,%esp
f0104855:	ff 75 18             	pushl  0x18(%ebp)
f0104858:	8b 45 14             	mov    0x14(%ebp),%eax
f010485b:	8d 58 ff             	lea    -0x1(%eax),%ebx
f010485e:	53                   	push   %ebx
f010485f:	ff 75 10             	pushl  0x10(%ebp)
f0104862:	83 ec 08             	sub    $0x8,%esp
f0104865:	ff 75 dc             	pushl  -0x24(%ebp)
f0104868:	ff 75 d8             	pushl  -0x28(%ebp)
f010486b:	ff 75 d4             	pushl  -0x2c(%ebp)
f010486e:	ff 75 d0             	pushl  -0x30(%ebp)
f0104871:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104874:	e8 27 0a 00 00       	call   f01052a0 <__udivdi3>
f0104879:	83 c4 18             	add    $0x18,%esp
f010487c:	52                   	push   %edx
f010487d:	50                   	push   %eax
f010487e:	89 f2                	mov    %esi,%edx
f0104880:	89 f8                	mov    %edi,%eax
f0104882:	e8 89 ff ff ff       	call   f0104810 <printnum>
f0104887:	83 c4 20             	add    $0x20,%esp
f010488a:	eb 13                	jmp    f010489f <printnum+0x8f>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010488c:	83 ec 08             	sub    $0x8,%esp
f010488f:	56                   	push   %esi
f0104890:	ff 75 18             	pushl  0x18(%ebp)
f0104893:	ff d7                	call   *%edi
f0104895:	83 c4 10             	add    $0x10,%esp
		while (--width > 0)
f0104898:	83 eb 01             	sub    $0x1,%ebx
f010489b:	85 db                	test   %ebx,%ebx
f010489d:	7f ed                	jg     f010488c <printnum+0x7c>
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010489f:	83 ec 08             	sub    $0x8,%esp
f01048a2:	56                   	push   %esi
f01048a3:	83 ec 04             	sub    $0x4,%esp
f01048a6:	ff 75 dc             	pushl  -0x24(%ebp)
f01048a9:	ff 75 d8             	pushl  -0x28(%ebp)
f01048ac:	ff 75 d4             	pushl  -0x2c(%ebp)
f01048af:	ff 75 d0             	pushl  -0x30(%ebp)
f01048b2:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01048b5:	89 f3                	mov    %esi,%ebx
f01048b7:	e8 04 0b 00 00       	call   f01053c0 <__umoddi3>
f01048bc:	83 c4 14             	add    $0x14,%esp
f01048bf:	0f be 84 06 ba 99 f7 	movsbl -0x86646(%esi,%eax,1),%eax
f01048c6:	ff 
f01048c7:	50                   	push   %eax
f01048c8:	ff d7                	call   *%edi
}
f01048ca:	83 c4 10             	add    $0x10,%esp
f01048cd:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01048d0:	5b                   	pop    %ebx
f01048d1:	5e                   	pop    %esi
f01048d2:	5f                   	pop    %edi
f01048d3:	5d                   	pop    %ebp
f01048d4:	c3                   	ret    
f01048d5:	8b 5d 14             	mov    0x14(%ebp),%ebx
f01048d8:	eb be                	jmp    f0104898 <printnum+0x88>

f01048da <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01048da:	55                   	push   %ebp
f01048db:	89 e5                	mov    %esp,%ebp
f01048dd:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01048e0:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01048e4:	8b 10                	mov    (%eax),%edx
f01048e6:	3b 50 04             	cmp    0x4(%eax),%edx
f01048e9:	73 0a                	jae    f01048f5 <sprintputch+0x1b>
		*b->buf++ = ch;
f01048eb:	8d 4a 01             	lea    0x1(%edx),%ecx
f01048ee:	89 08                	mov    %ecx,(%eax)
f01048f0:	8b 45 08             	mov    0x8(%ebp),%eax
f01048f3:	88 02                	mov    %al,(%edx)
}
f01048f5:	5d                   	pop    %ebp
f01048f6:	c3                   	ret    

f01048f7 <printfmt>:
{
f01048f7:	55                   	push   %ebp
f01048f8:	89 e5                	mov    %esp,%ebp
f01048fa:	83 ec 08             	sub    $0x8,%esp
	va_start(ap, fmt);
f01048fd:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104900:	50                   	push   %eax
f0104901:	ff 75 10             	pushl  0x10(%ebp)
f0104904:	ff 75 0c             	pushl  0xc(%ebp)
f0104907:	ff 75 08             	pushl  0x8(%ebp)
f010490a:	e8 05 00 00 00       	call   f0104914 <vprintfmt>
}
f010490f:	83 c4 10             	add    $0x10,%esp
f0104912:	c9                   	leave  
f0104913:	c3                   	ret    

f0104914 <vprintfmt>:
{
f0104914:	55                   	push   %ebp
f0104915:	89 e5                	mov    %esp,%ebp
f0104917:	57                   	push   %edi
f0104918:	56                   	push   %esi
f0104919:	53                   	push   %ebx
f010491a:	83 ec 2c             	sub    $0x2c,%esp
f010491d:	e8 45 b8 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0104922:	81 c3 fe 86 08 00    	add    $0x886fe,%ebx
f0104928:	8b 75 0c             	mov    0xc(%ebp),%esi
f010492b:	8b 7d 10             	mov    0x10(%ebp),%edi
f010492e:	e9 c3 03 00 00       	jmp    f0104cf6 <.L35+0x48>
		padc = ' ';
f0104933:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
		altflag = 0;
f0104937:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
		precision = -1;
f010493e:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
		width = -1;
f0104945:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
		lflag = 0;
f010494c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104951:	89 4d d0             	mov    %ecx,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0104954:	8d 47 01             	lea    0x1(%edi),%eax
f0104957:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010495a:	0f b6 17             	movzbl (%edi),%edx
f010495d:	8d 42 dd             	lea    -0x23(%edx),%eax
f0104960:	3c 55                	cmp    $0x55,%al
f0104962:	0f 87 16 04 00 00    	ja     f0104d7e <.L22>
f0104968:	0f b6 c0             	movzbl %al,%eax
f010496b:	89 d9                	mov    %ebx,%ecx
f010496d:	03 8c 83 44 9a f7 ff 	add    -0x865bc(%ebx,%eax,4),%ecx
f0104974:	ff e1                	jmp    *%ecx

f0104976 <.L69>:
f0104976:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
f0104979:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
f010497d:	eb d5                	jmp    f0104954 <vprintfmt+0x40>

f010497f <.L28>:
		switch (ch = *(unsigned char *) fmt++) {
f010497f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '0';
f0104982:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0104986:	eb cc                	jmp    f0104954 <vprintfmt+0x40>

f0104988 <.L29>:
		switch (ch = *(unsigned char *) fmt++) {
f0104988:	0f b6 d2             	movzbl %dl,%edx
f010498b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			for (precision = 0; ; ++fmt) {
f010498e:	b8 00 00 00 00       	mov    $0x0,%eax
				precision = precision * 10 + ch - '0';
f0104993:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0104996:	8d 44 42 d0          	lea    -0x30(%edx,%eax,2),%eax
				ch = *fmt;
f010499a:	0f be 17             	movsbl (%edi),%edx
				if (ch < '0' || ch > '9')
f010499d:	8d 4a d0             	lea    -0x30(%edx),%ecx
f01049a0:	83 f9 09             	cmp    $0x9,%ecx
f01049a3:	77 55                	ja     f01049fa <.L23+0xf>
			for (precision = 0; ; ++fmt) {
f01049a5:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
f01049a8:	eb e9                	jmp    f0104993 <.L29+0xb>

f01049aa <.L26>:
			precision = va_arg(ap, int);
f01049aa:	8b 45 14             	mov    0x14(%ebp),%eax
f01049ad:	8b 00                	mov    (%eax),%eax
f01049af:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01049b2:	8b 45 14             	mov    0x14(%ebp),%eax
f01049b5:	8d 40 04             	lea    0x4(%eax),%eax
f01049b8:	89 45 14             	mov    %eax,0x14(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01049bb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
f01049be:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01049c2:	79 90                	jns    f0104954 <vprintfmt+0x40>
				width = precision, precision = -1;
f01049c4:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01049c7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01049ca:	c7 45 cc ff ff ff ff 	movl   $0xffffffff,-0x34(%ebp)
f01049d1:	eb 81                	jmp    f0104954 <vprintfmt+0x40>

f01049d3 <.L27>:
f01049d3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01049d6:	85 c0                	test   %eax,%eax
f01049d8:	ba 00 00 00 00       	mov    $0x0,%edx
f01049dd:	0f 49 d0             	cmovns %eax,%edx
f01049e0:	89 55 e0             	mov    %edx,-0x20(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f01049e3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f01049e6:	e9 69 ff ff ff       	jmp    f0104954 <vprintfmt+0x40>

f01049eb <.L23>:
f01049eb:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			altflag = 1;
f01049ee:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f01049f5:	e9 5a ff ff ff       	jmp    f0104954 <vprintfmt+0x40>
f01049fa:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01049fd:	eb bf                	jmp    f01049be <.L26+0x14>

f01049ff <.L33>:
			lflag++;
f01049ff:	83 45 d0 01          	addl   $0x1,-0x30(%ebp)
		switch (ch = *(unsigned char *) fmt++) {
f0104a03:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;
f0104a06:	e9 49 ff ff ff       	jmp    f0104954 <vprintfmt+0x40>

f0104a0b <.L30>:
			putch(va_arg(ap, int), putdat);
f0104a0b:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a0e:	8d 78 04             	lea    0x4(%eax),%edi
f0104a11:	83 ec 08             	sub    $0x8,%esp
f0104a14:	56                   	push   %esi
f0104a15:	ff 30                	pushl  (%eax)
f0104a17:	ff 55 08             	call   *0x8(%ebp)
			break;
f0104a1a:	83 c4 10             	add    $0x10,%esp
			putch(va_arg(ap, int), putdat);
f0104a1d:	89 7d 14             	mov    %edi,0x14(%ebp)
			break;
f0104a20:	e9 ce 02 00 00       	jmp    f0104cf3 <.L35+0x45>

f0104a25 <.L32>:
			err = va_arg(ap, int);
f0104a25:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a28:	8d 78 04             	lea    0x4(%eax),%edi
f0104a2b:	8b 00                	mov    (%eax),%eax
f0104a2d:	99                   	cltd   
f0104a2e:	31 d0                	xor    %edx,%eax
f0104a30:	29 d0                	sub    %edx,%eax
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104a32:	83 f8 06             	cmp    $0x6,%eax
f0104a35:	7f 27                	jg     f0104a5e <.L32+0x39>
f0104a37:	8b 94 83 90 20 00 00 	mov    0x2090(%ebx,%eax,4),%edx
f0104a3e:	85 d2                	test   %edx,%edx
f0104a40:	74 1c                	je     f0104a5e <.L32+0x39>
				printfmt(putch, putdat, "%s", p);
f0104a42:	52                   	push   %edx
f0104a43:	8d 83 c5 91 f7 ff    	lea    -0x86e3b(%ebx),%eax
f0104a49:	50                   	push   %eax
f0104a4a:	56                   	push   %esi
f0104a4b:	ff 75 08             	pushl  0x8(%ebp)
f0104a4e:	e8 a4 fe ff ff       	call   f01048f7 <printfmt>
f0104a53:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0104a56:	89 7d 14             	mov    %edi,0x14(%ebp)
f0104a59:	e9 95 02 00 00       	jmp    f0104cf3 <.L35+0x45>
				printfmt(putch, putdat, "error %d", err);
f0104a5e:	50                   	push   %eax
f0104a5f:	8d 83 d2 99 f7 ff    	lea    -0x8662e(%ebx),%eax
f0104a65:	50                   	push   %eax
f0104a66:	56                   	push   %esi
f0104a67:	ff 75 08             	pushl  0x8(%ebp)
f0104a6a:	e8 88 fe ff ff       	call   f01048f7 <printfmt>
f0104a6f:	83 c4 10             	add    $0x10,%esp
			err = va_arg(ap, int);
f0104a72:	89 7d 14             	mov    %edi,0x14(%ebp)
				printfmt(putch, putdat, "error %d", err);
f0104a75:	e9 79 02 00 00       	jmp    f0104cf3 <.L35+0x45>

f0104a7a <.L36>:
			if ((p = va_arg(ap, char *)) == NULL)
f0104a7a:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a7d:	83 c0 04             	add    $0x4,%eax
f0104a80:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0104a83:	8b 45 14             	mov    0x14(%ebp),%eax
f0104a86:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0104a88:	85 ff                	test   %edi,%edi
f0104a8a:	8d 83 cb 99 f7 ff    	lea    -0x86635(%ebx),%eax
f0104a90:	0f 44 f8             	cmove  %eax,%edi
			if (width > 0 && padc != '-')
f0104a93:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104a97:	0f 8e b5 00 00 00    	jle    f0104b52 <.L36+0xd8>
f0104a9d:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0104aa1:	75 08                	jne    f0104aab <.L36+0x31>
f0104aa3:	89 75 0c             	mov    %esi,0xc(%ebp)
f0104aa6:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0104aa9:	eb 6d                	jmp    f0104b18 <.L36+0x9e>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104aab:	83 ec 08             	sub    $0x8,%esp
f0104aae:	ff 75 cc             	pushl  -0x34(%ebp)
f0104ab1:	57                   	push   %edi
f0104ab2:	e8 7e 04 00 00       	call   f0104f35 <strnlen>
f0104ab7:	8b 55 e0             	mov    -0x20(%ebp),%edx
f0104aba:	29 c2                	sub    %eax,%edx
f0104abc:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0104abf:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0104ac2:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0104ac6:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104ac9:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0104acc:	89 d7                	mov    %edx,%edi
				for (width -= strnlen(p, precision); width > 0; width--)
f0104ace:	eb 10                	jmp    f0104ae0 <.L36+0x66>
					putch(padc, putdat);
f0104ad0:	83 ec 08             	sub    $0x8,%esp
f0104ad3:	56                   	push   %esi
f0104ad4:	ff 75 e0             	pushl  -0x20(%ebp)
f0104ad7:	ff 55 08             	call   *0x8(%ebp)
				for (width -= strnlen(p, precision); width > 0; width--)
f0104ada:	83 ef 01             	sub    $0x1,%edi
f0104add:	83 c4 10             	add    $0x10,%esp
f0104ae0:	85 ff                	test   %edi,%edi
f0104ae2:	7f ec                	jg     f0104ad0 <.L36+0x56>
f0104ae4:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104ae7:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0104aea:	85 d2                	test   %edx,%edx
f0104aec:	b8 00 00 00 00       	mov    $0x0,%eax
f0104af1:	0f 49 c2             	cmovns %edx,%eax
f0104af4:	29 c2                	sub    %eax,%edx
f0104af6:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0104af9:	89 75 0c             	mov    %esi,0xc(%ebp)
f0104afc:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0104aff:	eb 17                	jmp    f0104b18 <.L36+0x9e>
				if (altflag && (ch < ' ' || ch > '~'))
f0104b01:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104b05:	75 30                	jne    f0104b37 <.L36+0xbd>
					putch(ch, putdat);
f0104b07:	83 ec 08             	sub    $0x8,%esp
f0104b0a:	ff 75 0c             	pushl  0xc(%ebp)
f0104b0d:	50                   	push   %eax
f0104b0e:	ff 55 08             	call   *0x8(%ebp)
f0104b11:	83 c4 10             	add    $0x10,%esp
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104b14:	83 6d e0 01          	subl   $0x1,-0x20(%ebp)
f0104b18:	83 c7 01             	add    $0x1,%edi
f0104b1b:	0f b6 57 ff          	movzbl -0x1(%edi),%edx
f0104b1f:	0f be c2             	movsbl %dl,%eax
f0104b22:	85 c0                	test   %eax,%eax
f0104b24:	74 52                	je     f0104b78 <.L36+0xfe>
f0104b26:	85 f6                	test   %esi,%esi
f0104b28:	78 d7                	js     f0104b01 <.L36+0x87>
f0104b2a:	83 ee 01             	sub    $0x1,%esi
f0104b2d:	79 d2                	jns    f0104b01 <.L36+0x87>
f0104b2f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104b32:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104b35:	eb 32                	jmp    f0104b69 <.L36+0xef>
				if (altflag && (ch < ' ' || ch > '~'))
f0104b37:	0f be d2             	movsbl %dl,%edx
f0104b3a:	83 ea 20             	sub    $0x20,%edx
f0104b3d:	83 fa 5e             	cmp    $0x5e,%edx
f0104b40:	76 c5                	jbe    f0104b07 <.L36+0x8d>
					putch('?', putdat);
f0104b42:	83 ec 08             	sub    $0x8,%esp
f0104b45:	ff 75 0c             	pushl  0xc(%ebp)
f0104b48:	6a 3f                	push   $0x3f
f0104b4a:	ff 55 08             	call   *0x8(%ebp)
f0104b4d:	83 c4 10             	add    $0x10,%esp
f0104b50:	eb c2                	jmp    f0104b14 <.L36+0x9a>
f0104b52:	89 75 0c             	mov    %esi,0xc(%ebp)
f0104b55:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0104b58:	eb be                	jmp    f0104b18 <.L36+0x9e>
				putch(' ', putdat);
f0104b5a:	83 ec 08             	sub    $0x8,%esp
f0104b5d:	56                   	push   %esi
f0104b5e:	6a 20                	push   $0x20
f0104b60:	ff 55 08             	call   *0x8(%ebp)
			for (; width > 0; width--)
f0104b63:	83 ef 01             	sub    $0x1,%edi
f0104b66:	83 c4 10             	add    $0x10,%esp
f0104b69:	85 ff                	test   %edi,%edi
f0104b6b:	7f ed                	jg     f0104b5a <.L36+0xe0>
			if ((p = va_arg(ap, char *)) == NULL)
f0104b6d:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104b70:	89 45 14             	mov    %eax,0x14(%ebp)
f0104b73:	e9 7b 01 00 00       	jmp    f0104cf3 <.L35+0x45>
f0104b78:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104b7b:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104b7e:	eb e9                	jmp    f0104b69 <.L36+0xef>

f0104b80 <.L31>:
f0104b80:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0104b83:	83 f9 01             	cmp    $0x1,%ecx
f0104b86:	7e 40                	jle    f0104bc8 <.L31+0x48>
		return va_arg(*ap, long long);
f0104b88:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b8b:	8b 50 04             	mov    0x4(%eax),%edx
f0104b8e:	8b 00                	mov    (%eax),%eax
f0104b90:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104b93:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104b96:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b99:	8d 40 08             	lea    0x8(%eax),%eax
f0104b9c:	89 45 14             	mov    %eax,0x14(%ebp)
			if ((long long) num < 0) {
f0104b9f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104ba3:	79 55                	jns    f0104bfa <.L31+0x7a>
				putch('-', putdat);
f0104ba5:	83 ec 08             	sub    $0x8,%esp
f0104ba8:	56                   	push   %esi
f0104ba9:	6a 2d                	push   $0x2d
f0104bab:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0104bae:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104bb1:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0104bb4:	f7 da                	neg    %edx
f0104bb6:	83 d1 00             	adc    $0x0,%ecx
f0104bb9:	f7 d9                	neg    %ecx
f0104bbb:	83 c4 10             	add    $0x10,%esp
			base = 10;
f0104bbe:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104bc3:	e9 10 01 00 00       	jmp    f0104cd8 <.L35+0x2a>
	else if (lflag)
f0104bc8:	85 c9                	test   %ecx,%ecx
f0104bca:	75 17                	jne    f0104be3 <.L31+0x63>
		return va_arg(*ap, int);
f0104bcc:	8b 45 14             	mov    0x14(%ebp),%eax
f0104bcf:	8b 00                	mov    (%eax),%eax
f0104bd1:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104bd4:	99                   	cltd   
f0104bd5:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104bd8:	8b 45 14             	mov    0x14(%ebp),%eax
f0104bdb:	8d 40 04             	lea    0x4(%eax),%eax
f0104bde:	89 45 14             	mov    %eax,0x14(%ebp)
f0104be1:	eb bc                	jmp    f0104b9f <.L31+0x1f>
		return va_arg(*ap, long);
f0104be3:	8b 45 14             	mov    0x14(%ebp),%eax
f0104be6:	8b 00                	mov    (%eax),%eax
f0104be8:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104beb:	99                   	cltd   
f0104bec:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104bef:	8b 45 14             	mov    0x14(%ebp),%eax
f0104bf2:	8d 40 04             	lea    0x4(%eax),%eax
f0104bf5:	89 45 14             	mov    %eax,0x14(%ebp)
f0104bf8:	eb a5                	jmp    f0104b9f <.L31+0x1f>
			num = getint(&ap, lflag);
f0104bfa:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104bfd:	8b 4d dc             	mov    -0x24(%ebp),%ecx
			base = 10;
f0104c00:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104c05:	e9 ce 00 00 00       	jmp    f0104cd8 <.L35+0x2a>

f0104c0a <.L37>:
f0104c0a:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0104c0d:	83 f9 01             	cmp    $0x1,%ecx
f0104c10:	7e 18                	jle    f0104c2a <.L37+0x20>
		return va_arg(*ap, unsigned long long);
f0104c12:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c15:	8b 10                	mov    (%eax),%edx
f0104c17:	8b 48 04             	mov    0x4(%eax),%ecx
f0104c1a:	8d 40 08             	lea    0x8(%eax),%eax
f0104c1d:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0104c20:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104c25:	e9 ae 00 00 00       	jmp    f0104cd8 <.L35+0x2a>
	else if (lflag)
f0104c2a:	85 c9                	test   %ecx,%ecx
f0104c2c:	75 1a                	jne    f0104c48 <.L37+0x3e>
		return va_arg(*ap, unsigned int);
f0104c2e:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c31:	8b 10                	mov    (%eax),%edx
f0104c33:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104c38:	8d 40 04             	lea    0x4(%eax),%eax
f0104c3b:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0104c3e:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104c43:	e9 90 00 00 00       	jmp    f0104cd8 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0104c48:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c4b:	8b 10                	mov    (%eax),%edx
f0104c4d:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104c52:	8d 40 04             	lea    0x4(%eax),%eax
f0104c55:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 10;
f0104c58:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104c5d:	eb 79                	jmp    f0104cd8 <.L35+0x2a>

f0104c5f <.L34>:
f0104c5f:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0104c62:	83 f9 01             	cmp    $0x1,%ecx
f0104c65:	7e 15                	jle    f0104c7c <.L34+0x1d>
		return va_arg(*ap, unsigned long long);
f0104c67:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c6a:	8b 10                	mov    (%eax),%edx
f0104c6c:	8b 48 04             	mov    0x4(%eax),%ecx
f0104c6f:	8d 40 08             	lea    0x8(%eax),%eax
f0104c72:	89 45 14             	mov    %eax,0x14(%ebp)
			base=8;
f0104c75:	b8 08 00 00 00       	mov    $0x8,%eax
f0104c7a:	eb 5c                	jmp    f0104cd8 <.L35+0x2a>
	else if (lflag)
f0104c7c:	85 c9                	test   %ecx,%ecx
f0104c7e:	75 17                	jne    f0104c97 <.L34+0x38>
		return va_arg(*ap, unsigned int);
f0104c80:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c83:	8b 10                	mov    (%eax),%edx
f0104c85:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104c8a:	8d 40 04             	lea    0x4(%eax),%eax
f0104c8d:	89 45 14             	mov    %eax,0x14(%ebp)
			base=8;
f0104c90:	b8 08 00 00 00       	mov    $0x8,%eax
f0104c95:	eb 41                	jmp    f0104cd8 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0104c97:	8b 45 14             	mov    0x14(%ebp),%eax
f0104c9a:	8b 10                	mov    (%eax),%edx
f0104c9c:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104ca1:	8d 40 04             	lea    0x4(%eax),%eax
f0104ca4:	89 45 14             	mov    %eax,0x14(%ebp)
			base=8;
f0104ca7:	b8 08 00 00 00       	mov    $0x8,%eax
f0104cac:	eb 2a                	jmp    f0104cd8 <.L35+0x2a>

f0104cae <.L35>:
			putch('0', putdat);
f0104cae:	83 ec 08             	sub    $0x8,%esp
f0104cb1:	56                   	push   %esi
f0104cb2:	6a 30                	push   $0x30
f0104cb4:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0104cb7:	83 c4 08             	add    $0x8,%esp
f0104cba:	56                   	push   %esi
f0104cbb:	6a 78                	push   $0x78
f0104cbd:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
f0104cc0:	8b 45 14             	mov    0x14(%ebp),%eax
f0104cc3:	8b 10                	mov    (%eax),%edx
f0104cc5:	b9 00 00 00 00       	mov    $0x0,%ecx
			goto number;
f0104cca:	83 c4 10             	add    $0x10,%esp
				(uintptr_t) va_arg(ap, void *);
f0104ccd:	8d 40 04             	lea    0x4(%eax),%eax
f0104cd0:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104cd3:	b8 10 00 00 00       	mov    $0x10,%eax
			printnum(putch, putdat, num, base, width, padc);
f0104cd8:	83 ec 0c             	sub    $0xc,%esp
f0104cdb:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0104cdf:	57                   	push   %edi
f0104ce0:	ff 75 e0             	pushl  -0x20(%ebp)
f0104ce3:	50                   	push   %eax
f0104ce4:	51                   	push   %ecx
f0104ce5:	52                   	push   %edx
f0104ce6:	89 f2                	mov    %esi,%edx
f0104ce8:	8b 45 08             	mov    0x8(%ebp),%eax
f0104ceb:	e8 20 fb ff ff       	call   f0104810 <printnum>
			break;
f0104cf0:	83 c4 20             	add    $0x20,%esp
			err = va_arg(ap, int);
f0104cf3:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104cf6:	83 c7 01             	add    $0x1,%edi
f0104cf9:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104cfd:	83 f8 25             	cmp    $0x25,%eax
f0104d00:	0f 84 2d fc ff ff    	je     f0104933 <vprintfmt+0x1f>
			if (ch == '\0')
f0104d06:	85 c0                	test   %eax,%eax
f0104d08:	0f 84 91 00 00 00    	je     f0104d9f <.L22+0x21>
			putch(ch, putdat);
f0104d0e:	83 ec 08             	sub    $0x8,%esp
f0104d11:	56                   	push   %esi
f0104d12:	50                   	push   %eax
f0104d13:	ff 55 08             	call   *0x8(%ebp)
f0104d16:	83 c4 10             	add    $0x10,%esp
f0104d19:	eb db                	jmp    f0104cf6 <.L35+0x48>

f0104d1b <.L38>:
f0104d1b:	8b 4d d0             	mov    -0x30(%ebp),%ecx
	if (lflag >= 2)
f0104d1e:	83 f9 01             	cmp    $0x1,%ecx
f0104d21:	7e 15                	jle    f0104d38 <.L38+0x1d>
		return va_arg(*ap, unsigned long long);
f0104d23:	8b 45 14             	mov    0x14(%ebp),%eax
f0104d26:	8b 10                	mov    (%eax),%edx
f0104d28:	8b 48 04             	mov    0x4(%eax),%ecx
f0104d2b:	8d 40 08             	lea    0x8(%eax),%eax
f0104d2e:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104d31:	b8 10 00 00 00       	mov    $0x10,%eax
f0104d36:	eb a0                	jmp    f0104cd8 <.L35+0x2a>
	else if (lflag)
f0104d38:	85 c9                	test   %ecx,%ecx
f0104d3a:	75 17                	jne    f0104d53 <.L38+0x38>
		return va_arg(*ap, unsigned int);
f0104d3c:	8b 45 14             	mov    0x14(%ebp),%eax
f0104d3f:	8b 10                	mov    (%eax),%edx
f0104d41:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104d46:	8d 40 04             	lea    0x4(%eax),%eax
f0104d49:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104d4c:	b8 10 00 00 00       	mov    $0x10,%eax
f0104d51:	eb 85                	jmp    f0104cd8 <.L35+0x2a>
		return va_arg(*ap, unsigned long);
f0104d53:	8b 45 14             	mov    0x14(%ebp),%eax
f0104d56:	8b 10                	mov    (%eax),%edx
f0104d58:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104d5d:	8d 40 04             	lea    0x4(%eax),%eax
f0104d60:	89 45 14             	mov    %eax,0x14(%ebp)
			base = 16;
f0104d63:	b8 10 00 00 00       	mov    $0x10,%eax
f0104d68:	e9 6b ff ff ff       	jmp    f0104cd8 <.L35+0x2a>

f0104d6d <.L25>:
			putch(ch, putdat);
f0104d6d:	83 ec 08             	sub    $0x8,%esp
f0104d70:	56                   	push   %esi
f0104d71:	6a 25                	push   $0x25
f0104d73:	ff 55 08             	call   *0x8(%ebp)
			break;
f0104d76:	83 c4 10             	add    $0x10,%esp
f0104d79:	e9 75 ff ff ff       	jmp    f0104cf3 <.L35+0x45>

f0104d7e <.L22>:
			putch('%', putdat);
f0104d7e:	83 ec 08             	sub    $0x8,%esp
f0104d81:	56                   	push   %esi
f0104d82:	6a 25                	push   $0x25
f0104d84:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104d87:	83 c4 10             	add    $0x10,%esp
f0104d8a:	89 f8                	mov    %edi,%eax
f0104d8c:	eb 03                	jmp    f0104d91 <.L22+0x13>
f0104d8e:	83 e8 01             	sub    $0x1,%eax
f0104d91:	80 78 ff 25          	cmpb   $0x25,-0x1(%eax)
f0104d95:	75 f7                	jne    f0104d8e <.L22+0x10>
f0104d97:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104d9a:	e9 54 ff ff ff       	jmp    f0104cf3 <.L35+0x45>
}
f0104d9f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104da2:	5b                   	pop    %ebx
f0104da3:	5e                   	pop    %esi
f0104da4:	5f                   	pop    %edi
f0104da5:	5d                   	pop    %ebp
f0104da6:	c3                   	ret    

f0104da7 <vsnprintf>:

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104da7:	55                   	push   %ebp
f0104da8:	89 e5                	mov    %esp,%ebp
f0104daa:	53                   	push   %ebx
f0104dab:	83 ec 14             	sub    $0x14,%esp
f0104dae:	e8 b4 b3 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0104db3:	81 c3 6d 82 08 00    	add    $0x8826d,%ebx
f0104db9:	8b 45 08             	mov    0x8(%ebp),%eax
f0104dbc:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104dbf:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104dc2:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104dc6:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104dc9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104dd0:	85 c0                	test   %eax,%eax
f0104dd2:	74 2b                	je     f0104dff <vsnprintf+0x58>
f0104dd4:	85 d2                	test   %edx,%edx
f0104dd6:	7e 27                	jle    f0104dff <vsnprintf+0x58>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104dd8:	ff 75 14             	pushl  0x14(%ebp)
f0104ddb:	ff 75 10             	pushl  0x10(%ebp)
f0104dde:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104de1:	50                   	push   %eax
f0104de2:	8d 83 ba 78 f7 ff    	lea    -0x88746(%ebx),%eax
f0104de8:	50                   	push   %eax
f0104de9:	e8 26 fb ff ff       	call   f0104914 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104dee:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104df1:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104df4:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104df7:	83 c4 10             	add    $0x10,%esp
}
f0104dfa:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104dfd:	c9                   	leave  
f0104dfe:	c3                   	ret    
		return -E_INVAL;
f0104dff:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104e04:	eb f4                	jmp    f0104dfa <vsnprintf+0x53>

f0104e06 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104e06:	55                   	push   %ebp
f0104e07:	89 e5                	mov    %esp,%ebp
f0104e09:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104e0c:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104e0f:	50                   	push   %eax
f0104e10:	ff 75 10             	pushl  0x10(%ebp)
f0104e13:	ff 75 0c             	pushl  0xc(%ebp)
f0104e16:	ff 75 08             	pushl  0x8(%ebp)
f0104e19:	e8 89 ff ff ff       	call   f0104da7 <vsnprintf>
	va_end(ap);

	return rc;
}
f0104e1e:	c9                   	leave  
f0104e1f:	c3                   	ret    

f0104e20 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104e20:	55                   	push   %ebp
f0104e21:	89 e5                	mov    %esp,%ebp
f0104e23:	57                   	push   %edi
f0104e24:	56                   	push   %esi
f0104e25:	53                   	push   %ebx
f0104e26:	83 ec 1c             	sub    $0x1c,%esp
f0104e29:	e8 39 b3 ff ff       	call   f0100167 <__x86.get_pc_thunk.bx>
f0104e2e:	81 c3 f2 81 08 00    	add    $0x881f2,%ebx
f0104e34:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104e37:	85 c0                	test   %eax,%eax
f0104e39:	74 13                	je     f0104e4e <readline+0x2e>
		cprintf("%s", prompt);
f0104e3b:	83 ec 08             	sub    $0x8,%esp
f0104e3e:	50                   	push   %eax
f0104e3f:	8d 83 c5 91 f7 ff    	lea    -0x86e3b(%ebx),%eax
f0104e45:	50                   	push   %eax
f0104e46:	e8 0d ed ff ff       	call   f0103b58 <cprintf>
f0104e4b:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104e4e:	83 ec 0c             	sub    $0xc,%esp
f0104e51:	6a 00                	push   $0x0
f0104e53:	e8 a7 b8 ff ff       	call   f01006ff <iscons>
f0104e58:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104e5b:	83 c4 10             	add    $0x10,%esp
	i = 0;
f0104e5e:	bf 00 00 00 00       	mov    $0x0,%edi
f0104e63:	eb 46                	jmp    f0104eab <readline+0x8b>
	while (1) {
		c = getchar();
		if (c < 0) {
			cprintf("read error: %e\n", c);
f0104e65:	83 ec 08             	sub    $0x8,%esp
f0104e68:	50                   	push   %eax
f0104e69:	8d 83 9c 9b f7 ff    	lea    -0x86464(%ebx),%eax
f0104e6f:	50                   	push   %eax
f0104e70:	e8 e3 ec ff ff       	call   f0103b58 <cprintf>
			return NULL;
f0104e75:	83 c4 10             	add    $0x10,%esp
f0104e78:	b8 00 00 00 00       	mov    $0x0,%eax
				cputchar('\n');
			buf[i] = 0;
			return buf;
		}
	}
}
f0104e7d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104e80:	5b                   	pop    %ebx
f0104e81:	5e                   	pop    %esi
f0104e82:	5f                   	pop    %edi
f0104e83:	5d                   	pop    %ebp
f0104e84:	c3                   	ret    
			if (echoing)
f0104e85:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104e89:	75 05                	jne    f0104e90 <readline+0x70>
			i--;
f0104e8b:	83 ef 01             	sub    $0x1,%edi
f0104e8e:	eb 1b                	jmp    f0104eab <readline+0x8b>
				cputchar('\b');
f0104e90:	83 ec 0c             	sub    $0xc,%esp
f0104e93:	6a 08                	push   $0x8
f0104e95:	e8 44 b8 ff ff       	call   f01006de <cputchar>
f0104e9a:	83 c4 10             	add    $0x10,%esp
f0104e9d:	eb ec                	jmp    f0104e8b <readline+0x6b>
			buf[i++] = c;
f0104e9f:	89 f0                	mov    %esi,%eax
f0104ea1:	88 84 3b c0 2b 00 00 	mov    %al,0x2bc0(%ebx,%edi,1)
f0104ea8:	8d 7f 01             	lea    0x1(%edi),%edi
		c = getchar();
f0104eab:	e8 3e b8 ff ff       	call   f01006ee <getchar>
f0104eb0:	89 c6                	mov    %eax,%esi
		if (c < 0) {
f0104eb2:	85 c0                	test   %eax,%eax
f0104eb4:	78 af                	js     f0104e65 <readline+0x45>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104eb6:	83 f8 08             	cmp    $0x8,%eax
f0104eb9:	0f 94 c2             	sete   %dl
f0104ebc:	83 f8 7f             	cmp    $0x7f,%eax
f0104ebf:	0f 94 c0             	sete   %al
f0104ec2:	08 c2                	or     %al,%dl
f0104ec4:	74 04                	je     f0104eca <readline+0xaa>
f0104ec6:	85 ff                	test   %edi,%edi
f0104ec8:	7f bb                	jg     f0104e85 <readline+0x65>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104eca:	83 fe 1f             	cmp    $0x1f,%esi
f0104ecd:	7e 1c                	jle    f0104eeb <readline+0xcb>
f0104ecf:	81 ff fe 03 00 00    	cmp    $0x3fe,%edi
f0104ed5:	7f 14                	jg     f0104eeb <readline+0xcb>
			if (echoing)
f0104ed7:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104edb:	74 c2                	je     f0104e9f <readline+0x7f>
				cputchar(c);
f0104edd:	83 ec 0c             	sub    $0xc,%esp
f0104ee0:	56                   	push   %esi
f0104ee1:	e8 f8 b7 ff ff       	call   f01006de <cputchar>
f0104ee6:	83 c4 10             	add    $0x10,%esp
f0104ee9:	eb b4                	jmp    f0104e9f <readline+0x7f>
		} else if (c == '\n' || c == '\r') {
f0104eeb:	83 fe 0a             	cmp    $0xa,%esi
f0104eee:	74 05                	je     f0104ef5 <readline+0xd5>
f0104ef0:	83 fe 0d             	cmp    $0xd,%esi
f0104ef3:	75 b6                	jne    f0104eab <readline+0x8b>
			if (echoing)
f0104ef5:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0104ef9:	75 13                	jne    f0104f0e <readline+0xee>
			buf[i] = 0;
f0104efb:	c6 84 3b c0 2b 00 00 	movb   $0x0,0x2bc0(%ebx,%edi,1)
f0104f02:	00 
			return buf;
f0104f03:	8d 83 c0 2b 00 00    	lea    0x2bc0(%ebx),%eax
f0104f09:	e9 6f ff ff ff       	jmp    f0104e7d <readline+0x5d>
				cputchar('\n');
f0104f0e:	83 ec 0c             	sub    $0xc,%esp
f0104f11:	6a 0a                	push   $0xa
f0104f13:	e8 c6 b7 ff ff       	call   f01006de <cputchar>
f0104f18:	83 c4 10             	add    $0x10,%esp
f0104f1b:	eb de                	jmp    f0104efb <readline+0xdb>

f0104f1d <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104f1d:	55                   	push   %ebp
f0104f1e:	89 e5                	mov    %esp,%ebp
f0104f20:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104f23:	b8 00 00 00 00       	mov    $0x0,%eax
f0104f28:	eb 03                	jmp    f0104f2d <strlen+0x10>
		n++;
f0104f2a:	83 c0 01             	add    $0x1,%eax
	for (n = 0; *s != '\0'; s++)
f0104f2d:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104f31:	75 f7                	jne    f0104f2a <strlen+0xd>
	return n;
}
f0104f33:	5d                   	pop    %ebp
f0104f34:	c3                   	ret    

f0104f35 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104f35:	55                   	push   %ebp
f0104f36:	89 e5                	mov    %esp,%ebp
f0104f38:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104f3b:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104f3e:	b8 00 00 00 00       	mov    $0x0,%eax
f0104f43:	eb 03                	jmp    f0104f48 <strnlen+0x13>
		n++;
f0104f45:	83 c0 01             	add    $0x1,%eax
	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104f48:	39 d0                	cmp    %edx,%eax
f0104f4a:	74 06                	je     f0104f52 <strnlen+0x1d>
f0104f4c:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0104f50:	75 f3                	jne    f0104f45 <strnlen+0x10>
	return n;
}
f0104f52:	5d                   	pop    %ebp
f0104f53:	c3                   	ret    

f0104f54 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104f54:	55                   	push   %ebp
f0104f55:	89 e5                	mov    %esp,%ebp
f0104f57:	53                   	push   %ebx
f0104f58:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f5b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104f5e:	89 c2                	mov    %eax,%edx
f0104f60:	83 c1 01             	add    $0x1,%ecx
f0104f63:	83 c2 01             	add    $0x1,%edx
f0104f66:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104f6a:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104f6d:	84 db                	test   %bl,%bl
f0104f6f:	75 ef                	jne    f0104f60 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104f71:	5b                   	pop    %ebx
f0104f72:	5d                   	pop    %ebp
f0104f73:	c3                   	ret    

f0104f74 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104f74:	55                   	push   %ebp
f0104f75:	89 e5                	mov    %esp,%ebp
f0104f77:	53                   	push   %ebx
f0104f78:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104f7b:	53                   	push   %ebx
f0104f7c:	e8 9c ff ff ff       	call   f0104f1d <strlen>
f0104f81:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0104f84:	ff 75 0c             	pushl  0xc(%ebp)
f0104f87:	01 d8                	add    %ebx,%eax
f0104f89:	50                   	push   %eax
f0104f8a:	e8 c5 ff ff ff       	call   f0104f54 <strcpy>
	return dst;
}
f0104f8f:	89 d8                	mov    %ebx,%eax
f0104f91:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104f94:	c9                   	leave  
f0104f95:	c3                   	ret    

f0104f96 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104f96:	55                   	push   %ebp
f0104f97:	89 e5                	mov    %esp,%ebp
f0104f99:	56                   	push   %esi
f0104f9a:	53                   	push   %ebx
f0104f9b:	8b 75 08             	mov    0x8(%ebp),%esi
f0104f9e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104fa1:	89 f3                	mov    %esi,%ebx
f0104fa3:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104fa6:	89 f2                	mov    %esi,%edx
f0104fa8:	eb 0f                	jmp    f0104fb9 <strncpy+0x23>
		*dst++ = *src;
f0104faa:	83 c2 01             	add    $0x1,%edx
f0104fad:	0f b6 01             	movzbl (%ecx),%eax
f0104fb0:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104fb3:	80 39 01             	cmpb   $0x1,(%ecx)
f0104fb6:	83 d9 ff             	sbb    $0xffffffff,%ecx
	for (i = 0; i < size; i++) {
f0104fb9:	39 da                	cmp    %ebx,%edx
f0104fbb:	75 ed                	jne    f0104faa <strncpy+0x14>
	}
	return ret;
}
f0104fbd:	89 f0                	mov    %esi,%eax
f0104fbf:	5b                   	pop    %ebx
f0104fc0:	5e                   	pop    %esi
f0104fc1:	5d                   	pop    %ebp
f0104fc2:	c3                   	ret    

f0104fc3 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104fc3:	55                   	push   %ebp
f0104fc4:	89 e5                	mov    %esp,%ebp
f0104fc6:	56                   	push   %esi
f0104fc7:	53                   	push   %ebx
f0104fc8:	8b 75 08             	mov    0x8(%ebp),%esi
f0104fcb:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104fce:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104fd1:	89 f0                	mov    %esi,%eax
f0104fd3:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104fd7:	85 c9                	test   %ecx,%ecx
f0104fd9:	75 0b                	jne    f0104fe6 <strlcpy+0x23>
f0104fdb:	eb 17                	jmp    f0104ff4 <strlcpy+0x31>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104fdd:	83 c2 01             	add    $0x1,%edx
f0104fe0:	83 c0 01             	add    $0x1,%eax
f0104fe3:	88 48 ff             	mov    %cl,-0x1(%eax)
		while (--size > 0 && *src != '\0')
f0104fe6:	39 d8                	cmp    %ebx,%eax
f0104fe8:	74 07                	je     f0104ff1 <strlcpy+0x2e>
f0104fea:	0f b6 0a             	movzbl (%edx),%ecx
f0104fed:	84 c9                	test   %cl,%cl
f0104fef:	75 ec                	jne    f0104fdd <strlcpy+0x1a>
		*dst = '\0';
f0104ff1:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104ff4:	29 f0                	sub    %esi,%eax
}
f0104ff6:	5b                   	pop    %ebx
f0104ff7:	5e                   	pop    %esi
f0104ff8:	5d                   	pop    %ebp
f0104ff9:	c3                   	ret    

f0104ffa <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0104ffa:	55                   	push   %ebp
f0104ffb:	89 e5                	mov    %esp,%ebp
f0104ffd:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105000:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105003:	eb 06                	jmp    f010500b <strcmp+0x11>
		p++, q++;
f0105005:	83 c1 01             	add    $0x1,%ecx
f0105008:	83 c2 01             	add    $0x1,%edx
	while (*p && *p == *q)
f010500b:	0f b6 01             	movzbl (%ecx),%eax
f010500e:	84 c0                	test   %al,%al
f0105010:	74 04                	je     f0105016 <strcmp+0x1c>
f0105012:	3a 02                	cmp    (%edx),%al
f0105014:	74 ef                	je     f0105005 <strcmp+0xb>
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0105016:	0f b6 c0             	movzbl %al,%eax
f0105019:	0f b6 12             	movzbl (%edx),%edx
f010501c:	29 d0                	sub    %edx,%eax
}
f010501e:	5d                   	pop    %ebp
f010501f:	c3                   	ret    

f0105020 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0105020:	55                   	push   %ebp
f0105021:	89 e5                	mov    %esp,%ebp
f0105023:	53                   	push   %ebx
f0105024:	8b 45 08             	mov    0x8(%ebp),%eax
f0105027:	8b 55 0c             	mov    0xc(%ebp),%edx
f010502a:	89 c3                	mov    %eax,%ebx
f010502c:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010502f:	eb 06                	jmp    f0105037 <strncmp+0x17>
		n--, p++, q++;
f0105031:	83 c0 01             	add    $0x1,%eax
f0105034:	83 c2 01             	add    $0x1,%edx
	while (n > 0 && *p && *p == *q)
f0105037:	39 d8                	cmp    %ebx,%eax
f0105039:	74 16                	je     f0105051 <strncmp+0x31>
f010503b:	0f b6 08             	movzbl (%eax),%ecx
f010503e:	84 c9                	test   %cl,%cl
f0105040:	74 04                	je     f0105046 <strncmp+0x26>
f0105042:	3a 0a                	cmp    (%edx),%cl
f0105044:	74 eb                	je     f0105031 <strncmp+0x11>
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0105046:	0f b6 00             	movzbl (%eax),%eax
f0105049:	0f b6 12             	movzbl (%edx),%edx
f010504c:	29 d0                	sub    %edx,%eax
}
f010504e:	5b                   	pop    %ebx
f010504f:	5d                   	pop    %ebp
f0105050:	c3                   	ret    
		return 0;
f0105051:	b8 00 00 00 00       	mov    $0x0,%eax
f0105056:	eb f6                	jmp    f010504e <strncmp+0x2e>

f0105058 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0105058:	55                   	push   %ebp
f0105059:	89 e5                	mov    %esp,%ebp
f010505b:	8b 45 08             	mov    0x8(%ebp),%eax
f010505e:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105062:	0f b6 10             	movzbl (%eax),%edx
f0105065:	84 d2                	test   %dl,%dl
f0105067:	74 09                	je     f0105072 <strchr+0x1a>
		if (*s == c)
f0105069:	38 ca                	cmp    %cl,%dl
f010506b:	74 0a                	je     f0105077 <strchr+0x1f>
	for (; *s; s++)
f010506d:	83 c0 01             	add    $0x1,%eax
f0105070:	eb f0                	jmp    f0105062 <strchr+0xa>
			return (char *) s;
	return 0;
f0105072:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105077:	5d                   	pop    %ebp
f0105078:	c3                   	ret    

f0105079 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0105079:	55                   	push   %ebp
f010507a:	89 e5                	mov    %esp,%ebp
f010507c:	8b 45 08             	mov    0x8(%ebp),%eax
f010507f:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105083:	eb 03                	jmp    f0105088 <strfind+0xf>
f0105085:	83 c0 01             	add    $0x1,%eax
f0105088:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f010508b:	38 ca                	cmp    %cl,%dl
f010508d:	74 04                	je     f0105093 <strfind+0x1a>
f010508f:	84 d2                	test   %dl,%dl
f0105091:	75 f2                	jne    f0105085 <strfind+0xc>
			break;
	return (char *) s;
}
f0105093:	5d                   	pop    %ebp
f0105094:	c3                   	ret    

f0105095 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0105095:	55                   	push   %ebp
f0105096:	89 e5                	mov    %esp,%ebp
f0105098:	57                   	push   %edi
f0105099:	56                   	push   %esi
f010509a:	53                   	push   %ebx
f010509b:	8b 7d 08             	mov    0x8(%ebp),%edi
f010509e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01050a1:	85 c9                	test   %ecx,%ecx
f01050a3:	74 13                	je     f01050b8 <memset+0x23>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01050a5:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01050ab:	75 05                	jne    f01050b2 <memset+0x1d>
f01050ad:	f6 c1 03             	test   $0x3,%cl
f01050b0:	74 0d                	je     f01050bf <memset+0x2a>
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01050b2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01050b5:	fc                   	cld    
f01050b6:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01050b8:	89 f8                	mov    %edi,%eax
f01050ba:	5b                   	pop    %ebx
f01050bb:	5e                   	pop    %esi
f01050bc:	5f                   	pop    %edi
f01050bd:	5d                   	pop    %ebp
f01050be:	c3                   	ret    
		c &= 0xFF;
f01050bf:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01050c3:	89 d3                	mov    %edx,%ebx
f01050c5:	c1 e3 08             	shl    $0x8,%ebx
f01050c8:	89 d0                	mov    %edx,%eax
f01050ca:	c1 e0 18             	shl    $0x18,%eax
f01050cd:	89 d6                	mov    %edx,%esi
f01050cf:	c1 e6 10             	shl    $0x10,%esi
f01050d2:	09 f0                	or     %esi,%eax
f01050d4:	09 c2                	or     %eax,%edx
f01050d6:	09 da                	or     %ebx,%edx
			:: "D" (v), "a" (c), "c" (n/4)
f01050d8:	c1 e9 02             	shr    $0x2,%ecx
		asm volatile("cld; rep stosl\n"
f01050db:	89 d0                	mov    %edx,%eax
f01050dd:	fc                   	cld    
f01050de:	f3 ab                	rep stos %eax,%es:(%edi)
f01050e0:	eb d6                	jmp    f01050b8 <memset+0x23>

f01050e2 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01050e2:	55                   	push   %ebp
f01050e3:	89 e5                	mov    %esp,%ebp
f01050e5:	57                   	push   %edi
f01050e6:	56                   	push   %esi
f01050e7:	8b 45 08             	mov    0x8(%ebp),%eax
f01050ea:	8b 75 0c             	mov    0xc(%ebp),%esi
f01050ed:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01050f0:	39 c6                	cmp    %eax,%esi
f01050f2:	73 35                	jae    f0105129 <memmove+0x47>
f01050f4:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01050f7:	39 c2                	cmp    %eax,%edx
f01050f9:	76 2e                	jbe    f0105129 <memmove+0x47>
		s += n;
		d += n;
f01050fb:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01050fe:	89 d6                	mov    %edx,%esi
f0105100:	09 fe                	or     %edi,%esi
f0105102:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0105108:	74 0c                	je     f0105116 <memmove+0x34>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010510a:	83 ef 01             	sub    $0x1,%edi
f010510d:	8d 72 ff             	lea    -0x1(%edx),%esi
			asm volatile("std; rep movsb\n"
f0105110:	fd                   	std    
f0105111:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0105113:	fc                   	cld    
f0105114:	eb 21                	jmp    f0105137 <memmove+0x55>
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105116:	f6 c1 03             	test   $0x3,%cl
f0105119:	75 ef                	jne    f010510a <memmove+0x28>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f010511b:	83 ef 04             	sub    $0x4,%edi
f010511e:	8d 72 fc             	lea    -0x4(%edx),%esi
f0105121:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("std; rep movsl\n"
f0105124:	fd                   	std    
f0105125:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105127:	eb ea                	jmp    f0105113 <memmove+0x31>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105129:	89 f2                	mov    %esi,%edx
f010512b:	09 c2                	or     %eax,%edx
f010512d:	f6 c2 03             	test   $0x3,%dl
f0105130:	74 09                	je     f010513b <memmove+0x59>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0105132:	89 c7                	mov    %eax,%edi
f0105134:	fc                   	cld    
f0105135:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0105137:	5e                   	pop    %esi
f0105138:	5f                   	pop    %edi
f0105139:	5d                   	pop    %ebp
f010513a:	c3                   	ret    
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010513b:	f6 c1 03             	test   $0x3,%cl
f010513e:	75 f2                	jne    f0105132 <memmove+0x50>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0105140:	c1 e9 02             	shr    $0x2,%ecx
			asm volatile("cld; rep movsl\n"
f0105143:	89 c7                	mov    %eax,%edi
f0105145:	fc                   	cld    
f0105146:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105148:	eb ed                	jmp    f0105137 <memmove+0x55>

f010514a <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010514a:	55                   	push   %ebp
f010514b:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010514d:	ff 75 10             	pushl  0x10(%ebp)
f0105150:	ff 75 0c             	pushl  0xc(%ebp)
f0105153:	ff 75 08             	pushl  0x8(%ebp)
f0105156:	e8 87 ff ff ff       	call   f01050e2 <memmove>
}
f010515b:	c9                   	leave  
f010515c:	c3                   	ret    

f010515d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010515d:	55                   	push   %ebp
f010515e:	89 e5                	mov    %esp,%ebp
f0105160:	56                   	push   %esi
f0105161:	53                   	push   %ebx
f0105162:	8b 45 08             	mov    0x8(%ebp),%eax
f0105165:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105168:	89 c6                	mov    %eax,%esi
f010516a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010516d:	39 f0                	cmp    %esi,%eax
f010516f:	74 1c                	je     f010518d <memcmp+0x30>
		if (*s1 != *s2)
f0105171:	0f b6 08             	movzbl (%eax),%ecx
f0105174:	0f b6 1a             	movzbl (%edx),%ebx
f0105177:	38 d9                	cmp    %bl,%cl
f0105179:	75 08                	jne    f0105183 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
		s1++, s2++;
f010517b:	83 c0 01             	add    $0x1,%eax
f010517e:	83 c2 01             	add    $0x1,%edx
f0105181:	eb ea                	jmp    f010516d <memcmp+0x10>
			return (int) *s1 - (int) *s2;
f0105183:	0f b6 c1             	movzbl %cl,%eax
f0105186:	0f b6 db             	movzbl %bl,%ebx
f0105189:	29 d8                	sub    %ebx,%eax
f010518b:	eb 05                	jmp    f0105192 <memcmp+0x35>
	}

	return 0;
f010518d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105192:	5b                   	pop    %ebx
f0105193:	5e                   	pop    %esi
f0105194:	5d                   	pop    %ebp
f0105195:	c3                   	ret    

f0105196 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0105196:	55                   	push   %ebp
f0105197:	89 e5                	mov    %esp,%ebp
f0105199:	8b 45 08             	mov    0x8(%ebp),%eax
f010519c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010519f:	89 c2                	mov    %eax,%edx
f01051a1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01051a4:	39 d0                	cmp    %edx,%eax
f01051a6:	73 09                	jae    f01051b1 <memfind+0x1b>
		if (*(const unsigned char *) s == (unsigned char) c)
f01051a8:	38 08                	cmp    %cl,(%eax)
f01051aa:	74 05                	je     f01051b1 <memfind+0x1b>
	for (; s < ends; s++)
f01051ac:	83 c0 01             	add    $0x1,%eax
f01051af:	eb f3                	jmp    f01051a4 <memfind+0xe>
			break;
	return (void *) s;
}
f01051b1:	5d                   	pop    %ebp
f01051b2:	c3                   	ret    

f01051b3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01051b3:	55                   	push   %ebp
f01051b4:	89 e5                	mov    %esp,%ebp
f01051b6:	57                   	push   %edi
f01051b7:	56                   	push   %esi
f01051b8:	53                   	push   %ebx
f01051b9:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01051bc:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01051bf:	eb 03                	jmp    f01051c4 <strtol+0x11>
		s++;
f01051c1:	83 c1 01             	add    $0x1,%ecx
	while (*s == ' ' || *s == '\t')
f01051c4:	0f b6 01             	movzbl (%ecx),%eax
f01051c7:	3c 20                	cmp    $0x20,%al
f01051c9:	74 f6                	je     f01051c1 <strtol+0xe>
f01051cb:	3c 09                	cmp    $0x9,%al
f01051cd:	74 f2                	je     f01051c1 <strtol+0xe>

	// plus/minus sign
	if (*s == '+')
f01051cf:	3c 2b                	cmp    $0x2b,%al
f01051d1:	74 2e                	je     f0105201 <strtol+0x4e>
	int neg = 0;
f01051d3:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;
	else if (*s == '-')
f01051d8:	3c 2d                	cmp    $0x2d,%al
f01051da:	74 2f                	je     f010520b <strtol+0x58>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01051dc:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f01051e2:	75 05                	jne    f01051e9 <strtol+0x36>
f01051e4:	80 39 30             	cmpb   $0x30,(%ecx)
f01051e7:	74 2c                	je     f0105215 <strtol+0x62>
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01051e9:	85 db                	test   %ebx,%ebx
f01051eb:	75 0a                	jne    f01051f7 <strtol+0x44>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01051ed:	bb 0a 00 00 00       	mov    $0xa,%ebx
	else if (base == 0 && s[0] == '0')
f01051f2:	80 39 30             	cmpb   $0x30,(%ecx)
f01051f5:	74 28                	je     f010521f <strtol+0x6c>
		base = 10;
f01051f7:	b8 00 00 00 00       	mov    $0x0,%eax
f01051fc:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01051ff:	eb 50                	jmp    f0105251 <strtol+0x9e>
		s++;
f0105201:	83 c1 01             	add    $0x1,%ecx
	int neg = 0;
f0105204:	bf 00 00 00 00       	mov    $0x0,%edi
f0105209:	eb d1                	jmp    f01051dc <strtol+0x29>
		s++, neg = 1;
f010520b:	83 c1 01             	add    $0x1,%ecx
f010520e:	bf 01 00 00 00       	mov    $0x1,%edi
f0105213:	eb c7                	jmp    f01051dc <strtol+0x29>
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105215:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0105219:	74 0e                	je     f0105229 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f010521b:	85 db                	test   %ebx,%ebx
f010521d:	75 d8                	jne    f01051f7 <strtol+0x44>
		s++, base = 8;
f010521f:	83 c1 01             	add    $0x1,%ecx
f0105222:	bb 08 00 00 00       	mov    $0x8,%ebx
f0105227:	eb ce                	jmp    f01051f7 <strtol+0x44>
		s += 2, base = 16;
f0105229:	83 c1 02             	add    $0x2,%ecx
f010522c:	bb 10 00 00 00       	mov    $0x10,%ebx
f0105231:	eb c4                	jmp    f01051f7 <strtol+0x44>
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
f0105233:	8d 72 9f             	lea    -0x61(%edx),%esi
f0105236:	89 f3                	mov    %esi,%ebx
f0105238:	80 fb 19             	cmp    $0x19,%bl
f010523b:	77 29                	ja     f0105266 <strtol+0xb3>
			dig = *s - 'a' + 10;
f010523d:	0f be d2             	movsbl %dl,%edx
f0105240:	83 ea 57             	sub    $0x57,%edx
		else if (*s >= 'A' && *s <= 'Z')
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0105243:	3b 55 10             	cmp    0x10(%ebp),%edx
f0105246:	7d 30                	jge    f0105278 <strtol+0xc5>
			break;
		s++, val = (val * base) + dig;
f0105248:	83 c1 01             	add    $0x1,%ecx
f010524b:	0f af 45 10          	imul   0x10(%ebp),%eax
f010524f:	01 d0                	add    %edx,%eax
		if (*s >= '0' && *s <= '9')
f0105251:	0f b6 11             	movzbl (%ecx),%edx
f0105254:	8d 72 d0             	lea    -0x30(%edx),%esi
f0105257:	89 f3                	mov    %esi,%ebx
f0105259:	80 fb 09             	cmp    $0x9,%bl
f010525c:	77 d5                	ja     f0105233 <strtol+0x80>
			dig = *s - '0';
f010525e:	0f be d2             	movsbl %dl,%edx
f0105261:	83 ea 30             	sub    $0x30,%edx
f0105264:	eb dd                	jmp    f0105243 <strtol+0x90>
		else if (*s >= 'A' && *s <= 'Z')
f0105266:	8d 72 bf             	lea    -0x41(%edx),%esi
f0105269:	89 f3                	mov    %esi,%ebx
f010526b:	80 fb 19             	cmp    $0x19,%bl
f010526e:	77 08                	ja     f0105278 <strtol+0xc5>
			dig = *s - 'A' + 10;
f0105270:	0f be d2             	movsbl %dl,%edx
f0105273:	83 ea 37             	sub    $0x37,%edx
f0105276:	eb cb                	jmp    f0105243 <strtol+0x90>
		// we don't properly detect overflow!
	}

	if (endptr)
f0105278:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010527c:	74 05                	je     f0105283 <strtol+0xd0>
		*endptr = (char *) s;
f010527e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105281:	89 0e                	mov    %ecx,(%esi)
	return (neg ? -val : val);
f0105283:	89 c2                	mov    %eax,%edx
f0105285:	f7 da                	neg    %edx
f0105287:	85 ff                	test   %edi,%edi
f0105289:	0f 45 c2             	cmovne %edx,%eax
}
f010528c:	5b                   	pop    %ebx
f010528d:	5e                   	pop    %esi
f010528e:	5f                   	pop    %edi
f010528f:	5d                   	pop    %ebp
f0105290:	c3                   	ret    
f0105291:	66 90                	xchg   %ax,%ax
f0105293:	66 90                	xchg   %ax,%ax
f0105295:	66 90                	xchg   %ax,%ax
f0105297:	66 90                	xchg   %ax,%ax
f0105299:	66 90                	xchg   %ax,%ax
f010529b:	66 90                	xchg   %ax,%ax
f010529d:	66 90                	xchg   %ax,%ax
f010529f:	90                   	nop

f01052a0 <__udivdi3>:
f01052a0:	55                   	push   %ebp
f01052a1:	57                   	push   %edi
f01052a2:	56                   	push   %esi
f01052a3:	53                   	push   %ebx
f01052a4:	83 ec 1c             	sub    $0x1c,%esp
f01052a7:	8b 54 24 3c          	mov    0x3c(%esp),%edx
f01052ab:	8b 6c 24 30          	mov    0x30(%esp),%ebp
f01052af:	8b 74 24 34          	mov    0x34(%esp),%esi
f01052b3:	8b 5c 24 38          	mov    0x38(%esp),%ebx
f01052b7:	85 d2                	test   %edx,%edx
f01052b9:	75 35                	jne    f01052f0 <__udivdi3+0x50>
f01052bb:	39 f3                	cmp    %esi,%ebx
f01052bd:	0f 87 bd 00 00 00    	ja     f0105380 <__udivdi3+0xe0>
f01052c3:	85 db                	test   %ebx,%ebx
f01052c5:	89 d9                	mov    %ebx,%ecx
f01052c7:	75 0b                	jne    f01052d4 <__udivdi3+0x34>
f01052c9:	b8 01 00 00 00       	mov    $0x1,%eax
f01052ce:	31 d2                	xor    %edx,%edx
f01052d0:	f7 f3                	div    %ebx
f01052d2:	89 c1                	mov    %eax,%ecx
f01052d4:	31 d2                	xor    %edx,%edx
f01052d6:	89 f0                	mov    %esi,%eax
f01052d8:	f7 f1                	div    %ecx
f01052da:	89 c6                	mov    %eax,%esi
f01052dc:	89 e8                	mov    %ebp,%eax
f01052de:	89 f7                	mov    %esi,%edi
f01052e0:	f7 f1                	div    %ecx
f01052e2:	89 fa                	mov    %edi,%edx
f01052e4:	83 c4 1c             	add    $0x1c,%esp
f01052e7:	5b                   	pop    %ebx
f01052e8:	5e                   	pop    %esi
f01052e9:	5f                   	pop    %edi
f01052ea:	5d                   	pop    %ebp
f01052eb:	c3                   	ret    
f01052ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01052f0:	39 f2                	cmp    %esi,%edx
f01052f2:	77 7c                	ja     f0105370 <__udivdi3+0xd0>
f01052f4:	0f bd fa             	bsr    %edx,%edi
f01052f7:	83 f7 1f             	xor    $0x1f,%edi
f01052fa:	0f 84 98 00 00 00    	je     f0105398 <__udivdi3+0xf8>
f0105300:	89 f9                	mov    %edi,%ecx
f0105302:	b8 20 00 00 00       	mov    $0x20,%eax
f0105307:	29 f8                	sub    %edi,%eax
f0105309:	d3 e2                	shl    %cl,%edx
f010530b:	89 54 24 08          	mov    %edx,0x8(%esp)
f010530f:	89 c1                	mov    %eax,%ecx
f0105311:	89 da                	mov    %ebx,%edx
f0105313:	d3 ea                	shr    %cl,%edx
f0105315:	8b 4c 24 08          	mov    0x8(%esp),%ecx
f0105319:	09 d1                	or     %edx,%ecx
f010531b:	89 f2                	mov    %esi,%edx
f010531d:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105321:	89 f9                	mov    %edi,%ecx
f0105323:	d3 e3                	shl    %cl,%ebx
f0105325:	89 c1                	mov    %eax,%ecx
f0105327:	d3 ea                	shr    %cl,%edx
f0105329:	89 f9                	mov    %edi,%ecx
f010532b:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f010532f:	d3 e6                	shl    %cl,%esi
f0105331:	89 eb                	mov    %ebp,%ebx
f0105333:	89 c1                	mov    %eax,%ecx
f0105335:	d3 eb                	shr    %cl,%ebx
f0105337:	09 de                	or     %ebx,%esi
f0105339:	89 f0                	mov    %esi,%eax
f010533b:	f7 74 24 08          	divl   0x8(%esp)
f010533f:	89 d6                	mov    %edx,%esi
f0105341:	89 c3                	mov    %eax,%ebx
f0105343:	f7 64 24 0c          	mull   0xc(%esp)
f0105347:	39 d6                	cmp    %edx,%esi
f0105349:	72 0c                	jb     f0105357 <__udivdi3+0xb7>
f010534b:	89 f9                	mov    %edi,%ecx
f010534d:	d3 e5                	shl    %cl,%ebp
f010534f:	39 c5                	cmp    %eax,%ebp
f0105351:	73 5d                	jae    f01053b0 <__udivdi3+0x110>
f0105353:	39 d6                	cmp    %edx,%esi
f0105355:	75 59                	jne    f01053b0 <__udivdi3+0x110>
f0105357:	8d 43 ff             	lea    -0x1(%ebx),%eax
f010535a:	31 ff                	xor    %edi,%edi
f010535c:	89 fa                	mov    %edi,%edx
f010535e:	83 c4 1c             	add    $0x1c,%esp
f0105361:	5b                   	pop    %ebx
f0105362:	5e                   	pop    %esi
f0105363:	5f                   	pop    %edi
f0105364:	5d                   	pop    %ebp
f0105365:	c3                   	ret    
f0105366:	8d 76 00             	lea    0x0(%esi),%esi
f0105369:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0105370:	31 ff                	xor    %edi,%edi
f0105372:	31 c0                	xor    %eax,%eax
f0105374:	89 fa                	mov    %edi,%edx
f0105376:	83 c4 1c             	add    $0x1c,%esp
f0105379:	5b                   	pop    %ebx
f010537a:	5e                   	pop    %esi
f010537b:	5f                   	pop    %edi
f010537c:	5d                   	pop    %ebp
f010537d:	c3                   	ret    
f010537e:	66 90                	xchg   %ax,%ax
f0105380:	31 ff                	xor    %edi,%edi
f0105382:	89 e8                	mov    %ebp,%eax
f0105384:	89 f2                	mov    %esi,%edx
f0105386:	f7 f3                	div    %ebx
f0105388:	89 fa                	mov    %edi,%edx
f010538a:	83 c4 1c             	add    $0x1c,%esp
f010538d:	5b                   	pop    %ebx
f010538e:	5e                   	pop    %esi
f010538f:	5f                   	pop    %edi
f0105390:	5d                   	pop    %ebp
f0105391:	c3                   	ret    
f0105392:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105398:	39 f2                	cmp    %esi,%edx
f010539a:	72 06                	jb     f01053a2 <__udivdi3+0x102>
f010539c:	31 c0                	xor    %eax,%eax
f010539e:	39 eb                	cmp    %ebp,%ebx
f01053a0:	77 d2                	ja     f0105374 <__udivdi3+0xd4>
f01053a2:	b8 01 00 00 00       	mov    $0x1,%eax
f01053a7:	eb cb                	jmp    f0105374 <__udivdi3+0xd4>
f01053a9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01053b0:	89 d8                	mov    %ebx,%eax
f01053b2:	31 ff                	xor    %edi,%edi
f01053b4:	eb be                	jmp    f0105374 <__udivdi3+0xd4>
f01053b6:	66 90                	xchg   %ax,%ax
f01053b8:	66 90                	xchg   %ax,%ax
f01053ba:	66 90                	xchg   %ax,%ax
f01053bc:	66 90                	xchg   %ax,%ax
f01053be:	66 90                	xchg   %ax,%ax

f01053c0 <__umoddi3>:
f01053c0:	55                   	push   %ebp
f01053c1:	57                   	push   %edi
f01053c2:	56                   	push   %esi
f01053c3:	53                   	push   %ebx
f01053c4:	83 ec 1c             	sub    $0x1c,%esp
f01053c7:	8b 6c 24 3c          	mov    0x3c(%esp),%ebp
f01053cb:	8b 74 24 30          	mov    0x30(%esp),%esi
f01053cf:	8b 5c 24 34          	mov    0x34(%esp),%ebx
f01053d3:	8b 7c 24 38          	mov    0x38(%esp),%edi
f01053d7:	85 ed                	test   %ebp,%ebp
f01053d9:	89 f0                	mov    %esi,%eax
f01053db:	89 da                	mov    %ebx,%edx
f01053dd:	75 19                	jne    f01053f8 <__umoddi3+0x38>
f01053df:	39 df                	cmp    %ebx,%edi
f01053e1:	0f 86 b1 00 00 00    	jbe    f0105498 <__umoddi3+0xd8>
f01053e7:	f7 f7                	div    %edi
f01053e9:	89 d0                	mov    %edx,%eax
f01053eb:	31 d2                	xor    %edx,%edx
f01053ed:	83 c4 1c             	add    $0x1c,%esp
f01053f0:	5b                   	pop    %ebx
f01053f1:	5e                   	pop    %esi
f01053f2:	5f                   	pop    %edi
f01053f3:	5d                   	pop    %ebp
f01053f4:	c3                   	ret    
f01053f5:	8d 76 00             	lea    0x0(%esi),%esi
f01053f8:	39 dd                	cmp    %ebx,%ebp
f01053fa:	77 f1                	ja     f01053ed <__umoddi3+0x2d>
f01053fc:	0f bd cd             	bsr    %ebp,%ecx
f01053ff:	83 f1 1f             	xor    $0x1f,%ecx
f0105402:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0105406:	0f 84 b4 00 00 00    	je     f01054c0 <__umoddi3+0x100>
f010540c:	b8 20 00 00 00       	mov    $0x20,%eax
f0105411:	89 c2                	mov    %eax,%edx
f0105413:	8b 44 24 04          	mov    0x4(%esp),%eax
f0105417:	29 c2                	sub    %eax,%edx
f0105419:	89 c1                	mov    %eax,%ecx
f010541b:	89 f8                	mov    %edi,%eax
f010541d:	d3 e5                	shl    %cl,%ebp
f010541f:	89 d1                	mov    %edx,%ecx
f0105421:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0105425:	d3 e8                	shr    %cl,%eax
f0105427:	09 c5                	or     %eax,%ebp
f0105429:	8b 44 24 04          	mov    0x4(%esp),%eax
f010542d:	89 c1                	mov    %eax,%ecx
f010542f:	d3 e7                	shl    %cl,%edi
f0105431:	89 d1                	mov    %edx,%ecx
f0105433:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0105437:	89 df                	mov    %ebx,%edi
f0105439:	d3 ef                	shr    %cl,%edi
f010543b:	89 c1                	mov    %eax,%ecx
f010543d:	89 f0                	mov    %esi,%eax
f010543f:	d3 e3                	shl    %cl,%ebx
f0105441:	89 d1                	mov    %edx,%ecx
f0105443:	89 fa                	mov    %edi,%edx
f0105445:	d3 e8                	shr    %cl,%eax
f0105447:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010544c:	09 d8                	or     %ebx,%eax
f010544e:	f7 f5                	div    %ebp
f0105450:	d3 e6                	shl    %cl,%esi
f0105452:	89 d1                	mov    %edx,%ecx
f0105454:	f7 64 24 08          	mull   0x8(%esp)
f0105458:	39 d1                	cmp    %edx,%ecx
f010545a:	89 c3                	mov    %eax,%ebx
f010545c:	89 d7                	mov    %edx,%edi
f010545e:	72 06                	jb     f0105466 <__umoddi3+0xa6>
f0105460:	75 0e                	jne    f0105470 <__umoddi3+0xb0>
f0105462:	39 c6                	cmp    %eax,%esi
f0105464:	73 0a                	jae    f0105470 <__umoddi3+0xb0>
f0105466:	2b 44 24 08          	sub    0x8(%esp),%eax
f010546a:	19 ea                	sbb    %ebp,%edx
f010546c:	89 d7                	mov    %edx,%edi
f010546e:	89 c3                	mov    %eax,%ebx
f0105470:	89 ca                	mov    %ecx,%edx
f0105472:	0f b6 4c 24 0c       	movzbl 0xc(%esp),%ecx
f0105477:	29 de                	sub    %ebx,%esi
f0105479:	19 fa                	sbb    %edi,%edx
f010547b:	8b 5c 24 04          	mov    0x4(%esp),%ebx
f010547f:	89 d0                	mov    %edx,%eax
f0105481:	d3 e0                	shl    %cl,%eax
f0105483:	89 d9                	mov    %ebx,%ecx
f0105485:	d3 ee                	shr    %cl,%esi
f0105487:	d3 ea                	shr    %cl,%edx
f0105489:	09 f0                	or     %esi,%eax
f010548b:	83 c4 1c             	add    $0x1c,%esp
f010548e:	5b                   	pop    %ebx
f010548f:	5e                   	pop    %esi
f0105490:	5f                   	pop    %edi
f0105491:	5d                   	pop    %ebp
f0105492:	c3                   	ret    
f0105493:	90                   	nop
f0105494:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105498:	85 ff                	test   %edi,%edi
f010549a:	89 f9                	mov    %edi,%ecx
f010549c:	75 0b                	jne    f01054a9 <__umoddi3+0xe9>
f010549e:	b8 01 00 00 00       	mov    $0x1,%eax
f01054a3:	31 d2                	xor    %edx,%edx
f01054a5:	f7 f7                	div    %edi
f01054a7:	89 c1                	mov    %eax,%ecx
f01054a9:	89 d8                	mov    %ebx,%eax
f01054ab:	31 d2                	xor    %edx,%edx
f01054ad:	f7 f1                	div    %ecx
f01054af:	89 f0                	mov    %esi,%eax
f01054b1:	f7 f1                	div    %ecx
f01054b3:	e9 31 ff ff ff       	jmp    f01053e9 <__umoddi3+0x29>
f01054b8:	90                   	nop
f01054b9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01054c0:	39 dd                	cmp    %ebx,%ebp
f01054c2:	72 08                	jb     f01054cc <__umoddi3+0x10c>
f01054c4:	39 f7                	cmp    %esi,%edi
f01054c6:	0f 87 21 ff ff ff    	ja     f01053ed <__umoddi3+0x2d>
f01054cc:	89 da                	mov    %ebx,%edx
f01054ce:	89 f0                	mov    %esi,%eax
f01054d0:	29 f8                	sub    %edi,%eax
f01054d2:	19 ea                	sbb    %ebp,%edx
f01054d4:	e9 14 ff ff ff       	jmp    f01053ed <__umoddi3+0x2d>
