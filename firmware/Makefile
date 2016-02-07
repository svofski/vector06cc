all:	cc65 floppysrc
	git submodule update --init --remote
	cd cc65 && git checkout vector06cc
	make -C cc65 TARGETS=vector
	make -C floppysrc

clean:
	make -C cc65 clean
	make -C floppysrc clean

