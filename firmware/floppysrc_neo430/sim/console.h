#pragma once

#define VT_HOME "\033[H"
#define VT_COLORSET "\033[37;46m\033[48;5;24m"
#define VT_COLORRESET "\033[0;0m"
#define VT_INVSET  "\033[7m"
#define VT_INVRESET "\033[27m"

#define CONSOLE_X 40
#define CONSOLE_Y 0

#define CONSOLE_COL "\033[93;40m\033[48;5;235m"
#define CONSOLE_NOCOL "\033[0;0m"



void console_init(void);
void console_print(void);
