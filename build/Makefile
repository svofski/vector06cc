###################################################################
# Project Configuration: 
# 
# Specify the name of the design (project) and the Quartus II
# Settings File (.qsf)
###################################################################

PROJECT = vector06cc
TOP_LEVEL_ENTITY = vector06cc
ASSIGNMENT_FILES = $(PROJECT).qpf $(PROJECT).qsf
QUARTUS_DIR = $(HOME)/altera/13.0sp1
export PATH := $(PATH):$(QUARTUS_DIR)/quartus/bin/
export TCLLIBPATH := \
    . \
    $(QUARTUS_DIR)/quartus/common/tcl/packages/tcllib-1.11/cmdline/ \
    $(QUARTUS_DIR)/quartus/linux/tcl8.5/msgcat/

###################################################################
# Part, Family, Boardfile DE1 or DE2
FAMILY = "Cyclone II"
PART = EP2C20F484C7
BOARDFILE = DE2Pins
###################################################################

###################################################################
# Main Targets
#
# all: build everything
# clean: remove output files and database
# program: program your device with the compiled design
###################################################################

all: smart.log $(PROJECT).asm.rpt $(PROJECT).sta.rpt 

clean:
	rm -f src
	rm -rf *.rpt *.chg smart.log *.htm *.eqn *.pin *.sof *.pof db incremental_db reports *.qpf *.qsf
	make -C ../firmware clean

map: smart.log $(PROJECT).map.rpt
fit: smart.log $(PROJECT).fit.rpt
asm: smart.log $(PROJECT).asm.rpt
sta: smart.log $(PROJECT).sta.rpt
smart: smart.log

###################################################################
# Executable Configuration
###################################################################

MAP_ARGS = --read_settings_files=on $(addprefix --source=,$(SRCS)) -l ../src -l ../src/altmodules -l ../src/DE1 -l ../src/T80

FIT_ARGS = --part=$(PART) --read_settings_files=on
ASM_ARGS =
STA_ARGS =

###################################################################
# Target implementations
###################################################################

STAMP = echo done >

../disk.hex:
	make -C ../firmware

$(PROJECT).map.rpt: map.chg ../src ../disk.hex
	ln -fs ../src .
	quartus_map $(PROJECT).qpf
	$(STAMP) fit.chg

$(PROJECT).fit.rpt: fit.chg $(PROJECT).map.rpt
	quartus_fit $(FIT_ARGS) $(PROJECT)
	$(STAMP) asm.chg
	$(STAMP) sta.chg

$(PROJECT).asm.rpt: asm.chg $(PROJECT).fit.rpt
	quartus_asm $(ASM_ARGS) $(PROJECT)

$(PROJECT).sta.rpt: sta.chg $(PROJECT).fit.rpt
	quartus_sta $(STA_ARGS) $(PROJECT) 

smart.log: $(ASSIGNMENT_FILES)
	quartus_sh --determine_smart_action $(PROJECT) > smart.log

###################################################################
# Project initialization
###################################################################

$(ASSIGNMENT_FILES):
	#quartus_sh --prepare -f $(FAMILY) -t $(TOP_LEVEL_ENTITY) $(PROJECT)
	#-cat $(BOARDFILE) >> $(PROJECT).qsf
	cp ../$(PROJECT).qsf .
	cp ../$(PROJECT).qpf .
map.chg:
	$(STAMP) map.chg
fit.chg:
	$(STAMP) fit.chg
sta.chg:
	$(STAMP) sta.chg
asm.chg:
	$(STAMP) asm.chg

###################################################################
# Programming the device
###################################################################

program: $(PROJECT).sof
	quartus_pgm --no_banner --mode=jtag -o "P;$(PROJECT).sof"
