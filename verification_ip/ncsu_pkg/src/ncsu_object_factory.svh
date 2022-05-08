class ncsu_object_factory extends ncsu_object;
  static ncsu_object_wrapper m_object_type_names[string];
  static ncsu_object_factory m_object_factory_inst;

  static function ncsu_object_factory get();
    if ( m_object_factory_inst == null) m_object_factory_inst = new();
    return m_object_factory_inst;
  endfunction

  static function void register_object(ncsu_object_wrapper c);
    m_object_type_names[c.get_type_name()] = c;
  endfunction

  static function ncsu_object create(string obj_name);
     if ( m_object_type_names.exists(obj_name) ) begin
        return m_object_type_names[obj_name].create_object(obj_name);
     end else begin
        $display("FATAL: ncsu_object_factory::create() - %s class not registered with object factory", obj_name);
        $fatal;
     end
  endfunction

endclass
