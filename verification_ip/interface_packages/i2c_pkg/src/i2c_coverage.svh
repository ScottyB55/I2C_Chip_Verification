class i2c_coverage extends ncsu_component#(.T(ncsu_transaction));
	i2c_configuration cfg_h;
	i2c_transaction i2c_trans_h;
	bit i2c_rw;
	bit [I2C_SLAVE_ADDR_SIZE-1:0] i2c_addr;

	covergroup i2c_interface_cg;
		coverpoint i2c_rw;
		coverpoint i2c_addr{
			bins slave_addr = {[1:127]};
		}
		i2c_addrxrw : cross i2c_addr, i2c_rw;
	endgroup	

	function new (string name = "", ncsu_component #(T) parent = null);
		super.new(name, parent);
		i2c_interface_cg = new;
	endfunction

	function void set_configuration(i2c_configuration cfg);
   		cfg_h = cfg;
 	endfunction

  	virtual function void nb_put(T trans);
    		$display("coverage::nb_put() %s called",get_full_name());
		$cast(i2c_trans_h,trans);
		i2c_addr = i2c_trans_h.address;
		i2c_rw = i2c_trans_h.rw;
		i2c_interface_cg.sample();
  	endfunction

endclass
