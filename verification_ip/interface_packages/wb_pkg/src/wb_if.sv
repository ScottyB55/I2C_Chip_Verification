// *****************************************************************************
// File: wb_if.sv
// Description: This file contains the wb_if interface, which is a Bus
// Functional Model (BFM) for the Wishbone communication protocol. The interface
// implements the Wishbone protocol, handling low-level details such as signal
// transitions and timing. The BFM provides tasks for common operations, such as
// waiting for a reset, waiting for a specific number of clock cycles, and
// master read and write operations. The wb_if interface can be used in a larger
// verification environment to model and verify the behavior of Wishbone devices,
// by abstracting the low-level details and providing a high-level API for
// interacting with the Wishbone bus.
// *****************************************************************************

interface wb_if       #(
      int ADDR_WIDTH = 2,                                
      int DATA_WIDTH = 8                                
      )
(
  // System sigals
  input wire clk_i,
  input wire rst_i,
  input wire irq_i,
  // Master signals
  output reg cyc_o,
  output reg stb_o,
  input wire ack_i,
  output reg [ADDR_WIDTH-1:0] adr_o,
  output reg we_o,
  // Slave signals
  input wire cyc_i,
  input wire stb_i,
  output reg ack_o,
  input wire [ADDR_WIDTH-1:0] adr_i,
  input wire we_i,
  // Shred signals
  output reg [DATA_WIDTH-1:0] dat_o,
  input wire [DATA_WIDTH-1:0] dat_i
  );

  initial reset_bus();

  // ****************************************************************************
  // Task: wait_for_reset
  // Description: Waits for the rst_i signal to transition from high to low
  // ****************************************************************************
   task wait_for_reset();
       if (rst_i !== 0) @(negedge rst_i);
   endtask

  // ****************************************************************************
  // Task: wait_for_num_clocks
  // Description: Waits for a specific number of clock cycles
  // ****************************************************************************
   task wait_for_num_clocks(int num_clocks);
       repeat (num_clocks) @(posedge clk_i);
   endtask

  // ****************************************************************************
  // Task: wait_for_interrupt
  // Description: Waits for the irq_i signal to transition from low to high
  // ****************************************************************************
   task wait_for_interrupt();
       @(posedge irq_i);
   endtask

  // ****************************************************************************
  // Task: reset_bus
  // Description: Resets the state of the bus to its initial values
  // ****************************************************************************
   task reset_bus();
        cyc_o <= 1'b0;
        stb_o <= 1'b0;
        we_o <= 1'b0;
        adr_o <= 'b0;
        dat_o <= 'b0;
   endtask

  // ****************************************************************************
  // Task: master_write
  // Description: Performs a master write operation on the Wishbone bus
  // ****************************************************************************
  task master_write(
                   input bit [ADDR_WIDTH-1:0]  addr,
                   input bit [DATA_WIDTH-1:0]  data
                   );  

        @(posedge clk_i);
        adr_o <= addr;
        dat_o <= data;
        cyc_o <= 1'b1;
        stb_o <= 1'b1;
        we_o <= 1'b1;
        while (!ack_i) @(posedge clk_i);
        cyc_o <= 1'b0;
        stb_o <= 1'b0;
        adr_o <= 'bx;
        dat_o <= 'bx;
        we_o <= 1'b0;
        @(posedge clk_i);

endtask        

  // ****************************************************************************
  // Task: master_read
  // Description: Performs a master read operation on the Wishbone bus
  // ****************************************************************************    
task master_read(
                 input bit [ADDR_WIDTH-1:0]  addr,
                 output bit [DATA_WIDTH-1:0] data
                 );                                                  

        @(posedge clk_i);
        adr_o <= addr;
        dat_o <= 'bx;
        cyc_o <= 1'b1;
        stb_o <= 1'b1;
        we_o <= 1'b0;
        @(posedge clk_i);
        while (!ack_i) @(posedge clk_i);
        cyc_o <= 1'b0;
        stb_o <= 1'b0;
        adr_o <= 'bx;
        dat_o <= 'bx;
        we_o <= 1'b0;
        data = dat_i;

endtask        

  // ****************************************************************************
  // Task: master_monitor
  // Description: Monitors the master signals and captures the transaction
  //              details (address, data, and write enable)
  // ****************************************************************************
     task master_monitor(
                   output bit [ADDR_WIDTH-1:0] addr,
                   output bit [DATA_WIDTH-1:0] data,
                   output bit we                    
                  );
                         
          while (!cyc_o) @(posedge clk_i);                                                  
          while (!ack_i) @(posedge clk_i);
          addr = adr_o;
          we = we_o;
          if (we_o) begin
            data = dat_o;
          end else begin
            data = dat_i;
          end
          while (cyc_o) @(posedge clk_i);                                                  
     endtask 

endinterface
