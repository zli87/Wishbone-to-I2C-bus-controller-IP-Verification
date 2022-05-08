class wb_agent extends ncsu_component #(.T(wb_transaction));

wb_configuration 	wb_cfg0;
wb_driver 		    wb_drv0;
wb_monitor          wb_mtr0;
//wb_coverage         wb_cov0;
ncsu_component #(T)	subscribers[$];
virtual wb_if#(.ADDR_WIDTH(WB_ADDR_WIDTH), .DATA_WIDTH(WB_DATA_WIDTH)) wb_bus;

function new(string name= "", ncsu_component_base parent=null);
	super.new(name, parent);
	if(!(ncsu_config_db#(virtual wb_if#(.ADDR_WIDTH(WB_ADDR_WIDTH), .DATA_WIDTH(WB_DATA_WIDTH)))::get("wb_interface", this.wb_bus))) begin
		ncsu_fatal("wb_agent::new()",$sformatf("ncsu_config_db::get() call failed."));
    end
endfunction

function void set_configuration(wb_configuration cfg);
	wb_cfg0 = cfg;
endfunction

virtual function void connect_subscriber(ncsu_component#(T) subs);
	subscribers.push_back(subs);
endfunction

virtual function void build();
	wb_drv0 = new("wb_driver_0", this);
	wb_drv0.set_configuration(wb_cfg0);
	wb_drv0.build();
	wb_drv0.wb_bus = this.wb_bus;

	wb_mtr0 = new("wb_monitor_0", this);
	wb_mtr0.set_configuration(wb_cfg0);
	wb_mtr0.set_agent(this);
	wb_mtr0.build();
	wb_mtr0.wb_bus = this.wb_bus;
endfunction

virtual function void nb_put(T trans);
	foreach(subscribers[i]) subscribers[i].nb_put(trans);
endfunction

virtual task bl_put(T trans);
	wb_drv0.bl_put(trans);
endtask

virtual task bl_put_ref(ref T trans);
	wb_drv0.bl_put_ref(trans);
endtask

virtual task bl_put_No_Wait(T trans);
	wb_drv0.bl_put_No_Wait(trans);
endtask

virtual task wait_for_interrupt();
	wb_drv0.wait_for_interrupt();
endtask

virtual task run();
	fork wb_mtr0.run(); join_none
endtask

endclass
