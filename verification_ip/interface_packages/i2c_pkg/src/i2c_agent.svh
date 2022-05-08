class i2c_agent extends ncsu_component#(.T(i2c_transaction));

i2c_configuration			i2c_cfg0;
i2c_driver				i2c_drv0;
i2c_monitor				i2c_mtr0;
//i2c_coverage				i2c_cov0;
ncsu_component #(T) 	subscribers[$];
// ncsu_component #(transaction_handler)	pred0;

virtual i2c_if #(.I2C_ADDR_WIDTH(I2C_ADDR_WIDTH), .I2C_DATA_WIDTH(I2C_DATA_WIDTH))	i2c_bus;

function new(string name="", ncsu_component_base parent=null);
	super.new(name, parent);
	if(!(ncsu_config_db#(virtual i2c_if#(.I2C_ADDR_WIDTH(I2C_ADDR_WIDTH), .I2C_DATA_WIDTH(I2C_DATA_WIDTH)))::get("i2c_interface", i2c_bus))) begin
		ncsu_fatal("i2c_agent::new()",$sformatf("ncsu_config_db::get() call failed."));
    end
endfunction

function void set_configuration(i2c_configuration cfg);
	i2c_cfg0 = cfg;
endfunction

virtual function void build();
	i2c_drv0 = new("i2c_drv0", this);
	i2c_drv0.set_configuration(i2c_cfg0);
	i2c_drv0.build();
	i2c_drv0.i2c_bus = this.i2c_bus;

	//i2c_cov0 = new("i2c_cov0", this);
	//i2c_cov0.set_configuration(i2c_cfg0);
	//i2c_cov0.build();
	//connect_subscriber(i2c_cov0);

	i2c_mtr0 = new("i2c_mtr0", this);
	i2c_mtr0.set_configuration(i2c_cfg0);
	i2c_mtr0.build();
	i2c_mtr0.set_agent(this);
	i2c_mtr0.i2c_bus = this.i2c_bus;

endfunction

virtual function void nb_put(T trans);
	foreach(subscribers[i]) subscribers[i].nb_put(trans);
endfunction

virtual function void connect_subscriber(ncsu_component#(T) subs);
	subscribers.push_back(subs);
endfunction

virtual task bl_put(T trans);
	i2c_drv0.bl_put(trans);
endtask

virtual task bl_get(output T trans);
	i2c_drv0.bl_get(trans);
endtask

virtual task run();
	fork i2c_mtr0.run(); join_none
endtask

task arb_lost_during_restart();
	i2c_drv0.arb_lost_during_restart();
endtask
task arb_lost_during_write();
	i2c_drv0.arb_lost_during_write();
endtask
task arb_lost_during_read();
	i2c_drv0.arb_lost_during_read();
endtask

task reset();
	i2c_drv0.reset();
endtask

endclass
