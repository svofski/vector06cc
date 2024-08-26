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
// Source file: serial.h
//
// UART output functions for debugging
//
// --------------------------------------------------------------------

#ifndef _SERIAL_H_
#define _SERIAL_H_

#include "integer.h"
#include "config.h"

#define SERIAL_RDY	0x01	// buffer empty

#define NL	"\n"

#ifdef WITH_SERIAL

void ser_putc(char c);
void ser_puts(const char *s);
void ser_nl(void);
void print_hex(BYTE b);
void print_dec_u32(uint32_t n);
void print_ptr16(void * ptr);
void print_buff(const BYTE *Buffer);

#else

#define ser_putc(c) {}
#define ser_puts(s) {}
#define ser_nl(void) {}
#define print_hex(b) {}
#define print_buff(Buffer) {}

#endif

#define vputs(s) {}
#define vputc(s) {}
#define vputh(s) {}
#define vdump(s) {}
#define vnl()    {}

#if VERBOSE >= 3
#undef vdump
#define vdump(b)  print_buff(b)
#endif

#if VERBOSE >= 2
#undef vputs
#undef vputc
#undef vputh
#undef vnl
#define vputs(s) ser_puts(s)
#define vputc(c) ser_putc(c)
#define vputh(x) print_hex(x)
#define vnl()    ser_nl()
#endif


#endif
