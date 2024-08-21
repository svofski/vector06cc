// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
//               Copyright (C) 2007-2024 Viacheslav Slavinsky
//
// This code is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Vector-06C home computer
//
// Author: Viacheslav Slavinsky, https://caglrc.cc
// 
// Source file: philes.c
//
// FAT FS toplevel interface
//
// --------------------------------------------------------------------

#include "config.h"
#include "integer.h"
#include "philes.h"
#include "diskio.h"
#include "serial.h"

#if NEW_FATFS
#include "ff.h"
#else
#include "tff.h"
#endif

#include <string.h>

FATFS           fatfs;
FILINFO         finfo;
DIR             dir;

#define PATHBUF_SZ 64

char pathbuf[PATHBUF_SZ];

char *ptrfile = pathbuf;

const char *default_path = "/VECTOR06/xxxxxxxx.xxx\0\0\0";

static file_kind_t filter;

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

file_kind_t philes_getkind(const char * filename)
{
    int fnlen = strlen(filename);
    int sulen = 4;  // ".fdd", ".rom", etc
    if (sulen > fnlen) return FK_UNKNOWN;

    if (strcmp(&filename[fnlen - sulen], ".FDD") == 0) return FK_FDD;
    if (strcmp(&filename[fnlen - sulen], ".ROM") == 0) return FK_ROM;
    if (strcmp(&filename[fnlen - sulen], ".R0M") == 0) return FK_R0M;
    if (strcmp(&filename[fnlen - sulen], ".EDD") == 0) return FK_EDD;
    if (strcmp(&filename[fnlen - sulen], ".WAV") == 0) return FK_WAV;
    if (strcmp(&filename[fnlen - sulen], ".ASC") == 0) return FK_ASC;
    if (strcmp(&filename[fnlen - sulen], ".BAS") == 0) return FK_BAS;
    if (strcmp(&filename[fnlen - sulen], ".CAS") == 0) return FK_CAS;

    return FK_UNKNOWN;
}

void philes_setfilter(file_kind_t flt)
{
    filter = flt;
}

int filter_accept(file_kind_t k)
{
    if (k == filter) return 1;

    switch (filter) {
        case FK_ROM:
            return k == FK_ROM || k == FK_R0M;
        case FK_CAS:
            return k == FK_CAS || k == FK_BAS || k == FK_ASC;
        default:
            break;
    }
    return 0;
}

void philes_init()
{
    strncpy(ptrfile, default_path, PATHBUF_SZ); // initialise ptrfile
    filter = FK_FDD;
}

FRESULT philes_mount() {
    FRESULT result = FR_NO_FILESYSTEM;

    uint8_t init_status = disk_initialize(0); 
    ser_puts("(disk_initialize: "); print_hex(init_status); ser_putc(')');
#if NEW_FATFS
    return f_mount(&fatfs, "", 0);
#else
    return f_mount(0, &fatfs);
#endif
}

FRESULT philes_opendir() {
    FRESULT result;

    ptrfile[9] = 000; 
    result = f_opendir(&dir, ptrfile);                                      
    ptrfile[9] = '/'; 

    return result;
}

// fill in file name in buffer pointed by filename
FRESULT philes_nextfile(char *filename, uint8_t terminate) {
    FRESULT res;

    while (((res = f_readdir(&dir, &finfo)) == FR_OK) && finfo.fname[0]) {
        if (finfo.fattrib & AM_DIR) {
            // nowai
        } else {
            int fk = philes_getkind(finfo.fname);
            if (filter_accept(fk)) {
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
