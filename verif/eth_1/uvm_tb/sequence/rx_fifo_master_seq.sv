////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : rx_fifo_master_seq.sv
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
//  UVM sequence for Ethernet RX FIFO master verification
////////////////////////////////////////////////////////////////////////////////

`ifndef RX_FIFO_MASTER_SEQ_SV
`define RX_FIFO_MASTER_SEQ_SV

class rx_fifo_master_seq extends uvm_sequence #(rx_fifo_in_seq_item);
  `uvm_object_utils(rx_fifo_master_seq)
  
  int num_packets;
  int fault_prob;

  function new(string name="rx_fifo_master_seq"); 
    super.new(name); 
  endfunction

  task pre_body();
    if (!$value$plusargs("num_pkts=%d", num_packets)) num_packets = 10;
    if (!$value$plusargs("fault_prob=%d", fault_prob)) fault_prob = 0; // Default: 100% Clean
    `uvm_info("FIFO_SEQ", $sformatf("Config: %0d Pkts | %0d%% Corrupt Chance", num_packets, fault_prob), UVM_NONE)
  endtask

  virtual task body();
    int dice_roll;

    for (int i = 0; i < num_packets; i++) begin
        req = rx_fifo_in_seq_item::type_id::create("req"); 
        start_item(req);
        
        dice_roll = $urandom_range(1, 100);

        if (dice_roll <= fault_prob) begin
            // ======================================================
            // CORRUPT PACKET (License-Free Randomization)
            // ======================================================
            req.is_corrupt     = 1'b1;
            req.invalid_bytes  = $urandom_range(10, 200);
            req.payload_length = $urandom_range(46, 1500);
            
            // Size the fake RAM to hold exactly the amount of garbage needed to flush
            req.internal_ram_data = new[req.invalid_bytes];
            foreach(req.internal_ram_data[j]) req.internal_ram_data[j] = $urandom();
            
            `uvm_info("FIFO_SEQ", $sformatf("Packet %0d: ROLLED CORRUPT FLUSH (Invalid Bytes: %0d)", i+1, req.invalid_bytes), UVM_NONE)
            
        end else begin
            // ======================================================
            // CLEAN PACKET (License-Free Randomization)
            // ======================================================
            req.is_corrupt     = 1'b0;
            req.invalid_bytes  = 0;
            req.payload_length = $urandom_range(46, 1500);
            
            // Size the fake RAM for a full clean transfer (payload + 42 bytes of headers)
            req.internal_ram_data = new[req.payload_length + 42];
            foreach(req.internal_ram_data[j]) req.internal_ram_data[j] = $urandom();
            
            `uvm_info("FIFO_SEQ", $sformatf("Packet %0d: ROLLED CLEAN MEMORY TRANSFER (Payload: %0d, Total Ram: %0d)", i+1, req.payload_length, req.internal_ram_data.size()), UVM_NONE)
        end
        
        finish_item(req);
    end
  endtask
endclass

`endif