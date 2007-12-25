SHELL=cmd.exe
C65=cc65
A65=ca65
L65=ld65

#CINC=c:\usr\lib\cc65\include
#AINC=c:\usr\lib\cc65\asminc

#OBJS=mmc.o tff.o serial.o main.o
#ASSS=mmc.s tff.s serial.s main.s
OBJS=tff.o mmc.o timer.o serial.o main.o
ASSS=tff.s mmc.s timer.s serial.s main.s

CFLAGS=-Oirs -t none -T --cpu 6502



all:	disk

disk:	$(OBJS)
	$(L65) -C vector.lc lib/vector.o $(OBJS) lib/vector.lib -o disk.bin -m disk.map
	bin2hex disk.bin
	copy disk.hex ..\..\workbench\floppy\src

clean:
	rm $(OBJS) $(ASSS) disk.bin disk.map

%.s:	%.c
	$(C65) $(CFLAGS) -I $(AINC) -I $(CINC) $<

%.o:	%.s
	$(A65) -t none $< -o $@

%.o:	%.c

#ld65 -C vector.lc lib/vector.o mmc.o lib/vector.lib -o mmc.bin -m mmc.map