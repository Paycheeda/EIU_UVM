////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : fifo_intf_uart.sv
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
//  SystemVerilog interface for FIFO UART verification
////////////////////////////////////////////////////////////////////////////////

`ifndef FIFO_INTF_UART_SV
`define FIFO_INTF_UART_SV

interface fifo_intf_uart #(parameter DATA_WIDTH = 9) (
    input logic wr_clk,
    input logic rd_clk
);

  // ==========================================
  // 1. GLOBAL SIGNALS
  // ==========================================
  logic rst_n;

  // ==========================================
  // 2. WRITE DOMAIN SIGNALS (Producer)
  // ==========================================
  logic [DATA_WIDTH-1:0] data_in;
  logic                  wr_en;
  logic                  fifo_full;

  // ==========================================
  // 3. READ DOMAIN SIGNALS (Consumer)
  // ==========================================
  logic                  rd_en;
  logic [DATA_WIDTH-1:0] data_out;
  logic                  fifo_empty;

  // ==========================================
  // 4. SYSTEMVERILOG ASSERTIONS (SVA)
  // ==========================================
    property p_no_overflow;
    @(posedge wr_clk) disable iff (!rst_n)
    (fifo_full |-> wr_en == 1'b0);
  endproperty
  
  assert_no_overflow: assert property (p_no_overflow) 
    else $error("[SVA ERROR] wr_en asserted while FIFO was FULL at time %0t!", $time);

  property p_no_underflow;
    @(posedge rd_clk) disable iff (!rst_n)
    (fifo_empty |-> rd_en == 1'b0);
  endproperty
  
  assert_no_underflow: assert property (p_no_underflow) 
    else $error("[SVA ERROR] rd_en asserted while FIFO was EMPTY at time %0t!", $time);

endinterface : fifo_intf_uart

`endif