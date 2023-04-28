class i2cmb_environment extends ncsu_component#(.T(ncsu_transaction));

  i2cmb_env_configuration   cfg_h;
  i2c_agent                 i2c_agent_h;
  wb_agent		    wb_agent_h;
  i2cmb_predictor           predictor_h;
  i2cmb_scoreboard          scoreboard_h;

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction 

  function void set_configuration(i2cmb_env_configuration cfg);
    cfg_h = cfg;
  endfunction

  virtual function void build();

    i2c_agent_h = new("i2c_agent",this);
    i2c_agent_h.set_configuration(cfg_h.i2c_conf_h);
    i2c_agent_h.build();

    wb_agent_h = new("wb_agent",this);
    wb_agent_h.set_configuration(cfg_h.wb_conf_h);
    wb_agent_h.build();

    predictor_h  = new("predictor_h", this);
    predictor_h.set_configuration(cfg_h);
    predictor_h.build();

    scoreboard_h  = new("scoreboard_h", this);
    scoreboard_h.build();

    //wb_agent_h.connect_subscriber(coverage);
    wb_agent_h.connect_subscriber(predictor_h);

    predictor_h.set_scoreboard(scoreboard_h);

    i2c_agent_h.connect_subscriber(scoreboard_h);

  endfunction

  function i2c_agent get_i2c_agent();
    return i2c_agent_h;
  endfunction

  function wb_agent get_wb_agent();
    return wb_agent_h;
  endfunction

  virtual task run();
      wb_agent_h.run();
      i2c_agent_h.run();
  endtask
  
endclass : i2cmb_environment
