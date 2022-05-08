class i2cmb_generator_random_test extends i2cmb_generator;
	`ncsu_register_object(i2cmb_generator_random_test)

integer max_test_round = 10;
int rand_size [];
i2c_transaction_rand i2c_trans_rand;
wb_transaction_rand wb_trans_rand;

function new(string name="", ncsu_component_base parent=null);
	super.new(name, parent);

	$cast(wb_trans_rand, ncsu_object_factory::create("wb_transaction_rand"));
	void'(wb_trans_rand.set_op(WB_WRITE)); 	void'(wb_trans_rand.set_addr(DPR));	// Write Command
	$cast(i2c_trans_rand, ncsu_object_factory::create("i2c_transaction_rand"));
	void'(i2c_trans_rand.set_op(I2C_READ));

endfunction

virtual task run();
	automatic int k,j,kk,jj;

	$display("--------------------------------------------------------");
    $display("  TEST PLAN: I2CMB RANDOM TESTS START          ");
    $display("--------------------------------------------------------");

	rand_size = new [max_test_round];
	for(k=0;k<max_test_round;k=k+1)begin
		rand_size[k] = $urandom_range(1,10);
	end

	reset_core_to_idle_state();

	fork
		begin
			for(int kk=0;kk<max_test_round;kk=kk+1)begin

				i2c_agt0.bl_put( i2c_write_trans );
				assert( i2c_trans_rand.randomize() );
				i2c_agt0.bl_put( i2c_trans_rand );

				i2c_agt0.bl_put( i2c_write_trans );

				assert( i2c_trans_rand.randomize() with { i2c_rand_data.size() == rand_size[kk]; } );
				i2c_agt0.bl_put( i2c_trans_rand );
			end
		end
	join_none

	for(j=0;j<max_test_round;j=j+1)begin

		wb_agt0.bl_put( cmd_start_trans );     	// Repeated START Command
		assert( wb_trans_rand.randomize() with { wb_rand_data[0] == bit'(I2C_WRITE); } );
		WB_write_byte( wb_trans_rand );
		assert( wb_trans_rand.randomize() );
		WB_write_byte( wb_trans_rand );

		wb_agt0.bl_put( cmd_start_trans );     	// Repeated START Command
		assert( wb_trans_rand.randomize() with { wb_rand_data[0] == bit'(I2C_READ); } );
		WB_write_byte( wb_trans_rand );                	// Slave Address and R/W bit & Write Command
		WB_read_byte();                      	// Read Command & Read out DPR

		wb_agt0.bl_put( cmd_start_trans );     	// Repeated START Command
		assert( wb_trans_rand.randomize() with { wb_rand_data[0] == bit'(I2C_WRITE); } );
		WB_write_byte( wb_trans_rand );
		repeat(rand_size[j]) begin
			assert( wb_trans_rand.randomize() );
			WB_write_byte( wb_trans_rand );
		end

		wb_agt0.bl_put( cmd_start_trans );     	// Repeated START Command
		assert( wb_trans_rand.randomize() with { wb_rand_data[0] == bit'(I2C_READ); } );
		WB_write_byte( wb_trans_rand );                	// Slave Address and R/W bit & Write Command
		for(jj=0;jj<rand_size[j];jj=jj+1)begin
			WB_read_byte( jj==(rand_size[j]-1) );                      	// Read Command & Read out DPR
		end
	end
	wb_agt0.bl_put( cmd_stop_trans );

	$display("--------------------------------------------------------");
    $display("  TEST PLAN: I2CMB RANDOM TESTS PASSED          ");
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

endclass
