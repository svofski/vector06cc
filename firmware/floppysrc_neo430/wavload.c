#include <stdint.h>

#include "wav.h"
#include "wavload.h"
#include "tff.h"
#include "specialio.h"
#include "serial.h"

#define ABBUF_SZ  512   // 2x 512, total of 1024 bytes

#define WAVBUF_SZ 128

uint8_t wavbuf[WAVBUF_SZ];

// fill one a/b buffer
size_t fill_buf(int ab, uint8_t *buffers)
{
    size_t pos = 0;
    size_t br;
    while (pos < ABBUF_SZ) {
        br = wav_read_bytes(wavbuf, WAVBUF_SZ);
        pos += wav_bytes_to_samples(wavbuf, br, &buffers[ab * 512 + pos]);
        if (br < WAVBUF_SZ) 
            break;
    }

    for (size_t i = pos; i < ABBUF_SZ; ++i) {
        buffers[ab * 512 + pos] = 0;
    }

    return pos;
}

FRESULT wav_load(FIL *f, uint8_t *buffers)
{
    if (wav_read_init(f) != FR_OK) return -1;

    int ab = 0;
    WAVCTL = 0; // make sure playback is stopped

    uint32_t total = 0;

#ifdef BEEPTEST
    for (int i = 0; i < 512; ++i) {
        buffers[i] = (i & 8) ? 0 : 255;
        buffers[i + 512] = (i & 8) ? 0 : 255;
    }
#else
    total = fill_buf(ab, buffers);
#endif

    uint8_t ratediv;
    uint32_t samplerate = wav_samplerate();
    if (samplerate > 46000) 
        ratediv = 2 << 2;
    else if (samplerate > 32000)
        ratediv = 0;
    else
        ratediv = 1 << 2;

    ser_puts("wav_load ratediv:"); print_hex(ratediv); ser_nl();
    WAVCTL = ratediv | 1;  // start playing (ab=0)
    for (;;) {
        ab = 1 ^ ab;

#ifdef BEEPTEST
        for (int i = 0; i < 512; ++i) {
            buffers[i + 512*ab] = (i & 8) ? 0 : 255;
        }
        size_t nsamps = ABBUF_SZ;
#else
        size_t nsamps = fill_buf(ab, buffers);
        total += nsamps;
#endif
        while (((WAVCTL & 2) >> 1) != ab); // wait until it starts playing
        if (nsamps < ABBUF_SZ) {
            break;
        }
    }
    while (((WAVCTL & 2) >> 1) == ab); // wait until it's done playing
    WAVCTL = 0; // stop

    ser_puts("wav_load done; total samples: ");
    print_dec_u32(total);
    ser_nl();

    return FR_OK;
}
