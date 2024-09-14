#include <stdint.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>


#include "wav.h"
#include "tff.h"

#define WAVBUF_SZ 128
uint8_t wavbuf[WAVBUF_SZ];

uint8_t sample[512];

int test(const char *path)
{
    FIL wafil;
    FRESULT r = f_open(&wafil, path, FA_READ);
    if (r != FR_OK) {
        fprintf(stderr, "could not open %s\n", path);
        return 1;
    }

    int raw = open("converted.raw", O_CREAT | O_WRONLY, 0644);
    
    if (wav_read_init(&wafil) != FR_OK) {
        fprintf(stderr, "could not initialise wav reader\n");
        return 1;
    }

    size_t total_bytes = 0, total_samples = 0;

    size_t br, nsamps;
    do {
        int pos = 0;
        memset(sample, 0, 512);
        while (pos < 512) {
            br = wav_read_bytes(wavbuf, WAVBUF_SZ);
            //printf("test: br=%d\n", br);
            total_bytes += br;

            // this is invalid now
            nsamps = wav_bytes_to_samples(wavbuf, br, &sample[pos]);
            pos += nsamps;

            if (br < WAVBUF_SZ) break;
        }

        printf("%04x ", 0);
        for (int i = 0; i < 512; ++i) {
            printf("%02x ", sample[i]);
            if ((i + 1) % 16 == 0) printf("\n%04x ", i + 16);
        }

        write(raw, sample, pos);

        total_samples += pos;
    } while(nsamps > 0);

    close(raw);

    printf("read %lu bytes, %lu samples\n", total_bytes, total_samples);
}

int main()
{
    //test("test8u.wav");
    //test("test16i.wav");
    //test("test16is.wav");
    //test("test8u22k.wav");
    //test("test8u44.wav");
    test("test16m.wav");

    return 0;
}

