`ifndef PHY_RX_AGENT_SV
`define PHY_RX_AGENT_SV

class phy_rx_agent extends uvm_agent;
  `uvm_component_utils(phy_rx_agent)

  eth_rx_if_driver drv; // Your custom driver!
  phy_rx_monitor   mon;
  uvm_sequencer #(phy_rx_seq_item) sqr;

  function new(string name = "phy_rx_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = phy_rx_monitor::type_id::create("mon", this);
    
    // Only build the driver and sequencer if the agent is ACTIVE
    if (get_is_active() == UVM_ACTIVE) begin
      drv = eth_rx_if_driver::type_id::create("drv", this);
      sqr = uvm_sequencer#(phy_rx_seq_item)::type_id::create("sqr", this);
    end
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active() == UVM_ACTIVE) begin
      drv.seq_item_port.connect(sqr.seq_item_export);
    end
  endfunction
endclass

`endif