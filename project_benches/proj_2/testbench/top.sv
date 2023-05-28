`timescale 1ns / 10ps

/*
See Project 2 Assignment Specification https://drive.google.com/file/d/1Wwm0r40eOcAkUP1Ks8nou_rW9pNChVHT/view?usp=sharing
    - Slide 9

Changes from Project 1
    - Within test_flow initial block
        - Create an object of type i2cmb_testcase called testcase. Where the tests are = run() instead of directly in top.sv


Top level module to instantiate an I2C multiple bus controller, 
drive some basic signals to configure it, and monitor it.
*/

module top();
import ncsu_pkg::*;
import i2c_pkg::*;
import wb_pkg::*;
import i2cmb_env_pkg::*;

/* Declare the inputs, outputs, and internal signals required for the I2C bus controller */
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

// Taking instance of tests @ verification_ip/environment_packages/i2cmb_env_pkg/src/i2cmb_testcase.svh
i2cmb_testcase testcase;

// Instantiating I2c and wishbone interface (I2C Slave BFM)
i2c_if i2c_if_bus (
  // Slave signals
  .scl(scl[1]),
  .sda(sda[1])
  );

// ****************************************************************************
// Instantiate the Wishbone master Bus Functional Model
// This allows us to drive the real time signals to the DUT with a higher layer of abstraction
wb_if       #(
      .ADDR_WIDTH(WB_ADDR),
      .DATA_WIDTH(WB_DATA)
      )
wb_bus (
  // System sigals
  .clk_i(clk),
  .rst_i(rst),
  // Master signals
  .cyc_o(cyc),
  .stb_o(stb),
  .ack_i(ack),
  .adr_o(adr),
  .we_o(we),
  // Slave signals. Nothing is connected here yet. TODO: Why?
  .cyc_i(),
  .stb_i(),
  .ack_o(),
  .adr_i(),
  .we_i(),
  // Shared signals
  .dat_o(dat_wr_o),
  .dat_i(dat_rd_i)
  );

// ****************************************************************************
// Instantiate the DUT - I2C Multi-Bus Controller
// And connect it to the same nets as our wishbone interface (wb_if) called wb_bus
\work.iicmb_m_wb(str) #(.g_bus_num(NUM_I2C_SLAVES)) DUT
  (
    // ------------------------------------
    // -- Wishbone signals:
    .clk_i(clk),         // in    std_logic;                            -- Clock
    .rst_i(rst),         // in    std_logic;                            -- Synchronous reset (active high)
    // -------------
    .cyc_i(cyc),         // in    std_logic;                            -- Valid bus cycle indication
    .stb_i(stb),         // in    std_logic;                            -- Slave selection
    .ack_o(ack),         //   out std_logic;                            -- Acknowledge output
    .adr_i(adr),         // in    std_logic_vector(1 downto 0);         -- Low bits of Wishbone address
    .we_i(we),           // in    std_logic;                            -- Write enable
    .dat_i(dat_wr_o),    // in    std_logic_vector(7 downto 0);         -- Data input
    .dat_o(dat_rd_i),    //   out std_logic_vector(7 downto 0);         -- Data output
    // ------------------------------------
    // ------------------------------------
    // -- Interrupt request:
    .irq(irq),           //   out std_logic;                            -- Interrupt request
    // ------------------------------------
    // ------------------------------------
    // -- I2C interfaces:
    .scl_i(scl),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Clock inputs
    .sda_i(sda),         // in    std_logic_vector(0 to g_bus_num - 1); -- I2C Data inputs
    .scl_o(scl),         //   out std_logic_vector(0 to g_bus_num - 1); -- I2C Clock outputs
    .sda_o(sda)          //   out std_logic_vector(0 to g_bus_num - 1)  -- I2C Data outputs
    // ------------------------------------
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

// See Project 2 Slide 9
initial test_flow : begin
    // Place virtual interface handles into ncsu_config_db
    ncsu_config_db#(virtual i2c_if)::set("testcase.env_h.i2c_agent", i2c_if_bus);
    ncsu_config_db#(virtual wb_if)::set("testcase.env_h.wb_agent", wb_bus);
    // Construct the test class
    testcase = new("testcase",null);
    // Execute the run task of the test after reset is released
    wb_bus.wait_for_reset();
    testcase.run();
    // Execute $finish after test complete
    $finish();
end

initial begin
	#1000ms;
	$finish();
end

endmodule
