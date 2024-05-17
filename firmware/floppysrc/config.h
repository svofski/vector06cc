#ifndef _CONFIG_H
#define _CONFIG_H

//#define WITH_DMA

#define WITH_SERIAL

#define VERBOSE 2	// 1: mostly quiet
			// 2: log all requests
			// 3: obsessive, print sector dumps


#define FDD_SECTOR_SIZE		1024U
#define FDD_NSIDES		2U
#define FDD_NSECTORS		5U
#define SECTOR_SIZE_CODE	3U		// 0 = 128, 1 = 256, 2 = 512, 3 = 1024

#endif