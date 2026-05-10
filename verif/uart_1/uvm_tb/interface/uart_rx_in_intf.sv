////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : uart_rx_in_intf.sv
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
//  interface for uart rx input
////////////////////////////////////////////////////////////////////////////////
interface uart_rx_in_intf(input logic clk);
  logic rst_n;
  logic data_rx;
  logic parity_en;
  logic parity_odd_even;
  
  
  logic [31:0] baudrate;
  logic        baudrate_valid;
  logic [3:0]  data_width;
endinterface