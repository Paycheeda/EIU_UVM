////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : eth_rx_scoreboard.sv
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
//  UVM scoreboard for Ethernet RX verification
////////////////////////////////////////////////////////////////////////////////

`ifndef ETH_RX_SCOREBOARD_SV
`define ETH_RX_SCOREBOARD_SV

class eth_rx_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(eth_rx_scoreboard)

  // Two FIFOs: One for the physical PHY sniff, one for the internal MAC memory sniff
  uvm_tlm_analysis_fifo #(fifo_out_seq_item) phy_fifo;
  uvm_tlm_analysis_fifo #(fifo_out_seq_item) fifo_fifo;

  uvm_analysis_export #(fifo_out_seq_item) phy_export;
  uvm_analysis_export #(fifo_out_seq_item) fifo_export;

  int pkts_checked = 0; int pkts_passed = 0; int pkts_failed = 0;

  function new(string name="eth_rx_scoreboard", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    phy_fifo = new("phy_fifo", this); fifo_fifo = new("fifo_fifo", this);
    phy_export = new("phy_export", this); fifo_export = new("fifo_export", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    phy_export.connect(phy_fifo.analysis_export);
    fifo_export.connect(fifo_fifo.analysis_export);
  endfunction

  virtual task run_phase(uvm_phase phase);
    fifo_out_seq_item phy_item, fifo_item;
    int udp_len, expected_phy_size;
    bit early_drop, phy_rx_er, crc_good, expect_corrupt, match;
    bit [7:0] crc_data_q[$];
    bit [31:0] calc_crc, rx_crc;

    forever begin
      phy_fifo.get(phy_item);
      fifo_fifo.get(fifo_item);

      match = 1'b1; early_drop = 0; crc_good = 0;
      phy_rx_er = phy_item.is_corrupt; // The PHY Monitor hijacks this to report rx_er

      // 1. Analyze for Early Drop (Did rx_dv go low before the packet finished?)
      if (phy_item.fifo_data.size() >= 40) begin
         udp_len = {phy_item.fifo_data[38], phy_item.fifo_data[39]};
         expected_phy_size = 14 + 20 + udp_len + 4; // MACs + IPv4 + UDP + CRC
         early_drop = (phy_item.fifo_data.size() < expected_phy_size);
      end else begin
         early_drop = 1'b1;
      end

      // 2. Analyze CRC Integrity (If the packet wasn't dropped early)
      if (!early_drop && phy_item.fifo_data.size() >= 4) begin
         crc_data_q.delete();
         for(int i=0; i<phy_item.fifo_data.size()-4; i++) crc_data_q.push_back(phy_item.fifo_data[i]);
         calc_crc = calc_crc32(crc_data_q);
         
         // Reconstruct the received CRC (Driver sends LSB first)
         rx_crc = {phy_item.fifo_data[phy_item.fifo_data.size()-1],
                   phy_item.fifo_data[phy_item.fifo_data.size()-2],
                   phy_item.fifo_data[phy_item.fifo_data.size()-3],
                   phy_item.fifo_data[phy_item.fifo_data.size()-4]};
                   
         if (calc_crc == rx_crc) crc_good = 1'b1;
      end

      // 3. Determine Truth Table
      expect_corrupt = phy_rx_er | early_drop | !crc_good;

      // 4. Verify RTL Response
      if (fifo_item.is_corrupt !== expect_corrupt) begin
         `uvm_error("SCB", $sformatf("Corrupt Flag Mismatch! Expected FSM to say: %0b, Got: %0b", expect_corrupt, fifo_item.is_corrupt))
         match = 1'b0;
      end

      if (expect_corrupt == 1'b0) begin
         // If clean, the MAC should have written EXACTLY the frame minus the 4 CRC bytes to memory
         if (fifo_item.fifo_data.size() != phy_item.fifo_data.size() - 4) begin
             `uvm_error("SCB", "Clean packet size mismatch! The FIFO captured the wrong number of bytes.")
             match = 1'b0;
         end else begin
             for(int i=0; i<fifo_item.fifo_data.size(); i++) begin
                 if(fifo_item.fifo_data[i] !== phy_item.fifo_data[i]) match = 1'b0;
             end
         end

         // Verify the new dynamic payload_length hardware extractor
         if (fifo_item.payload_length !== (udp_len - 8)) begin
             `uvm_error("SCB", $sformatf("Payload Length Extractor Failed! Expected: %0d, Got: %0d", (udp_len-8), fifo_item.payload_length))
             match = 1'b0;
         end
      end

      // 5. Output Beautiful Dissection
      `uvm_info("SCB_JUDGE", $sformatf({
         "\n==================================================",
         "\n  FSM FAULT-TOLERANCE ANALYSIS",
         "\n==================================================",
         "\n  Physical Faults Injected : rx_er=%0b, early_drop=%0b",
         "\n  Physical CRC Integrity   : %s",
         "\n  Expected RTL Reaction    : %s",
         "\n  Actual RTL Reaction      : %s",
         "\n  Overall Verification     : %s",
         "\n=================================================="
      }, phy_rx_er, early_drop,
         (early_drop ? "N/A (Dropped)" : (crc_good ? "PASS" : "FAIL (Corrupt)")),
         (expect_corrupt ? "CORRUPT MEMORY FLUSH" : "CLEAN MEMORY WRITE"),
         (fifo_item.is_corrupt ? "CORRUPT MEMORY FLUSH" : "CLEAN MEMORY WRITE"),
         (match ? "PASS" : "FAIL")
      ), UVM_NONE)

      if (match) pkts_passed++; else pkts_failed++;
      pkts_checked++;
    end
  endtask

  function bit [31:0] calc_crc32(bit [7:0] dq[$]);
     bit [31:0] crc = 32'hFFFFFFFF; bit [31:0] poly = 32'hEDB88320;
     foreach(dq[i]) for(int j=0; j<8; j++) crc = ((crc[0] ^ dq[i][j]) == 1'b1) ? (crc >> 1) ^ poly : (crc >> 1);
     return ~crc;
  endfunction
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SCB_FINAL_RESULTS", $sformatf({
       "\n==================================================",
       "\n  TESTBENCH FINAL RESULTS",
       "\n==================================================",
       "\n  Total Packets Checked : %0d",
       "\n  Packets PASSED        : %0d",
       "\n  Packets FAILED        : %0d",
       "\n=================================================="
    }, pkts_checked, pkts_passed, pkts_failed), UVM_NONE)
  endfunction
endclass

`endif