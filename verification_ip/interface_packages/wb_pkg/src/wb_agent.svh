class wb_agent extends ncsu_component#(.T(ncsu_transaction));
  wb_configuration conf_h;
  wb_monitor       mon_h;
  ncsu_component #(T) subscribers[$];
  wb_driver        drv_h;
  wb_coverage      coverage_h;
  virtual wb_if    wb_intf_h;

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
    if ( !(ncsu_config_db#(virtual wb_if)::get(get_full_name(), this.wb_intf_h))) begin;
      $fatal("WB_AGENT : Failed to get wb interface : %s ", get_full_name());
    end
  endfunction

  function void set_configuration(wb_configuration cfg);
    conf_h = cfg;
  endfunction

  virtual function void build();
    // creating driver instance
    drv_h = new("drv_h",this);
    drv_h.set_configuration(conf_h);
    drv_h.wb_intf_h = this.wb_intf_h;
    //creating instance for coverage
    coverage_h = new("coverage_h",this);
    coverage_h.set_configuration(conf_h);
    coverage_h.build();
    connect_subscriber(coverage_h);
    // creating monitor instance
    mon_h = new("mon_h",this);
    mon_h.set_configuration(conf_h);
    mon_h.set_agent(this);
    mon_h.enable_transaction_viewing = 1;
    mon_h.build();
    mon_h.wb_intf_h = this.wb_intf_h;
  endfunction

  virtual function void nb_put(T trans);
    foreach (subscribers[i]) subscribers[i].nb_put(trans);
  endfunction

  virtual task bl_put(T trans);
    drv_h.bl_put(trans);
  endtask

  virtual task gen_bl_put(T trans);
    drv_h.gen_bl_put(trans);
  endtask

  virtual function void connect_subscriber(ncsu_component#(T) subscriber);
    subscribers.push_back(subscriber);
  endfunction

  virtual task run();
     drv_h.configure_driver();
     fork 
	     mon_h.run(); 
     join_none
  endtask

endclass : wb_agent
