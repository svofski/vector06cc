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
// Source file: slave.c
//
// Main request handler, runs eternally
//
// --------------------------------------------------------------------

#include "config.h"
#include "slave.h"
#include "specialio.h"

#if NEW_FATFS
#include "ff.h"
#else
#include "tff.h"
#endif

#include "fddimage.h"
#include "romload.h"
#include "integer.h"
#include "timer.h"
#include "menu.h"
#include "philes.h"
#include "diskio.h"
#include "wavload.h"

#include "serial.h"

const char * S_ERROR = "ERROR";
const char * S_ERRORnl = "ERROR\n";
const char * S_OK = "OK";
const char * S_OKnl = "OK\n";

FDDImage fddimage;
FIL     file1;

#define DELAY_RELOAD 128

uint8_t blink(void);
uint8_t loop_until_useraction(void);

uint8_t fdd_mounted;

void printerr(uint8_t code, uint8_t nl)
{
    ser_puts(S_ERROR); ser_putc(' '); print_hex(code);
    if (nl) ser_putc('\n');
}

uint8_t thrall(char *imagefile, volatile uint8_t *buffer)
{
    uint8_t result;
    uint8_t fs_mounted = 0;

    SLAVE_STATUS = CPU_STATUS_DRVNOTRDY;

    philes_init();
    menu_init();

    fdd_mounted = 0;

    for(;;) {
        SLAVE_STATUS = CPU_STATUS_DRVNOTRDY;
        do {
            if (!fs_mounted) {
                ser_puts("mount: ");
                result = philes_mount();
                if (result != FR_OK) {
                    printerr(result, 1);
                    break;
                }
                ser_puts(S_OKnl);

                fs_mounted = 1;

#if AUTO_FIRST_FILE
                ser_puts("opendir: ");
                result = philes_opendir();
                if (result != FR_OK) {
                    printerr(result, 1);
                    break;
                }
                ser_puts(S_OKnl);

                philes_nextfile(imagefile+10, 1);
#endif
            }

            loop_until_useraction();

            ser_nl();
            if ((result = f_open(&file1, imagefile, FA_READ)) != FR_OK) {
                ser_puts("Error: ");
                fs_mounted = 0;
            } else {
                ser_puts("=> ");
            }
            ser_puts(imagefile); ser_putc('$');ser_nl();

            if (result != FR_OK) break;

            int fk = philes_getkind(imagefile);

            switch (fk) {
            case FK_FDD:
                fdd_load(&file1, &fddimage, (uint8_t *)buffer);
                fdd_mounted = 1;
                break;
            case FK_ROM:
                fdd_mounted = 0; // avoid confict with fdd image
                rom_load(&file1, (uint8_t *)buffer, 0x100);
                f_close(&file1);
                break;
            case FK_R0M:
                fdd_mounted = 0; // avoid conflict with fdd image
                rom_load(&file1, (uint8_t *)buffer, 0x0);
                f_close(&file1);
                break;
            case FK_WAV:
                fdd_mounted = 0;
                wav_load(&file1, (uint8_t *)buffer);
                break;
            case FK_CAS:
                fdd_mounted = 0;
                cas_load(&file1, (uint8_t *)buffer);
                break;
            default:
                break;
            }

        } while(0);
        delay2(255);
        menu_busy(2);
        menu_dispatch(0);
        delay2(10);
    }
}

// loop until menu_dispatch() returns something else but MENURESULT_NOTHING
uint8_t loop_until_useraction(void) {
    uint8_t result;
    uint8_t t1;
    uint8_t cmd;

    SLAVE_STATUS = 0;       // clear drive not ready flag

    for (result = FR_OK; result == FR_OK;) { //result != FR_RW_ERROR;) {
        //SLAVE_STATUS = 0;
        result = FR_OK;
        if (disk_poll(0) == RES_NOTRDY) {
            vputs("NOSD");
            break;
        }

        if (!fdd_mounted) {
            //vputs("FDD not mounted");
            SLAVE_STATUS = CPU_STATUS_DRVNOTRDY;
            if ((result = blink()) != MENURESULT_NOTHING) {
                return result;   // break and return to the toplevel loop
            }
            continue;
        }

        cmd = MASTER_COMMAND;
        switch (cmd & 0xf0) {
            case CPU_REQUEST_READ:
                SLAVE_STATUS = CPU_STATUS_BUSY;
                menu_busy(1);
                vnl();
                vputs("rHST:");
                t1 = cmd & 0x02; // side

                if (t1 == 0) {
                    fdd_seek(&fddimage, 0x01 & cmd, MASTER_TRACK, MASTER_SECTOR);

                    vputh(fddimage.cur_side);
                    vputh(fddimage.cur_sector);
                    vputh(fddimage.cur_track);

                    result = fdd_readsector(&fddimage);

                    vputc(':');
                    vputh(result);
                    vdump(fddimage.buffer);
                } else {
                    result = FR_INVALID_DRIVE;
                    vputs("DRVERR");
                }

                SLAVE_STATUS = CPU_STATUS_COMPLETE 
                    | (result == FR_OK ? CPU_STATUS_SUCCESS : 0) 
                    | (result != FR_OK ? CPU_STATUS_CRC : 0);

                //delay2(10);

                break;
            case CPU_REQUEST_READADDR:
                // fill the beginning of buffer with position info
                // 6 bytes: track, side, sector, sectorsize code, crc1, crc2
                SLAVE_STATUS = CPU_STATUS_BUSY;

                menu_busy(1);
                vnl();
                vputc('Q');
                t1 = cmd & 0x02; // side

                if (t1 == 0) {
                    fdd_seek(&fddimage, 0x01 & cmd, MASTER_TRACK, MASTER_SECTOR);
                    result = fdd_readadr(&fddimage);

                    //for (t1 = 0; t1 < 6; t1++) vputh(buffer[t1]);
                } else {
                    result = FR_INVALID_DRIVE;
                    vputs("DRVERR");
                }

                SLAVE_STATUS = CPU_STATUS_COMPLETE | (result == FR_OK ? CPU_STATUS_SUCCESS : 0);
                // touche!
                break;
            case CPU_REQUEST_WRITE:
                SLAVE_STATUS = CPU_STATUS_BUSY;
                menu_busy(1);
                vnl();
                vputh(cmd);
                vputh(MASTER_TRACK);
                vputs("wHST:");
                t1 = cmd & 0x02;

                if (t1 == 0) {
                    fdd_seek(&fddimage, 0x01 & cmd, MASTER_TRACK, MASTER_SECTOR);

                    vputh(fddimage.cur_side);
                    vputh(fddimage.cur_sector);
                    vputh(fddimage.cur_track);
                    vputh(MASTER_TRACK);

                    result = fdd_writesector(&fddimage);

                    vputc(':');
                    vputh(result);
                    vdump(fddimage.buffer);
                } else {
                    result = FR_INVALID_DRIVE;
                    vputs("DRVERR");
                }

                SLAVE_STATUS = CPU_STATUS_COMPLETE
                    | (result == FR_OK ? CPU_STATUS_SUCCESS : 0)
                    | (result != FR_OK ? CPU_STATUS_CRC : 0);
                break;
            case CPU_REQUEST_ACK:
                SLAVE_STATUS = 0;
                vputc('+');
                break;
            case CPU_REQUEST_NOP:
                SLAVE_STATUS = CPU_STATUS_BUSY;
                vputc('`');
                vputh(cmd);
                vputh(MASTER_SECTOR);
                vputh(MASTER_TRACK);
                SLAVE_STATUS = CPU_STATUS_COMPLETE;
                break;
            case CPU_REQUEST_FAIL:
                SLAVE_STATUS = 0;
                vputs("Death by snoo-snoo:");
                vputh(cmd);
                vputs("CMD:");
                vputh(MASTER_SECTOR);
                vputs(" STATE:");
                vputh(MASTER_TRACK);
                vnl();
                vputs("X_x");
                for(;;);
                break;
            default:
                SLAVE_STATUS = 0;
                if ((result = blink()) != MENURESULT_NOTHING) {
                    return result;   // break and return to the toplevel loop
                }
                break;
        }               
    }

    SLAVE_STATUS = 0;
    return result;
}

uint8_t blink(void) {
    static uint8_t leds = 0x01;
    static uint8_t delay = 1;
    static uint8_t tick;

    tick = --delay == 0;

    menu_busy(0);

    //GREEN_LEDS = JOYSTICK;
    if (tick) {
        delay = DELAY_RELOAD;
        GREEN_LEDS = leds;
        leds <<= 1;
        if (leds == 0) leds = 0x01;
    }

    return menu_dispatch(tick);
}
