////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : eth_rx_app_agent.sv
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
//  UVM agent for Ethernet RX application verification
////////////////////////////////////////////////////////////////////////////////

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