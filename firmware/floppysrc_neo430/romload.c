#include "specialio.h"
#include "romload.h"
#include "serial.h"

static void acquire_ram()
{
    OSD_CMD = OSDCMD_ROMHOLD;   // take exclusive RAM access
}

static void release_ram()
{
    OSD_CMD = OSDCMD_NONE;      // release exclusive RAM access
}

// sideload rom file into v06c memory at addr
// bufptr is SECTOR_BUFFER[SECTOR_BUFFER_SZ] 
uint8_t rom_load(FIL * file, uint8_t * bufptr, uint32_t addr) 
{
    // a rom cannot be larger than 64K but a .edd could
    UINT bytesread = 0;

    acquire_ram();
    ROMLOAD_PAGE = 0;
    uint16_t a = addr & 0xffff;
    uint32_t total = 0;
    do {
        FRESULT r = f_read(file, bufptr, SECTOR_BUFFER_SZ, &bytesread);
        
        if (r != FR_OK) {
            break;
        }

        for (unsigned i = 0; i < bytesread; ++i) {
            ROMLOAD_ADDR = a++;
            ROMLOAD_DATA = bufptr[i];   // writes data to v06c ram
        }

        total += bytesread;

        // TODO: pages?
    } while (bytesread == SECTOR_BUFFER_SZ);

    release_ram();

    vputs("rom_load() size=0x"); vputh16(total); vnl();

    return 0;
}
