// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
//               Copyright (C) 2007-2024 Viacheslav Slavinsky
//
// This code is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Vector-06C home computer
//
// Author: Viacheslav Slavinsky, https://caglrc.cc
// 
// Source file: serial.c
//
// UART output functions for debugging
//
// --------------------------------------------------------------------

#include "specialio.h"
#include "serial.h"
#include "integer.h"
#include "config.h"

#ifdef WITH_SERIAL
void ser_putc(char c) {
	for(; (SERIAL_CTL & SERIAL_RDY) != 0;);
	SERIAL_TxD = c;
}

void ser_puts(const char *s) {
	for(; *s != 0; s++) {
		for(; (SERIAL_CTL & SERIAL_RDY) != 0;);
		SERIAL_TxD = *s;
	}
}

void ser_nl(void) {
	ser_putc('\n');
}

BYTE nybble_alpha(BYTE nybble) {
	return nybble + (nybble < 0x0a ? '0' : 'a'-0x0a);
}

void print_hex(BYTE b) {
	ser_putc(nybble_alpha((b & 0xf0) >> 4));
	ser_putc(nybble_alpha(b & 0x0f));
}

void print_buff(const BYTE *Buffer) {
  WORD ofs;
  BYTE add;
  BYTE c;
  
  for (ofs = 0; ofs < FDD_SECTOR_SIZE; ofs += 16) {
	ser_nl();
	for (add = 0; add < 16; add++) {
		print_hex(Buffer[ofs+add]);
		ser_putc(add == 8 ? '-' : ' '); 
	}
	for (add = 0; add < 16; add++) {
		c = Buffer[ofs+add];
		ser_putc(c > 31 && c < 128 ? c : '.'); 
	}
  }
  ser_nl();
}

void print_ptr16(void * ptr)
{
    uint16_t n = (uint16_t) ptr;
    print_hex(n & 255);
    print_hex(n >> 8);
}
#endif

