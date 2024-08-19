#pragma once

#include <stdint.h>

#include "config.h"
#if NEW_FATFS
#include "ff.h"
#else
#include "tff.h"
#endif


uint8_t rom_load(FIL * file, uint8_t * bufptr, uint32_t addr);
