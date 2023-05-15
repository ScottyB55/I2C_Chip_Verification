class i2c_driver extends ncsu_component#(.T(ncsu_transaction));
    /*
    A class used to represent an I2C Driver.

    This class is responsible for managing I2C transactions in hardware.
    It handles operations such as setting configurations and providing read data to the 
    I2C interface.

    Attributes
    ----------
    i2c_intf_h : virtual i2c_if
        The interface handler for the I2C bus
    i2c_trans_h : i2c_transaction
        The I2C transaction handler
    configuration : i2c_configuration
        The configuration settings for the I2C driver
    */

    virtual i2c_if i2c_intf_h;
    i2c_transaction i2c_trans_h;
    i2c_configuration configuration;

    function new(string name = "", ncsu_component_base  parent = null);
        /*
        Constructs all the necessary attributes for the i2c_driver object.

        Parameters
        ----------
        name : string
            The name of the I2C driver
        parent : ncsu_component_base
            The parent component of the I2C driver
        */
        super.new(name,parent);
    endfunction

    function void set_configuration(i2c_configuration cfg);
        /*
        Sets the configuration for the I2C driver.

        Parameters
        ----------
        cfg : i2c_configuration
            The configuration to be set
        */
        configuration = cfg;
    endfunction

    virtual task bl_put(T trans);
        /*
        Sends the transaction to the I2C interface for reading data.

        Parameters
        ----------
        trans : T
            The transaction to be sent
        */
        $cast(i2c_trans_h,trans);
        i2c_intf_h.write_words_to_I2C_bus(i2c_trans_h.data);
    endtask

endclass : i2c_driver