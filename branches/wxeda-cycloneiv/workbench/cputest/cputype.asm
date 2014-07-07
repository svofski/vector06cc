		cpu 8080
		org 100h
	
		lxi 	d, hellojpg
		mvi 	c, 9
		call 	5
		call 	cpudetect
		mvi		c, 9
		call 	5
		ret
hellojpg	db	"DETECTING CPU TYPE",0dh,0ah,"THE CPU IS: $"
msg_z80		db	"Z80$"
msg_8080	db	"KP580BM80A$"
msg_vm1		db	"KP580BM1$"
cpudetect:
		lxi		d, msg_z80
		
		xra		a
		dcr		a
		rpo
		
		lxi		h, 0020h
		push	h
		pop		psw
		push	psw
		pop		h
		mvi		a, 20h
		ana		l
		jz		kr580
		lxi		d, msg_vm1
		ret
kr580:	lxi		d, msg_8080
		ret
		
		end
		