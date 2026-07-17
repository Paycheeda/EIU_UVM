////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : kwr_intf.sv
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
//  SystemVerilog interface for Kernel KWR verification
////////////////////////////////////////////////////////////////////////////////

`ifndef KWR_INTF_SV
`define KWR_INTF_SV

interface kwr_intf(input logic clk, input logic rst_n);

    // =========================================================
    // UART Outputs
    // =========================================================
    logic       data_send_uart1,  data_send_uart2,  data_send_uart3;
    logic       fifo_wr_en_uart1, fifo_wr_en_uart2, fifo_wr_en_uart3;
    logic [8:0] fifo_data_in_uart1, fifo_data_in_uart2, fifo_data_in_uart3;

    // =========================================================
    // ETH Outputs
    // =========================================================
    logic       data_send_eth1,  data_send_eth2,  data_send_eth3,  data_send_eth4;
    logic       fifo_wr_en_eth1, fifo_wr_en_eth2, fifo_wr_en_eth3, fifo_wr_en_eth4;
    logic [7:0] fifo_data_in_eth1, fifo_data_in_eth2, fifo_data_in_eth3, fifo_data_in_eth4;

endinterface

`endif