;; ====================================================================
;;                         VECTOR-06C FPGA REPLICA
;;
;; 				Copyright (C) 2007,2008 Viacheslav Slavinsky
;;
;; This core is distributed under modified BSD license. 
;; For complete licensing information see LICENSE.TXT.
;; -------------------------------------------------------------------- 
;;
;; An open implementation of Vector-06C home computer
;;
;; Author: Viacheslav Slavinsky, http://sensi.org/~svo
;; 
;; This will test timer latching, to some extent anyway.
;;
;; --------------------------------------------------------------------

		cpu		8080	
		org		00100H

		xra		a
		sta 	flag
		lxi		h, lolz
		call	msg
		lxi 	h, crlf
		call 	msg
		call	timer	;jump to timer diagnostic
		ret
;
lolz	db		"VECTOR-06C TIMER LATCH PROBULATOR"
crlf	db		0dh, 0ah, '$'
goodmsg	db 		"Good latched MSB: $"
badmsg	db		"Bad latched MSB: $"

;
; Message output
;
msg:	push	psw
		push	d
		mvi		c, 9
		mov 	d,h
		mov 	e,l
		call 	5
		pop		d
msgret:	pop 	psw
		ret
;
; character output routine
;
pchar:	push	psw
		push	d
		push	h
		mov		e,a
		mvi		c,2
		call	5
		pop 	h
		pop		d
		pop		psw
		ret
;
; Byte output (from Kelly Smith test)
;
byteo:	push	psw
		call	byto1
		mov	e,a
		call	pchar
		pop	psw
		call	byto2
		mov	e,a
		jmp	pchar
byto1:	rrc
		rrc
		rrc
		rrc
byto2:	ani	0fh
		cpi	0ah
		jm	byto3
		adi	7
byto3:	adi	30h
		ret

timer:
		di
		mvi 	a, 34h		; ctr 0, mode 2, lsb/msb, binary
		out		08h
		
		mvi		a, 80h		; 
		out		0bh
		out		0bh			; load msb = lsb
		
		mvi 	a, 0h
		out		08h			; latch the counter
		
		in		0bh			; skip lsb
		
		; really wait some time
		lxi		h, 0ffffh
really:		
		dcx		h
		mov		a,h
		ora		l
		jnz		really
		
		in		0bh
		push psw
		cpi		80h
		jnz 	baaad
		lxi		h, goodmsg
		jmp 	over
baaad:
		lxi		h, badmsg
over:
		call 	msg
		pop		psw
		call	byteo
		ret
flag:
		db 0

		end

;; $Id$
