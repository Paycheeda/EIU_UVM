////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : tb_top_fifo.sv
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
//  top-level testbench for UART FIFO verification
////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/100fs

module tb_top_fifo;
  import uvm_pkg::*;
  // Make sure you bundle your new FIFO files into a fifo_pkg.sv!
  import fifo_pkg::*; 

  bit wr_clk;
  bit rd_clk;
  bit rst_n;

  real wr_freq = 100.0; // Default to 100 MHz
  real rd_freq = 44.2;  // Default to 44.2 MHz
  real wr_half_period;
  real rd_half_period;

  initial begin
    // Grab the frequencies from the command line (if provided)
    if ($value$plusargs("wr_freq=%f", wr_freq)) begin end
    if ($value$plusargs("rd_freq=%f", rd_freq)) begin end

    // Calculate half-periods in nanoseconds (Period = 1000 / MHz)
    wr_half_period = 1000.0 / wr_freq / 2.0;
    rd_half_period = 1000.0 / rd_freq / 2.0;
  end

  // Generate Write Clock
  initial begin
    wr_clk = 0;
    #1; // Wait a tiny tick for the math to finish computing above
    forever #wr_half_period wr_clk = ~wr_clk;
  end

  // Generate Read Clock
  initial begin
    rd_clk = 0;
    #1; 
    forever #rd_half_period rd_clk = ~rd_clk;
  end

  // ==========================================
  // INTERFACE & DUT
  // ==========================================
  fifo_intf #(9) vif(wr_clk, rd_clk);
  assign vif.rst_n = rst_n;

  dual_port_FIFO #(
      .PARAM_DATA_WIDTH(9),
      .PARAM_FIFO_SIZE("18Kb")
  ) dut (
      .rst_n                  (vif.rst_n),
      
      // Write Domain
      .wr_clk                 (vif.wr_clk),
      .packet_corrupt_flag    (vif.packet_corrupt_flag),
      .data_in                (vif.data_in),
      .write_pulse_in         (vif.write_pulse_in), // <-- FIXED
      .fifo_full              (vif.fifo_full),
      
      // Read Domain
      .rd_clk                 (vif.rd_clk),
      .read_data_flag         (vif.read_data_flag),
      .data_out               (vif.data_out),
      .read_pulse_out         (vif.read_pulse_out), // <-- FIXED
      .fifo_empty             (vif.fifo_empty)
  );

  // ==========================================
  // UVM IGNITION SWITCH
  // ==========================================
  initial begin
    uvm_config_db#(virtual fifo_intf)::set(null, "*", "fifo_vif", vif);
    run_test(); 
  end

 // ==========================================
  // HARDWARE RESET
  // ==========================================
  initial begin
    rst_n = 0; 
    #2000;  // <-- Held low for 200ns (well over 5 rd_clk cycles)
    rst_n = 1;
  end
endmodule