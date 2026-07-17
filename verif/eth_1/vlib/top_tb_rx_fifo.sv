////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : top_tb_rx_fifo.sv
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
//  top-level testbench for Ethernet RX FIFO verification
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

import uvm_pkg::*; 
import rx_fifo_pkg::*; // Import our new package
`include "uvm_macros.svh" 
`include "eth_rx_fifo_if.sv"
`include "rx_fifo_base_test.sv"

module top_tb_rx_fifo;

  // ---> 1. DECLARATIONS <---
  logic clk; 
  logic rst_n;

  // ---> 2. STRUCTURAL INSTANTIATIONS <---
  eth_rx_fifo_if vif (.clk(clk), .rst_n(rst_n));

  eth_if    tx_dummy_if (.clk(clk), .rst_n(rst_n));
  eth_rx_if rx_dummy_if (.clk(clk), .rst_n(rst_n));

  eth_rx_fifo_IF u_dut (
    .clk(clk),
    .rst_n(rst_n),
    
    // Output (To External System)
    .eth_rx_data_valid(vif.eth_rx_data_valid),
    .rx_fifo_wr_en(vif.rx_fifo_wr_en),
    .rx_fifo_data_in(vif.rx_fifo_data_in),
    .ext_fifo_rst_n(vif.ext_fifo_rst_n),
    .corrupt_packet_counter(vif.corrupt_packet_counter),
    .valid_eth_frame              (vif.valid_eth_frame),
    
    // Input (From PHY Status)
    .payload_length(vif.payload_length),
    .rx_transaction_done_pulse(vif.rx_transaction_done_pulse),
    .packet_received_corrupt_pulse(vif.packet_received_corrupt_pulse),
    .invalid_bytes(vif.invalid_bytes),
    
    // Internal RAM Feedback Loop
    .int_fifo_rd_en(vif.int_fifo_rd_en),
    .int_fifo_data_out(vif.int_fifo_data_out)
  );

  // ---> 3. BEHAVIORAL TIMING <---
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
    uvm_config_db#(virtual eth_rx_fifo_if)::set(null, "*", "vif", vif); 
    run_test("rx_fifo_base_test"); 
  end

endmodule