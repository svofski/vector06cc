; ---------------------------------------------------------------------------
; crt0.s
; ---------------------------------------------------------------------------
;
; Startup code for cc65 (Vector-06C FDD emulator version)
;
; This must be the *first* file on the linker command line

		.export         _exit
		.export		_init
		.import	        _main
		
		.export   __STARTUP__ : absolute = 1        ; Mark as startup
		.import   __RAM_START__, __RAM_SIZE__       ; Linker generated
		
		.import    copydata, zerobss, initlib, donelib
       	;.import	__CONSTRUCTOR_TABLE__, __CONSTRUCTOR_COUNT__
		;.import	__DESTRUCTOR_TABLE__, __DESTRUCTOR_COUNT__

		.include "zeropage.inc"
		.include "vector.inc"

; ---------------------------------------------------------------------------
; Place the startup code in a special segment

.segment  "STARTUP"
.bss
.code

; ---------------------------------------------------------------------------
; A little light 6502 housekeeping

_init:
		LDX     #$FF;  $FF is loaded to X immediately
		;TXS			; X->SP
		CLD         ; Clear decimal mode
;		JSR     zerobss              ; Clear BSS segment
;		JSR     copydata             ; Initialize DATA segment

; ---------------------------------------------------------------------------
; Set cc65 argument stack pointer

;		LDA     #<(__RAM_START__ + __RAM_SIZE__)
;		STA     sp
		LDA     #>(__RAM_START__ + __RAM_SIZE__)
		STA     sp+1
       		stz	sp
; ---------------------------------------------------------------------------
; Initialize memory storage

;		;JSR     zerobss              ; Clear BSS segment
;		;JSR     copydata             ; Initialize DATA segment
;		JSR     initlib              ; Run constructors
		

; ---------------------------------------------------------------------------
; Call main()

		JSR     _main

; ---------------------------------------------------------------------------
; Back from main (this is also the _exit entry):  force a software break

_exit:  JSR     donelib              ; Run destructors
exit:	jmp    	exit


.proc   irq
		pha		;push	A
		pla		;pop	A
		rti		;return from interrupt
.endproc

.proc   nmi
		rti
.endproc
