////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : eth_rx_app_if.sv
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
//  SystemVerilog interface for Ethernet RX application verification
////////////////////////////////////////////////////////////////////////////////

`ifndef ETH_RX_APP_IF_SV
`define ETH_RX_APP_IF_SV

interface eth_rx_app_if(input logic clk, input logic rst_n);
  // MAC Output Status
  logic        rx_fifo_rst_n;
  logic [10:0] rx_eth_corrupt_frame_count;
  logic        eth_rx_data_valid;
  logic [10:0] rx_eth_valid_bytes;

  // MAC Internal Write Pins
  logic        rx_fifo_wr_en;
  logic [7:0]  rx_fifo_data_in;

  // ---> NEW: External physical FIFO Read Pins
  logic       ext_rx_fifo_rd_en;
  logic [7:0] ext_rx_fifo_data_out;
  logic       ext_rx_fifo_empty;
endinterface

`endif