// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
// 					Copyright (C) 2007, Viacheslav Slavinsky
//
// This code is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Vector-06C home computer
//
// Author: Viacheslav Slavinsky, http://sensi.org/~svo
// 
// Source file: fddimage.h
//
// FDD floppy image interface
//
// --------------------------------------------------------------------
#ifndef _FDDIMAGE_H
#define _FDDIMAGE_H

#include "integer.h"
#include "tff.h"

typedef struct {
	uint8_t nsides;
	uint8_t ntracks;
	uint8_t nsectors;
	uint16_t sectorsize;
	
	uint8_t cur_side;
	uint8_t cur_sector;
	uint8_t cur_track;
	
	FIL* file;
	uint16_t offset;		// current offset into buffer
	uint8_t	ready;			// 1 => read operation must be performed first
	uint8_t	*buffer;
} FDDImage;

uint8_t fdd_clearerror();
uint8_t fdd_load(FIL* file, FDDImage *fdd, uint8_t* bufptr);
uint8_t fdd_seek(FDDImage *fdd, uint8_t side, uint8_t track, uint8_t sector);
//uint8_t fdd_nextbyte(FDDImage* fdd);
FRESULT fdd_readsector(FDDImage* fdd);
FRESULT fdd_readadr(FDDImage *fdd);

#endif