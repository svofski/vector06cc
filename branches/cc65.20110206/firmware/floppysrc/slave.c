// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
//               Copyright (C) 2007, 2008 Viacheslav Slavinsky
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
#include "philes.h"
#include "diskio.h"

#include "serial.h"

#if VERBOSE >= 3
	#define vdump(b)  print_buff(b)
#else
	#define vdump(s) {}

	#if VERBOSE >= 2
		#define vputs(s) ser_puts(s)
		#define vputc(c) ser_putc(c)
		#define vputh(x) print_hex(x)
		#define vnl()	 ser_nl()
	#else
		#define vputs(s) {}
		#define vputc(s) {}
		#define vputh(s) {}
		#define vnl()	 {}
	#endif
#endif

static FDDImage fddimage;
static FIL	file1;

const char* FResultAsText(FRESULT _result)
{
	const char* text[] =
	{ "OK"
	, "NOT_READY"
	, "NO_FILE"
	, "NO_PATH"
	, "INVALID_NAME"
	, "INVALID_DRIVE"
	, "DENIED"
	, "EXIST"
	, "RW_ERROR"
	, "WRITE_PROTECTED"
	, "NOT_ENABLED"
	, "NO_FILESYSTEM"
	, "INVALID_OBJECT"
	};
	if (_result < sizeof(text)/sizeof(text[0])) return text[_result];
	else return "FR_RANGE";
}


static BOOL VerifyResult( const FRESULT	_verified
						, const char*	_function
						, FRESULT*		_result
						)
{
	*_result = _verified;
	ser_puts(_function);
	ser_puts(":");
	ser_puts(FResultAsText(_verified));
	ser_nl();
	return (_verified == FR_OK) ? TRUE : FALSE;
}



#define DELAY_RELOAD 128

static uint8_t blink()
{
	static uint8_t leds = 0x01;
	static uint8_t delay = 1;
	static uint8_t tick;
	
	tick = --delay == 0;

	menu_busy(0);
	
	//GREEN_LEDS = JOYSTICK;
	if (tick)
	{
		delay = DELAY_RELOAD;
		GREEN_LEDS = leds;
		leds <<= 1;
		if (leds == 0) leds = 0x01;
	}
	
	return menu_dispatch(tick);
}



static FRESULT slave()
{
	FRESULT	result;
	uint8_t	t1;
	uint8_t cmd;

	SLAVE_STATUS = 0;	// clear drive not ready flag

	for (;result != FR_RW_ERROR;) //hmm... should be == FR_OK
	{
		//SLAVE_STATUS = 0;
		result = FR_OK;
		
		while (disk_poll() == RES_NOTRDY)
		{
			vputs("NOSD");
			break;
		}
		
		cmd = MASTER_COMMAND; //IOPORT_CPUREQ (specialio.h)
		switch (cmd & 0xf0)
		{
		case CPU_REQUEST_READ: //slave.h
			SLAVE_STATUS = CPU_STATUS_BUSY;
			menu_busy(1);
			vnl();
			vputs("rHST:");
			t1 = cmd & 0x02; // side
			
			if (t1 == 0)
			{
				fdd_seek(&fddimage, 0x01 & cmd, MASTER_TRACK, MASTER_SECTOR);

				vputh(fddimage.cur_side);
				vputh(fddimage.cur_sector);
				vputh(fddimage.cur_track);

				result = fdd_readsector(&fddimage);
				
				vputc(':');
				vputh(result);
				vdump(fddimage.buffer);
			}
			else
			{
				result = FR_INVALID_DRIVE;
				vputs("DRVERR");
			}
			
			SLAVE_STATUS= CPU_STATUS_COMPLETE
						| (result == FR_OK ? CPU_STATUS_SUCCESS : 0)
						| (result == FR_RW_ERROR ? CPU_STATUS_CRC : 0);
			break;
		case CPU_REQUEST_READADDR:
			// fill the beginning of buffer with position info
			// 6 bytes: track, side, sector, sectorsize code, crc1, crc2
			SLAVE_STATUS = CPU_STATUS_BUSY;

			menu_busy(1);
			vnl();
			vputc('Q');
			t1 = cmd & 0x02; // side
			
			if (t1 == 0) {
				fdd_seek(&fddimage, 0x01 & cmd, MASTER_TRACK, MASTER_SECTOR);
				result = fdd_readadr(&fddimage);
				
				//for (t1 = 0; t1 < 6; t1++) vputh(buffer[t1]);
			}
			else
			{
				result = FR_INVALID_DRIVE;
				vputs("DRVERR");
			}
			
			SLAVE_STATUS = CPU_STATUS_COMPLETE | (result == FR_OK ? CPU_STATUS_SUCCESS : 0);
			// touche!
			break;
		case CPU_REQUEST_WRITE:
			SLAVE_STATUS = CPU_STATUS_BUSY;
			menu_busy(1);
			vnl();
			vputh(cmd);
			vputh(MASTER_TRACK);
			vputs("wHST:");
			
			if (t1 == 0) {
				fdd_seek(&fddimage, 0x01 & cmd, MASTER_TRACK, MASTER_SECTOR);

				vputh(fddimage.cur_side);
				vputh(fddimage.cur_sector);
				vputh(fddimage.cur_track);
				vputh(MASTER_TRACK);

				result = fdd_writesector(&fddimage);
				
				vputc(':');
				vputh(result);
				vdump(fddimage.buffer);
			} else {
				result = FR_INVALID_DRIVE;
				vputs("DRVERR");
			}
			
			SLAVE_STATUS = CPU_STATUS_COMPLETE | (result == FR_OK ? CPU_STATUS_SUCCESS : 0) | (result == FR_RW_ERROR ? CPU_STATUS_CRC : 0);
			break;
		case CPU_REQUEST_ACK:
			SLAVE_STATUS = 0;
			vputc('+');
			break;
		case CPU_REQUEST_NOP:
			SLAVE_STATUS = CPU_STATUS_BUSY;
			vputc('`');
			vputh(cmd);
			vputh(MASTER_SECTOR);
			vputh(MASTER_TRACK);
			SLAVE_STATUS = CPU_STATUS_COMPLETE;
			break;
		case CPU_REQUEST_FAIL:
			SLAVE_STATUS = 0;
			vputs("Death by snoo-snoo:");
			vputh(cmd);
			vputs("CMD:");
			vputh(MASTER_SECTOR);
			vputs(" STATE:");
			vputh(MASTER_TRACK);
			vnl();
			vputs("X_x");
			for(;;);
			break;
		default:
			SLAVE_STATUS = 0;
			if ((result = blink()) != MENURESULT_NOTHING)
			{
				return result;
			}
			break;
		}		
	}

	SLAVE_STATUS = 0;
	return result;
}



FRESULT thrall(char *_ptrfile, uint8_t *_buffer)
{
	FRESULT result = FR_OK;
	int once = 0;
	
	SLAVE_STATUS = CPU_STATUS_DRVNOTRDY;
	menu_init();
	
	if (VerifyResult(philes_mount(), "philes_mount", &result))
	{
		if (VerifyResult(philes_opendir(), "philes_opendir", &result))
		if (!once++ && VerifyResult(philes_nextfile(_ptrfile+10, 1), "philes_nextfile", &result))
		while (VerifyResult(f_open(&file1, _ptrfile, FA_READ), "f_open", &result))
		{
			ser_puts("=> "); ser_puts(_ptrfile); ser_putc('$');ser_nl();
			fdd_load(&file1, &fddimage, _buffer);
			slave();
			//f_close(&file1);
		}
		menu_busy(2); menu_dispatch(0);	delay2(100);
	}
	return result;
}
