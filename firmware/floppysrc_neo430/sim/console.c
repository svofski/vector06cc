#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>

#define CONSOLE_X 40
#define CONSOLE_Y 0

#define CONSOLE_COL "\033[93;40m\033[48;5;235m"
#define CONSOLE_NOCOL "\033[0;0m"


char * consolebuf[25];
size_t console_nlines = sizeof(consolebuf)/sizeof(consolebuf[0]);
int console_y = 0, console_x = 0;
const int console_width = 64;
int console_invalid;

void vt_gotoxy(int x, int y)
{
    printf("\033[%d;%dH", y + 1, x);
}

void console_init()
{
    for (int i = 0; i < console_nlines; ++i) {
        consolebuf[i] = (char *) malloc(console_width + 1);
        consolebuf[i][0] = 0;
    }
    console_invalid = 1;
}

void console_print()
{
    if (console_invalid) {
        for (int y = 0; y < console_nlines; ++y) {
            vt_gotoxy(CONSOLE_X, CONSOLE_Y + y);
            printf("%s%-64s%s", CONSOLE_COL, consolebuf[y], CONSOLE_NOCOL);
        }
        console_invalid = 0;
    }
}

void console_scroll()
{
    if (console_y == console_nlines) {
        char * line0 = consolebuf[0];
        line0[0] = 0;

        for (int i = 1; i < console_nlines; ++i) {
            consolebuf[i - 1] = consolebuf[i];
        }
        consolebuf[console_nlines - 1] = line0;
        console_invalid = 1;

        --console_y;
    }
}


// SERIAL
//

void ser_putc(char c) {
    if (c == '\r') 
        console_x = 0;
    else if (c == '\n') {
        console_x = 0;
        console_y += 1;
        console_scroll();
    }
    else {
        consolebuf[console_y][console_x] = c;
        consolebuf[console_y][++console_x] = 0;
        if (console_x == console_width) {
            console_x = 0;
            console_y += 1;
            console_scroll();
        }
    }
    console_invalid = 1;
}

void ser_puts(const char *s) {
    for(; *s != 0; s++) {
        ser_putc(*s);
    }
}

void ser_nl(void) {
    ser_putc('\n');
}
