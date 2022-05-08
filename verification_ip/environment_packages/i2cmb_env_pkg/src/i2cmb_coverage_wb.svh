class i2cmb_coverage_wb extends ncsu_component #(.T(wb_transaction));

i2cmb_env_configuration cfg0;

//*****************************************************************
// variable for wishbone coverage

iicmb_reg_ofst_t wb_addr;
iicmb_cmdr_t iicmb_cmd;
wb_op_t wb_op;
bit [WB_DATA_WIDTH-1:0] wb_data;
CSR_REG csr_reg;
CMDR_REG cmdr_reg;
event sample_wb;
event sample_CSR;
event sample_DPR;
event sample_CMDR;

//*****************************************************************
// covergroups for whishbone

covergroup env_coverage @(sample_wb);
	wb_addr_offset: coverpoint wb_addr; 	// c1.auto[CSR],c1.auto[DPR],c1.auto[CMDR],c1.auto[FSMR]
	wb_operation: coverpoint wb_op; 		// c2.auto[WB_READ],c2.auto[WB_WRITE]
	wb_addrXop: cross wb_addr_offset, wb_operation;
endgroup

covergroup CSR_coverage @(sample_CSR);
	CSR_Enable_bit: coverpoint csr_reg.e;
	CSR_Interrupt_Enable_bit: coverpoint csr_reg.ie;
	CSR_Bus_Busy_bit: coverpoint csr_reg.bb;
	CSR_Bus_Captured_bit: coverpoint csr_reg.bc;
	CSR_Bus_ID_bits: coverpoint csr_reg.bus_id { option.auto_bin_max = 4; }
endgroup

covergroup DPR_coverage @(sample_DPR);
	// Create 4 automatic bins, each bins cover 256/4= 64 values
	DPR_Data_Value: coverpoint wb_data { option.auto_bin_max = 4; }
endgroup

covergroup CMDR_coverage @(sample_CMDR);
	CMDR_Done_bit: coverpoint cmdr_reg.don iff(wb_op==WB_READ);
	CMDR_Nak_bit: coverpoint cmdr_reg.nak iff(wb_op==WB_READ);
	CMDR_Arbitration_Lost_bit: coverpoint cmdr_reg.al iff(wb_op==WB_READ);
	CMDR_Error_Indication_bit: coverpoint cmdr_reg.err iff(wb_op==WB_READ);
	// reserve bit has no functionality, never assert
	//CMDR_Reserved_bit: coverpoint cmdr_reg.r iff(wb_op==WB_READ && wb_addr==CMDR);
	CMDR_Command_bits: coverpoint cmdr_reg.cmd iff (wb_op == WB_READ){ ignore_bins no_used_command = {CMD_NO_USED}; }
	CMDR_Command_transfer: coverpoint cmdr_reg.cmd iff (wb_op == WB_WRITE){
		bins legal_trans[] = (CMD_SET_BUS=>CMD_SET_BUS), (CMD_SET_BUS=>CMD_START), (CMD_SET_BUS=>CMD_STOP), (CMD_SET_BUS=>CMD_WAIT),
							(CMD_START=>CMD_START), (CMD_START=>CMD_WRITE), (CMD_START=>CMD_STOP),
							(CMD_STOP=>CMD_START), (CMD_STOP=>CMD_SET_BUS), (CMD_STOP=>CMD_WAIT),
							(CMD_WRITE=>CMD_WRITE), (CMD_WRITE=>CMD_STOP), (CMD_WRITE=>CMD_START), (CMD_WRITE=>CMD_READ_W_NAK), (CMD_WRITE=>CMD_READ_W_AK),
							(CMD_READ_W_AK=>CMD_READ_W_AK), (CMD_READ_W_AK=>CMD_READ_W_NAK), (CMD_READ_W_AK=>CMD_START), (CMD_READ_W_AK=>CMD_STOP),
							(CMD_READ_W_NAK=>CMD_START), (CMD_READ_W_NAK=>CMD_STOP),
							(CMD_WAIT=>CMD_WAIT), (CMD_WAIT=>CMD_SET_BUS), (CMD_WAIT=>CMD_START), (CMD_WAIT=>CMD_STOP);
	}
endgroup


function void set_configuration(i2cmb_env_configuration cfg);
	cfg0 = cfg;
endfunction

function new(string name= "", ncsu_component_base parent = null);
	super.new(name, parent);
	env_coverage = new;
	CSR_coverage = new;
	DPR_coverage = new;
	CMDR_coverage = new;
endfunction

virtual function void nb_put(T trans);
	// wb_irq_transaction should not count to coverage.
	if(trans.get_type_handle()==wb_transaction::get_type())begin
		$cast( wb_op , trans.get_op());
		$cast( wb_addr, trans.get_addr());
		wb_data =  trans.get_data_0();

		{cmdr_reg.don, cmdr_reg.nak, cmdr_reg.al, cmdr_reg.err, cmdr_reg.r, cmdr_reg.cmd} = wb_data;
		{csr_reg.e, csr_reg.ie, csr_reg.bb, csr_reg.bc, csr_reg.bus_id} = wb_data;
		if(wb_op == WB_READ && wb_addr==CMDR) assert(cmdr_reg.r == 1'b0) begin end else $fatal("CMDR reserved bit should never be asserted.");

		if(wb_addr==CSR)	->>sample_CSR;
		if(wb_addr==DPR) ->>sample_DPR;
		if(wb_addr==CMDR) ->>sample_CMDR;
		//$display("ENV COVERAGE/ cmdr_reg: %p trans.wb_data: %b", cmdr_reg,wb_data));
		->>sample_wb;
	end
endfunction


endclass
