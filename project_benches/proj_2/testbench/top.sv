`timescale 1ns / 10ps
module top();

import ncsu_pkg::*;
import wb_pkg::*;
import i2c_pkg::*;
import i2cmb_env_pkg::*;

// ****************************************************************************
// define your parameter below

parameter int CLK_PERIOD = 10;
parameter int RESET_DELAY = 113;
parameter int MAX_SIMULATION_TIME = 100000000;

parameter int NUM_I2C_BUSSES = 16;

// ****************************************************************************
// Define variable

bit  clk;
bit  rst = 1'b1;
wire cyc;
wire stb;
wire we;
tri ack;
wire [WB_ADDR_WIDTH-1:0] adr;
wire [WB_DATA_WIDTH-1:0] dat_wr_o;
wire [WB_DATA_WIDTH-1:0] dat_rd_i;
wire irq;
tri  [NUM_I2C_BUSSES] scl;
tri  [NUM_I2C_BUSSES] sda;

integer             i,j,k;

iicmb_reg_ofst_t    adr_enum;
iicmb_cmdr_t        dat_o_enum;

assign adr_enum = iicmb_reg_ofst_t'(adr);
assign dat_o_enum = (adr_enum == CMDR)? iicmb_cmdr_t'(dat_wr_o) : XX ;

// ****************************************************************************
// Instantiate the I2C slave Bus Functional Model
i2c_if      #(
    .I2C_ADDR_WIDTH(I2C_ADDR_WIDTH),
    .I2C_DATA_WIDTH(I2C_DATA_WIDTH),
    .SLAVE_ADDRESS(I2C_SLAVE_ADDRESS)
)
i2c_bus (
  // Slave signals
  .scl_s(scl[ WB_BUS_ID ]),
  .sda_s(sda[ WB_BUS_ID ])
);
// ****************************************************************************
// Instantiate the Wishbone master Bus Functional Model
wb_if       #(
      .ADDR_WIDTH(WB_ADDR_WIDTH),
      .DATA_WIDTH(WB_DATA_WIDTH)
)
wb_bus (
  // System sigals
  .clk_i(clk),
  .rst_i(rst),
  .irq_i(irq),
  // Master signals
  .cyc_o(cyc),
  .stb_o(stb),
  .ack_i(ack),
  .adr_o(adr),
  .we_o(we),
  // Slave signals
  .cyc_i(),
  .stb_i(),
  .ack_o(),
  .adr_i(),
  .we_i(),
  // Shred signals
  .dat_o(dat_wr_o),
  .dat_i(dat_rd_i)
  );


// ****************************************************************************
// Instantiate the DUT - I2C Multi-Bus Controller
\work.iicmb_m_wb(str) #(.g_bus_num(NUM_I2C_BUSSES)) DUT
  (
    // ------------------------------------
    // -- Wishbone signals:
    .clk_i(clk),         // in    std_logic;                            -- Clock
    .rst_i(rst),         // in    std_logic;                            -- Synchronous reset (active high)
    // -------------
    .cyc_i(cyc),         // in    std_logic;                            -- Valid bus cycle indication
    .stb_i(stb),         // in    std_logic;                            -- Slave selection
    .ack_o(ack),         //   out std_logic;                            -- Acknowledge output
    .adr_i(adr),         // in    std_logic_vector(1 downto 0);         -- Low bits of Wishbone address
    .we_i(we),           // in    std_logic;                            -- Write enable
    .dat_i(dat_wr_o),    // in    std_logic_vector(7 downto 0);         -- Data input
    .dat_o(dat_rd_i),    //   out std_logic_vector(7 downto 0);         -- Data output
    // ------------------------------------
    // ------------------------------------
    // -- Interrupt request:
    .irq(irq),           //   out std_logic;                            -- Interrupt request
    // ------------------------------------
    // ------------------------------------
    // -- I2C master interfaces:
    .scl_i(scl),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Clock inputs
    .sda_i(sda),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Data inputs
    .scl_o(scl),         //   out std_logic_vector(0 to g_bus_num - 1); -- I2C Clock outputs
    .sda_o(sda)          //   out std_logic_vector(0 to g_bus_num - 1)  -- I2C Data outputs
    // ------------------------------------
  );

// ****************************************************************************
// Dump waveform if you use synopsys verdi
`ifdef FSDB
initial begin : dumpfsdb
  //	$dumpfile("count.vcd"); 	// waveforms in this file..
  //	$dumpvars; 			        // saves all waveforms
      $fsdbDumpfile("proj1.fsdb"); 	// waveforms in this file..
      $fsdbDumpvars(0,"+mda");     	// saves all waveforms
      $display("[info] enable output fsdb file");
end
`endif

initial    $timeformat(-9, 2, " ns", 6);

// ****************************************************************************
// Clock generator
initial begin : clk_gen
    clk = 0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end

// ****************************************************************************
// Reset generator
initial begin : rst_gen
    #(RESET_DELAY) rst = 0;
end

// ****************************************************************************
// 1. Place an instance of i2cmb_test within top.sv
i2cmb_test tst;

initial begin : test_flow
// 2. Place virtual interface handles into ncsu_config_db
// 3. Construct the test class
// 4. Execute the run task of the test after reset is released
// 5. Execute $finish after test complete

    ncsu_config_db#(virtual wb_if#(.ADDR_WIDTH(WB_ADDR_WIDTH), .DATA_WIDTH(WB_DATA_WIDTH)))::set("wb_interface", wb_bus);
    ncsu_config_db#(virtual i2c_if#(.I2C_ADDR_WIDTH(I2C_ADDR_WIDTH), .I2C_DATA_WIDTH(I2C_DATA_WIDTH)))::set("i2c_interface", i2c_bus);

    tst = new("tst", null);
    wait( rst==0 );
    tst.run();
    #1000ns $finish;
end

// ****************************************************************************
initial begin : time_limit
    #(MAX_SIMULATION_TIME) $fatal("[%t] run out of time!!!",$time);
    $finish;
end

endmodule
