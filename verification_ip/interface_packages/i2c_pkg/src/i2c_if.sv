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
	assign sda = output_enable ? data_in : 1'bz;

	//task wait_for_i2c_transfer ( output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] write_data []);
	task wait_for_i2c_transfer ( output bit op, output bit [I2C_DATA_WIDTH-1:0] write_data []);
	
		automatic bit stop_write;
		automatic bit repeat_read_address;
		automatic bit [I2C_ADDR_WIDTH-1:0] capture_address;
		automatic bit [I2C_DATA_WIDTH-1:0] capture_data;
		automatic bit [I2C_DATA_WIDTH-1:0] cumulative_capture_data [$];
		
			
		start();
		read_address(capture_address, op);
		ack();
		if(op == 1) begin
			//$display ("op=%0d" , op);
			//$display ("debug3: entered the wait_to_i2c_transfer_task with");
		end
		else begin
			@(negedge scl) output_enable <= 1'b0;
			read_data(capture_data);
			cumulative_capture_data.push_back(capture_data);
			ack();
			@(negedge scl) output_enable <= 1'b0;
			stop_write = 1'b0;
			repeat_read_address = 1'b0;
			//$display ("debug0: entered the wait_to_i2c_transfer_task with capture_data = %0x", capture_data);
			while(stop_write == 0) begin
				fork
					begin 
						start();
						repeat_read_address = 1'b1;
					end
					begin
						stop_();
						stop_write = 1; 
					end
					begin
						if (repeat_read_address == 1) begin
							//read_address(capture_address, op);
							//ack();
							//@(negedge scl) output_enable <= 1'b0;
							read_data(capture_data);
							cumulative_capture_data.push_back(capture_data);
							ack();
							@(negedge scl) output_enable <= 1'b0;
							repeat_read_address = 1'b0;
						end
						else begin
							read_data(capture_data);
							cumulative_capture_data.push_back(capture_data);
							//$display("entered else loop capture_data=%0x", capture_data);
							ack();
							@(negedge scl) output_enable <= 1'b0;
						end
					end
				join_any
				disable fork;
			end
			write_data = new[cumulative_capture_data.size()];	
			write_data = { >> {cumulative_capture_data}};
			//$display("WARNING! should not enter while reading");
		end
		//$display("Exiting write task");
	endtask
	
	
	//task provide_read_data ( input bit [I2C_DATA_WIDTH-1:0] read_data [], output bit transfer_complete);
	task provide_read_data ( input bit [I2C_DATA_WIDTH-1:0] read_data []);
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
	
	
	
	
	task monitor ( output bit [I2C_ADDR_WIDTH-1:0] addr, output bit op, output bit [I2C_DATA_WIDTH-1:0] data []);
	//task monitor ( output bit [I2C_ADDR_WIDTH-1:0] addr, output i2c_op_t op, output bit [I2C_DATA_WIDTH-1:0] data []);
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
	
	task automatic wait4ack (output bit ack_m);
		@(negedge scl) output_enable = 1'b0;
		@(posedge scl) if(sda == 0) begin
		ack_m = 1'b1;
		end
	endtask

	task automatic parallel2serial (input bit [I2C_DATA_WIDTH-1:0] read_data);
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
	
	 
	//task automatic read_address (output bit [I2C_ADDR_WIDTH-1:0] capture_address, output i2c_op_t op);
	task automatic read_address (output bit [I2C_ADDR_WIDTH-1:0] capture_address, output bit op);
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
	
	task automatic read_data (output bit [I2C_DATA_WIDTH-1:0] capture_data);
		automatic bit capture_data_queue [$];
		
		for(int i=(I2C_DATA_WIDTH-1); i >= 0; i--) begin
			@(posedge scl) begin 
				capture_data_queue.push_back(sda);
			end
		end
		
		capture_data = { >> {capture_data_queue}};
	endtask
	
	
	task automatic start ();
		automatic bit start_flag = 1'b1;
		do begin
			@(negedge sda) begin
				if(scl) start_flag = 1'b0;
			end
		end
		while (start_flag);
		start_flag = 1'b1;
	endtask
	
	task automatic stop_ ();
		automatic bit stop_flag = 1'b1;
		do begin
			@(posedge sda) begin
				if(scl) stop_flag = 1'b0;
			end
		end
		while (stop_flag);
		stop_flag = 1'b1;
	endtask
	
	task automatic ack ();
		@(negedge scl) begin
		       	data_in <= 1'b0; 
			output_enable <= 1'b1;
		end
		@(posedge scl);
		//@(negedge scl) output_enable <= 1'b0;
	endtask

endinterface
