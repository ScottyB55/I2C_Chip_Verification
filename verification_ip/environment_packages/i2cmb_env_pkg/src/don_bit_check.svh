class don_bit_check extends i2cmb_test;

	i2c_transaction alt_master_transactions [];
	i2c_transaction alt_slave_transactions [];
	int bus_num = 0;
	int num_of_operation;
	int num_of_read_operation;
	int j = 0;
	bit [WB_BYTE_SIZE-1:0] read_data;

	function new(string name = "", ncsu_component_base parent = null);
		super.new(name,parent);
	endfunction : new


	virtual task run();

		bit [WB_BYTE_SIZE-1:0] alt_read_data []; 
		bit [WB_BYTE_SIZE-1:0] alt_write_data [];

		// Alternate read and write
		alt_master_transactions = new[4]; 
		alt_slave_transactions = new[2];
		alt_read_data = new[1];
		alt_write_data = new[1];
		
		// Setting master transactions
		while (num_of_operation < 4) begin
			alt_write_data[0] = j + 2;
			alt_master_transactions[num_of_operation] = new("Read by master", SLAVE_ADDRESS, READ, 1, bus_num);
			alt_master_transactions[num_of_operation + 1] = new("Write by master", SLAVE_ADDRESS, WRITE, 1, bus_num);
			alt_master_transactions[num_of_operation + 1].data = alt_write_data;
			num_of_operation = num_of_operation + 2;
			j = j + 1;
		end
		super.gen_h.set_master_transactions(alt_master_transactions);
		// Setting slave transactions
		while (num_of_read_operation < 2) begin
			alt_slave_transactions[num_of_read_operation] = new("Read by slave", SLAVE_ADDRESS, READ, 1, bus_num);
			alt_read_data[0] = 1 - num_of_read_operation;
			alt_slave_transactions[num_of_read_operation].data = alt_read_data;
			num_of_read_operation = num_of_read_operation + 1;
		end
		super.gen_h.set_slave_transactions(alt_slave_transactions);

		fork 
			super.run(); 
			super.gen_h.read_reg(CMDR, read_data);
			read_data = 240 + read_data;
			super.gen_h.compare_actual_and_expected_val(read_data, 8'h20);
		join_any
		disable fork;

		$display("Done bit check TEST COMPLETE. \n");

	endtask : run
endclass
