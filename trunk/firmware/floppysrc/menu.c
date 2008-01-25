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
// Source file: menu.c
//
// Menu functions
//
// --------------------------------------------------------------------

#include "integer.h"
#include "specialio.h"
#include "osd.h"
#include "menu.h"

#include "serial.h"

#include <string.h>


static uint8_t fsel_index;		// currently selected item
static uint8_t	fsel_start;		// start refresh from here

static uint16_t delay = 1;
static uint8_t joy_status;

#define STATE_MENU 		0
#define STATE_FSEL	 	1
static uint8_t state;

static char* menu_item[] = {	NULL, 			TXT_MENU_UP, 		NULL,
								TXT_MENU_LEFT,	TXT_MENU_MIDDLE,	TXT_MENU_RIGHT,
								NULL,			TXT_MENU_DOWN,		NULL};
static uint8_t menu_x, menu_y, menu_selected;

uint8_t menu_dispatch() {
	menu_selected = 0xff;
	
	if (JOYSTICK != joy_status) {
		joy_status = JOYSTICK;
		
		if (joy_status & JOY_UP != 0) {
		}
		
		if (joy_status & JOY_DN != 0) {
		}
		
		if (joy_status & JOY_LT != 0) {
		}
		
		if (joy_status & JOY_RT != 0) {
		}
		
		if (joy_status & JOY_FIRE != 0) {
		}
		
		if (state == STATE_MENU) {
			if (joy_status & JOY_UP) menu_y = 0;
			else if (joy_status & JOY_DN) menu_y = 2;
			else menu_y = 1;
			
			if (joy_status & JOY_LT) menu_x = 0;
			else if (joy_status & JOY_RT) menu_x = 2;
			else menu_x = 1;
			
			if (joy_status & JOY_FIRE) {
				menu_selected = menu_x+menu_y*3;
				ser_puts("selected:"); print_hex(menu_selected); ser_nl();
			}
		}
		draw_menu();
	}
	
	return menu_selected;
}

void menu_init() {
	state = STATE_MENU;
	joy_status = 0xff;
	
	osd_cls(1);
	
	menu_x = 1;
	menu_y = 1;
}

void draw_menu() {
	int m_y, m_x, item = 0;
	for (m_y = 0; m_y < 3; m_y++) {
		for (m_x = 0; m_x < 3; m_x++) {
			osd_inv((m_y == menu_y) && (m_x == menu_x));
			draw_item(menu_item[item], 5 + m_x * 10, m_y+2, ALIGN_MIDDLE);
			item++;
		}
	}

	osd_inv(0);	osd_gotoxy(0,7); osd_puts(TXT_MENU_HALP);
}

void draw_item(char *s, uint8_t x, uint8_t y, uint8_t align) {
	int len;
	
	len = strlen(s);
	switch (align) {
	case ALIGN_MIDDLE:
		x -= len/2;
		break;
	case ALIGN_LEFT:
		break;
	case ALIGN_RIGHT:
		x -= len;
		break;
	}

	osd_gotoxy(x, y);
	osd_puts(s);
}