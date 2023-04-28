class i2cmb_generator extends ncsu_component#(.T(ncsu_transaction));

  i2c_transaction slave_transactions [];
  i2c_transaction master_transactions [];
  wb_transaction wb_trans_h;

  i2c_agent i2c_agent_h;
  wb_agent wb_agent_h;

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  virtual task run_wb();
	foreach(master_transactions[i]) begin
		wb_agent_h.bl_put(master_transactions[i]);
	    	//$display("I2CMB GENERATOR : WB transactions : ", master_transactions[i].convert2string());
	end
  endtask

  task wait_for_read_request(); 
  	wait(i2c_agent_h.bus.read_data_event);
  endtask

  virtual task run_i2c();
  	foreach(slave_transactions[i]) begin
	  	wait_for_read_request();
	  	i2c_agent_h.bl_put(slave_transactions[i]);
	  	//$display("I2CMB GENERATOR : I2C transactions : ",slave_transactions[i].convert2string());
  	end
  endtask

  task read_reg(input bit [WB_ADDR-1:0] read_addr, output bit [WB_DATA - 1:0] read_data);
      wb_trans_h = new;
      wb_trans_h.wb_addr = read_addr;
      wb_trans_h.rw = 1;
      wb_agent_h.gen_bl_put(wb_trans_h);
      read_data = wb_trans_h.data;
      $display("Reset Value Collected for Addr = %0d is CSR: %x", read_addr, read_data);
  endtask

  task write_reg(input bit [WB_ADDR-1:0] write_addr, input bit [WB_DATA - 1:0] write_data);
      wb_trans_h = new;
      wb_trans_h.wb_addr = write_addr;
      wb_trans_h.rw = 0;
      wb_trans_h.data = write_data;
      wb_agent_h.gen_bl_put(wb_trans_h);
      $display("Writing to Addr = %0d with value: %x", write_addr, write_data);
  endtask

  task compare_actual_and_expected_val(input bit [WB_DATA - 1:0] actual_data, input bit [WB_DATA - 1:0] expected_data);
	  if (actual_data == expected_data) begin
		  $display("Actual value of register is = %0x which is equal to expected val which is = %0x \n", actual_data, expected_data);
	  end
	  else begin
		  $display("Actual value of register = %0x which is not equal to expected val which is %0x \n", actual_data, expected_data);
	  end
  endtask

  task default_offset_check();
	bit [WB_DATA-1:0] read_data;

	//$display ("DEFAULT REG VALUE READ START\n");
	read_reg(CSR, read_data);
	compare_actual_and_expected_val(read_data, 8'hc0);
	read_reg(DPR, read_data);
	compare_actual_and_expected_val(read_data, DPR_RESET_VAL);
	read_reg(CMDR, read_data);
	compare_actual_and_expected_val(read_data, CMDR_RESET_VAL);
	read_reg(FSMR, read_data);
	compare_actual_and_expected_val(read_data, FSMR_RESET_VAL);
	//$display ("DEFAULT REG VALUE READ END \n");

  endtask

  task read_write_permission();
	bit [WB_DATA-1:0] read_data;
	bit [WB_DATA-1:0] write_data;

	$display ("REG PERMISSION START\n");
	write_data = 8'hff;
	write_reg(CSR, write_data);
	read_reg(CSR, read_data);
	compare_actual_and_expected_val(read_data, 8'hc0);

	write_reg(DPR, write_data);
	read_reg(DPR, read_data);
	compare_actual_and_expected_val(read_data, 8'h00);

	write_reg(FSMR, write_data);
	read_reg(FSMR, read_data);
	compare_actual_and_expected_val(read_data, FSMR_RESET_VAL);

	write_data = 8'hfd;
	write_reg(CMDR, write_data);
	read_reg(CMDR, read_data);
	compare_actual_and_expected_val(read_data, 8'h15);
	$display ("REG PERMISSION END \n");
  endtask

 task reset_iicm_check();
	bit [WB_DATA-1:0] read_data;
	bit [WB_DATA-1:0] write_data;

	$display ("RESET CHECK START\n");
	write_data = 8'haa;
	write_reg(DPR, write_data);
	read_reg(DPR, read_data);
	compare_actual_and_expected_val(8'haa, write_data);
	// Resetting the core
	write_data = 8'h00;
	write_reg(CSR, write_data);
	read_reg(DPR, read_data);
	compare_actual_and_expected_val(read_data, write_data);
	$display ("RESET CHECK END\n");
  endtask

  task error_check();
	bit [WB_DATA-1:0] read_data;
	bit [WB_DATA-1:0] write_data;

	write_data = 8'h7;
	write_reg(CMDR, write_data);
	read_reg(CMDR, read_data);
	compare_actual_and_expected_val(read_data, 8'h17);   
  endtask

task write_on_read_only_register();
	bit [WB_DATA-1:0] read_data;
	bit [WB_DATA-1:0] write_data;
	bit [WB_DATA-1:0] expected_data;

	write_data = $urandom;
	write_reg(CSR, write_data);
	read_reg(CSR, read_data);
	
	write_data = $urandom;
	write_reg(DPR, write_data);
	read_reg(DPR, read_data);

	write_data = $urandom;
	write_reg(CMDR, write_data);
	read_reg(CMDR, read_data);

	write_data = $urandom;
	write_reg(FSMR, write_data);
	read_reg(FSMR, read_data);
	$display("write_on_read_only_register Done!\n");
  endtask

 task register_aliasing();
	bit [WB_DATA-1:0] read_data;
	bit [WB_DATA-1:0] write_data;
	write_data = $urandom;
	write_reg(DPR, write_data);
	read_reg(DPR, read_data);
	default_offset_check();

  endtask

  function void set_agent(i2c_agent i2c_agent, wb_agent	wb_agent);
    this.i2c_agent_h = i2c_agent;
    this.wb_agent_h = wb_agent;
  endfunction

  function void set_master_transactions(i2c_transaction i2c_trans []);
    this.master_transactions = i2c_trans;
  endfunction

  function void set_slave_transactions(i2c_transaction wb_trans []);
    this.slave_transactions = wb_trans;
  endfunction

endclass : i2cmb_generator
