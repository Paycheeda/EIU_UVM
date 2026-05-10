////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : loopback_vsqncr.sv
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
//  virtual sequence for uart fifo
////////////////////////////////////////////////////////////////////////////////
class loopback_vsqncr extends uvm_sequencer;
  `uvm_component_utils(loopback_vsqncr)

  // Handles to the physical sequencers
  uvm_sequencer #(fifo_item)        tx_sqncr;
  uvm_sequencer #(fifo_item)        rx_sqncr;
  uvm_sequencer #(uart_config_item) cfg_sqncr;

  function new(string name="loopback_vsqncr", uvm_component parent=null);
    super.new(name, parent);
  endfunction
endclass