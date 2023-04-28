class consecutive_write_test extends i2cmb_test;

	i2c_transaction write_transactions [];
	int bus_num = 0;
	int write_value = 0;
	bit [WB_BYTE_SIZE-1:0] write_data []; 

	function new(string name = "", ncsu_component_base parent = null);
		super.new(name,parent);
	endfunction : new


	virtual task run();

		$display("Consecutive write START \n");

  		write_data = new[32];
		write_consecutive_data(32);
		write_transactions = new[1];
		write_transactions[0] = new("0-31_Write", SLAVE_ADDRESS, WRITE, 32, bus_num);
		write_transactions[0].data = write_data;
		//$display("write_data = %0xp \n", write_data);
		//$display("write_transaction = %0xp \n", write_transactions[0].data);
		super.gen_h.set_master_transactions(write_transactions);
		fork 
			super.run(); 
		join_any
		disable fork;

		$display("Consecutive write TEST COMPLETE. \n");

	endtask : run

	task write_consecutive_data (input int max_value);

		while(write_value < max_value) begin
			write_data[write_value] = write_value;
			write_value = write_value + 1;
		end

	endtask


endclass
