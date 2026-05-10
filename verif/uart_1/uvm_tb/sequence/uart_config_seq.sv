////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : uart_config_seq.sv
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
//  config sequence for uart fifo
////////////////////////////////////////////////////////////////////////////////

class uart_config_seq extends uvm_sequence #(uart_config_item);
  `uvm_object_utils(uart_config_seq)

  // KNOBS
  bit [31:0] req_baudrate;
  bit        req_parity_en;
  bit        req_parity_odd_even;
  bit [3:0]  req_data_width;

  function new(string name = "uart_config_seq");
    super.new(name);
  endfunction

  virtual task body();
    uart_config_item item;
    item = uart_config_item::type_id::create("item");

    start_item(item);
    
    // --- BYPASS LICENSE RESTRICTION ---
    // Instead of item.randomize(), assign directly!
    item.baudrate        = req_baudrate;
    item.parity_en       = req_parity_en;
    item.parity_odd_even = req_parity_odd_even;
    item.data_width      = req_data_width;
    // ----------------------------------

    finish_item(item);
    
    `uvm_info("CFG_SEQ", $sformatf("Sequence sent configuration to driver: %s", item.convert2string()), UVM_HIGH)
  endtask
endclass