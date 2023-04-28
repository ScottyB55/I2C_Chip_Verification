typedef enum int {
	FSM_START,
	FSM_ADDRESS,
	FSM_DATA
} wb_transaction_state_t;

class i2cmb_predictor extends ncsu_component#(.T(ncsu_transaction));

  ncsu_component#(T) scoreboard;
  T predictor_trans;
  i2cmb_env_configuration config_h;
  i2c_transaction i2c_predicted_trans;

  wb_transaction_state_t state = FSM_START;

  
  function new(string name = "", ncsu_component_base  parent = null); 
    super.new(name,parent);
  endfunction

  function void set_configuration(i2cmb_env_configuration cfg);
    config_h = cfg;
  endfunction

  virtual function void set_scoreboard(ncsu_component #(T) scoreboard);
      this.scoreboard = scoreboard;
  endfunction

  function bit predicted_wb_transaction(wb_transaction wb_trans);
	if(state == FSM_START) begin 
		if(wb_trans.wb_addr == 2'b10 && wb_trans.data == 8'b00000100) begin
		       	state = FSM_ADDRESS;
		end
      	end
        else if (state == FSM_ADDRESS) begin
        	if(wb_trans.wb_addr != 2'b10 && wb_trans.data != 8'b00000100) begin
        		i2c_predicted_trans = new("Predictor transactions");
        		i2c_predicted_trans.address = wb_trans.data >> 1;
        		i2c_predicted_trans.rw = wb_trans.data & 8'b00000001;
        		i2c_predicted_trans.bus_num = wb_trans.bus_num;
        		i2c_predicted_trans.num_bytes = 0;
        		state = FSM_DATA;
		end
        end
      else if (state == FSM_DATA) begin
        if(wb_trans.wb_addr == 2'b10 && wb_trans.data == 8'b00000101) begin
          state = FSM_START;
          return 1;
        end 
        else begin
          if(wb_trans.wb_addr != 2'b10) begin
            i2c_predicted_trans.num_bytes++;
            i2c_predicted_trans.data = new[i2c_predicted_trans.num_bytes](i2c_predicted_trans.data);
            i2c_predicted_trans.data[i2c_predicted_trans.num_bytes - 1] = wb_trans.data;
          end
        end
      end    
      return 0;
  endfunction

  virtual function void nb_put(T trans);
    if(predicted_wb_transaction(trans)) begin
      scoreboard.nb_transport(i2c_predicted_trans, predictor_trans);
    end
  endfunction

endclass
