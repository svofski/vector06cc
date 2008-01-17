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
;; Timer test program. This piece is based on a timer probe 
;; routine found in the SkyNet demo by Sunami et al. 
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
		jmp		timer	;jump to timer diagnostic
;
lolz	db		"VECTOR-06C TIMER PROBULATOR"
crlf	db		0dh, 0ah, '$'
expec	db 		"Expected $"
bad1	db		"B0, got:$"
bad2	db		"50, got:$"
bad3 	db		"30, got:$"
badnik 	db		"Bad, useless timer.$"
good	db		"It must be a very good timer!$"

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
		mvi 	a, 14h		; ctr 0, mode 2, lsb only, binary
		out		08h
		
		mvi		a, 80h		; load value into ctr0
		out		0bh
		
		mvi 	a, 54h		; ctr 1, mode 2, lsb only, binary
		out		08h
		
		mvi		a, 60h		; load ctr 1
		out		0ah
		
		mvi		a, 94h		; ctr 2, mode 2, lsb only, binary
		out		08h
		
		mvi 	a, 0e0h		; load ctr 2
		out		09h
		
		mvi		a, 00h		; ctr 0, latch value
		out		08h
		
		in		0bh			; read value of ctr0
		mov		c, a
		
		mvi		a, 40h		; load ctr 0
		out		08h
		
		in		0ah			; read ctr 1
		mov		b, a
		
		mvi		a, 80h		; ctr 2, latch value
		out		08h
		
		in		09h			; read ctr 2
		mvi		d, 01
		cpi		0b0h
		cnz		fail1
		
		mov		a, c
		cpi		50h
		cnz		fail2
		
		mov		a, b
		cpi		30h
		cnz		fail3
		
		lda		flag
		ora		a
		jnz		noir
		lxi		h, good
		call	msg
		jmp		gagg
	
noir:
		lxi		h, badnik
		call	msg
gagg:
		mvi		a, 10h
		mvi		b, 40h
		out		8
		out		0bh
		add		b
		out		8
		out		0ah
		add		b
		out		8
		out		09h
		ret
fail1:
		lxi	h, bad1
		jmp fail
fail2:
		lxi	h, bad2
		jmp fail
fail3:
		lxi h, bad3
fail:
		push 	b
		push	d
		push	psw
		push	h
		lxi		h, expec
		call	msg
		pop		h
		call	msg
		mvi		a, 1
		sta 	flag
		pop 	psw
		call	byteo
		lxi		h, crlf
		call	msg
		pop		d
		pop		b
		ret
flag:
		db 0

		end

;; $Id$