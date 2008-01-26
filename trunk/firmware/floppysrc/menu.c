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
#include "philes.h"
#include "serial.h"

#include <string.h>


extern uint8_t* dmem;
extern char* ptrfile;

static uint8_t fsel_index;		// currently selected item
static uint8_t	fsel_pagestart;	// start refresh from here
static uint8_t fsel_redraw;	// plz redraw file selector, teh slow
static uint8_t fsel_hasnextpage; 

static uint16_t delay = 1;
static uint8_t joy_status;

#define STATE_MENU 		0
#define STATE_FSEL	 	1
#define STATE_WAITBREAK	10
#define STATE_WAITBREAK2 11
#define STATE_ABOOT2 12
#define STATE_ABOOT		2

static uint8_t state;

static char* menu_item[] = {	NULL, 			TXT_MENU_UP, 		NULL,
								TXT_MENU_LEFT,	TXT_MENU_MIDDLE,	TXT_MENU_RIGHT,
								NULL,			TXT_MENU_DOWN,		NULL};
static uint8_t menu_x, menu_y, menu_selected;

static uint8_t osdcmd = 0;


#define INACTIVITY 8192

static uint16_t inactivity;

#define SEL_HOLD	1
#define SEL_RESET	3
#define SEL_DISK	4
#define SEL_RESTART 5
#define SEL_ABOUT	7


#define FSEL_PAGESIZE 12		// total of 12 items
#define FSEL_NLINES	6			// 6 lines

extern char* cnotice2;
extern char* dude[];
uint8_t dude_seqno;


static void switch_state(void);
static void draw_fsel(void);
static void fsel_showselection(uint8_t on);
static void fsel_getselected(char *file);
void aboot_anim();
void aboot_show();

uint8_t menu_busy(uint8_t yes) {
	osd_gotoxy(0, 7);
	osd_puts(yes ? TXT_MENU_BUSY : state == STATE_ABOOT2 ? TXT_MENU_ABOOTHALP : TXT_MENU_HALP);
}

uint8_t menu_dispatch(uint8_t tick) {
	uint8_t result = MENURESULT_NOTHING;
	
	if (tick && (state == STATE_ABOOT2)) {
		aboot_anim(); 
	}

	if (inactivity) inactivity--;
	if (!inactivity && state == STATE_FSEL) {
		menu_init();
	}
	
	if (JOYSTICK != joy_status) {
		joy_status = JOYSTICK;
		
		inactivity = INACTIVITY;
		
		switch (state) {
		case STATE_ABOOT:
			if (joy_status == 0) {
				state = STATE_ABOOT2;
			}
			break;
			
		case STATE_MENU:
			if (joy_status & JOY_UP) menu_y = 0;
			else if (joy_status & JOY_DN) menu_y = 2;
			else menu_y = 1;
			
			if (joy_status & JOY_LT) menu_x = 0;
			else if (joy_status & JOY_RT) menu_x = 2;
			else menu_x = 1;

			draw_menu();
			
			if (joy_status & JOY_FIRE) {
				state = STATE_WAITBREAK;
				menu_selected = menu_x+menu_y*3;
			}
			break;
			
		case STATE_WAITBREAK:
			if (!(joy_status & JOY_FIRE)) {
				switch_state();
			}
			break;
			
		case STATE_WAITBREAK2:
			if (!(joy_status & JOY_FIRE)) {
				fsel_getselected(ptrfile + 10);
				ser_puts("Selected image: "); ser_puts(ptrfile); ser_nl();
				menu_init();
				result = MENURESULT_DISK;
			}
			break;
			
		case STATE_ABOOT2:
			if (!(joy_status & JOY_FIRE)) {
				menu_init();
			}
			break;
			
		case STATE_FSEL:
			if (joy_status & JOY_UP) {
				if (menu_y > 0)	{
					menu_y -= 1;
				} else if (fsel_pagestart != 0) {
					fsel_pagestart -= FSEL_PAGESIZE-1;
					menu_y = FSEL_NLINES-1;
					fsel_redraw = 1;
				}
			} 
			
			if (joy_status & JOY_DN) {
				if (menu_y  < FSEL_NLINES-1) {
					menu_y += 1;
				} else if (fsel_hasnextpage) {
					menu_y = 0;
					fsel_pagestart += FSEL_PAGESIZE-1;
					fsel_redraw = 1;
				}
			}
			
			if (joy_status & JOY_LT) {
				menu_x = (menu_x - 1) % 2;
			}
			
			if (joy_status & JOY_RT) {
				menu_x = (menu_x + 1) % 2;
			}
			
			if (fsel_redraw) {
				fsel_redraw = 0;
				draw_fsel();
			}

			fsel_showselection(0);
			menu_selected = menu_y*2 + menu_x;
			fsel_showselection(1);
			
			if (joy_status & JOY_FIRE != 0) {
				state = STATE_WAITBREAK2;
			}
		
			break;
		}
	}
	
	return result;
}

void menu_init() {
	state = STATE_MENU;
	joy_status = 0377;
	
	osd_cls(1);
	
	menu_x = 1;
	menu_y = 1;
	menu_selected = 0377;
	osdcmd &= 1;	// clear reset bits, keep hold
	OSD_CMD = osdcmd;
}

void fsel_init() {
	fsel_pagestart = 0;
	fsel_redraw = 1;
	joy_status = 0xff;
	osd_cls(1);
	menu_x = 0;
	menu_y = 0;
	menu_selected = 0;
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
	
	osd_inv(0); draw_item(ptrfile, 16, 6, ALIGN_MIDDLE);

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

void switch_state(void) {
	if (state == STATE_WAITBREAK) {
		switch (menu_selected) {
		case SEL_HOLD:
			osdcmd ^= 1;	// toggle hold 
			OSD_CMD = osdcmd;
			state = STATE_MENU;
			break;
		case SEL_RESET:
			osdcmd |= 4;
			OSD_CMD = osdcmd;
			osdcmd &= ~4;
			OSD_CMD = osdcmd;
			state = STATE_MENU;
			break;
		case SEL_RESTART:
			osdcmd |= 2;
			OSD_CMD = osdcmd;
			osdcmd &= ~2;
			OSD_CMD = osdcmd;
			state = STATE_MENU;
			break;
		case SEL_ABOUT:
			state = STATE_ABOOT;
			aboot_show();
			break;
		case SEL_DISK:
			fsel_init();
			state = STATE_FSEL;
			break;
		default:
			state = STATE_MENU;
			break;
		}
	} 
}

uint8_t fsel_index2offs(uint8_t idx) {
	return 33 + (idx/2)*32 + (idx % 2)*16;
}

void draw_fsel(void) {
	uint8_t i;
	char *uptr;
	
	fsel_hasnextpage = 1;
	ser_puts("opendir");
	if (philes_opendir() == FR_OK) {
		ser_puts(" ok"); ser_nl();

		// skip until pagestart
		if (fsel_pagestart != 0) {
			for (i = 0; i < fsel_pagestart; i++) {
				if (philes_nextfile(0, 0) != FR_OK) {
					fsel_pagestart = 0;
					break;
				}
			}
		}
		
		// show files
		for (i = 0; i < FSEL_PAGESIZE; i++) {
			uptr = dmem + fsel_index2offs(i);
			memset(uptr, 32, 12);
			if (philes_nextfile(uptr, 0) != FR_OK) {
				fsel_hasnextpage = 0;
				// keep filling the screen though
			}
		}
	}
}

void fsel_showselection(uint8_t on) {
	char* uptr = dmem + fsel_index2offs(menu_selected);
	uint8_t i = 12;
	
	while (i--) uptr[i] = on ? uptr[i] | 0200 : uptr[i] & 0177;
}

void fsel_getselected(char *file) {
	char* uptr = dmem + fsel_index2offs(menu_selected);
	uint8_t u;
	uint8_t i = 12;
	while (i-- && ((u = 0177 & *uptr++) != 32)) {
		*file++ = u;
	}
	*file++ = '\000';
}


char* aboot2   = "";
char* aboot4   = "sensi.org/~svo/vector06c";
char* aboot3   = "vector06cc.googlecode.com";
char* aboot5   = "";
char* aboot6   = "Thank you for using VECTOR-06CC!";
//char* aboot6   = "--------------------------------";

char* dude[]   = {"\\o/",
		  " | ",
		  "/ \\",

		  "_o_",
		  " | ",
		  "/ \\",

		  "\\o_",
		  " |_",
		  "/  ",

		  "_o/",
		  "_| ",
		  "  \\"};

uint8_t waverseq[] = {0,0,1,1,0,0,1,1,2,3,2,3,2,3,2,3};



void aboot_show() {
	osd_cls(1);
	osd_gotoxy(0,1); osd_puts(cnotice2);
	osd_gotoxy(0,2); osd_puts(aboot2);
	osd_gotoxy(0,3); osd_puts(aboot3);
	osd_gotoxy(0,4); osd_puts(aboot4);
	osd_gotoxy(0,5); osd_puts(aboot5);
	osd_gotoxy(0,6); osd_puts(aboot6);
	dude_seqno = 0;
}

void aboot_anim() {
	uint8_t i;
	
	for (i = 0; i < 3; i++) {
		osd_gotoxy(28, i+3); osd_puts(dude[waverseq[dude_seqno]*3+i]);
	}
	dude_seqno = (dude_seqno + 1) % 16;
}