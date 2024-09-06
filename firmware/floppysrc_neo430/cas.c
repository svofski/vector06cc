#include <stdint.h>
#include <string.h>

#include "config.h"
#include "cas.h"
#include "tff.h"
#include "serial.h"

#define v06c_preamble_size 256

const uint8_t V06C_BAS[] = { 0xD3, 0xD3, 0xD3, 0xD3 }; // CSAVE
const uint8_t V06C_BIN[] = { 0xD2, 0xD2, 0xD2, 0xD2 }; // BSAVE/Monitor

/* MSX headers definitions */
//const uint8_t MSX_HEADER[] = { 0x1F,0xA6,0xDE,0xBA,0xCC,0x13,0x7D,0x74 };
#if 0
const uint8_t MSX_ASCII[] =  { 0xEA,0xEA,0xEA,0xEA,0xEA,0xEA,0xEA,0xEA,0xEA,0xEA };
const uint8_t MSX_BIN[] =    { 0xD0,0xD0,0xD0,0xD0,0xD0,0xD0,0xD0,0xD0,0xD0,0xD0 };
const uint8_t MSX_BASIC[] =  { 0xD3,0xD3,0xD3,0xD3,0xD3,0xD3,0xD3,0xD3,0xD3,0xD3 };
#endif

#define long_pulse ((CAS_LOAD_SAMPLERATE) / 1200)
#define short_pulse ((CAS_LOAD_SAMPLERATE) / 2400)

#define short_silence (CAS_LOAD_SAMPLERATE)
#define long_silence  (CAS_LOAD_SAMPLERATE * 2)

#define long_header 16000
#define short_header 4000

static FIL * casfile;
static caskind_t caskind;

extern uint8_t wavbuf[WAVBUF_SZ];

static int32_t caspos;

static uint16_t cas_srcpos, cas_avail;

caskind_t cas_guess_kind(const uint8_t * data)
{
    if (memcmp(data, V06C_BAS, sizeof(V06C_BAS))) return CAS_CSAVE;
    if (memcmp(data, V06C_BIN, sizeof(V06C_BIN))) return CAS_BSAVE;
    //if (memcmp(data, MSX_HEADER, sizeof(MSX_HEADER))) return CAS_MSX;

    return CAS_UNKNOWN;
}

FRESULT cas_read_init(FIL *f)
{
    casfile = f;
    caspos = 0;

    UINT br;
    f_read(casfile, wavbuf, WAVBUF_SZ, &br);
    if (br < 10) return CAS_ERROR;
    caskind = cas_guess_kind(wavbuf);

    ser_puts("cas: "); print_hex(caskind);

    if (caskind == CAS_CSAVE || caskind == CAS_BSAVE) {
        caspos = -v06c_preamble_size; // virtual preamble 
        f_lseek(casfile, 0);          // reset to starting position
        cas_avail = 0;
        cas_srcpos = 0;
    }

    return caskind != CAS_UNKNOWN ? FR_OK : CAS_ERROR;
}

// read cas bytes (v06c csave/bsave)
uint16_t cas_read_bytes(uint8_t *buf, uint16_t buf_sz)
{
    uint16_t pos = 0;

    while (caspos < -1 && pos < buf_sz) {
        buf[pos] = 0x00;
        ++pos;
        ++caspos;
    }

    if (caspos == -1 && pos < buf_sz) {
        buf[pos] = 0xe6;
        ++pos;
        ++caspos;
    }

    UINT br;
    UINT toread = buf_sz - pos;
    f_read(casfile, &buf[pos], toread, &br);
    return pos + br;
}

// fill one a/b buffer encoding cas
uint16_t cas_fill_buf(int ab, uint8_t *buffers)
{
    uint16_t dstpos = 0;
    uint16_t br;

    uint8_t *bp = buffers + ab;  // write pointer (stride 2)

    while (dstpos < ABBUF_SZ) {
        // top up cas bytes (source)
        if (cas_avail == 0) {
            br = cas_read_bytes(wavbuf, WAVBUF_SZ);
            cas_avail = br;
            cas_srcpos = 0;
            if (cas_avail == 0)   // eof
                break;
        }

        // encode PSK byte
        uint8_t octet = wavbuf[cas_srcpos];
        for (uint8_t b = 0; b < 8; ++b, octet <<= 1) {
            uint8_t phase = (octet & 0x80) ? 0 : 255;
            *bp++ = phase;
            ++bp;
            phase ^= 255;
            *bp++ = phase;
            ++bp;
        }

        cas_srcpos += 1;
        cas_avail -= 1;
        dstpos += 2 * 8;
    }

    uint16_t ret = dstpos;

    // fill remainder
    while (dstpos < ABBUF_SZ) {
        *bp++ = 0;
        ++bp;
        ++dstpos;
    }

    return ret;
}


