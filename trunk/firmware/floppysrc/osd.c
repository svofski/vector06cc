#include "specialio.h"
#include "integer.h"
#include "osd.h"

#include <string.h>

uint8_t* dmem = (uint8_t*) DISPLAY_BASE;

uint8_t x, y;
uint8_t inv;

void osd_cls() {
	x = 0;
	y = 0;
	inv = 0;
	memset(dmem, 32, DISPLAY_RAMSIZE);
}

void osd_gotoxy(uint8_t _x, uint8_t _y) {
	x = _x;
	y = _y;
}

void osd_puts(char *s) {
	uint8_t ofs = y << 5 + x;
	int i;
	
	if (inv) {
		for (i = ofs; *s != 0; i++, s++) dmem[i] = 0x80 | *s;
	} else {
		memcpy(dmem+ofs, s, strlen(s));
	}
}

void osd_inv(uint8_t i) {
	inv = i;
}