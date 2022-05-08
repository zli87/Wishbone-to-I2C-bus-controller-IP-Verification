class ncsu_object_registry #( type T=ncsu_object, string T_NAME="<unknown>") extends ncsu_object_wrapper;

  typedef  ncsu_object_registry #(T,T_NAME) this_type;

  virtual function string get_type_name();
    return T_NAME;
  endfunction

  static this_type me = get();

  static function this_type get();
    if ( me == null ) begin
      ncsu_object_factory f_obj = ncsu_object_factory::get();
      me = new();
      f_obj.register_object(me);
    end
    return me;
  endfunction

  virtual function ncsu_object create_object(string name ="");
    T obj;
    obj = new(name);
    return obj;
  endfunction

endclass
