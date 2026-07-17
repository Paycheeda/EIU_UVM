////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : uart_base_test.sv
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
//  base UVM test for UART verification
////////////////////////////////////////////////////////////////////////////////

class uart_base_test extends uvm_test;
  `uvm_component_utils(uart_base_test)

  function new(string name = "uart_base_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  uart_env             env;
  uart_config          cfg;
  virtual uart_tx_intf in_vif;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // 1. Create the Config Object 
    // (It automatically parses +num_uart_packets from the terminal right here!)
    cfg = uart_config::type_id::create("cfg");

    // 2. Push it to the UVM Database for the Env and Sequences
    uvm_config_db #(uart_config)::set(this, "*", "uart_cfg", cfg);
    
    // 3. Build the Environment
    env = uart_env::type_id::create("env", this);
    
    // 4. Grab the interface for the reset phase
    if (!uvm_config_db#(virtual uart_tx_intf)::get(this, "", "uart_tx_intf", in_vif))
      `uvm_fatal("TEST", "Did not get uart_tx_intf")
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    // Print the topology to prove the Agent, Driver, and Scoreboard are wired!
    uvm_top.print_topology();
  endfunction

  // =========================================================================
  // Hardware Reset Phase
  // =========================================================================
  virtual task reset_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("UART_BASE_TEST", "Starting reset_phase..", UVM_LOW)
    
    vif_init_zero(); 
    
    // Give the hardware a moment to stabilize
    repeat (10) @(posedge in_vif.clk); 
    
    `uvm_info("UART_BASE_TEST", "reset_phase done..", UVM_LOW)
    phase.drop_objection(this);
  endtask 

  task vif_init_zero();
    // Initialize the standard payload pins
    in_vif.data_in          <= '0; 
    in_vif.parity_en        <= 1'b0;
    in_vif.parity_odd_even  <= 1'b0;
    in_vif.data_start_pulse <= 1'b0;
    
    // ========================================================
    // PRO-SAN FIX: Initialize the new dynamic architecture pins!
    // ========================================================
    in_vif.baudrate         <= 32'd115200; // Safe default
    in_vif.data_width       <= 4'd8;       // Safe default
    in_vif.baudrate_valid   <= 1'b0;
  endtask
  
endclass