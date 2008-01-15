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
// Source file: fddimage.c
//
// FDD floppy image implementation
//
// --------------------------------------------------------------------


#include "integer.h"
#include "fddimage.h"
#include "tff.h"
#include "config.h"

enum FDDErrors{
	FDD_OK,
	FDD_SEEK_ERROR,
	FDD_READ_ERROR,
};

static uint8_t fdderror;

static FDDImage fdd;

static void seterror(uint8_t e) {
	fdderror = e;
}

uint8_t fdd_clearerror() {
	uint8_t result = fdderror;
	fdderror = 0;
	return result;
}

uint8_t fdd_load(FIL* file, FDDImage *fdd, uint8_t *bufptr) {
	fdd_clearerror();
	
	fdd->ntracks = file->fsize / (2*FDD_NSECTORS*FDD_SECTOR_SIZE);	// these seem to be fixed more or less
	fdd->nsides = FDD_NSIDES;
	fdd->nsectors = FDD_NSECTORS;
	fdd->sectorsize = FDD_SECTOR_SIZE;
	fdd->file = file;
	fdd->buffer = bufptr;
	
	return (uint8_t) 0;
}

uint8_t fdd_seek(FDDImage *fdd, uint8_t side, uint8_t track, uint8_t sector) {
	fdd_clearerror();
	
	if (side > FDD_NSIDES||
		track > fdd->ntracks ||
		sector > FDD_NSECTORS) seterror(FDD_SEEK_ERROR);
		
	fdd->cur_side = side;
	fdd->cur_track = track;
	fdd->cur_sector = sector;
	fdd->offset = 0;
	fdd->ready = 0;
}

FRESULT fdd_readsector(FDDImage* fdd) {
	FRESULT r;
	UINT bytesread;
	
	uint32_t offset = FDD_NSIDES*fdd->cur_track + (1-fdd->cur_side);
	offset *= FDD_NSECTORS; 
	offset += fdd->cur_sector - 1;
	offset *= FDD_SECTOR_SIZE;
	
	if ((r = f_lseek(fdd->file, offset)) != FR_OK) return r;
	
	r = f_read(fdd->file, fdd->buffer, FDD_SECTOR_SIZE, &bytesread);
	
	return r;
}

FRESULT fdd_readadr(FDDImage *fdd) {
	uint8_t sizecode = SECTOR_SIZE_CODE;
	
	// 6 bytes: track, side, sector, sectorsize code, crc1, crc2
	fdd->buffer[0] = fdd->cur_track;
	fdd->buffer[1] = fdd->cur_side;
	fdd->buffer[2] = fdd->cur_sector;
	fdd->buffer[3] = sizecode;
	fdd->buffer[4] = 0;
	fdd->buffer[5] = 0;
	
	return FR_OK;
}
