////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : rx_inp_agent.sv
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
//  UVM agent for UART RX input verification
////////////////////////////////////////////////////////////////////////////////

class rx_inp_agent extends uvm_agent;
  `uvm_component_utils(rx_inp_agent)

  // =============================
  // Constructor Method
  // =============================  
  function new(string name="rx_inp_agent", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  rx_inp_monitor                 mntr ; // RX Input Monitor
  rx_inp_driver                  drvr ; // RX Input Driver
  uvm_sequencer #(rx_uart)       sqncr; // Sequencer holding rx_uart packets

  // =============================
  // Build Phase Method
  // =============================
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // The monitor is ALWAYS built
    mntr = rx_inp_monitor::type_id::create("mntr", this);
    
    // The driver and sequencer are ONLY built if the agent is active
    if (get_is_active() == UVM_ACTIVE) begin
      sqncr = uvm_sequencer#(rx_uart)::type_id::create("sqncr", this); 
      drvr  = rx_inp_driver::type_id::create("drvr", this);
    end
  endfunction

  // =============================
  // Connect Phase Method
  // =============================
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // Only connect if the agent is active
    if (get_is_active() == UVM_ACTIVE) begin
      drvr.seq_item_port.connect(sqncr.seq_item_export);
    end
  endfunction

endclass