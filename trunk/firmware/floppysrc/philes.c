#include "integer.h"
#include "philes.h"
#include "diskio.h"
#include "tff.h"

#include <string.h>

FATFS 		fatfs;
FILINFO 	finfo;
DIR 		dir;

char *ptrfile = "/VECTOR06/xxxxxxxx.xxx\0\0\0";

BYTE endsWith(char *s1, const char *suffix) {
	int s1len = strlen(s1);
	int sulen = strlen(suffix);
	
	if (sulen > s1len) return 0;
	
	return strcmp(&s1[s1len - sulen], suffix) == 0;
}

FRESULT philes_mount() {
	FRESULT result = FR_NO_FILESYSTEM;
	
	disk_initialize(0); 
	return f_mount(0, &fatfs);
}

FRESULT philes_opendir() {
	FRESULT result;
	
	ptrfile[9] = 000; 
	result = f_opendir(&dir, ptrfile);					
	ptrfile[9] = '/'; 
	
	return result;
}

static void strxcpy(char *dst, char *src) {
	uint8_t i = 12;
	while (*src != 0 && i--) *dst++ = *src++;
}

// fill in file name in buffer pointed by filename
FRESULT philes_nextfile(char *filename, uint8_t terminate) {
	while ((f_readdir(&dir, &finfo) == FR_OK) && finfo.fname[0]) {
		if (finfo.fattrib & AM_DIR) {
			// nowai
		} else {
			if (endsWith(finfo.fname, ".FDD")) {
				if (filename != 0) {
					if (terminate) {
						strncpy(filename, finfo.fname, 12);
					} else {
						strxcpy(filename, finfo.fname);
					}
				}
				return 0;
			}
		}
	}
	
	return FR_NO_FILE;
}