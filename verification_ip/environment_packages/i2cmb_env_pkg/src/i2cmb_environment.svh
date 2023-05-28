/**
 * The `i2cmb_environment` class extends the `ncsu_component` class. 
 * It defines the environment for the I2C and Wishbone agents, and also sets up a predictor and a scoreboard.
 */

class i2cmb_environment extends ncsu_component#(.T(ncsu_transaction));

    i2cmb_env_configuration cfg_h;
    i2c_agent               i2c_agent_h;
    wb_agent		        wb_agent_h;
    i2cmb_predictor         predictor_h;
    i2cmb_scoreboard        scoreboard_h;

    /**
    * The constructor for the `i2cmb_environment` class.
    * @param name The name of the instance.
    * @param parent The parent component for the instance.
    */
    function new(string name = "", ncsu_component_base  parent = null); 
        super.new(name,parent);
    endfunction 

    /**
    * The `set_configuration` function sets the environment configuration.
    * @param cfg The configuration to set.
    */
    function void set_configuration(i2cmb_env_configuration cfg);
        cfg_h = cfg;
    endfunction

    /**
    * The `build` function initializes and builds the i2c and wb agents, predictor and scoreboard. 
    * It also sets up connections between the agents, the predictor, and the scoreboard.
    */
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

    /**
    * The `get_i2c_agent` function returns the handle to the i2c agent.
    * @return The handle to the i2c agent.
    */
    function i2c_agent get_i2c_agent();
        return i2c_agent_h;
    endfunction

    /**
    * The `get_wb_agent` function returns the handle to the wb agent.
    * @return The handle to the wb agent.
    */
    function wb_agent get_wb_agent();
        return wb_agent_h;
    endfunction

    /**
    * The `run` task runs the i2c and WB monitors (within the agent) in parallel
    */
    virtual task run();
        wb_agent_h.run();
        i2c_agent_h.run();
    endtask
  
endclass : i2cmb_environment
