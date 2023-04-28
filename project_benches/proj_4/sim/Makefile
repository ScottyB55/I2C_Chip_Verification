export ECE745_PROJECT_HOME ?= $(PWD)/../../..

include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/wb_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/i2c_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/environment_packages/i2cmb_env_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/ncsu_pkg/Makefile

GEN_TRANS_TYPE ?= wb_transaction
GEN_TEST_TYPE ?= i2cmb_test
TEST_SEED ?= 123456

CLI_DO_COMMANDS = -do " \
                    set NoQuitOnFinish 1; \
                    run -all; \
	 	            do save_coverage.do $(GEN_TEST_TYPE); \
		    	    coverage save $(GEN_TEST_TYPE).$(TEST_SEED).ucdb; \
                    quit -f;" 

DEBUG_DO_COMMANDS = -do " \
                    set NoQuitOnFinish 1; \
                    do wave.do;\
                    run -a;"\

clean: 
	rm -rf work *.wlf transcript *.ucdb

comp_I2C_MB:
	vcom -cover befst ../rtl/iicmb_int_pkg.vhd
	vcom -cover befst ../rtl/iicmb_pkg.vhd
	vcom -cover befst ../rtl/mbyte.vhd
	vcom -cover befst ../rtl/mbit.vhd
	vcom -cover befst ../rtl/bus_state.vhd
	vcom -cover befst ../rtl/filter.vhd
	vcom -cover befst ../rtl/conditioner.vhd
	vcom -cover befst ../rtl/conditioner_mux.vhd
	vcom -cover befst ../rtl/iicmb_m.vhd
	vcom -cover befst ../rtl/regblock.vhd
	vcom -cover befst ../rtl/wishbone.vhd
	vcom -cover befst ../rtl/iicmb_m_wb.vhd


comp_bench: comp_ncsu_pkg comp_i2c_pkg comp_wb_pkg comp_i2cmb_env_pkg
	vlog +cover ../testbench/top.sv

optimize:
	vopt +acc top -o optimized_debug_top_tb

compile: comp_I2C_MB comp_bench optimize

simulate:
	vsim  -i -coverage -classdebug -msgmode both -do "set NoQuitOnFinish 1; do wave.do" optimized_debug_top_tb

debug: clean compile simulate


run_cli:
	vsim -coverage -c -sv_seed $(TEST_SEED) -do "set NoQuitOnFinish 1; run -a; coverage attribute -name TESTNAME -value $(GEN_TEST_TYPE); coverage save $(GEN_TEST_TYPE).$(TEST_SEED).ucdb; quit -f" +GEN_TRANS_TYPE=$(GEN_TRANS_TYPE) +GEN_TEST_TYPE=$(GEN_TEST_TYPE) optimized_debug_top_tb


cli: clean compile run_cli

run_cov:
	vsim -i -classdebug -msgmode both -do "do load_ucdbs_and_merge_with_test_plan.do" optimized_debug_top_tb

merge_coverage_with_test_plan: clean compile run_cov

covert_testplan:
	xml2ucdb -formal Excel ./i2cmb_test_plan.xml ./i2cmb_test_plan.ucdb
	add testbrowser ./*.ucdb

merge_coverage:
	xml2ucdb -format Excel ./i2cmb_test_plan.xml ./sim_and_testplan_merged.ucdb
	vcover merge -stats=none -strip 0 -totals sim_and_testplan_merged.ucdb ./*.ucdb

report_coverage:
	vcover report -details -html -htmldir covhtmlreport -assert -directive -cvg -code -bcefst -threshL 50 -threshH 90 ./sim_and_testplan_merged.ucdb
	

run_gui:
	vsim -coverage -sv_seed $(TEST_SEED) $(DEBUG_DO_COMMANDS) +GEN_TEST_TYPE=$(GEN_TEST_TYPE) optimized_debug_top_tb


debug: clean compile optimize run_gui


regress:
	./regress.sh

view_coverage:
	vsim -viewcov ./sim_and_testplan_merged.ucdb
