////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : fifo_sequences.sv
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
//  UVM sequence collection for UART FIFO verification
////////////////////////////////////////////////////////////////////////////////

// ==============================================================================
// 1. THE PRODUCER SEQUENCE (Write Domain)
// ==============================================================================
class fifo_wr_sequence extends uvm_sequence #(fifo_item);
  `uvm_object_utils(fifo_wr_sequence)

  int num_packets;

  function new (string name = "fifo_wr_sequence");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info("FIFO_WR_SEQ", $sformatf("Producer starting: Generating %0d items...", num_packets), UVM_LOW)
    
    for (int i = 0; i < num_packets; i++) begin
      req = fifo_item::type_id::create("req");
      start_item(req);

      req.data = $urandom_range(0, 511); 
      
      // 5% chance of being corrupt (if random number 0-99 is less than 5)
      //req.corrupt = ($urandom_range(0, 99) < 5) ? 1'b1 : 1'b0; 

      req.corrupt = 1'b0; 
      
      // Random delay between 0 and 10 cycles
      req.delay_cycles = $urandom_range(0, 10);
      
      finish_item(req);
    end
    `uvm_info("FIFO_WR_SEQ", "Producer finished.", UVM_LOW)
  endtask
endclass

// ==============================================================================
// 2. THE CONSUMER SEQUENCE (Read Domain)
// ==============================================================================
class fifo_rd_sequence extends uvm_sequence #(fifo_item);
  `uvm_object_utils(fifo_rd_sequence)

  int num_packets;

  function new (string name = "fifo_rd_sequence");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info("FIFO_RD_SEQ", $sformatf("Consumer starting: Requesting %0d reads...", num_packets), UVM_LOW)
    
    for (int i = 0; i < num_packets; i++) begin
      req = fifo_item::type_id::create("req");
      start_item(req);

      req.delay_cycles = $urandom_range(0, 10);

      
      finish_item(req);
    end
    `uvm_info("FIFO_RD_SEQ", "Consumer finished.", UVM_LOW)
  endtask
endclass