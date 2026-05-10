`ifndef RX_FIFO_IN_AGENT_SV
`define RX_FIFO_IN_AGENT_SV

class rx_fifo_in_agent extends uvm_agent;
  `uvm_component_utils(rx_fifo_in_agent)

  rx_fifo_in_driver  drv;
  rx_fifo_in_monitor mon;
  uvm_sequencer #(rx_fifo_in_seq_item) sqr;

  function new(string name="rx_fifo_in_agent", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(get_is_active() == UVM_ACTIVE) begin
      drv = rx_fifo_in_driver::type_id::create("drv", this);
      sqr = uvm_sequencer#(rx_fifo_in_seq_item)::type_id::create("sqr", this);
    end
    mon = rx_fifo_in_monitor::type_id::create("mon", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    if(get_is_active() == UVM_ACTIVE) begin
      drv.seq_item_port.connect(sqr.seq_item_export);
    end
  endfunction
endclass

`endif