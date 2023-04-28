class consecutive_read_test extends i2cmb_test;

	i2c_transaction read_transactions [];
	i2c_transaction read_transactions_wb [];
	int bus_num = 0;
	int num_of_read;
	int num_of_operation;
	int num_of_read_operation;

	function new(string name = "", ncsu_component_base parent = null);
		super.new(name,parent);
	endfunction : new


	virtual task run();

		bit [WB_BYTE_SIZE-1:0] read_data []; 

		$display("Consecutive read START. \n");

  		read_data = new[32];
		
		// Reading
		read_transactions_wb = new[1];
		read_transactions_wb[0] = new("100-131_Read", SLAVE_ADDRESS, READ, 32, bus_num);
		super.gen_h.set_master_transactions(read_transactions_wb);

		while (num_of_read < 32) begin
			read_data[num_of_read] = 100 + num_of_read;
			num_of_read = num_of_read + 1;
		end

		read_transactions = new[1];
		read_transactions[0] = new("100-131_Read", SLAVE_ADDRESS, READ, 32, bus_num);
		read_transactions[0].data = read_data;

		// Setting wishbone to drive values from 0 to 31
		super.gen_h.set_slave_transactions(read_transactions);

		fork 
			super.run(); 
		join_any
		disable fork;

		$display("Consecutive read TEST COMPLETE. \n");

	endtask : run

endclass
