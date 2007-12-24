#include "specialio.h"
#include "serial.h"

void ser_putc(char c) {
	for(; SERIAL_CTL & SERIAL_RDY != 0;);
	SERIAL_TxD = c;
}

void ser_puts(char *s) {
	for(; *s != 0; s++) {
		for(; SERIAL_CTL & SERIAL_RDY != 0;);
		SERIAL_TxD = *s;
	}
}

