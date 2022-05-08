class i2cmb_generator_fsm_functionality_test extends i2cmb_generator;
	`ncsu_register_object(i2cmb_generator_fsm_functionality_test)

time time_start,time_end;
bit [7:0] wait_time;

function new(string name="", ncsu_component_base parent=null);
	super.new(name, parent);
endfunction

virtual task run();

    //=================================================================
    // possible reponses to byte-level commands
    //              |  done | arb. lost | no ack | byte | error |
    // start        |   +   |   +       |        |      |       |
    // stop         |   +   |           |        |      |       |
    // read with ack|       |           |        |  +   |   +   |
    // read with nak|       |   +       |        |  +   |   +   |
    // write        |   +   |   +       |   +    |      |   +   |
    // set bus      |   +   |           |        |      |   +   |
    // wait         |   +   |           |        |      |   +   |
    //=================================================================
	// Definition of arbitration lost:
	// 		i2c slave pull down SDA when it should not. The master detects this as an arbitration lost event and stops the transfer.
	// https://www.i2c-bus.org/i2c-primer/analysing-obscure-problems/master-reports-arbitration-lost/


	//=================================================================
	// TEST PLAN
	//
	// test plan section 2.2: Bus ID check through CMDR register
	//		=> case 1.2:   state{idle} -> cmd[set bus] -> resp{done, error}

	// test plan section 2.3: Byte FSM transition
	//		=> all case

	// test plan section 2.4: Illegal Command Sequence
	// 		=> case 1.1:   state{idle} -> cmd[stop, read, write] -> resp{error} -> state{idle}
    // 		=> case 2.5 :  state{taken} -> cmd[set bus, wait] -> resp{error}

	// test plan section 2.5: Arbitration Lost generation
	// 		=> case 3.1:   state{taken} -> cmd[start] -> resp{arb. lost} -> state{idle}
	// 		=> case 3.2:   state{taken} -> cmd[write] -> resp{arb. lost} -> state{idle}
	// 		=> case 3.3:   state{taken} -> cmd[read w/ Nak] -> resp{arb. lost} -> state{idle}

	// test plan section 2.6: No acknowledge detection
	// 		=> case 4.1:   state{taken} -> cmd[write] -> resp{no ack} -> state{taken}

	//=================================================================
	// Content of Table
	//
	//	Case Group 1: TEST OPERATION IN BYTE FSM S_IDLE STATE
    // 		case 1.1:   state{idle} -> cmd[stop, read, write] -> resp{error} -> state{idle}
    // 		case 1.2:   state{idle} -> cmd[set bus] -> resp{done, error}
    // 		case 1.3:   state{idle} -> cmd[wait] -> resp{done}
    // 		case 1.4:   state{idle} -> cmd[start] -> state{taken}
	//
	//	Case Group 2: TEST OPERATION IN BYTE FSM S_BUS_TAKEN STATE
    // 		case 2.1:   state{taken} -> cmd[start] -> state{taken}
	// 		case 2.2:   state{taken} -> cmd[write] -> resp{done} -> state{taken}
    // 		case 2.3:   state{taken} -> cmd[read w/ Ack/Nak] -> resp{done, byte} -> state{taken}
    // 		case 2.4:   state{taken} -> cmd[stop] -> resp{done} -> state{idle}
    // 		case 2.5 :  state{taken} -> cmd[set bus, wait] -> resp{error}
	//
	// Case Group 3: TEST ARBITRATION LOST
	// 		case 3.1:   state{taken} -> cmd[start] -> resp{arb. lost} -> state{idle}
	// 		case 3.2:   state{taken} -> cmd[write] -> resp{arb. lost} -> state{idle}
	// 		case 3.3:   state{taken} -> cmd[read w/ Nak] -> resp{arb. lost} -> state{idle}
	//
	// Case Group 4: TEST NO ACKNOWLEDGE DETECTION
	// 		case 4.1:   state{taken} -> cmd[write] -> resp{no ack} -> state{taken}

    //=================================================================
	// the following two error test cases are impossible to generate through WB interface,
	// verification environment need to access generic interface inside DUT to generate them.
	// Since this course is focus on function test instead of unit test, I decide not test them.

	// case 5.1:   state{taken} -> cmd[write] -> resp{error} -> state{idle}
	// case 5.2:   state{taken} -> cmd[read w/ Ack/Nak] -> resp{error} -> state{idle}

	// test case assumption: assert error bit "when byte fsm state is taken".
	// rule 1. to trigger this error, we need to trigger bit FSM to send a error response to byte FSM when byte FSM state is taken.
	// rule 2. the only way to trigger bit FSM error is sending bit level command [Write 0]/[Write 1]/[Read] when bit FSM is idle.
	// However, when bit fsm state is IDLE, byte FSM is always IDLE.
	// Since rule 1 and rule 2 can not match in the same time, it is impossible to generate these error test case.
    //=================================================================

	$display("--------------------------------------------------------");
    $display("  TEST PLAN 2: I2CMB FSM FUNCTIONALITY TESTS START          ");
    $display("--------------------------------------------------------");

	i2c_data.push_back( 100 );
	i2c_data.push_back( 101 );
	void'(i2c_read_trans.set_data(i2c_data));

	// fork i2c agent thread to generate legal i2c slave signal
	fork   begin i2c_agt0.bl_put( i2c_read_trans ); end join_none
	$display("___________CASE GROUP 1.TEST OPERATION IN BYTE FSM IDLE STATE___________________");
	wb_agt0.bl_put_ref( cmd_en_trans );   // cmd reset
    check_FSM_state(`__LINE__, S_IDLE);

    // case 1.1:   state{idle} -> cmd[stop, read, write] -> resp{error} -> state{idle}

    wb_agt0.bl_put_ref( cmd_stop_trans );     // cmd stop
    check_err_bit( `__LINE__, cmd_stop_trans,"REQUESTING STOP COMMAND IN IDLE STATE");
    check_FSM_state(`__LINE__, S_IDLE);

	void'( trans_w[CMDR].set_data( {5'b0, CMD_READ_W_AK } ));
    wb_agt0.bl_put_ref( trans_w[CMDR] );     // cmd read ack
    check_err_bit( `__LINE__, trans_w[CMDR], "REQUESTING READ ACK COMMAND IN IDLE STATE");
    check_FSM_state(`__LINE__, S_IDLE);

	void'( trans_w[CMDR].set_data( {5'b0, CMD_READ_W_NAK } ) );
    wb_agt0.bl_put_ref( trans_w[CMDR] );     // cmd read Nak
    check_err_bit( `__LINE__, trans_w[CMDR], "REQUESTING READ NAK COMMAND IN IDLE STATE");
    check_FSM_state(`__LINE__, S_IDLE);

    wb_agt0.bl_put_ref( cmd_write_trans );          // cmd write
    check_err_bit( `__LINE__, cmd_write_trans, "REQUESTING WRITE COMMAND IN IDLE STATE");
    check_FSM_state(`__LINE__, S_IDLE);

    // case 1.2:   state{idle} -> cmd[set bus] -> resp{done, error} -> state{idle}
    wb_agt0.bl_put( trans_w[DPR].set_data( 8'h0f ) );
	void'( trans_w[CMDR].set_data( {5'b0,CMD_SET_BUS} ));
    wb_agt0.bl_put_ref( trans_w[CMDR] );
    check_err_bit( `__LINE__, trans_w[CMDR], "INVALID BUS ID");
    check_FSM_state(`__LINE__, S_IDLE);

    wb_agt0.bl_put( trans_w[DPR].set_data( I2C_BUS_ID ) );
	void'( trans_w[CMDR].set_data( {5'b0,CMD_SET_BUS} ) );
    wb_agt0.bl_put_ref( trans_w[CMDR] );
    check_don_bit( `__LINE__, trans_w[CMDR], "SETTING VALID BUS ID");

    check_FSM_state(`__LINE__, S_IDLE);

    // case 1.3:   state{idle} -> cmd[wait] -> resp{done} -> state{idle}

    wait_time = 8'h01;  // wait 16 milisecond,  1 milisecond = 10^6 ns
    wb_agt0.bl_put( trans_w[DPR].set_data( wait_time ) );
	void'( trans_w[CMDR].set_data( {5'b0, CMD_WAIT} ) );
    time_start = $time;
    wb_agt0.bl_put_ref( trans_w[CMDR] );
    time_end = $time;
    // remeber time format is -9, 2. -9 means ns, 2 means print 2 digit after decimal point
    // nanosecond = $time/100
    // milisecond = ($time/100)/10^6 = $time/10^8
    assert( ((time_end - time_start)/100000000) == wait_time ) $display("TEST CASE PASSED: WAIT TIME CORRECT");
    else $fatal("TEST CASE FAILED: WAIT TIME DURATION INCORRECT");

    check_don_bit( `__LINE__,trans_w[CMDR], "FINISHING WAIT COMMAND");
    check_FSM_state(`__LINE__, S_IDLE);

	// reset_core_to_idle_state();

    // case 1.4:   state{idle} -> cmd[start] -> state{taken}

    wb_agt0.bl_put_ref( cmd_start_trans );     // cmd start
    check_don_bit( `__LINE__, cmd_start_trans, "START COMMAND IN INDLE STATE");
    check_FSM_state(`__LINE__, S_BUS_TAKEN);

	$display("___________CASE GROUP 2.TEST OPERATION IN BYTE FSM BUS_TAKEN STATE______________");
    // case 2.1.1:   state{taken} -> cmd[start] -> resp{done} -> state{taken}

	wb_agt0.bl_put_ref( cmd_start_trans );     // cmd start
	check_don_bit( `__LINE__, cmd_start_trans, "START COMMAND IN TAKEN STATE");
	check_FSM_state(`__LINE__, S_BUS_TAKEN);

    // case 2.2.1:   state{taken} -> cmd[write] -> resp{done,no ack} -> state{taken}

	// wb_agt0.bl_put_ref( cmd_start_trans );     // cmd start
	wb_agt0.bl_put(trans_w[DPR].set_data( {I2C_SLAVE_ADDRESS<<1} | bit'(I2C_READ) ) ); //Slave Address and R/W bit
	wb_agt0.bl_put_ref(cmd_write_trans); //Write Command
	check_don_bit( `__LINE__, cmd_write_trans, "WRITE COMMAND IN TAKEN STATE");
	check_FSM_state(`__LINE__,  S_BUS_TAKEN );

    // case 2.3:   state{taken} -> cmd[read w/ Ack/Nak] -> resp{done, byte} -> state{taken}

	void'( trans_w[CMDR].set_data( {5'b0, CMD_READ_W_AK } ) );
    wb_agt0.bl_put_ref( trans_w[CMDR] );     // cmd read ack
    check_don_bit( `__LINE__, trans_w[CMDR], "READ ACK COMMAND IN TAKEN STATE");
    check_FSM_state(`__LINE__,  S_BUS_TAKEN );

	void'( trans_w[CMDR].set_data( {5'b0, CMD_READ_W_AK } ) );
    wb_agt0.bl_put_ref( trans_w[CMDR] );     // cmd read ack
    check_don_bit( `__LINE__, trans_w[CMDR], "READ NAK COMMAND IN TAKEN STATE");
    check_FSM_state(`__LINE__,  S_BUS_TAKEN );

    // case 2.4:   state{taken} -> cmd[stop] -> resp{done} -> state{idle}
    wb_agt0.bl_put_ref( cmd_start_trans );     // cmd start
    wb_agt0.bl_put_ref( cmd_stop_trans );     // cmd stop
    wb_agt0.bl_put_ref( trans_r[CMDR] );  // read error bit
    check_FSM_state(`__LINE__, S_IDLE);

	wb_agt0.bl_put_ref( cmd_start_trans );     // cmd start
    // case 2.5 :   state{taken} -> cmd[set bus, wait] -> resp{error} -> state{taken}

    wb_agt0.bl_put( trans_w[DPR].set_data( I2C_BUS_ID ) );
	void'( trans_w[CMDR].set_data( {5'b0,CMD_SET_BUS} ) );
    wb_agt0.bl_put_ref( trans_w[CMDR] );
	//!! this should be check_err_bit !!!
    check_err_bit( `__LINE__, trans_w[CMDR], "REQUESTING SET BUS ID COMMAND IN TAKEN STATE");
    check_FSM_state(`__LINE__, S_BUS_TAKEN);

    wb_agt0.bl_put( trans_w[DPR].set_data( 8'h01 ) );
	void'( trans_w[CMDR].set_data( {5'b0, CMD_WAIT} ) );
    wb_agt0.bl_put_ref( trans_w[CMDR] );
    check_err_bit( `__LINE__, trans_w[CMDR], "REQUESTING WAIT COMMAND IN TAKEN STATE");
    check_FSM_state(`__LINE__, S_BUS_TAKEN);


	// arbitration lost test
	$display("___________CASE GROUP 3.TEST ARBITRATION LOST___________________________________");
	// fork i2c agent thread to generate illegal i2c slave signal
	reset_core_to_idle_state();

	// case 3.1:   state{taken} -> cmd[start] -> resp{arb. lost} -> state{idle}

	fork
		begin
				i2c_agt0.arb_lost_during_restart();
		end
		begin
				wb_agt0.bl_put_ref(cmd_start_trans);
				WB_address( I2C_WRITE );
				wb_agt0.bl_put( trans_w[DPR].set_data( 8'd100 ) );
				wb_agt0.bl_put( cmd_write_trans ); //

				wb_agt0.bl_put_ref( cmd_start_trans );     // cmd start
				check_al_bit( `__LINE__, cmd_start_trans, "ARB. LOST WHILE REQUESTING START COMMAND IN TAKEN STATE");
				check_FSM_state(`__LINE__, S_IDLE);
		end
	join

	i2c_agt0.reset();
	reset_core_to_idle_state();

	// case 3.2:   state{taken} -> cmd[write] -> resp{arb. lost} -> state{idle}

	fork
		begin
				// do the same as i2c_agt0.bl_put( i2c_write_trans ); but pull SDA low after i2c read byte finish
				i2c_agt0.arb_lost_during_write();
		end
		begin
				wb_agt0.bl_put_ref(cmd_start_trans);
				wb_agt0.bl_put( trans_w[DPR].set_data( 8'h44 ) );
				wb_agt0.bl_put_ref( cmd_write_trans ); //Read with NACK COmmand
				check_al_bit( `__LINE__, cmd_write_trans, "ARB. LOST WHILE WHILE REQUESTING WRITE COMMAND IN TAKEN STATE");
				check_FSM_state(`__LINE__, S_IDLE);
		end
	join
	disable fork;

	i2c_agt0.reset();
	reset_core_to_idle_state();

	// case 3.3:   state{taken} -> cmd[read w/ Nak] -> resp{arb. lost} -> state{idle}

	fork
		begin
				// do the same as i2c_agt0.bl_put( i2c_read_trans ); but pull SDA low after i2c read byte finish
				i2c_agt0.arb_lost_during_read();
		end
		begin
				wb_agt0.bl_put_ref(cmd_start_trans);
				WB_address( I2C_READ );
				void'( trans_w[CMDR].set_data({5'b0, CMD_READ_W_NAK}) );
				wb_agt0.bl_put_ref( trans_w[CMDR] );
				check_al_bit( `__LINE__, trans_w[CMDR], "ARB. LOST WHILE WHILE REQUESTING READ COMMAND IN TAKEN STATE");
				check_FSM_state(`__LINE__, S_IDLE);
		end
	join
	disable fork;
	i2c_agt0.reset();
	reset_core_to_idle_state();

	$display("___________CASE GROUP 4.TEST NO ACKNOWLEDGE DETECTION___________________________________");
	// case 4.1:   state{taken} -> cmd[write] -> resp{no ack} -> state{taken}
	wb_agt0.bl_put_ref(cmd_start_trans);
	wb_agt0.bl_put( trans_w[DPR].set_data( 8'd100 ) );
	wb_agt0.bl_put_ref(cmd_write_trans);
	check_nak_bit( `__LINE__, cmd_write_trans, "NO ACKNOWLEDGE WHILE REQUESTING WRITE COMMAND IN TAKEN STATE");
	check_FSM_state(`__LINE__, S_BUS_TAKEN);

	$display("--------------------------------------------------------");
	$display("  TEST PLAN 2: I2CMB FSM FUNCTIONALITY TESTS PASSED          ");
	$display("--------------------------------------------------------");

endtask

task reset_core_to_idle_state;
	wb_agt0.bl_put( trans_w[CSR].set_data( (~CSR_E) ) );   // cmd reset
	wb_agt0.bl_put( cmd_en_trans );   // cmd reset
	// this is optional, but if we dont set bus id, default id is 0.
	wb_agt0.bl_put( trans_w[DPR].set_data( I2C_BUS_ID ) );
	wb_agt0.bl_put( trans_w[CMDR].set_data( {5'b0,CMD_SET_BUS} ) );
	// check_don_bit( `__LINE__, trans_w[CMDR], "SETTING VALID BUS ID");
endtask

task reset_core_to_taken_state;
	reset_core_to_idle_state();
	wb_agt0.bl_put_ref(cmd_start_trans);
endtask

// virtual task WB_address( input i2c_op_t i2c_op );
//     wb_agt0.bl_put(trans_w[DPR].set_data( {I2C_SLAVE_ADDRESS<<1} | bit'(i2c_op) ) ); //Slave Address and R/W bit
//     wb_agt0.bl_put_ref(cmd_write_trans); //Write Command
// endtask

task check_FSM_state(int line, BYTE_FSM_STATE expected_state );
    automatic BYTE_FSM_STATE actual_state;
    wb_agt0.bl_put_ref( trans_r[FSMR] );
    actual_state = to_fsmr_reg(trans_r[FSMR].wb_data).byte_fsm;
	//$display("[%0t] line:[%3d] , EXPECTED BYTE FSM STATE: %s , ACTUAL BYTE FSM STATE: %s", $time,line ,map_state_name[expected_state], map_state_name[actual_state] );
    assert( actual_state == expected_state ) begin end
    else $fatal("TEST CASE FAILED: EXPECTED BYTE FSM STATE: %s , INSTEAD BYTE FSM STATE IS SET: %s", map_state_name[expected_state], map_state_name[actual_state] );
endtask

task check_don_bit(int line, wb_transaction trans, string msg="TBD");

	//$display("[%0t] line:[%3d] %s, %p",$time,line, msg, to_cmdr_reg(trans.cmdr_data) );
    assert( to_cmdr_reg(trans.cmdr_data).don ) $display( "TEST CASE PASSED: {DON BIT} ASSERTED AS EXPECTED DUE TO %s",msg);
    else $fatal("TEST CASE FAILED: EXPECTED {DON BIT} ASSERTED DUE TO %s, INSTEAD DONE IS 0 !.",msg);
endtask

task check_err_bit(int line, wb_transaction trans, string msg="TBD");

	//$display("[%0t] line:[%3d] %s, %p",$time, line, msg, to_cmdr_reg(trans.cmdr_data) );
    // !TBD: add !don in condition
    assert( to_cmdr_reg(trans.cmdr_data).err ) $display("TEST CASE PASSED: {ERR BIT} ASSERTED AS EXPECTED DUE TO %s",msg);
    else $fatal("TEST CASE FAILED: EXPECTED {ERR BIT} ASSERTED DUE TO %s, INSTEAD DONE IS SET",msg);
endtask

task check_al_bit(int line, wb_transaction trans, string msg="TBD");

	//$display("[%0t] line:[%3d] %s, %p",$time, line, msg, to_cmdr_reg(trans.cmdr_data) );
    // !TBD: add !don in condition
    assert( !to_cmdr_reg(trans.cmdr_data).don && to_cmdr_reg(trans.cmdr_data).al ) $display("TEST CASE PASSED: {AL BIT} ASSERTED AS EXPECTED DUE TO %s",msg);
    else $fatal("TEST CASE FAILED: EXPECTED {AL BIT} ASSERTED DUE TO %s, INSTEAD DONE IS SET",msg);
endtask

task check_nak_bit(int line, wb_transaction trans, string msg="TBD");

	//$display("[%0t] line:[%3d] %s, %p",$time, line, msg, to_cmdr_reg(trans.cmdr_data) );
    // !TBD: add !don in condition
    assert( !to_cmdr_reg(trans.cmdr_data).don && to_cmdr_reg(trans.cmdr_data).nak ) $display("TEST CASE PASSED: {NAK BIT} ASSERTED AS EXPECTED DUE TO %s",msg);
    else $fatal("TEST CASE FAILED: EXPECTED {NAK BIT} ASSERTED DUE TO %s, INSTEAD DONE IS SET",msg);
endtask

endclass
