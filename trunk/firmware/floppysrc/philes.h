#ifndef _PHILES_H
#define _PHILES_H

#include "integer.h"
#include "tff.h"

FRESULT philes_mount();
FRESULT philes_opendir();
FRESULT philes_nextfile(char *filename, uint8_t terminate);

#endif