////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : eth_rx_if.sv
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
//  SystemVerilog interface for Ethernet RX verification
////////////////////////////////////////////////////////////////////////////////

`ifndef ETH_RX_IF_SV
`define ETH_RX_IF_SV

interface eth_rx_if (input logic clk, input logic rst_n);
  // --- Physical PHY Inputs (Driven by UVM Active Driver) ---
  logic [7:0] rxd;
  logic       rx_dv;
  logic       rx_er;
  
  // --- Internal FIFO Outputs (Snooped by UVM Passive Monitor) ---
  logic       rx_fifo_wr_en;
  logic [7:0] fifo_data_in;

  // --- Status & Diagnostics (Snooped by UVM Passive Monitor) ---
  logic        packet_received_corrupt_out;
  logic [10:0] invalid_bytes;
  logic        rx_transaction_done_pulse;
  logic [10:0] payload_length;

  initial begin
    rxd = 0; rx_dv = 0; rx_er = 0;
  end
endinterface

`endif