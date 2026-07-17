////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : rx_fifo_in_seq_item.sv
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
//  UVM sequence item for Ethernet RX FIFO in verification
////////////////////////////////////////////////////////////////////////////////

`ifndef RX_FIFO_IN_SEQ_ITEM_SV
`define RX_FIFO_IN_SEQ_ITEM_SV

class rx_fifo_in_seq_item extends uvm_sequence_item;
  
  // Configuration Knobs for the transaction
  rand bit [10:0] payload_length;
  rand bit        is_corrupt;
  rand bit [10:0] invalid_bytes;
  
  // The data payload loaded into our "Fake Internal RAM"
  rand bit [7:0]  internal_ram_data[];

  `uvm_object_utils_begin(rx_fifo_in_seq_item)
    `uvm_field_int(payload_length, UVM_ALL_ON)
    `uvm_field_int(is_corrupt, UVM_ALL_ON)
    `uvm_field_int(invalid_bytes, UVM_ALL_ON)
    `uvm_field_array_int(internal_ram_data, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "rx_fifo_in_seq_item");
    super.new(name);
  endfunction

  // The Magic Logic: Size the fake RAM exactly based on what the RTL expects to read
  constraint ram_size_c {
    payload_length inside {[46:1500]}; // Standard Ethernet sizes
    invalid_bytes inside {[10:200]};   // Random chunk of garbage if corrupt
    
    // If corrupt, we only need 'invalid_bytes' of data to flush.
    // If clean, your RTL calculates: valid_eth_frame <= payload_length + 42
    internal_ram_data.size() == (is_corrupt ? invalid_bytes : (payload_length + 42));
  }
endclass

`endif