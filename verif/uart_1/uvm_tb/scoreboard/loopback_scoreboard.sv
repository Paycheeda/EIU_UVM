////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : loopback_scoreboard.sv
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
//  UVM scoreboard for UART loopback verification
////////////////////////////////////////////////////////////////////////////////

`uvm_analysis_imp_decl(_loop_ingr)
`uvm_analysis_imp_decl(_loop_egrs)

class loopback_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(loopback_scoreboard)

  function new(string name="loopback_scoreboard", uvm_component parent=null);
    super.new(name, parent);
  endfunction 

  uvm_analysis_imp_loop_ingr #(tx_uart, loopback_scoreboard) ingr_imp_export;
  
  uvm_analysis_imp_loop_egrs #(rx_uart, loopback_scoreboard) egrs_imp_export;

  tx_uart ingr_pkt_q[$]; 

  uvm_event    loopback_evnt;
  uart_config  cfg;            

  int match, mismatch, pkt_count;
  string result_table; 

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    ingr_imp_export = new ("ingr_imp_export", this);
    egrs_imp_export = new ("egrs_imp_export", this);
    loopback_evnt   = uvm_event_pool::get_global("loopback_scb_event"); 

    if(!uvm_config_db #(uart_config)::get(this, "", "uart_cfg", cfg))
      `uvm_warning("LOOPBACK_SCB", "Could not get uart_cfg! Event trigger might not work.")

    // Initialize the Ultimate Loopback Table Header
    result_table = "\n";
    result_table = {result_table, "+-------+-------+----------+--------+----------+----------+---------+\n"};
    result_table = {result_table, "| Pkt # | Width | Baud     | Parity | TX Sent  | RX Rcvd  | Status  |\n"};
    result_table = {result_table, "+-------+-------+----------+--------+----------+----------+---------+\n"};
  endfunction 

  virtual function void write_loop_ingr (tx_uart pkt);
    ingr_pkt_q.push_back(pkt);
  endfunction

  virtual function void write_loop_egrs (rx_uart act_pkt);
    tx_uart exp_pkt;
    string  status_str;
    string  parity_str;
    
    pkt_count++;

    if (ingr_pkt_q.size() == 0) begin
      `uvm_error("LOOPBACK_SCB", "RX output received but no TX expected data in queue!")
      mismatch++;
      return;
    end
    
    exp_pkt = ingr_pkt_q.pop_front();

    if (exp_pkt.parity_en) begin
        parity_str = exp_pkt.parity_odd_even ? "Even" : "Odd"; // TX parity_odd_even==1 is Even
    end else begin
        parity_str = "None";
    end
    
    if (act_pkt.data_out === exp_pkt.data_in) begin
      
      if (act_pkt.flag_packet_corrupt === 1'b1) begin
        `uvm_error("LOOPBACK_SCB", "Data matched, but RX flagged the packet as CORRUPT!")
        mismatch++;
        status_str = "*CORRUPT*";
      end else begin
        match++;
        status_str = "PASS";
      end
      
    end else begin
      `uvm_error("LOOPBACK_SCB_MISMATCH", $sformatf("EXPECTED TX: 0x%0h | ACTUAL RX: 0x%0h", exp_pkt.data_in, act_pkt.data_out))
      mismatch++;
      status_str = "*FAIL*";
    end

    // Add row to the ASCII table
    result_table = {result_table, $sformatf("| %-5d | %-5d | %-8d | %-6s | 0x%-6h | 0x%-6h | %-7s |\n", 
                    pkt_count, exp_pkt.data_width, exp_pkt.baudrate, parity_str, exp_pkt.data_in, act_pkt.data_out, status_str)};
  endfunction  

  // ========================================
  // Main Phase Task
  // ========================================
  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);
    
    if (cfg != null) begin
      wait(cfg.num_uart_packets == match + mismatch);
      loopback_evnt.trigger();
    end
  endtask 

  // ========================================
  // Report Phase
  // ========================================
  virtual function void report_phase (uvm_phase phase);
    result_table = {result_table, "+-------+-------+----------+--------+----------+----------+---------+\n"};
    result_table = {result_table, $sformatf("| TOTAL | MATCH = %-2d                | MISMATCH = %-2d               |\n", match, mismatch)};
    result_table = {result_table, "+-------+---------------------------+-------------------------------+\n"};

    `uvm_info("LOOPBACK_VERIFICATION_SUMMARY", result_table, UVM_NONE)
  endfunction 

endclass