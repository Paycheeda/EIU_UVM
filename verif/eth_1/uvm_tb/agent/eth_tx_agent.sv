class eth_tx_sequencer extends uvm_sequencer #(eth_tx_seq_item);
  `uvm_component_utils(eth_tx_sequencer)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
endclass

class eth_tx_agent extends uvm_agent;
  `uvm_component_utils(eth_tx_agent)
  eth_tx_sequencer sqr;
  eth_tx_driver    drv;
  eth_tx_monitor   mon;

  function new(string name = "eth_tx_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = eth_tx_monitor::type_id::create("mon", this);
    if (get_is_active() == UVM_ACTIVE) begin
      sqr = eth_tx_sequencer::type_id::create("sqr", this);
      drv = eth_tx_driver::type_id::create("drv", this);
    end
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active() == UVM_ACTIVE) begin
      drv.seq_item_port.connect(sqr.seq_item_export);
    end
  endfunction
endclass