class wb_transaction_rand extends wb_transaction;
  `ncsu_register_object(wb_transaction_rand)

  typedef wb_transaction_rand this_type;
  static this_type type_handle = get_type();

  static function this_type get_type();
      if(type_handle == null)
        type_handle = new();
      return type_handle;
    endfunction

    virtual function transaction_handler get_type_handle();
       return get_type();
     endfunction

rand bit [WB_DATA_WIDTH-1:0] wb_rand_data;

function new(string name="");
    super.new(name);
endfunction

virtual function string convert2string();
    return {super.convert2string(),$sformatf(" random Data:0x%x", wb_rand_data)};
endfunction

virtual function this_type set_addr(bit [WB_ADDR_WIDTH-1:0] addr);
    void'(super.set_addr(addr));
    return this;
endfunction

virtual function this_type set_op(wb_op_t OP);
    void'(super.set_op(OP));
    return this;
endfunction

virtual function bit [WB_DATA_WIDTH-1:0] get_data_0();
      return this.wb_rand_data;
endfunction

virtual function automatic dynamic_arr_t get_data();
      dynamic_arr_t return_dyn_arr;
      return_dyn_arr = new[0];
      return_dyn_arr[0] = this.wb_rand_data;
      return return_dyn_arr;
endfunction


endclass
