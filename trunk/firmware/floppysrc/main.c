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


FATFS fatfs;
FILINFO finfo;

//BYTE Buffer[SECTOR_SIZE];			/* Working buffer */

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

BYTE endsWith(char *s1, const char *suffix) {
	int s1len = strlen(s1);
	int sulen = strlen(suffix);
	
	if (sulen > s1len) return 0;
	
	return stricmp(&s1[s1len - sulen], suffix) == 0;
}

void fill_filename(char *buf, char *fname) {
	memset(buf, 0, 12);
	strncpy(buf, fname, 12);
}

#define CHECKRESULT {/*if (result) break;*/}

char* cnotice1 = "    VECTOR-06C FPGA REPLICA     ";
char* cnotice2 = "  (C)2008 VIACHESLAV SLAVINSKY  ";
char *ptrfile = "/VECTOR06/xxxxxxxx.xxx";

void main(void) {
	FATFS *fs = &fatfs;
	BYTE res;
	DIR dir;
	UINT bytesread;
	FIL	file1;

	uint8_t leds = 0x01;
	DRESULT result;
	FRESULT fresult;
	
	SLAVE_STATUS = 0;
	GREEN_LEDS = 0xC3;

	ser_puts("@");
	delay2(10);
	ser_nl();
	ser_puts(cnotice1);
	ser_puts(cnotice2);

	osd_cls();
	osd_inv(1); osd_puts(cnotice1); osd_inv(0);
	osd_gotoxy(0,1); osd_puts(cnotice2);

	for(;;) {
		ser_putc('F');
		result = disk_initialize(0); CHECKRESULT;

#if 0
		ser_puts("disk_read(): ");
		result = disk_read (0, Buffer, 0, 1); 
		//print_buff();
		CHECKRESULT;
#endif

		ser_putc('T');
		fresult = f_mount(0, &fatfs); CHECKRESULT;
		
		ser_putc('W');
		ptrfile[9] = 000; 
		fresult = f_opendir(&dir, ptrfile);					
		ptrfile[9] = '/'; 
		CHECKRESULT;
		
		ser_nl();
		
		if (fresult == FR_OK) {
			while ((f_readdir(&dir, &finfo) == FR_OK) && finfo.fname[0]) {
				if (finfo.fattrib & AM_DIR) {
					// no need for this: ser_putc('['); ser_puts(finfo.fname); ser_putc(']');
				} else {
					if (endsWith(finfo.fname, ".fdd")) {
						ser_puts(" * ");
						ser_puts(finfo.fname);
						
						fill_filename(ptrfile+10, finfo.fname);
					}
				}
				ser_nl();
			}
		}
		ser_puts("=> "); ser_puts(ptrfile); ser_nl();

#if 0
		ser_puts("f_open "); ser_puts(ptrfile);
		fresult = f_open(&file1, ptrfile, FA_READ);					CHECKRESULT;


		ser_puts("f_lseek 0xA000");
		fresult = f_lseek(&file1, 0xA000);							CHECKRESULT;
			
		ser_puts("f_read 2048:");
		fresult = f_read(&file1, Buffer, 2048, &bytesread);			CHECKRESULT;
		
		ser_puts("f_close:");
		fresult = f_close(&file1);									CHECKRESULT;

#endif

		slave(ptrfile, Buffer);
		ser_puts("RELOAD");
		delay2(100);
#if 0
		print_buff();
#endif		
	}
	print_result(result);
	ser_puts("\r\nWTF?");
}
