class i2c_transaction extends ncsu_transaction;
  bit [I2C_SLAVE_ADDR_SIZE-1:0] address;
  bit rw;
  bit [I2C_BYTE_SIZE-1:0] data [];
  int num_bytes;
  int bus_num;

  function new(string name="",
               bit [I2C_SLAVE_ADDR_SIZE-1:0] address = 0,
               bit rw = WRITE, 
               int num_bytes = 0,
               int bus_num = 0
               ); 
    super.new(name);
    this.address = address;
    this.rw = rw;
    this.num_bytes = num_bytes;
    this.bus_num = bus_num;
  endfunction

  virtual function string convert2string();
    return {super.convert2string(),$sformatf("num_bytes:%d address:0x%x rw:%x data:%p", num_bytes, address, rw, data)};
  endfunction

endclass : i2c_transaction
