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
// Source file: slave.c
//
// Main request handler, runs eternally
//
// --------------------------------------------------------------------

#include "slave.h"
#include "specialio.h"
#include "tff.h"
#include "fddimage.h"
#include "integer.h"
#include "timer.h"
#include "menu.h"

#include "serial.h"


#define vputs(s) {}
#define vputc(s) {}
#define vputh(s) {}
#define vdump(s) {}
#define vnl()	 {}

#if VERBOSE >= 3
  #undef vdump
  #define vdump(b)  print_buff(b)
#endif

#if VERBOSE >= 2
  #undef vputs
  #undef vputc
  #undef vputh
  #undef vnl
  #define vputs(s) ser_puts(s)
  #define vputc(c) ser_putc(c)
  #define vputh(x) print_hex(x)
  #define vnl()	   ser_nl()
#endif

FDDImage fddimage;
FIL	file1;

#define DELAY_RELOAD 4096

void blink(void);


uint8_t useimage(const char *imagefile, uint8_t *buffer) {
	menu_init();
	
	if (f_open(&file1, imagefile, FA_READ) != FR_OK) return SR_OPENERR;

	fdd_load(&file1, &fddimage, buffer);
	fdd_seek(&fddimage, 1, 4, 1);
	if (fdd_readsector(&fddimage) != FR_OK) return SR_READERR;
	// tests passed, clear to slave forever
	slave(buffer);
}

// thrall forever
uint8_t slave(uint8_t *buffer) {
	uint8_t result;
	uint8_t t1;

	
	SLAVE_STATUS = 0;

	for (;result != FR_RW_ERROR;) {
		result = FR_OK;
		switch (MASTER_COMMAND & 0xf0) {
		case CPU_REQUEST_READ:
			SLAVE_STATUS = 0;

			vnl();
			vputs("rHST:");
			t1 = MASTER_COMMAND & 0x02; // side
			
			if (t1 == 0) {
				fdd_seek(&fddimage, 0x01 & MASTER_COMMAND, MASTER_TRACK, MASTER_SECTOR);

				vputh(fddimage.cur_side);
				vputh(fddimage.cur_sector);
				vputh(fddimage.cur_track);

				result = fdd_readsector(&fddimage);
				
				vputc(':');
				vputh(result);
				vdump(fddimage.buffer);
			} else {
				result = FR_INVALID_DRIVE;
				vputs("DRVERR");
			}
			
			SLAVE_STATUS = CPU_STATUS_COMPLETE | (result == FR_OK ? CPU_STATUS_SUCCESS : 0);
			// touche!

			break;
		case CPU_REQUEST_READADDR:
			// fill the beginning of buffer with position info
			// 6 bytes: track, side, sector, sectorsize code, crc1, crc2
			SLAVE_STATUS = 0;

			vnl();
			vputc('Q');
			t1 = MASTER_COMMAND & 0x02; // side
			
			if (t1 == 0) {
				fdd_seek(&fddimage, 0x01 & MASTER_COMMAND, MASTER_TRACK, MASTER_SECTOR);
				result = fdd_readadr(&fddimage);
				
				for (t1 = 0; t1 < 6; t1++) vputh(buffer[t1]);
			} else {
				result = FR_INVALID_DRIVE;
				vputs("DRVERR");
			}
			
			SLAVE_STATUS = CPU_STATUS_COMPLETE | (result == FR_OK ? CPU_STATUS_SUCCESS : 0);
			// touche!
			break;
		case CPU_REQUEST_WRITE:
			SLAVE_STATUS = 0;
			vputc('W');
			SLAVE_STATUS = CPU_STATUS_COMPLETE; // no success
			break;
		case CPU_REQUEST_ACK:
			SLAVE_STATUS = 0;
			blink();
			break;
		case CPU_REQUEST_NOP:
			SLAVE_STATUS = 0;
			vputc('`');
			vputh(MASTER_COMMAND);
			vputh(MASTER_SECTOR);
			SLAVE_STATUS = CPU_STATUS_COMPLETE;
			break;
		case CPU_REQUEST_FAIL:
			vputc('[');
			vputh(MASTER_COMMAND);
			vputh(MASTER_SECTOR);
			vputc(']');
			break;
		default:
			break;
		}
	}

	SLAVE_STATUS = 0;
	return result;
}

void blink(void) {
	static uint8_t leds = 0x01;
	static uint16_t delay = 1;

	menu_dispatch();
	
	//GREEN_LEDS = JOYSTICK;
	if (--delay == 0) {
		delay = DELAY_RELOAD;
		GREEN_LEDS = leds;
		leds <<= 1;
		if (leds == 0) leds = 0x01;
	}
}
