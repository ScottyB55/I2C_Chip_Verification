class alt_read_write_test extends i2cmb_test;

	i2c_transaction alt_master_transactions [];
	i2c_transaction alt_slave_transactions [];
	int bus_num = 0;
	int num_of_operation;
	int num_of_read_operation;
	int j;

	function new(string name = "", ncsu_component_base parent = null);
		super.new(name,parent);
	endfunction : new


	virtual task run();

		bit [WB_BYTE_SIZE-1:0] alt_read_data []; 
		bit [WB_BYTE_SIZE-1:0] alt_write_data []; 

		// Alternate read and write
		alt_master_transactions = new[128]; 
		alt_slave_transactions = new[64];
		alt_read_data = new[1];
		alt_write_data = new[1];
		
		// Setting master transactions
		while (num_of_operation < 128) begin
			alt_write_data[0] = j + 64;
			alt_master_transactions[num_of_operation] = new("Read by master", SLAVE_ADDRESS, READ, 1, bus_num);
			alt_master_transactions[num_of_operation + 1] = new("Write by master", SLAVE_ADDRESS, WRITE, 1, bus_num);
			alt_master_transactions[num_of_operation + 1].data = alt_write_data;
			num_of_operation = num_of_operation + 2;
			j = j + 1;
		end
		super.gen_h.set_master_transactions(alt_master_transactions);
		// Setting slave transactions
		while (num_of_read_operation < 64) begin
			alt_slave_transactions[num_of_read_operation] = new("Read by slave", SLAVE_ADDRESS, READ, 1, bus_num);
			alt_read_data[0] = 63 - num_of_read_operation;
			alt_slave_transactions[num_of_read_operation].data = alt_read_data;
			num_of_read_operation = num_of_read_operation + 1;
		end
		super.gen_h.set_slave_transactions(alt_slave_transactions);

		fork 
			super.run(); 
		join_any
		disable fork;

		$display("Alternate read write TEST COMPLETE. \n");

	endtask : run
endclass
