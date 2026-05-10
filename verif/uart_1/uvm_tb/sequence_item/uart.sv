////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : uart.sv
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
//  sequence item for uart
////////////////////////////////////////////////////////////////////////////////
class uart extends uvm_sequence_item;

  function new(string name = "uart");
    super.new(name);
  endfunction // new

/*-------------------------------------------------------------------------------
-- Interface, port, fields
-------------------------------------------------------------------------------*/



  rand bit       [8:0]   data_in;           // MUST be data_in
  rand bit          parity_en;
  rand bit          parity_odd_even;
  bit               data_start_pulse;
  bit               data_tx;
  bit               data_ready_pulse;
  uart_config          uart_cfg ;

  `uvm_object_utils_begin(uart)
    `uvm_field_int(data_in, UVM_ALL_ON|UVM_NOCOMPARE)
    `uvm_field_int(parity_en,  UVM_ALL_ON|UVM_NOCOMPARE)
    `uvm_field_int(parity_odd_even, UVM_ALL_ON|UVM_NOCOMPARE)
    `uvm_field_int(data_tx,   UVM_ALL_ON)
    `uvm_field_int(data_ready_pulse,   UVM_ALL_ON)
  `uvm_object_utils_end

  // constraint length_c { length inside{[40:60]};}
  // constraint width_c  { width  inside{[07:00]};}
  // constraint height_c { height <= width; }
  // ========================================
  // Create a new cuboid and copy content
  // ========================================
  function uart clone;
    uart p;
    $cast(p, super.clone());
    return p;
  endfunction // clone

  // ==============================================================================================
  // 
  // ==============================================================================================
  virtual function void display_uart(string name);
    string msg;
    
    msg = $sformatf("\n This is being displayed from %s \n", name);
    msg = {msg, $sformatf("================================================================\n")};
    msg = {msg, $sformatf("data_in = %h, parity_en = %h, parity_odd_even =%h \n", data_in, parity_en, parity_odd_even)};
    msg = {msg, $sformatf("data_tx = %h, data_ready_pulse = %h \n", data_tx, data_ready_pulse)};
    `uvm_info(name, msg, UVM_MEDIUM)
  endfunction // display_pkt

endclass // cuboid

