  parameter int I2C_SLAVE_ADDR_SIZE = 7;
  parameter int I2C_BYTE_SIZE = 8;
  typedef struct {
    bit [I2C_SLAVE_ADDR_SIZE-1:0] address;
    bit rw; 
  } i2c_op_t;
