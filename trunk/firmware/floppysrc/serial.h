#ifndef _SERIAL_H_
#define _SERIAL_H_

#define SERIAL_RDY	0x01	// buffer empty

void ser_putc(char c);
void ser_puts(char *s);

#endif