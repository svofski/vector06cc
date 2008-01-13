// ====================================================================
//                         VECTOR-06C FPGA REPLICA
//
// 					Copyright (C) 2007, Viacheslav Slavinsky
//
// This code is distributed under modified BSD license. 
// For complete licensing information see LICENSE.TXT.
// -------------------------------------------------------------------- 
//
// An open implementation of Vector-06C home computer
//
// Author: Viacheslav Slavinsky, http://sensi.org/~svo
// 
// Source file: specialio.h
//
// I/O port mapping for FDC interface
//
// --------------------------------------------------------------------


#ifndef _SPECIALIO_J
#define _SPECIALIO_J

#define 	IOPORT_BASE			0xE000
#define		IOPORT_MMC_A		0x00			/* BIT0: SD_DAT3/CS */
#define		IOPORT_SPDR			0x01
#define		IOPORT_SPSR			0x02
#define 	IOPORT_SOCKPORT		0x03			/* Socket contact port */

#define		IOPORT_SERIAL_TxD	0x04
#define		IOPORT_SERIAL_RxD	0x05
#define		IOPORT_SERIAL_CTL	0x06

#define		IOPORT_TIMER_1		0x07			/* counts down by 1 every 10ms */
#define		IOPORT_TIMER_2		0x08			/* counts down by 1 every 10ms */

#define		IOPORT_CPUREQ		0x09			/* our command */
#define		IOPORT_CPUSTAT		0x0A			/* where we set our status */
#define 	IOPORT_CPUTRACK		0x0B
#define		IOPORT_CPUSECTOR	0x0C

#define		IOPORT_GLEDS		0x10

#define		MMC_A		(*((unsigned char *)(IOPORT_BASE+IOPORT_MMC_A)))
#define		SPDR		(*((unsigned char *)(IOPORT_BASE+IOPORT_SPDR)))
#define		SPSR        (*((unsigned char *)(IOPORT_BASE+IOPORT_SPSR)))
#define		SOCKPORT	(*((unsigned char *)(IOPORT_BASE+IOPORT_SOCKPORT)))

#define		SERIAL_TxD	(*((unsigned char *)(IOPORT_BASE+IOPORT_SERIAL_TxD)))
#define		SERIAL_RxD	(*((unsigned char *)(IOPORT_BASE+IOPORT_SERIAL_RxD)))
#define		SERIAL_CTL	(*((unsigned char *)(IOPORT_BASE+IOPORT_SERIAL_CTL)))

#define		TIMER_1		(*((unsigned char *)(IOPORT_BASE+IOPORT_TIMER_1)))
#define		TIMER_2		(*((unsigned char *)(IOPORT_BASE+IOPORT_TIMER_2)))

#define		MASTER_COMMAND	(*((unsigned char *)(IOPORT_BASE+IOPORT_CPUREQ)))
#define		SLAVE_STATUS	(*((unsigned char *)(IOPORT_BASE+IOPORT_CPUSTAT)))
#define  	MASTER_TRACK	(*((unsigned char *)(IOPORT_BASE+IOPORT_CPUTRACK)))	
#define		MASTER_SECTOR	(*((unsigned char *)(IOPORT_BASE+IOPORT_CPUSECTOR)))

#define		GREEN_LEDS	(*((unsigned char *)(IOPORT_BASE+IOPORT_GLEDS)))


#define SOCKWP		0x20			/* Write protect switch (PB5) */
#define SOCKINS		0x10			/* Card detect switch (PB4) */


// MMC_A bits
#define 	MMC_DAT3		1

#define SELECT()	MMC_A &= ~MMC_DAT3
#define DESELECT()	MMC_A |= MMC_DAT3

#define SPIF	0x01

#endif