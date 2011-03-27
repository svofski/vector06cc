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

char* cnotice1 = " VECTOR-06C FPGA REPLICA v.3.67 ";
char* cnotice2 = "  (C)2008 VIACHESLAV SLAVINSKY  ";


/*---------------------------------------------------------*/
/* User Provided Timer Function for FatFs module           */
/*---------------------------------------------------------*/
/* This is a real time clock service to be called from     */
/* FatFs module. Any valid time must be returned even if   */
/* the system does not support a real time clock.          */
DWORD get_fattime (void) { return 0; }

BYTE* Buffer = (BYTE *)0x0200;

extern char* ptrfile;


FRESULT thrall(char*, uint8_t*);

void main(void)
{
	SLAVE_STATUS = 0;
	GREEN_LEDS = 0xC3;

	ser_puts("@");
	delay2(10);
	
	ser_nl(); ser_puts(cnotice1); 
	ser_nl(); ser_puts(cnotice2);

	thrall(ptrfile, Buffer);

	ser_puts("\r\nWTF?");
	for(;;);
}
