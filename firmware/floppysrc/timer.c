#include "integer.h"
#include "specialio.h"
#include "timer.h"

void delay1(uint8_t ms10) {
	for(TIMER_1 = ms10; TIMER_1 !=0;);
}

void delay2(uint8_t ms10) {
	for(TIMER_2 = ms10; TIMER_2 !=0;);
}
