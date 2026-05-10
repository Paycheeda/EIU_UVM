////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : tx_uart.sv
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
//  sequence item for uart TX
////////////////////////////////////////////////////////////////////////////////

class tx_uart extends uvm_sequence_item;

  // The simplest factory registration (No field macros to break the queue!)
  `uvm_object_utils(tx_uart)

  function new(string name = "tx_uart");
    super.new(name);
  endfunction // new

  // ==========================================
  // PAYLOAD & CONFIG FIELDS (No 'rand' keyword!)
  // ==========================================
  bit [8:0]  data_in;         // Hardcoded to max physical width (9)
  bit [3:0]  data_width;      // Dynamically generated (8 or 9)
  bit [31:0] baudrate;        // Dynamically generated
  bit        parity_en;
  bit        parity_odd_even; 
  bit        expected_parity; // Calculated automatically
  bit        sampled_parity;  // Stored by Output Monitor if needed

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

    // 5. Calculate expected parity (Matched exactly to your RTL logic)
    // In your RTL: parity_odd_even == 1 means EVEN parity (~^data)
    if (parity_en) begin
      if (parity_odd_even) expected_parity = ~(^data_in); // Even
      else                 expected_parity = ^data_in;    // Odd
    end else begin
      expected_parity = 1'b0;
    end
  endfunction

  // ==============================================================================================
  // Display Method
  // ==============================================================================================
  virtual function void display_uart(string name);
    string msg;
    
    msg = $sformatf("\n This is being displayed from %s \n", name);
    msg = {msg, "================================================================\n"};
    msg = {msg, $sformatf("Data In         = 0x%0h (Bin: %0b)\n", data_in, data_in)};
    msg = {msg, $sformatf("Data Width      = %0d\n", data_width)};
    msg = {msg, $sformatf("Baudrate        = %0d\n", baudrate)};
    msg = {msg, $sformatf("Parity Enable   = %0b\n", parity_en)};
    msg = {msg, $sformatf("Parity Odd/Even = %0b (%s)\n", parity_odd_even, parity_odd_even ? "Even" : "Odd")};
    msg = {msg, $sformatf("Expected Parity = %0b\n", expected_parity)};
    `uvm_info(name, msg, UVM_MEDIUM)
  endfunction 

  // ============================================================================
  // Custom Print Function
  // ============================================================================
  virtual function string convert2string();
    string msg;
    int payload_size = data_width;
    int total_frame  = 1 + payload_size + parity_en + 1; // Start + Data + Parity + Stop
    int parity_pos   = 1 + payload_size + 1;             // Start + Data + 1
    
    msg = "\n+---------------------------------------------------+";
    msg = {msg, "\n| UART TX PACKET SUMMARY                            |"};
    msg = {msg, "\n+---------------------------------------------------+"};
    msg = {msg, $sformatf("\n| Payload Data      : 0x%0h (Bin: %0b)", data_in, data_in)};
    msg = {msg, $sformatf("\n| Data Width        : %0d bits", payload_size)};
    msg = {msg, $sformatf("\n| Baudrate          : %0d", baudrate)};
    msg = {msg, $sformatf("\n| Parity Enabled    : %0b", parity_en)};
    
    if (parity_en) begin
      msg = {msg, $sformatf("\n| Expected Parity   : %0b (%s)", expected_parity, parity_odd_even ? "Even" : "Odd")};
      msg = {msg, $sformatf("\n| Total Wire Length : %0d bits", total_frame)};
      msg = {msg, $sformatf("\n| Parity Position   : Bit #%0d (if Start = Bit 1)", parity_pos)};
    end else begin
      msg = {msg, $sformatf("\n| Total Wire Length : %0d bits (No Parity)", total_frame)};
    end
    msg = {msg, "\n+-------------------------------------------------+\n"};
    
    return msg;
  endfunction
endclass