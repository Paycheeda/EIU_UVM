`ifndef ETH_RX_ENV_CFG_SV
`define ETH_RX_ENV_CFG_SV

class eth_rx_env_cfg extends uvm_object;
  `uvm_object_utils(eth_rx_env_cfg)

  // The central place to store the virtual interface
  virtual eth_rx_if vif;

  // Agent configurations
  uvm_active_passive_enum phy_agent_active = UVM_ACTIVE;
  uvm_active_passive_enum fifo_agent_active = UVM_PASSIVE;

  function new(string name="eth_rx_env_cfg");
    super.new(name);
  endfunction
endclass

`endif