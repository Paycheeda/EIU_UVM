`ifndef ETH_ENV_CFG_SV
`define ETH_ENV_CFG_SV

class eth_env_cfg extends uvm_object;
  `uvm_object_utils(eth_env_cfg)

  virtual eth_if vif;

  // Agent activity flags
  uvm_active_passive_enum tx_is_active = UVM_ACTIVE;
  uvm_active_passive_enum rx_is_active = UVM_ACTIVE;

 

  function new(string name = "eth_env_cfg");
    super.new(name);
  endfunction

endclass

`endif