////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : mac_rx_cpu_seqs.sv
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
//  UVM sequence collection for Ethernet MAC RX CPU verification
////////////////////////////////////////////////////////////////////////////////

`ifndef MAC_RX_CPU_SEQS_SV
`define MAC_RX_CPU_SEQS_SV

class mac_rx_cpu_seqs extends uvm_sequence #(mac_rx_cpu_seq_item);
  `uvm_object_utils(mac_rx_cpu_seqs)

  function new(string name="mac_rx_cpu_seqs"); 
    super.new(name); 
  endfunction

  virtual task body();
    forever begin
        req = mac_rx_cpu_seq_item::type_id::create("req"); 
        start_item(req);
        // We don't need to randomize anything! The driver just needs the object to trigger a read cycle.
        finish_item(req); 
    end
  endtask
endclass

`endif