class bus_busy_capture_id_check extends i2cmb_test;

	i2c_transaction write_transactions [];
	int bus_num = 0;
	int write_value = 0;
	bit [WB_BYTE_SIZE-1:0] write_data []; 
	bit [WB_BYTE_SIZE-1:0] read_data; 


	function new(string name = "", ncsu_component_base parent = null);
		super.new(name,parent);
	endfunction : new


	virtual task run();

		$display("Consecutive write START \n");

  		write_data = new[1];
		write_consecutive_data(1);
		write_transactions = new[1];
		write_transactions[0] = new("Write random value", SLAVE_ADDRESS, WRITE, 32, bus_num);
		write_transactions[0].data = write_data;
		super.gen_h.set_master_transactions(write_transactions);
		super.gen_h.read_reg(CSR, read_data);
		read_data = 32 + read_data;
		super.gen_h.compare_actual_and_expected_val(read_data, 8'hf0);

		fork 
			super.run(); 
		join_any
		disable fork;

		$display("Consecutive write TEST COMPLETE. \n");

	endtask : run

	task write_consecutive_data (input max_value);

		while(write_value < max_value) begin
			write_data[write_value] = $urandom();
			write_value = write_value + 1;
		end

	endtask


endclass
