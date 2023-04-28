class i2c_agent extends ncsu_component#(.T(ncsu_transaction));
  
  i2c_configuration configuration;
  i2c_coverage i2c_cov_h;
  i2c_driver        drv_h;
  i2c_monitor       mon_h;
  ncsu_component #(T) subscribers[$];
  
  virtual i2c_if    bus;
 	function new(string name = "", ncsu_component_base  parent = null); 
    	super.new(name,parent);

    	if (!(ncsu_config_db#(virtual i2c_if)::get(get_full_name(), this.bus))) begin;
      		$fatal("Not able to get i2c interface: %s ",get_full_name());
    	end
 	endfunction

	function void set_configuration(i2c_configuration cfg);
	    configuration = cfg;
	endfunction

	virtual function void build();
		// instantiating monitor
		mon_h = new("mon_h",this);
	    	mon_h.set_configuration(configuration);
	   	mon_h.set_agent(this);
	  	mon_h.enable_transaction_viewing = 1;
	   	mon_h.build();
	    	mon_h.i2c_intf_h = this.bus;
		// instantiating driver
		drv_h = new("drv_h",this);
		drv_h.set_configuration(configuration);
		drv_h.build();
		drv_h.i2c_intf_h = this.bus;
		i2c_cov_h = new("i2c_cov_h", this);
         	i2c_cov_h.set_configuration(configuration);
         	i2c_cov_h.build();
         	connect_subscriber(i2c_cov_h);
	   
	endfunction

 	virtual task bl_put(T trans);
    		drv_h.bl_put(trans);
  	endtask

  	virtual function void connect_subscriber(ncsu_component#(T) subscriber);
    		subscribers.push_back(subscriber);
  	endfunction

  	virtual task run();
    		fork 
			mon_h.run(); 
		join_none
  	endtask

	virtual function void nb_put(T trans);
    		foreach (subscribers[i]) subscribers[i].nb_put(trans);
  	endfunction

endclass
