class i2cmb_testcase extends i2cmb_test;

	i2c_transaction write_transactions [];
	i2c_transaction read_transactions [];
	i2c_transaction read_transactions_wb [];
	i2c_transaction alt_master_transactions [];
	i2c_transaction alt_slave_transactions [];
	int bus_num = 0;
	int write_value;
	int num_of_read;
	int num_of_operation;
	int num_of_read_operation;
	int j;
	bit [WB_BYTE_SIZE-1:0] write_data []; 

	function new(string name = "", ncsu_component_base parent = null);
		super.new(name,parent);
	endfunction : new


	virtual task run();

		bit [WB_BYTE_SIZE-1:0] read_data []; 
		bit [WB_BYTE_SIZE-1:0] alt_read_data []; 
		bit [WB_BYTE_SIZE-1:0] alt_write_data []; 

		//$display("Test1: Write 0 to 31 to i2c bus from wishbone master \n");

  		write_data = new[32];
  		read_data = new[32];
		write_consecutive_data(32);
		write_transactions = new[1];
		write_transactions[0] = new("0-31_Write", SLAVE_ADDRESS, WRITE, 32, bus_num);
		write_transactions[0].data = write_data;
		super.gen_h.set_master_transactions(write_transactions);
		fork 
			super.run(); 
		join_any
		disable fork;

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

		$display("TEST COMPLETE. \n");

	endtask : run

    // Populates the write_data array starting at global write_value up until input max_value (exclusive)
	task write_consecutive_data (input max_value);

		while(write_value < max_value) begin
			write_data[write_value] = write_value;
			write_value = write_value + 1;
		end

	endtask


endclass
