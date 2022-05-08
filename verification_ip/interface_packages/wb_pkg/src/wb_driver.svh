class wb_driver extends ncsu_component#(.T(wb_transaction));

    wb_configuration cfg0;

    virtual wb_if#(.ADDR_WIDTH(WB_ADDR_WIDTH), .DATA_WIDTH(WB_DATA_WIDTH)) wb_bus;

    T trans;

    function new(string name="", ncsu_component_base  parent=null);
        super.new(name, parent);
    endfunction

    function void set_configuration(wb_configuration cfg);
    	cfg0 = cfg;
    endfunction

    virtual task bl_put(T trans);
        //ncsu_info("wb_driver::bl_put() ",{ " ", trans.convert2string()},NCSU_NONE);
        if(trans.wb_op==WB_WRITE)    wb_bus.master_write(trans.wb_addr, trans.get_data_0());
        if(trans.wb_op==WB_READ)     wb_bus.master_read(trans.wb_addr, trans.wb_data);
    	if((trans.wb_op==WB_WRITE) && (trans.wb_addr==CMDR)) begin
            wb_bus.wait_for_interrupt();
            wb_bus.master_read(CMDR, trans.cmdr_data);
        end

    endtask

    virtual task bl_put_ref(ref T trans);
        //ncsu_info("wb_driver::bl_put() ",{ " ", trans.convert2string()},NCSU_NONE);
        if(trans.wb_op==WB_WRITE)    wb_bus.master_write(trans.wb_addr, trans.get_data_0());
        if(trans.wb_op==WB_READ)     wb_bus.master_read(trans.wb_addr, trans.wb_data);
    	if((trans.wb_op==WB_WRITE) && (trans.wb_addr==CMDR) && (trans.wb_data[2:0]!= CMD_NO_USED)) begin
            wb_bus.wait_for_interrupt();
            wb_bus.master_read(CMDR, trans.cmdr_data);
        end
        //ncsu_info("wb_driver::bl_put() ",{ " END ", trans.convert2string()},NCSU_NONE);
    endtask

    virtual task bl_put_No_Wait(T trans);
        if(trans.wb_op==WB_WRITE)    wb_bus.master_write(trans.wb_addr, trans.wb_data);
        if(trans.wb_op==WB_READ)     wb_bus.master_read(trans.wb_addr, trans.wb_data);
    endtask

    virtual task wait_for_interrupt();
        wb_bus.wait_for_interrupt();
    endtask

endclass
