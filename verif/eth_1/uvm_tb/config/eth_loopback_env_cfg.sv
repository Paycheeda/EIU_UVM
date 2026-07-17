////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : eth_loopback_env_cfg.sv
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
//  UVM configuration object for Ethernet loopback verification
////////////////////////////////////////////////////////////////////////////////

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