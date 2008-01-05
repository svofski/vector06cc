#include "slave.h"
#include "specialio.h"
#include "tff.h"
#include "fddimage.h"
#include "integer.h"
#include "timer.h"

#include "serial.h"

FDDImage fddimage;

#define DELAY_RELOAD 4096

// thrall forever
uint8_t slave(const char *imagefile, uint8_t *buffer) {
	FIL	file1;
	uint8_t leds = 0x01;
	uint16_t delay = 1;
	uint8_t last_request = 0377;

	if (f_open(&file1, imagefile, FA_READ) != FR_OK) return SR_OPENERR;

	ser_puts("opened file\n\r");

	//if (f_lseek(&file1, 0xA000U) != FR_OK) return SR_READERR;
	//if (f_read(&file1, buffer, SECTOR_SIZE, &bytesread) != FR_OK) return SR_READERR;
	//if (buffer[0] != '\000') return SR_FORMAT;
	
	fdd_load(&file1, &fddimage, buffer);
	fdd_seek(&fddimage, 0, 4, 0);
	if (fdd_readsector(&fddimage) != FR_OK) return SR_READERR;

	ser_puts("read sector\n\r");

	if (buffer[0] != '\000') return SR_FORMAT;	// directory starts with a 0
	
	ser_puts("format match\n\r");

	// initial tests passed, it seems we're clear to slave forever now
	
	for (;;) {
		if (MASTER_COMMAND != last_request) {
			last_request = MASTER_COMMAND;
			
			switch (MASTER_COMMAND & 0xf0) {
			case CPU_REQUEST_READ:
				ser_puts("R");
				SLAVE_STATUS = 0;
				fdd_seek(&fddimage, MASTER_COMMAND & 0x01, MASTER_TRACK, MASTER_SECTOR);
				if (fdd_readsector(&fddimage) != FR_OK) SLAVE_STATUS = CPU_STATUS_ERROR;
				SLAVE_STATUS |= CPU_STATUS_COMPLETE;
				// touche!
				break;
			case CPU_REQUEST_READADDR:
				ser_puts("Q");
				// fill the beginning of buffer with position info
				// 6 bytes: track, side, sector, sectorsize code, crc1, crc2
				SLAVE_STATUS = 0;
				if (fdd_readadr(&fddimage) != FR_OK) SLAVE_STATUS |= CPU_STATUS_ERROR;
				SLAVE_STATUS |= CPU_STATUS_COMPLETE;
				// touche!
				break;
			case CPU_REQUEST_WRITE:
				ser_puts("W");
				SLAVE_STATUS = CPU_STATUS_COMPLETE | CPU_STATUS_ERROR;
				break;
			case CPU_REQUEST_ACK:
				ser_puts("A");
				SLAVE_STATUS = 0;
				break;
			default:
				break;
			}
		} else {
			if (--delay == 0) {
				delay = DELAY_RELOAD;
				GREEN_LEDS = leds;
				leds <<= 1;
				if (leds == 0) leds = 0x01;
			}
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
