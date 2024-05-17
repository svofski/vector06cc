TARGET=floppy_testbench

BASE_DIR=../..
FLOPPY_DIR=$(BASE_DIR)/floppy $(BASE_DIR)/floppy/verilog-6502-copy
TOP=$(TARGET)

IVINC=$(addprefix -I,$(FLOPPY_DIR))

IVERILOG=iverilog $(IVINC) -DSIMULATION #-DSIM
VVP=vvp
GTKWAVE=gtkwave

FLOPPY_SRC=$(foreach sdir,$(FLOPPY_DIR),$(wildcard $(sdir)/*.v))

OTHER_SRC=$(BASE_DIR)/oneshot.v ../upi_uart/uart.v ram.v

$(info sdir=$(sdir) FLOPPY_SRC=$(FLOPPY_SRC) OTHER_SRC=$(OTHER_SRC))

SRC=$(TARGET).v $(FLOPPY_SRC) $(SDCARD_SRC) $(OTHER_SRC)

all:	$(TARGET).vcd

wave:	$(TARGET).vcd
	$(GTKWAVE) $^ &

$(TARGET).vcd:	$(TARGET).vvp
	$(VVP) $^

$(TARGET).vvp:	$(SRC)
	$(IVERILOG) -o $@ -s $(TOP) $^
