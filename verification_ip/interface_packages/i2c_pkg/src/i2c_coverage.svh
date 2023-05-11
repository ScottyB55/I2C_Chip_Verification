class i2c_coverage extends ncsu_component#(.T(ncsu_transaction));
    /*
    A class used to represent the coverage of an I2C Transaction.

    This class is responsible for handling coverage related to I2C transactions, which include the configuration, transaction details, and sampling the coverage group.

    Attributes
    ----------
    cfg_h : i2c_configuration
        The configuration for the I2C transaction
    i2c_trans_h : i2c_transaction
        The I2C transaction to be sampled
    i2c_rw : bit
        Specifies if the transaction is a read (1) or write (0) operation
    i2c_addr : bit [I2C_SLAVE_ADDR_SIZE-1:0]
        The slave address for the I2C transaction
    i2c_interface_cg : covergroup
        The covergroup to sample
    */
	i2c_configuration cfg_h;
	i2c_transaction i2c_trans_h;
	bit i2c_rw;
	bit [I2C_SLAVE_ADDR_SIZE-1:0] i2c_addr;

	covergroup i2c_interface_cg;
        /*
        A covergroup for I2C interface

        This covergroup checks the coverage of the read/write operation and the slave address.
        It also checks the cross coverage between the slave address and read/write operation.
        */
        
        /*Monitors the read/write operation (i2c_rw). 
        It checks whether both read (1) and write (0) operations occur during the simulation.*/
		coverpoint i2c_rw;

        /*Monitoring the I2C slave address (i2c_addr). It checks whether all possible slave 
        addresses from 1 to 127 are exercised during the simulation.*/
		coverpoint i2c_addr{
			bins slave_addr = {[1:127]};
		}

        /*Defines a cross coverage between the i2c_addr and i2c_rw. 
        Cross coverage is used to verify interactions between different coverpoints. 
        In this case, it checks whether all combinations of read/write operations 
        for each slave address are tested.*/
		i2c_addrxrw : cross i2c_addr, i2c_rw;
	endgroup

	function new (string name = "", ncsu_component #(T) parent = null);
        /*
        Constructs all the necessary attributes for the i2c_coverage object.

        Parameters
        ----------
        name : string
            The name of the I2C coverage
        parent : ncsu_component #(T)
            The parent component of the I2C coverage
        */
		super.new(name, parent);
		i2c_interface_cg = new;
	endfunction

	function void set_configuration(i2c_configuration cfg);
        /*
        Sets the configuration for the I2C transaction.

        Parameters
        ----------
        cfg : i2c_configuration
            The configuration to be set
        */
   		cfg_h = cfg;
 	endfunction

  	virtual function void nb_put(T trans);
        /*
        Puts the I2C transaction into the coverage model and samples the covergroup.

        Parameters
        ----------
        trans : T
            The transaction to be put into the coverage model
        */
    	$display("coverage::nb_put() %s called",get_full_name());
		$cast(i2c_trans_h,trans);
		i2c_addr = i2c_trans_h.address;
		i2c_rw = i2c_trans_h.rw;
		i2c_interface_cg.sample();
  	endfunction

endclass