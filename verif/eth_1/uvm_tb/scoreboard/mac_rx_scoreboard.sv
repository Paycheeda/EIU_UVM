////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : mac_rx_scoreboard.sv
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
//  UVM scoreboard for Ethernet MAC RX verification
////////////////////////////////////////////////////////////////////////////////

`ifndef MAC_RX_SCOREBOARD_SV
`define MAC_RX_SCOREBOARD_SV

// We need two distinct imports because we are listening to two different data types
`uvm_analysis_imp_decl(_phy)
`uvm_analysis_imp_decl(_cpu)

class mac_rx_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(mac_rx_scoreboard)

  uvm_analysis_imp_phy #(mac_rx_phy_seq_item, mac_rx_scoreboard) phy_export;
  uvm_analysis_imp_cpu #(mac_rx_cpu_seq_item, mac_rx_scoreboard) cpu_export;

  // The Queue to hold expected packets from the network until the CPU reads them
  mac_rx_phy_seq_item expected_queue[$];

  // Final Grade Metrics
  int pkts_checked = 0;
  int pkts_passed  = 0;
  int pkts_failed  = 0;

  function new(string name="mac_rx_scoreboard", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    phy_export = new("phy_export", this);
    cpu_export = new("cpu_export", this);
  endfunction

  // ---> FLUSH STALE QUEUE DATA <---
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    expected_queue.delete();
  endtask

  // ========================================================
  // RECEIVE FROM GIGABIT PHY MONITOR (The Expectation)
  // ========================================================
  virtual function void write_phy(mac_rx_phy_seq_item item);
    // As designed, the RTL silently drops RX_ER packets without triggering the corrupt counter.
    // We must ignore them here so the Scoreboard Queue stays perfectly synced with the RTL output.
    
    // Push the expected packet into the FIFO queue
    expected_queue.push_back(item);
  endfunction

  // ========================================================
  // RECEIVE FROM CPU/MEMORY MONITOR (The Audit)
  // ========================================================
  virtual function void write_cpu(mac_rx_cpu_seq_item out_item);
    mac_rx_phy_seq_item in_item;
    bit packet_passed = 1'b1;
    int expected_size;

    if (expected_queue.size() == 0) begin
      `uvm_error("SCB_FAIL", "CPU extracted data from memory, but the PHY never sent a packet!")
      return;
    end

    in_item = expected_queue.pop_front();
    pkts_checked++;

    `uvm_info("SCB", $sformatf("--- AUDITING PACKET %0d ---", pkts_checked), UVM_LOW)

    // ========================================================
    // PATH A: CORRUPT PACKET AUDIT (The Firewall Check)
    // ========================================================
    if (in_item.inject_bad_crc || in_item.inject_rx_er_spike) begin
        
        // 1. Ensure ZERO bytes leaked to external memory
        if (out_item.ext_fifo_data.size() > 0) begin
            `uvm_error("SCB_FAIL", $sformatf("FIREWALL BREACH! Corrupt packet leaked %0d bytes to external memory!", out_item.ext_fifo_data.size()))
            packet_passed = 1'b0;
        end
        
        if (packet_passed) begin
            `uvm_info("SCB_PASS", $sformatf("Packet %0d (CORRUPT) - Firewall held perfectly. Threat neutralized.", pkts_checked), UVM_NONE)
            // Fix: increment passed count for properly blocked corrupt packets!
            pkts_passed++; 
        end else begin
            pkts_failed++;
        end

    // ========================================================
    // PATH B: CLEAN PACKET AUDIT (The Transfer Check)
    // ========================================================
    end else begin
        expected_size = in_item.payload_length + 42; // FSM strips 8-byte preamble, leaves header + payload
        
        // 1. Verify RTL asserted the external FIFO reset to wipe the memory
        // ---> MOVED THIS CHECK HERE! <---
        if (!out_item.ext_rst_n_toggled) begin
            `uvm_error("SCB_FAIL", "RTL failed to toggle external reset before flushing clean packet!")
            packet_passed = 1'b0;
        end

        // 2. Verify RTL calculated the exact right frame size
        if (out_item.hw_valid_eth_frame != expected_size) begin
            `uvm_error("SCB_FAIL", $sformatf("HW Math Error! RTL calculated valid_eth_frame as %0d, but expected %0d", out_item.hw_valid_eth_frame, expected_size))
            packet_passed = 1'b0;
        end

        // 3. Verify the CPU read the exact right number of bytes
        if (out_item.ext_fifo_data.size() != expected_size) begin
            `uvm_error("SCB_FAIL", $sformatf("Size Mismatch! Expected: %0d bytes, CPU Extracted: %0d bytes", expected_size, out_item.ext_fifo_data.size()))
            packet_passed = 1'b0;
        end
        
        // 4. Byte-by-Byte Data Integrity Check
        if (packet_passed) begin
            for (int i = 0; i < expected_size; i++) begin
                // We compare against raw_frame[8 + i] because the RTL drops the 8-byte preamble!
                if (in_item.raw_frame[8 + i] !== out_item.ext_fifo_data[i]) begin
                    `uvm_error("SCB_FAIL", $sformatf("Data Mismatch at index %0d! Expected: 8'h%02h, Got: 8'h%02h", 
                                          i, in_item.raw_frame[8 + i], out_item.ext_fifo_data[i]))
                    packet_passed = 1'b0;
                    break;
                end
            end
        end
        
        if (packet_passed) begin
            `uvm_info("SCB_PASS", $sformatf("Packet %0d (CLEAN) - Perfect transfer of %0d bytes! RTL Math: %0d", 
                      pkts_checked, expected_size, out_item.hw_valid_eth_frame), UVM_NONE)
            pkts_passed++;
        end else begin
            pkts_failed++;
        end
    end
  endfunction

  virtual function void report_phase(uvm_phase phase);
    `uvm_info("SCB_FINAL_RESULTS", $sformatf("\n==================================================\n  SUBSYSTEM VERIFICATION RESULTS\n==================================================\n  Total Packets Checked : %0d\n  Packets PASSED        : %0d\n  Packets FAILED        : %0d\n==================================================", pkts_checked, pkts_passed, pkts_failed), UVM_NONE)
  endfunction

endclass

`endif