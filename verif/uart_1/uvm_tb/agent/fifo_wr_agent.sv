class fifo_wr_agent extends uvm_agent;
  `uvm_component_utils(fifo_wr_agent)

  uvm_sequencer #(fifo_item) sqncr;
  fifo_wr_driver             drvr;
  fifo_wr_monitor            mntr;

  function new(string name="fifo_wr_agent", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    mntr = fifo_wr_monitor::type_id::create("mntr", this);
    
    if (get_is_active() == UVM_ACTIVE) begin
      sqncr = uvm_sequencer#(fifo_item)::type_id::create("sqncr", this);
      drvr  = fifo_wr_driver::type_id::create("drvr", this);
    end
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    if (get_is_active() == UVM_ACTIVE) begin
      drvr.seq_item_port.connect(sqncr.seq_item_export);
    end
  endfunction
  
endclass