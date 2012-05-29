
all:	sim
SHELL = /bin/sh
#MS=-s

##########################################################################
#
# DUT Sources
#
##########################################################################
DUT_SRC_DIR=../../../rtl/verilog
_TARGETS_=	$(DUT_SRC_DIR)/I2C_Clock_gen.v		\
			$(DUT_SRC_DIR)/I2C_Ctrl_top.v		\
			$(DUT_SRC_DIR)/I2C_Transceiver.v


##########################################################################
#
# Test Bench Sources
#
##########################################################################
TB_SRC_DIR=../../../bench/verilog
_TB_=
#_TB_=		$(TB_SRC_DIR)/test_bench_top.v


##########################################################################
#
# Misc Variables
#
##########################################################################

INCDIR=+incdir+./$(DUT_SRC_DIR)/ +incdir+./$(TB_SRC_DIR)/
LOGF=-l .nclog

ACCESS=+access+rw
WAVES=+define+WAVES
VCD=

##########################################################################
#
# Make Targets
#
##########################################################################

ss:
	signalscan -do waves/waves.do -waves waves/waves.trn &

simw:
	$(MAKE) $(MS) sim ACCESS="+access+r " WAVES="+define+WAVES"

sim:
	ncverilog $(_TARGETS_) $(_TB_)      \
		$(INCDIR) $(WAVES) $(VCD) $(ACCESS) $(LOGF) +ncstatus  \

gatew:
	@$(MAKE) -s gate ACCESS="+access+r" WAVES="+define+WAVES"

gate:
	ncverilog -q +define+RUDIS_TB $(_TB_) $(UMC_LIB)        \
		$(GATE_NETLIST) $(INCDIR) $(WAVES) $(ACCESS)    \
		$(LOGF) +ncstatus +ncuid+`hostname`

clean:
	rm -rf	./waves/*.dsn ./waves/*.trn		\
		INCA_libs				\
		./verilog.* .nclog hal.log \
		./.simvision

##########################################################################
