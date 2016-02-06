;
; Startup code for cc65 (Vector-06C FDD emulator version)
;
; This must be the *first* file on the linker command line
;

		.export         _exit
	        .export         __STARTUP__ : absolute = 1      ; Mark as startup
	
		.import	        _main
    		.import         initlib, donelib, copydata
    		.import         zerobss
		.import		__RAM_START__, __RAM_SIZE__	; Linker generated
       		.import		__CONSTRUCTOR_TABLE__, __CONSTRUCTOR_COUNT__
		.import		__DESTRUCTOR_TABLE__, __DESTRUCTOR_COUNT__

		.include "zeropage.inc"
		.include "vector.inc"

.bss
.code

		.segment  "STARTUP"
reset:
		jsr	zerobss

		; initialize data
		jsr	copydata

	        lda     #>(__RAM_START__ + __RAM_SIZE__)
       		sta	sp+1   		; Set argument stack ptr
       		stz	sp              ; #<(__RAM_START__ + __RAM_SIZE__)
       	
		jsr	initlib
		jsr	_main
_exit:		jsr     donelib
exit:   	jmp    	exit


.proc   	irq
		pha
		pla
		rti
.endproc

.proc   	nmi
		rti
.endproc

