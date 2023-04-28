class wb_transaction extends ncsu_transaction;
  bit [WB_SLAVE_ADDR_SIZE-1:0] wb_addr;
  bit [WB_BYTE_SIZE-1:0] data;
  bit rw;
  int bus_num;

  function new(string name="",
               bit [WB_SLAVE_ADDR_SIZE-1:0] wb_addr = 0,
               bit rw = 0, 
               int bus_num = 0
               ); 
    super.new(name);
    this.wb_addr = wb_addr;
    this.rw = rw;
    this.bus_num = bus_num;
  endfunction

  virtual function string convert2string();
    return {super.convert2string(),$sformatf("WB TRANS: WB_addr :0x%x rw:%x data:%p ", wb_addr, rw, data)};
  endfunction

endclass : wb_transaction
