////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : rx_uart.sv
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
//  sequence item for uart RX
////////////////////////////////////////////////////////////////////////////////

class rx_uart extends uvm_sequence_item;
  `uvm_object_utils(rx_uart)

  function new(string name = "rx_uart");
    super.new(name);
  endfunction

  // Removed 'rand' keywords to bypass ModelSim license block
  bit [8:0]  data_in;
  bit [3:0]  data_width;
  bit [31:0] baudrate;
  bit        parity_en;
  bit        parity_odd_even;

  bit [8:0]  data_out; 
  bit        expected_parity;
  bit        sampled_parity;
  bit        flag_packet_corrupt;

  // ============================================================================
  // CUSTOM RANDOMIZATION (Bypassing free ModelSim limitations)
  // ============================================================================
  function void randomize_packet();
    int baud_choice;

    // 1. Manually constrain Width (8 or 9)
    data_width = $urandom_range(8, 9);

    // 2. Manually constrain Baudrate (9600, 115200, 1000000)
    baud_choice = $urandom_range(0, 4);
    if      (baud_choice == 0) baudrate = 9600;
    else if (baud_choice == 1) baudrate = 115200;
    else if (baud_choice == 2) baudrate = 230400;
    else if (baud_choice == 3) baudrate = 460800;
    else                       baudrate = 1843200;

    // 3. Manually constrain the Payload limit!
    if (data_width == 8) data_in = $urandom_range(0, 255); // 8-bit max
    else                 data_in = $urandom_range(0, 511); // 9-bit max

    // 4. Parity bits
    parity_en       = $urandom_range(0, 1);
    parity_odd_even = $urandom_range(0, 1);

    // 5. Calculate expected parity
    if (parity_en) begin
      if (parity_odd_even) expected_parity = ~(^data_in);
      else                 expected_parity = ^data_in;
    end else begin
      expected_parity = 1'b0;
    end
  endfunction
  
  // ============================================================================
  // Custom Print Function
  // ============================================================================
  virtual function string convert2string();
    string msg;
    // FIX: Use the dynamic randomized width, NOT the macro!
    int payload_size = data_width; 
    int total_frame  = 1 + payload_size + parity_en + 1; // Start + Data + Parity + Stop
    int parity_pos   = 1 + payload_size + 1;             // Start + Data + 1
    
    msg = $sformatf("\n+---------------------------------------------------+");
    msg = {msg, $sformatf("\n| UART PACKET SUMMARY                               |")};
    msg = {msg, $sformatf("\n+---------------------------------------------------+")};
    msg = {msg, $sformatf("\n| Payload Data      : %0h", data_in)};
    msg = {msg, $sformatf("\n| Data Width        : %0d bits", payload_size)};
    msg = {msg, $sformatf("\n| Parity Enabled    : %0b", parity_en)};
    
    if (parity_en) begin
      msg = {msg, $sformatf("\n| Expected Parity   : %0b (%s)", expected_parity, parity_odd_even ? "Odd" : "Even")};
      msg = {msg, $sformatf("\n| Total Wire Length : %0d bits", total_frame)};
      msg = {msg, $sformatf("\n| Parity Position   : Bit #%0d (if Start = Bit 1)", parity_pos)};
    end else begin
      msg = {msg, $sformatf("\n| Total Wire Length : %0d bits (No Parity)", total_frame)};
    end
    msg = {msg, $sformatf("\n+-------------------------------------------------+\n")};
    
    return msg;
  endfunction

endclass