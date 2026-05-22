######################################
## GLOBAL VARIABLES
######################################
WHOAMI := $(shell whoami)
PWD := $(shell pwd)
DATE := $(shell date '+%Y_%m%d_%H%M_%S')

TEST_DIR := $(shell pwd)
UVM_TRAINING := /home/ahmed/uvm_training
COMP_DIR := $(UVM_TRAINING)/verif/EIU/test

SIMULATOR := questa
ifeq ($(SIMULATOR), questa)
	BUILD_CMD := vlog 
	OPTM_CMD := vopt 
endif

TOP_MODULE := tb_top
DATABASE := $(TOP_MODULE) glbl

#####################################
## TEST VARIABLES
#####################################
USR_OPT := $(addprefix , $(OPT))
USR_LOG := $(addprefix , $(LOG))

ifeq "$(TEST_NAME)" ""
	TEST_NAME := eiu_base_test
endif

UART_WIDTH ?= 9

GUI  := 0
PLUSARGS ?=

ifeq ($(SIMULATOR), questa)
	SIM_CMD := vsim 
	COMMON_OPT := -modelsimini /home/ahmed/modelsim_2020_libs/modelsim.ini -sv -mfcu -work $(COMP_DIR)/work +define+VSIM -timescale=1ns/100fs +incdir+/home/ahmed/Downloads/NED_IC_Design_Course/Design_Verification_UVM/uvm_1.2/uvm-1.2/src -suppress 2388
endif

# =====================================================================
# ---> EXECUTION COMMANDS <---
# =====================================================================

ifeq ($(SIMULATOR), questa)
	OPTM_OPT := +acc $(TOP_MODULE) glbl -o $(DATABASE) -designfile design.bin -work $(COMP_DIR)/work
	SIM_OPT := $(SIM_OPT) -modelsimini /home/ahmed/modelsim_2020_libs/modelsim.ini -L unisims_ver -L unimacro_ver -L secureip -L xpm
	SIM_OPT := $(SIM_OPT) -sv_lib /home/ahmed/Downloads/NED_IC_Design_Course/Design_Verification_UVM/uvm_1.2/uvm-1.2/lib/uvm_dpi -work $(COMP_DIR)/work
	SIM_OPT := $(SIM_OPT) $(PLUSARGS)
endif

ifeq ($(GUI), 1)
	SIM_OPT := $(DATABASE) $(SIM_OPT)
else
	SIM_OPT := -c $(DATABASE) $(SIM_OPT)
endif

SIM_OPT := $(SIM_OPT) +UVM_TESTNAME=$(TEST_NAME)
SIM_OPT := $(SIM_OPT) +UVM_CONFIG_DB_TRACE
SIM_OPT := $(SIM_OPT) -classdebug
SIM_OPT := $(SIM_OPT) -l $(TEST_NAME).log

ifeq ($(SIMULATOR), questa)
    ifeq ($(GUI), 1)
    # ---> FIXED FOR GUI <---
    # 1. Removed the 'q' so the window stays open!
    # 2. Replaced 'do wave.do' with dynamic wildcard signal additions.
    # 3. Added -r (recursive) to dive deep into the sub-modules.
    SIM_OPT := $(SIM_OPT) -do " \
        onerror {resume}; \
        add wave -noupdate -divider {=== EIU TOP PINS ===}; \
        add wave -noupdate -r /tb_top/DUT/u_kernel/u_kernel_nrz/*; \
        add wave -noupdate /tb_top/DUT/*; \
        add wave -noupdate -divider {=== ETH (Config/Write/Read) ===}; \
        add wave -noupdate -r /tb_top/DUT/u_eth1/*; \
        add wave -noupdate -divider {=== UART TX / RX & FIFOs ===}; \
        add wave -noupdate -r /tb_top/DUT/*uart*/*; \
        run -a;"
    else
    SIM_OPT := $(SIM_OPT) -do "run -a; q"
    endif
endif

cov:
	dve -covdir $(COMP_DIR)/simv.vdb -full64

# =====================================================================
# ---> MODULAR COMPILATION (NO NAMESPACE COLLISIONS!) <---
# =====================================================================
compile:
	@echo "=== 1. Compiling UVM Base & RTL Base ==="
	$(BUILD_CMD) $(COMMON_OPT) /home/ahmed/modelsim_2020_libs/glbl.v /home/ahmed/Downloads/NED_IC_Design_Course/Design_Verification_UVM/uvm_1.2/uvm-1.2/src/uvm_pkg.sv $(UVM_TRAINING)/design/kernel/dual_port_FIFO.sv $(UVM_TRAINING)/design/kernel/cdc_*.sv
	
	@echo "=== 2. Compiling UART Subsystem ==="
	$(BUILD_CMD) $(COMMON_OPT) +define+UART_WIDTH=$(UART_WIDTH) \
	+incdir+$(UVM_TRAINING)/verif/uart_1/uvm_tb/sequence_item \
	+incdir+$(UVM_TRAINING)/verif/uart_1/uvm_tb/sequence \
	+incdir+$(UVM_TRAINING)/verif/uart_1/uvm_tb/config \
	+incdir+$(UVM_TRAINING)/verif/uart_1/uvm_tb/agent \
	+incdir+$(UVM_TRAINING)/verif/uart_1/uvm_tb/scoreboard \
	+incdir+$(UVM_TRAINING)/verif/uart_1/uvm_tb/env \
	+incdir+$(UVM_TRAINING)/verif/uart_1/test/short_test \
	$(UVM_TRAINING)/design/uart_1/uart_RX.sv $(UVM_TRAINING)/design/uart_1/uart_TX.sv $(UVM_TRAINING)/design/uart_1/uart_IF.sv $(UVM_TRAINING)/design/uart_1/uart.sv \
	$(UVM_TRAINING)/verif/uart_1/uvm_tb/interface/*.sv \
	$(UVM_TRAINING)/verif/uart_1/uvm_tb/package/uart_pkg.sv
	
	@echo "=== 3. Compiling ETH Subsystem ==="
	$(BUILD_CMD) $(COMMON_OPT) \
	+incdir+$(UVM_TRAINING)/verif/eth_1/uvm_tb/sequence_item \
	+incdir+$(UVM_TRAINING)/verif/eth_1/uvm_tb/sequence \
	+incdir+$(UVM_TRAINING)/verif/eth_1/uvm_tb/config \
	+incdir+$(UVM_TRAINING)/verif/eth_1/uvm_tb/agent \
	+incdir+$(UVM_TRAINING)/verif/eth_1/uvm_tb/scoreboard \
	+incdir+$(UVM_TRAINING)/verif/eth_1/uvm_tb/env \
	+incdir+$(UVM_TRAINING)/verif/eth_1/test/new_test \
	$(UVM_TRAINING)/design/eth_1/crc32_data8.sv $(UVM_TRAINING)/design/eth_1/udp_checksum_calculator.sv $(UVM_TRAINING)/design/eth_1/iddr_rx.sv $(UVM_TRAINING)/design/eth_1/oddr_tx.sv $(UVM_TRAINING)/design/eth_1/eth_*.sv $(UVM_TRAINING)/design/eth_1/ipv4_header_maker.sv $(UVM_TRAINING)/design/eth_1/udp_packet_maker.sv $(UVM_TRAINING)/design/eth_1/eth.sv \
	$(UVM_TRAINING)/verif/eth_1/uvm_tb/package/*_pkg.sv \
	$(UVM_TRAINING)/verif/eth_1/uvm_tb/interface/*.sv
	
	@echo "=== 4. Compiling KERNEL Subsystem ==="
	$(BUILD_CMD) $(COMMON_OPT) \
	+incdir+$(UVM_TRAINING)/verif/kernel/uvm_tb/sequence_item \
	+incdir+$(UVM_TRAINING)/verif/kernel/uvm_tb/sequence \
	+incdir+$(UVM_TRAINING)/verif/kernel/uvm_tb/config \
	+incdir+$(UVM_TRAINING)/verif/kernel/uvm_tb/agent \
	+incdir+$(UVM_TRAINING)/verif/kernel/uvm_tb/scoreboard \
	+incdir+$(UVM_TRAINING)/verif/kernel/uvm_tb/env \
	$(UVM_TRAINING)/design/kernel/kernel_config.sv $(UVM_TRAINING)/design/kernel/kernel_write.sv $(UVM_TRAINING)/design/kernel/kernel_read.sv $(UVM_TRAINING)/design/kernel/kernel_start_tx.sv $(UVM_TRAINING)/design/kernel/kernel_nrz.sv $(UVM_TRAINING)/design/kernel/kernel.sv \
	$(UVM_TRAINING)/verif/kernel/uvm_tb/interface/*.sv \
	$(UVM_TRAINING)/verif/kernel/uvm_tb/package/kernel_pkg.sv
	
	@echo "=== 5. Compiling EIU System ==="
	$(BUILD_CMD) $(COMMON_OPT) \
	+incdir+$(UVM_TRAINING)/verif/EIU/uvm_tb/config \
	+incdir+$(UVM_TRAINING)/verif/EIU/uvm_tb/env \
	+incdir+$(UVM_TRAINING)/verif/EIU/uvm_tb/scoreboard \
	+incdir+$(UVM_TRAINING)/verif/EIU/uvm_tb/sequence \
	$(UVM_TRAINING)/design/EIU/counter_8bit.sv \
	$(UVM_TRAINING)/design/EIU/EIU_TOP.sv \
	$(UVM_TRAINING)/verif/EIU/uvm_tb/pkg/eiu_pkg.sv \
	$(UVM_TRAINING)/verif/EIU/test/*_test.sv \
	$(UVM_TRAINING)/verif/EIU/vlib/tb_top.sv

optimize:
	$(OPTM_CMD) $(OPTM_OPT)

run: build run_sim

run_sim: 
ifeq ($(SIMULATOR), questa) 
	$(SIM_CMD) $(SIM_OPT) $(USR_OPT)
else
	$(SIMV_CMD) $(SIM_OPT) $(USR_OPT)
endif

build: compile

build_run_sim: build run_sim

clean:
	@rm -rf $(COMP_DIR)/compile.log
	@rm -rf $(COMP_DIR)/*.log
	@rm -rf $(COMP_DIR)/work
	@rm -rf $(COMP_DIR)/design.bin
	@rm -rf $(COMP_DIR)/vsim.wlf