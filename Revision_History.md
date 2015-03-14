### Rev.388 ###
  * rom\_access is registered, hopefully this reduces SRAM\_OE\_N delay and makes it better compatible with newer revisions of DE1 board that have slower SRAM
  * big cleanup in framebuffer.v: now SRAM accesses happen once on every video\_slice, that is exactly 4 times per 8 pixels as it should be


### Rev.377 ###
  * Fixed 512x256 modes

### Rev.366 ###
  * Changed wait states to match the original, match based on instruction count between interrupts test by ivagor (spdtest.rom, spdtest2.rom)
  * Added adjustable palette RAM write delay to make fixes like this less painful
  * Changed the moment of scroll register update based on scrltst{2} by ivagor (horizontal shift still observed)

### Rev.353 ###
  * T80 CPU fixes. No currently known discrepancies with 8080/КР580ВМ80А left.
  * PILLARS work
  * Restored separate second PLL for audio-related clocks, fixes tape loading problem

### Rev.349 ###
  * Implemented composite colour PAL output, see [TV\_Howto](TV_Howto.md)
  * All clocks moved to single PLL

### Rev.331 ###
  * SkyNet now works correctly in the end of the photo part: sunami's face appears without the dash of doom and "home doctor" face is circled correctly
  * All stack operations now generate STACK status proper
  * port 01 (Port C) bits 3:0 read as 1's now, this fixes Kolobiha decoder
  * Changed configuration device to EPCS4 for DE1 board
  * The project is now for Quartus 8.0sp1 (qsf file changed)

### Rev.322 ###
  * Keyboard stuckness: only keys that are in different positions in shifted/nonshifted mode are prone to get stuck now, but only if pressed in specially designed order. Otherwise, keyboard works very nicely [Issue](http://code.google.com/p/vector06cc/issues/detail?id=1)
  * Characters `~`_` mapped to their proper PS/2 keys [Issue](http://code.google.com/p/vector06cc/issues/detail?id=36)
  * Added forgotten mclk14mhz.v to the repository.

### Rev.300 ###
  * ([r297](https://code.google.com/p/vector06cc/source/detail?r=297)) FDC: rewrote the state machine: now it uses many more states, but debugging is more linear; D>Q command works in both versions of MicroDOS but BDS C chaining only works sometimes.
  * FDC write mode implemented, DMA included [Issue](http://code.google.com/p/vector06cc/issues/detail?id=35)
  * Improved recovery after an attempt to select disk image with SD card removed was made
  * Use bit 7 (NOTREADY) to indicate SD card absence, also set error bits in the status word.
  * DE1 doesn't have a contact input, so a continuous polling is implemented to detect card presence [Issue](http://code.google.com/p/vector06cc/issues/detail?id=34)
  * Implemented a workaround for FDC detection, useful when using disk microdos without floppy compiled in, see `FLOPPYLESS_HAX` define [Issue](http://code.google.com/p/vector06cc/issues/detail?id=33)

### Rev.267 ###
  * Video scroll reg is cleared on 8255 mode set, fixes screen jumping in MUSICIAN.ROM; [Issue](http://code.google.com/p/vector06cc/issues/detail?id=29)
  * YM2149 is now clocked by 1.75MHz, as appropriate, uses separate PLL when `TWO_PLL_OK` is defined; otherwise, primary PLL is used and resulting clock frequency is 1.8MHz, which is not bad at all either (36 cents difference); [Issue](http://code.google.com/p/vector06cc/issues/detail?id=30)
  * Tape input can be disabled by setting SW6 up ("1") (ZAS viewer skips otherwise); [Issue](http://code.google.com/p/vector06cc/issues/detail?id=25)
  * Floppy DMA mode is implemented (direct SPI -> buffer, bypassing the 6502). Stellar! [Issue](http://code.google.com/p/vector06cc/issues/detail?id=20).

### Rev.234 ###
  * OSD! Toggled by ScrollLock, allows changing floppy images, reset, restart, bus hold
  * converted retrace interrupt into a latch, reset by !INTE, hoping for better compat

**Revision Notes:**

ScollLock now toggles the menu, it thus doesn't hold the bus anymore -- the main CPU keeps on crunching as the OSD is displayed. Instead, the bus can still be held by SW7 or by selecting HOLD menu item.

### Rev.222 ###
  * Reviewed all 8080 instructions regarding TStates. Everything but HLT must be matching now
  * Changed vga\_refresh a little bit: made borders even according to the docs, simplified yborder and framebuffer line counter logic. It looks much more clear now.
  * Retrace interrupt: still unclear about that, currently it holds for 192 cycles and resets on INTA or after the period of time is over.

**Revision Notes:**

It seems that there's some compromise between the shaky bits now. Black Ice shows the TV almost in place (some 8 pixels closer to the TV border), m@color still works as before and SkyNet passes to the end, even though not without some sparks in the cursed photo part.

### Rev.212 ###
  * Display frame changed to 624 lines which matches the original HW
  * 8253 timer: terminal count in mode 2 fixed for proper rate generation
  * T80: 8080 mode -- status bit 1 is now always '1', bits 3 and 5 are '0'; this prevents programs from detecting is as a **КР580ВМ1** (test program available in workbench/cputest)
  * AY reading from registers. Not really tested but MicroDOS probe detects AY presence
  * Floppy controller now faults when drive B is accessed
  * Simplified SRAM bus multiplexer (without noticable side effects)

**Revision Notes:**
> The first two changes fix probs with Exolon [=>](http://code.google.com/p/vector06cc/issues/detail?id=3&can=1#c4)_._

> Same thing apparently enabled SkyNet demo to work farther. Now it flawlessly passes the `KIROV CODERS` part and crashes near the end of photo part with what appears to be a minor memory corruption at first (always a black stripe across Sunami's mouth, how omnious!), with more dramatic effects following. It's worth noting that it's still a single overlay module.

> ВМ1 detection probably wasn't an issue due to low availability of the latter. But I definitely have a more adequate 8080 now.

### Rev.204 ###
  * 8253 timer partially fixed, but only somewhat.. Events happen in time, but Exolon that depends on it still doesn't work as expected; SkyNet "emulator detection" now takes vector06cc for the real thing
  * floppy now automatically remounts the disk image after mmc is reinserted but since there's no door contact of any kind, this happens not before a read operation has failed

### Rev.195 ###
  * [.fdd check fixed](http://code.google.com/p/vector06cc/issues/detail?id=16)
  * [multicolor in Black Ice fixed](http://code.google.com/p/vector06cc/issues/detail?id=14)
  * [DAA instruction fixed](http://code.google.com/p/vector06cc/issues/detail?id=13)

### Rev.192 ###

  * Got rid of priority encoder in peripheral\_data\_in bus: this fixed some timing issues

> A construct like this unwraps into a loooong cascade:
```
always peripheral_data_in = ~vv55int_oe_n ? vv55int_odata :
			vi53_rden ? vi53_odata : 
			floppy_rden ? floppy_odata : 
			~vv55pu_oe_n ? vv55pu_odata : 8'hFF;
```
> I tried a more linear and clearly defined selector and it seems to be working nicely:
```
always
	case ({~vv55int_oe_n, vi53_rden, floppy_rden, ~vv55pu_oe_n}) 
		4'b1000: peripheral_data_in <= vv55int_odata;
		4'b0100: peripheral_data_in <= vi53_odata;
		4'b0010: peripheral_data_in <= floppy_odata;
		4'b0001: peripheral_data_in <= vv55pu_odata;
		default: peripheral_data_in <= 8'hFF;
	endcase
```
> There are plenty of constructs like the former one in vector06cc, but I'm not sure if many of them are worth replacing. SRAM multiplexer, for one, definitely wants some attention, even though there are no apparent problems with it yet.

### Rev.184 ###

  * AY sound added (YM2149 by MikeJ)
  * 8-bit pcm is added to soundcodec.v

### Rev.183 ###

  * First release of FDC.

### Rev.73 ###

  * [JTAG access](JTAG_Implementation.md) via Control Panel.

### Rev.62 ###

  * Keyboard shiftness stuckness resolved: shift+: or `*` can be safely pressed and depressed.

### Here there be dragons ###