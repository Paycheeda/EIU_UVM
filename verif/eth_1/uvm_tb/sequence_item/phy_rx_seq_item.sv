////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : phy_rx_seq_item.sv
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
//  UVM sequence item for Ethernet PHY RX verification
////////////////////////////////////////////////////////////////////////////////

`ifndef PHY_RX_SEQ_ITEM_SV
`define PHY_RX_SEQ_ITEM_SV

class phy_rx_seq_item extends uvm_sequence_item;
  // --- Standard Packet Data ---
  bit [47:0] dest_mac; bit [47:0] source_mac; bit [15:0] eth_type;
  bit [3:0]  version;  bit [3:0]  ihl;        bit [7:0]  tos;
  bit [15:0] total_length; bit [15:0] id;     bit [2:0]  flags;
  bit [12:0] frag_offset;  bit [7:0]  ttl;    bit [7:0]  protocol;
  bit [31:0] src_ip;       bit [31:0] dest_ip;
  bit [15:0] source_port;  bit [15:0] dest_port;
  bit [7:0]  payload[];

  // ---> FAULT INJECTION KNOBS (The Attack Vectors) <---
  rand bit inject_crc_error;       // If 1, driver flips a bit in the final CRC
  rand int inject_rx_er_at_byte;   // If > 0, driver pulses rx_er at this specific byte index
  rand int early_drop_at_byte;     // If > 0, driver drops rx_dv at this specific byte index

  `uvm_object_utils_begin(phy_rx_seq_item)
    `uvm_field_int(dest_mac, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(src_ip,   UVM_ALL_ON | UVM_HEX)
    `uvm_field_array_int(payload, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(inject_crc_error, UVM_ALL_ON)
    `uvm_field_int(inject_rx_er_at_byte, UVM_ALL_ON)
    `uvm_field_int(early_drop_at_byte, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "phy_rx_seq_item"); 
    super.new(name); 
  endfunction
  
  // Constrain the faults by default so we mostly generate clean traffic
  constraint default_faults {
    soft inject_crc_error == 0;
    soft inject_rx_er_at_byte == 0;
    soft early_drop_at_byte == 0;
  }
endclass

`endif