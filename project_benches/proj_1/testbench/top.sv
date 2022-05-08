`timescale 1ns / 10ps
module top();
`ifdef TERMINAL
`define displayY(x) $display("\033[93m%s\033[0m",x);
`else
`define displayY(x) $display("%s",x);
`endif
parameter int WB_ADDR_WIDTH = 2;
parameter int WB_DATA_WIDTH = 8;

// ****************************************************************************
// define your parameter below

parameter int CLK_PERIOD = 10;
parameter int RESET_DELAY = 113;
parameter int MAX_SIMULATION_TIME = 100000000;

parameter int NUM_I2C_BUSSES = 1;
parameter int I2C_ADDR_WIDTH = 7;
parameter int I2C_DATA_WIDTH = 8;
parameter int I2C_SLAVE_ADDRESS = 7'h22;

parameter int MAX_TEST_ROUND_1 = 32;
parameter int MAX_TEST_ROUND_2 = 32;
parameter int MAX_TEST_ROUND_3 = 64;

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
tri  [NUM_I2C_BUSSES-1:0] scl;
tri  [NUM_I2C_BUSSES-1:0] sda;

// ****************************************************************************
//  Define Your Data Type below

typedef enum bit {
    PRINT       =1,
    NO_PRINT    =0
} print_t;

typedef enum bit {
    OP_READ     =1,
    OP_WRITE    =0
} i2c_op_t;

// *****************************************
// Name Offset Access Description
// CSR  0x00   R/W    Control/Status Register
// DPR  0x01   R/W    Data/Parameter Register
// CMDR 0x02   R/W    Command Register
// FSMR 0x03   RO     FSM States Register
// *****************************************
typedef enum logic [1:0] {
    CSR         = 2'd0,
    DPR         = 2'd1,
    CMDR        = 2'd2,
    FSMR        = 2'd3,
    X           = 2'dx
} iicmb_reg_ofst_t;

typedef enum logic [2:0] {
    CMD_SET_BUS     = 3'b110,
    CMD_START       = 3'b100,
    CMD_WRITE       = 3'b001,
    CMD_STOP        = 3'b101,
    CMD_READ_W_NAK  = 3'b011,
    CMD_READ_W_AK   = 3'b010,
    CMD_WAIT        = 3'b000,
    XX              = 3'dx
} iicmb_cmdr_t;

typedef enum bit [7:0] {
    CSR_E           = 8'b10000000,
    CSR_IE          = 8'b01000000,
    CSR_BB          = 8'b00100000,
    CSR_BC          = 8'b00010000,
    CSR_BUS_ID      = 8'b00001111
} iicmb_csr_t;
// ****************************************************************************
//  Define Your Variable below
//string  map_color [ string ] = '{
//    "BRIGHT_RED"      : "91",
//    "BRIGHT_GREEN"    : "92",
//    "BRIGHT_YELLOW"   : "93",
//    "BRIGHT_CYAN"     : "96"
//};
//$display("\033[%smHello\033[0m",map_color["BRIGHT_YELLOW"]);

string  map_reg_ofst_name [ iicmb_reg_ofst_t ] = '{
    CSR             :   "CSR" ,
    DPR             :   "DPR" ,
    CMDR            :   "CMDR",
    FSMR            :   "FSMR"
};
string  map_cmd_name [ iicmb_cmdr_t ] = '{
    CMD_SET_BUS     :   "CMD_SET_BUS",
    CMD_START       :   "CMD_START",
    CMD_WRITE       :   "CMD_WRITE",
    CMD_STOP        :   "CMD_STOP",
    CMD_READ_W_NAK  :   "CMD_READ_W_NAK",
    CMD_READ_W_AK   :   "CMD_READ_W_AK",
    CMD_WAIT        :   "CMD_WAIT"
};

string  map_we_name [ bit ] = '{ 0: "READ", 1: "WRITE" };
string  map_op_name [ bit ] = '{ 1: "READ", 0: "WRITE" };

integer             i,j,k;
print_t             flg_print = NO_PRINT;
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
  .scl_s(scl[0]),
  .sda_s(sda[0])
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

`ifdef FSDB
initial begin : dumpfsdb
  //	$dumpfile("count.vcd"); 	// waveforms in this file..
  //	$dumpvars; 			// saves all waveforms
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
// Monitor Wishbone bus and display transfers in the transcript
initial begin : wb_monitoring
    logic [WB_ADDR_WIDTH-1:0] addr_p;
    logic [WB_DATA_WIDTH-1:0] data_p;
    logic we_p;

    #113 //forever
    begin
        wb_bus.master_monitor(addr_p,data_p,we_p);
        if( flg_print ) begin
            $display("================================================\n\
WB transaction at %t\n\
addr: %s\n\
data: %h\n\
we:   %s\n\
====================================================="
            , $time, map_cmd_name[iicmb_reg_ofst_t'(addr_p)], data_p, map_we_name[we_p]);
        end
    end
end
// ****************************************************************************
// Define the flow of the simulation
task wait_done();
    logic [WB_DATA_WIDTH-1:0] data_p;

    wait(irq);
    // read CMDR to clear irq bit
    wb_bus.master_read(CMDR,data_p);
endtask

initial begin : driver_wb_bus
    @(negedge rst);
    repeat(3) @(posedge clk);

    // reset core
    //wb_bus.master_write(CSR_ADDR_OFST,8'b0xxxxxxx);

    // enable core and interrupt
    wb_bus.master_write( CSR, CSR_E | CSR_IE );

    // store parameter, I2C Bus ID = 5
    wb_bus.master_write( DPR,8'h05 );

    // set Bus command
    wb_bus.master_write( CMDR, {5'bx,CMD_SET_BUS} );
    wait_done();

//=============================================================
//  write 32 values from i2c bus
//=============================================================

    `displayY("\n--------------------------------------------------------\n\
 Write 32 incrementing values \n\
--------------------------------------------------------\n");
    WB_start();
    WB_write( {I2C_SLAVE_ADDRESS, OP_WRITE} );
    for(int i=0;i< MAX_TEST_ROUND_1 ;i=i+1)
        WB_write( i, PRINT );
    WB_stop();

//=============================================================
//  read 32 values from i2c bus
//=============================================================
    `displayY("\n--------------------------------------------------------\n\
 Read 32 values from the i2c_bus \n\
--------------------------------------------------------\n");
    WB_start();
    WB_write( {I2C_SLAVE_ADDRESS, OP_READ} );
    for(int i=0;i< MAX_TEST_ROUND_2;i=i+1) begin
        automatic bit [I2C_DATA_WIDTH-1:0] data;
        WB_read( data, PRINT, (i==MAX_TEST_ROUND_2-1) );
        assert( data == (8'd100 + i) ) begin end else $fatal("wrong data= %d, ans= %d",data,(8'd100 + i));
    end
    WB_stop();

//=============================================================
//  Alternate writes and reads for 64 transfers
//=============================================================
    `displayY("\n--------------------------------------------------------\n\
 Alternate writes and reads for 64 transfers \n\
--------------------------------------------------------\n");
    for(int i=0;i< MAX_TEST_ROUND_3 ;i=i+1) begin
        automatic bit [I2C_DATA_WIDTH-1:0] data;
        WB_start();
        WB_write( {I2C_SLAVE_ADDRESS, OP_WRITE} );
        WB_write( 8'd64 + i, PRINT );
        WB_start();
        WB_write( {I2C_SLAVE_ADDRESS, OP_READ} );
        WB_read( data, PRINT );
        assert( data == (8'd63 - i) ) begin end else $fatal("wrong data= %d, ans= %d",data,(8'd63 - i));
    end
    WB_stop();
    `displayY("\n--------------------------------------------------------\n\
 Finish Project 1 \n\
--------------------------------------------------------\n");
    #2000 $finish;
end

task WB_start();
    wb_bus.master_write( CMDR, {5'bx,CMD_START} );
    wait_done();
endtask

task WB_stop();
    wb_bus.master_write( CMDR, {5'bx,CMD_STOP} );
    wait_done();
endtask

task WB_write( input logic [WB_DATA_WIDTH-1:0] data_w, input print_t _en_print_=NO_PRINT );

    // store parameter: slave address
    wb_bus.master_write(DPR, data_w );

    // Write command
    wb_bus.master_write(CMDR, {5'bx,CMD_WRITE} );
    wait_done();
    if(_en_print_) $display("\
WB_BUS WRITE Transfer: [%0t]\n\
data : %d\n\
---------------------------------------------",$time, data_w );
endtask

task WB_read( output logic [WB_DATA_WIDTH-1:0] data_r, input print_t _en_print_=NO_PRINT, input logic last=1  );

    // Read command with Ack or Nak
    wb_bus.master_write( CMDR, {5'bx, CMD_READ_W_AK ^ last } );
    wait_done();

    // Read DPR to get received byte of data
    wb_bus.master_read( DPR, data_r );
    if(_en_print_) $display("\
WB_BUS READ Transfer: [%0t]\n\
data : %d\n\
---------------------------------------------",$time, data_r );

    //$display("[info] wb master read DPR, data =%x =%b",data_r,data_r);
endtask

initial begin : time_limit_flow
#(MAX_SIMULATION_TIME) $fatal("[%t] run out of time!!!",$time);
$finish;
end

initial begin : monitor_i2c_bus
    bit [I2C_ADDR_WIDTH-1:0] addr;
    bit op;
    bit [I2C_DATA_WIDTH-1:0] data [];
    #113    forever begin
        i2c_bus.monitor(addr,op,data);
        $display("\
I2C_BUS %s Transfer: [%0t]\n\
addr = %h\n\
op   = %b\n\
data = %p\n\
---------------------------------------------",map_op_name[i2c_op_t'(op)],$time,addr,op, data);
    end
end

initial begin : driver_i2c_bus
    bit i2c_op;
    bit [I2C_DATA_WIDTH-1:0] write_data [];
    bit [I2C_DATA_WIDTH-1:0] read_data [];
    bit transfer_complete;

    // slave wait for master write
    i2c_bus.wait_for_i2c_transfer(i2c_op,write_data);
    foreach(write_data[i]) if ( i < MAX_TEST_ROUND_1 ) assert( i == write_data[i] ) begin end else $fatal("wrong write data!");


    // slave wait for master read
    i2c_bus.wait_for_i2c_transfer(i2c_op,write_data);
    if( i2c_op == OP_READ ) begin
        read_data = new [1];
        read_data[0] = 8'd100;
        do begin
            i2c_bus.provide_read_data(read_data,transfer_complete);
            read_data[0] = read_data[0] + 1;
        end while(!transfer_complete);
    end

    read_data = new [1];
    for(int i=0;i<MAX_TEST_ROUND_3;i=i+1)begin

        // slave wait for master write
        i2c_bus.wait_for_i2c_transfer(i2c_op,write_data);
        assert( i2c_op == 0) begin end else $fatal("i2c_op is not write");
        assert( write_data[0] == (signed'(8'd64) + i) ) begin end else $fatal("write data not match");

        // slave wait for master read
        i2c_bus.wait_for_i2c_transfer(i2c_op,write_data);
        assert( i2c_op == 1) begin end else $fatal("i2c_op is not read");
        read_data[0] = 8'd63 - i;
        i2c_bus.provide_read_data( read_data , transfer_complete );
    end
end

endmodule
