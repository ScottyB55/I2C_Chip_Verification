`timescale 1ns / 10ps

module top();
import ncsu_pkg::*;
import i2c_pkg::*;
import wb_pkg::*;
import i2cmb_env_pkg::*;

bit  clk;
bit  rst = 1'b1;
wire cyc;
wire stb;
wire we;
tri1 ack;
wire [WB_ADDR-1:0] adr;
wire [WB_DATA-1:0] dat_wr_o;
wire [WB_DATA-1:0] dat_rd_i;
wire irq;
tri  [NUM_I2C_SLAVES-1:0] scl;
triand  [NUM_I2C_SLAVES-1:0] sda;

//i2c bus
bit [I2C_SLAVE_ADDR_SIZE-1:0]   addr;
bit [I2C_BYTE_SIZE-1:0] data [];
bit [WB_DATA-1:0] data_slave [];

// Taking instance of tests
i2cmb_testcase testcase;

// Instantiating I2c and wishbone interface
i2c_if i2c_if_bus (
  .scl(scl[1]),
  .sda(sda[1])
  );

wb_if       #(
      .ADDR_WIDTH(WB_ADDR),
      .DATA_WIDTH(WB_DATA)
      )
wb_bus (
  .clk_i(clk),
  .rst_i(rst),
  .irq_i(irq),
  .cyc_o(cyc),
  .stb_o(stb),
  .ack_i(ack),
  .adr_o(adr),
  .we_o(we),
  .cyc_i(),
  .stb_i(),
  .ack_o(),
  .adr_i(),
  .we_i(),
  .dat_o(dat_wr_o),
  .dat_i(dat_rd_i)
  );

// Instantiating Iicmb 

\work.iicmb_m_wb(str) #(.g_bus_num(NUM_I2C_SLAVES)) DUT
  (
    .clk_i(clk),        
    .rst_i(rst),       
    .cyc_i(cyc),         
    .stb_i(stb),         
    .ack_o(ack),        
    .adr_i(adr),        
    .we_i(we),           
    .dat_i(dat_wr_o),    
    .dat_o(dat_rd_i),    
    .irq(irq),           
    .scl_i(scl),         
    .sda_i(sda),         
    .scl_o(scl),         
    .sda_o(sda)          
  );

// Clock generator
initial begin
  forever begin
	  clk = 1'b0;
	  #5;
	  clk = 1'b1;
	  #5;
   end
end

// Resetting the Core
initial begin
  rst = 1'b1;
  #113
  rst = 1'b0;
end

// Setting virtual interface for all tests and triggering the run
initial test_flow : begin
  
  ncsu_config_db#(virtual i2c_if)::set("testcase.env_h.i2c_agent", i2c_if_bus);
  ncsu_config_db#(virtual wb_if)::set("testcase.env_h.wb_agent", wb_bus);
  testcase = new("testcase",null);
  wb_bus.wait_for_reset();
  testcase.run();
  
  $finish();
end

initial begin
	#1000ms;
	$finish();
end

endmodule
