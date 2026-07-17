////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : phy_mac_monitor.sv
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
//  UVM monitor for Ethernet PHY MAC verification
////////////////////////////////////////////////////////////////////////////////

`ifndef PHY_MAC_MONITOR_SV
`define PHY_MAC_MONITOR_SV

class phy_mac_monitor extends uvm_monitor;
  `uvm_component_utils(phy_mac_monitor)
  virtual mac_rx_if vif; 
  uvm_analysis_port #(mac_rx_phy_seq_item) mon_ap;

  function new(string name="phy_mac_monitor", uvm_component parent=null); 
    super.new(name, parent); 
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase); 
    mon_ap = new("mon_ap", this);
    if(!uvm_config_db#(virtual mac_rx_if)::get(this, "", "vif", vif)) 
      `uvm_fatal("NO_VIF", "No VIF in PHY Monitor")
  endfunction

  virtual task run_phase(uvm_phase phase);
    mac_rx_phy_seq_item item; 
    bit [3:0] lower_nibble;
    bit [3:0] upper_nibble;
    bit [7:0] reconstructed_byte;
    
    bit pos_ctl_seen;
    bit neg_ctl_seen;
    bit [7:0] temp_crc_data[];

    wait(vif.rst_n == 1'b1);

    forever begin
      @(posedge vif.clk);
      #1ps; 
      
      if (vif.rx_ctl === 1'b0) continue; 
      
      item = mac_rx_phy_seq_item::type_id::create("item");
      item.inject_bad_crc = 1'b0; 
      item.inject_rx_er_spike = 1'b0;
      
      forever begin
          lower_nibble = vif.rxd;
          pos_ctl_seen = vif.rx_ctl;
          
          @(negedge vif.clk);
          #1ps; 
          upper_nibble = vif.rxd;
          neg_ctl_seen = vif.rx_ctl;
          
          if (pos_ctl_seen ^ neg_ctl_seen) item.inject_rx_er_spike = 1'b1;
          
          reconstructed_byte = {upper_nibble, lower_nibble};
          item.raw_frame = new[item.raw_frame.size() + 1] (item.raw_frame);
          item.raw_frame[item.raw_frame.size() - 1] = reconstructed_byte;
          
          @(posedge vif.clk);
          #1ps;
          
          if (vif.rx_ctl === 1'b0) break;
      end
      
      if (item.raw_frame.size() >= 50) begin
          // ---> THE MATH FIX: Shifted to 46 & 47! <---
          item.payload_length = {item.raw_frame[46], item.raw_frame[47]} - 11'd8; 
          
          item.expected_payload = new[item.payload_length];
          for(int i = 0; i < item.payload_length; i++) begin
              item.expected_payload[i] = item.raw_frame[50 + i];
          end
          
          temp_crc_data = new[42 + item.payload_length];
          for (int i = 0; i < (42 + item.payload_length); i++) begin
              temp_crc_data[i] = item.raw_frame[8 + i];
          end
          
          item.expected_crc = item.calc_crc32(temp_crc_data);
          
          if ({item.raw_frame[item.raw_frame.size()-1], 
               item.raw_frame[item.raw_frame.size()-2], 
               item.raw_frame[item.raw_frame.size()-3], 
               item.raw_frame[item.raw_frame.size()-4]} !== item.expected_crc) begin
              item.inject_bad_crc = 1'b1;
          end
      end
      
      `uvm_info("PHY_MON", $sformatf("Captured Frame. Total Size: %0d | Payload: %0d | Has ER Spike: %0b | Has Bad CRC: %0b", 
               item.raw_frame.size(), item.payload_length, item.inject_rx_er_spike, item.inject_bad_crc), UVM_MEDIUM)
      
      mon_ap.write(item);
    end
  endtask
endclass

`endif