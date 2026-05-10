`ifndef ETH_RX_APP_AGENT_SV
`define ETH_RX_APP_AGENT_SV

class eth_rx_app_agent extends uvm_agent;
  `uvm_component_utils(eth_rx_app_agent)
  
  eth_rx_app_monitor mon;

  function new(string name="eth_rx_app_agent", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = eth_rx_app_monitor::type_id::create("mon", this);
  endfunction
endclass

`endif