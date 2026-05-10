////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : rx_main_sequence.sv
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
//  main sequence for uart RX
////////////////////////////////////////////////////////////////////////////////
class rx_main_sequence extends uvm_sequence #(rx_uart);
  `uvm_object_utils(rx_main_sequence)
 
  rx_stimulus_sequence rx_seq;
  uart_config          cfg; 

  function new (string name = "rx_main_sequence");
    super.new(name);    
  endfunction

  // Get the configuration from the database
  virtual task pre_start();
    if (!uvm_config_db#(uart_config)::get(get_sequencer(), "", "uart_cfg", cfg))
      `uvm_fatal("RX_MAIN_SEQ", "Did not get uart_config! Make sure it is set in the test.")
  endtask

  virtual task body();
    `uvm_info("RX_MAIN_SEQ", $sformatf("Starting rx_seq for %0d packets..", cfg.num_uart_packets), UVM_MEDIUM)

    // 1. Create the worker sequence
    rx_seq = rx_stimulus_sequence::type_id::create("rx_seq");
    
    // 2. Pass the configuration data to the worker sequence
    rx_seq.num_packets = cfg.num_uart_packets; 
    
    // 3. Start it!
    rx_seq.start(get_sequencer());
    
    `uvm_info("RX_MAIN_SEQ", "rx_seq finished successfully.", UVM_MEDIUM)
  endtask 
    
endclass
