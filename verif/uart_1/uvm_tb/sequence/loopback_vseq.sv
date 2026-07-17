////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : loopback_vseq.sv
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
//  UVM virtual sequence for UART loopback verification
////////////////////////////////////////////////////////////////////////////////

// --- Self-Contained Helper Sequences ---
class loopback_tx_seq extends uvm_sequence #(fifo_item);
  `uvm_object_utils(loopback_tx_seq)
  int num_packets;
  function new(string name = "loopback_tx_seq"); super.new(name); endfunction
  virtual task body();
    fifo_item item;
    repeat(num_packets) begin
      item = fifo_item::type_id::create("item");
      start_item(item);
      
      item.data         = $urandom(); 
      // item.corrupt   = 1'b0;       // Hardware handles this natively now
      item.delay_cycles = 0;          // DMA Blast mode: 0 delay between writes
      // ----------------------------------
      
      finish_item(item);
    end
  endtask
endclass

class loopback_rx_seq extends uvm_sequence #(fifo_item);
  `uvm_object_utils(loopback_rx_seq)
  int num_packets;
  function new(string name = "loopback_rx_seq"); super.new(name); endfunction
  virtual task body();
    fifo_item item;
    repeat(num_packets) begin
      item = fifo_item::type_id::create("item");
      start_item(item);
      
      item.delay_cycles = 0; // DMA Drain mode: pull data as fast as possible
      // ----------------------------------
      
      finish_item(item);
    end
  endtask
endclass

// --- The Master Virtual Sequence ---
class loopback_vseq extends uvm_sequence;
  `uvm_object_utils(loopback_vseq)
  `uvm_declare_p_sequencer(loopback_vsqncr)

  function new(string name = "loopback_vseq");
    super.new(name);
  endfunction

  virtual task body();
    uart_config_seq cfg_seq;
    loopback_tx_seq tx_seq;
    loopback_rx_seq rx_seq;
    
    int total_flex_packets = 500;
    
    // --- MANUAL RANDOMIZATION LOOKUP TABLES ---
    // We only want valid baudrates, so we put them in an array
    int valid_bauds[11] = '{9600, 57600, 76800, 115200, 230400, 460800, 921600, 1843200, 3686400, 7372800, 14745600};
    int random_baud_idx;

    `uvm_info("VSEQ", "==================================================", UVM_LOW)
    `uvm_info("VSEQ", "--- INITIATING STARTER-EDITION FLEX STRESS TEST ---", UVM_LOW)
    `uvm_info("VSEQ", "==================================================", UVM_LOW)

    for (int i = 0; i < total_flex_packets; i++) begin
      
      // 1. Create the Config Sequence
      cfg_seq = uart_config_seq::type_id::create("cfg_seq");
      

      random_baud_idx = $urandom_range(0, 5); 
      
      cfg_seq.req_baudrate        = valid_bauds[random_baud_idx];
      cfg_seq.req_data_width      = $urandom_range(8, 9); // Randomly pick 8 or 9
      cfg_seq.req_parity_en       = $urandom_range(0, 1); // Randomly pick 0 or 1
      cfg_seq.req_parity_odd_even = $urandom_range(0, 1); // Randomly pick 0 or 1
      
      `uvm_info("VSEQ_FLEX", $sformatf("Packet %0d/%0d -> Baud: %0d | Width: %0d | Parity EN: %0b | Odd/Even: %0b", 
                i+1, total_flex_packets, cfg_seq.req_baudrate, cfg_seq.req_data_width, 
                cfg_seq.req_parity_en, cfg_seq.req_parity_odd_even), UVM_LOW)

      // ---------------------------------------------------------
      // 2. APPLY THE CONFIG TO THE HARDWARE
      // ---------------------------------------------------------
      cfg_seq.start(p_sequencer.cfg_sqncr);

      // Give the RTL state machine time to catch the config_done_pulse
      // (Using a safe, large delay to cover even the slowest baudrate changes)
      #50000; 

      // ---------------------------------------------------------
      // 3. FIRE EXACTLY ONE PACKET
      // ---------------------------------------------------------
      tx_seq = loopback_tx_seq::type_id::create("tx_seq");
      rx_seq = loopback_rx_seq::type_id::create("rx_seq");
      
      tx_seq.num_packets = 1;
      rx_seq.num_packets = 1;

      fork
        tx_seq.start(p_sequencer.tx_sqncr);
        rx_seq.start(p_sequencer.rx_sqncr);
      join

    end // End of loop

    `uvm_info("VSEQ", "--- STARTER-EDITION FLEX COMPLETE ---", UVM_LOW)
    
    // Let the Scoreboard finish its final delta-cycle comparison
    #100000; 
  endtask
endclass