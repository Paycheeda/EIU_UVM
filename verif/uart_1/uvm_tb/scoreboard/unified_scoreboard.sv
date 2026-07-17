////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : unified_scoreboard.sv
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
//  UVM scoreboard for UART unified verification
////////////////////////////////////////////////////////////////////////////////

// ==========================================================
// 4 Unique Macros for 4 Distinct Analysis Ports!
// ==========================================================
`uvm_analysis_imp_decl(_host_tx)
`uvm_analysis_imp_decl(_line_tx)
`uvm_analysis_imp_decl(_line_rx)
`uvm_analysis_imp_decl(_host_rx)

class unified_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(unified_scoreboard)

  function new(string name="unified_scoreboard", uvm_component parent=null);
    super.new(name, parent);
  endfunction 

  // ============================================
  // PORT DEFINITIONS
  // ============================================
  // --- TX Engine Ports ---
  uvm_analysis_imp_host_tx #(tx_uart, unified_scoreboard) host_tx_export; // Expected TX
  uvm_analysis_imp_line_tx #(tx_uart, unified_scoreboard) line_tx_export; // Actual TX

  // --- RX Engine Ports ---
  uvm_analysis_imp_line_rx #(tx_uart, unified_scoreboard) line_rx_export; // Expected RX
  uvm_analysis_imp_host_rx #(rx_uart, unified_scoreboard) host_rx_export; // Actual RX

  // ============================================
  // INTERNAL QUEUES
  // ============================================
  tx_uart tx_expected_q[$]; 
  tx_uart rx_expected_q[$]; 

  uvm_event    unified_evnt;
  uart_config  cfg;            

  // Trackers
  int tx_match, tx_mismatch, tx_count;
  int rx_match, rx_mismatch, rx_count;
  
  string tx_result_table; 
  string rx_result_table; 

  // ============================================
  // Build Phase
  // ============================================
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    host_tx_export = new ("host_tx_export", this);
    line_tx_export = new ("line_tx_export", this);
    line_rx_export = new ("line_rx_export", this);
    host_rx_export = new ("host_rx_export", this);
    
    unified_evnt = uvm_event_pool::get_global("unified_scb_event"); 

    if(!uvm_config_db #(uart_config)::get(this, "", "uart_cfg", cfg))
      `uvm_warning("UNIFIED_SCB", "Could not get uart_cfg! Event trigger might not work.")

    // Initialize Tables
    tx_result_table = "\n+-------------------------------------------------------------------------+\n";
    tx_result_table =   {tx_result_table, "| [TX ENGINE] PARALLEL TO SERIAL (CPU -> WIRE)                            |\n"};
    tx_result_table =   {tx_result_table, "+-------+-------+----------+--------+----------+----------+---------+\n"};
    tx_result_table =   {tx_result_table, "| Pkt # | Width | Baud     | Parity | CPU Sent | Wire Act | Status  |\n"};
    tx_result_table =   {tx_result_table, "+-------+-------+----------+--------+----------+----------+---------+\n"};

    rx_result_table = "\n+-------------------------------------------------------------------------+\n";
    rx_result_table =   {rx_result_table, "| [RX ENGINE] SERIAL TO PARALLEL (WIRE -> CPU)                            |\n"};
    rx_result_table =   {rx_result_table, "+-------+-------+----------+--------+----------+----------+---------+\n"};
    rx_result_table =   {rx_result_table, "| Pkt # | Width | Baud     | Parity | Wire Snt | CPU Read | Status  |\n"};
    rx_result_table =   {rx_result_table, "+-------+-------+----------+--------+----------+----------+---------+\n"};
  endfunction 

  // ==============================================================================
  // ENGINE 1: TX VERIFICATION (Parallel CPU to Serial Wire)
  // ==============================================================================
  virtual function void write_host_tx (tx_uart pkt);
    tx_expected_q.push_back(pkt);
  endfunction

  virtual function void write_line_tx (tx_uart act_pkt);
    tx_uart exp_pkt;
    string  status_str, parity_str;
    tx_count++;

    if (tx_expected_q.size() == 0) begin
      `uvm_error("UNIFIED_SCB_TX", "Line TX monitored data but no Host TX expected data in queue!")
      tx_mismatch++;
      return;
    end
    
    exp_pkt = tx_expected_q.pop_front();
    parity_str = exp_pkt.parity_en ? (exp_pkt.parity_odd_even ? "Even" : "Odd") : "None";

    // Compare Data and Parity
    if (act_pkt.data_in === exp_pkt.data_in) begin
      if (exp_pkt.parity_en == 1'b1) begin
        if (act_pkt.sampled_parity === exp_pkt.expected_parity) begin
          tx_match++;
          status_str = "PASS";
        end else begin
          tx_mismatch++;
          status_str = "*PARITY*";
        end
      end else begin
        tx_match++;
        status_str = "PASS";
      end
    end else begin
      tx_mismatch++;
      status_str = "*FAIL*";
    end

    tx_result_table = {tx_result_table, $sformatf("| %-5d | %-5d | %-8d | %-6s | 0x%-6h | 0x%-6h | %-7s |\n", 
                    tx_count, exp_pkt.data_width, exp_pkt.baudrate, parity_str, exp_pkt.data_in, act_pkt.data_in, status_str)};
  endfunction  

  // ==============================================================================
  // ENGINE 2: RX VERIFICATION (Serial Wire to Parallel CPU)
  // ==============================================================================
  virtual function void write_line_rx (tx_uart pkt);
    rx_expected_q.push_back(pkt);
  endfunction

  virtual function void write_host_rx (rx_uart act_pkt);
    tx_uart exp_pkt;
    string  status_str, parity_str;
    rx_count++;

    if (rx_expected_q.size() == 0) begin
      `uvm_error("UNIFIED_SCB_RX", "Host RX read data but no Line RX expected data in queue!")
      rx_mismatch++;
      return;
    end
    
    exp_pkt = rx_expected_q.pop_front();
    parity_str = exp_pkt.parity_en ? (exp_pkt.parity_odd_even ? "Even" : "Odd") : "None";

    // Compare Data and Hardware Corruption Flag
    if (act_pkt.data_out === exp_pkt.data_in) begin
      if (act_pkt.flag_packet_corrupt === 1'b1) begin
        rx_mismatch++;
        status_str = "*CORRUPT*";
      end else begin
        rx_match++;
        status_str = "PASS";
      end
    end else begin
      rx_mismatch++;
      status_str = "*FAIL*";
    end

    rx_result_table = {rx_result_table, $sformatf("| %-5d | %-5d | %-8d | %-6s | 0x%-6h | 0x%-6h | %-7s |\n", 
                    rx_count, exp_pkt.data_width, exp_pkt.baudrate, parity_str, exp_pkt.data_in, act_pkt.data_out, status_str)};
  endfunction  

  // ========================================
  // Main Phase Task
  // ========================================
  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);
    
    if (cfg != null) begin
      // Wait for BOTH paths to finish processing the exact same number of packets!
      wait((cfg.num_uart_packets == tx_match + tx_mismatch) && (cfg.num_uart_packets == rx_match + rx_mismatch));
      unified_evnt.trigger();
    end
  endtask 

  // ========================================
  // Report Phase
  // ========================================
  virtual function void report_phase (uvm_phase phase);
    tx_result_table = {tx_result_table, "+-------+-------+----------+--------+----------+----------+---------+\n"};
    tx_result_table = {tx_result_table, $sformatf("| TOTAL | MATCH = %-2d                | MISMATCH = %-2d               |\n", tx_match, tx_mismatch)};
    tx_result_table = {tx_result_table, "+-------+---------------------------+-------------------------------+\n"};

    rx_result_table = {rx_result_table, "+-------+-------+----------+--------+----------+----------+---------+\n"};
    rx_result_table = {rx_result_table, $sformatf("| TOTAL | MATCH = %-2d                | MISMATCH = %-2d               |\n", rx_match, rx_mismatch)};
    rx_result_table = {rx_result_table, "+-------+---------------------------+-------------------------------+\n"};

    // Print the final Double Masterpiece!
    `uvm_info("UNIFIED_TX_SUMMARY", tx_result_table, UVM_NONE)
    `uvm_info("UNIFIED_RX_SUMMARY", rx_result_table, UVM_NONE)
  endfunction 

endclass