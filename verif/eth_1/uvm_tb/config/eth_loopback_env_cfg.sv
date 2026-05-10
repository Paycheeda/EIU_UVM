`ifndef ETH_LOOPBACK_ENV_CFG_SV
`define ETH_LOOPBACK_ENV_CFG_SV

class eth_loopback_env_cfg extends uvm_object;
  `uvm_object_utils(eth_loopback_env_cfg)

  virtual eth_tx_if     tx_vif;
  virtual eth_rx_app_if rx_vif;

  function new(string name="eth_loopback_env_cfg");
    super.new(name);
  endfunction
endclass

`endif