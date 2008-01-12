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

	uint8_t result;
	uint8_t t1, t2;

	if (f_open(&file1, imagefile, FA_READ) != FR_OK) return SR_OPENERR;

	fdd_load(&file1, &fddimage, buffer);
	fdd_seek(&fddimage, 0, 4, 1);
	if (fdd_readsector(&fddimage) != FR_OK) return SR_READERR;

	if (buffer[0] != '\000' || buffer[1] == '\000') return SR_FORMAT;	// directory starts with a 0
	
	// tests passed, clear to slave forever
	
	SLAVE_STATUS = 0;

	for (;;) {
		t1 = MASTER_COMMAND;
		t2 = MASTER_SECTOR;

		//if (t1 != last_request) {
			last_request = t1;
			

			switch (t1 & 0xf0) {
			case CPU_REQUEST_READ:
				SLAVE_STATUS = 0;
				ser_nl();
				ser_puts("rHST(");
				print_hex(t1);
				print_hex(t2);
				ser_putc(')');
			
				fdd_seek(&fddimage, 0x01 & ~t1, MASTER_TRACK, MASTER_SECTOR);

				print_hex(fddimage.cur_side);
				print_hex(fddimage.cur_sector);
				print_hex(fddimage.cur_track);

				result = fdd_readsector(&fddimage);
				
				ser_putc(':');
				print_hex(result);
			
				//print_buff(fddimage.buffer);

				
				SLAVE_STATUS = CPU_STATUS_COMPLETE | (result == FR_OK ? CPU_STATUS_SUCCESS : 0);
				// touche!

				break;
			case CPU_REQUEST_READADDR:
				// fill the beginning of buffer with position info
				// 6 bytes: track, side, sector, sectorsize code, crc1, crc2
				SLAVE_STATUS = 0;
				ser_putc('Q');

				result = fdd_readadr(&fddimage);
				SLAVE_STATUS = CPU_STATUS_COMPLETE | (result == FR_OK ? CPU_STATUS_SUCCESS : 0);
				// touche!
				break;
			case CPU_REQUEST_WRITE:
				SLAVE_STATUS = CPU_STATUS_COMPLETE; // no success
				ser_putc('W');
				break;
			case CPU_REQUEST_ACK:
				SLAVE_STATUS = 0;
				//ser_putc('A');
				break;
			case CPU_REQUEST_NOTIFY:
				ser_putc('<');
				print_hex(MASTER_COMMAND);
				print_hex(MASTER_SECTOR);
				print_hex(MASTER_TRACK);
				ser_putc('>');
				SLAVE_STATUS = CPU_STATUS_COMPLETE;
				break;
			case CPU_REQUEST_FAIL:
				ser_putc('[');
				print_hex(MASTER_COMMAND);
				print_hex(MASTER_SECTOR);
				ser_putc(']');
				break;
			default:
				break;
			}
		//} else {
		//	if (--delay == 0) {
		//		delay = DELAY_RELOAD;
		//		GREEN_LEDS = leds;
		//		leds <<= 1;
		//		if (leds == 0) leds = 0x01;
		//	}
		//}
	}
}
