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
// Source file: specialio.h
//
// I/O port mapping for FDC interface
//
// --------------------------------------------------------------------


#ifndef _SPECIALIO_J
#define _SPECIALIO_J

#include <stdint.h>

#define 	IOPORT_BASE		0xFF00
#define		IOPORT_MMC_A		0x00			/* BIT0: SD_DAT3/CS */
#define		IOPORT_SPDR		0xA6
#define		IOPORT_SPSR		0xA4
#define 	IOPORT_JOY		0x02			/* Joystick */

#define		IOPORT_SERIAL_TxD	0x04
#define		IOPORT_SERIAL_RxD	0x05
#define		IOPORT_SERIAL_CTL	0x06

#define		IOPORT_TIMER_1		0x08			/* counts down by 1 every 10ms */
#define		IOPORT_TIMER_2		0x0A			/* counts down by 1 every 10ms */

#define		IOPORT_CPUREQ		12			/* our command */
#define		IOPORT_CPUSTAT		14			/* where we set our status */
#define 	IOPORT_CPUTRACK		16
#define		IOPORT_CPUSECTOR	18

//#define		IOPORT_DMAMSB		0x0E
//#define		IOPORT_DMALSB		0x0F

#define		IOPORT_GLEDS		20
#define 	IOPORT_OSDCMD		22			/* ROMHOLD,F11,F12,HOLD */

#define         IOPORT_ROM_PAGE         24                      /* upper 6 bits of addr for romload */
#define         IOPORT_ROM_ADDR         26                      /* romload write address, word-only */
#define         IOPORT_ROM_DATA         28                      /* romload data */

#define         OSDCMD_NONE             0
#define         OSDCMD_HOLD             (1<<0)                  // pause
#define         OSDCMD_RESTART          (1<<1)                  // BLK+SBR, F12
#define         OSDCMD_RESET            (1<<2)                  // BLK+VVOD, F11
#define         OSDCMD_ROMHOLD          (1<<3)                  // exclusive ram acceess for rom loader


#ifndef SIMULATION
#define		DISPLAY_BASE		0xE000
#else
extern uint8_t DISPLAY_BASE[];
#endif

#define		DISPLAY_W		32
#define		DISPLAY_H		8
#define		DISPLAY_RAMSIZE		256

#define		MMC_A		(*((volatile unsigned char *)(IOPORT_BASE+IOPORT_MMC_A)))
#define		SPDR		(*((volatile unsigned char *)(IOPORT_BASE+IOPORT_SPDR)))
#define		SPSR        	(*((volatile unsigned char *)(IOPORT_BASE+IOPORT_SPSR)))
#ifndef SIMULATION
#define		JOYSTICK	(*((volatile unsigned char *)(IOPORT_BASE+IOPORT_JOY)))
#else
extern uint8_t JOYSTICK;
#endif

#define		SERIAL_TxD	(*((volatile unsigned char *)(IOPORT_BASE+IOPORT_SERIAL_TxD)))
#define		SERIAL_RxD	(*((volatile unsigned char *)(IOPORT_BASE+IOPORT_SERIAL_RxD)))
#define		SERIAL_CTL	(*((volatile unsigned char *)(IOPORT_BASE+IOPORT_SERIAL_CTL)))

#define		TIMER_1		(*((volatile unsigned char *)(IOPORT_BASE+IOPORT_TIMER_1)))
#define		TIMER_2		(*((volatile unsigned char *)(IOPORT_BASE+IOPORT_TIMER_2)))

#define		MASTER_COMMAND	(*((volatile unsigned char *)(IOPORT_BASE+IOPORT_CPUREQ)))
#define		SLAVE_STATUS	(*((volatile unsigned char *)(IOPORT_BASE+IOPORT_CPUSTAT)))
#define  	MASTER_TRACK	(*((volatile unsigned char *)(IOPORT_BASE+IOPORT_CPUTRACK)))	
#define		MASTER_SECTOR	(*((volatile unsigned char *)(IOPORT_BASE+IOPORT_CPUSECTOR)))

#define  	DMAMSB		(*((unsigned char *)(IOPORT_BASE+IOPORT_DMAMSB)))
#define  	DMALSB		(*((unsigned char *)(IOPORT_BASE+IOPORT_DMALSB)))


#define		GREEN_LEDS	(*((volatile unsigned char *)(IOPORT_BASE+IOPORT_GLEDS)))
#ifndef SIMULATION
#define		OSD_CMD		(*((volatile unsigned char *)(IOPORT_BASE+IOPORT_OSDCMD)))
#else
extern uint8_t OSD_CMD;
#endif

#define		ROMLOAD_PAGE	(*((volatile unsigned char *)(IOPORT_BASE+IOPORT_ROM_PAGE)))
#define		ROMLOAD_ADDR	(*((volatile uint16_t*)      (IOPORT_BASE+IOPORT_ROM_ADDR)))
#define         ROMLOAD_DATA    (*((volatile uint8_t*)       (IOPORT_BASE+IOPORT_ROM_DATA)))

#define		SECTOR_BUFFER_SZ	1024
#define		SECTOR_BUFFER	((volatile BYTE *)0xd000)

#define SOCKWP		0x20			/* Write protect switch (PB5) */
#define SOCKINS		0x10			/* Card detect switch (PB4) */


#define		JOY_LT		0x10
#define		JOY_RT		0x08
#define 	JOY_UP		0x04
#define		JOY_DN		0x02
#define		JOY_FIRE	0x01

// MMC_A bits
#define 	MMC_DAT3		1

#define SELECT()	MMC_A &= ~MMC_DAT3
#define DESELECT()	MMC_A |= MMC_DAT3

#define SPIF	0x01

#endif
