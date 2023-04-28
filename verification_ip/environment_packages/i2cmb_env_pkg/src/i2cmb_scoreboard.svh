class i2cmb_scoreboard extends ncsu_component#(.T(ncsu_transaction));

  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  i2c_transaction i2c_trans_input;
  i2c_transaction i2c_trans_output;

  i2c_transaction current;

  virtual function void nb_transport(input T input_trans, output T output_trans);
    $cast(this.i2c_trans_input, input_trans);
    $display("I2CM_SCOREBOARD: Expected transaction ", this.i2c_trans_input.convert2string());

    $cast(output_trans, i2c_trans_output);
  endfunction

  function bit matching(i2c_transaction i2c_first_trans, i2c_transaction i2c_second_trans);
      bit data_flag = 1;
      bit address_flag = 0;
      bit rw_flag = 0;
      bit bus_num_flag = 0;
      int num_of_checks;
  
      if(i2c_first_trans.num_bytes == i2c_second_trans.num_bytes) begin
        while (num_of_checks < i2c_second_trans.num_bytes) begin
          data_flag = data_flag & (i2c_first_trans.data[num_of_checks] == i2c_second_trans.data[num_of_checks]);
          num_of_checks++;
      	end
        if (i2c_first_trans.address == i2c_second_trans.address) begin
  		address_flag = 1;
        end
        else begin
  		address_flag = 0;
        end
        if (i2c_first_trans.rw == i2c_second_trans.rw) begin
       		rw_flag = 1;
        end
        else begin
       		rw_flag = 0;
        end
       	if (i2c_first_trans.bus_num == i2c_second_trans.bus_num) begin
       		bus_num_flag = 1;
        end
        else begin
       		bus_num_flag = 0;
        end
      end
      else return 0;
      return  data_flag & address_flag & rw_flag & bus_num_flag;
  endfunction
  
  virtual function void nb_put(T trans);
    
    $cast(current,trans);
    $display("I2CM_SCOREBOARD: Actual transaction ",current.convert2string());
    if (matching(i2c_trans_input,current)) begin
	    $display("TRANSACTION MATCHED! \n");
    end
    else begin
	    $display("TRANSACTION MISMATCHED! \n");
    end
  endfunction

endclass
