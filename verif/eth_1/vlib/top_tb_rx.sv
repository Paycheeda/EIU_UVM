////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : top_tb_rx.sv
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
//  top-level testbench for Ethernet RX verification
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

import uvm_pkg::*; 
`include "uvm_macros.svh" 
`include "eth_rx_if.sv"
`include "eth_if.sv"

module top_tb_rx;

  // ---> 1. DECLARATIONS (Physical Nets and Registers) <---
  logic clk; 
  logic rst_n;

  wire        crc_first_wire;
  wire        crc_valid_wire;
  wire        crc_last_wire;
  wire [31:0] crc_calc_wire;
  wire        crc_done_flag_wire;

  // ---> 2. STRUCTURAL INSTANTIATIONS (Interfaces and Modules) <---
  eth_rx_if vif (.clk(clk), .rst_n(rst_n));
  eth_if tx_dummy_if (.clk(clk), .rst_n(rst_n));

  eth_rx_IF u_dut (
    .clk(clk),
    .rst_n(rst_n),
    
    // Physical PHY
    .rxd(vif.rxd),
    .rx_dv(vif.rx_dv),
    .rx_er(vif.rx_er),
    
    // FIFO Interface
    .rx_fifo_wr_en(vif.rx_fifo_wr_en),
    .fifo_data_in(vif.fifo_data_in),
    
    // Status
    .packet_received_corrupt_out(vif.packet_received_corrupt_out),
    .invalid_bytes(vif.invalid_bytes),
    .rx_transaction_done_pulse(vif.rx_transaction_done_pulse),
    .payload_length(vif.payload_length),
    
    // Sideband CRC Routing
    .crc_first(crc_first_wire),
    .crc_valid(crc_valid_wire),
    .crc_last(crc_last_wire),
    .crc_done_flag(crc_done_flag_wire),
    .crc_calc(crc_calc_wire)
  );

  crc32_data8 u_crc (
    .clk(clk),
    .rst_n(rst_n),
    .crc_start_flag(crc_first_wire),
    .crc_valid_flag(crc_valid_wire),
    .crc_last_flag(crc_last_wire),
    .data_in(vif.fifo_data_in), 
    .crc_out(crc_calc_wire),
    .crc_done_pulse(), 
    .crc_done_flag(crc_done_flag_wire)
  );

  // ---> 3. BEHAVIORAL TIMING (Clocks and UVM Launch) <---
  initial begin 
    clk = 0; 
    forever #4 clk = ~clk; 
  end
  
  initial begin 
    rst_n = 0; 
    #100; 
    rst_n = 1; 
  end

  initial begin 
    uvm_config_db#(virtual eth_rx_if)::set(null, "*", "vif", vif); 
    run_test("eth_rx_base_test"); 
  end

endmodule