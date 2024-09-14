CFLAGS=-g -O0
SRC=sim.c ../osd.c ../rstrings.c ../menu.c ../philes.c ../util.c dir.c console.c
SRCWAV=wavtest.c ../util.c ../wav.c console.c faketff.c
SRCCAS=castest.c ../util.c ../wav.c ../cas.c console.c faketff.c

all:	sim castest

sim:	$(SRC)
	gcc -g -DSIMULATION -I.. $(SRC) -o sim	

wavtest:	$(SRCWAV)
	gcc -g -DSIMULATION -I.. $(SRCWAV) -o wavtest

castest:	$(SRCCAS)
	gcc -g -DSIMULATION -I.. $(SRCCAS) -o castest

clean:
	rm -f sim wavtest castest *.o
