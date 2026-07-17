////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : fifo_rd_monitor.sv
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
//  UVM monitor for UART FIFO read verification
////////////////////////////////////////////////////////////////////////////////

class fifo_rd_monitor extends uvm_monitor;
  `uvm_component_utils(fifo_rd_monitor)

  virtual fifo_intf_uart vif;
  uvm_analysis_port #(fifo_item) mon_ap;
  fifo_config cfg;

  function new(string name="fifo_rd_monitor", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual fifo_intf_uart)::get(this, "", "fifo_vif", vif))
      `uvm_fatal("FIFO_RD_MON", "Could not get virtual interface")
      
    if (!uvm_config_db#(fifo_config)::get(this, "", "fifo_cfg", cfg))
      `uvm_fatal("FIFO_RD_MON", "Could not get fifo_config") 
      
    mon_ap = new("mon_ap", this);
  endfunction

virtual task run_phase(uvm_phase phase);
    fifo_item item; 
    bit prev_empty = 1; 
    logic read_pending = 0; 
    
    fork
      // standard SRAM 1-Cycle Capture
      forever begin
        @(posedge vif.rd_clk);
        
        if (read_pending) begin
          item = fifo_item::type_id::create("item");
          item.data = vif.data_out;
          mon_ap.write(item);
          `uvm_info("FIFO_RD_MON", $sformatf("Sampled Read: 0x%0h", item.data), UVM_LOW)
        end
        
        read_pending = vif.rd_en; 
      end

      // Synchronous EMPTY Edge Detector
      forever begin
        @(posedge vif.rd_clk); 
        if (vif.fifo_empty !== prev_empty) begin
          if (vif.fifo_empty === 1'b1)
            `uvm_info("FIFO_RD_MON", "[FLAG] FIFO EMPTY SIGNAL ASSERTED", UVM_LOW)
          else
            `uvm_info("FIFO_RD_MON", "[FLAG] FIFO EMPTY SIGNAL DE-ASSERTED", UVM_LOW)
            
          prev_empty = vif.fifo_empty;
        end
      end
    join 
  endtask
endclass