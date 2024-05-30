// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
//              Copyright (C) 2007,2008 Viacheslav Slavinsky
//
// This code is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Vector-06C home computer
//
// Author: Viacheslav Slavinsky, http://sensi.org/~svo
// 
// Source file: osd.c
//
// On-Screen Display functions
//
// --------------------------------------------------------------------

#include "specialio.h"
#include "integer.h"
#include "osd.h"

#include <string.h>

extern char* cnotice1;

uint8_t* dmem = (uint8_t*) DISPLAY_BASE;

static uint8_t x, y;
static uint8_t inv;

void osd_cls(uint8_t hdr) {
    x = 0;
    y = 0;
    inv = 0;
    memset(dmem, 32, DISPLAY_RAMSIZE);
    if (hdr) {
        osd_inv(1); osd_puts(cnotice1); osd_inv(0);
    }
}

void osd_gotoxy(uint8_t _x, uint8_t _y) {
    x = _x;
    y = _y;
}

void osd_puts(char *s) {
    uint8_t ofs = (y << 5) + x;
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
