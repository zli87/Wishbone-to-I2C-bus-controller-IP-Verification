`define GET_WB_OP(x) wb_op_t'(x.get_op()[0])
`define GET_WB_ADDR(x) (iicmb_reg_ofst_t'(x.get_addr()[WB_ADDR_WIDTH-1:0]))
`define GET_WB_DATA(x) (x.get_data_0()[WB_DATA_WIDTH-1:0])
