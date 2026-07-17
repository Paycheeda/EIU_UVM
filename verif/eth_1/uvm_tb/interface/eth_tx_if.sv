////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : eth_tx_if.sv
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
//  SystemVerilog interface for Ethernet TX verification
////////////////////////////////////////////////////////////////////////////////

`ifndef ETH_TX_IF_SV
`define ETH_TX_IF_SV

interface eth_tx_if(input logic clk, input logic rst_n);
  // MAC Dynamic Metadata
  logic [47:0] dest_mac;
  logic [47:0] source_mac;
  logic [31:0] source_ip;
  logic [31:0] dest_ip;
  logic [15:0] source_port;
  logic [15:0] dest_port;
  logic [15:0] payload_length;

  // TX Control (Internal)
  logic config_done_pulse;      
  logic eth_tx_start_pulse;     
  logic eth_tx_data_sent;

  // External physical FIFO Write Pins (Internal)
  logic       ext_tx_fifo_wr_en;
  logic [7:0] ext_tx_fifo_data_in;

  // Old Internal MAC Read Pins (Internal)
  logic       tx_fifo_rd_en;
  logic [7:0] tx_fifo_data_out;
  logic       tx_fifo_empty;

  // ---> NEW: PHYSICAL RGMII GIGABIT PINS <---
  logic [3:0] txd;
  logic       tx_ctl;
  logic       tx_c;

endinterface

`endif