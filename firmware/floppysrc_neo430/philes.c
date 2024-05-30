// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
//                  Copyright (C) 2007,2008 Viacheslav Slavinsky
//
// This code is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Vector-06C home computer
//
// Author: Viacheslav Slavinsky, http://sensi.org/~svo
// 
// Source file: philes.c
//
// FAT FS toplevel interface
//
// --------------------------------------------------------------------

#include "integer.h"
#include "philes.h"
#include "diskio.h"
#include "tff.h"
#include "serial.h"

#include <string.h>

FATFS           fatfs;
FILINFO         finfo;
DIR             dir;

#define PATHBUF_SZ 64

char pathbuf[PATHBUF_SZ];

char *ptrfile = pathbuf;

const char *default_path = "/VECTOR06/xxxxxxxx.xxx\0\0\0";

static void strxcpy(char *dst, const char *src, int maxlen) {
    uint8_t i = maxlen;
    while (*src != 0 && i--) *dst++ = *src++;
}

BYTE endsWith(char *s1, const char *suffix) {
    int s1len = strlen(s1);
    int sulen = strlen(suffix);

    if (sulen > s1len) return 0;

    return strcmp(&s1[s1len - sulen], suffix) == 0;
}

FRESULT philes_mount() {
    FRESULT result = FR_NO_FILESYSTEM;

    strncpy(ptrfile, default_path, PATHBUF_SZ); // initialise ptrfile

    uint8_t init_status = disk_initialize(0); 
    ser_puts("(disk_initialize: "); print_hex(init_status); ser_putc(')');
    return f_mount(0, &fatfs);
}

FRESULT philes_opendir() {
    FRESULT result;

ser_puts("philes_opendir ptrfile="); ser_puts(ptrfile); ser_puts(" after=");
    ptrfile[9] = 000; 
ser_puts(ptrfile); ser_puts(" @"); print_ptr16(ptrfile); ser_nl();
    result = f_opendir(&dir, ptrfile);                                      
    ptrfile[9] = '/'; 

    return result;
}

// fill in file name in buffer pointed by filename
FRESULT philes_nextfile(char *filename, uint8_t terminate) {
    while ((f_readdir(&dir, &finfo) == FR_OK) && finfo.fname[0]) {
        if (finfo.fattrib & AM_DIR) {
            // nowai
        } else {
            //ser_puts(finfo.fname); ser_nl();
            if (endsWith(finfo.fname, ".FDD")) { // DEBUG restore to ".FDD"
                if (filename != 0) {
                    if (terminate) {
                        strncpy(filename, finfo.fname, 12);
                    } else {
                        strxcpy(filename, finfo.fname, 12);
                    }
                }
                return 0;
            }
        }
    }

    return FR_NO_FILE;
}
