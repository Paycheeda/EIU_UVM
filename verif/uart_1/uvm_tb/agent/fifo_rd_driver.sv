////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : fifo_rd_driver.sv
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
//  UVM driver for UART FIFO read verification
////////////////////////////////////////////////////////////////////////////////

class fifo_rd_driver extends uvm_driver #(fifo_item);
  `uvm_component_utils(fifo_rd_driver)

  virtual fifo_intf_uart vif;

  function new(string name = "fifo_rd_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual fifo_intf_uart)::get(this, "", "fifo_vif", vif))
      `uvm_fatal("FIFO_RD_DRV", "Could not get virtual interface")
  endfunction

  virtual task run_phase(uvm_phase phase);
    vif.rd_en = 1'b0;

    @(posedge vif.rst_n);
    `uvm_info("FIFO_RD_DRV", "Reset dropped. Consumer is awake.", UVM_LOW)

    forever begin
      seq_item_port.get_next_item(req);
      drive_item(req);
      seq_item_port.item_done();
    end
  endtask

virtual task drive_item(fifo_item item);
    // Wait for the requested delay
    repeat(item.delay_cycles) @(posedge vif.rd_clk);

    // Wait until there is actually data in the FIFO to read
    wait (vif.fifo_empty === 1'b0);
    @(posedge vif.rd_clk);

    // Assert Read Enable
    vif.rd_en <= 1'b1;
    
    // Hold for 1 cycle (SRAM Standard)
    @(posedge vif.rd_clk);
    
    // De-assert Read Enable
    vif.rd_en <= 1'b0;

    repeat(2) @(posedge vif.rd_clk);

  endtask
endclass