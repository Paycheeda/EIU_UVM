////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : host_tx_driver.sv
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
//  UVM driver for UART host TX verification
////////////////////////////////////////////////////////////////////////////////

`ifndef HOST_TX_DRIVER_SV
`define HOST_TX_DRIVER_SV

class host_tx_driver extends uvm_driver #(tx_uart);
  `uvm_component_utils(host_tx_driver)

  virtual uart_unified_intf vif;

  function new(string name = "host_tx_driver", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual uart_unified_intf)::get(this, "", "uart_unified_intf", vif))
      `uvm_fatal("HOST_TX_DRIVER", "Could not get unified vif")
  endfunction 

  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);
    
    vif.tx <= 1'b1; // Idle state

    `uvm_info("DRV_PROBE", "Driver started. Waiting for rst_n == 1...", UVM_NONE)
    wait(vif.rst_n === 1'b1);
    `uvm_info("DRV_PROBE", "Reset cleared! Entering main loop.", UVM_NONE)

    forever begin
      `uvm_info("DRV_PROBE", "Calling get_next_item()...", UVM_NONE)
      seq_item_port.get_next_item(req); 
      
      `uvm_info("DRV_PROBE", $sformatf("Got Packet! Width: %0d, Baud: %0d", req.data_width, req.baudrate), UVM_NONE)
      drive_item(req);
      
      seq_item_port.item_done();
      `uvm_info("DRV_PROBE", "Packet drive complete.", UVM_NONE)
    end
  endtask 

  virtual task drive_item(tx_uart drv_pkt); 
    int clock_delay;
    
    // Prevent divide-by-zero if sequence passes bad baudrate
    if (drv_pkt.baudrate == 0) drv_pkt.baudrate = 115200;
    
    clock_delay = 44236800 / drv_pkt.baudrate;
    
    // 1. Start Bit
    vif.tx <= 1'b0;
    repeat(clock_delay) @(posedge vif.clk);

    // 2. Data Bits
    for (int i = 0; i < drv_pkt.data_width; i++) begin
      vif.tx <= drv_pkt.data_in[i];
      repeat(clock_delay) @(posedge vif.clk);
    end

    // 3. Stop Bit
    vif.tx <= 1'b1;
    repeat(clock_delay) @(posedge vif.clk);
    
    // Gap
    repeat(100) @(posedge vif.clk);
  endtask
endclass

`endif