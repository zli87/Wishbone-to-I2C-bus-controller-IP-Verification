class i2c_driver extends ncsu_component#(.T(i2c_transaction));

	function new(string name = "", ncsu_component_base parent = null);
		super.new(name, parent);
	endfunction : new

	virtual i2c_if #(.I2C_ADDR_WIDTH(I2C_ADDR_WIDTH), .I2C_DATA_WIDTH(I2C_DATA_WIDTH))	i2c_bus;
	i2c_configuration i2c_cfg0;
	i2c_transaction i2c_trans;
	bit transfer_complete;

	function void set_configuration(i2c_configuration cfg);
		i2c_cfg0 = cfg;
	endfunction

	virtual task bl_put(T trans);
		automatic bit [I2C_DATA_WIDTH-1:0] tmp_data [];

		//ncsu_info("i2c_driver::bl_put() ",{ " before ", trans.convert2string()},NCSU_NONE);
		if(trans.i2c_op == I2C_WRITE) begin
			i2c_bus.wait_for_i2c_transfer(trans.i2c_op, trans.i2c_data );
		end else if(trans.i2c_op == I2C_READ) begin
			i2c_bus.wait_for_i2c_transfer(trans.i2c_op, tmp_data );
			i2c_bus.provide_read_data(trans.get_data(), transfer_complete);
		end
		//ncsu_info("i2c_driver::bl_put() ",{ " after ", trans.convert2string()},NCSU_NONE);

	endtask : bl_put

	task arb_lost_during_restart();
		i2c_bus.arb_lost_during_restart();
	endtask

	task arb_lost_during_write();
		i2c_bus.arb_lost_during_write();
	endtask
	task arb_lost_during_read();
		i2c_bus.arb_lost_during_read();
	endtask
	task reset();
		i2c_bus.reset();
	endtask
endclass
