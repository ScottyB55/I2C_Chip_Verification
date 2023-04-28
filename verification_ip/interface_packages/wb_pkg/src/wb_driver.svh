class wb_driver extends ncsu_component#(.T(ncsu_transaction));

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  virtual wb_if wb_intf_h;
  wb_configuration configuration;
  i2c_transaction wb_trans;
  wb_transaction wb_trans_h;

  function void set_configuration(wb_configuration cfg);
    configuration = cfg;
  endfunction

  task configure_driver();
  	wb_intf_h.master_write(CSR,8'b11000000);
  endtask

  virtual task bl_put(T trans);
  	$cast(wb_trans,trans);
	if(wb_trans.rw) begin
	       read_data_from_wb_master(wb_trans.address, wb_trans.bus_num, wb_trans.num_bytes, wb_trans.data);
	end
	else begin
	       write_data_from_wb_master(wb_trans.address, wb_trans.data, wb_trans.bus_num);
	end

  endtask

  virtual task gen_bl_put(T trans);
      $cast(wb_trans_h,trans);
      if(wb_trans_h.rw) wb_intf_h.master_read(wb_trans_h.wb_addr, wb_trans_h.data);
      else wb_intf_h.master_write(wb_trans_h.wb_addr, wb_trans_h.data);
  endtask

task op_done();
  bit [WB_DATA-1:0] cmdr = 8'h00;
  wb_intf_h.wait_for_interrupt();
  wb_intf_h.master_read(CMDR, cmdr);
endtask

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
