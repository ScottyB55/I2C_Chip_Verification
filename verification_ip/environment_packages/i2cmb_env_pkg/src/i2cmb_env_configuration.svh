class i2cmb_env_configuration extends ncsu_configuration;

  i2c_configuration i2c_conf_h;
  wb_configuration wb_conf_h;

  function new(string name=""); 
    super.new(name);

    i2c_conf_h = new("i2c_conf_h");
    wb_conf_h = new("wb_conf_h");

  endfunction

endclass : i2cmb_env_configuration
