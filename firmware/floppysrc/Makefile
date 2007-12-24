SHELL=cmd.exe
C65=c:\usr\lib\cc65\bin\cc65
A65=c:\usr\lib\cc65\bin\ca65
L65=c:\usr\lib\cc65\bin\ld65

CINC=c:\usr\lib\cc65\include
AINC=c:\usr\lib\cc65\asminc

OBJS=mmc.o tff.o serial.o main.o
ASSS=mmc.s tff.s serial.s main.s

CFLAGS=--signed-chars -v



all:	disk

disk:	$(OBJS)
	$(L65) -C vector.lc lib/vector.o $(OBJS) lib/vector.lib -o disk.bin -m disk.map
	bin2hex disk.bin

clean:
	rm $(OBJS) $(ASSS) disk.bin disk.map

%.s:	%.c
	$(C65) -t none -T --cpu 6502 -I $(AINC) -I $(CINC) $<

%.o:	%.s
	$(A65) -t none $< -o $@

%.o:	%.c

#ld65 -C vector.lc lib/vector.o mmc.o lib/vector.lib -o mmc.bin -m mmc.map