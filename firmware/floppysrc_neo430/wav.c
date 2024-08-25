#include <stdint.h>
#include <string.h>
#include "wav.h"
#include "tff.h"

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
            if (seek_data() != FR_OK) return 0;
        }

        int toread = buf_sz - pos;
        if (chunk_sz < toread) {
            toread = chunk_sz;
        }
        if (f_read(wavfile, &buf[pos], toread, &br) != FR_OK || br != toread)
            return 0;
        pos += br;
        chunk_sz -= br;
    }

    return pos;
}

size_t merge_stereo_u8(const uint8_t *buf, size_t buf_sz, uint8_t *dst)
{
    if (wavheader.NumChannels == 2) {
        size_t i, j;
        for (i = 0, j = 0; j < buf_sz;) {
            int a = buf[j++];
            a += buf[j++];
            dst[i++] = a >> 1;
        }
        return i;
    }
    else {
        memcpy(dst, buf, buf_sz);
    }
    return buf_sz;
}

size_t merge_stereo_i16(const uint8_t *buf, size_t buf_sz, uint8_t *dst)
{
    int16_t * jbuf = (int16_t *) buf;
    size_t jbuf_sz = buf_sz >> 1;
    size_t i, j;

    if (wavheader.NumChannels == 2) {
        for (i = 0, j = 0; j < jbuf_sz;) {
            int a = jbuf[j++] / 2;
            a += jbuf[j++] / 2;
            dst[i++] = a / 256 + 128; 
        }
    }
    else {
        for (i = 0, j = 0; j < jbuf_sz;) {
            dst[i++] = jbuf[j++] / 256 + 128;
        }
    }
    return i;
}

size_t wav_bytes_to_samples(uint8_t *buf, size_t buf_sz, uint8_t *dst)
{
    switch (wavheader.BitsPerSample) {
        case 8:
            return merge_stereo_u8(buf, buf_sz, dst);
        case 16:
            return merge_stereo_i16(buf, buf_sz, dst);
        default:
            return 0;
    }
}
#include "serial.h"

uint32_t wav_samplerate()
{
    //int sr = (int)wavheader.SampleRate;
    //ser_puts("sr=");
    //print_hex(sr>>8);
    //print_hex(sr&255);
    //ser_nl();
    return wavheader.SampleRate;
}
