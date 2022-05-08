class ncsu_configuration extends ncsu_object;

  function new(string name=""); 
    super.new(name);
  endfunction

  virtual function string convert2string();
     return $sformatf("name: %s ",name);
  endfunction

endclass
