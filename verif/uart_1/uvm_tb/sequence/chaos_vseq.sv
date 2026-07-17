////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : chaos_vseq.sv
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
//  UVM virtual sequence for UART chaos verification
////////////////////////////////////////////////////////////////////////////////

class chaos_vseq extends uvm_sequence;
  `uvm_object_utils(chaos_vseq)
  
  `uvm_declare_p_sequencer(loopback_vsqncr)

  uart_config_seq   cfg_seq; 
  loopback_tx_seq   tx_seq;  
  loopback_rx_seq   rx_seq;  

  virtual uart_config_intf  cfg_vif;
  virtual error_inject_intf err_vif;

  // CLI Parameters (Defaults)
  int    num_pkts = 100;
  int    err_prob = 0; // 0 to 100%
  string err_type = "BOTH"; // "PARITY", "STOP", or "BOTH"

  function new(string name = "chaos_vseq");
    super.new(name);
  endfunction

  task pre_start();
    // Catch CLI Arguments
    void'($value$plusargs("NUM_PKTS=%d", num_pkts));
    void'($value$plusargs("ERR_PROB=%d", err_prob));
    void'($value$plusargs("ERR_TYPE=%s", err_type));

    if (!uvm_config_db#(virtual uart_config_intf)::get(null, "*", "cfg_vif", cfg_vif))
      `uvm_fatal("CHAOS", "Could not get cfg_vif")
    if (!uvm_config_db#(virtual error_inject_intf)::get(null, "*", "err_vif", err_vif))
      `uvm_fatal("CHAOS", "Could not get err_vif")

    `uvm_info("CHAOS", $sformatf("\n>>> INITIATING CHAOS ENGINE <<<\nPackets: %0d | Error Rate: %0d%% | Type: %s", num_pkts, err_prob, err_type), UVM_NONE)
  endtask

  virtual task body();
    int valid_bauds[10] = '{9600, 57600, 76800, 115200, 230400, 460800, 921600, 1843200, 3686400, 7372800};
    int rand_baud_idx;
    bit inject_err;
    int old_corrupt_count; 
    int watchdog_timer; // <--- THE FIX: Moved the declaration to the top!
    string injected_err_str;

    for (int i = 0; i < num_pkts; i++) begin
      // ---------------------------------------------------------
      // 1. PURE RANDOMIZATION (Config)
      // ---------------------------------------------------------
      cfg_seq = uart_config_seq::type_id::create("cfg_seq");
      rand_baud_idx = $urandom_range(0, 9); 
      
      cfg_seq.req_baudrate        = valid_bauds[rand_baud_idx];
      cfg_seq.req_data_width      = $urandom_range(8, 9);
      cfg_seq.req_parity_en       = $urandom_range(0, 1);
      cfg_seq.req_parity_odd_even = $urandom_range(0, 1);
      
      `uvm_info("CHAOS_FLEX", $sformatf("Packet %0d/%0d -> Baud: %0d | Width: %0d | Parity EN: %0b | Odd/Even: %0b", 
                i+1, num_pkts, cfg_seq.req_baudrate, cfg_seq.req_data_width, 
                cfg_seq.req_parity_en, cfg_seq.req_parity_odd_even), UVM_LOW)

      cfg_seq.start(p_sequencer.cfg_sqncr);
      #50000; 

      // ---------------------------------------------------------
      // 2. ERROR PROBABILITY ENGINE (The Saboteur)
      // ---------------------------------------------------------
      inject_err = ($urandom_range(1, 100) <= err_prob);
      err_vif.inject_parity_err = 0;
      err_vif.inject_stop_err   = 0;
      injected_err_str          = "NONE"; // Default

      if (inject_err) begin
        if (err_type == "PARITY" && cfg_seq.req_parity_en == 1) begin
            err_vif.inject_parity_err = 1;
            injected_err_str = "PARITY ERROR";
        end 
        else if (err_type == "STOP") begin
            err_vif.inject_stop_err = 1;
            injected_err_str = "FRAMING (STOP BIT) ERROR";
        end 
        else if (err_type == "BOTH") begin
            if ($urandom_range(0, 1) && cfg_seq.req_parity_en == 1) begin
                err_vif.inject_parity_err = 1;
                injected_err_str = "PARITY ERROR";
            end else begin
                err_vif.inject_stop_err = 1;
                injected_err_str = "FRAMING (STOP BIT) ERROR";
            end
        end
      end

      // ---------------------------------------------------------
      // 3. SEND EXACTLY ONE TX PACKET
      // ---------------------------------------------------------
      old_corrupt_count = cfg_vif.hw_rx_corrupt_bytes;

      tx_seq = loopback_tx_seq::type_id::create("tx_seq");
      tx_seq.num_packets = 1;
      tx_seq.start(p_sequencer.tx_sqncr);

      `uvm_info("CHAOS", "Packet dispatched. Waiting for RTL to assert BUSY...", UVM_LOW)

      // ---------------------------------------------------------
      // THE FIX: CATCH THE START, THEN CATCH THE END
      // ---------------------------------------------------------
      // 1. Force UVM to wait until the hardware actually WAKES UP
      wait(cfg_vif.uart_tx_busy === 1'b1);
      
      `uvm_info("CHAOS", "Hardware is actively transmitting. Fast-forwarding...", UVM_LOW)

      // 2. Now wait for BOTH state machines to completely finish
      wait(cfg_vif.uart_tx_busy === 1'b0 && cfg_vif.uart_rx_busy === 1'b0);
      
      // Give the hardware exactly 1 microsecond to clock the error counters
      #1000; 

      `uvm_info("CHAOS", "RTL officially idle! Evaluating outcome...", UVM_LOW)

      // ---------------------------------------------------------
      // 4. CONDITIONAL RX READ 
      // ---------------------------------------------------------
      if (cfg_vif.hw_rx_corrupt_bytes == old_corrupt_count) begin
          rx_seq = loopback_rx_seq::type_id::create("rx_seq");
          rx_seq.num_packets = 1;
          rx_seq.start(p_sequencer.rx_sqncr);
      end else begin
          // NEW: Print exactly what killed the packet!
          `uvm_info("CHAOS", $sformatf("Packet assassinated on the wire! RTL dropped it due to: %s. Skipping RX read.", injected_err_str), UVM_LOW)
      end
    end
    
    `uvm_info("CHAOS", "--- CHAOS STRESS TEST COMPLETE ---", UVM_LOW)
    #100000; // Let scoreboard finish
  endtask
endclass