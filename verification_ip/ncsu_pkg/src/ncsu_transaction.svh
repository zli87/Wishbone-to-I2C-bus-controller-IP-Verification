class ncsu_transaction extends ncsu_object;

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

endclass
