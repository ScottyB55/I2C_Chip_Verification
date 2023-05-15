// *****************************************************************************
// File: i2c_if.sv
// Description: This file contains the i2c_if interface, which is a Bus
// Functional Model (BFM) for the I2C communication protocol. The interface
// implements the I2C protocol, handling low-level details such as clock cycle
// by clock cycle bit transfers, start and stop conditions, and sending and
// receiving ACK/NACK signals. The BFM provides tasks for common operations,
// such as waiting for a start condition, providing read data, and monitoring
// the I2C bus. The i2c_if interface can be used in a larger verification
// environment to model and verify the behavior of I2C devices, by abstracting
// the low-level details and providing a high-level API for interacting with
// the I2C bus.
// *****************************************************************************

`include "i2c_typedefs.svh"
`timescale 1ns / 10ps
interface i2c_if #(
	int I2C_ADDR_WIDTH=7,
	int I2C_DATA_WIDTH=8,
	int SLAVE_ADDRESS = 7'h22
)(
	input scl,
	inout triand sda
);
	
	//import i2c_pkg::*;
	event read_data_event;
	logic data_in = 1'b0;
	logic output_enable = 1'b0;
    // Setting output_enable to 0 (as it does with output_enable = 1'b0) disconnects the device from the sda line
    // (i.e., sets sda to high impedance). This allows the device to listen for the ACK/NACK signal from another device on the bus.
    // If output_enable is set to 1, the device will drive the sda line with the value of data_in.
	assign sda = output_enable ? data_in : 1'bz;

	/* ----------------------------------------------------------------------------
	Task: wait_for_i2c_transfer
    Description: Waits for an I2C transfer (either read or write operation) to
	complete (signaled by the stop condition). Captures the address, operation type, and data, then processes
	the operation accordingly.

    Outputs:
    - op is a binary output that indicates whether the operation is a write operation (op = 1) or a read operation (op = 0). 
    - write_data[] is an array that captures the data in the case of a write operation.

    TODO Flaws
    - Doesn't do anything for writes, and doesn't wait for a stop condition for writes either
	   ---------------------------------------------------------------------------- */
	task wait_for_i2c_transfer( output bit op, output bit [I2C_DATA_WIDTH-1:0] write_data []);
	
        // initialize local variables that will be used to control the flow of the function and capture the necessary data.
		automatic bit stop_write;
		automatic bit repeat_read_address;
		automatic bit [I2C_ADDR_WIDTH-1:0] capture_address;
		automatic bit [I2C_DATA_WIDTH-1:0] capture_data;
		automatic bit [I2C_DATA_WIDTH-1:0] cumulative_capture_data [$]; // dynamic queue to hold an bunch of words
		
        // Wait for a start condition on the I2C bus.
		start();
        // Read the address and operation type (read/write) from the I2C bus, and save that into capture_address and op
		read_address(capture_address, op);
        // Send an ack on the bus
		ack();
		if(op == 1) begin
            // We would be writing data to the I2C bus
		end
		else begin
            // We are reading data from the I2C bus
			@(negedge scl) output_enable <= 1'b0;
			read_data(capture_data);
            // Log the first word and send ack
			cumulative_capture_data.push_back(capture_data);
			ack();
			@(negedge scl) output_enable <= 1'b0;
			stop_write = 1'b0;
			repeat_read_address = 1'b0;
			//$display ("debug0: entered the wait_to_i2c_transfer_task with capture_data = %0x", capture_data);
			while(stop_write == 0) begin // Run until we get a stop condition
				fork // run all of these in parallel
					begin 
                        // Waits for another start condition on the I2C bus.
                        // If this occurs, we signal that a repeat read happened.
						start();
						repeat_read_address = 1'b1;
					end
					begin
                        // Waits for a stop condition on the I2C bus.
                        // If this occurs, we signal stop_write to exit the loop.
						stop_();
						stop_write = 1; 
					end
					begin
                        // If data is read properly, we allow for that
                        //$display("entered else loop capture_data=%0x", capture_data);
                        read_data(capture_data);
                        cumulative_capture_data.push_back(capture_data);
                        ack();
                        @(negedge scl) output_enable <= 1'b0;
					end
				join_any // If any of these finish, disable the rest of them and start them all again if stop_write == 0
				disable fork;
			end
            // Convert the dynamic queue into a dynamic array of bit [I2C_DATA_WIDTH-1:0]
			write_data = new[cumulative_capture_data.size()];	
			write_data = { >> {cumulative_capture_data}};
			//$display("WARNING! should not enter while reading");
		end
		//$display("Exiting write task");
	endtask
	
	
	// ----------------------------------------------------------------------------
	// Task: provide_read_data
	// Description: Sends the provided read_data to the I2C bus, following the
	// I2C protocol. It breaks if a NACK is received, assuming the transfer is
	// complete.
	// ----------------------------------------------------------------------------
	task provide_read_data( input bit [I2C_DATA_WIDTH-1:0] read_data []);
		automatic int size_of_read_data;
		automatic bit ack_m;

		size_of_read_data = read_data.size();
		//$display("sizeof_read_data=%0d \n",size_of_read_data);
		
		//$display ("debug1: entered the provide_read_data with read_data = %0x", read_data);
		for(int i = 0; i < size_of_read_data ; i++ ) begin
				parallel2serial(read_data[i]);
				wait4ack(ack_m);
				//$display("ack=%0b or nack received \n",ack_m);
				if(!ack_m) begin
					fork
						begin start(); end
						begin stop_(); end
					join_any
					disable fork;
				break;
				end
		end
		//transfer_complete = !ack_m;
	endtask
	
	
	// ----------------------------------------------------------------------------
	// Task: monitor
	// Description: Monitors the I2C bus and captures the address, operation type,
	// and the received data in an array.
	// ----------------------------------------------------------------------------
	task monitor( output bit [I2C_ADDR_WIDTH-1:0] addr, output bit op, output bit [I2C_DATA_WIDTH-1:0] data []);
		automatic bit stop_write;
		automatic bit repeat_read_address;
		automatic bit [I2C_ADDR_WIDTH-1:0] capture_address;
		automatic bit [I2C_DATA_WIDTH-1:0] capture_data;
		automatic bit [I2C_DATA_WIDTH-1:0] cumulative_capture_data [$];
		
			
		start();
		read_address(capture_address, op);
		addr <= capture_address;
		@(posedge scl);
		if(op == 1) begin
			->read_data_event;
		end
		read_data(capture_data);
		//$display("1st read_data capture_data=%0x \n",capture_data);
		cumulative_capture_data.push_back(capture_data);
		@(posedge scl);
		
		stop_write = 1'b0;
		repeat_read_address = 1'b0;

		while(stop_write == 0) begin
			fork
				begin 
					start();
					repeat_read_address = 1'b0;
				end
				begin
					stop_();
					stop_write = 1; 
				end
				begin
						if (repeat_read_address == 1) begin
							read_address(capture_address, op);
							@(posedge scl)
							read_data(capture_data);
							cumulative_capture_data.push_back(capture_data);
							@(posedge scl);
							repeat_read_address = 1'b0;
						end
						else begin
							read_data(capture_data);
							//$display("Dobara read_data capture_data=%0x \n",capture_data);
							cumulative_capture_data.push_back(capture_data);
							@(posedge scl);
						end
				end
			join_any
			disable fork;
		data = new[cumulative_capture_data.size()];	
		data = { >> {cumulative_capture_data}};	
		end

	endtask


	/* ----------------------------------------------------------------------------
	Task: wait4ack
	Description: Waits for an ACK (acknowledge) or NACK (not acknowledge) signal from the I2C bus.
    Output ack_m -> high for ACK, use previous ACK for NACK
	   ---------------------------------------------------------------------------- */
	task automatic wait4ack(output bit ack_m);
        // Wait for a falling edge on the scl (serial clock) signal.
        // Right after the falling edge of the clock, the data is allowed to change while the clock is low
        @(negedge scl)
        // Dsable the output of this BFM simulated I2C side, to allow us to listen for ACK or NACK that will come from
        // another device connected (typically the DUT)
		output_enable = 1'b0;
        // Wait for a rising edge on the scl (serial clock) signal
        // After this, the data (probs from the DUT) will be stable and ready to be read from the I2C bus
		@(posedge scl)
        if(sda == 0) begin
		    ack_m = 1'b1; // ack
		end
        else begin // TODO: potentially take this out! Could cause issues. Vishal's code remembered the previous in the event of NACK
            ack_m = 1'b0; // nack
        end
        // Typically, if there is an ack number and not an ack bit, we send back the previous successful ack number
        // If there is just an ack bit, send ack or nack for each one, not the previous
	endtask


	// ----------------------------------------------------------------------------
	// Task: parallel2serial
	// Description: Converts parallel data to serial data to be sent over the
	// I2C bus.
	// ----------------------------------------------------------------------------
	task automatic parallel2serial(input bit [I2C_DATA_WIDTH-1:0] read_data);
		//$display("parallel2serial read_data =%0b \n",read_data);
			for(int i = I2C_DATA_WIDTH -1; i >= 0 ; i--) begin
			@(negedge scl) begin 
				output_enable <= 1'b1; data_in <= read_data[i];
			end
		//$display("data_in=%0b bit ",data_in);
		//$display("read_data[i]=%0b bit ",read_data[i]);
		//$display("sda=%0b bit ",sda);
		end	
	endtask
	
	 
	// ----------------------------------------------------------------------------
	// Task: read_address
	// Description: Reads the address and operation type (read/write) from the I2C bus.
    // 1 for write, 0 for read
	// ----------------------------------------------------------------------------
	task automatic read_address(output bit [I2C_ADDR_WIDTH-1:0] capture_address, output bit op);
		automatic bit capture_address_queue[$];
		
		for(int i= I2C_ADDR_WIDTH-1; i >= 0; i--) begin
			//$display("i=%0x & sda=%0b \n",i,sda);
			@(posedge scl) begin 
			capture_address_queue.push_back(sda);
			end
		end
		capture_address = { >> {capture_address_queue}};
		//$display ("INTERFACE read address from queue =%0p", capture_address_queue);	
		//$display ("INTERFACE read address =%0x", capture_address);	
		//Read/Write bit
		//@(posedge scl) op = i2c_op_t'(sda);
		@(posedge scl) op = sda;
	endtask


	// ----------------------------------------------------------------------------
	// Task: read_data
	// Description: Reads data from the I2C bus and stores it in the
	// capture_data output variable.
	// ----------------------------------------------------------------------------
	task automatic read_data(output bit [I2C_DATA_WIDTH-1:0] capture_data);
		automatic bit capture_data_queue [$]; // declare a dynamic queue
		
        // Cycle through each bit of the data being read
		for(int i=(I2C_DATA_WIDTH-1); i >= 0; i--) begin
            // Sample data shortly at the posedge of the clock
            // The first bit transmitted will become the LSB and the last bit transmitted will become the MSB
            // This is the opposite of typical I2C
			@(posedge scl) begin 
				capture_data_queue.push_back(sda);
			end
		end
		// Unpack the capture_data_queue into bits and pack it back into the variable capture_data (bit vector)
		capture_data = { >> {capture_data_queue}};
	endtask
	

	// ----------------------------------------------------------------------------
	// Task: start
	// Description: Waits for a start condition on the I2C bus.
	// ----------------------------------------------------------------------------
	task automatic start();
		automatic bit start_flag = 1'b1;
		do begin
			@(negedge sda) begin
				if(scl) start_flag = 1'b0;
			end
		end
		while (start_flag);
		start_flag = 1'b1;
	endtask


	// ----------------------------------------------------------------------------
	// Task: stop_
	// Description: Waits for a stop condition on the I2C bus.
	// ----------------------------------------------------------------------------
	task automatic stop_();
		automatic bit stop_flag = 1'b1;
		do begin
			@(posedge sda) begin
				if(scl) stop_flag = 1'b0;
			end
		end
		while (stop_flag);
		stop_flag = 1'b1;
	endtask

	// ----------------------------------------------------------------------------
	// Task: ack
	// Description: Sends an ACK (acknowledge) signal on the I2C bus.
	// ----------------------------------------------------------------------------
	task automatic ack();
        // Wait for the clock to go low before we update the data on the bus
		@(negedge scl) begin
		    data_in <= 1'b0; 
			output_enable <= 1'b1;
		end
        // Make it consume a whole clock cycle, this is a standard throughout?
		@(posedge scl);
	endtask

endinterface
