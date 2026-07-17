////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : whitebox_mac_agent.sv
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
//  UVM agent for Ethernet whitebox MAC verification
////////////////////////////////////////////////////////////////////////////////

`ifndef WHITEBOX_MAC_AGENT_SV
`define WHITEBOX_MAC_AGENT_SV

class whitebox_mac_agent extends uvm_agent;
  `uvm_component_utils(whitebox_mac_agent)
  
  whitebox_mac_monitor mon;

  function new(string name="whitebox_mac_agent", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // We only build the monitor because this is a purely passive agent
    mon = whitebox_mac_monitor::type_id::create("mon", this);
  endfunction

endclass

`endif