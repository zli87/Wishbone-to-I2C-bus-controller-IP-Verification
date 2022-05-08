class i2cmb_environment extends ncsu_component;

i2cmb_env_configuration cfg0;
wb_configuration wb_cfg0;
i2c_configuration i2c_cfg0;

wb_agent wb_agt0;
i2c_agent i2c_agt0;
i2cmb_predictor pred0;
i2cmb_scoreboard sb0;
i2cmb_coverage_wb cov0;
i2cmb_coverage_i2c cov1;

function new(string name="", ncsu_component_base parent=null);
    super.new(name, parent);
endfunction

function void set_configuration(i2cmb_env_configuration cfg);
	cfg0 = cfg;
    wb_cfg0 = new(cfg.get_name());
    i2c_cfg0 = new(cfg.get_name());
endfunction


virtual function void build();
	wb_agt0 = new("wb_agent", this);
    wb_agt0.set_configuration(wb_cfg0);
	wb_agt0.build();
	i2c_agt0 = new("i2c_agent", this);
    i2c_agt0.set_configuration(i2c_cfg0);
	i2c_agt0.build();
	cov0 = new("wb_coverage", this);
	cov0.set_configuration(cfg0);
	cov0.build();
    cov1 = new("i2c_coverage", this);
	cov1.set_configuration(cfg0);
	cov1.build();
	pred0 = new("predictor", this);
    pred0.set_configuration(cfg0);
	pred0.build();
	sb0 = new("scoreboard", this);
	sb0.build();
	i2c_agt0.connect_subscriber(sb0);
    i2c_agt0.connect_subscriber(cov1);
    // !!! if you want to connect predictor and i2c bus,
    // !!! you need to think about how to transfer from i2c agent's type,"ncsu_component#(i2c_transaction)",
    // !!! to predictor's type, "ncsu_component#(wb_transaction)".
    // i2c_agt0.connect_subscriber(pred0);
    wb_agt0.connect_subscriber(cov0);
    wb_agt0.connect_subscriber(pred0);
    pred0.set_scoreboard(sb0);
endfunction

function wb_agent get_wb_agent();
	return wb_agt0;
endfunction

function i2c_agent get_i2c_agent();
	return i2c_agt0;
endfunction

virtual task run();
 	wb_agt0.run();
	i2c_agt0.run();
    fork sb0.run(); join_none
endtask

endclass
