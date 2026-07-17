////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : kst_intf.sv
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
//  SystemVerilog interface for Kernel KST verification
////////////////////////////////////////////////////////////////////////////////

`ifndef KST_INTF_SV
`define KST_INTF_SV

interface kst_intf(
    input logic clk, 
    input logic clk_uart, 
    input logic clk_eth1, 
    input logic clk_eth2, 
    input logic clk_eth3, 
    input logic clk_eth4, 
    input logic rst_n
);

    // =========================================================
    // 1. Outputs from kernel_start_tx
    // =========================================================
    logic tx_acq_start_uart1, tx_acq_start_uart2, tx_acq_start_uart3;
    logic tx_data_sent_uart1, tx_data_sent_uart2, tx_data_sent_uart3;

    logic eth_tx_start_pulse_eth1;
    logic eth_tx_start_pulse_eth2;
    logic eth_tx_start_pulse_eth3;
    logic eth_tx_start_pulse_eth4;

    // =========================================================
    // 2. FIFO Read Side (Controlled by UVM to simulate UART consuming data)
    // =========================================================
    logic       rd_en_uart1, rd_en_uart2, rd_en_uart3;
    logic [8:0] data_out_uart1, data_out_uart2, data_out_uart3;
    
    // Empty flags (Driven by physical FIFO, monitored by UVM and kernel_start_tx)
    logic       fifo_empty_uart1, fifo_empty_uart2, fifo_empty_uart3;

endinterface

`endif