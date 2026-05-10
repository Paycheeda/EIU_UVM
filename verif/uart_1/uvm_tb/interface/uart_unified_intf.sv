////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : uart_unified_intf.sv
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
//  interface for uart 
////////////////////////////////////////////////////////////////////////////////
interface uart_unified_intf(input logic clk);
  // ==========================================
  // GLOBAL SIGNALS
  // ==========================================
  logic rst_n;

  // ==========================================
  // HOST INTERFACE (Left Side - CPU Bus)
  // ==========================================
  
  logic [31:0] baudrate;
  logic        parity_en;
  logic        parity_odd_even;
  logic [3:0]  data_width;

  logic [(`UART_WIDTH - 1) : 0] data_in_TX;
  logic                         send_data_tx;
  logic                         uart_tx_busy; 

  logic [(`UART_WIDTH - 1) : 0] data_out_RX;
  logic                         RX_DATA_RECEIVED;
  logic                         flag_packet_RX_corrupt;


  // ==========================================
  // LINE INTERFACE (Right Side - Physical Wires)
  // ==========================================
  
  logic rx;

  logic tx;

endinterface