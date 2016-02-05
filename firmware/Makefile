all:    cc65 floppysrc
	git submodule update --init --remote
	cd cc65 && git checkout vector06cc
	TARGETS=vector make -C cc65
	make -C floppysrc

clean:
	make -C cc65 clean
	make -C floppysrc clean

