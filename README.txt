	VECTOR-06C FPGA REPLICA
	~~~~~~~~~~~~~~~~~~~~~~~

This project is an attempt to replicate Vector-06C, a Soviet-era home 
computer, in FPGA. The primary hardware platform for this project is 
Altera DE1 development board.


The following features are implemented as of December 16, 2007:

- CPU
- SRAM is used for everything
- 8253 timer (not entirely, only what's useful for sound generation)
- tape i/o (and beeper)
- all internal stuff, video modes, palette
- PS/2 keyboard
- 256K RAM disk
- DE1 JTAG interface to JTAG USB API program


DE1 Thingies
~~~~~~~~~~~~

Enjoy the generous blinkenlights from Terasic and svofski!

It is important to have switches SW8 and SW9 in "1" position (up). This
enables proper CPU clocking. Other switches just change the blinken pattern
and only important when you're debugging.

KEY0 is master reset, somewhat like BLK+VVOD. 

KEY1 is manual clock for CPU. Useful only for hardcore debugging.

KEY3 is same as BLK+SBR: boot ROM is disabled, RST0 is executed.

If KEY3 is held pressed when KEY0 is being pressed, or when Vector-06C 
image is being programmed into FPGA, boot ROM doesn't work at all. 
This is useful if you want to preserve SRAM content.



DE1 SRAM Mapping
~~~~~~~~~~~~~~~~
DE1 SRAM is addressed by word. This is mapped linearly into bytes, so programs
can be uploaded with CII Starter Kit Control Panel software without any 
modifications. However, addresses should be minded.

Normally a .rom file goes to address 0x0100. Translated into word-address, that
becomes 0x0080. So when uploading a .rom file to Vector, enter "80" in the SRAM
page, "Sequential Write" box.

Similarly, RAM disk pages start after first 64K, which is 0x10000, or 0x8000 
in words. So, for uploading RAM disk images, use address "8000". RAM disk images
can be read Starter Kit Control Panel software and re-uploaded later or used
with an emulator as .edd files.


Known Problems
~~~~~~~~~~~~~~

1. Keyboard input gets stuck when some of the ":()*@" characters are entered.

	This is a problem with PS/2 -> Vector keyboard key/char mapping.
	I tried to make it as much PS/2 as possible. But since some characters
	shift/key combination differ, there's more than one direct mapping and
	this mapping gets stuck.
	
	Workaround: always carefully press SHIFT, then ":", then release ":", 
	then release SHIFT. If input gets stuck, unstuck it by carefully 
	pressing same character again.

2. PS key is not implemented

	Well, duh.. 

3. BLK+VVOD is not implemented

	Use KEY0 instead.

n-1. ROM "<whatever>.rom" doesn't work
	
	Unless you know for sure that it must work, screw it.

n. ROM "<whatver>.rom" works incorrectly.

	If you know for sure how it must work, I'm open for suggestions.


Acknowledgements
~~~~~~~~~~~~~~~~

This project uses work of different people. 

T80 CPU by Daniel Wallner with fixes from MikeJ of www.fpgaarcade.com is used 
for KR580WM80A. The code is modified in attempt to make this otherwise
excellent CPU cycle-compatible with i8080 and to implement STACK signal in PSW.

82C55 code by MikeJ of www.fpgaarcade.com is used without any modifications.

DE1-specific code uses, or may be based upon, samples from Altera DE1 package.


$Id$

Viacheslav Slavinsky
http://sensi.org/~svo
http://sensi.org/~svo/vector06c
