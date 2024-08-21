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
// Source file: philes.h
//
// FAT FS toplevel interface
//
// --------------------------------------------------------------------

#ifndef _PHILES_H
#define _PHILES_H

#include "integer.h"
#include "config.h"

#if NEW_FATFS
#include "ff.h"
#else
#include "tff.h"
#endif

typedef enum file_kind {
    FK_UNKNOWN,
    FK_FDD,
    FK_ROM,
    FK_R0M,
    FK_EDD,
    FK_WAV,
    FK_ASC,
    FK_BAS,
    FK_CAS
} file_kind_t;

void philes_init(void);
FRESULT philes_mount(void);
FRESULT philes_opendir(void);
void philes_setfilter(file_kind_t flt);
FRESULT philes_nextfile(char *filename, uint8_t terminate);
file_kind_t philes_getkind(const char * filename);

#endif
