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
	
	fdd->ntracks = file->fsize / (2*TRACK_1SIDE*SECTOR_SIZE);	// these seem to be fixed more or less
	fdd->nsides = 2;
	fdd->nsectors = TRACK_1SIDE;
	fdd->sectorsize = SECTOR_SIZE;
	fdd->file = file;
	fdd->buffer = bufptr;
	
	return (uint8_t) 0;
}

uint8_t fdd_seek(FDDImage *fdd, uint8_t side, uint8_t track, uint8_t sector) {
	fdd_clearerror();
	
	if (side > fdd->nsides||
		track > fdd->ntracks ||
		sector > fdd->nsectors) seterror(FDD_SEEK_ERROR);
		
	fdd->cur_side = side;
	fdd->cur_track = track;
	fdd->cur_sector = sector;
	fdd->offset = 0;
	fdd->ready = 0;
}

/*
uint8_t fdd_nextbyte(FDDImage *fdd) {
	uint8_t result;
	
	if (!fdd->ready) {
		fdd->ready = fdd_readsector(fdd) == FR_OK ? 1 : 0;
		if (!fdd->ready)
			seterror(FDD_READ_ERROR);
	}
	
	if (fdd->ready) {
		result = fdd->buffer[fdd->offset];
		fdd->offset++;
		if (fdd->offset >= fdd->sectorsize) {
			fdd->ready = 0;
		}
	} 
	
	return result;
}
*/

FRESULT fdd_readsector(FDDImage* fdd) {
	FRESULT r;
	UINT bytesread;
	
	uint32_t offset = fdd->nsides*fdd->cur_track + fdd->cur_side;
	offset *= fdd->nsectors;
	offset += fdd->cur_sector - 1;
	offset *= fdd->sectorsize;
	
	//uint32_t offset = (fdd->nsectors*(fdd->nsides*fdd->cur_track + fdd->cur_side) + fdd->cur_sector - 1) * fdd->sectorsize;
	
	if ((r = f_lseek(fdd->file, offset)) != FR_OK) return r;
	
	r = f_read(fdd->file, fdd->buffer, fdd->sectorsize, &bytesread);
	
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
