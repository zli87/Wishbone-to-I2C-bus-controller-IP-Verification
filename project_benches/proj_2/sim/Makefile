# if you execute "module load synopsys" then you can uncomment FSDB
OPT = #FSDB

export ECE745_PROJECT_HOME ?= $(PWD)/../../..

include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/wb_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/interface_packages/i2c_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/ncsu_pkg/Makefile
include $(ECE745_PROJECT_HOME)/verification_ip/environment_packages/i2cmb_env_pkg/Makefile

clean:
	rm -rf work *.wlf transcript

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


comp_bench: comp_ncsu_pkg comp_wb_pkg comp_i2c_pkg comp_i2cmb_env_pkg
	vlog +define+$(OPT) ../testbench/top.sv
	#vlog  ../testbench/top.sv

optimize:
	vopt +acc top -o optimized_debug_top_tb

compile: comp_I2C_MB comp_bench optimize

simulate:
	vsim  -i -classdebug -msgmode both -l transcript -do "set NoQuitOnFinish 1; do wave.do" optimized_debug_top_tb

run: clean compile
	vsim  -batch -classdebug -msgmode both -l transcript -do "set NoQuitOnFinish 1; add wave -r *; log -r *; run -all; exit" optimized_debug_top_tb #-pli /mnt/apps/public/COE/synopsys_apps/verdi/S-2021.09-SP1/share/PLI/MODELSIM/LINUX/novas_fli.so

view:
	vsim -view vsim.wlf -do wave.do

#nWave:
#	nWave -f proj1.fsdb

debug: clean compile simulate

#vsim -c TESTBED -pli /mnt/apps/public/COE/synopsys_apps/verdi_vr-2020_12-SP2-1/share/PLI/MODELSIM/LINUX64/novas_fli.so -64 -do "run -all"
