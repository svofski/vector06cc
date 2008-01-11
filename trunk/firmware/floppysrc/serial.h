#ifndef _SERIAL_H_
#define _SERIAL_H_

#include "integer.h"
#include "config.h"

#define SERIAL_RDY	0x01	// buffer empty

#define NL	"\r\n"

#ifdef WITH_SERIAL

void ser_putc(char c);
void ser_puts(char *s);
void ser_nl();
void print_hex(BYTE b);
void print_buff(BYTE *Buffer);

#else

#define ser_putc(c) {}
#define ser_puts(s) {}
#define ser_nl() {}
#define print_hex(b) {}
#define print_buff(Buffer) {}

#endif

#endif