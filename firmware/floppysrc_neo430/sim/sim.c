#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>

#include "integer.h"
#include "specialio.h"
#include "osd.h"
#include "menu.h"
#include "philes.h"
#include "serial.h"
#include "tff.h"
#include "diskio.h"

#include "console.h"

// stub memory substitutes
uint8_t DISPLAY_BASE[DISPLAY_RAMSIZE];
uint8_t OSD_CMD;
uint8_t JOYSTICK;

void osd_print(void);
void console_print(void);

int kbhit()
{
    struct timeval tv = { 0L, 0L };
    fd_set fds;
    FD_ZERO(&fds);
    FD_SET(0, &fds);
    return select(1, &fds, NULL, NULL, &tv) > 0;
}

int main()
{
    console_init();

    philes_init();
    menu_init();
    philes_mount();

    JOYSTICK = 0;

    uint8_t delay = 1;
    uint8_t tick = 0;

    int keypress = 0;

    while (1) {
        if (kbhit()) {
            int c = getchar();
            switch (c) {
                case 'w':  keypress=100; JOYSTICK |= JOY_UP; break;
                case 'a':  keypress=100; JOYSTICK |= JOY_LT; break;
                case 's':  keypress=100; JOYSTICK |= JOY_DN; break;
                case 'd':  keypress=100; JOYSTICK |= JOY_RT; break;
                case '\n':
                case ' ':  keypress=100; JOYSTICK |= JOY_FIRE; break;
                case '.':  keypress=0; JOYSTICK = 0; break;
                default: break;
            }
        }

        if (keypress) {
            if (--keypress == 0) {
                JOYSTICK = 0;
            }
        }

        osd_print();
        console_print();

        menu_busy(0);

        tick = --delay == 0;
        menu_dispatch(tick);
        usleep(1000);

        extern int8_t menu_x, menu_y, menu_selected, current_page;
        printf("%3d menu_x=%d menu_y=%d menu_selected=%d current_page=%d\r",
                delay, menu_x, menu_y, menu_selected, current_page);
    }

    return 0;
}


//
// OSD STUB
//

void osd_print()
{
    extern uint8_t * dmem;

    puts(VT_COLORRESET);
    printf("%s", VT_HOME);
    int inv = 0;


    for (int y = 0; y < 8; ++y) {
        printf("%s", VT_COLORSET);
        for (int x = 0; x < 32; ++x) {
            int c = dmem[y * 32 + x];
            int newinv = c & 0200;
            if (newinv != inv) {
                inv = newinv;
                printf("%s", inv ? VT_INVSET : VT_INVRESET);
            }
            c = c & 0177;
            if (c < 32 || c > 127) c = ' ';
            putchar(c);
        }
        if (inv) printf("%s", VT_INVRESET);
        inv = 0;
        printf("%s", VT_COLORRESET);
        printf("\n");
    }
}


void delay2(uint8_t ms10)
{
    usleep(ms10*10000);
}

// DISK
//
DSTATUS disk_initialize (BYTE drv)
{
    return FR_OK;
}

FRESULT f_mount(BYTE drv, FATFS *fs)
{
    return FR_OK;
}

FRESULT f_opendir(DIR *dirobj, const char *path)
{
    dirobj->index = 0;
    return FR_OK;
}

FRESULT f_readdir(DIR *dirobj, FILINFO *finfo)
{
    extern const char * files[];
    extern size_t n_files;

    if (dirobj->index < n_files) {
        strncpy(finfo->fname, files[dirobj->index], 8+1+3); 
        finfo->fsize = 1234;
        ++dirobj->index;
        return FR_OK;
    }
    finfo->fsize = 0;
    finfo->fname[0] = 0;
    return FR_NO_FILE;
}
