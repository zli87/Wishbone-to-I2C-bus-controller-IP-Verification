class i2cmb_predictor extends ncsu_component#(.T(wb_transaction));

ncsu_component#(i2c_transaction) sb0;
i2cmb_env_configuration cfg0;
i2c_transaction pred_i2c, empty_trans;

//---------------------------------------------------------------------------------------
// DUT status simulator related signals

BYTE_FSM_STATE state_c; // current
BYTE_FSM_STATE state_n; // next, ! state change after all execution finish in current function call

logic [8-1:0] dpr_reg;
CMDR_REG cmdr_reg;
CSR_REG csr_reg;
FSMR_REG fsmr_reg; // ! only predict byte fsm state
bit [4-1:0] bus_id;
bit cmd_w_flg [iicmb_reg_ofst_t]; // write command flag
bit cmd_r_flg [iicmb_reg_ofst_t]; // read command flag

//---------------------------------------------------------------------------------------
// i2c bus related signals
// ! note:
// Because it is too complicate to connect predictor with i2c bus, this simulator
// currently comment out all logic related to i2c bus.
// you can develope an special i2c monitor to capture each i2c "ackowledgement bit" and send to predictor,
bit ack_flg;
//---------------------------------------------------------------------------------------
// i2c transaction predictor related signals
bit en_flg;
bit start_flg;
bit rd_flg;
iicmb_reg_ofst_t    wb_addr;
iicmb_cmdr_t        wb_cmd;
bit [WB_DATA_WIDTH-1:0]         wb_data;
wb_op_t             wb_op;
bit[I2C_DATA_WIDTH-1:0] data_buffer[$];
bit i2c_addr_flg;   // if an i2c transaction has recieved address, assert this flag.

function new(string name="", ncsu_component_base parent = null);
	super.new(name, parent);
	state_c = S_IDLE;

    en_flg =0;
    start_flg =0;
    bus_id =0;
    i2c_addr_flg =0;
endfunction

function void set_configuration(i2cmb_env_configuration cfg);
	cfg0 = cfg;
endfunction

virtual function void set_scoreboard(ncsu_component#(i2c_transaction) scoreboard);
	this.sb0 = scoreboard;
endfunction

function void set_cmd_flg( wb_op_t op, iicmb_reg_ofst_t addr);
	cmd_w_flg[CSR] = (op==WB_WRITE)&&(addr==CSR);
	cmd_w_flg[DPR] = (op==WB_WRITE)&&(addr==DPR);
	cmd_w_flg[CMDR] = (op==WB_WRITE)&&(addr==CMDR);
	cmd_w_flg[FSMR] = (op==WB_WRITE)&&(addr==FSMR);
	cmd_r_flg[CSR] = (op==WB_READ)&&(addr==CSR);
	cmd_r_flg[DPR] = (op==WB_READ)&&(addr==DPR);
	cmd_r_flg[CMDR] = (op==WB_READ)&&(addr==CMDR);
	cmd_r_flg[FSMR] = (op==WB_READ)&&(addr==FSMR);
endfunction

virtual function void nb_put(T trans);
	// Simulator will ignore any request during "fsm functionality test".
	// Since simulator does not connect to i2c bus, it can not detect any arbitration lost and simulator failed.
	if( cfg0.get_name() == "i2cmb_generator_fsm_functionality_test" ) return;

	if( trans.get_type_handle() == wb_transaction::get_type() )begin

	    $cast(wb_op, trans.get_op());
	    $cast(wb_addr, trans.get_addr());
	    $cast(wb_data, trans.get_data_0());
	    if(wb_addr==CMDR) wb_cmd = iicmb_cmdr_t'(wb_data[2:0]);
		set_cmd_flg(wb_op, wb_addr);
	end
//---------------------------------------------------------------------------------------
// DUT Byte-level FSM Simulator
//---------------------------------------------------------------------------------------
	if( trans.get_type_handle() == wb_transaction::get_type() )begin

		if(cmd_w_flg[CSR])begin
			if(!wb_data[7]) state_n=S_IDLE; // clear enable bit == reset iicmb core
		end
		if(state_c == S_IDLE)begin
			if(cmd_w_flg[CMDR])begin
				if(wb_cmd==CMD_START) state_n = S_BUS_TAKEN;
			end
		end
		else if(state_c == S_BUS_TAKEN)begin
			if(cmd_w_flg[CMDR])begin
				if(wb_cmd==CMD_SET_BUS) state_n = S_BUS_TAKEN;
				if(wb_cmd==CMD_WAIT) state_n = S_BUS_TAKEN;
				if(wb_cmd==CMD_STOP) state_n = S_IDLE;
				if(wb_cmd==CMD_START) state_n = S_BUS_TAKEN;
				if(wb_cmd==CMD_WRITE) state_n = S_WRITE_BYTE;
				if(wb_cmd==CMD_READ_W_AK) state_n = S_READ_BYTE;
				if(wb_cmd==CMD_READ_W_NAK) state_n = S_READ_BYTE;
			end
		end
	end // end if wb trans type
	else if( trans.get_type_handle() == wb_irq_transaction::get_type() )begin

		if(state_c==S_WRITE_BYTE) state_n = S_BUS_TAKEN;
		if(state_c==S_READ_BYTE) state_n = S_BUS_TAKEN;
	end // end if irq trans type

//---------------------------------------------------------------------------------------
// DUT Registers Simulator (predict the golden value of 4 registers)
//---------------------------------------------------------------------------------------
	if( trans.get_type_handle() == wb_transaction::get_type() )begin

		if(cmd_w_flg[DPR]) dpr_reg = wb_data;
		if(cmd_w_flg[CMDR]) cmdr_reg.cmd = wb_cmd;
		if(cmd_w_flg[CMDR] && (wb_data[2:0]==3'd7)) cmdr_reg.err = 1'b1;

		if(cmd_w_flg[CSR])begin
			csr_reg.e = wb_data[7];
			csr_reg.ie = wb_data[6];
		end
		if(state_c == S_IDLE)begin
			if(cmd_w_flg[CMDR])begin
				if(wb_cmd==CMD_STOP) cmdr_reg.err = 1'b1;
				if(wb_cmd==CMD_WRITE) cmdr_reg.err = 1'b1;
				if(wb_cmd==CMD_READ_W_AK) cmdr_reg.err = 1'b1;
				if(wb_cmd==CMD_READ_W_NAK) cmdr_reg.err = 1'b1;
				if(wb_cmd==CMD_SET_BUS && dpr_reg >= NUM_I2C_BUSSES ) cmdr_reg.err = 1'b1;
			end
		end
		else if(state_c == S_BUS_TAKEN)begin
			if(cmd_w_flg[CMDR])begin
				if(wb_cmd==CMD_SET_BUS) cmdr_reg.err = 1'b1;
				if(wb_cmd==CMD_WAIT) cmdr_reg.err = 1'b1;
			end
		end
	end // end if wb trans type
	else if( trans.get_type_handle() == wb_irq_transaction::get_type() )begin
		// this simulator does not simulate nak bit!
		// if(state_c==S_WRITE_BYTE) cmdr_reg.nak = !ack_flg;
	end // end if irq trans type

	fsmr_reg.byte_fsm = state_n;

//---------------------------------------------------------------------------------------
// i2c transaction Predictor (the same logic from Proj2)
//---------------------------------------------------------------------------------------
	if( trans.get_type_handle() == wb_transaction::get_type() )begin

		if(csr_reg.e && (state_c==S_BUS_TAKEN) )begin
			if( cmd_w_flg[CMDR] ) begin // write CMDR

					if( wb_cmd == CMD_WRITE ) begin
						assert( (!i2c_addr_flg) || (i2c_addr_flg && (pred_i2c.i2c_op==I2C_WRITE)) );

						// not yet recieved i2c address, recieve an i2c address
						if(!i2c_addr_flg) begin
							$cast( pred_i2c, ncsu_object_factory::create("i2c_transaction"));
							$cast( pred_i2c.i2c_op ,dpr_reg[0]);
							i2c_addr_flg=1;
							pred_i2c.i2c_addr = dpr_reg[7:1];

						// already recieve i2c address, recieve data byte
						end else if( pred_i2c.i2c_op == I2C_WRITE )
							data_buffer.push_back(dpr_reg);

					end
					// start read from i2c slave, must recieved an i2c address before!
					if( wb_cmd==CMD_READ_W_AK || wb_cmd==CMD_READ_W_NAK ) begin
						assert(i2c_addr_flg && (pred_i2c.i2c_op==I2C_READ));
						rd_flg = 1;
					end
					// match terminate conditions, terminate capture data and send whole transaction to scoreboard
					if( wb_cmd == CMD_START || wb_cmd == CMD_STOP ) begin
						if(i2c_addr_flg) begin
							void'(pred_i2c.set_data( data_buffer ));
							sb0.nb_transport( pred_i2c, empty_trans );
							data_buffer.delete;
						end
					end

			end // end if write CMDR
			else if( cmd_r_flg[DPR] ) begin
					// if generator requested a read command before and generator now read out DPR from DUT,
					// predictor observe DPR value from wishbone bus line (wb_data).
					if(rd_flg) data_buffer.push_back(wb_data);
					rd_flg = 0;
			end // end if read DPR
//---------------------------------------------------------------------------------------
// finish all process of i2c trans predictor, update control flags
			if(cmd_w_flg[CMDR] && wb_cmd==CMD_START) begin   i2c_addr_flg=0; end
			if(cmd_w_flg[CMDR] && wb_cmd==CMD_STOP)  begin   i2c_addr_flg=0; end
		end // end if enable
	end


//---------------------------------------------------------------------------------------
// finish all process of current function call, update fsm state and flag
	state_c = state_n;
	if( trans.get_type_handle() == wb_irq_transaction::get_type() ) ack_flg = 0;
endfunction

//----------------------------------------------------------------------------------------
// these function can be used to obtain information from i2c bus
// current proj4 does not have connection between predictor with i2c bus, they are just a prototype.
//
// function void i2c_capture_read_byte(bit [8-1:0] _data_);
// 	dpr_reg = _data_;
// endfunction
//
// function void i2c_capture_ack();
// 	ack_flg = 1;
// endfunction

endclass
