`timescale 1ns / 10ps

module top();
/*
Top level module to instantiate an I2C multiple bus controller, 
drive some basic signals to configure it, and monitor it.
*/

parameter int WB_ADDR_WIDTH = 2;    // Width of the Wishbone address bus
parameter int WB_DATA_WIDTH = 8;    // Width of the Wishbone data bus
parameter int NUM_I2C_BUSSES = 1;   // Number of I2C buses
parameter int I2C_ADDR_WIDTH = 7;
parameter int I2C_DATA_WIDTH = 8;
parameter int I2C_SLAVE_ADDRESS = 7'h22;

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
tri ack;
wire [WB_ADDR_WIDTH-1:0] adr;
wire [WB_DATA_WIDTH-1:0] dat_wr_o;
wire [WB_DATA_WIDTH-1:0] dat_rd_i;
wire irq;
tri  [NUM_I2C_BUSSES-1:0] scl;
triand  [NUM_I2C_BUSSES-1:0] sda;

//global variables to track transfer
bit [7:0] read_data_wb;
bit [6:0] read_address_wb_monitor;
bit Read_Write;
bit [WB_DATA_WIDTH-1:0] wb_data;

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
endtask

// ****************************************************************************
// Define the test flow of the simulation
// We use the Wishbone master Bus Functional Model (type wb_if, instance handle called wb_bus)
// The wb_bus BFM allows us to send commands on higher levels of abstractions
// And it takes care of the real time signal generation, and each function takes as long as it needs to
initial begin : test_flow
	
	@(negedge rst);             // Wait for the negative edge of the reset
	repeat(5) @(posedge clk);   // wait for five positive edges of the clock

	$display("TOP: Starting the IICMB core by powering up. \n");
 	// Enable the IICMB core and interrupts
	wb_bus.master_write(CSR,8'b11000000);

    // **********Modified from Example 3 on Pg 22!************
    // See the I2C Multiple Bus Controller IP Core Specification PDF
    // Task: Write 32 bytes to a slave with address 0x22, residing on I2C bus #0
    // System bus actions are as follows:
    $display("TOP: Doing configurations to select I2C bus using WB bus. \n");

    // 1. Write byte 0x00 to the data/parameter register. This is the ID of desired I2C bus
	wb_bus.master_write(DPR,8'h0);

	// 2. Write byte “xxxxx110” to the command register. This is Set Bus command (Pg 7)
	wb_bus.master_write(CMDR,8'bxxxxx110);

	// 3. Wait for interrupt to signal that a byte-level command has been completed, and then clear the interrupt
	wait4intr();

	// ************* WRITE 32 values *************

	// 4. Send the start command
	wb_bus.master_write(CMDR,8'bxxxxx100);

	// 5. Wait for interrupt to signal that a byte-level command has been completed, and then clear the interrupt
	wait4intr();

	// 6. Write byte 0x44 to the DPR. This is the slave address 0x22 shifted 1 bit to the left +
    // rightmost bit = '0', which means writing.
	wb_bus.master_write(DPR,8'h44);

	// 7. Write byte “xxxxx001” to the CMDR. This is Write command.
	wb_bus.master_write(CMDR,8'bxxxxx001);

	$display("TOP: Giving write command from WB to IICMB to perform 32 bytes write. \n");
	// 8. Wait for interrupt to signal that a byte-level command has been completed, and then clear the interrupt
	wait4intr();
	for (int i = 0; i<=31; i++) begin
	    // 9. Write byte 'i' to the DPR. This is the byte to be written.
		wb_bus.master_write(DPR,i);

	    // 10. Write byte “xxxxx001” to the CMDR. This is Write command.
		wb_bus.master_write(CMDR,8'bxxxxx001);

	    // 11. Wait for interrupt to signal that a byte-level command has been completed, and then clear the interrupt
		wait4intr();
	end

	// 12. Write byte “xxxxx101” to the CMDR. This is Stop command. It frees the selected I2C bus.
	wb_bus.master_write(CMDR,8'bxxxxx101);
	
	// 13. Wait for interrupt to signal that a byte-level command has been completed, and then clear the interrupt
	wait4intr();

	// ************* READ 32 values *************
    // Modified from Example 5 on Pg 23
    // See the I2C Multiple Bus Controller IP Core Specification PDF
    // Task: Read 32 bytes of data from a slave with address 0x22, residing on I2C bus #0
    // System bus actions are as follows:

	// 4. Write byte “xxxxx100” to the CMDR. This is Start command.
	wb_bus.master_write(CMDR,8'bxxxxx100);

	// 5. Wait for interrupt to signal that a byte-level command has been completed, and then clear the interrupt
	wait4intr();

	// 6. Write byte 0x46 to the DPR. This is the slave address 0x23 shifted 1 bit to the left +
    // rightmost bit is '1' which means reading.
	wb_bus.master_write(DPR,8'h45);

	// 7. Write byte “xxxxx001” to the CMDR. This is Write command.
	wb_bus.master_write(CMDR,8'bxxxxx001);

	// 8. Wait for interrupt to signal that a byte-level command has been completed, and then clear the interrupt
	wait4intr();

	$display("TOP: Giving read command from WB to IICMB to perform 32 bytes read. \n");
	$display("TOP: Reading DPR register from wishbone to capture data send from I2C slave. \n");

	for ( int i = 0; i < 32; i++) begin
		if (i == 31) begin
            // 17. Write byte “xxxxx011” to the CMDR. This is Read With Nak command.
			wb_bus.master_write(CMDR,8'bxxxxx011);
            // 18. Wait for interrupt to signal that a byte-level command has been completed, and then clear the interrupt
			wait4intr();
		end
		else begin
            // Read With Ack, Receive a byte with acknowledge.
			wb_bus.master_write(CMDR,8'bxxxxx010);
			wait4intr();
		end
		// 19. Read DPR to get received byte of data.
		wb_bus.master_read(DPR,wb_data);
	end
	// 20. Write byte “xxxxx101” to the CMDR. This is Stop command
	wb_bus.master_write(CMDR,8'bxxxxx101);
	
	// 21. Wait for interrupt to signal that a byte-level command has been completed, and then clear the interrupt
	wait4intr();

	//Alternate READ/WRITE 64 values//
	$display("TOP: Doing alternative write and read from Wishbone to I2C slave. \n");

	for(int i=0; i < 64; i++) begin
		write_transfer(64 + i);
		read_transfer(63 - i);
	end	

	@(posedge clk) $finish;
end


task read_transfer(input int data_to_be_transfered);
	// 4. Write byte “xxxxx100” to the CMDR. This is Start command.
	wb_bus.master_write(CMDR,8'bxxxxx100);

	// 5. Wait for interrupt to signal that a byte-level command has been completed, and then clear the interrupt
	wait4intr();

	// 6. Write byte 0x46 to the DPR. This is the slave address 0x23 shifted 1 bit to the left +
    // rightmost bit is '1' which means reading.
	wb_bus.master_write(DPR,8'h45);

	// 7. Write byte “xxxxx001” to the CMDR. This is Write command.
	wb_bus.master_write(CMDR,8'bxxxxx001);

	// 8. Wait for interrupt to signal that a byte-level command has been completed, and then clear the interrupt
	wait4intr();

	if (data_to_be_transfered == 0) begin
        // 17. Write byte “xxxxx011” to the CMDR. This is Read With Nak command.
		wb_bus.master_write(CMDR,8'bxxxxx011);
        // 18. Wait for interrupt to signal that a byte-level command has been completed, and then clear the interrupt
		wait4intr();
	end
	else begin
        // Read With Ack, Receive a byte with acknowledge.
		wb_bus.master_write(CMDR,8'bxxxxx010);
		wait4intr();
	end

	// 19. Read DPR to get received byte of data.
	wb_bus.master_read(DPR,wb_data);

	// 20. Write byte “xxxxx101” to the CMDR. This is Stop command
	wb_bus.master_write(CMDR,8'bxxxxx101);
	
	// 21. Wait for interrupt to signal that a byte-level command has been completed, and then clear the interrupt
	wait4intr();
endtask

task write_transfer(input int final_write_data);
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

	// 9. Write byte final_write_data to the DPR. This is the byte to be written.
	wb_bus.master_write(DPR,final_write_data);

	// 10. Write byte “xxxxx001” to the CMDR. This is Write command.
	wb_bus.master_write(CMDR,8'bxxxxx001);

	// 11. Wait for interrupt to signal that a byte-level command has been completed, and then clear the interrupt
	wait4intr();

	// 12. Write byte “xxxxx101” to the CMDR. This is Stop command. It frees the selected I2C bus.
	wb_bus.master_write(CMDR,8'bxxxxx101);

	// 13. Wait for interrupt to signal that a byte-level command has been completed, and then clear the interrupt
	wait4intr();
endtask

// ******** This is a new part not in lab 1! ********

initial begin : i2c_calling_task
	bit i2c_op;
	bit i2c_op_1;
	bit i2c_op_2;
	bit i2c_op_3;
	bit [I2C_DATA_WIDTH-1:0] write_data []; 
	bit [I2C_DATA_WIDTH-1:0] read_data [];
	bit transfer_complete;
	
	//Write 32 values
	i2c_bus.wait_for_i2c_transfer(i2c_op,write_data);

	//Read 32 values
	i2c_bus.wait_for_i2c_transfer(i2c_op_1,write_data);
	if( i2c_op_1 == 1 ) begin
		read_data = new [1];
		read_data[0] = 8'd100;
		i2c_bus.provide_read_data(read_data,transfer_complete);
	        read_data[0] = read_data[0] + 1;
		while(!transfer_complete) begin
			//$display("Entered if condition at the top");
			i2c_bus.provide_read_data(read_data,transfer_complete);
	        	read_data[0] = read_data[0] + 1;
		end
	end

	//Alternate Read Write
	read_data = new [1];
	read_data[0] = 8'd63;
	for(int i = 0; i < 64; i++) begin
		i2c_bus.wait_for_i2c_transfer(i2c_op_2,write_data);	
		i2c_bus.wait_for_i2c_transfer(i2c_op_3,write_data);
		if( i2c_op_3 == 1 ) begin
			i2c_bus.provide_read_data(read_data,transfer_complete);
		        read_data[0] = read_data[0] - 1;
		end
	end
end

// Timeout after a certain number of cycles
initial begin : timeout
	#50000000 $display("stop the simulation");
	$finish;
end

// Instantiate the I2C slave
i2c_if      #(
    .I2C_ADDR_WIDTH(I2C_ADDR_WIDTH),
    .I2C_DATA_WIDTH(I2C_DATA_WIDTH),
    .SLAVE_ADDRESS(I2C_SLAVE_ADDRESS)
)
i2c_bus (
  // Slave signals
  .scl(scl),
  .sda(sda)
);

// Calling monitor from I2C interface
initial begin : monitor_i2c_bus
    bit [I2C_ADDR_WIDTH-1:0] I2C_address;
    bit Read_Write;
    bit [I2C_DATA_WIDTH-1:0] I2C_data [];
    #200    forever begin
        i2c_bus.monitor(I2C_address,Read_Write,I2C_data);
        if (Read_Write==1) begin 
		$display("I2C_BUS READ Transfer: [%0t]\n I2C_address = %h\n Read_Write = READ\n I2C_data = %p\n",$time,I2C_address,I2C_data);
	end
	else begin
		$display("I2C_BUS WRITE Transfer: [%0t]\n I2C_address = %h\n Read_Write = WRITE\n I2C_data = %p\n",$time,I2C_address,I2C_data);
	end
    end
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
  // Master signals
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
