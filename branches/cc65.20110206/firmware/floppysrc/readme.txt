Disk I/O Processor for Vector-06C Replica
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

vector.o and vector.lib based on spectravision library. Makefile of
libsrc section only works in cygwin.

Vector PIO memory map is defined in vector.lc.

elm-chan's tff and mmc modules, altered for custom memory-mapped i/o; 
based on AVR version. Platform-dependent defines moved to 
specialio.h.



Memory mapped I/O
~~~~~~~~~~~~~~~~~

$E000		Misc control signals:
			bit 0: MMC card CS_n

$E001		SPI Data Register

$E002		SPI control register:
			bit 0: SPIF (1 == transmit complete)
		
$E003		Socket contact port
			bit 4:	0x10 	card detect switch
			bit 5:	0x20	write protect switch
			
			