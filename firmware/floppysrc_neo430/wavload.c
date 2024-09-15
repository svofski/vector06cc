#include <stdint.h>

#include "config.h"
#include "wav.h"
#include "cas.h"
#include "wavload.h"
#include "tff.h"
#include "specialio.h"
#include "serial.h"

// The playback buffers share the same memory as the floppy sector buffer.
// The buffers are interleaved: even addresses is buffer A, odd addresses is B

//#define BEEPTEST

// global, also used by cas.c
uint8_t wavbuf[WAVBUF_SZ];

// return weird samplerate bits for WAVCTL
static uint8_t samplerate_bv(uint16_t samplerate)
{
    switch (samplerate) {
        case 2400:  return 3 << 2;
        case 4800:  return 4 << 2;
        case 22050: return 1 << 2;
        case 44100: return 0 << 2;
        case 48000: return 2 << 2;
        default:    return 2 << 2;
            break;
    }
}

// fill one a/b buffer
size_t fill_buf(int ab, uint8_t *buffers)
{
    size_t pos = 0;
    size_t br;
    while (pos < ABBUF_SZ) {
        br = wav_read_bytes(wavbuf, WAVBUF_SZ);
        pos += wav_bytes_to_samples_i(wavbuf, br, &buffers[ab + pos * 2]);
        if (br < WAVBUF_SZ) 
            break;
    }

    for (unsigned i = pos; i < ABBUF_SZ; ++i) {
        buffers[ab + i * 2] = 0;
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
        buffers[i*2] = (i & 8) ? 0 : 255;         // A
        buffers[i*2 + 1] = (i & 16) ? 0 : 255;    // B
    }
#else
    total = fill_buf(ab, buffers);
#endif

    uint8_t ratediv;
    uint32_t samplerate = wav_samplerate();

    if (samplerate > 46000) 
        ratediv = samplerate_bv(48000);
    else if (samplerate > 32000)
        ratediv = samplerate_bv(44100);
    else
        ratediv = samplerate_bv(22050);

#if 0
    ser_puts("wav_load ratediv:"); print_hex(ratediv); ser_nl();
#endif
    WAVCTL = ratediv | 1;  // start playing (ab=0)
    for (;;) {
        ab = 1 ^ ab;

#ifdef BEEPTEST
        for (int i = 0; i < 512; ++i) {
            buffers[i*2 + ab] = (i & (8<<ab)) ? 0 : 255;
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

#if 0
    ser_puts("wav_load done; total samples: ");
    print_dec_u32(total);
    ser_nl();
#endif

    return FR_OK;
}


FRESULT cas_load(FIL *f, uint8_t *buffers)
{
    if (cas_read_init(f) != FR_OK) return -1;

    ser_puts("cas_load..");

    int ab = 0;
    WAVCTL = 0; // make sure playback is stopped
    
    uint16_t nsamps;
#ifdef BEEPTEST
    for (int i = 0; i < 512; ++i) {
        buffers[i*2] = (i & 8) ? 0 : 255;         // A
        buffers[i*2 + 1] = (i & 16) ? 0 : 255;    // B
    }
#else
    nsamps = cas_fill_buf(ab, buffers);
#endif
    //WAVCTL = (3 << 2) | 1;  // samplerate 2400 | ab = 0 | start playback
    // samplerate 2400/4800, ab=0, start playback
    WAVCTL = samplerate_bv(cas_samplerate()) | 1;

    for (;;) {
        ab = 1 ^ ab;

#ifdef BEEPTEST
        nsamps = ABBUF_SZ;
#else
        nsamps = cas_fill_buf(ab, buffers);
#endif
        while (((WAVCTL & 2) >> 1) != ab); // wait until buffer switchover
        if (nsamps < ABBUF_SZ) {
            break;
        }
    }
    while (((WAVCTL & 2) >> 1) == ab) {} // wait until done playing

    WAVCTL = 0; // stop

    ser_puts("done\n");

    return FR_OK;
}
