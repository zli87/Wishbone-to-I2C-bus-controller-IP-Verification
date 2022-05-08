`timescale 1ns / 10ps

module top();

parameter int WB_ADDR_WIDTH = 2;
parameter int WB_DATA_WIDTH = 8;
parameter int NUM_I2C_BUSSES = 16;
// *****************************************
// Name Offset Access Description
// CSR  0x00   R/W    Control/Status Register
// DPR  0x01   R/W    Data/Parameter Register
// CMDR 0x02   R/W    Command Register
// FSMR 0x03   RO     FSM States Register
// *****************************************
typedef enum logic  [1:0] {
    CSR = 2'd0,
    DPR = 2'd1,
    CMDR = 2'd2,
    FSMR = 2'd3
} REG_OFST;

bit  clk;
bit  rst = 1'b1;
wire cyc;
wire stb;
wire we;
tri1 ack;
wire [WB_ADDR_WIDTH-1:0] adr;
wire [WB_DATA_WIDTH-1:0] dat_wr_o;
wire [WB_DATA_WIDTH-1:0] dat_rd_i;
wire irq;
tri  [NUM_I2C_BUSSES] scl;
tri  [NUM_I2C_BUSSES] sda;

// define temp variable
logic [WB_ADDR_WIDTH-1:0] addr_p;
logic [WB_DATA_WIDTH-1:0] data_p;
logic we_p;

// ****************************************************************************
// Clock generator
initial begin : clk_gen
    clk = 0;
    forever #5 clk = ~clk;
end

// ****************************************************************************
// Reset generator
initial begin : rst_gen
    #113 rst = 0;
end

// ****************************************************************************
// Monitor Wishbone bus and display transfers in the transcript
initial begin : wb_monitoring
    $timeformat(-9, 2, " ns", 6);
    wb_bus.master_monitor(addr_p,data_p,we_p);
    $display("============== transaction at %t ns ==============",$time);
    $display("addr: %h",addr_p);
    $display("data: %h",data_p);
    $display("we:   %b", we_p);
    $display("======================================================");
end

// ****************************************************************************
// Define the flow of the simulation
task wait_done();
    wait(irq);
    // read CMDR to clear irq bit
    wb_bus.master_read(CMDR,data_p);
endtask

initial begin : test_flow
    @(negedge rst);
    repeat(3) @(posedge clk);

    // reset core
    //wb_bus.master_write(CSR_ADDR_OFST,8'b0xxxxxxx);

    // enable core and interrupt
    wb_bus.master_write(CSR,8'b11xxxxxx);

    // store parameter, I2C Bus ID = 5
    wb_bus.master_write(DPR,8'h05);
    // set Bus command
    wb_bus.master_write(CMDR,8'bxxxxx110);
    wait_done();

    // Start command
    wb_bus.master_write(CMDR,8'bxxxxx100);
    wait_done();

    // store parameter
    wb_bus.master_write(DPR,8'h44);
    // Write command
    wb_bus.master_write(CMDR,8'bxxxxx001);
    wait_done();

    // store parameter
    wb_bus.master_write(DPR,8'h78);
    // Write command
    wb_bus.master_write(CMDR,8'bxxxxx001);
    wait_done();

    // Stop command
    wb_bus.master_write(CMDR,8'bxxxxx001);
    wait_done();

    #100 $finish;
end

initial begin : end_flow
#200000 $display("run out of time");
$finish;
end
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

REG_OFST adr_ii;
assign adr_ii = REG_OFST'(adr);
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
    // -- I2C interfaces:
    .scl_i(scl),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Clock inputs
    .sda_i(sda),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Data inputs
    .scl_o(scl),         //   out std_logic_vector(0 to g_bus_num - 1); -- I2C Clock outputs
    .sda_o(sda)          //   out std_logic_vector(0 to g_bus_num - 1)  -- I2C Data outputs
    // ------------------------------------
  );

initial begin : dumpfsdb
  //	$dumpfile("count.vcd"); 	// waveforms in this file..
  //	$dumpvars; 			// saves all waveforms
      $fsdbDumpfile("counter.fsdb"); 	// waveforms in this file..
      $fsdbDumpvars(0,"+mda");     	// saves all waveforms
end

endmodule
