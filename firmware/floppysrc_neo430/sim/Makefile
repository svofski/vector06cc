CFLAGS=-g -O0
SRC=sim.c ../osd.c ../rstrings.c ../menu.c ../philes.c ../util.c dir.c console.c
SRCWAV=wavtest.c ../util.c ../wav.c console.c

all:	sim wavtest

sim:	$(SRC)
	gcc -g -DSIMULATION -I.. $(SRC) -o sim	

wavtest:	$(SRCWAV)
	gcc -g -DSIMULATION -I.. $(SRCWAV) -o wavtest

clean:
	rm -f sim wavtest
