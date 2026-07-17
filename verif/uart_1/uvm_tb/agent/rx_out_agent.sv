////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : rx_out_agent.sv
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
//  UVM agent for UART RX output verification
////////////////////////////////////////////////////////////////////////////////

class rx_out_agent extends uvm_agent;
  `uvm_component_utils(rx_out_agent)

  // =============================
  // Constructor Method
  // =============================  
  function new(string name="rx_out_agent", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  rx_out_monitor mntr; // Monitor handle

  // =============================
  // Build Phase Method
  // =============================
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create the monitor
    mntr = rx_out_monitor::type_id::create("mntr", this);
  endfunction

  // =============================
  // Connect Phase Method
  // =============================
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

endclass