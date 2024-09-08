#pragma once

#include "config.h"

#ifdef RSTRINGS_RODATA
typedef const char * const RSTRING;
#else
typedef const char * RSTRING;
#endif

extern RSTRING cnotice1; 
extern RSTRING cnotice2;
extern RSTRING dude[];

extern RSTRING aboot2;
extern RSTRING aboot4;
extern RSTRING aboot3;
extern RSTRING aboot5;
extern RSTRING aboot6;
