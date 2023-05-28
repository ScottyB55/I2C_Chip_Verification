/**
 * The `wb_agent` class extends the `ncsu_component` class.
 * It serves as the agent for the Wishbone (WB) protocol, and contains configuration, monitor, driver, and coverage objects.
 */

class wb_agent extends ncsu_component#(.T(ncsu_transaction));
    wb_configuration conf_h;
    wb_monitor       mon_h;
    ncsu_component #(T) subscribers[$];
    wb_driver        drv_h;
    wb_coverage      coverage_h;
    virtual wb_if    wb_intf_h;

    /**
    * The constructor for the `wb_agent` class.
    * @param name The name of the instance.
    * @param parent The parent component for the instance.
    */
    function new(string name = "", ncsu_component_base  parent = null); 
        super.new(name,parent);
        if ( !(ncsu_config_db#(virtual wb_if)::get(get_full_name(), this.wb_intf_h))) begin;
        $fatal("WB_AGENT : Failed to get wb interface : %s ", get_full_name());
        end
    endfunction

    /**
    * The `set_configuration` function sets the agent's configuration.
    * @param cfg The configuration to set.
    */
    function void set_configuration(wb_configuration cfg);
        conf_h = cfg;
    endfunction

    /**
    * The `build` function initializes and builds the driver, coverage, and monitor.
    * It also connects the coverage object to the subscribers.
    */
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

    /**
    * The `nb_put` function sends a transaction to all subscribers.
    * @param trans The transaction to be sent.
    */
    virtual function void nb_put(T trans);
        foreach (subscribers[i]) subscribers[i].nb_put(trans);
    endfunction

    /**
    * The `bl_put` task sends a transaction to the driver in a blocking manner.
    * @param trans The transaction to be sent.
    */
    virtual task bl_put(T trans);
        drv_h.bl_put(trans);
    endtask

    /**
    * The `gen_bl_put` task sends a transaction to the driver's generator in a blocking manner.
    * @param trans The transaction to be sent.
    */
    virtual task gen_bl_put(T trans);
        drv_h.gen_bl_put(trans);
    endtask

    /**
    * The `connect_subscriber` function adds a subscriber to the list of subscribers.
    * @param subscriber The subscriber to be added.
    */
    virtual function void connect_subscriber(ncsu_component#(T) subscriber);
        subscribers.push_back(subscriber);
    endfunction

    /**
    * The `run` task configures the driver and runs the monitor.
    */
    virtual task run();
        drv_h.configure_driver();
        fork 
            mon_h.run(); 
        join_none
    endtask

endclass : wb_agent