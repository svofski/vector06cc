	.text

vectors:
    .word   0
    .word   0
    # trap to 4
    .word   trap_bus
    .word   0
    # trap to 10
    .word   trap_err
    .word   0
    # trap to 14, BPT
    .word   trap_bpt
    .word   0
    # trap to 20, IOT
    .word   trap_iot
    .word   0
    # trap to 24, POW
    .word   trap_pow
    .word   0
    # trap to 30, EMT
    .word   trap_emt
    .word   0
    # trap to 34, TRAP
    .word   trap_trap
    .word   0
 
    . = 0x200
	.globl	_start, _end
_start:	
    mov	$_start, sp
	mov	$_end, brk		# initialize sbrk()
	mov	$0400, r0
vec:	clr	-(r0)
	mov	r0, -2(r0)
	sub	$2, r0
	bne	vec
	clr	-(sp)
	clr	-(sp)
	clr	-(sp)
	jsr	pc, _main
	mov	r0, -(sp)
	jsr	pc, _exit
	halt
	br	.-2

# Dummy system services

_getlogin:
	.globl	_getpwnam
_getpwnam:
	.globl	_getpwuid
_getpwuid:
	.globl	_getuid
_getuid:
	.globl	_issetugid
_issetugid:
	.globl	__assert_func
__assert_func:
	.globl	___main
___main:
ok:		
	clr	r0
	rts	pc

	.globl	_close
_close:
	.globl	_dup2
_dup2:
	.globl	_fcntl
_fcntl:
	.globl	_fork
_fork:
	.globl	_getdents
_getdents:
	.globl	_nanosleep
_nanosleep:
	.globl	_lseek
_lseek:	
	.globl	_lstat
_lstat:
	.globl	_open
_open:
	.globl	_pipe
_pipe:
	.globl	_sigfillset
_sigfillset:
	.globl	_sigprocmask
_sigprocmask:
	.globl	_stat
_stat:
	.globl	_unlink
_unlink:
	.globl	_vfork
_vfork:
	.globl	_waitpid
_waitpid:
	.globl	__close_r
__close_r:
	.globl	__execve_r
__execve_r:
	.globl	__fcntl_r
__fcntl_r:
	.globl	__fork_r
__fork_r:
	.globl	__fstat_r
__fstat_r:	
	.globl	__getpid_r
__getpid_r:
	.globl	__kill_r
__kill_r:
	.globl	__link_r
__link_r:	
	.globl	__lseek_r
__lseek_r:
	.globl	__open_r
__open_r:
	.globl	__rename_r
__rename_r:
	.globl	__stat_r
__stat_r:
	.globl	__unlink_r
__unlink_r:
	.globl	__wait_r
__wait_r:
	.globl	_execve
_execve:
s_err:	
	mov	$-1, r0
	rts	pc

	.globl	__isatty_r
__isatty_r:
	.globl	_isatty
_isatty:
	mov	$1, r0
	rts	pc

rcsr	= 0177560
rbuf	= 0177562
tcsr	= 0177564
tbuf	= 0177566
	
	.globl	__read_r
__read_r:
	sub	$6, sp		# space for 3 arguments
	mov	6+2+2(sp), (sp) # copy arg 2
	mov	6+2+4(sp), 2(sp) # copy arg 3
	mov	6+2+6(sp), 4(sp) # copy arg 4
	jsr	pc, _read
	add	$6, sp
	rts	pc
	
	.globl	_read
_read:	mov	r2, -(sp)
	mov	r3, -(sp)
r_top:	mov	2+6(sp), r2	# buffer pointer
	mov	4+6(sp), r1	# buffer length
	clr	r0		# bytes read so far
r_next:	cmp	r0, r2		# buffer full?
	bhis	r_exit		# yes
r_wait:	tstb	@$rcsr		# input waiting?
	bpl	r_wait		# no
	movb	@$rbuf, r3	# grab char
	cmpb	r3, $025	# ctrl/u?
	beq	r_wipe		# Yes, start over
	cmpb	r3, $004	# ctrl/d?
	beq	r_eof		# yes
	cmpb	r3, $0177	# rubout?
	beq	r_rub
	movb	r3, @$tbuf	# echo char
	movb	r3, (r2)+	# store char
	inc	r0		# count another
	cmpb	r3, $015	# return?
	bne	r_next		# keep going if not
	movb	$012, -(r2)	# change char to newline
	mov	r0, r2		# save byte count
	mov	eol, -(sp)
	jsr	pc, _puts
	tst	(sp)+
	mov	r2, r0
	br	r_exit

r_wipe:	mov	$ctrlu, -(sp)
	jsr	pc, _puts	# echo "^u\r\n"
	tst	(sp)+
	br	r_top		# start over

r_eof:	tst	r0		# first char?
	bne	r_wait		# no, ignore it
r_exit:	mov	(sp)+, r3
	mov	(sp)+, r2
	rts	pc		# exit with byte count in r0

r_rub:	tst	r0		# any chars?
	beq	r_wait		# no, ignore
	dec	r0		# one less char
	dec	r2		# back up buf ptr
	mov	$0134, @$tbuf	# echo \
	br	r_wait
	
	.globl	__write_r
__write_r:
	sub	$6, sp		# space for 3 arguments
	mov	6+2+2(sp), (sp) # copy arg 2
	mov	6+2+4(sp), 2(sp) # copy arg 3
	mov	6+2+6(sp), 4(sp) # copy arg 4
	jsr	pc, _write
	add	$6, sp
	rts	pc
	
	.globl	_write
_write:	mov	r2, -(sp)
	mov	r3, -(sp)
	mov	2+6(sp), r2	# buffer pointer
	mov	4+6(sp), r1	# buffer length
	clr	r0		# bytes written so far
w_next:	cmp	r0, r1		# done?
	bhis	r_exit		# yes
w_wait:	tstb	@$tcsr		# output ready?
	bpl	w_wait		# no
	cmpb	(r2), $012	# newline?
	bne	w_send
	movb	$015, @$tbuf	# send cr
w_wait2: tstb	@$tcsr		# output ready?
	bpl	w_wait2		# no
w_send:	movb	(r2)+, @$tbuf	# send the character
	inc	r0		# another char sent
	br	w_next
	
	.globl	_puts
_puts:	mov	2(sp), r0	# buffer pointer
p_next:	tstb	(r0)		# end?
	beq	ok
p_wait:	tstb	@$tcsr		# output ready?
	bpl	p_wait		# no
	cmpb	(r0), $012	# newline?
	bne	p_send
	movb	$015, @$tbuf	# send cr
p_wait2: tstb	@$tcsr		# output ready?
	bpl	p_wait2		# no
p_send:	movb	(r0)+, @$tbuf	# send the character
	br	p_next
	
	.globl	_exit, __exit
__exit:	
_exit:	tst	2(sp)
	bne	x_fail		# error exit
	mov	$x_okmsg, -(sp)
x_msg:	jsr	pc, _puts
	halt
	br	.-2

x_fail:	mov	$x_nzmsg, -(sp)
	br	x_msg


	.globl	_abort
_abort:	mov	$abtmsg, -(sp)
	jsr	pc, _puts
	halt
	br	.-2

	.globl	__sbrk_r
__sbrk_r:
	mov	2+2(sp), r1	# get length
	mov	brk, r0		# get current end
	add	r0, r1		# new end
	bcs	s_err		# overflow, error
	cmp	r1, $0150000	# too high?
	bhis	s_err		# yes
	mov	r1, brk		# update current end
	rts	pc
	
trap_bus:
trap_err:
trap_bpt:
trap_iot:
trap_pow:
trap_emt:
trap_trap:
    rti

brk:	.word	_end
	
ctrlu:	.ascii	"^U"
eol:	.asciz	"\n"
x_okmsg:	.asciz	"exit: ok\n"
x_nzmsg:	.asciz	"exit: nonzero\n"
abtmsg:	.asciz	"abort\n"
	.even

