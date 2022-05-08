// ****************************************************************************
//  Define Macro
`define GET_I2C_OP(x) i2c_op_t'(x.get_op()[0])
`define GET_I2C_ADDR(x) (x.get_addr()[I2C_ADDR_WIDTH-1:0])
`define GET_I2C_DATA(x) (x.get_data())
