`timescale 1ns / 10ps

module top();

parameter int WB_ADDR_WIDTH = 2;
parameter int WB_DATA_WIDTH = 8;
parameter int NUM_I2C_BUSSES = 1;
parameter int I2C_ADDR_WIDTH = 7;
parameter int I2C_DATA_WIDTH = 8;
parameter int I2C_SLAVE_ADDRESS = 7'h22;

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
    wb_bus.master_monitor(read_address_wb_monitor,read_data_wb,Read_Write);
    $display("Transaction at %t ns",$time);
    $display("address from WB_IF: %h",read_address_wb_monitor);
    $display("data from WB_IF: %h",read_data_wb);
    $display("write_enable from WB_IF:   %b", Read_Write);
end

// ****************************************************************************
// Define the flow of the simulation

task wait4intr ();
	wait(irq);
	wb_bus.master_read(CMDR,read_data_wb);
endtask

initial begin : test_flow
	
	@(negedge rst);
	repeat(5) @(posedge clk);

	$display("TOP: Starting the IICMB core by powering up. \n");
 	//Enable the IICMB core after power-up
	wb_bus.master_write(CSR,8'b11000000);

	$display("TOP: Doing configurations to select I2C bus using WB bus. \n");
	//Write byte 0x05 to the DPR. This is the ID of desired I2C bus
	wb_bus.master_write(DPR,8'h0);

	//Write byte “xxxxx110” to the CMDR. This is Set Bus command
	wb_bus.master_write(CMDR,8'bxxxxx110);

	//Wait for interrupt or until DON bit of CMDR reads '1'
	wait4intr();

	//WRITE 32 values

	//Giving start command
	wb_bus.master_write(CMDR,8'bxxxxx100);

	//Waiting for Interrupt
	wait4intr();

	//Giving write command & slave address as 0x22
	wb_bus.master_write(DPR,8'h44);

	//Giving write command
	wb_bus.master_write(CMDR,8'bxxxxx001);

	$display("TOP: Giving write command from WB to IICMB to perform 32 bytes write. \n");
	//Wait for interrupt
	wait4intr();
	for (int i = 0; i<=31; i++) begin
		//byte to be written
		wb_bus.master_write(DPR,i);

		//Write command
		wb_bus.master_write(CMDR,8'bxxxxx001);

		//Wait for interrupt
		wait4intr();
	end

	//Giving the stop command
	wb_bus.master_write(CMDR,8'bxxxxx101);
	
	//Wait for interrupt
	wait4intr();

	//READ 32 values

	//Giving write command
	wb_bus.master_write(CMDR,8'bxxxxx100);

	//Wait for interrupt
	wait4intr();

	//Giving write command & slave address as 0x22
	wb_bus.master_write(DPR,8'h45);

	//Giving write command
	wb_bus.master_write(CMDR,8'bxxxxx001);

	//Wait for interrupt
	wait4intr();

	$display("TOP: Giving read command from WB to IICMB to perform 32 bytes read. \n");
	$display("TOP: Reading DPR register from wishbone to capture data send from I2C slave. \n");

	for ( int i = 0; i < 32; i++) begin
		if (i == 31) begin
			wb_bus.master_write(CMDR,8'bxxxxx011);
			wait4intr();
		end
		else begin
			wb_bus.master_write(CMDR,8'bxxxxx010);
			wait4intr();
		end
		// Read DPR to get received byte of data
		wb_bus.master_read(DPR,wb_data);
	end
	//Giving the stop command
	wb_bus.master_write(CMDR,8'bxxxxx101);
	
	//Wait for interrupt
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
	//Giving write command
	wb_bus.master_write(CMDR,8'bxxxxx100);

	//Wait for interrupt
	wait4intr();

	//Giving write command & slave address as 0x22
	wb_bus.master_write(DPR,8'h45);

	//Giving write command
	wb_bus.master_write(CMDR,8'bxxxxx001);

	//Wait for interrupt
	wait4intr();

	if (data_to_be_transfered == 0) begin
		wb_bus.master_write(CMDR,8'bxxxxx011);
		wait4intr();
	end
	else begin
		wb_bus.master_write(CMDR,8'bxxxxx010);
		wait4intr();
	end

	// Read DPR to get received byte of data
	wb_bus.master_read(DPR,wb_data);

	//Giving the stop command
	wb_bus.master_write(CMDR,8'bxxxxx101);
	
	//Wait for interrupt
	wait4intr();
endtask

task write_transfer(input int final_write_data);

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
	wb_bus.master_write(DPR,final_write_data);

	//Write command
	wb_bus.master_write(CMDR,8'bxxxxx001);

	//Wait for interrupt
	wait4intr();

	//Giving the stop command
	wb_bus.master_write(CMDR,8'bxxxxx101);
	
	//Wait for interrupt
	wait4intr();


endtask

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
