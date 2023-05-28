/**
 * The `i2cmb_generator` class, extending `ncsu_component`, is used to define the behavior 
 * of the I2C Master and Wishbone transactions and execute the various test tasks.
 */
class i2cmb_generator extends ncsu_component#(.T(ncsu_transaction));

    i2c_transaction slave_transactions [];
    i2c_transaction master_transactions [];
    wb_transaction wb_trans_h;

    i2c_agent i2c_agent_h;
    wb_agent wb_agent_h;

    /**
    * The constructor for the `i2cmb_generator` class.
    * @param name The name of the instance.
    * @param parent The parent component for this instance.
    */
    function new(string name = "", ncsu_component_base  parent = null); 
        super.new(name,parent);
    endfunction

    /**
    * The `run_wb` task iterates over each of the master transactions and sends them to the Wishbone agent.
    */
    virtual task run_wb();
        foreach(master_transactions[i]) begin
            wb_agent_h.bl_put(master_transactions[i]);
            //$display("I2CMB GENERATOR : WB transactions : ", master_transactions[i].convert2string());
        end
    endtask

    /**
    * The `wait_for_read_request` task waits for a read request event from the I2C bus.
    */
    task wait_for_read_request(); 
        wait(i2c_agent_h.bus.read_data_event);
    endtask

    /**
    * The `run_i2c` task iterates over each of the slave transactions, waits for a read request, and sends them to the I2C agent.
    */
    virtual task run_i2c();
        foreach(slave_transactions[i]) begin
            wait_for_read_request();
            i2c_agent_h.bl_put(slave_transactions[i]);
            //$display("I2CMB GENERATOR : I2C transactions : ",slave_transactions[i].convert2string());
        end
    endtask

    /**
    * The `read_reg` task reads data from the specified register address.
    * @param read_addr The register address to read data from.
    * @param read_data The data read from the register address.
    */
    task read_reg(input bit [WB_ADDR-1:0] read_addr, output bit [WB_DATA - 1:0] read_data);
        wb_trans_h = new;
        wb_trans_h.wb_addr = read_addr;
        wb_trans_h.rw = 1;
        wb_agent_h.gen_bl_put(wb_trans_h);
        read_data = wb_trans_h.data;
        $display("Reset Value Collected for Addr = %0d is CSR: %x", read_addr, read_data);
    endtask

    /**
    * The `write_reg` task writes data to the specified register address.
    * @param write_addr The register address to write data to.
    * @param write_data The data to write to the register address.
    */
    task write_reg(input bit [WB_ADDR-1:0] write_addr, input bit [WB_DATA - 1:0] write_data);
        wb_trans_h = new;
        wb_trans_h.wb_addr = write_addr;
        wb_trans_h.rw = 0;
        wb_trans_h.data = write_data;
        wb_agent_h.gen_bl_put(wb_trans_h);
        $display("Writing to Addr = %0d with value: %x", write_addr, write_data);
    endtask

    /**
    * The `compare_actual_and_expected_val` task compares the actual and expected data values and displays the comparison results.
    * @param actual_data The actual data value.
    * @param expected_data The expected data value.
    */
    task compare_actual_and_expected_val(input bit [WB_DATA - 1:0] actual_data, input bit [WB_DATA - 1:0] expected_data);
        if (actual_data == expected_data) begin
            $display("Actual value of register is = %0x which is equal to expected val which is = %0x \n", actual_data, expected_data);
        end
        else begin
            $display("Actual value of register = %0x which is not equal to expected val which is %0x \n", actual_data, expected_data);
        end
    endtask

    /**
    * The `default_offset_check` task checks the default offset values of the registers and compares them with the expected values.
    */
    task default_offset_check();
        bit [WB_DATA-1:0] read_data;

        //$display ("DEFAULT REG VALUE READ START\n");
        read_reg(CSR, read_data);
        compare_actual_and_expected_val(read_data, 8'hc0);
        read_reg(DPR, read_data);
        compare_actual_and_expected_val(read_data, DPR_RESET_VAL);
        read_reg(CMDR, read_data);
        compare_actual_and_expected_val(read_data, CMDR_RESET_VAL);
        read_reg(FSMR, read_data);
        compare_actual_and_expected_val(read_data, FSMR_RESET_VAL);
        //$display ("DEFAULT REG VALUE READ END \n");
    endtask

    /**
    * The `read_write_permission` task checks the read and write permissions for the registers and compares the actual and expected data values.
    */
    task read_write_permission();
        bit [WB_DATA-1:0] read_data;
        bit [WB_DATA-1:0] write_data;

        $display ("REG PERMISSION START\n");
        write_data = 8'hff;
        write_reg(CSR, write_data);
        read_reg(CSR, read_data);
        compare_actual_and_expected_val(read_data, 8'hc0);

        write_reg(DPR, write_data);
        read_reg(DPR, read_data);
        compare_actual_and_expected_val(read_data, 8'h00);

        write_reg(FSMR, write_data);
        read_reg(FSMR, read_data);
        compare_actual_and_expected_val(read_data, FSMR_RESET_VAL);

        write_data = 8'hfd;
        write_reg(CMDR, write_data);
        read_reg(CMDR, read_data);
        compare_actual_and_expected_val(read_data, 8'h15);
        $display ("REG PERMISSION END \n");
    endtask

    /**
    * The `reset_iicm_check` task checks the reset functionality of the registers by writing and reading data, and comparing the actual and expected data values.
    */
    task reset_iicm_check();
        bit [WB_DATA-1:0] read_data;
        bit [WB_DATA-1:0] write_data;

        $display ("RESET CHECK START\n");
        write_data = 8'haa;
        write_reg(DPR, write_data);
        read_reg(DPR, read_data);
        compare_actual_and_expected_val(8'haa, write_data);
        // Resetting the core
        write_data = 8'h00;
        write_reg(CSR, write_data);
        read_reg(DPR, read_data);
        compare_actual_and_expected_val(read_data, write_data);
        $display ("RESET CHECK END\n");
    endtask

    /**
    * The `error_check` task writes and reads data to/from the CMDR register, and compares the actual and 
    * expected data values to check for errors.
    */
    task error_check();
        bit [WB_DATA-1:0] read_data;
        bit [WB_DATA-1:0] write_data;

        write_data = 8'h7;
        write_reg(CMDR, write_data);
        read_reg(CMDR, read_data);
        compare_actual_and_expected_val(read_data, 8'h17);   
    endtask

    /**
    * The `write_on_read_only_register` task attempts to write data to read-only registers, then reads the data and 
    * compares the actual and expected values.
    */
    task write_on_read_only_register();
        bit [WB_DATA-1:0] read_data;
        bit [WB_DATA-1:0] write_data;
        bit [WB_DATA-1:0] expected_data;

        write_data = $urandom;
        write_reg(CSR, write_data);
        read_reg(CSR, read_data);

        write_data = $urandom;
        write_reg(DPR, write_data);
        read_reg(DPR, read_data);

        write_data = $urandom;
        write_reg(CMDR, write_data);
        read_reg(CMDR, read_data);

        write_data = $urandom;
        write_reg(FSMR, write_data);
        read_reg(FSMR, read_data);
        $display("write_on_read_only_register Done!\n");
    endtask

    /**
    * The `register_aliasing` task checks for register aliasing by writing and reading data, and performing the default offset check.
    */
    task register_aliasing();
        bit [WB_DATA-1:0] read_data;
        bit [WB_DATA-1:0] write_data;
        write_data = $urandom;
        write_reg(DPR, write_data);
        read_reg(DPR, read_data);
        default_offset_check();
    endtask

    /**
    * The `set_agent` function sets the I2C and Wishbone agent handles.
    * @param i2c_agent The I2C agent handle.
    * @param wb_agent The Wishbone agent handle.
    */
    function void set_agent(i2c_agent i2c_agent, wb_agent	wb_agent);
        this.i2c_agent_h = i2c_agent;
        this.wb_agent_h = wb_agent;
    endfunction

    /**
    * The `set_master_transactions` function sets the master transactions array.
    * @param i2c_trans The master transactions array to set.
    */
    function void set_master_transactions(i2c_transaction i2c_trans []);
        this.master_transactions = i2c_trans;
    endfunction

    /**
    * The `set_slave_transactions` function sets the slave transactions array.
    * @param wb_trans The slave transactions array to set.
    */
    function void set_slave_transactions(i2c_transaction wb_trans []);
        this.slave_transactions = wb_trans;
    endfunction

endclass : i2cmb_generator
