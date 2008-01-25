// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
//                 Copyright (C) 2007,2008 Viacheslav Slavinsky
//
// This code is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Vector-06C home computer
//
// Author: Viacheslav Slavinsky, http://sensi.org/~svo
// 
// Source file: menu.h
//
// Menu functions
//
// --------------------------------------------------------------------

#include "integer.h"
#include "specialio.h"
#include "osd.h"

#define AUTOREPEAT 4096


#define TXT_MENU_MIDDLE	" DISK "
#define TXT_MENU_LEFT 	" RESET "
#define TXT_MENU_RIGHT	" RESTART "
#define TXT_MENU_UP		" HOLD "
#define TXT_MENU_DOWN	" ABOUT "

#define TXT_MENU_HALP	"  SELECT WITH ARROWS AND ENTER  "

#define ALIGN_RIGHT		0
#define ALIGN_MIDDLE 	1
#define ALIGN_LEFT 		2

#define FSEL_ITEMS_PER_PAGE		2*6	// two columns, 6 lines

uint8_t menu_dispatch();
void menu_init();
void draw_menu();
void draw_item(char *s, uint8_t x, uint8_t y, uint8_t align);
