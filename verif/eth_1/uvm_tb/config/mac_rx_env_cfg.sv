////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : mac_rx_env_cfg.sv
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
//  UVM configuration object for Ethernet MAC RX verification
////////////////////////////////////////////////////////////////////////////////

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