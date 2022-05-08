class transaction_handler extends ncsu_transaction;
 `ncsu_register_object(transaction_handler)

 typedef transaction_handler this_type;
 static this_type type_handle = get_type();

 static function this_type get_type();
    if(type_handle == null)
      type_handle = new();
    return type_handle;
  endfunction

  virtual function transaction_handler get_type_handle();
     return get_type();
   endfunction

  int transaction_id;
  static int transaction_count;
  time start_time, end_time;
  int transaction_view_h;

  function new(string name="");
    super.new(name);
    this.name = name;
    transaction_id = transaction_count++;
  endfunction

  virtual function string convert2string();
     return $sformatf("name: %s transaction_count: %0d ",name,transaction_id);
  endfunction

  virtual function void add_to_wave(int transaction_viewing_stream_h);
    if ( transaction_view_h == 0)
       transaction_view_h = $begin_transaction(transaction_viewing_stream_h,"Transaction",start_time);
    $add_attribute( transaction_view_h, transaction_id, "transaction_id" );
  endfunction

  virtual function bit [8-1:0] get_addr();
        return 0;
  endfunction

  virtual function bit get_op();
        return 0;
  endfunction

  typedef bit [7:0] bit8;
  typedef bit8 dynamic_arr_t[];

  virtual function automatic dynamic_arr_t get_data();
        dynamic_arr_t return_dyn_arr;
        return_dyn_arr = new[0];
        return return_dyn_arr;
  endfunction

  virtual function bit [8-1:0] get_data_0();
        return 0;
  endfunction

  virtual function bit compare(this_type rhs);
    return 1'b0;
  endfunction

endclass
