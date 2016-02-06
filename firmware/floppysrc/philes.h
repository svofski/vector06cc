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
// Source file: philes.h
//
// FAT FS toplevel interface
//
// --------------------------------------------------------------------

#ifndef _PHILES_H
#define _PHILES_H

#include "integer.h"
#include "tff.h"

FRESULT philes_mount(void);
FRESULT philes_opendir(void);
FRESULT philes_nextfile(char *filename, uint8_t terminate);

#endif
