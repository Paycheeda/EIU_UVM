////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : eth_rx_env_cfg.sv
//  Author        : Ahmed Ali
//  Creation Date : 16/04/2026
//
//  Copyright 2026 Avant Labs PVT LTD. All Rights Reserved.
//
//  No portions of this material may be reproduced in any form without
//  the written permission of:
//
//    First Floor, Jumaira Arcade,
//    Fateh Jang Road,
//    Sector F-17, Islamabad, 45230
//
//  All information contained in this document is Avant Labs PVT LTD
//  company private, proprietary and trade secret.
//
//  Description
//  ===========
//  UVM configuration object for Ethernet RX verification
////////////////////////////////////////////////////////////////////////////////

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