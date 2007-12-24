#include "serial.h"
#include "specialio.h"
#include "integer.h"

#include "tff.h"

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

void delay(uint8_t approx) {
	uint8_t i,q;
	for(i = approx; --i > 0;) {
		for(q = 255; --q > 0;);
	}
}

void delayt(uint8_t ms10) {
	for(TIMER_1 = ms10; TIMER_1 !=0;);
}

FATFS fatfs;
FILINFO finfo;
BYTE Buff[2048];			/* Working buffer */

void main(void) {
	uint8_t leds = 0x01;
	
	GREEN_LEDS = 0xC3;

	
	ser_puts("@");
	delay(10);
	ser_puts("\n\r}O{\n\rhello.jpg\n\r");
	delay(50);

	/*
	for(;;) {
	GREEN_LEDS = 0xff;
	delay(100);
	GREEN_LEDS = 0;
	delay(100);
	}
	*/

	
	for(;;) {
		GREEN_LEDS = leds;
		delayt(50);
		leds <<= 1;
		if (leds == 0) leds = 0x01;
	}
	
}