////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : eth_tx_stress_seq.sv
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
//  UVM sequence for Ethernet TX stress verification
////////////////////////////////////////////////////////////////////////////////

/*`ifndef ETH_TX_STRESS_SEQ_SV
`define ETH_TX_STRESS_SEQ_SV

class eth_tx_stress_seq extends uvm_sequence #(eth_tx_seq_item);
  `uvm_object_utils(eth_tx_stress_seq)

  int num_pkts = 10; 
  int prob_crc = 0;
  int prob_phy = 0;
  int prob_pre = 0;

  function new(string name = "eth_tx_stress_seq");
    super.new(name);
  endfunction

  virtual task body();
    int roll;
    int payload_size;

    // Pull arguments from the command line
    void'($value$plusargs("NUM_PKTS=%d", num_pkts));
    void'($value$plusargs("CRC_ERR=%d", prob_crc));
    void'($value$plusargs("PHY_ERR=%d", prob_phy));
    void'($value$plusargs("PREAMBLE_ERR=%d", prob_pre));

    `uvm_info("STRESS_SEQ", $sformatf("Starting Stress Test: %0d Pkts. [CRC:%0d%%, PHY:%0d%%, PRE:%0d%%]", 
              num_pkts, prob_crc, prob_phy, prob_pre), UVM_NONE)

    for(int i = 0; i < num_pkts; i++) begin
      req = eth_tx_seq_item::type_id::create("req");
      start_item(req);
// ---> THE LICENSE BYPASS (FIXED FOR ALIGNMENT) <---
      // Manually randomize using byte-sized chunks to prevent endianness mismatches
      req.dest_mac    = {8'h11, 8'h22, 8'h33, 8'h44, 8'h55, 8'h66}; // Fixed for stability
      req.source_mac  = {8'hAA, 8'hBB, 8'hCC, 8'hDD, 8'hEE, 8'hFF}; // Fixed for stability
      req.src_ip      = {8'hC0, 8'hA8, 8'h01, 8'h0A}; // 192.168.1.10
      req.dest_ip     = {8'hC0, 8'hA8, 8'h01, 8'h14}; // 192.168.1.20
      req.source_port = 16'h1234;
      req.dest_port   = 16'h5678;
      
      // Generate a dynamic payload between 18 and 100 bytes
      payload_size = $urandom_range(46, 100); 
      req.payload = new[payload_size];
      foreach(req.payload[j]) req.payload[j] = $urandom_range(0, 255); // STRICTLY 8-bit!
// Roll a 100-sided die for error injection
      roll = $urandom_range(1, 100);
      
      if      (roll <= prob_crc)                                    req.fault_type = eth_pkg::FAULT_CRC;
      else if (roll <= prob_crc + prob_phy)                         req.fault_type = eth_pkg::FAULT_PHY;
      else if (roll <= prob_crc + prob_phy + prob_pre)              req.fault_type = eth_pkg::FAULT_PREAMBLE;
      else                                                          req.fault_type = eth_pkg::FAULT_NONE;

      if (req.fault_type != FAULT_NONE) begin
        `uvm_info("STRESS_SEQ", $sformatf("SABOTAGE ORDERED: Packet %0d tagged with %s", i+1, req.fault_type.name()), UVM_LOW)
      end

      finish_item(req);
      
    end
  endtask
endclass

`endif*/

`ifndef ETH_TX_STRESS_SEQ_SV
`define ETH_TX_STRESS_SEQ_SV

class eth_tx_stress_seq extends uvm_sequence #(eth_tx_seq_item);
  `uvm_object_utils(eth_tx_stress_seq)

  int num_pkts = 10; 
  int prob_crc = 0;
  int prob_phy = 0;
  int prob_pre = 0;
  
  // ---> NEW: Default size override flag
  int target_payload_size = 0; 

  function new(string name = "eth_tx_stress_seq");
    super.new(name);
  endfunction

  virtual task body();
    int roll;
    int payload_size;

    // Pull arguments from the command line
    void'($value$plusargs("NUM_PKTS=%d", num_pkts));
    void'($value$plusargs("CRC_ERR=%d", prob_crc));
    void'($value$plusargs("PHY_ERR=%d", prob_phy));
    void'($value$plusargs("PREAMBLE_ERR=%d", prob_pre));
    
    // ---> NEW: Extract payload size from terminal! <---
    void'($value$plusargs("PAYLOAD_SIZE=%d", target_payload_size));

    `uvm_info("STRESS_SEQ", $sformatf("Starting Stress Test: %0d Pkts. [CRC:%0d%%, PHY:%0d%%, PRE:%0d%%]", 
               num_pkts, prob_crc, prob_phy, prob_pre), UVM_NONE)

    if (target_payload_size > 0) begin
        `uvm_info("STRESS_SEQ", $sformatf("Payload size overridden to fixed %0d bytes", target_payload_size), UVM_NONE)
    end

    for(int i = 0; i < num_pkts; i++) begin
      req = eth_tx_seq_item::type_id::create("req");
      start_item(req);

      // ---> THE LICENSE BYPASS (FIXED FOR ALIGNMENT) <---
      // Manually randomize using byte-sized chunks to prevent endianness mismatches
      req.dest_mac    = {8'h11, 8'h22, 8'h33, 8'h44, 8'h55, 8'h66}; // Fixed for stability
      req.source_mac  = {8'hAA, 8'hBB, 8'hCC, 8'hDD, 8'hEE, 8'hFF}; // Fixed for stability
      req.src_ip      = {8'hC0, 8'hA8, 8'h01, 8'h0A}; // 192.168.1.10
      req.dest_ip     = {8'hC0, 8'hA8, 8'h01, 8'h14}; // 192.168.1.20
      req.source_port = 16'h1234;
      req.dest_port   = 16'h5678;
      
      // ---> NEW: Dynamic Payload Size Logic <---
      // Use the override if provided, otherwise pick a random size
      if (target_payload_size > 0) begin
          payload_size = target_payload_size;
      end else begin
          payload_size = $urandom_range(50, 1472); 
      end
      
      req.payload = new[payload_size];
      foreach(req.payload[j]) req.payload[j] = $urandom_range(0, 255); // STRICTLY 8-bit!

      // Roll a 100-sided die for error injection
      roll = $urandom_range(1, 100);
      
      if      (roll <= prob_crc)                                    req.fault_type = eth_pkg::FAULT_CRC;
      else if (roll <= prob_crc + prob_phy)                         req.fault_type = eth_pkg::FAULT_PHY;
      else if (roll <= prob_crc + prob_phy + prob_pre)              req.fault_type = eth_pkg::FAULT_PREAMBLE;
      else                                                          req.fault_type = eth_pkg::FAULT_NONE;

      if (req.fault_type != FAULT_NONE) begin
        `uvm_info("STRESS_SEQ", $sformatf("SABOTAGE ORDERED: Packet %0d tagged with %s", i+1, req.fault_type.name()), UVM_LOW)
      end

      finish_item(req);
      #20000;
      
    end

    
  endtask
endclass

`endif
//eth_tx_start_pulse , eth_tx_data_sent calculate time difference 