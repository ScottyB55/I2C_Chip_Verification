parameter int I2C_SLAVE_ADDR_SIZE = 7;
parameter int I2C_BYTE_SIZE = 8;
enum bit {READ = 1'b1, WRITE = 1'b0} i2c_op_t;

`define OP_I2C_WRITE 1
`define OP_I2C_READ 0