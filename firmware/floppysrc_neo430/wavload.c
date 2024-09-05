#include <stdint.h>

#include "wav.h"
#include "wavload.h"
#include "tff.h"
#include "specialio.h"
#include "serial.h"

#define ABBUF_SZ  512   // 2x 512, total of 1024 bytes

#define WAVBUF_SZ 256

// The playback buffers share the same memory as the floppy sector buffer.
// The buffers are interleaved: even addresses is buffer A, odd addresses is B

//#define BEEPTEST

uint8_t wavbuf[WAVBUF_SZ];

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
        //for (int i = 0; i < 512; ++i) {
        //    buffers[i + 512*ab] = (i & 8) ? 0 : 255;
        //}
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

    ser_puts("wav_load done; total samples: ");
    print_dec_u32(total);
    ser_nl();

    return FR_OK;
}
