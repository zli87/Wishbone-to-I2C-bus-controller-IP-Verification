class wb_monitor extends ncsu_component#(.T(wb_transaction));

wb_configuration wb_cfg0;
virtual wb_if#(.ADDR_WIDTH(WB_ADDR_WIDTH), .DATA_WIDTH(WB_DATA_WIDTH)) wb_bus;
T monitor_trans;
T wb_irq_trans;
ncsu_component#(T) agent;

function new(string name ="", ncsu_component_base parent=null);
	super.new(name, parent);
endfunction

function void set_configuration(wb_configuration cfg);
	wb_cfg0 = cfg;
endfunction

function void set_agent(ncsu_component#(T) agent);
    this.agent = agent;
endfunction

virtual task run();
	wb_bus.wait_for_reset();
	fork
	 	begin forever begin
			$cast(monitor_trans, ncsu_object_factory::create("wb_transaction"));
			wb_bus.master_monitor(monitor_trans.wb_addr, monitor_trans.wb_data, monitor_trans.wb_op);
			this.agent.nb_put(monitor_trans);
		end end
		begin forever begin
			wb_bus.wait_for_interrupt();
			$cast( wb_irq_trans, ncsu_object_factory::create("wb_irq_transaction"));
			this.agent.nb_put(wb_irq_trans);
		end end
	join
endtask

endclass
