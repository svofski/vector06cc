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
const uint8_t MSX_HEADER[] = { 0x1F,0xA6,0xDE,0xBA,0xCC,0x13,0x7D,0x74 };
#if 0
const uint8_t MSX_ASCII[] =  { 0xEA,0xEA,0xEA,0xEA,0xEA,0xEA,0xEA,0xEA,0xEA,0xEA };
const uint8_t MSX_BIN[] =    { 0xD0,0xD0,0xD0,0xD0,0xD0,0xD0,0xD0,0xD0,0xD0,0xD0 };
const uint8_t MSX_BASIC[] =  { 0xD3,0xD3,0xD3,0xD3,0xD3,0xD3,0xD3,0xD3,0xD3,0xD3 };
#endif

#define CAS_LOAD_SAMPLERATE 4800

#define long_pulse ((CAS_LOAD_SAMPLERATE) / 1200)
#define short_pulse ((CAS_LOAD_SAMPLERATE) / 2400)

#define short_silence (CAS_LOAD_SAMPLERATE / 2)
#define long_silence  (CAS_LOAD_SAMPLERATE)

#define long_header 16000
#define short_header 4000

static FIL * casfile;
static caskind_t caskind;

extern uint8_t wavbuf[WAVBUF_SZ];

static int32_t caspos;  // global cas file position

static uint16_t cas_bufpos, cas_avail;

static uint16_t fsk_bits;   // 1, 8, 2 = 11 bits 
static int8_t fsk_nbits;    // number of leftover bits, including stop bits
static int8_t msx_header_num;

static int16_t msx_header_count;    // negative header bits count
static int16_t msx_silence_count;   // negative silence count

caskind_t cas_guess_kind(const uint8_t * data)
{
    if (0 == memcmp(data, V06C_BAS, sizeof(V06C_BAS))) return CAS_CSAVE;
    if (0 == memcmp(data, V06C_BIN, sizeof(V06C_BIN))) return CAS_BSAVE;
    if (0 == memcmp(data, MSX_HEADER, sizeof(MSX_HEADER))) return CAS_MSX;

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

#ifdef SIMULATION2
    printf("cas kind: %d\n", caskind);
#else
    ser_puts("cas: "); print_hex(caskind);
#endif

    if (caskind == CAS_CSAVE || caskind == CAS_BSAVE) {
        caspos = -v06c_preamble_size; // virtual preamble 
    }
    else if (caskind == CAS_MSX) {
        msx_header_num = 0;
        msx_header_count = 0;
        fsk_nbits = 0;
    }

    f_lseek(casfile, 0);          // reset to starting position
    cas_avail = 0;
    cas_bufpos = 0;

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

void cas_fetch()
{
#ifdef SIMULATION
    printf("\ncas_fetch\n");
#endif
    cas_avail = cas_read_bytes(wavbuf, WAVBUF_SZ);
    cas_bufpos = 0;
}

// fill one a/b buffer from v06c cas
uint16_t v06c_fill_buf(int ab, uint8_t *buffers)
{
    uint16_t dstpos = 0;
    //uint16_t br;

    uint8_t *bp = buffers + ab;  // write pointer (stride 2)

    while (dstpos < ABBUF_SZ) {
        // top up cas bytes (source)
        //if (cas_avail == 0) {
        //    br = cas_read_bytes(wavbuf, WAVBUF_SZ);
        //    cas_avail = br;
        //    cas_bufpos = 0;
        //    if (cas_avail == 0)   // eof
        //        break;
        //}
        if (cas_avail == 0) 
            cas_fetch();
        if (cas_avail == 0)   // eof
            break;

        // encode PSK byte
        uint8_t octet = wavbuf[cas_bufpos];
        for (uint8_t b = 0; b < 8; ++b, octet <<= 1) {
            uint8_t phase = (octet & 0x80) ? 0 : 255;
            *bp++ = phase;
            ++bp;
            phase ^= 255;
            *bp++ = phase;
            ++bp;
        }

        cas_bufpos += 1;
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

// fsk bit
// 1:     1 0 1 0
// 0:     1 1 0 0
//
// fsk byte
// 1 start bit: "0"     4 samps
// 8 data bits          4 * 8
// 2 stop bits: "11"    8 samps
//                    = 44 samps

// it's inevitable that bytes will cross buffer edges
// bits will always be atomic

uint8_t fsk_0(uint8_t **bpp)
{
    uint8_t *bp = *bpp;
    *bp++ = 255; ++bp;
    *bp++ = 255; ++bp;
    *bp++ = 0;   ++bp;
    *bp++ = 0;   ++bp;
    *bpp = bp;
    return 4;
}

uint8_t fsk_1(uint8_t **bpp)
{
    uint8_t *bp = *bpp;
    *bp++ = 255; ++bp;
    *bp++ = 0;   ++bp;
    *bp++ = 255; ++bp;
    *bp++ = 0;   ++bp;
    *bpp = bp;
    return 4;
}

uint8_t fsk_silence(uint8_t **bpp)
{
    uint8_t *bp = *bpp;
    *bp++ = 0; ++bp;      // could be 128, but it's a 1-bit sample
    *bp++ = 0; ++bp;
    *bp++ = 0; ++bp;
    *bp++ = 0; ++bp;
    *bpp = bp;
    return 4;
}

// requirement: ABBUF_SZ - dstpos >= 4
void encode_fsk_byte(uint8_t **bpp, uint8_t byte, uint16_t *dstpos)
{
    // finish the remainder of the last byte
    for (; --fsk_nbits >= 0 && *dstpos < ABBUF_SZ; fsk_bits >>= 1) {
        *dstpos += (fsk_bits & 1) ? fsk_1(bpp) : fsk_0(bpp);
    }

    fsk_bits = (byte | 0x0300) << 1; // start and stop bits
    for (fsk_nbits = 11; --fsk_nbits >= 0 && *dstpos < ABBUF_SZ; fsk_bits >>= 1) {
        *dstpos += (fsk_bits & 1) ? fsk_1(bpp) : fsk_0(bpp);
    }
}

int msx_next_byte()
{
    // top up cas bytes (source)
    if (cas_avail == 0) 
        cas_fetch();
    if (cas_avail == 0)
        return -1;

#ifdef SIMULATION2
    printf("msx_next_byte: cas_bufpos=%d ", cas_bufpos);
#endif

    // every 8-byte boundary can hide a header
    if ((cas_bufpos & 7) == 0
            && 0 == memcmp(wavbuf + cas_bufpos, MSX_HEADER, sizeof(MSX_HEADER))) {
        // enter header sequence
        msx_header_count = msx_header_num == 0 ? -long_header : -short_header;
        msx_header_count /= 2;
        if (msx_header_num > 0) {
            msx_silence_count = -short_silence / 4;
        }
        ++msx_header_num;
        cas_bufpos += sizeof(MSX_HEADER);
        cas_avail -= sizeof(MSX_HEADER);
#ifdef SIMULATION2
        printf("HEADER DETECTED msx_header_count=%d ", msx_header_count);
#endif
        return -1;
    }

    cas_avail -= 1;
#ifdef SIMULATION2
    printf("cas_avail=%d cas_bufpos<-%d wavbuf[caspos]=%02x\n", cas_avail, cas_bufpos+1, 
            wavbuf[cas_bufpos]);
#endif
    return wavbuf[cas_bufpos++];
}

void fsk_header(uint8_t **bpp, uint16_t *dstpos)
{
    for (; msx_silence_count < 0 && *dstpos < ABBUF_SZ; ++msx_silence_count) {
        *dstpos += fsk_silence(bpp);
    }
    for (; msx_header_count < 0 && *dstpos < ABBUF_SZ; ++msx_header_count) {
        *dstpos += fsk_1(bpp);
    }
}

// fill one a/b buffer from msx cas
uint16_t msx_fill_buf(int ab, uint8_t *buffers)
{
    uint16_t dstpos = 0;
    uint8_t *bp = buffers + ab;

    fsk_header(&bp, &dstpos);
#ifdef SIMULATION2
    printf("msx_fill_buf after fsk_header: dstpos=%u msx_header_count=%d\n", dstpos, msx_header_count);
#endif

    while (dstpos < ABBUF_SZ) {
        int cas_byte = msx_next_byte();
#ifdef SIMULATION
        printf("%02x ", cas_byte);
#endif
        if (cas_byte == -1) {
            if (dstpos == 0 && fsk_nbits > 0) { // finish the last byte
                encode_fsk_byte(&bp, 0, &dstpos);
            }
            if (msx_header_count == 0) 
                break; // eof

            fsk_header(&bp, &dstpos);
            continue;
        }
        encode_fsk_byte(&bp, cas_byte, &dstpos);
    }

    uint16_t ret = dstpos;

    // fill remainder
    while (dstpos < ABBUF_SZ) {
        *bp++ = 0; ++bp;
        ++dstpos;
    }

    return ret;
}

uint16_t cas_fill_buf(int ab, uint8_t *buffers)
{
    switch (caskind) {
        case CAS_CSAVE:
        case CAS_BSAVE:
            return v06c_fill_buf(ab, buffers);
        case CAS_MSX:
            return msx_fill_buf(ab, buffers);
        default:
            break;
    }

    return 0;
}
