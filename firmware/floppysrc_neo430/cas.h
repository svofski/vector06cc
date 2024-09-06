#pragma once
#include <stdint.h>
#include "tff.h"

typedef enum {
    CAS_UNKNOWN = -1,
    CAS_CSAVE = 0,  // CSAVE
    CAS_BSAVE = 1,  // BSAVE
    CAS_MSX = 2     // BASIC-Korvet
} caskind_t;

#define CAS_ERROR -3

FRESULT cas_read_init(FIL *f);
uint16_t cas_read_bytes(uint8_t *buf, uint16_t buf_sz);
uint16_t cas_fill_buf(int ab, uint8_t *buffers);
