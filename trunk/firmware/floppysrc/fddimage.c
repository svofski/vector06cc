#include "integer.h"
#include "fddimage.h"
#include "tff.h"

enum FDDErrors{
	FDD_OK,
	FDD_SEEK_ERROR,
	FDD_READ_ERROR,
};

static uint8_t fdderror;

static FDDImage fdd;

uint8_t fdd_clearerror();
uint8_t fdd_load(FIL* file, FDDImage *fdd);
uint8_t fdd_seek(FDDImage *fdd, uint8_t side, uint8_t track, uint8_t sector);
uint8_t fdd_nextbyte(FDDImage* fdd);
FRESULT fdd_readsector(FDDImage* fdd);

static void seterror(uint8_t e) {
	fdderror = e;
}

uint8_t fdd_clearerror() {
	uint8_t result = fdderror;
	fdderror = 0;
	return result;
}

uint8_t fdd_load(FIL* file, FDDImage *fdd) {
	fdd_clearerror();
	
	fdd->ntracks = file->fsize / (2*10*512);	// these seem to be fixed more or less
	fdd->nsides = 2;
	fdd->nsectors = 10;
	fdd->sectorsize = 512;
	
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

FRESULT fdd_readsector(FDDImage* fdd) {
	uint32_t offset = (fdd->cur_track*(fdd->nsides+fdd->cur_side) + fdd->cur_sector) * fdd->sectorsize;
	FRESULT r = f_lseek(fdd->file, offset);
	
	return r;
}