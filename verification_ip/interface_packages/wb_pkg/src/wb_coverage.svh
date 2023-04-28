class wb_coverage extends ncsu_component#(.T(ncsu_transaction));

  wb_configuration cfg_h;
  wb_transaction wb_trans_h;
  bit core_enable;
  bit intr_enable;
  bit wb_opcode;
  bit [WB_SLAVE_ADDR_SIZE-1:0] wb_addr;

  covergroup wb_interface_cg;
	  coverpoint wb_addr {
		  bins CSR = {0};
		  bins DPR = {1};
		  bins CMDR = {2};
		  bins FSMR = {3};
	  }
	  coverpoint wb_opcode;
	  wb_addrxopcode : cross wb_addr, wb_opcode;
  endgroup

  covergroup wb_functionality_cg;
    coverpoint core_enable;
    coverpoint intr_enable;
  endgroup

  function new(string name = "", ncsu_component #(T) parent = null); 
    super.new(name,parent);
    wb_interface_cg = new;
    wb_functionality_cg = new;
  endfunction

  function void set_configuration(wb_configuration cfg);
    cfg_h = cfg;
  endfunction

  virtual function void nb_put(T trans);
    $display("coverage::nb_put() %s called", get_full_name());
    $cast(wb_trans_h,trans);
    wb_addr = wb_trans_h.wb_addr;
    wb_opcode = wb_trans_h.rw;
    if(wb_trans_h.wb_addr == CSR) begin
    	core_enable = wb_trans_h.data[7];
   	intr_enable = wb_trans_h.data[6];
    end
    wb_interface_cg.sample();
    wb_functionality_cg.sample();
  endfunction

endclass
