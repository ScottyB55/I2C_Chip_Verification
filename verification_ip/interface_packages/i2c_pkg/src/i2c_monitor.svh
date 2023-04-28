class i2c_monitor extends ncsu_component#(.T(ncsu_transaction));
  i2c_configuration  configuration;
  virtual i2c_if i2c_intf_h;

  i2c_transaction monitored_trans;
  ncsu_component #(T) agent;

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  function void set_configuration(i2c_configuration cfg);
    configuration = cfg;
  endfunction

  function void set_agent(ncsu_component#(T) agent);
    this.agent = agent;
  endfunction
  
  virtual task run ();
      forever begin
        monitored_trans = new("monitored transaction");
        i2c_intf_h.monitor(monitored_trans.address,
                    monitored_trans.rw,
                    monitored_trans.data
                    );
        monitored_trans.num_bytes = monitored_trans.data.size();
        agent.nb_put(monitored_trans);
    end
  endtask
endclass
