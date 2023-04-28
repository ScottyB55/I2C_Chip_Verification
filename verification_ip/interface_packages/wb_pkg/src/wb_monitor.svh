class wb_monitor extends ncsu_component#(.T(ncsu_transaction));

  virtual wb_if wb_intf_h;
  wb_transaction wb_trans_h;
  T monitored_trans;
  ncsu_component #(T) agent;
  wb_configuration  cfg_h;

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  function void set_configuration(wb_configuration cfg);
    cfg_h = cfg;
  endfunction

  function void set_agent(ncsu_component#(T) agent);
    this.agent = agent;
  endfunction
  
  virtual task run ();

      bit [WB_BYTE_SIZE-1:0] temp;
      wb_intf_h.wait_for_reset();
      forever begin
        wb_trans_h = new("monitored_trans");
        wb_intf_h.master_monitor(wb_trans_h.wb_addr,
                    wb_trans_h.data,
                    wb_trans_h.rw
                    );

        monitored_trans = wb_trans_h;
        agent.nb_put(monitored_trans);
    end
  endtask
endclass : wb_monitor
