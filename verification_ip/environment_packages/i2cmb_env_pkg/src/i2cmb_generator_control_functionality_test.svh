class i2cmb_generator_control_functionality_test extends i2cmb_generator;
	`ncsu_register_object(i2cmb_generator_control_functionality_test)

wb_transaction cmd_en_trans;
wb_transaction trans_r[iicmb_reg_ofst_t];
wb_transaction trans_w[iicmb_reg_ofst_t];

i2c_transaction i2c_write_trans, i2c_read_trans;
bit [I2C_DATA_WIDTH-1:0] i2c_data [$];
time time_start,time_end;
bit [7:0] wait_time;

function new(string name="", ncsu_component_base parent=null);
	super.new(name, parent);
	for(int i=3; i>=0; i--) begin
        automatic iicmb_reg_ofst_t addr_ofst = iicmb_reg_ofst_t'(i);
        //ncsu_info("i2cmb_generator_register_test::run()" ,$sformatf("construct transactions for testing %s register.", map_reg_ofst_name[addr_ofst]),NCSU_NONE);
        $cast(trans_r[addr_ofst], ncsu_object_factory::create("wb_transaction"));
        $cast(trans_w[addr_ofst], ncsu_object_factory::create("wb_transaction"));
        // fixed command
        void'(trans_r[addr_ofst].set_addr(addr_ofst)); void'(trans_r[addr_ofst].set_op(WB_READ));
        // half-fixed command, need assign wb_data while using
        void'(trans_w[addr_ofst].set_addr(addr_ofst)); void'(trans_w[addr_ofst].set_op(WB_WRITE));
    end

    $cast(cmd_en_trans, ncsu_object_factory::create("wb_transaction"));
    void'(cmd_en_trans.set_op(WB_WRITE)); 		void'(cmd_en_trans.set_addr(CSR)); 		void'(cmd_en_trans.set_data( CSR_E | CSR_IE));		// Enable Core
    $cast(cmd_start_trans, ncsu_object_factory::create("wb_transaction"));
    void'(cmd_start_trans.set_op(WB_WRITE)); 	void'(cmd_start_trans.set_addr(CMDR)); 	void'(cmd_start_trans.set_data({5'b0,CMD_START}));	// Repeated START Command
    $cast(cmd_write_trans, ncsu_object_factory::create("wb_transaction"));
    void'(cmd_write_trans.set_op(WB_WRITE)); 	void'(cmd_write_trans.set_addr(CMDR)); 	void'(cmd_write_trans.set_data({5'b0,CMD_WRITE}));	// Write Command
    $cast(cmd_stop_trans, ncsu_object_factory::create("wb_transaction"));
    void'(cmd_stop_trans.set_op(WB_WRITE)); 	void'(cmd_stop_trans.set_addr(CMDR)); 	void'(cmd_stop_trans.set_data(CMD_STOP));			// Stop Command


    $cast(i2c_write_trans, ncsu_object_factory::create("i2c_transaction"));
	$cast(i2c_read_trans, ncsu_object_factory::create("i2c_transaction"));

    i2c_data.push_back( 100 );
	void'(i2c_write_trans.set_op(I2C_WRITE));
    void'(i2c_read_trans.set_op(I2C_READ));    void'(i2c_read_trans.set_data(i2c_data));
endfunction

virtual task run();

	$display("--------------------------------------------------------");
    $display("  TEST PLAN 3: I2CMB CONTROL FUNCTIONALITY TESTS START          ");
    $display("--------------------------------------------------------");

	fork   begin i2c_agt0.bl_put( i2c_write_trans );
                i2c_agt0.bl_put( i2c_read_trans );
            end
    join_none

	wb_agt0.bl_put_ref(cmd_en_trans);
	wb_agt0.bl_put_ref(trans_r[CSR]);
	assert(!(to_csr_reg(trans_r[CSR].wb_data).bb)) $display("TEST CASE PASSED: BUS BUSY BIT RESET BEFORE ISSUE OF START");
	else $fatal("TEST CASE FAILED: BUS BUSY BIT SET BEFORE ISSUE OF START");

	assert(!to_csr_reg(trans_r[CSR].wb_data).bc) $display("TEST CASE PASSED: BUS CAPTURE BIT NOT SET BEFORE SET BUS COMMAND");
    else $fatal("TEST CASE FAILED: BUS CAPTURE BIT SET BEFORE SET BUS COMMAND");

	$display("");

    void'(trans_w[DPR].set_data( 8'h00 ));
	wb_agt0.bl_put(trans_w[DPR]);

    void'(trans_w[CMDR].set_data( {5'b0,CMD_SET_BUS} ));
    wb_agt0.bl_put(trans_w[CMDR]);
	wb_agt0.bl_put_ref(trans_r[CMDR]);
	assert(to_cmdr_reg(trans_r[CMDR].wb_data).don ) $display("TEST CASE PASSED: VALID BUS ID");
	else $fatal("TEST CASE FAILED: VALID BUS ID GENERATED ERROR");

	wb_agt0.bl_put(cmd_start_trans);

    void'(trans_w[DPR].set_data( {I2C_SLAVE_ADDRESS<<1} | bit'(I2C_WRITE) ));
	wb_agt0.bl_put(trans_w[DPR]);

	wb_agt0.bl_put(cmd_write_trans);

    void'(trans_w[DPR].set_data( 8'd200 ));
    wb_agt0.bl_put(trans_w[DPR]);
	wb_agt0.bl_put_No_Wait(cmd_write_trans);
    wb_agt0.bl_put_ref(trans_r[CSR]);
    assert(to_csr_reg(trans_r[CSR].wb_data).bc) $display("TEST CASE PASSED: BUS CAPTURE BIT SET DURING EXECUTING COMMAND");
	else $fatal("TEST CASE FAILED: BUS CAPTURE BIT RESET DURING EXECUTING COMMAND");

    assert(to_csr_reg(trans_r[CSR].wb_data).bb) $display("TEST CASE PASSED: BUS BUSY BIT SET DURING EXECUTING COMMAND");
    else $fatal("TEST CASE FAILED: BUS BUSY BIT RESET DURING EXECUTING COMMAND");
    //$display("cmdr before irq triggered: %p", trans_r[CSR].to_csr_reg());

    wb_agt0.wait_for_interrupt();
    wb_agt0.bl_put_ref(trans_r[CMDR]);

	wb_agt0.bl_put(cmd_stop_trans);

	wb_agt0.bl_put_ref(trans_r[CSR]);
	assert(!to_csr_reg(trans_r[CSR].wb_data).bc) $display("TEST CASE PASSED: BUS CAPTURE BIT RESET AFTER STOP");
	else $fatal("TEST CASE FAILED: BUS CAPTURE BIT SET AFTER STOP");

	$display("--------------------------------------------------------");
    $display("  TEST PLAN 3: I2CMB CONTROL FUNCTIONALITY TESTS PASSED          ");
    $display("--------------------------------------------------------");

endtask

endclass
