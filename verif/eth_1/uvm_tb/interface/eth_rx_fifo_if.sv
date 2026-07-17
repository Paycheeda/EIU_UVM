////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : eth_rx_fifo_if.sv
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
//  SystemVerilog interface for Ethernet RX FIFO verification
////////////////////////////////////////////////////////////////////////////////

`ifndef ETH_RX_FIFO_IF_SV
`define ETH_RX_FIFO_IF_SV

interface eth_rx_fifo_if(input logic clk, input logic rst_n);

  // Output from DUT (To External System)
  logic        eth_rx_data_valid;
  logic        rx_fifo_wr_en;
  logic [7:0]  rx_fifo_data_in;
  logic        ext_fifo_rst_n;
  logic [10:0] corrupt_packet_counter;
  logic [10:0] valid_eth_frame;

  // Input to DUT (From PHY Status)
  logic [10:0] payload_length;
  logic        rx_transaction_done_pulse;
  logic        packet_received_corrupt_pulse;
  logic [10:0] invalid_bytes;

  // Internal RAM Feedback Loop
  logic        int_fifo_rd_en;
  logic [7:0]  int_fifo_data_out;

endinterface

`endif