////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : eth_rx_base_sequence.sv
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
//  UVM sequence for Ethernet RX verification
////////////////////////////////////////////////////////////////////////////////

`ifndef ETH_RX_BASE_SEQUENCE_SV
`define ETH_RX_BASE_SEQUENCE_SV

class eth_rx_base_sequence extends uvm_sequence #(eth_rx_seq_item);
  `uvm_object_utils(eth_rx_base_sequence)

  function new(string name = "eth_rx_base_sequence");
    super.new(name);
  endfunction

  virtual task body();
    forever begin
      req = eth_rx_seq_item::type_id::create("req");
      start_item(req);
      finish_item(req);
    end
  endtask
endclass

`endif