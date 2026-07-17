////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : nrz_intf.sv
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
//  SystemVerilog interface for Kernel NRZ verification
////////////////////////////////////////////////////////////////////////////////

`ifndef NRZ_INTF_SV
`define NRZ_INTF_SV

interface nrz_intf(
    input logic clk_20mhz,  // Slow clock for NRZ Driver
    input logic clk_64mhz   // Fast system clock for NRZ Monitor
);
    // ==========================================
    // 20MHz Domain (Driven by Testbench)
    // ==========================================
    logic       data_in_nrz;

    // ==========================================
    // 64MHz Domain (Monitored from RTL)
    // ==========================================
    logic       fifo_wr_en;
    logic [7:0] fifo_data_in;
    logic       eth_tx_start_pulse;

endinterface

`endif