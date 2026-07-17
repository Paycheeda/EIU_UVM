////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : rx_clean_pkt_seq.sv
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
//  UVM sequence for Ethernet RX clean packet verification
////////////////////////////////////////////////////////////////////////////////

`ifndef ETH_RX_TEST_SEQS_SV
`define ETH_RX_TEST_SEQS_SV

// 1. The "Happy Path" (Standard Traffic)
class rx_clean_pkt_seq extends uvm_sequence #(phy_rx_seq_item);
  `uvm_object_utils(rx_clean_pkt_seq)
  function new(string name="rx_clean_pkt_seq"); super.new(name); endfunction
  virtual task body();
    req = phy_rx_seq_item::type_id::create("req"); start_item(req);
    req.payload = new[$urandom_range(10, 30)]; foreach(req.payload[j]) req.payload[j] = $urandom();
    // Default constraints ensure zero faults!
    req.total_length = req.payload.size() + 28;
    finish_item(req);
  endtask
endclass

// 2. The CRC Attack (Valid packet, corrupt FCS)
class rx_crc_err_seq extends uvm_sequence #(phy_rx_seq_item);
  `uvm_object_utils(rx_crc_err_seq)
  function new(string name="rx_crc_err_seq"); super.new(name); endfunction
  virtual task body();
    req = phy_rx_seq_item::type_id::create("req"); start_item(req);
    req.payload = new[15]; foreach(req.payload[j]) req.payload[j] = $urandom();
    req.total_length = req.payload.size() + 28;
    
    // SABOTAGE!
    req.randomize() with { inject_crc_error == 1; };
    
    finish_item(req);
  endtask
endclass

// 3. The Physical Error Attack (Asserts rx_er mid-packet)
class rx_er_inject_seq extends uvm_sequence #(phy_rx_seq_item);
  `uvm_object_utils(rx_er_inject_seq)
  function new(string name="rx_er_inject_seq"); super.new(name); endfunction
  virtual task body();
    req = phy_rx_seq_item::type_id::create("req"); start_item(req);
    req.payload = new[20]; foreach(req.payload[j]) req.payload[j] = $urandom();
    req.total_length = req.payload.size() + 28;
    
    // SABOTAGE: Pulse rx_er randomly between byte 15 and 40
    req.randomize() with { inject_rx_er_at_byte inside {[15:40]}; };
    
    finish_item(req);
  endtask
endclass

// 4. The Cut-Wire Attack (Drops rx_dv before the packet finishes)
class rx_early_drop_seq extends uvm_sequence #(phy_rx_seq_item);
  `uvm_object_utils(rx_early_drop_seq)
  function new(string name="rx_early_drop_seq"); super.new(name); endfunction
  virtual task body();
    req = phy_rx_seq_item::type_id::create("req"); start_item(req);
    req.payload = new[30]; foreach(req.payload[j]) req.payload[j] = $urandom();
    req.total_length = req.payload.size() + 28;
    
    // SABOTAGE: Drop the line randomly between byte 10 and 50
    req.randomize() with { early_drop_at_byte inside {[10:50]}; };
    
    finish_item(req);
  endtask
endclass

`endif