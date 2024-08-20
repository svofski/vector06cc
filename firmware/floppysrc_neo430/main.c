// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
//              Copyright (C) 2007-2024, Viacheslav Slavinsky
//
// This code is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Vector-06C home computer
//
// Author: Viacheslav Slavinsky, https://caglrc.cc
// 
// Source file: main.c
//
// FDC workhorse main module.
//
// --------------------------------------------------------------------

#include <string.h>

#include "config.h"

#include "serial.h"
#include "specialio.h"
#include "integer.h"

#include "diskio.h"

#include "timer.h"

#if NEW_FATFS
#include "ff.h"
#else
#include "tff.h"
#endif

#include "slave.h"

#include "osd.h"

#include "philes.h"

void _zpu_interrupt(void) {}
void _premain(void) {}

/*---------------------------------------------------------*/
/* User Provided Timer Function for FatFs module           */
/*---------------------------------------------------------*/
/* This is a real time clock service to be called from     */
/* FatFs module. Any valid time must be returned even if   */
/* the system does not support a real time clock.          */
DWORD get_fattime (void)
{
    return 0;
}


volatile BYTE* Buffer = SECTOR_BUFFER;

void print_result(DRESULT result) {
    switch (result) {
        case 0:
            break;
        default:
            ser_puts(" :( ");
            print_hex((BYTE)result);
            ser_nl();
            break;
    }
}

void fill_filename(char *buf, char *fname) {
    memset(buf, 0, 12);
    strncpy(buf, fname, 12);
}

#define CHECKRESULT {/*if (result) break;*/}

extern char* ptrfile;

int test_buf()
{
    ser_puts("test_buf write...");
    //print_buff(Buffer);

    for (int i = 0; i < SECTOR_BUFFER_SZ; ++i) {
        Buffer[i] = i & 255;
    }
    ser_puts(" readback...");
    //print_buff(Buffer);
    //

    for (int i = 0; i < SECTOR_BUFFER_SZ; ++i) {
        uint8_t v = Buffer[i];
        if (v != (i & 255)) {
            ser_puts(" ERROR\n");
            return i;
        }
    }
    ser_puts(" OK\n");

    return SECTOR_BUFFER_SZ;
}

int main(void) {
    DRESULT result;
    FRESULT fresult;
    
    SLAVE_STATUS = 0;
    GREEN_LEDS = 0xC3;

    ser_puts("@");
    delay2(10);
    test_buf();

    //ser_puts("A");
    
    extern const char *cnotice1, *cnotice2;
    ser_nl(); ser_puts(cnotice1); 
    ser_nl(); ser_puts(cnotice2);
    ser_nl();

    thrall(ptrfile, Buffer);
    print_result(result);
    ser_puts("\r\nWTF?");
}
