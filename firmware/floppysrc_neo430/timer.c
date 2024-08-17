// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
//               Copyright (C) 2007-2024 Viacheslav Slavinsky
//
// This code is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Vector-06C home computer
//
// Author: Viacheslav Slavinsky, https://caglrc.cc
// 
// Source file: timer.c
//
// Delay functions
//
// --------------------------------------------------------------------

#include "integer.h"
#include "specialio.h"
#include "timer.h"

void delay1(uint8_t ms10) {
	for(TIMER_1 = ms10; TIMER_1 !=0;);
}

void delay2(uint8_t ms10) {
	for(TIMER_2 = ms10; TIMER_2 !=0;);
}
