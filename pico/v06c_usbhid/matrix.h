#pragma once

#include <stdint.h>

typedef struct _km {
    uint8_t modkeys;      // v06c modkeys
    uint8_t rows[8];
} matrix_t;

void matrix_init();
void matrix_setkeys(uint8_t hid_mods, const uint8_t * scancodes);
matrix_t * matrix_getdata();
