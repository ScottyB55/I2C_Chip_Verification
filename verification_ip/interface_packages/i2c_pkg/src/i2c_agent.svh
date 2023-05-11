class i2c_agent extends ncsu_component#(.T(ncsu_transaction));
    /*
    A class used to represent an I2C Agent.

    This class is responsible for managing I2C communication in hardware.
    It handles operations such as setting configurations, building I2C components,
    connecting subscribers, running the monitor and sending transactions to 
    subscribers and the driver.

    Attributes
    ----------
    configuration : i2c_configuration
        The configuration settings for the I2C components
    i2c_cov_h : i2c_coverage
        The I2C coverage handler
    drv_h : i2c_driver
        The I2C driver handler
    mon_h : i2c_monitor
        The I2C monitor handler
    subscribers : ncsu_component #(T) []
        The subscribers of the I2C agent
    bus : virtual i2c_if
        The interface for the I2C bus
    */
  
	i2c_configuration configuration;
	i2c_coverage i2c_cov_h;
	i2c_driver        drv_h;
	i2c_monitor       mon_h;
	ncsu_component #(T) subscribers[$];
	virtual i2c_if    bus;

 	function new(string name = "", ncsu_component_base  parent = null); 
        /*
        Constructs all the necessary attributes for the i2c_agent object.

        Parameters
        ----------
        name : string
            The name of the I2C agent
        parent : ncsu_component_base
            The parent component of the I2C agent
        */
    	super.new(name,parent);

    	if (!(ncsu_config_db#(virtual i2c_if)::get(get_full_name(), this.bus))) begin;
      		$fatal("Not able to get i2c interface: %s ",get_full_name());
    	end
 	endfunction

	function void set_configuration(i2c_configuration cfg);
        /*
        Sets the configuration for the I2C agent.

        Parameters
        ----------
        cfg : i2c_configuration
            The configuration to be set
        */
	    configuration = cfg;
	endfunction

	virtual function void build();
        /*
        Builds the I2C components: driver, monitor and coverage handler. 
        Also connects the coverage handler as a subscriber.
        */
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
        /*
        Sends the transaction to the driver.

        Parameters
        ----------
        trans : T
            The transaction to be sent
        */
    	drv_h.bl_put(trans);
  	endtask

  	virtual function void connect_subscriber(ncsu_component#(T) subscriber);
        /*
        Connects a subscriber to the I2C agent.

        Parameters
        ----------
        subscriber : ncsu_component#(T)
            The subscriber to be connected
        */
    	subscribers.push_back(subscriber);
  	endfunction

  	virtual task run();
        /*
        Runs the monitor task asynchronously.
        */
    	fork 
			mon_h.run(); 
		join_none
  	endtask

	virtual function void nb_put(T trans);
        /*
        Sends the transaction to all the subscribers.

        Parameters
        ----------
        trans : T
            The transaction to be sent
        */
    	foreach (subscribers[i]) subscribers[i].nb_put(trans);
  	endfunction

endclass