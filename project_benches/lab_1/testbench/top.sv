`timescale 1ns / 10ps

module top();
/*
Top level module to instantiate an I2C multiple bus controller, 
drive some basic signals to configure it, and monitor it.
*/

parameter int WB_ADDR_WIDTH = 2;    // Width of the Wishbone address bus
parameter int WB_DATA_WIDTH = 8;    // Width of the Wishbone data bus
parameter int NUM_I2C_BUSSES = 1;   // Number of I2C buses

// Defining the enumeration for register offsets
// See the I2C Multiple Bus Controller IP Core Specification PDF
typedef enum logic  [1:0] {
    CSR = 2'd0, // Control/Status Register, Pg 18
    DPR = 2'd1, // Data/Parameter Register, Pg 19
    CMDR = 2'd2,// Command Register, Pg 19
    FSMR = 2'd3 // FSM States Register, Pg 20
} reg_offset;

/* Declare the inputs, outputs, and internal signals required for the I2C bus controller */
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
// Reset generator, start high then set it low after a while
initial begin : rst_gen
    #113 rst = 0;
end

// ****************************************************************************
// Monitor Wishbone bus and display transfers in the transcript
initial begin : wb_monitoring
    // Variable declarations must happen before procedural statements!
    int file;   // Implicitly static and initialization removed form declaration
    file = $fopen("out_wb_monitor.txt", "w");

    $timeformat(-9, 2, " ns", 6);
    #5; // Wait a hair to make sure the signals are defined, to keep from infinitely looping at time t=0

    // Loops indefinitely
    forever begin
        // Waits for the cyc_o (cycle valid output) to be asserted, and exits when it is lowered
        // It logs the transaction details
        wb_bus.master_monitor(read_address,read_data,rw);
        // Then when cyc_o is lowered, we display the transaction details as a log
        $display("Transaction at %t ns",$time);
        $display("address from WB_IF: %h",read_address);
        $display("data from WB_IF: %h",read_data);
        $display("write_enable from WB_IF:   %b\n", rw);

        $fwrite(file, "Transaction at %t ns\n", $time);
        $fwrite(file, "address from WB_IF: %h\n", read_address);
        $fwrite(file, "data from WB_IF: %h\n", read_data);
        $fwrite(file, "write_enable from WB_IF:   %b\n\n", rw);
    end
    $fclose(file);
end

// The irq interrupt is an output from the DUT, Pg 17
// It's active high. It's generated when a byte-level command has been completed
// and the Interrupt Enable bit (IE) in the Control/Status Register (CSR) is equal to '1'.
// It can be cleared (reset to '0') by reading CMDR register
// Read data is a global variable to track the transfers
task wait4intr ();
    // Wait for the byte-level command to be completed (signaled by the DUT by irq interrupt pin)
	wait(irq);
    // Clear the interrupt by reading the CMDR Command Register (takes at least 2 clock cycles)
	wb_bus.master_read(CMDR,read_data);
    // Commented out: wait until the DON(E) bit of CMDR reads '1'
	/*while(read_data != 8'b1xxxxxxx ) begin
		wb_bus.master_read(CMDR,read_data);
		if (read_data==8'bx1xxxxxx) begin
			$fatal("CMDR register = %0x which means we are getting NACK", read_data);
		end
	end*/
endtask

// ****************************************************************************
// Define the test flow of the simulation
// We use the Wishbone master Bus Functional Model (type wb_if, instance handle called wb_bus)
// The wb_bus BFM allows us to send commands on higher levels of abstractions
// And it takes care of the real time signal generation, and each function takes as long as it needs to
initial begin : test_flow
	
	@(negedge rst);             // Wait for the negative edge of the reset
	repeat(5) @(posedge clk);   // wait for five positive edges of the clock

 	// Enable the IICMB core and interrupts
	wb_bus.master_write(CSR,8'b11xxxxxx);

    // **********Modeled off Example 3 on Pg 22!************
    // See the I2C Multiple Bus Controller IP Core Specification PDF
    // Task: Write a byte 0x78 to a slave with address 0x22, residing on I2C bus #5
    // System bus actions are as follows:

	// 1. Write byte 0x05 to the data/parameter register. This is the ID of desired I2C bus
	wb_bus.master_write(DPR,8'h05);

	// 2. Write byte “xxxxx110” to the command register. This is Set Bus command (Pg 7)
	wb_bus.master_write(CMDR,8'bxxxxx110);

	// 3. Wait for interrupt to signal that a byte-level command has been completed, and then clear the interrupt
	wait4intr();

	// 4. Send the start command
	wb_bus.master_write(CMDR,8'bxxxxx100);

	// 5. Wait for interrupt to signal that a byte-level command has been completed, and then clear the interrupt
	wait4intr();

	// 6. Write byte 0x44 to the DPR. This is the slave address 0x22 shifted 1 bit to the left +
    // rightmost bit = '0', which means writing.
	wb_bus.master_write(DPR,8'h44);

	// 7. Write byte “xxxxx001” to the CMDR. This is Write command.
	wb_bus.master_write(CMDR,8'bxxxxx001);

	// 8. Wait for interrupt to signal that a byte-level command has been completed, and then clear the interrupt
	wait4intr();

	// 9. Write byte 0x78 to the DPR. This is the byte to be written.
	wb_bus.master_write(DPR,8'h78);

	// 10. Write byte “xxxxx001” to the CMDR. This is Write command.
	wb_bus.master_write(CMDR,8'bxxxxx001);

	// 11. Wait for interrupt to signal that a byte-level command has been completed, and then clear the interrupt
	wait4intr();

	// 12. Write byte “xxxxx101” to the CMDR. This is Stop command. It frees the selected I2C bus.
	wb_bus.master_write(CMDR,8'bxxxxx101);
	
	// 13. Wait for interrupt to signal that a byte-level command has been completed, and then clear the interrupt
	wait4intr();	
	
	@(posedge clk) $finish;

end

// Timeout after a certain number of cycles
initial begin : max_timeout
	#250000 $display("stop the simulation");
	$finish;
end

// ****************************************************************************
// Instantiate the Wishbone master Bus Functional Model
// This allows us to drive the real time signals to the DUT with a higher layer of abstraction
wb_if       #(
      .ADDR_WIDTH(WB_ADDR_WIDTH),
      .DATA_WIDTH(WB_DATA_WIDTH)
      )
wb_bus (
  // System sigals
  .clk_i(clk),
  .rst_i(rst),
  // Master signals. We are just configuring the master.
  .cyc_o(cyc),
  .stb_o(stb),
  .ack_i(ack),
  .adr_o(adr),
  .we_o(we),
  // Slave signals. Nothing is connected here yet!
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
// And connect it to the same nets as our wishbone interface (wb_if) called wb_bus
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
