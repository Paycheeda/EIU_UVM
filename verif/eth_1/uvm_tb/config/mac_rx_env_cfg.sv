`ifndef MAC_RX_ENV_CFG_SV
`define MAC_RX_ENV_CFG_SV

class mac_rx_env_cfg extends uvm_object;
  `uvm_object_utils(mac_rx_env_cfg)

  // Virtual Interface Hookup
  virtual mac_rx_if vif;

  // Agent Activity Flags
  uvm_active_passive_enum is_phy_active = UVM_ACTIVE;
  uvm_active_passive_enum is_cpu_active = UVM_ACTIVE;

  // Track the hardware configurations (Optional for advanced tests)
  bit has_coverage = 1'b0;

  function new(string name = "mac_rx_env_cfg");
    super.new(name);
  endfunction
  
endclass

`endif