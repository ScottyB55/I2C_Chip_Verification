/*
    Used for running different test scenarios for I2C and Wishbone interfaces.
    It has configuration, environment, and generator components. 
*/

class i2cmb_test extends ncsu_component;
    // Declare instances for configuration, environment and generator
    i2cmb_env_configuration  cfg_h;
    i2cmb_environment        env_h;
    i2cmb_generator          gen_h;
    string 		   testcase_handle;

    function new(string name = "", ncsu_component_base parent = null); 
    super.new(name,parent);

    // Instantiate configuration, environment, and generator
    cfg_h = new("cfg_h");
    env_h = new("env_h",this);
    env_h.set_configuration(cfg_h); // Set the configuration for the environment
    env_h.build();

    gen_h = new("gen_h",this);
    gen_h.set_agent(env_h.get_i2c_agent(), env_h.get_wb_agent()); // Set the I2C and Wishbone agents for the generator

    // If the user didn't provide a test case through a command-line argument, display an error and terminate
    if(!$value$plusargs("GEN_TEST_TYPE=%s", testcase_handle)) 
    begin
        $display("FATAL: +GEN_TEST_TYPE plusarg NOT FOUND");
            $fatal;
    end
    endfunction

    // Task to run the different test cases
    virtual task run();
        // Run the i2c and WB monitors (within the agent) in parallel
        env_h.run();
        // Depending on the "testcase_handle" command-line argument, run the appropriate test case
        // Each of these functions in the generator class is assumed to initiate a specific test case
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
        else begin // if none of the above test cases was selected, run the default I2C and Wishbone tasks
        fork 
            gen_h.run_i2c(); 
        join_none
        gen_h.run_wb(); 
        end
    endtask

endclass : i2cmb_test