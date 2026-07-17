////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : eth_rx_agent.sv
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
//  UVM agent for Ethernet RX verification
////////////////////////////////////////////////////////////////////////////////

class eth_rx_sequencer extends uvm_sequencer #(eth_rx_seq_item);
  `uvm_component_utils(eth_rx_sequencer)
  function new(string name, uvm_component parent); super.new(name,parent); endfunction
endclass

class eth_rx_agent extends uvm_agent;
  `uvm_component_utils(eth_rx_agent)
  eth_rx_sequencer sqr;
  eth_rx_driver    drv;
  eth_rx_monitor   mon;

  function new(string name = "eth_rx_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon = eth_rx_monitor::type_id::create("mon", this);
    if (get_is_active() == UVM_ACTIVE) begin
      sqr = eth_rx_sequencer::type_id::create("sqr", this);
      drv = eth_rx_driver::type_id::create("drv", this);
    end
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active() == UVM_ACTIVE) begin
      drv.seq_item_port.connect(sqr.seq_item_export);
    end
  endfunction
endclass