// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
//                 Copyright (C) 2007,2008 Viacheslav Slavinsky
//
// This code is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Vector-06C home computer
//
// Author: Viacheslav Slavinsky, http://sensi.org/~svo
// 
// Source file: osd.h
//
// On-Screen Display functions
//
// --------------------------------------------------------------------

#ifndef _OSD_H
#define _OSD_H

#include "integer.h"

void osd_cls(uint8_t hdr);
void osd_gotoxy(uint8_t _x, uint8_t _y);
void osd_puts(char *s);
void osd_inv(uint8_t i);

#endif