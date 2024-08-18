REQUIREMENTS

The toolchain that I'm building the firmware now reponds to version query with

  msp430-elf-gcc (Mitto Systems Limited - msp430-gcc 9.3.1.11) 9.3.1

There seems to be several versions of the toolchain available. I found mine here:
https://www.ti.com/tool/download/MSP430-GCC-OPENSOURCE


BUILDING

Make sure that the toolchain is in the system PATH, e.g.:

  export PATH=/opt/msp430/msp430-gcc-9.3.1.11_linux64/bin:$PATH

If the toolchain is fine, make check will say that the toolchain is OK.


Run

  make compile

It should produce disk_neo430.hax needed to initialise the floppy rom.
