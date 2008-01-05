#include "slave.h"
#include "specialio.h"
#include "tff.h"
#include "fddimage.h"
#include "integer.h"
#include "timer.h"

FDDImage fddimage;

// thrall forever
uint8_t slave(const char *imagefile, uint8_t *buffer) {
	FIL	file1;
	uint8_t leds = 0xffffU;
	uint16_t delay = 0;

	if (f_open(&file1, imagefile, FA_READ) != FR_OK) return SR_OPENERR;
	//if (f_lseek(&file1, 0xA000U) != FR_OK) return SR_READERR;
	//if (f_read(&file1, buffer, SECTOR_SIZE, &bytesread) != FR_OK) return SR_READERR;
	//if (buffer[0] != '\000') return SR_FORMAT;
	
	fdd_load(&file1, &fddimage, buffer);
	fdd_seek(&fddimage, 0, 4, 0);
	if (fdd_readsector(&fddimage) != FR_OK) return SR_READERR;
	if (buffer[0] != '\000') return SR_FORMAT;	// directory starts with a 0
	
	// initial tests passed, it seems we're clear to slave forever now
	
	for (;;) {
		switch (MASTER_COMMAND & 0xf0) {
		case CPU_REQUEST_ACK:
			SLAVE_STATUS = 0;
			break;
		case CPU_REQUEST_READ:
			SLAVE_STATUS = 0;
			fdd_seek(&fddimage, MASTER_COMMAND & 0x01, MASTER_TRACK, MASTER_SECTOR);
			if (fdd_readsector(&fddimage) != FR_OK) SLAVE_STATUS = CPU_STATUS_ERROR;
			SLAVE_STATUS |= CPU_STATUS_COMPLETE;
			// touche!
			break;
		case CPU_REQUEST_READADDR:
			// fill the beginning of buffer with position info
			// 6 bytes: track, side, sector, sectorsize code, crc1, crc2
			SLAVE_STATUS = 0;
			if (fdd_readadr(&fddimage) != FR_OK) SLAVE_STATUS |= CPU_STATUS_ERROR;
			SLAVE_STATUS |= CPU_STATUS_COMPLETE;
			// touche!
			break;
		case CPU_REQUEST_WRITE:
			SLAVE_STATUS = CPU_STATUS_COMPLETE | CPU_STATUS_ERROR;
			break;
		default:
			if (--delay == 0) {
				GREEN_LEDS = leds;
				leds <<= 1;
				if (leds == 0) leds = 0x01;
			}
			break;
		}
	}
/*	
	for(;;) {
		GREEN_LEDS = leds;
		delay1(10);
		leds <<= 1;
		if (leds == 0) leds = 0x01;
	}
*/	
}
