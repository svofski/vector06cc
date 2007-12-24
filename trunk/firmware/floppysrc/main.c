#include "serial.h"
#include "specialio.h"
#include "integer.h"

#include "tff.h"

#include "timer.h"

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
BYTE Buff[2048];			/* Working buffer */

void main(void) {
	uint8_t leds = 0x01;
	
	GREEN_LEDS = 0xC3;

	
	ser_puts("@");
	delay2(100);
	ser_puts("\n\r}O{\n\rhello.jpg\n\r");
	delay2(50);

	for(;;) {
		GREEN_LEDS = leds;
		delay1(10);
		leds <<= 1;
		if (leds == 0) leds = 0x01;
	}
	
}