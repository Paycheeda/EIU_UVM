////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : eth_rx_app_monitor.sv
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
//  UVM monitor for Ethernet RX application verification
////////////////////////////////////////////////////////////////////////////////

`ifndef ETH_RX_APP_MONITOR_SV
`define ETH_RX_APP_MONITOR_SV

class eth_rx_app_monitor extends uvm_monitor;
  `uvm_component_utils(eth_rx_app_monitor)
  
  virtual eth_rx_app_if vif;
  uvm_analysis_port #(eth_rx_seq_item) mon_ap;

  function new(string name="eth_rx_app_monitor", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon_ap = new("mon_ap", this);
    if(!uvm_config_db#(virtual eth_rx_app_if)::get(this, "", "rx_vif", vif)) 
      `uvm_fatal("NO_VIF", "No VIF found")
  endfunction

  virtual task run_phase(uvm_phase phase);
    eth_rx_seq_item item;
    byte frame_data[$]; 

    vif.ext_rx_fifo_rd_en <= 1'b0;
    wait(vif.rst_n == 1'b1);

    forever begin
      @(posedge vif.clk);

      if (vif.eth_rx_data_valid) begin
        `uvm_info("RX_MON", "Valid flag received! Draining Physical RX FIFO...", UVM_LOW)
        item = eth_rx_seq_item::type_id::create("item");
        frame_data.delete(); 

        // Assert Read Enable
        vif.ext_rx_fifo_rd_en <= 1'b1;
        
        // ---> THE FIX: Add +1 to the loop to account for 1-cycle latency! <---
        for(int i = 0; i < vif.rx_eth_valid_bytes + 1; i++) begin
           @(posedge vif.clk);
           
           // Drop Read Enable right before the last byte emerges
           if (i == vif.rx_eth_valid_bytes - 1) begin
               vif.ext_rx_fifo_rd_en <= 1'b0; 
           end
           
           // Skip the first clock cycle (data isn't ready yet!)
           if (i > 0) begin
               frame_data.push_back(vif.ext_rx_fifo_data_out);
           end
        end

        item.payload = new[frame_data.size()] (frame_data);
        `uvm_info("RX_MON", $sformatf("Successfully popped %0d bytes from FIFO.", item.payload.size()), UVM_LOW)
        
        mon_ap.write(item);
      end
    end
  endtask
endclass
`endif