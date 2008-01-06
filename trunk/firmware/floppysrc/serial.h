#ifndef _SERIAL_H_
#define _SERIAL_H_

#define SERIAL_RDY	0x01	// buffer empty

#define NL	"\r\n"

void ser_putc(char c);
void ser_puts(char *s);
void ser_nl();

#endif