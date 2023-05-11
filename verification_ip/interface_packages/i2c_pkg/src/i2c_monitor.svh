class i2c_monitor extends ncsu_component#(.T(ncsu_transaction));
    /*
    A class used to represent an I2C Monitor.

    This class is responsible for monitoring I2C transactions on the bus.
    It handles operations such as setting configurations, setting agent and running the monitoring task.

    Attributes
    ----------
    configuration : i2c_configuration
        The configuration settings for the I2C monitor
    i2c_intf_h : virtual i2c_if
        The interface handler for the I2C bus
    monitored_trans : i2c_transaction
        The I2C transaction being monitored
    agent : ncsu_component#(T)
        The agent responsible for the I2C transaction
    */
    i2c_configuration  configuration;
    virtual i2c_if i2c_intf_h;

    i2c_transaction monitored_trans;
    ncsu_component #(T) agent;

    function new(string name = "", ncsu_component_base  parent = null);
        /*
        Constructs all the necessary attributes for the i2c_monitor object.

        Parameters
        ----------
        name : string
            The name of the I2C monitor
        parent : ncsu_component_base
            The parent component of the I2C monitor
        */
        super.new(name,parent);
    endfunction

    function void set_configuration(i2c_configuration cfg);
        /*
        Sets the configuration for the I2C monitor.

        Parameters
        ----------
        cfg : i2c_configuration
            The configuration to be set
        */
        configuration = cfg;
    endfunction

    function void set_agent(ncsu_component#(T) agent);
        /*
        Sets the agent for the I2C monitor.

        Parameters
        ----------
        agent : ncsu_component#(T)
            The agent to be set
        */
        this.agent = agent;
    endfunction

    virtual task run ();
        /*
        Runs the I2C monitoring task.

        The task continuously monitors the I2C transactions on the bus,
        and sends the monitored transaction to the agent.
        */
        forever begin
            monitored_trans = new("monitored transaction");
            i2c_intf_h.monitor( monitored_trans.address,
                                monitored_trans.rw,
                                monitored_trans.data
                                );
            monitored_trans.num_bytes = monitored_trans.data.size();
            agent.nb_put(monitored_trans);
        end
    endtask
endclass
