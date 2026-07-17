////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : rx_fifo_in_monitor.sv
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
//  UVM monitor for Ethernet RX FIFO in verification
////////////////////////////////////////////////////////////////////////////////

`ifndef RX_FIFO_IN_MONITOR_SV
`define RX_FIFO_IN_MONITOR_SV

class rx_fifo_in_monitor extends uvm_monitor;
  `uvm_component_utils(rx_fifo_in_monitor)
  virtual eth_rx_fifo_if vif; 
  uvm_analysis_port #(rx_fifo_in_seq_item) mon_ap;

  function new(string name="rx_fifo_in_monitor", uvm_component parent=null); 
    super.new(name, parent); 
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase); 
    mon_ap = new("mon_ap", this);
    if(!uvm_config_db#(virtual eth_rx_fifo_if)::get(this, "", "vif", vif)) 
      `uvm_fatal("NO_VIF", "No VIF in Input Monitor")
  endfunction

  virtual task run_phase(uvm_phase phase);
    rx_fifo_in_seq_item item; 
    int bytes_flushed;
    bit rd_en_d1;
    bit [7:0] captured_ram_data[$];

    wait(vif.rst_n == 1'b1);

    forever begin
      bytes_flushed = 0;
      rd_en_d1 = 0;
      captured_ram_data.delete();
      
      wait(vif.rx_transaction_done_pulse == 1'b1);
      
      item = rx_fifo_in_seq_item::type_id::create("item");
      item.payload_length = vif.payload_length;
      item.is_corrupt     = vif.packet_received_corrupt_pulse;
      item.invalid_bytes  = vif.invalid_bytes;
      
      fork
        begin
            // Thread 1: Snoop Read Enables and Data Bus
            forever begin
                @(posedge vif.clk);
                
                // Because RAM has a 1-cycle latency, we capture data 1 cycle AFTER rd_en was high
                if (rd_en_d1) begin
                    captured_ram_data.push_back(vif.int_fifo_data_out);
                end
                
                rd_en_d1 = vif.int_fifo_rd_en; // Delay the read enable by 1 clock
                
                if (vif.int_fifo_rd_en) bytes_flushed++;
            end
        end
        begin
            // Thread 2: Timeout / End of Transaction detect
            if (!item.is_corrupt) begin
                wait(vif.eth_rx_data_valid == 1'b1);
                @(posedge vif.clk); 
                @(posedge vif.clk); // Wait two extra ticks to let the final rd_en_d1 capture complete
            end else begin
                repeat(item.invalid_bytes + 20) @(posedge vif.clk); 
            end
        end
      join_any
      disable fork; 

      // Populate the Scoreboard item with the successfully captured RAM data!
      item.internal_ram_data = new[captured_ram_data.size()];
      foreach(captured_ram_data[i]) item.internal_ram_data[i] = captured_ram_data[i];

      if (item.is_corrupt) item.invalid_bytes = bytes_flushed;
      
      mon_ap.write(item);
      `uvm_info("IN_MON", $sformatf("Captured Input. Corrupt: %0b | Flush Reads Detected: %0d | RAM Bytes Snooped: %0d", 
               item.is_corrupt, bytes_flushed, item.internal_ram_data.size()), UVM_NONE)
      
      @(posedge vif.clk);
    end
  endtask
endclass

`endif