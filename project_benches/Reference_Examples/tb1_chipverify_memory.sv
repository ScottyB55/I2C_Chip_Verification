// https://www.chipverify.com/systemverilog/systemverilog-testbench-example-1

// Design
// Note that in this protocol, write data is provided
// in a single clock along with the address while read
// data is received on the next clock, and no transactions
// can be started during that time indicated by "ready" signal.
// I assume that a write cannot start while the previous one is reading,
// and this is why we don't need the threading and semaphore for a pipeline!

// This is what we are trying to verify. We don't need to understand how it is implemented.
// We only need to understand what it is supposed to do in terms of specifications.
module reg_ctrl
    # (
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 16,
    parameter DEPTH = 256,
    parameter RESET_VAL = 16'h1234
    )
    ( input clk,
    input rstn,
    input [ADDR_WIDTH-1:0] addr,
    input sel,
    input wr,
    input [DATA_WIDTH-1:0] wdata,
    output reg [DATA_WIDTH-1:0] rdata,
    output reg ready);
    // Some memory element to store data for each
    reg [DATA_WIDTH-1:0] ctrl [DEPTH];
    reg ready_dly;
    wire ready_pe;
    // If reset is asserted, clear the memory element
    // Else store data to addr for valid writes
    // For reads, provide read data back
    always @ (posedge clk) begin
        if (!rstn) begin
            for (int i = 0; i < DEPTH; i += 1) begin
                ctrl[i] <= RESET_VAL;
            end
            end else begin
            if (sel & ready & wr) begin
                ctrl[addr] <= wdata;
            end
            if (sel & ready & !wr) begin
                rdata <= ctrl[addr];
            end else begin
                rdata <= 0;
            end
        end
    end
    // Ready is driven using this always block
    // During reset, drive ready as 1
    // Else drive ready low for a clock low
    // for a read until the data is given back
    always @ (posedge clk) begin
        if (!rstn) begin
            ready <= 1;
        end else begin
            if (sel & ready_pe) begin
                ready <= 1;
            end
            if (sel & ready & !wr) begin
                ready <= 0;
            end
        end
    end
    // Drive internal signal accordingly
    always @ (posedge clk) begin
        if (!rstn) ready_dly <= 1;
        else ready_dly <= ready;
    end

    assign ready_pe = ~ready & ready_dly;
endmodule


// Transaction Object
// What we put in the mailbox between the driver & test/generator as well as the monitor & scoreboard
class reg_item;
    // This is the base transaction object that will be used
    // in the environment to initiate new transactions and
    // capture transactions at DUT interface
    
    // The rand types will be randomized when the randomize() function is called on this object!
    // The non rand types won't be randomized when this happens. Remember we can apply constraints with the 'with' keyword!
    rand bit [7:0] addr;
    rand bit [15:0] wdata;
    bit [15:0] rdata;
    rand bit wr;
    // This function allows us to print contents of the data packet
    // so that it is easier to track in a logfile
    function void print(string tag="");
        $display ("T=%0t [%s] addr=0x%0h wr=%0d",
                    $time, tag, addr, wr, wdata, rdata);
    endfunction
endclass


// The driver is responsible for driving transactions to the DUT
// Gets a transaction reg_item object from the mailbox,
// And convert it into real-time signals and drives it out to the interface to the DUT
class driver;
    virtual reg_if vif;
    event drv_done;
    mailbox drv_mbx; // Will use to get items that were put by the test/generator
    task run();
        $display ("T=%0t [Driver] starting ...", $time);
        @ (posedge vif.clk);

        // Try to get a new transaction every time and then assign
        // packet contents to the interface. But do this only if the
        // design is ready to accept new transactions
        forever begin
            reg_item item;

            $display ("T=%0t [Driver] waiting for item ...", $time);
            drv_mbx.get(item); // Wait for the test/generator to put an item
            // Fills & effectively returns the item as a reference argument passed to the function
            item.print("Driver");
            // Write all these during this clock cycle to be present on the rising edge of the next clock cycle (driver outputs)
            vif.sel <= 1;
            vif.addr <= item.addr;
            vif.wr <= item.wr;
            vif.wdata <= item.wdata;
            // Wait at least one clock cycle before setting sel back low
            @ (posedge vif.clk);
            // If the ready is low (driver input), keep waiting with all the information on the bus
            while (!vif.ready) begin
                $display ("T=%0t [Driver] wait until ready is high", $time);
                @(posedge vif.clk);
            end
            // When transfer is over, set sel back low
            // And raise the done event (which is not currently being used)
            vif.sel <= 0; ->drv_done;
        end
    endtask
endclass


// Monitor
// Captures live transactions / events on the interface bus, and converts
// them into a reg_item object (packet), and sends to the scoreboard
// using a mailbox.
// The monitor has a virtual interface handle which connects the monitor to the driver and DUT
// The interface is connected to the DUT in the instantiation of the reg_ctrl DUT module
// in the testbench top
class monitor;
    virtual reg_if vif;
    mailbox scb_mbx; // Mailbox connected to scoreboard
    task run();
        $display ("T=%0t [Monitor] starting ...", $time);
        // Check forever at every clock edge to see if there is a
        // valid transaction and if yes, capture info into a class
        // object and send it to the scoreboard when the transaction
        // is over.
        forever begin // loop forever
            @ (posedge vif.clk); // Wait until posedge clock event
            if (vif.sel) begin
                reg_item item = new;
                item.addr = vif.addr;
                item.wr = vif.wr;
                item.wdata = vif.wdata;
                // If we are doing a read, capture the read data on the next clock cycle
                if (!vif.wr) begin
                    @(posedge vif.clk);
                    item.rdata = vif.rdata;
                end
                item.print("Monitor");
                scb_mbx.put(item);
            end
        end
    endtask
endclass


// Scoreboard and Predictor
// The scoreboard is responsible to check data integrity. Since the design
// stores data it receives for each address, scoreboard helps to check if the 
// same data is received when the same address is read at any later point
// in time. So the scoreboard has a "memory" element which updates it
// internally for every write operation.
class scoreboard;
    mailbox scb_mbx;
    reg_item refq[256];
    task run();
        forever begin
            reg_item item;
            scb_mbx.get(item);
            item.print("Scoreboard");
            
            if (item.wr) begin // Handle Writes
                if (refq[item.addr] == null)
                    refq[item.addr] = new;
                refq[item.addr] = item;
                $display ("T=%0t [Scoreboard] Store addr=0x%0h wr=0x%0h data=0x%0h", $time, item.addr, item.wr, item.wdata);
            end

            else begin // Handle Reads
                // Check if it's a first time read before any writes to that address
                if (refq[item.addr] == null) begin
                    // If the read data from the monitor isn't the default expectation, flag an error
                    if (item.rdata != 'h1234)
                        $display ("T=%0t [Scoreboard] ERROR! First time read, addr=0x%0h exp=1234 act=0x%0h",
                                $time, item.addr, item.rdata);
                    else
                        $display ("T=%0t [Scoreboard] PASS! First time read, addr=0x%0h exp=1234 act=0x%0h",
                                $time, item.addr, item.rdata);
                end
                // If there is already a reg_item stored at this address (not read before first write)
                else begin
                    // If the item read data from the monitor doesn't match what we think it should be
                    // flag an error
                    if (item.rdata != refq[item.addr].wdata)
                        $display ("T=%0t [Scoreboard] ERROR! addr=0x%0h exp=0x%0h act=0x%0h",
                                    $time, item.addr, refq[item.addr].wdata, item.rdata);
                    else
                        $display ("T=%0t [Scoreboard] PASS! addr=0x%0h exp=0x%0h act=0x%0h",
                                    $time, item.addr, refq[item.addr].wdata, item.rdata);
                end
            end  
        end
    endtask
endclass

                                  
// Environment
// The environment is a container object simply to hold and connect all verification
// components together. This environment can then be reused later and all
// components in it would be automatically connected and available for use.
// This is an environment without a generator.
class env;
    // Member Variables
    driver d0; // Driver to desi
    monitor m0; // Monitor from d
    scoreboard s0; // Scoreboard con
    mailbox scb_mbx; // Top level mail
    virtual reg_if vif; // Virtual interf
    
    // New constructor function. Instantiate all testbench components
    function new();
        d0 = new;
        m0 = new;
        s0 = new;
        scb_mbx = new();
    endfunction
    
    // Assign handles and start all components so that
    // they all become active and wait for transactions to be
    // available
    virtual task run();
        // Share the interface between the driver and monitor
        d0.vif = vif;
        m0.vif = vif;
        // Share the mailbox between the monitor and scoreboard
        m0.scb_mbx = scb_mbx;
        s0.scb_mbx = scb_mbx;
        fork // start all of these tasks in parallel
            s0.run();
            d0.run();
            m0.run();
        join_any // run task finishes when any of these parallel tasks finish
    endtask
endclass

                                  
// Test Interface and Generator
// The environment does not include the generator, so the stimulus is 
// written in here in the test.
class test;
    // The enviornment connects everything together, but doesn't include the generator in this case
    env e0;
    // Create the mailbox to connect the generator (in this class) to the driver.
    mailbox drv_mbx;
    
    // New constructor function. Instantiate the environment and generator mailbox
    function new();
        drv_mbx = new();
        e0 = new();
    endfunction
    
    virtual task run();
        // Set the environment's driver's mailbox handle
        e0.d0.drv_mbx = drv_mbx;
        fork
        e0.run();
        join_none   // keep running this in parallel immediately when e0.run() starts,
        // no need to wait for e0.run() to finish (start the environment)
        apply_stim();
    endtask
    
    // Apply stimulus
    virtual task apply_stim();
        reg_item item;
        $display ("T=%0t [Test] Starting stimulus ...", $time);
        item = new;
        // Randomize all the rand and randc types with the constraints!
        if (!item.randomize() with { addr == 8'haa; wr == 1; })
            $fatal("Randomization failed");
        drv_mbx.put(item); // takes up some time and the scoreboard will do its thing in parallel
        item = new;
        if (!item.randomize() with { addr == 8'haa; wr == 0; })
            $fatal("Randomization failed");
        drv_mbx.put(item);
    endtask
endclass

                                  
// The interface allows verification components to access DUT signals
// using a virtual interface handle
interface reg_if (input bit clk);
    // logic datatypes can be driven in procedural and continuous assign statements!
    logic rstn;
    logic [7:0] addr;
    logic [15:0] wdata;
    logic [15:0] rdata;
    logic wr;
    logic sel;
    logic ready;
endinterface

                                  
// Testbench Top
// Top level testbench contains the interface, DUT and test handles which
// can be used to start test components once the DUT comes out of reset. Or
// the reset can also be a part of the test class in which case all you need
// to do is start the test's run method.
module tb;
    reg clk;

    // Generate the clock, inverting every #10 time units (pound delay)
    always #10 clk = ~clk;
    
    // Call the constructor to the pin interface to connect the DUT, driver, and monitor
    reg_if _if (clk);

    // Instantiate the dut of type reg_ctrl and connect it to the interface
    reg_ctrl u0 (.clk (clk),
                .addr (_if.addr),
                .rstn(_if.rstn),
                .sel (_if.sel),
                .wr (_if.wr),
                .wdata (_if.wdata),
                .rdata (_if.rdata),
                .ready (_if.ready));

    test t0 = new();  // Create the new instance at the same time you declare the handle

    initial begin
        // Apply reset at time = 0
        clk <= 0;
        _if.rstn <= 0;
        _if.sel <= 0;

        // At time = 20, release reset, create the new test object,
        // connect its environment to the interface, and run the test
        #20 _if.rstn <= 1;
        t0.e0.vif = _if;
        t0.run();
        // Once the main stimulus is over, wait for some time
        // until all transactions are finished and then end
        // simulation. Note that $finish is required because
        // there are components that are running forever in
        // the background like clk, monitor, driver, etc
        #200 $finish;
    end

    // Simulator dependent system tasks that can be used to
    // dump simulation waves.
    initial begin
        // Runs concurrently with other initial blocks
        
        // specifies the name of the output file where the dumped waveforms will be stored
        // **dumpfile should always be called before dumpvars!**
        $dumpfile("dump.vcd");

        // dumpvars is a system task that tells the simulator to record the changes in all the variables
        // and nets in your design. The waveform can be viewed using a waveform viewer, 
        // like ModelSim or GTKWave, which helps in debugging the code
        $dumpvars;
        
        // When the previous initial block runs the $finish command, we terminate the simulation
        // And $dumpvars and $dumpfile also finish
    end
endmodule
