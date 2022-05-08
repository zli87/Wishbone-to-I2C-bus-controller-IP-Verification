class i2c_transaction extends transaction_handler;
	`ncsu_register_object(i2c_transaction)

	typedef i2c_transaction this_type;
    static this_type type_handle = get_type();

    static function this_type get_type();
        if(type_handle == null)
          type_handle = new();
        return type_handle;
      endfunction

      virtual function transaction_handler get_type_handle();
         return get_type();
       endfunction

	bit [I2C_DATA_WIDTH-1:0] i2c_data [];
	//bit [I2C_DATA_WIDTH-1:0] read_data [];
	bit [I2C_ADDR_WIDTH-1:0] i2c_addr;
	i2c_op_t i2c_op;
	bit ack;
//	bit [7:0] data [];
//	bit [7:0] data_random;
//	rand bit [7:0] data_temp;


	function new(string name = "");
		super.new(name);
	endfunction : new

	virtual function string convert2string();
		if(this.i2c_op == I2C_WRITE)
			return {super.convert2string(), $sformatf("write data: %p", i2c_data)};
		else
			return {super.convert2string(), $sformatf("read data: %p", i2c_data)};
	endfunction

	virtual function bit compare (transaction_handler rhs);
		return  (this.get_addr() == rhs.get_addr()) && (this.get_data() == rhs.get_data());
	endfunction

	virtual function this_type set_data(bit [I2C_DATA_WIDTH-1:0] data_buffer [$]);
		this.i2c_data = new [data_buffer.size()];
		this.i2c_data = {>>{data_buffer}};
		return this;
	endfunction

	function this_type set_op(i2c_op_t op);
		this.i2c_op = op;
		return this;
	endfunction

	virtual function bit [8-1:0] get_addr();
		// because addr only has 7 bits, use the 8th unused bit to transfer ackowledgement
	      return {this.ack, this.i2c_addr};
	endfunction

	virtual function bit get_op();
	      return this.i2c_op;
	endfunction

	virtual function bit [8-1:0] get_data_0();
	      return this.i2c_data[0];
	endfunction

	virtual function dynamic_arr_t get_data();
		dynamic_arr_t return_dyn_arr;
          return_dyn_arr = i2c_data;
          return return_dyn_arr;
    endfunction

endclass
