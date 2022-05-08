package i2cmb_env_pkg;
	import ncsu_pkg::*;
	import my_pkg::*;
	import wb_pkg::*;
	import i2c_pkg::*;
	`include "../../ncsu_pkg/ncsu_macros.svh"

	`include "src/i2cmb_type.svh"
	`include "src/i2cmb_generator.svh"
	`include "src/i2cmb_generator_register_test.svh"
	`include "src/i2cmb_generator_control_functionality_test.svh"
	`include "src/i2cmb_generator_fsm_functionality_test.svh"
	`include "src/i2cmb_generator_direct_test.svh"
	`include "src/i2cmb_generator_random_test.svh"
	`include "src/i2cmb_env_configuration.svh"
	`include "src/i2cmb_predictor.svh"
    `include "src/i2cmb_scoreboard.svh"
    `include "src/i2cmb_coverage_wb.svh"
	`include "src/i2cmb_coverage_i2c.svh"
	`include "src/i2cmb_environment.svh"
	`include "src/i2cmb_test.svh"

endpackage
