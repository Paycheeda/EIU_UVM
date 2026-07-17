////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : mac_rx_phy_seq_item.sv
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
//  UVM sequence item for Ethernet MAC RX PHY verification
////////////////////////////////////////////////////////////////////////////////

`ifndef MAC_RX_PHY_SEQ_ITEM_SV
`define MAC_RX_PHY_SEQ_ITEM_SV

class mac_rx_phy_seq_item extends uvm_sequence_item;

  // =========================================================================
  // PACKET DNA (Control Knobs)
  // =========================================================================
  rand bit [15:0] payload_length;
  rand bit        inject_bad_crc;
  rand bit        inject_rx_er_spike;
  rand bit [10:0] rx_er_spike_location; // Which byte should get corrupted?
  
  // Constraint: Keep payloads between standard Ethernet sizes
  constraint payload_size_c { payload_length inside {[46:1500]}; }
  constraint rx_er_loc_c    { rx_er_spike_location < payload_length + 42; }

  // =========================================================================
  // RAW HARDWARE DATA (The Bits on the Wire)
  // =========================================================================
  // This array will hold the final constructed frame (Preamble -> Payload -> CRC)
  bit [7:0] raw_frame[]; 

  // Store the raw expected fields to make scoreboard comparisons easier
  bit [7:0] expected_payload[];
  bit [31:0] expected_crc;

  `uvm_object_utils_begin(mac_rx_phy_seq_item)
    `uvm_field_int(payload_length, UVM_ALL_ON)
    `uvm_field_int(inject_bad_crc, UVM_ALL_ON)
    `uvm_field_int(inject_rx_er_spike, UVM_ALL_ON)
    `uvm_field_int(rx_er_spike_location, UVM_ALL_ON)
    `uvm_field_array_int(raw_frame, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name="mac_rx_phy_seq_item"); 
    super.new(name); 
  endfunction

  // =========================================================================
  // PACKET CONSTRUCTOR (Runs right after randomization)
  // =========================================================================
  function void post_randomize();
    int header_offset = 0;
    bit [7:0] temp_crc_data[];
    
    // 1. Size the raw frame: Preamble(8) + Header(42) + Payload + CRC(4)
    raw_frame = new[8 + 42 + payload_length + 4];
    temp_crc_data = new[42 + payload_length]; // Only Header+Payload is used for CRC calc
    expected_payload = new[payload_length];

    // 2. Insert Fixed Preamble + SFD
    raw_frame[0] = 8'h55; raw_frame[1] = 8'h55; raw_frame[2] = 8'h55; raw_frame[3] = 8'h55;
    raw_frame[4] = 8'h55; raw_frame[5] = 8'h55; raw_frame[6] = 8'h55; raw_frame[7] = 8'hd5;
    
    // 3. Generate Random Header + Payload
    for(int i = 0; i < (42 + payload_length); i++) begin
        raw_frame[8 + i] = $urandom();
        
        // Hardcode the UDP length bytes so the FSM knows how long the FSM payload is!
        if (i == 38) raw_frame[8 + i] = (payload_length + 16'd8) >> 8; 
        if (i == 39) raw_frame[8 + i] = (payload_length + 16'd8) & 8'hFF;
        temp_crc_data[i] = raw_frame[8 + i];
        
        // Save the raw payload for the Scoreboard
        if (i >= 42) expected_payload[i-42] = raw_frame[8 + i];
    end
    
    // 4. Calculate the mathematically perfect CRC32 over Header + Payload
    expected_crc = calc_crc32(temp_crc_data);
    
    // 5. Append the CRC to the end of the frame (Little Endian to match RTL)
    if (inject_bad_crc) begin
        raw_frame[8 + 42 + payload_length + 0] = ~expected_crc[7:0]; // Corrupt it!
        raw_frame[8 + 42 + payload_length + 1] = ~expected_crc[15:8];
        raw_frame[8 + 42 + payload_length + 2] = ~expected_crc[23:16];
        raw_frame[8 + 42 + payload_length + 3] = ~expected_crc[31:24];
    end else begin
        raw_frame[8 + 42 + payload_length + 0] = expected_crc[7:0];
        raw_frame[8 + 42 + payload_length + 1] = expected_crc[15:8];
        raw_frame[8 + 42 + payload_length + 2] = expected_crc[23:16];
        raw_frame[8 + 42 + payload_length + 3] = expected_crc[31:24];
    end

  endfunction

  // =========================================================================
  // IEEE 802.3 STANDARD CRC-32 CALCULATOR
  // Uses Polynomial: 0x04C11DB7
  // =========================================================================
  function bit [31:0] calc_crc32(bit [7:0] data_in[]);
    bit [31:0] crc = 32'hFFFFFFFF;
    bit [7:0] current_byte;
    
    foreach (data_in[i]) begin
      current_byte = data_in[i];
      for (int j = 0; j < 8; j++) begin
        if ((crc[31] ^ current_byte[j]) == 1'b1)
          crc = {crc[30:0], 1'b0} ^ 32'h04C11DB7;
        else
          crc = {crc[30:0], 1'b0};
      end
    end
    
    // Final Bit Reversal and Inversion required by IEEE 802.3
    crc = ~{<<{crc}};
    return crc;
  endfunction

endclass

`endif