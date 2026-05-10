`ifndef FIFO_OUT_AGENT_SV
`define FIFO_OUT_AGENT_SV

class fifo_out_agent extends uvm_agent;
  `uvm_component_utils(fifo_out_agent)

  fifo_out_monitor mon;

  function new(string name = "fifo_out_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // Hardcode to passive, since we never drive the internal FIFO output!
    is_active = UVM_PASSIVE; 
    mon = fifo_out_monitor::type_id::create("mon", this);
  endfunction

endclass

`endif