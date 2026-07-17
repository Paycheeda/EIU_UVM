////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : eth_if.sv
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
//  SystemVerilog interface for Ethernet verification
////////////////////////////////////////////////////////////////////////////////

`ifndef ETH_IF_SV
`define ETH_IF_SV

interface eth_if (input logic clk, input logic rst_n);
  // --- Core & Payload ---
  logic        eth_tx_start_pulse;
  logic [10:0] payload_length;
  logic        eth_tx_payload_ack;

  // --- Dynamic Metadata Inputs ---
  logic [47:0] dest_mac_in; logic [47:0] source_mac_in; logic [15:0] eth_type_in;
  logic [3:0]  version_in; logic [3:0]  header_length_in; logic [7:0]  type_of_service_in;
  logic [15:0] ipv4_total_length_in; logic [15:0] identification_in; logic [2:0]  flags_in;
  logic [12:0] fragment_offset_in; logic [7:0]  time_to_live_in; logic [7:0]  protocol_in;
  logic [31:0] source_ip_in; logic [31:0] dest_ip_in;
  logic [15:0] source_port_in; logic [15:0] dest_port_in; logic [15:0] udp_length_in;
  
  // --- Application FIFO Interface ---
  logic        ext_fifo_rd_en;
  logic        ext_fifo_empty;
  logic [7:0]  ext_fifo_data_out;

  // --- Physical PHY Outputs (RGMII DDR) ---
  logic [3:0]  txd;
  logic        tx_ctl;
  logic        tx_c;

  // --- Status ---
  logic        eth_tx_data_sent_pulse;
  logic        eth_tx_data_sent_flag;

  initial begin
    eth_tx_start_pulse = 0; 
    payload_length = 0; 
    ext_fifo_empty = 1; 
    ext_fifo_data_out = 0;
    eth_tx_payload_ack = 0; // Initialize new signal
  end
endinterface
`endif