////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : fifo_intf.sv
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
//  interface for fifo
////////////////////////////////////////////////////////////////////////////////

interface fifo_intf #(parameter PARAM_DATA_WIDTH = 9) (
    input logic wr_clk,
    input logic rd_clk
);
  
  // Global Reset
  logic rst_n;

  // ==========================================
  // WRITE DOMAIN (Producer)
  // ==========================================
  logic [PARAM_DATA_WIDTH-1:0] data_in;
  logic                        packet_corrupt_flag;
  logic                        write_pulse_in; 
  logic                        fifo_full;

  // ==========================================
  // READ DOMAIN (Consumer)
  // ==========================================
  logic                        read_data_flag;
  logic [PARAM_DATA_WIDTH-1:0] data_out;
  logic                        read_pulse_out; 
  logic                        fifo_empty;

endinterface