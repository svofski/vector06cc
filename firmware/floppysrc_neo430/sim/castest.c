#include <stdint.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>

#include "wav.h"
#include "cas.h"
#include "tff.h"
#include "config.h"
#include "console.h"

uint8_t wavbuf[WAVBUF_SZ];

uint8_t buffers[1024];

ssize_t total_bytes_written;

void writebuf(int ab, const uint8_t *buffers, int fd)
{
    uint8_t linbuf[512];

    for (int i = 0; i < 512; ++i) {
        linbuf[i] = buffers[ab + i * 2];
    }
    total_bytes_written += write(fd, linbuf, 512);
    //printf("written total: %ld\n", total_bytes_written);
}

int test(const char * caspath, const char * rawpath)
{
    total_bytes_written = 0;

    FIL casfil;
    FRESULT r = f_open(&casfil, caspath, FA_READ);
    if (r != FR_OK) {
        fprintf(stderr, "could not open %s\n", caspath);
        return 1;
    }

    int rawfil = open(rawpath, O_CREAT | O_WRONLY, 0644);

    if (cas_read_init(&casfil) != FR_OK) {
        fprintf(stderr, "could not initialise cas reader\n");
        return 1;
    }

    int ab = 0;
    uint16_t nsamps = cas_fill_buf(ab, buffers);

    for (;nsamps == ABBUF_SZ; ab ^= 1) {
        nsamps = cas_fill_buf(ab, buffers);
        writebuf(ab, buffers, rawfil);
    }

    close(rawfil);
}

int main()
{
    console_init();
    test("korvet.cas", "korvet.raw");
    return 0;
}
