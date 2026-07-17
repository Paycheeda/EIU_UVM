////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : fifo_out_monitor.sv
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
//  UVM monitor for Ethernet FIFO output verification
////////////////////////////////////////////////////////////////////////////////

`ifndef FIFO_OUT_MONITOR_SV
`define FIFO_OUT_MONITOR_SV

class fifo_out_monitor extends uvm_monitor;
  `uvm_component_utils(fifo_out_monitor)
  virtual eth_rx_if vif; 
  uvm_analysis_port #(fifo_out_seq_item) mon_ap;

  function new(string name="fifo_out_monitor", uvm_component parent=null); 
    super.new(name, parent); 
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase); 
    mon_ap = new("mon_ap", this);
    if(!uvm_config_db#(virtual eth_rx_if)::get(this, "", "vif", vif)) 
      `uvm_fatal("NO_VIF", "No VIF in FIFO Monitor")
  endfunction

  virtual task run_phase(uvm_phase phase);
    fifo_out_seq_item item; 
    bit [7:0] packet_q[$]; 

    wait(vif.rst_n == 1'b1);

    forever begin
      packet_q.delete();

      // Capture loop: Sniff data whenever wr_en is high
      while(vif.rx_transaction_done_pulse === 1'b0) begin
         @(posedge vif.clk);
         if(vif.rx_fifo_wr_en) begin
            packet_q.push_back(vif.fifo_data_in);
            // EXTREME VERBOSITY: Print exactly what is going into the FIFO
            `uvm_info("FIFO_MON_BUS", $sformatf("CAPTURED [%3d] | fifo_data_in: 8'h%02h | wr_en: 1", (packet_q.size()-1), vif.fifo_data_in), UVM_NONE)
         end
      end

      // End of Transaction
      item = fifo_out_seq_item::type_id::create("item");
      item.fifo_data = new[packet_q.size()];
      foreach(packet_q[i]) item.fifo_data[i] = packet_q[i];
      
      item.is_corrupt = vif.packet_received_corrupt_out;
      item.invalid_bytes = vif.invalid_bytes;
      item.payload_length = vif.payload_length;
      
      mon_ap.write(item);
      
      `uvm_info("FIFO_MON", $sformatf("RTL Transaction Done! Captured %0d bytes. Corrupt Flag: %0b, Invalid Bytes: %0d", 
          packet_q.size(), item.is_corrupt, item.invalid_bytes), UVM_NONE)
          
      @(posedge vif.clk);
    end
  endtask
endclass

`endif