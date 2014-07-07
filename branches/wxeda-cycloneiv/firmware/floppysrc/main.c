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
// Source file: main.c
//
// FDC workhorse main module.
//
// --------------------------------------------------------------------

#include <string.h>

#include "serial.h"
#include "specialio.h"
#include "integer.h"

#include "diskio.h"
#include "tff.h"

#include "timer.h"
#include "config.h"
#include "slave.h"

#include "osd.h"

#include "philes.h"

char* cnotice1 = "    VECTOR-06C FPGA REPLICA     ";
char* cnotice2 = "  (C)2008 VIACHESLAV SLAVINSKY  ";

/*---------------------------------------------------------*/
/* User Provided Timer Function for FatFs module           */
/*---------------------------------------------------------*/
/* This is a real time clock service to be called from     */
/* FatFs module. Any valid time must be returned even if   */
/* the system does not support a real time clock.          */
DWORD get_fattime (void)
{
	return 0;
}


BYTE* Buffer = (BYTE *)0x0200;

void print_result(DRESULT result) {
	switch (result) {
		case 0:
			break;
		default:
			ser_puts(" :( ");
			print_hex((BYTE)result);
			ser_nl();
			break;
	}
}

void fill_filename(char *buf, char *fname) {
	memset(buf, 0, 12);
	strncpy(buf, fname, 12);
}

#define CHECKRESULT {/*if (result) break;*/}

extern char* ptrfile;

void main(void) {
	BYTE res;
	//UINT bytesread;
	//FIL	file1;

	DRESULT result;
	FRESULT fresult;
	
	SLAVE_STATUS = 0;
	GREEN_LEDS = 0xC3;

	ser_puts("@");
	delay2(10);
	
	ser_nl(); ser_puts(cnotice1); 
	ser_nl(); ser_puts(cnotice2);

	thrall(ptrfile, Buffer);
//	for(;;) {
//		philes_mount();
//		fresult = philes_opendir();
//		
//		if (fresult == FR_OK) {
//			philes_nextfile(ptrfile+10, 1);
//		}
//		ser_puts("=> "); ser_puts(ptrfile); ser_nl();
//
//		useimage(ptrfile, Buffer);
//		ser_puts("RELOAD");
//		delay2(100);
//	}
	print_result(result);
	ser_puts("\r\nWTF?");
}
