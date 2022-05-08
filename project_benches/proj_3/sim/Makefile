
export ECE745_PROJECT_HOME ?= $(PWD)/../../..

include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/wb_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/i2c_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/handler_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/ncsu_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/environment_packages/i2cmb_env_pkg/Makefile

GEN_TYPE ?= i2cmb_generator #i2cmb_generator_base
TEST_SEED ?= random

# if you execute "module load synopsys" then you can uncomment FSDB
VLOG_OPT = -cover bcesf #+define+FSDB
VSIM_OPT = -coverage -sv_seed $(TEST_SEED) +GEN_TYPE=$(GEN_TYPE) -classdebug -msgmode both -l transcript #-pli /mnt/apps/public/COE/synopsys_apps/verdi/S-2021.09-SP1/share/PLI/MODELSIM/LINUX/novas_fli.so

CLI_DO_COMMANDS = -do "do vsim_cli.do $(GEN_TYPE);"

BATCH_DO_COMMANDS = -do " \
			set NoQuitOnFinish 1; \
			add wave -r *; \
			log -r *; \
			run -all; \
			exit; "

GUI_DO_COMMANDS = -do " \
			set NoQuitOnFinish 1; \
			do wave.do; "

clean:
	rm -rf work *.wlf transcript i2cmb_test_plan*.ucdb *.vstf

comp_I2C_MB:
	vcom -cover bces ../rtl/iicmb_int_pkg.vhd
	vcom -cover bces ../rtl/iicmb_pkg.vhd
	vcom -cover bcesf ../rtl/mbyte.vhd
	vcom -cover bcesf ../rtl/mbit.vhd
	vcom -cover bces ../rtl/bus_state.vhd
	vcom -cover bces ../rtl/filter.vhd
	vcom -cover bces ../rtl/conditioner.vhd
	vcom -cover bces ../rtl/conditioner_mux.vhd
	vcom -cover bces ../rtl/iicmb_m.vhd
	vcom -cover bces ../rtl/regblock.vhd
	vcom -cover bces ../rtl/wishbone.vhd
	vcom -cover bces ../rtl/iicmb_m_wb.vhd

comp_bench: comp_ncsu_pkg comp_handler_pkg comp_wb_pkg comp_i2c_pkg comp_i2cmb_env_pkg
	vlog $(VLOG_OPT) ../testbench/top.sv
	#vlog  ../testbench/top.sv

optimize:
	vopt +acc top -o optimized_debug_top_tb

compile:  comp_bench comp_I2C_MB optimize

simulate:
	vsim  -i $(VSIM_OPT) $(GUI_DO_COMMANDS) optimized_debug_top_tb

run: clean compile
	vsim  -batch $(VSIM_OPT) $(BATCH_DO_COMMANDS) optimized_debug_top_tb
view:
	vsim -view vsim.wlf -do wave.do

#nWave:
#	nWave -f proj1.fsdb

debug: clean compile simulate

#=====================================
# add for proj3 & 4
#=====================================
run_cli:
	vsim -c -coverage -sv_seed $(TEST_SEED) $(CLI_DO_COMMANDS) +GEN_TYPE=$(GEN_TYPE) optimized_debug_top_tb

cli: clean compile run_cli

regress: clean compile
	#$(MAKE) run_cli GEN_TYPE=i2cmb_generator
	$(MAKE) run_cli GEN_TYPE=i2cmb_generator_register_test
	$(MAKE) run_cli GEN_TYPE=i2cmb_generator_fsm_functionality_test
	$(MAKE) run_cli GEN_TYPE=i2cmb_generator_control_functionality_test
	# $(MAKE) merge_coverage
	#$(MAKE) view_coverage

merge_coverage:
	xml2ucdb -format Excel ./i2cmb_test_plan.xml ./i2cmb_test_plan.ucdb
	add testbrowser ./*.ucdb
	vcover merge -stats=none -strip 0 -totals i2cmb_test_plan.ucdb ./*.ucdb

view_coverage:
	vsim -viewcov ./i2cmb_test_plan.ucdb

report_coverage:
	vcover report -details -html -htmldir covhtmlreport -assert -directive -cvg -code bcefst -threshL 50 -threshH 90 ./sim_and_testplan_merged.ucdb

merge_coverage_with_test_plan:
	rm -f i2cmb_test_plan.ucdb
	vsim -i -do load_ucdbs_and_merge_with_test_plan.do


#vsim -c TESTBED -pli /mnt/apps/public/COE/synopsys_apps/verdi_vr-2020_12-SP2-1/share/PLI/MODELSIM/LINUX64/novas_fli.so -64 -do "run -all"
