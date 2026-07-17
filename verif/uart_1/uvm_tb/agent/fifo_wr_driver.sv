////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : fifo_wr_driver.sv
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
//  UVM driver for UART FIFO write verification
////////////////////////////////////////////////////////////////////////////////

class fifo_wr_driver extends uvm_driver #(fifo_item);
  `uvm_component_utils(fifo_wr_driver)

  virtual fifo_intf_uart vif;

  function new(string name = "fifo_wr_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual fifo_intf_uart)::get(this, "", "fifo_vif", vif))
      `uvm_fatal("FIFO_WR_DRV", "Could not get virtual interface")
  endfunction

  virtual task run_phase(uvm_phase phase);
    vif.wr_en   = 1'b0;
    vif.data_in = '0;

    @(posedge vif.rst_n);
    `uvm_info("FIFO_WR_DRV", "Reset dropped. Ready to write data.", UVM_LOW)

    forever begin
      seq_item_port.get_next_item(req);
      drive_item(req);
      seq_item_port.item_done();
    end
  endtask

  virtual task drive_item(fifo_item item);
    repeat(item.delay_cycles) @(posedge vif.wr_clk);

    // =========================================
    // BURST-AND-DRAIN LOCK
    // =========================================
    if (vif.fifo_full === 1'b1) begin
      `uvm_info("FIFO_WR_DRV", "[LOCKED] FIFO hit FULL! Halting writes and waiting for drain...", UVM_LOW)
      wait (vif.fifo_empty === 1'b1); 
      @(posedge vif.wr_clk); 
      `uvm_info("FIFO_WR_DRV", "[UNLOCKED] FIFO is completely EMPTY! Resuming writes...", UVM_LOW)
    end

    // Drive Payload
    vif.data_in <= item.data;
    vif.wr_en   <= 1'b1;

    @(posedge vif.wr_clk);

    // Drop Pulse
    vif.wr_en   <= 1'b0;

    // FSM Sync Lock
    @(posedge vif.wr_clk); 
    while (vif.fifo_full === 1'b1) begin
      @(posedge vif.wr_clk);
    end
    
    @(posedge vif.wr_clk);
  endtask
endclass