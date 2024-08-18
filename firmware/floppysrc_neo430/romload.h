#pragma once

#include <stdint.h>
#include "tff.h"
#include "config.h"

uint8_t rom_load(FIL * file, uint8_t * bufptr, uint32_t addr);
