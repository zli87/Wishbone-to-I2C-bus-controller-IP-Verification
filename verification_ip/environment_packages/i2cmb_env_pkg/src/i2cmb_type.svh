parameter bit [7:0] I2C_BUS_ID = 8'h05;
parameter int NUM_I2C_BUSSES = 13;

typedef enum bit [3:0] {
       S_IDLE           = 4'd0,
       S_BUS_TAKEN      = 4'd1,
       S_START_PENDING  = 4'd2,
       S_START          = 4'd3,
       S_STOP           = 4'd4,
       S_WRITE_BYTE     = 4'd5,
       S_READ_BYTE      = 4'd6,
       S_WAIT           = 4'd7
} BYTE_FSM_STATE;

typedef enum bit [0:3] {
       SS_IDLE          = 4'd0,
       SS_START_A       = 4'd1,
       SS_START_B       = 4'd2,
       SS_START_C       = 4'd3,
       SS_RW_A          = 4'd4,
       SS_RW_B          = 4'd5,
       SS_RW_C          = 4'd6,
       SS_RW_D          = 4'd7,
       SS_RW_E          = 4'd8,
       SS_STOP_A        = 4'd9,
       SS_STOP_B        = 4'd10,
       SS_STOP_C        = 4'd11,
       SS_RSTART_A      = 4'd12,
       SS_RSTART_B      = 4'd13,
       SS_RSTART_C      = 4'd14
} BIT_FSM_STATE;

// ****************************************************************************
// Define register structure

typedef struct{
    bit don;
    bit nak;
    bit al;
    bit err;
    bit r;
    iicmb_cmdr_t cmd;
} CMDR_REG;

typedef struct{
    bit e;
    bit ie;
    bit bb;
    bit bc;
    bit [3:0] bus_id;
} CSR_REG;

typedef struct{
    BYTE_FSM_STATE   byte_fsm;
    bit [3:0]   bit_fsm;
} FSMR_REG;

string map_state_name[ BYTE_FSM_STATE ] = '{
    S_IDLE: "S_IDLE",
    S_BUS_TAKEN: "S_BUS_TAKEN"
};
