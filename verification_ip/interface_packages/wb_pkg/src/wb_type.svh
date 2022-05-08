// ****************************************************************************
//  Define Parameter
parameter int WB_ADDR_WIDTH = 2;
parameter int WB_DATA_WIDTH = 8;

// ****************************************************************************
// Define enum

typedef enum bit {
    PRINT       =1,
    NO_PRINT    =0
} print_t;

typedef enum bit {
    WB_READ     =0,
    WB_WRITE    =1
} wb_op_t;

// *****************************************
// Name Offset Access Description
// CSR  0x00   R/W    Control/Status Register
// DPR  0x01   R/W    Data/Parameter Register
// CMDR 0x02   R/W    Command Register
// FSMR 0x03   RO     FSM States Register
// *****************************************
typedef enum bit [1:0] {
    CSR         = 2'd0,
    DPR         = 2'd1,
    CMDR        = 2'd2,
    FSMR        = 2'd3
} iicmb_reg_ofst_t;

typedef enum bit [2:0] {
    CMD_SET_BUS     = 3'b110,   // 6
    CMD_START       = 3'b100,   // 4
    CMD_WRITE       = 3'b001,   // 1
    CMD_STOP        = 3'b101,   // 5
    CMD_READ_W_NAK  = 3'b011,   // 3
    CMD_READ_W_AK   = 3'b010,   // 2
    CMD_WAIT        = 3'b000,   // 0
    CMD_NO_USED     = 3'b111   // 7
} iicmb_cmdr_t;

typedef enum bit [7:0] {
    CSR_E           = 8'b10000000,
    CSR_IE          = 8'b01000000,
    CSR_BB          = 8'b00100000,
    CSR_BC          = 8'b00010000,
    CSR_BUS_ID      = 8'b00001111
} iicmb_csr_t;

typedef enum bit [7:0]{
    CMDR_DON_MASK = 8'b10000000,
    CMDR_NAK_MASK = 8'b01000000,
    CMDR_AL_MASK  = 8'b00100000,
    CMDR_ERR_MASK = 8'b00010000,
    CMDR_CMD_MASK = 8'b00000111
} cmdr_mask_t;



// ****************************************************************************
//  Define enum string mapping variable

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

string  map_we_name [ wb_op_t ] = '{
    WB_READ     : "READ",
    WB_WRITE    : "WRITE"
};
