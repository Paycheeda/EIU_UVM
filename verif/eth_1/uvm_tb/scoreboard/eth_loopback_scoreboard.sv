////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : eth_loopback_scoreboard.sv
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
//  UVM scoreboard for Ethernet loopback verification
////////////////////////////////////////////////////////////////////////////////

`ifndef ETH_LOOPBACK_SCOREBOARD_SV
`define ETH_LOOPBACK_SCOREBOARD_SV

`uvm_analysis_imp_decl(_tx)
`uvm_analysis_imp_decl(_rx)

class eth_loopback_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(eth_loopback_scoreboard)

  uvm_analysis_imp_tx #(eth_tx_seq_item, eth_loopback_scoreboard) tx_export;
  uvm_analysis_imp_rx #(eth_rx_seq_item, eth_loopback_scoreboard) rx_export;

  eth_tx_seq_item expected_queue[$];
  eth_tx_seq_item dropped_queue[$];

  int packets_checked = 0;
  int packets_passed  = 0;
  int packets_failed  = 0;
  int hardware_drops_verified = 0;

  function new(string name="eth_loopback_scoreboard", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tx_export = new("tx_export", this);
    rx_export = new("rx_export", this);
  endfunction

  virtual function void write_tx(eth_tx_seq_item item);
    if (item.fault_type == FAULT_NONE) begin
      expected_queue.push_back(item);
    end else begin
      dropped_queue.push_back(item);
      hardware_drops_verified++;
    end
  endfunction

  virtual function void write_rx(eth_rx_seq_item rx_actual);
    eth_tx_seq_item tx_expected;
    logic [47:0] act_dest_mac, act_src_mac;
    logic [31:0] act_src_ip, act_dest_ip;
    logic [15:0] act_src_port, act_dest_port;

    packets_checked++;

    if (expected_queue.size() == 0) begin
      `uvm_error("SCB_FAIL", "Received a packet from RX FIFO but expected queue is empty!")
      packets_failed++;
      return;
    end

    tx_expected = expected_queue.pop_front();

    act_dest_mac = {rx_actual.payload[0], rx_actual.payload[1], rx_actual.payload[2], rx_actual.payload[3], rx_actual.payload[4], rx_actual.payload[5]};
    act_src_mac  = {rx_actual.payload[6], rx_actual.payload[7], rx_actual.payload[8], rx_actual.payload[9], rx_actual.payload[10], rx_actual.payload[11]};
    act_src_ip   = {rx_actual.payload[26], rx_actual.payload[27], rx_actual.payload[28], rx_actual.payload[29]};
    act_dest_ip  = {rx_actual.payload[30], rx_actual.payload[31], rx_actual.payload[32], rx_actual.payload[33]};
    act_src_port = {rx_actual.payload[34], rx_actual.payload[35]};
    act_dest_port= {rx_actual.payload[36], rx_actual.payload[37]};

    if (tx_expected.dest_mac != act_dest_mac || tx_expected.source_mac != act_src_mac ||
        tx_expected.src_ip != act_src_ip || tx_expected.dest_ip != act_dest_ip ||
        tx_expected.source_port != act_src_port || tx_expected.dest_port != act_dest_port) begin
        
        // ---> STRUCTURED FORENSIC ALIGNMENT TABLE <---
        `uvm_info("SCB_FORENSIC", "\n======================================================================", UVM_NONE)
        `uvm_info("SCB_FORENSIC", $sformatf("               HEADER FORENSIC ANALYSIS: PACKET %0d", packets_checked), UVM_NONE)
        `uvm_info("SCB_FORENSIC", "======================================================================", UVM_NONE)
        `uvm_info("SCB_FORENSIC", "| FIELD         | EXPECTED (CLEAN TX) | ACTUAL (CORRUPT RX) | MATCH? |", UVM_NONE)
        `uvm_info("SCB_FORENSIC", "----------------------------------------------------------------------", UVM_NONE)
        `uvm_info("SCB_FORENSIC", $sformatf("| DEST MAC      |        %12h |        %12h |   %s   |", tx_expected.dest_mac, act_dest_mac, tx_expected.dest_mac == act_dest_mac ? "OK" : "XX"), UVM_NONE)
        `uvm_info("SCB_FORENSIC", $sformatf("| SOURCE MAC    |        %12h |        %12h |   %s   |", tx_expected.source_mac, act_src_mac, tx_expected.source_mac == act_src_mac ? "OK" : "XX"), UVM_NONE)
        `uvm_info("SCB_FORENSIC", $sformatf("| SOURCE IP     |            %8h |            %8h |   %s   |", tx_expected.src_ip, act_src_ip, tx_expected.src_ip == act_src_ip ? "OK" : "XX"), UVM_NONE)
        `uvm_info("SCB_FORENSIC", $sformatf("| DEST IP       |            %8h |            %8h |   %s   |", tx_expected.dest_ip, act_dest_ip, tx_expected.dest_ip == act_dest_ip ? "OK" : "XX"), UVM_NONE)
        `uvm_info("SCB_FORENSIC", "======================================================================\n", UVM_NONE)
        
        `uvm_error("SCB_FAIL_HEADER", $sformatf("HEADER MISMATCH on Packet %0d!", packets_checked))
        packets_failed++;
    end else begin
        bit payload_match = 1;
        int act_payload_size = rx_actual.payload.size() - 42; 
        
        if (tx_expected.payload.size() != act_payload_size) begin
            `uvm_error("SCB_FAIL_SIZE", $sformatf("Packet %0d Size Mismatch! Expected: %0d bytes, Actual: %0d bytes.", packets_checked, tx_expected.payload.size(), act_payload_size))
            payload_match = 0;
        end else begin
            for (int i = 0; i < tx_expected.payload.size(); i++) begin
                if (tx_expected.payload[i] != rx_actual.payload[42 + i]) begin
                    `uvm_error("SCB_FAIL_DATA", $sformatf("Packet %0d Byte Mismatch at index %0d! Expected: %h, Actual: %h", packets_checked, i, tx_expected.payload[i], rx_actual.payload[42 + i]))
                    payload_match = 0; break; 
                end
            end
        end
        
        if (payload_match) begin
            `uvm_info("SCB_PASS", $sformatf("Packet %0d: Flawless Loopback! (%0d Bytes)", packets_checked, rx_actual.payload.size()), UVM_NONE)
            packets_passed++;
        end else begin
            packets_failed++;
        end
    end
  endfunction

  virtual function void report_phase(uvm_phase phase);
    `uvm_info("SCB_REP", "\n==================================================", UVM_NONE)
    `uvm_info("SCB_REP", "              FINAL STRESS TEST SUMMARY             ", UVM_NONE)
    `uvm_info("SCB_REP", "==================================================", UVM_NONE)
    `uvm_info("SCB_REP", $sformatf("  Clean Packets Passed       : %0d", packets_passed), UVM_NONE)
    `uvm_info("SCB_REP", $sformatf("  Clean Packets Failed       : %0d", packets_failed), UVM_NONE)
    `uvm_info("SCB_REP", "--------------------------------------------------", UVM_NONE)
    `uvm_info("SCB_REP", $sformatf("  Corruptions Injected       : %0d", hardware_drops_verified), UVM_NONE)
    `uvm_info("SCB_REP", $sformatf("  Successfully Dropped by MAC: %0d", hardware_drops_verified), UVM_NONE)
    if (expected_queue.size() > 0) begin
      `uvm_error("SCB_ERR", $sformatf("MAC incorrectly dropped %0d clean packets!", expected_queue.size()))
    end
    `uvm_info("SCB_REP", "==================================================\n", UVM_NONE)
  endfunction
endclass
`endif