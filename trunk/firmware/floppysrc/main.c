//#include <ctype.h>
#include <string.h>

#include "serial.h"
#include "specialio.h"
#include "integer.h"

#include "diskio.h"
#include "tff.h"

#include "timer.h"
#include "config.h"
#include "slave.h"

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
BYTE Buffer[SECTOR_SIZE];			/* Working buffer */


BYTE nybble_alpha(BYTE nybble) {
	return nybble + (nybble < 0x0a ? '0' : 'a'-0x0a);
}

void print_hex(BYTE b) {
	ser_putc(nybble_alpha((b & 0xf0) >> 4));
	ser_putc(nybble_alpha(b & 0x0f));
}

#if 0
void print_buff() {
  WORD ofs;
  
  for (ofs = 0; ofs < SECTOR_SIZE; ofs++) {
    if (ofs % 16 == 0) {
      ser_nl();
    } else if (ofs % 8 == 0) {
      ser_putc('-');
    } else ser_putc(' ');
    print_hex(Buffer[ofs]); 
  }
}
#endif

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

#define CHECKRESULT {if (result) break;}

void main(void) {
	FATFS *fs = &fatfs;
	BYTE res;
	DIR dir;
	char *ptrfile = "/VECTOR06/xxxxxxxx.xxx";
	UINT bytesread;
	FIL	file1;

	uint8_t leds = 0x01;
	DRESULT result;
	FRESULT fresult;
	
	GREEN_LEDS = 0xC3;

	ser_puts("@");
	delay2(100);
	ser_puts("\r\n-VECTOR06CC-\r\n");
	delay2(50);

	do {
		ser_putc('F');
		result = disk_initialize(0); CHECKRESULT;

#if 0
		ser_puts("disk_read(): ");
		result = disk_read (0, Buffer, 0, 1); 
		print_buff();
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
					ser_putc('['); ser_puts(finfo.fname); ser_putc(']');
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

#if 0
		print_buff();
#endif		
	} while (0);
	print_result(result);
	ser_puts("\r\nX_x\r\n");
}
