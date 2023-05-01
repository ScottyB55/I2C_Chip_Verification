// *****************************************************************************
// File: wb_driver.sv
// Description: This file contains the wb_driver class, which is a component
// that drives the Wishbone bus using the wb_if interface. The driver is
// responsible for converting high-level transactions into low-level
// Wishbone bus operations. It provides tasks for configuring the driver,
// putting transactions on the bus, and performing read and write operations.
// The wb_driver can be used in a larger verification environment to control
// and interact with devices connected to the Wishbone bus.
// *****************************************************************************

class wb_driver extends ncsu_component#(.T(ncsu_transaction));

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  virtual wb_if wb_intf_h;
  wb_configuration configuration;
  i2c_transaction wb_trans;
  wb_transaction wb_trans_h;

  // ****************************************************************************
  // Function: set_configuration
  // Description: Sets the configuration for the Wishbone driver
  // ****************************************************************************
  function void set_configuration(wb_configuration cfg);
    configuration = cfg;
  endfunction

  // ****************************************************************************
  // Task: configure_driver
  // Description: Configures the driver with the initial settings
  // ****************************************************************************
  task configure_driver();
  	wb_intf_h.master_write(CSR,8'b11000000);
  endtask

  // ****************************************************************************
  // Task: bl_put
  // Description: Puts a transaction on the bus, either performing a read or a write
  // ****************************************************************************
  virtual task bl_put(T trans);
  	$cast(wb_trans,trans);
	if(wb_trans.rw) begin
	       read_data_from_wb_master(wb_trans.address, wb_trans.bus_num, wb_trans.num_bytes, wb_trans.data);
	end
	else begin
	       write_data_from_wb_master(wb_trans.address, wb_trans.data, wb_trans.bus_num);
	end

  endtask

  // ****************************************************************************
  // Task: gen_bl_put
  // Description: Generates a transaction on the bus, either performing a read or a write
  // ****************************************************************************
  virtual task gen_bl_put(T trans);
      $cast(wb_trans_h,trans);
      if(wb_trans_h.rw) wb_intf_h.master_read(wb_trans_h.wb_addr, wb_trans_h.data);
      else wb_intf_h.master_write(wb_trans_h.wb_addr, wb_trans_h.data);
  endtask

  // ****************************************************************************
  // Task: op_done
  // Description: Waits for the current operation to complete
  // ****************************************************************************
task op_done();
  bit [WB_DATA-1:0] cmdr = 8'h00;
  wb_intf_h.wait_for_interrupt();
  wb_intf_h.master_read(CMDR, cmdr);
endtask

  // ****************************************************************************
  // Task: write_data_from_wb_master
  // Description: Performs a write operation from the Wishbone master
  // ****************************************************************************
task write_data_from_wb_master(
  bit [WB_DATA-1:0] wb_instr,
  bit [WB_DATA-1:0] write_data [],
  int bus_num
  );

  wb_intf_h.master_write(DPR,bus_num);
  wb_intf_h.master_write(CMDR,SET_BUS_CONFG);
  op_done();
  wb_intf_h.master_write(CMDR, START_CONFG);
  op_done();
  wb_intf_h.master_write(DPR, wb_instr << 1);
  wb_intf_h.master_write(CMDR, WRITE_CONFG);
  op_done();

  for(int i = 0; i < write_data.size(); i++) begin
    wb_intf_h.master_write(DPR, write_data[i]);
    wb_intf_h.master_write(CMDR, WRITE_CONFG);
    op_done();
  end
  wb_intf_h.master_write(CMDR, STOP_CONFG);
  op_done();
endtask

  // ****************************************************************************
  // Task: read_data_from_wb_master
  // Description: Performs a read operation from the Wishbone master
  // ****************************************************************************
task read_data_from_wb_master(
  bit [WB_DATA-1:0] wb_instr,
  int bus_num,
  int read_num,
  output bit [WB_DATA-1:0] read_data []
  );
  wb_intf_h.master_write(DPR,bus_num);
  wb_intf_h.master_write(CMDR,SET_BUS_CONFG);
  op_done();
  wb_intf_h.master_write(CMDR, START_CONFG);
  op_done();
  wb_intf_h.master_write(DPR, (wb_instr << 1) | 8'd1);
  wb_intf_h.master_write(CMDR, WRITE_CONFG);
  op_done();

  for(int i = 0; i < read_num-1; i++) begin
    wb_intf_h.master_write(CMDR, READ_ACK_CONFG);
    op_done();
    wb_intf_h.master_read(DPR, read_data[i]);
  end
  wb_intf_h.master_write(CMDR, READ_NAK_CONFG);
  op_done();
  wb_intf_h.master_read(DPR, read_data[read_num-1]);
  wb_intf_h.master_write(CMDR, STOP_CONFG);
  op_done();

endtask

endclass : wb_driver
