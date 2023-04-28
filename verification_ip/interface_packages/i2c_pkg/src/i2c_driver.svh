class i2c_driver extends ncsu_component#(.T(ncsu_transaction));

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  virtual i2c_if i2c_intf_h;
  i2c_transaction i2c_trans_h;
  i2c_configuration configuration;

  function void set_configuration(i2c_configuration cfg);
    configuration = cfg;
  endfunction

  virtual task bl_put(T trans);
    $cast(i2c_trans_h,trans);
    i2c_intf_h.provide_read_data(i2c_trans_h.data);
  endtask

endclass : i2c_driver
