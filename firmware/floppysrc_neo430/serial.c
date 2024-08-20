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

#endif

