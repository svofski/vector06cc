#pragma once

#include "tff.h"
#include <stdint.h>
#include <stdlib.h>

FRESULT wav_read_init(FIL *f);
uint32_t wav_samplerate();
size_t wav_read_bytes(uint8_t *buf, size_t buf_sz);
//size_t wav_bytes_to_samples(uint8_t *buf, size_t buf_sz, uint8_t *dst);
uint16_t wav_bytes_to_samples_i(uint8_t *buf, uint16_t buf_sz, uint8_t *dst);
