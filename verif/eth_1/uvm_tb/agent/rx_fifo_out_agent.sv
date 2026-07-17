////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : rx_fifo_out_agent.sv
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
//  UVM agent for Ethernet RX FIFO output verification
////////////////////////////////////////////////////////////////////////////////

`ifndef RX_FIFO_OUT_AGENT_SV
`define RX_FIFO_OUT_AGENT_SV

class rx_fifo_out_agent extends uvm_agent;
  `uvm_component_utils(rx_fifo_out_agent)

  rx_fifo_out_monitor mon;

  function new(string name="rx_fifo_out_agent", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // Force this agent to be strictly passive (no driver, no sequencer)
    is_active = UVM_PASSIVE; 
    
    mon = rx_fifo_out_monitor::type_id::create("mon", this);
  endfunction

endclass

`endif