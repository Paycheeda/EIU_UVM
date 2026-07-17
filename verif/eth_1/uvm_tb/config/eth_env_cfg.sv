////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : eth_env_cfg.sv
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
//  UVM configuration object for Ethernet verification
////////////////////////////////////////////////////////////////////////////////

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