export ECE745_PROJECT_HOME ?= $(PWD)/../../..

include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/wb_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/i2c_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/environment_packages/i2cmb_env_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/ncsu_pkg/Makefile
GEN_TRANS_TYPE ?= i2cmb_test
TEST_SEED ?= 123456

CLI_DO_COMMANDS = -do " \
                    set NoQuitOnFinish 1; \
                    run -all; \
	 	            do save_coverage.do $(GEN_TRANS_TYPE); \
                    quit -f;" 

DEBUG_DO_COMMANDS = -do " \
                    set NoQuitOnFinish 1; \
                    do wave.do;\
                    run -a;"\

clean: 
	rm -rf work *.wlf transcript *.ucdb

comp_I2C_MB:
	vcom ../rtl/iicmb_int_pkg.vhd
	vcom ../rtl/iicmb_pkg.vhd
	vcom ../rtl/mbyte.vhd
	vcom ../rtl/mbit.vhd
	vcom ../rtl/bus_state.vhd
	vcom ../rtl/filter.vhd
	vcom ../rtl/conditioner.vhd
	vcom ../rtl/conditioner_mux.vhd
	vcom ../rtl/iicmb_m.vhd
	vcom ../rtl/regblock.vhd
	vcom ../rtl/wishbone.vhd
	vcom ../rtl/iicmb_m_wb.vhd


comp_bench: comp_ncsu_pkg comp_i2c_pkg comp_wb_pkg comp_i2cmb_env_pkg
	vlog +cover ../testbench/top.sv

optimize:
	vopt +acc top -o optimized_debug_top_tb

compile: comp_I2C_MB comp_bench optimize

simulate:
	vsim  -i -coverage -classdebug -msgmode both -do "set NoQuitOnFinish 1; do wave.do" optimized_debug_top_tb

debug: clean compile simulate



run_cli:
	vsim -c -coverage -sv_seed $(TEST_SEED) $(CLI_DO_COMMANDS) +GEN_TRANS_TYPE=$(GEN_TRANS_TYPE) optimized_debug_top_tb

run_gui:
	vsim -coverage -sv_seed $(TEST_SEED) $(DEBUG_DO_COMMANDS) +GEN_TRANS_TYPE=$(GEN_TRANS_TYPE) optimized_debug_top_tb

cli: clean compile optimize run_cli

debug: clean compile optimize run_gui

merge_coverage:
	xml2ucdb -format Excel ./i2cmb_test_plan.xml ./test_plan.ucdb
	vcover merge -stats=none -strip 0 -totals sim_and_testplan_merged.ucdb ./*.ucdb 


regress:
	./regress.sh

view_coverage:
	vsim -viewcov ./sim_and_testplan_merged.ucdb
