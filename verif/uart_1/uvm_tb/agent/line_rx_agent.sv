////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : line_rx_agent.sv
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
//  UVM agent for UART line RX verification
////////////////////////////////////////////////////////////////////////////////

class line_rx_agent extends uvm_agent;
  `uvm_component_utils(line_rx_agent)

  function new(string name="line_rx_agent", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  line_rx_monitor           mntr;  
  line_rx_driver            drvr;  
  uvm_sequencer #(tx_uart)  sqncr; 

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    mntr = line_rx_monitor::type_id::create("mntr", this);
    
    if (get_is_active() == UVM_ACTIVE) begin
      sqncr = uvm_sequencer#(tx_uart)::type_id::create("sqncr", this); 
      drvr  = line_rx_driver::type_id::create("drvr", this);
    end
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    if (get_is_active() == UVM_ACTIVE) begin
      drvr.seq_item_port.connect(sqncr.seq_item_export);
    end
  endfunction

endclass