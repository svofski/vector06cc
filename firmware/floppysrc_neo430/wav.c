#include <stdint.h>
#include <string.h>
#include "wav.h"
#include "tff.h"
#include "serial.h"

#if SIMULATION
#include <stdio.h>
#endif

typedef uint8_t sample_t;

typedef struct _wavparams {
    uint16_t NumChannels;
    uint32_t SampleRate;
    uint32_t ByteRate;
    uint16_t BlockAlign;
    uint16_t BitsPerSample;
}  __attribute__((packed)) wavheader_t;

wavheader_t wavheader;

uint8_t tokenbuf[4];
uint32_t chunk_sz;

static FIL * wavfile;

#define WAV_ERROR -1

FRESULT parse_header()
{
    UINT br;
    if (f_read(wavfile, tokenbuf, 4, &br) != FR_OK || br != 4) return WAV_ERROR;
    if (0 != memcmp(tokenbuf, "RIFF", 4)) return WAV_ERROR;

    // ignore globsize
    if (f_read(wavfile, &tokenbuf, 4, &br) != FR_OK || br != 4) return WAV_ERROR;

    if (f_read(wavfile, tokenbuf, 4, &br) != FR_OK || br != 4) return WAV_ERROR;
    if (0 != memcmp(tokenbuf, "WAVE", 4)) return WAV_ERROR;

    if (f_read(wavfile, tokenbuf, 4, &br) != FR_OK || br != 4) return WAV_ERROR;
    if (0 != memcmp(tokenbuf, "fmt ", 4)) return WAV_ERROR;

    uint32_t subchunksize;
    if (f_read(wavfile, &subchunksize, 4, &br) != FR_OK || br != 4) return WAV_ERROR;
    size_t nextchunk = f_tell(wavfile) + subchunksize;

    uint16_t audioformat;
    if (f_read(wavfile, &audioformat, 2, &br) != FR_OK || br != 2) return WAV_ERROR;
    if (audioformat != 1) return WAV_ERROR;

    if (f_read(wavfile, &wavheader, sizeof(wavheader_t), &br) != FR_OK
            || br != sizeof(wavheader_t)) return WAV_ERROR;

#if SIMULATION
    printf("WAV file: Channels: %d Sample rate: %lu Byte rate: %lu "
            "Block align: %u Bits per sample: %u\n",
            wavheader.NumChannels, wavheader.SampleRate, wavheader.ByteRate, 
            wavheader.BlockAlign, wavheader.BitsPerSample);
#else
    //ser_puts("NumChannels: "); print_hex(wavheader.NumChannels);
    //ser_puts(" bits: "); print_hex(wavheader.BitsPerSample); 
    //ser_nl();
#endif

    return f_lseek(wavfile, nextchunk);
}

FRESULT seek_data()
{
    UINT br;
    while (1) {
        if (f_read(wavfile, tokenbuf, 4, &br) != FR_OK || br != 4) return WAV_ERROR;
        if (f_read(wavfile, &chunk_sz, 4, &br) != FR_OK || br != 4) return WAV_ERROR;
        if (0 == memcmp(tokenbuf, "data", 4)) {
            // found data chunk, set at correct pos, chunk_sz bytes available
#if SIMULATION
            printf("data chunk, sz=%lu\n", chunk_sz);
#endif
            return FR_OK;
        }
        if (f_lseek(wavfile, f_tell(wavfile) + chunk_sz) != FR_OK) return WAV_ERROR;
    }
}

FRESULT wav_read_init(FIL *f)
{
    wavfile = f;
    FRESULT r = parse_header();
    if (r != FR_OK) return r;

    return seek_data();
}

size_t wav_read_bytes(uint8_t *buf, size_t buf_sz)
{
    size_t pos = 0;
    UINT br;
    while (pos < buf_sz) {
        if (chunk_sz == 0) {
            if (seek_data() != FR_OK) return pos;
        }

        int toread = buf_sz - pos;
        if (chunk_sz < toread) {
            toread = chunk_sz;
        }
        //if (f_read(wavfile, &buf[pos], toread, &br) != FR_OK || br != toread)
        //    return 0;
        f_read(wavfile, &buf[pos], toread, &br);
        pos += br;
        chunk_sz -= br;

#if SIMULATION        
        printf("br=%d pos=%d chunk_sz=%d\n", br, pos, chunk_sz);
#endif

        if (br != toread) {
#if SIMULATION        
            printf("premature EOF\n");
#endif
            break;
        }
    }

    return pos;
}

uint16_t merge_stereo_u8i(const uint8_t *buf, uint16_t buf_sz, uint8_t *dst)
{
    if (wavheader.NumChannels == 2) {
        //// untested
        //unsigned i, j;
        //for (i = 0, j = 0; j < buf_sz;) {
        //    int a = buf[j++];
        //    a += buf[j++];
        //    dst[i] = a >> 1;
        //    i += 2;
        //}
        //return i;
        return 0;
    }
    else {
        // copy linear buf[j] to dst[i] stride 2
        // it's like memcpy(dst, buf, buf_sz) but dst increments by 2 for each buf byte
        for (unsigned i = 0, j = 0; j < buf_sz; i += 2, j += 1) {
            dst[i] = buf[j];
        }
        return buf_sz;
    }
    return 0;
}

uint16_t merge_stereo_i16i(const uint8_t *buf, uint16_t buf_sz_bytes, uint8_t *dst)
{
    int16_t * jbuf = (int16_t *) buf;
    uint16_t jbuf_sz = buf_sz_bytes >> 1;

    if (wavheader.NumChannels == 2) {
        //// untested
        //for (unsigned i = 0, j = 0; j < jbuf_sz;) {
        //    int a = jbuf[j++] / 2;
        //    a += jbuf[j++] / 2;
        //    dst[i] = a / 256 + 128; 
        //    i += 2;
        //}
        //return jbuf_sz >> 1;
        return 0;
    }
    else {
        for (unsigned i = 0, j = 0; j < jbuf_sz; i += 2, j += 1) {
            // somehow this works well
            int n = jbuf[j];
            if (n < 0) n = 0; else n = 255;
            dst[i] = n;
            // but not this...
            //dst[i] = jbuf[j] < 0 ? 0 : 255;
        }
        return jbuf_sz;
    }
    return 0;
}

// interleaved buffers, stride 2
uint16_t wav_bytes_to_samples_i(uint8_t *buf, uint16_t buf_sz, uint8_t *dst)
{
    switch (wavheader.BitsPerSample) {
        case 8:
            return merge_stereo_u8i(buf, buf_sz, dst);
        case 16:
            return merge_stereo_i16i(buf, buf_sz, dst);
        default:
            return 0;
    }
}

uint32_t wav_samplerate()
{
    return wavheader.SampleRate;
}
