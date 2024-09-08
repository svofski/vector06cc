#ifndef _CONFIG_H
#define _CONFIG_H

#define NOT_WITH_DMA

// somehow on msp430 strings in RODATA makes code bigger
//#define RSTRINGS_RODATA

// run a test on sector buffer ram at startup
//#define BUFRAM_TEST

#define WITH_SERIAL

#define VERBOSE 2	// 1: mostly quiet
			// 2: log all requests
			// 3: obsessive, print sector dumps


#define FDD_SECTOR_SIZE		1024U
#define FDD_NSIDES		2U
#define FDD_NSECTORS		5U
#define SECTOR_SIZE_CODE	3U		// 0 = 128, 1 = 256, 2 = 512, 3 = 1024

#ifndef NEW_FATFS
#define NEW_FATFS 0 // default to the old version
#endif

#define WAVBUF_SZ 256   // wav/cas load buffer
#define ABBUF_SZ  512   // playback buffers are 512 bytes, total of 1024 bytes

#endif
