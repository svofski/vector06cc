CC=/usr/local/pdp11/bin/pdp11-aout-gcc
OBJCOPY=/usr/local/pdp11/bin/pdp11-aout-objcopy
OBJDUMP=/usr/local/pdp11/bin/pdp11-aout-objdump

OBJS=crt0.o philes.o menu.o osd.o slave.o fddimage.o tff.o mmc.o timer.o serial.o main.o 

# snapshot version of cc65 has a patch regarding -Os
# release version will only work with -Oirs
CFLAGS=-Os -m40 -fomit-frame-pointer

all:	disk.bin disk.hex

disk.bin:	disk.aout
	$(OBJCOPY) -O binary $< $@
	$(OBJDUMP) -d $< > disk.dump

disk.hex:	disk.aout
	$(OBJCOPY) -O ihex $< $@

disk.aout:	$(OBJS)
	#$(L65) -C vector.lc lib/vector.o $(OBJS) lib/vector.lib -o disk.bin -m disk.map
	#bin2hex disk.bin
	#copy disk.hex ..\..\workbench\floppy\src
	#copy disk.hex ..\..
	$(CC) -Tvectorfloppy.x $^ -o $@ -nostartfiles

clean:
	rm -f $(OBJS) disk.bin disk.map disk.hex disk.aout

#%.o:	%.s
#	$(A65) -t none $< -o $@

