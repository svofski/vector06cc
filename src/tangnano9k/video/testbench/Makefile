TARGET=lcd_testbench

BASE_DIR=..
TOP=$(TARGET)

IVINC=$(addprefix -I,$(FLOPPY_DIR))

IVERILOG=iverilog $(IVINC) -DSIMULATION #-DSIM
VVP=vvp
GTKWAVE=gtkwave

MAIN_SRC=$(BASE_DIR)/vga_refresh.v

OTHER_SRC=#$(BASE_DIR)/oneshot.v ../upi_uart/uart.v

$(info sdir=$(sdir))

SRC=$(TARGET).v $(MAIN_SRC)

all:	$(TARGET).vcd

wave:	$(TARGET).vcd
	$(GTKWAVE) $^ &

$(TARGET).vcd:	$(TARGET).vvp
	$(VVP) $^

$(TARGET).vvp:	$(SRC)
	$(IVERILOG) -o $@ -s $(TOP) $^
