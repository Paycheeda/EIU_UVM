////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : static_uart_sequence.sv
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
//  static sequence for uart loopback
////////////////////////////////////////////////////////////////////////////////

class static_uart_sequence extends uvm_sequence #(tx_uart);
  `uvm_object_utils(static_uart_sequence)
  int num_packets;

  function new (string name = "static_uart_sequence");
    super.new(name);
  endfunction

  virtual task body();
    `uvm_info("STATIC_SEQ", $sformatf("Generating %0d STATIC config TX items...", num_packets), UVM_LOW)
    
    for (int i = 0; i < num_packets; i++) begin
      req = tx_uart::type_id::create("req");
      start_item(req);
      
      // 1. Generate the random payload
      req.randomize_packet(); 
      
      // 2. OVERRIDE: Lock the configuration so both agents match!
      req.baudrate        = 115200;
      req.data_width      = 8;
      req.parity_en       = 0;
      req.parity_odd_even = 0;
      req.expected_parity = 0;
      
      // 3. Truncate payload to ensure it fits in 8 bits
      req.data_in = req.data_in & 8'hFF; 
      
      finish_item(req);
    end
  endtask
endclass

class static_main_sequence extends uvm_sequence #(tx_uart);
  `uvm_object_utils(static_main_sequence)
  
  static_uart_sequence seq;
  uart_config          cfg;
  
  function new (string name = "static_main_sequence");
    super.new(name);
  endfunction

  virtual task pre_start();
    if (!uvm_config_db#(uart_config)::get(get_sequencer(), "", "uart_cfg", cfg))
      `uvm_fatal("STATIC_MAIN", "No config found!")
  endtask

  virtual task body();
    seq = static_uart_sequence::type_id::create("seq");
    seq.num_packets = cfg.num_uart_packets;
    seq.start(get_sequencer());
  endtask
endclass