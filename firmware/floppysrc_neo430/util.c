#include "config.h"
#include "integer.h"
#include "serial.h"

void print_nybble(BYTE nybble) {
    ser_putc(nybble + (nybble < 0x0a ? '0' : 'a'-0x0a));
}

void print_hex(BYTE b) {
    print_nybble((b & 0xf0) >> 4);
    print_nybble(b & 0x0f);
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

void print_hex16(uint16_t n)
{
    print_hex(n & 255);
    print_hex(n >> 8);
}


void print_dec_u32(uint32_t n)
{
    char buf[11];
    buf[10] = 0;
    int pos = 10;

    while (n > 0 && pos >= 0) {
        buf[--pos] = n % 10 + '0';
        n /= 10;
    }
    ser_puts(&buf[pos]);
}

