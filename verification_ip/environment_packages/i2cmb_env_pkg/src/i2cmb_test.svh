class i2cmb_test extends ncsu_component;
  i2cmb_env_configuration  cfg_h;
  i2cmb_environment        env_h;
  i2cmb_generator          gen_h;
  string 		   testcase_handle;

  function new(string name = "", ncsu_component_base parent = null); 
    super.new(name,parent);

    cfg_h = new("cfg_h");

    env_h = new("env_h",this);
    env_h.set_configuration(cfg_h);
    env_h.build();

    gen_h = new("gen_h",this);
    gen_h.set_agent(env_h.get_i2c_agent(), env_h.get_wb_agent());

    if(!$value$plusargs("GEN_TEST_TYPE=%s", testcase_handle)) 
    begin
       $display("FATAL: +GEN_TEST_TYPE plusarg NOT FOUND");
         $fatal;
    end
  endfunction

  virtual task run();
     env_h.run();
     if (testcase_handle == "default_offset_check") begin
	     gen_h.default_offset_check();
     end
     else if (testcase_handle == "read_write_permission") begin
	     gen_h.read_write_permission();
     end
     else if (testcase_handle == "reset_iicm_check") begin
	     gen_h.reset_iicm_check();
     end
     else if (testcase_handle == "error_check") begin
	     gen_h.error_check();
     end
     else if (testcase_handle == "register_aliasing") begin
	     gen_h.register_aliasing();
     end
     else if (testcase_handle == "write_on_read_only_register") begin
	     gen_h.write_on_read_only_register();
     end
     else begin
       fork 
	     gen_h.run_i2c();
       join_none
       gen_h.run_wb(); 
     end
  endtask

endclass : i2cmb_test
