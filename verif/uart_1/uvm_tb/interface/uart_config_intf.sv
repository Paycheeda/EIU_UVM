////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : uart_config_intf.sv
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
//  SystemVerilog interface for UART verification
////////////////////////////////////////////////////////////////////////////////

`ifndef UART_CONFIG_INTF_SV
`define UART_CONFIG_INTF_SV

interface uart_config_intf (
    input logic clk );

  // Global
  logic        rst_n;

  // UART Configuration Registers
  logic [31:0] baudrate;
  logic        parity_en;
  logic        parity_odd_even;
  logic [3:0]  data_width;
  
  // The trigger pulse to latch the new settings
  logic        config_done_pulse;

  // --- NEW: Hardware Stat Trackers ---
    logic [10:0] hw_rx_corrupt_bytes;
    logic [10:0] hw_rx_valid_bytes;

    logic uart_tx_busy;
    logic uart_rx_busy;

endinterface : uart_config_intf

`endif