`timescale 1ns / 10ps

module top();

parameter int WB_ADDR_WIDTH = 2;
parameter int WB_DATA_WIDTH = 8;
parameter int NUM_I2C_BUSSES = 1;

typedef enum logic  [1:0] {
    CSR = 2'd0,
    DPR = 2'd1,
    CMDR = 2'd2,
    FSMR = 2'd3
} reg_offset;


bit  clk;
bit  rst = 1'b1;
wire cyc;
wire stb;
wire we;
tri1 ack;
wire [WB_ADDR_WIDTH-1:0] adr;
wire [WB_DATA_WIDTH-1:0] dat_wr_o;
wire [WB_DATA_WIDTH-1:0] dat_rd_i;
wire irq;
tri  [NUM_I2C_BUSSES-1:0] scl;
tri  [NUM_I2C_BUSSES-1:0] sda;

//global variables to track transfer
bit [7:0] read_data;
bit [6:0] read_address;
bit rw;
// ****************************************************************************
// Clock generator

always begin : clk_gen
     #5;
     clk = 0;
     #5
     clk = 1;
end

// ****************************************************************************
// Reset generator
initial begin : rst_gen
    #113 rst = 0;
end

// ****************************************************************************
// Monitor Wishbone bus and display transfers in the transcript
initial begin : wb_monitoring
    $timeformat(-9, 2, " ns", 6);
    wb_bus.master_monitor(read_address,read_data,rw);
    $display("Transaction at %t ns",$time);
    $display("address from WB_IF: %h",read_address);
    $display("data from WB_IF: %h",read_data);
    $display("write_enable from WB_IF:   %b", rw);
end

// ****************************************************************************
// Define the flow of the simulation

task wait4intr ();
	wait(irq);
	//read_data = 0;
	wb_bus.master_read(CMDR,read_data);
	//while(read_data != 8'b1xxxxxxx ) begin
	//	wb_bus.master_read(CMDR,read_data);
	//	if (read_data==8'bx1xxxxxx) begin
	//		$fatal("CMDR register = %0x which means we are getting NACK", read_data);
	//	end
	//end
endtask

initial begin : test_flow
	
	@(negedge rst);
	repeat(5) @(posedge clk);

 	//Enable the IICMB core after power-up
	wb_bus.master_write(CSR,8'b11xxxxxx);

	//Write byte 0x05 to the DPR. This is the ID of desired I2C bus
	wb_bus.master_write(DPR,8'h05);

	//Write byte “xxxxx110” to the CMDR. This is Set Bus command
	wb_bus.master_write(CMDR,8'bxxxxx110);

	//Wait for interrupt or until DON bit of CMDR reads '1'
	wait4intr();

	//Giving start command
	wb_bus.master_write(CMDR,8'bxxxxx100);

	//Waiting for Interrupt
	wait4intr();

	//Giving write command & slave address as 0x22
	wb_bus.master_write(DPR,8'h44);

	//Giving write command
	wb_bus.master_write(CMDR,8'bxxxxx001);

	//Wait for interrupt
	wait4intr();

	//byte to be written
	wb_bus.master_write(DPR,8'h78);

	//Next write command
	wb_bus.master_write(CMDR,8'bxxxxx001);

	//Wait for interrupt
	wait4intr();

	//Giving the stop command
	wb_bus.master_write(CMDR,8'bxxxxx101);
	
	//Wait for interrupt
	wait4intr();	
	
	@(posedge clk) $finish;

end

initial begin : max_timeout
	#250000 $display("stop the simulation");
	$finish;
end

// ****************************************************************************
// Instantiate the Wishbone master Bus Functional Model
wb_if       #(
      .ADDR_WIDTH(WB_ADDR_WIDTH),
      .DATA_WIDTH(WB_DATA_WIDTH)
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
  // Slave signals
  .cyc_i(),
  .stb_i(),
  .ack_o(),
  .adr_i(),
  .we_i(),
  // Shred signals
  .dat_o(dat_wr_o),
  .dat_i(dat_rd_i)
  );

reg_offset reg_addr;
assign reg_address = reg_offset'(adr);

// ****************************************************************************
// Instantiate the DUT - I2C Multi-Bus Controller
\work.iicmb_m_wb(str) #(.g_bus_num(NUM_I2C_BUSSES)) DUT
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

endmodule
