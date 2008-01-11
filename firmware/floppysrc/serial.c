#include "specialio.h"
#include "serial.h"
#include "integer.h"
#include "config.h"

#ifdef WITH_SERIAL
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

void ser_nl() {
	ser_putc('\r');
	ser_putc('\n');
}

BYTE nybble_alpha(BYTE nybble) {
	return nybble + (nybble < 0x0a ? '0' : 'a'-0x0a);
}

void print_hex(BYTE b) {
	ser_putc(nybble_alpha((b & 0xf0) >> 4));
	ser_putc(nybble_alpha(b & 0x0f));
}

void print_buff(BYTE *Buffer) {
  WORD ofs;
  
  for (ofs = 0; ofs < SECTOR_SIZE; ofs++) {
    if (ofs % 16 == 0) {
      ser_nl();
    } else if (ofs % 8 == 0) {
      ser_putc('-');
    } else ser_putc(' ');
    print_hex(Buffer[ofs]); 
  }
}
#endif

