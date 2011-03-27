// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
//                  Copyright (C) 2007,2008 Viacheslav Slavinsky
//
// This code is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Vector-06C home computer
//
// Author: Viacheslav Slavinsky, http://sensi.org/~svo
// 
// Source file: philes.c
//
// FAT FS toplevel interface
//
// --------------------------------------------------------------------

#include "config.h"
#include "integer.h"
#include "philes.h"
#include "diskio.h"
#include "tff.h"
#include "serial.h"

#include <string.h>

static FATFS	fatfs;
static FILINFO 	finfo;
static DIR 		dir;

char *ptrfile = "/VECTOR06/xxxxxxxx.xxx\0\0\0";

BYTE endsWith(char *s1, const char *suffix) {
	int s1len = strlen(s1);
	int sulen = strlen(suffix);
	
	if (sulen > s1len) return 0;
	
	return strcmp(&s1[s1len - sulen], suffix) == 0;
}



FRESULT philes_mount()
{
#if VERBOSE >= 2
	FRESULT result = FR_NO_FILESYSTEM;
	DSTATUS dstatus = disk_initialize(0);
	if (dstatus) ser_putx("disk_initialize", dstatus);
	else
	{
		result = f_mount(0, &fatfs);
		if (result != FR_OK) ser_putx("f_mount",result);
	}
	return result;
#else	
	return disk_initialize(0) ? FR_NO_FILESYSTEM : f_mount(0, &fatfs);
#endif
}



FRESULT philes_opendir()
{
	FRESULT result;
	
	ptrfile[9] = 000; 
	result = f_opendir(&dir, ptrfile);					
	ptrfile[9] = '/'; 
	
	return result;
}



static void strxcpy(char *dst, char *src)
{
	uint8_t i = 12;
	while (*src != 0 && i--) *dst++ = *src++;
	while (i--) *dst++ = 0;
}



// fill in file name in buffer pointed by filename
										//bool here
FRESULT philes_nextfile(char *filename, uint8_t terminate)
{
	FRESULT	result = FR_OK;
	
	while ((f_readdir(&dir, &finfo) == FR_OK) && finfo.fname[0])
	{
		if (finfo.fattrib & AM_DIR) {}
		else
		{
			if (endsWith(finfo.fname, ".FDD"))
			{
				if (filename)
				{
					if (terminate) strxcpy(filename, finfo.fname); //strncpy(filename, finfo.fname, 12);
					else strxcpy(filename, finfo.fname);
				}
				return 0;
			}
		}
	}
	return FR_NO_FILE;
}