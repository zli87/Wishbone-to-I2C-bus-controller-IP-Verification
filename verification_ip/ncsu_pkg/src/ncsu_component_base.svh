class ncsu_component_base extends ncsu_object;

  ncsu_component_base parent;
  int transaction_viewing_stream;
  bit enable_transaction_viewing;

  function new(string name="", ncsu_component_base  parent=null); 
    super.new(name);
    this.parent = parent;
  endfunction

  virtual function string get_name();
    return(name);
  endfunction

  virtual function string get_full_name();
    if ( parent == null ) return (name);
    else                  return ({parent.get_full_name(),".",name});
  endfunction

  virtual function void build();
     if (enable_transaction_viewing) begin
       transaction_viewing_stream = $create_transaction_stream({"\\",get_full_name(),".txn_stream"});
     end
  endfunction
endclass
