////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : tb_top.sv
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
//  top-level testbench for Kernel verification
////////////////////////////////////////////////////////////////////////////////

/*`timescale 1ns/1ps
`ifndef TB_TOP_SV
`define TB_TOP_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import kernel_pkg::*;

module tb_top;

    // =========================================================
    // 1. PHYSICAL CLOCK GENERATORS (Real-World Frequencies)
    // =========================================================
    logic clk = 0;
    logic clk_uart = 0;
    logic clk_eth1 = 0, clk_eth2 = 0, clk_eth3 = 0, clk_eth4 = 0, clk_eth_nrz = 0;
    
    logic clk_20MHz = 0;

    // System Clock: 64 MHz (15.625ns period)
    always #7.8125 clk = ~clk;

    // UART Clock: 44.2368 MHz (22.605ns period)
    always #11.3025 clk_uart = ~clk_uart;

    // Ethernet Clocks: 125 MHz (8.0ns period)
    always #4.0 clk_eth1 = ~clk_eth1;
    always #4.0 clk_eth2 = ~clk_eth2;
    always #4.0 clk_eth3 = ~clk_eth3;
    always #4.0 clk_eth4 = ~clk_eth4;
    always #4.0 clk_eth_nrz = ~clk_eth_nrz;
    
    // 20MHz NRZ Clock (25ns half-period)
    always #25.0 clk_20MHz = ~clk_20MHz;

    logic rst_n;
    initial begin rst_n = 1'b0; #200; rst_n = 1'b1; end

    // =========================================================
    // 2. Interface Instantiations
    // =========================================================
    bkp_intf bkp_if(.clk(clk), .rst_n(rst_n));
    out_intf out_if(.clk(clk), .rst_n(rst_n));
    kwr_intf kwr_if(.clk(clk), .rst_n(rst_n));
    
    kst_intf kst_if(
        .clk(clk), .clk_uart(clk_uart), .clk_eth1(clk_eth1), .clk_eth2(clk_eth2), 
        .clk_eth3(clk_eth3), .clk_eth4(clk_eth4), .rst_n(rst_n)
    );

    krd_intf krd_if(
        .clk(clk), .clk_uart(clk_uart), .clk_eth1(clk_eth1), .clk_eth2(clk_eth2), 
        .clk_eth3(clk_eth3), .clk_eth4(clk_eth4), .rst_n(rst_n)
    );
    
    nrz_intf nrz_if(
        .clk_20mhz(clk_20MHz), 
        .clk_64mhz(clk)
    );

    wire strobe_pulse = bkp_if.bkp_config_wr_pulse;
    
    // ---> FIXED: UART Data Width Conversion Logic <---
    wire data_width_uart1_raw;
    wire data_width_uart2_raw;
    wire data_width_uart3_raw;
    
    assign out_if.data_width_uart1 = (data_width_uart1_raw) ? 4'd9 : 4'd8;
    assign out_if.data_width_uart2 = (data_width_uart2_raw) ? 4'd9 : 4'd8;
    assign out_if.data_width_uart3 = (data_width_uart3_raw) ? 4'd9 : 4'd8;

    // =========================================================
    // 3. DUT: kernel_config
    // =========================================================
    kernel_config CONFIG_DUT (
        .clk(clk), .clk_uart(clk_uart), .clk_eth1(clk_eth1), .clk_eth2(clk_eth2), .clk_eth3(clk_eth3), .clk_eth4(clk_eth4), .clk_eth_nrz(clk_eth_nrz), .rst_n(rst_n),
        .bkp_config_wr_pulse(bkp_if.bkp_config_wr_pulse), .bkp_card_id(bkp_if.bkp_card_id), .fpga_card_id(bkp_if.fpga_card_id),
        .bkp_data_dir(bkp_if.bkp_data_dir), .bkp_address(bkp_if.bkp_address), .bkp_data(bkp_if.bkp_data),
        .config_done_pulse(out_if.config_done_pulse), .config_done_uart(out_if.config_done_uart), .config_done_eth1(out_if.config_done_eth1),
        .config_done_eth2(out_if.config_done_eth2), .config_done_eth3(out_if.config_done_eth3), .config_done_eth4(out_if.config_done_eth4),
        
        // Use the raw 1-bit wires here!
        .baudrate_uart1(out_if.baudrate_uart1), .parity_en_uart1(out_if.parity_en_uart1), .parity_odd_even_uart1(out_if.parity_odd_even_uart1), .data_width_uart1(data_width_uart1_raw),
        .baudrate_uart2(out_if.baudrate_uart2), .parity_en_uart2(out_if.parity_en_uart2), .parity_odd_even_uart2(out_if.parity_odd_even_uart2), .data_width_uart2(data_width_uart2_raw),
        .baudrate_uart3(out_if.baudrate_uart3), .parity_en_uart3(out_if.parity_en_uart3), .parity_odd_even_uart3(out_if.parity_odd_even_uart3), .data_width_uart3(data_width_uart3_raw),
        
        .dest_mac_eth1(out_if.dest_mac_eth1), .source_mac_eth1(out_if.source_mac_eth1), .source_ip_eth1(out_if.source_ip_eth1), .dest_ip_eth1(out_if.dest_ip_eth1), .source_port_eth1(out_if.source_port_eth1), .dest_port_eth1(out_if.dest_port_eth1), .tx_payload_length_eth1(out_if.tx_payload_length_eth1),
        .dest_mac_eth2(out_if.dest_mac_eth2), .source_mac_eth2(out_if.source_mac_eth2), .source_ip_eth2(out_if.source_ip_eth2), .dest_ip_eth2(out_if.dest_ip_eth2), .source_port_eth2(out_if.source_port_eth2), .dest_port_eth2(out_if.dest_port_eth2), .tx_payload_length_eth2(out_if.tx_payload_length_eth2),
        .dest_mac_eth3(out_if.dest_mac_eth3), .source_mac_eth3(out_if.source_mac_eth3), .source_ip_eth3(out_if.source_ip_eth3), .dest_ip_eth3(out_if.dest_ip_eth3), .source_port_eth3(out_if.source_port_eth3), .dest_port_eth3(out_if.dest_port_eth3), .tx_payload_length_eth3(out_if.tx_payload_length_eth3),
        .dest_mac_eth4(out_if.dest_mac_eth4), .source_mac_eth4(out_if.source_mac_eth4), .source_ip_eth4(out_if.source_ip_eth4), .dest_ip_eth4(out_if.dest_ip_eth4), .source_port_eth4(out_if.source_port_eth4), .dest_port_eth4(out_if.dest_port_eth4), .tx_payload_length_eth4(out_if.tx_payload_length_eth4),
        .dest_mac_eth_nrz(out_if.dest_mac_eth_nrz), .source_mac_eth_nrz(out_if.source_mac_eth_nrz), .source_ip_eth_nrz(out_if.source_ip_eth_nrz), .dest_ip_eth_nrz(out_if.dest_ip_eth_nrz), .source_port_eth_nrz(out_if.source_port_eth_nrz), .dest_port_eth_nrz(out_if.dest_port_eth_nrz), .tx_payload_length_eth_nrz(out_if.tx_payload_length_eth_nrz), .tx_zero_endian_eth_nrz(out_if.tx_zero_endian_eth_nrz), .tx_bpw_eth_nrz(out_if.tx_bpw_eth_nrz), .tx_sync_word1_eth_nrz(out_if.tx_sync_word1_eth_nrz), .tx_sync_word2_eth_nrz(out_if.tx_sync_word2_eth_nrz)
    );

    // =========================================================
    // 4. DUT: kernel_write
    // =========================================================
    kernel_write ROUTER_DUT (
        .clk(clk), .rst_n(rst_n),
        .bkp_card_id(bkp_if.bkp_card_id), .fpga_card_id(bkp_if.fpga_card_id), .bkp_data_dir(bkp_if.bkp_data_dir),
        .bkp_address(bkp_if.bkp_address), .bkp_data(bkp_if.bkp_data), .word_start_strobe_pulse(strobe_pulse), 
        .data_send_uart1(kwr_if.data_send_uart1), .data_send_uart2(kwr_if.data_send_uart2), .data_send_uart3(kwr_if.data_send_uart3),
        .fifo_wr_en_uart1(kwr_if.fifo_wr_en_uart1), .fifo_wr_en_uart2(kwr_if.fifo_wr_en_uart2), .fifo_wr_en_uart3(kwr_if.fifo_wr_en_uart3),
        .fifo_data_in_uart1(kwr_if.fifo_data_in_uart1), .fifo_data_in_uart2(kwr_if.fifo_data_in_uart2), .fifo_data_in_uart3(kwr_if.fifo_data_in_uart3),
        .data_send_eth1(kwr_if.data_send_eth1), .data_send_eth2(kwr_if.data_send_eth2), .data_send_eth3(kwr_if.data_send_eth3), .data_send_eth4(kwr_if.data_send_eth4),
        .fifo_wr_en_eth1(kwr_if.fifo_wr_en_eth1), .fifo_wr_en_eth2(kwr_if.fifo_wr_en_eth2), .fifo_wr_en_eth3(kwr_if.fifo_wr_en_eth3), .fifo_wr_en_eth4(kwr_if.fifo_wr_en_eth4),
        .fifo_data_in_eth1(kwr_if.fifo_data_in_eth1), .fifo_data_in_eth2(kwr_if.fifo_data_in_eth2), .fifo_data_in_eth3(kwr_if.fifo_data_in_eth3), .fifo_data_in_eth4(kwr_if.fifo_data_in_eth4)
    );

    // =========================================================
    // 5. TX FIFOs for UARTs
    // =========================================================
    dual_port_FIFO #( .PARAM_DATA_WIDTH(9), .PARAM_FIFO_SIZE("18Kb") ) UART1_FIFO (
        .rst_n(rst_n), .wr_clk(clk), .data_in(kwr_if.fifo_data_in_uart1), .wr_en(kwr_if.fifo_wr_en_uart1),
        .rd_clk(clk_uart), .rd_en(kst_if.rd_en_uart1), .data_out(kst_if.data_out_uart1), .fifo_full(), .fifo_empty(kst_if.fifo_empty_uart1)
    );

    dual_port_FIFO #( .PARAM_DATA_WIDTH(9), .PARAM_FIFO_SIZE("18Kb") ) UART2_FIFO (
        .rst_n(rst_n), .wr_clk(clk), .data_in(kwr_if.fifo_data_in_uart2), .wr_en(kwr_if.fifo_wr_en_uart2),
        .rd_clk(clk_uart), .rd_en(kst_if.rd_en_uart2), .data_out(kst_if.data_out_uart2), .fifo_full(), .fifo_empty(kst_if.fifo_empty_uart2)
    );

    dual_port_FIFO #( .PARAM_DATA_WIDTH(9), .PARAM_FIFO_SIZE("18Kb") ) UART3_FIFO (
        .rst_n(rst_n), .wr_clk(clk), .data_in(kwr_if.fifo_data_in_uart3), .wr_en(kwr_if.fifo_wr_en_uart3),
        .rd_clk(clk_uart), .rd_en(kst_if.rd_en_uart3), .data_out(kst_if.data_out_uart3), .fifo_full(), .fifo_empty(kst_if.fifo_empty_uart3)
    );

    // =========================================================
    // 6. DUT: kernel_start_tx
    // =========================================================
    kernel_start_tx START_TX_DUT (
        .clk(clk), .rst_n(rst_n), .clk_uart(clk_uart), .clk_eth1(clk_eth1), .clk_eth2(clk_eth2), .clk_eth3(clk_eth3), .clk_eth4(clk_eth4),
        .data_send_uart1(kwr_if.data_send_uart1), .data_send_uart2(kwr_if.data_send_uart2), .data_send_uart3(kwr_if.data_send_uart3),
        .data_send_eth1(kwr_if.data_send_eth1), .data_send_eth2(kwr_if.data_send_eth2), .data_send_eth3(kwr_if.data_send_eth3), .data_send_eth4(kwr_if.data_send_eth4),
        .tx_fifo_empty_uart1(kst_if.fifo_empty_uart1), .tx_fifo_empty_uart2(kst_if.fifo_empty_uart2), .tx_fifo_empty_uart3(kst_if.fifo_empty_uart3),
        .tx_acq_start_uart1(kst_if.tx_acq_start_uart1), .tx_acq_start_uart2(kst_if.tx_acq_start_uart2), .tx_acq_start_uart3(kst_if.tx_acq_start_uart3),
        .eth_tx_start_pulse_eth1(kst_if.eth_tx_start_pulse_eth1), .eth_tx_start_pulse_eth2(kst_if.eth_tx_start_pulse_eth2), .eth_tx_start_pulse_eth3(kst_if.eth_tx_start_pulse_eth3), .eth_tx_start_pulse_eth4(kst_if.eth_tx_start_pulse_eth4),
        .tx_data_sent_uart1(kst_if.tx_data_sent_uart1), .tx_data_sent_uart2(kst_if.tx_data_sent_uart2), .tx_data_sent_uart3(kst_if.tx_data_sent_uart3)
    );

    // =========================================================
    // 7. PHYSICAL RX FIFOS
    // =========================================================
    dual_port_FIFO #( .PARAM_DATA_WIDTH(9), .PARAM_FIFO_SIZE("18Kb") ) RX_UART1 (
        .rst_n(rst_n), 
        .wr_clk(clk_uart), 
        .data_in(krd_if.rx_fifo_data_in_uart1), .wr_en(krd_if.rx_fifo_wr_en_uart1),
        .rd_clk(clk), .rd_en(krd_if.rx_fifo_rd_en_uart1), .data_out(krd_if.rx_fifo_data_out_uart1), 
        .fifo_empty(krd_if.rx_fifo_empty_uart1), .fifo_full()
    );
    dual_port_FIFO #( .PARAM_DATA_WIDTH(9), .PARAM_FIFO_SIZE("18Kb") ) RX_UART2 (
        .rst_n(rst_n), .wr_clk(clk_uart), .data_in(krd_if.rx_fifo_data_in_uart2), .wr_en(krd_if.rx_fifo_wr_en_uart2),
        .rd_clk(clk), .rd_en(krd_if.rx_fifo_rd_en_uart2), .data_out(krd_if.rx_fifo_data_out_uart2), 
        .fifo_empty(krd_if.rx_fifo_empty_uart2), .fifo_full()
    );
    dual_port_FIFO #( .PARAM_DATA_WIDTH(9), .PARAM_FIFO_SIZE("18Kb") ) RX_UART3 (
        .rst_n(rst_n), .wr_clk(clk_uart), .data_in(krd_if.rx_fifo_data_in_uart3), .wr_en(krd_if.rx_fifo_wr_en_uart3),
        .rd_clk(clk), .rd_en(krd_if.rx_fifo_rd_en_uart3), .data_out(krd_if.rx_fifo_data_out_uart3), 
        .fifo_empty(krd_if.rx_fifo_empty_uart3), .fifo_full()
    );
    dual_port_FIFO #( .PARAM_DATA_WIDTH(8), .PARAM_FIFO_SIZE("18Kb") ) RX_ETH1 (
        .rst_n(rst_n), 
        .wr_clk(clk_eth1), 
        .data_in(krd_if.rx_fifo_data_in_eth1), .wr_en(krd_if.rx_fifo_wr_en_eth1),
        .rd_clk(clk), .rd_en(krd_if.rx_fifo_rd_en_eth1), .data_out(krd_if.rx_fifo_data_out_eth1), 
        .fifo_empty(krd_if.rx_fifo_empty_eth1), .fifo_full()
    );
    dual_port_FIFO #( .PARAM_DATA_WIDTH(8), .PARAM_FIFO_SIZE("18Kb") ) RX_ETH2 (
        .rst_n(rst_n), .wr_clk(clk_eth2), .data_in(krd_if.rx_fifo_data_in_eth2), .wr_en(krd_if.rx_fifo_wr_en_eth2),
        .rd_clk(clk), .rd_en(krd_if.rx_fifo_rd_en_eth2), .data_out(krd_if.rx_fifo_data_out_eth2), 
        .fifo_empty(krd_if.rx_fifo_empty_eth2), .fifo_full()
    );
    dual_port_FIFO #( .PARAM_DATA_WIDTH(8), .PARAM_FIFO_SIZE("18Kb") ) RX_ETH3 (
        .rst_n(rst_n), .wr_clk(clk_eth3), .data_in(krd_if.rx_fifo_data_in_eth3), .wr_en(krd_if.rx_fifo_wr_en_eth3),
        .rd_clk(clk), .rd_en(krd_if.rx_fifo_rd_en_eth3), .data_out(krd_if.rx_fifo_data_out_eth3), 
        .fifo_empty(krd_if.rx_fifo_empty_eth3), .fifo_full()
    );
    dual_port_FIFO #( .PARAM_DATA_WIDTH(8), .PARAM_FIFO_SIZE("18Kb") ) RX_ETH4 (
        .rst_n(rst_n), .wr_clk(clk_eth4), .data_in(krd_if.rx_fifo_data_in_eth4), .wr_en(krd_if.rx_fifo_wr_en_eth4),
        .rd_clk(clk), .rd_en(krd_if.rx_fifo_rd_en_eth4), .data_out(krd_if.rx_fifo_data_out_eth4), 
        .fifo_empty(krd_if.rx_fifo_empty_eth4), .fifo_full()
    );

    // =========================================================
    // 8. DUT Instantiation: kernel_read
    // =========================================================
    kernel_read READ_DUT (
        .clk(clk), 
        .clk_uart(clk_uart), 
        .rst_n(rst_n),
        .rx_clk_eth1(clk_eth1), .rx_clk_eth2(clk_eth2), .rx_clk_eth3(clk_eth3), .rx_clk_eth4(clk_eth4),
        
        .bkp_card_id(bkp_if.bkp_card_id),
        .fpga_card_id(bkp_if.fpga_card_id),
        .bkp_data_dir(bkp_if.bkp_data_dir),
        .bkp_address(bkp_if.bkp_address),
        .bkp_data(bkp_if.bkp_data), 
        .word_start_strobe_pulse(strobe_pulse),
        
        .rx_fifo_data_out_uart1(krd_if.rx_fifo_data_out_uart1), .rx_fifo_data_out_uart2(krd_if.rx_fifo_data_out_uart2), .rx_fifo_data_out_uart3(krd_if.rx_fifo_data_out_uart3),
        .rx_fifo_data_out_eth1(krd_if.rx_fifo_data_out_eth1), .rx_fifo_data_out_eth2(krd_if.rx_fifo_data_out_eth2), .rx_fifo_data_out_eth3(krd_if.rx_fifo_data_out_eth3), .rx_fifo_data_out_eth4(krd_if.rx_fifo_data_out_eth4),
        
        .rx_valid_byte_count_uart1(krd_if.rx_valid_byte_count_uart1), .rx_valid_byte_count_uart2(krd_if.rx_valid_byte_count_uart2), .rx_valid_byte_count_uart3(krd_if.rx_valid_byte_count_uart3),
        .rx_eth_valid_bytes_eth1(krd_if.rx_eth_valid_bytes_eth1), .rx_eth_valid_bytes_eth2(krd_if.rx_eth_valid_bytes_eth2), .rx_eth_valid_bytes_eth3(krd_if.rx_eth_valid_bytes_eth3), .rx_eth_valid_bytes_eth4(krd_if.rx_eth_valid_bytes_eth4),
        
        .rx_corrupt_byte_count_uart1(krd_if.rx_corrupt_byte_count_uart1), .rx_corrupt_byte_count_uart2(krd_if.rx_corrupt_byte_count_uart2), .rx_corrupt_byte_count_uart3(krd_if.rx_corrupt_byte_count_uart3),
        .rx_eth_corrupt_frame_count_eth1(krd_if.rx_eth_corrupt_frame_count_eth1), .rx_eth_corrupt_frame_count_eth2(krd_if.rx_eth_corrupt_frame_count_eth2), .rx_eth_corrupt_frame_count_eth3(krd_if.rx_eth_corrupt_frame_count_eth3), .rx_eth_corrupt_frame_count_eth4(krd_if.rx_eth_corrupt_frame_count_eth4),
        
        .tx_fifo_full_uart1(krd_if.tx_fifo_full_uart1), .tx_fifo_full_uart2(krd_if.tx_fifo_full_uart2), .tx_fifo_full_uart3(krd_if.tx_fifo_full_uart3),
        .tx_fifo_full_eth1(krd_if.tx_fifo_full_eth1), .tx_fifo_full_eth2(krd_if.tx_fifo_full_eth2), .tx_fifo_full_eth3(krd_if.tx_fifo_full_eth3), .tx_fifo_full_eth4(krd_if.tx_fifo_full_eth4), .tx_fifo_full_eth_nrz(krd_if.tx_fifo_full_eth_nrz),
        
        .rx_fifo_full_uart1(krd_if.rx_fifo_full_uart1), .rx_fifo_full_uart2(krd_if.rx_fifo_full_uart2), .rx_fifo_full_uart3(krd_if.rx_fifo_full_uart3),
        .rx_fifo_full_eth1(krd_if.rx_fifo_full_eth1), .rx_fifo_full_eth2(krd_if.rx_fifo_full_eth2), .rx_fifo_full_eth3(krd_if.rx_fifo_full_eth3), .rx_fifo_full_eth4(krd_if.rx_fifo_full_eth4),
        
        .tx_fifo_empty_uart1(krd_if.tx_fifo_empty_uart1), .tx_fifo_empty_uart2(krd_if.tx_fifo_empty_uart2), .tx_fifo_empty_uart3(krd_if.tx_fifo_empty_uart3),
        .tx_fifo_empty_eth1(krd_if.tx_fifo_empty_eth1), .tx_fifo_empty_eth2(krd_if.tx_fifo_empty_eth2), .tx_fifo_empty_eth3(krd_if.tx_fifo_empty_eth3), .tx_fifo_empty_eth4(krd_if.tx_fifo_empty_eth4), .tx_fifo_empty_eth_nrz(krd_if.tx_fifo_empty_eth_nrz),
        
        .rx_fifo_empty_uart1(krd_if.rx_fifo_empty_uart1), .rx_fifo_empty_uart2(krd_if.rx_fifo_empty_uart2), .rx_fifo_empty_uart3(krd_if.rx_fifo_empty_uart3),
        .rx_fifo_empty_eth1(krd_if.rx_fifo_empty_eth1), .rx_fifo_empty_eth2(krd_if.rx_fifo_empty_eth2), .rx_fifo_empty_eth3(krd_if.rx_fifo_empty_eth3), .rx_fifo_empty_eth4(krd_if.rx_fifo_empty_eth4),
        
        .rx_fifo_rd_en_uart1(krd_if.rx_fifo_rd_en_uart1), .rx_fifo_rd_en_uart2(krd_if.rx_fifo_rd_en_uart2), .rx_fifo_rd_en_uart3(krd_if.rx_fifo_rd_en_uart3),
        .rx_fifo_rd_en_eth1(krd_if.rx_fifo_rd_en_eth1), .rx_fifo_rd_en_eth2(krd_if.rx_fifo_rd_en_eth2), .rx_fifo_rd_en_eth3(krd_if.rx_fifo_rd_en_eth3), .rx_fifo_rd_en_eth4(krd_if.rx_fifo_rd_en_eth4),
        
        .tx_data_sent_uart1(krd_if.tx_data_sent_uart1), .tx_data_sent_uart2(krd_if.tx_data_sent_uart2), .tx_data_sent_uart3(krd_if.tx_data_sent_uart3),
        .tx_data_sent_eth1(out_if.eth_tx_data_sent_eth1), .tx_data_sent_eth2(out_if.eth_tx_data_sent_eth2), .tx_data_sent_eth3(out_if.eth_tx_data_sent_eth3), .tx_data_sent_eth4(out_if.eth_tx_data_sent_eth4), .tx_data_sent_eth_nrz(out_if.eth_tx_data_sent_eth_nrz)
    );

    // =========================================================
    // 9. DUT Instantiation: kernel_nrz
    // =========================================================
    kernel_nrz NRZ_DUT (
        .clk                         (clk),
        .clk_eth                     (clk_eth_nrz),
        .rst_n                       (rst_n),
        
        // ---> FIXED: Connected to the out_if dedicated force wire <---
        .bkp_prg_mode_on             (out_if.bkp_prg_mode_force), 
        
        .clk_20MHz                   (clk_20MHz),
        .data_in_nrz                 (nrz_if.data_in_nrz),
        .config_done_pulse_eth_nrz   (out_if.config_done_eth_nrz),
        .config_done_pulse           (out_if.config_done_pulse),
        .tx_bpw_eth_nrz              (out_if.tx_bpw_eth_nrz),
        .tx_payload_length_eth_nrz   (out_if.tx_payload_length_eth_nrz),
        .tx_zero_endian_eth_nrz      (out_if.tx_zero_endian_eth_nrz),
        .tx_sync_word1_eth_nrz       (out_if.tx_sync_word1_eth_nrz),
        .tx_sync_word2_eth_nrz       (out_if.tx_sync_word2_eth_nrz),
        .tx_payload_length_actual    (), 
        .eth_tx_start_pulse_eth_nrz  (nrz_if.eth_tx_start_pulse),
        .tx_fifo_wr_en_eth_nrz       (nrz_if.fifo_wr_en),
        .tx_fifo_data_in_eth_nrz     (nrz_if.fifo_data_in)
    );

    // =========================================================
    // 10. Start UVM Test
    // =========================================================
    initial begin
        uvm_config_db#(virtual bkp_intf)::set(null, "*", "bkp_vif", bkp_if);
        uvm_config_db#(virtual out_intf)::set(null, "*", "out_vif", out_if);
        uvm_config_db#(virtual kwr_intf)::set(null, "*", "kwr_vif", kwr_if); 
        uvm_config_db#(virtual kst_intf)::set(null, "*", "kst_vif", kst_if); 
        uvm_config_db#(virtual krd_intf)::set(null, "*", "krd_vif", krd_if);
        uvm_config_db#(virtual nrz_intf)::set(null, "*", "nrz_vif", nrz_if);

        run_test();
    end

    // =========================================================
    // 11. THE X-RAY HARDWARE MONITOR
    // =========================================================
    always @(posedge krd_if.rx_fifo_wr_en_uart1) begin
        $display("\n=======================================================");
        $display("[X-RAY] Time %0t: UVM Driver PUSHING DATA into FIFO! Data: 'h%0h", $time, krd_if.rx_fifo_data_in_uart1);
    end

    always @(negedge krd_if.rx_fifo_empty_uart1) begin
        $display("[X-RAY] Time %0t: Physical FIFO EMPTY flag dropped! Data is safely inside!", $time);
        $display("=======================================================\n");
    end

    always @(posedge krd_if.rx_fifo_rd_en_uart1) begin
        $display("\n[X-RAY] Time %0t: Kernel_Read RTL is asserting RD_EN to fetch the Data!", $time);
        $display("[X-RAY] Time %0t: Data emerging from FIFO: 'h%0h", $time, krd_if.rx_fifo_data_out_uart1);
    end

    int cycle_cnt = 0;
    always @(posedge clk) begin
        if (krd_if.rx_fifo_rd_en_uart1) cycle_cnt = 1;
        else if (cycle_cnt > 0 && cycle_cnt < 6) cycle_cnt++;
        else cycle_cnt = 0;
    end

    always @(negedge clk) begin
        if (cycle_cnt == 1) $display("\n================ X-RAY CYCLE TRACE (UART1 FIFO READ) ================");
        if (cycle_cnt > 0) begin
            $display("[X-RAY] Cycle %0d | RD_EN: %b | FIFO_DO_BUS: 'h%0h | BKP_DATA_REG: 'h%0h | FSM_STATE: %0d",
                cycle_cnt, krd_if.rx_fifo_rd_en_uart1, krd_if.rx_fifo_data_out_uart1, READ_DUT.bkp_data_reg, READ_DUT.state);
        end
        if (cycle_cnt == 5) $display("===================================================================\n");
    end

    // =========================================================
    // 12. THE HARD-PROOF CDC WIRETAPS (ETH1 Valid Bytes)
    // =========================================================
    
    // Tap 1: Did the UVM Driver actually drive the physical pins?
    always @(krd_if.rx_eth_valid_bytes_eth1) begin
        if (krd_if.rx_eth_valid_bytes_eth1 > 0)
            $display("\n[X-RAY CDC] Time %0t: Tap 1 - UVM Driver drove ETH1 Count = %0d onto physical pins", $time, krd_if.rx_eth_valid_bytes_eth1);
    end

    // Tap 2: Did the 125 MHz Source Clock successfully catch the integer and trigger a toggle?
    always @(READ_DUT.cdc_rx_eth_valid_bytes_eth1_inst.src_count_shadow) begin
        if (READ_DUT.cdc_rx_eth_valid_bytes_eth1_inst.src_count_shadow > 0)
            $display("[X-RAY CDC] Time %0t: Tap 2 - 125MHz SRC Domain latched Count = %0d. Firing Toggle!", $time, READ_DUT.cdc_rx_eth_valid_bytes_eth1_inst.src_count_shadow);
    end

    // Tap 3: Did the 64 MHz Destination Clock see the toggle pulse?
    always @(posedge READ_DUT.cdc_rx_eth_valid_bytes_eth1_inst.dst_toggle_edge) begin
        $display("[X-RAY CDC] Time %0t: Tap 3 - 64MHz DST Domain caught the toggle edge! Sampling data...", $time);
    end

    // Tap 4: Did the final synchronized output update?
    always @(READ_DUT.cdc_rx_eth_valid_bytes_eth1_inst.dst_count) begin
        if (READ_DUT.cdc_rx_eth_valid_bytes_eth1_inst.dst_count > 0)
            $display("[X-RAY CDC] Time %0t: Tap 4 - CDC Successfully Synchronized Output = %0d", $time, READ_DUT.cdc_rx_eth_valid_bytes_eth1_inst.dst_count);
    end

    // Tap 5: What is the CPU actually reading at the exact moment of the sweep?
    always @(posedge clk) begin
        if (bkp_if.bkp_address == 10 && bkp_if.bkp_config_wr_pulse) begin
            $display("[BKP-XRAY] Time %0t: CPU requested ETH1 Count. The raw CDC Output wire is currently: %0d\n", $time, READ_DUT.rx_eth_valid_bytes_eth1_kernel);
        end
    end

    // =========================================================
    // 13. THE RACE CONDITION WIRETAPS (UART1 FIFO)
    // =========================================================

    // Tap A: Logs the exact time the RTL captures the bus
    always @(posedge clk) begin
        if (READ_DUT.state == 2'd1 && READ_DUT.captured_address == 6'd0) begin // DATA_CAPTURE_STATE for UART1
            $display("[RACE-XRAY] Time %0t: RTL is taking a snapshot of the bus...", $time);
            $display("            Current Bus Value: 'h%0h", krd_if.rx_fifo_data_out_uart1);
        end
    end

    // Tap B: Logs the exact time the FIFO puts new data on the bus
    always @(krd_if.rx_fifo_data_out_uart1) begin
        if (krd_if.rx_fifo_data_out_uart1 > 0) begin
            $display("[RACE-XRAY] Time %0t: FIFO physically pushed NEW data onto the bus: 'h%0h", $time, krd_if.rx_fifo_data_out_uart1);
        end
    end

endmodule

`endif*/

`timescale 1ns/1ps
`ifndef TB_TOP_SV
`define TB_TOP_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import kernel_pkg::*;

module tb_top;

    // =========================================================
    // 1. PHYSICAL CLOCK GENERATORS
    // =========================================================
    logic clk = 0;
    logic clk_uart = 0;
    logic clk_eth1 = 0, clk_eth2 = 0, clk_eth3 = 0, clk_eth4 = 0, clk_eth_nrz = 0;
    logic clk_20MHz = 0;

    always #7.8125 clk = ~clk;
    always #11.3025 clk_uart = ~clk_uart;
    always #4.0 clk_eth1 = ~clk_eth1;
    always #4.0 clk_eth2 = ~clk_eth2;
    always #4.0 clk_eth3 = ~clk_eth3;
    always #4.0 clk_eth4 = ~clk_eth4;
    always #4.0 clk_eth_nrz = ~clk_eth_nrz;
    always #25.0 clk_20MHz = ~clk_20MHz;

    logic rst_n;
    initial begin rst_n = 1'b0; #200; rst_n = 1'b1; end

    // =========================================================
    // 2. Interface Instantiations
    // =========================================================
    bkp_intf bkp_if(.clk(clk), .rst_n(rst_n));
    out_intf out_if(.clk(clk), .rst_n(rst_n));
    kwr_intf kwr_if(.clk(clk), .rst_n(rst_n));
    
    kst_intf kst_if(
        .clk(clk), .clk_uart(clk_uart), .clk_eth1(clk_eth1), .clk_eth2(clk_eth2), 
        .clk_eth3(clk_eth3), .clk_eth4(clk_eth4), .rst_n(rst_n)
    );

    krd_intf krd_if(
        .clk(clk), .clk_uart(clk_uart), .clk_eth1(clk_eth1), .clk_eth2(clk_eth2), 
        .clk_eth3(clk_eth3), .clk_eth4(clk_eth4), .rst_n(rst_n)
    );
    
    nrz_intf nrz_if(
        .clk_20mhz(clk_20MHz), 
        .clk_64mhz(clk)
    );

    // ---> FIXED: Read Strobe is strictly isolated from Write Pulse! <---
    wire strobe_pulse = bkp_if.word_start_strobe;
    
    wire data_width_uart1_raw;
    wire data_width_uart2_raw;
    wire data_width_uart3_raw;
    
    assign out_if.data_width_uart1 = (data_width_uart1_raw) ? 4'd9 : 4'd8;
    assign out_if.data_width_uart2 = (data_width_uart2_raw) ? 4'd9 : 4'd8;
    assign out_if.data_width_uart3 = (data_width_uart3_raw) ? 4'd9 : 4'd8;

    // =========================================================
    // 3. DUT: kernel_config
    // =========================================================
    kernel_config CONFIG_DUT (
        .clk(clk), .clk_uart(clk_uart), .clk_eth1(clk_eth1), .clk_eth2(clk_eth2), .clk_eth3(clk_eth3), .clk_eth4(clk_eth4), .clk_eth_nrz(clk_eth_nrz), .rst_n(rst_n),
        .bkp_config_wr_pulse(bkp_if.bkp_config_wr_pulse), .bkp_card_id(bkp_if.bkp_card_id), .fpga_card_id(bkp_if.fpga_card_id),
        .bkp_data_dir(bkp_if.bkp_data_dir), .bkp_address(bkp_if.bkp_address), .bkp_data(bkp_if.bkp_data),
        .config_done_pulse(out_if.config_done_pulse), .config_done_uart(out_if.config_done_uart), .config_done_eth1(out_if.config_done_eth1),
        .config_done_eth2(out_if.config_done_eth2), .config_done_eth3(out_if.config_done_eth3), .config_done_eth4(out_if.config_done_eth4),
        
        .baudrate_uart1(out_if.baudrate_uart1), .parity_en_uart1(out_if.parity_en_uart1), .parity_odd_even_uart1(out_if.parity_odd_even_uart1), .data_width_uart1(data_width_uart1_raw),
        .baudrate_uart2(out_if.baudrate_uart2), .parity_en_uart2(out_if.parity_en_uart2), .parity_odd_even_uart2(out_if.parity_odd_even_uart2), .data_width_uart2(data_width_uart2_raw),
        .baudrate_uart3(out_if.baudrate_uart3), .parity_en_uart3(out_if.parity_en_uart3), .parity_odd_even_uart3(out_if.parity_odd_even_uart3), .data_width_uart3(data_width_uart3_raw),
        
        .dest_mac_eth1(out_if.dest_mac_eth1), .source_mac_eth1(out_if.source_mac_eth1), .source_ip_eth1(out_if.source_ip_eth1), .dest_ip_eth1(out_if.dest_ip_eth1), .source_port_eth1(out_if.source_port_eth1), .dest_port_eth1(out_if.dest_port_eth1), .tx_payload_length_eth1(out_if.tx_payload_length_eth1),
        .dest_mac_eth2(out_if.dest_mac_eth2), .source_mac_eth2(out_if.source_mac_eth2), .source_ip_eth2(out_if.source_ip_eth2), .dest_ip_eth2(out_if.dest_ip_eth2), .source_port_eth2(out_if.source_port_eth2), .dest_port_eth2(out_if.dest_port_eth2), .tx_payload_length_eth2(out_if.tx_payload_length_eth2),
        .dest_mac_eth3(out_if.dest_mac_eth3), .source_mac_eth3(out_if.source_mac_eth3), .source_ip_eth3(out_if.source_ip_eth3), .dest_ip_eth3(out_if.dest_ip_eth3), .source_port_eth3(out_if.source_port_eth3), .dest_port_eth3(out_if.dest_port_eth3), .tx_payload_length_eth3(out_if.tx_payload_length_eth3),
        .dest_mac_eth4(out_if.dest_mac_eth4), .source_mac_eth4(out_if.source_mac_eth4), .source_ip_eth4(out_if.source_ip_eth4), .dest_ip_eth4(out_if.dest_ip_eth4), .source_port_eth4(out_if.source_port_eth4), .dest_port_eth4(out_if.dest_port_eth4), .tx_payload_length_eth4(out_if.tx_payload_length_eth4),
        
        // ---> FIXED: NRZ Parameters reconnected to out_if! <---
        .dest_mac_eth_nrz           (), // Leave MACs/IPs floated if unused by NRZ RTL 
        .source_mac_eth_nrz         (), 
        .source_ip_eth_nrz          (), 
        .dest_ip_eth_nrz            (), 
        .source_port_eth_nrz        (), 
        .dest_port_eth_nrz          (), 
        .tx_payload_length_eth_nrz  (out_if.tx_payload_length_eth_nrz), 
        .tx_zero_endian_eth_nrz     (out_if.tx_zero_endian_eth_nrz), 
        .tx_bpw_eth_nrz             (out_if.tx_bpw_eth_nrz), 
        .tx_sync_word1_eth_nrz      (out_if.tx_sync_word1_eth_nrz), 
        .tx_sync_word2_eth_nrz      (out_if.tx_sync_word2_eth_nrz)
    );

    // =========================================================
    // 4. DUT: kernel_write
    // =========================================================
    kernel_write ROUTER_DUT (
        .clk(clk), .rst_n(rst_n),
        .bkp_card_id(bkp_if.bkp_card_id), .fpga_card_id(bkp_if.fpga_card_id), .bkp_data_dir(bkp_if.bkp_data_dir),
        .bkp_address(bkp_if.bkp_address), .bkp_data(bkp_if.bkp_data), .word_start_strobe_pulse(strobe_pulse), 
        .data_send_uart1(kwr_if.data_send_uart1), .data_send_uart2(kwr_if.data_send_uart2), .data_send_uart3(kwr_if.data_send_uart3),
        .fifo_wr_en_uart1(kwr_if.fifo_wr_en_uart1), .fifo_wr_en_uart2(kwr_if.fifo_wr_en_uart2), .fifo_wr_en_uart3(kwr_if.fifo_wr_en_uart3),
        .fifo_data_in_uart1(kwr_if.fifo_data_in_uart1), .fifo_data_in_uart2(kwr_if.fifo_data_in_uart2), .fifo_data_in_uart3(kwr_if.fifo_data_in_uart3),
        .data_send_eth1(kwr_if.data_send_eth1), .data_send_eth2(kwr_if.data_send_eth2), .data_send_eth3(kwr_if.data_send_eth3), .data_send_eth4(kwr_if.data_send_eth4),
        .fifo_wr_en_eth1(kwr_if.fifo_wr_en_eth1), .fifo_wr_en_eth2(kwr_if.fifo_wr_en_eth2), .fifo_wr_en_eth3(kwr_if.fifo_wr_en_eth3), .fifo_wr_en_eth4(kwr_if.fifo_wr_en_eth4),
        .fifo_data_in_eth1(kwr_if.fifo_data_in_eth1), .fifo_data_in_eth2(kwr_if.fifo_data_in_eth2), .fifo_data_in_eth3(kwr_if.fifo_data_in_eth3), .fifo_data_in_eth4(kwr_if.fifo_data_in_eth4)
    );

    // =========================================================
    // 5. TX FIFOs for UARTs
    // =========================================================
    dual_port_FIFO #( .PARAM_DATA_WIDTH(9), .PARAM_FIFO_SIZE("18Kb") ) UART1_FIFO (
        .rst_n(rst_n), .wr_clk(clk), .data_in(kwr_if.fifo_data_in_uart1), .wr_en(kwr_if.fifo_wr_en_uart1),
        .rd_clk(clk_uart), .rd_en(kst_if.rd_en_uart1), .data_out(kst_if.data_out_uart1), .fifo_full(), .fifo_empty(kst_if.fifo_empty_uart1)
    );

    dual_port_FIFO #( .PARAM_DATA_WIDTH(9), .PARAM_FIFO_SIZE("18Kb") ) UART2_FIFO (
        .rst_n(rst_n), .wr_clk(clk), .data_in(kwr_if.fifo_data_in_uart2), .wr_en(kwr_if.fifo_wr_en_uart2),
        .rd_clk(clk_uart), .rd_en(kst_if.rd_en_uart2), .data_out(kst_if.data_out_uart2), .fifo_full(), .fifo_empty(kst_if.fifo_empty_uart2)
    );

    dual_port_FIFO #( .PARAM_DATA_WIDTH(9), .PARAM_FIFO_SIZE("18Kb") ) UART3_FIFO (
        .rst_n(rst_n), .wr_clk(clk), .data_in(kwr_if.fifo_data_in_uart3), .wr_en(kwr_if.fifo_wr_en_uart3),
        .rd_clk(clk_uart), .rd_en(kst_if.rd_en_uart3), .data_out(kst_if.data_out_uart3), .fifo_full(), .fifo_empty(kst_if.fifo_empty_uart3)
    );

    // =========================================================
    // 6. DUT: kernel_start_tx
    // =========================================================
    kernel_start_tx START_TX_DUT (
        .clk(clk), .rst_n(rst_n), .clk_uart(clk_uart), .clk_eth1(clk_eth1), .clk_eth2(clk_eth2), .clk_eth3(clk_eth3), .clk_eth4(clk_eth4),
        .data_send_uart1(kwr_if.data_send_uart1), .data_send_uart2(kwr_if.data_send_uart2), .data_send_uart3(kwr_if.data_send_uart3),
        .data_send_eth1(kwr_if.data_send_eth1), .data_send_eth2(kwr_if.data_send_eth2), .data_send_eth3(kwr_if.data_send_eth3), .data_send_eth4(kwr_if.data_send_eth4),
        .tx_fifo_empty_uart1(kst_if.fifo_empty_uart1), .tx_fifo_empty_uart2(kst_if.fifo_empty_uart2), .tx_fifo_empty_uart3(kst_if.fifo_empty_uart3),
        .tx_acq_start_uart1(kst_if.tx_acq_start_uart1), .tx_acq_start_uart2(kst_if.tx_acq_start_uart2), .tx_acq_start_uart3(kst_if.tx_acq_start_uart3),
        .eth_tx_start_pulse_eth1(kst_if.eth_tx_start_pulse_eth1), .eth_tx_start_pulse_eth2(kst_if.eth_tx_start_pulse_eth2), .eth_tx_start_pulse_eth3(kst_if.eth_tx_start_pulse_eth3), .eth_tx_start_pulse_eth4(kst_if.eth_tx_start_pulse_eth4),
        .tx_data_sent_uart1(kst_if.tx_data_sent_uart1), .tx_data_sent_uart2(kst_if.tx_data_sent_uart2), .tx_data_sent_uart3(kst_if.tx_data_sent_uart3)
    );

    // =========================================================
    // 7. PHYSICAL RX FIFOS
    // =========================================================
    dual_port_FIFO #( .PARAM_DATA_WIDTH(9), .PARAM_FIFO_SIZE("18Kb") ) RX_UART1 (
        .rst_n(rst_n), 
        .wr_clk(clk_uart), 
        .data_in(krd_if.rx_fifo_data_in_uart1), .wr_en(krd_if.rx_fifo_wr_en_uart1),
        .rd_clk(clk), .rd_en(krd_if.rx_fifo_rd_en_uart1), .data_out(krd_if.rx_fifo_data_out_uart1), 
        .fifo_empty(krd_if.rx_fifo_empty_uart1), .fifo_full()
    );
    dual_port_FIFO #( .PARAM_DATA_WIDTH(9), .PARAM_FIFO_SIZE("18Kb") ) RX_UART2 (
        .rst_n(rst_n), .wr_clk(clk_uart), .data_in(krd_if.rx_fifo_data_in_uart2), .wr_en(krd_if.rx_fifo_wr_en_uart2),
        .rd_clk(clk), .rd_en(krd_if.rx_fifo_rd_en_uart2), .data_out(krd_if.rx_fifo_data_out_uart2), 
        .fifo_empty(krd_if.rx_fifo_empty_uart2), .fifo_full()
    );
    dual_port_FIFO #( .PARAM_DATA_WIDTH(9), .PARAM_FIFO_SIZE("18Kb") ) RX_UART3 (
        .rst_n(rst_n), .wr_clk(clk_uart), .data_in(krd_if.rx_fifo_data_in_uart3), .wr_en(krd_if.rx_fifo_wr_en_uart3),
        .rd_clk(clk), .rd_en(krd_if.rx_fifo_rd_en_uart3), .data_out(krd_if.rx_fifo_data_out_uart3), 
        .fifo_empty(krd_if.rx_fifo_empty_uart3), .fifo_full()
    );
    dual_port_FIFO #( .PARAM_DATA_WIDTH(8), .PARAM_FIFO_SIZE("18Kb") ) RX_ETH1 (
        .rst_n(rst_n), 
        .wr_clk(clk_eth1), 
        .data_in(krd_if.rx_fifo_data_in_eth1), .wr_en(krd_if.rx_fifo_wr_en_eth1),
        .rd_clk(clk), .rd_en(krd_if.rx_fifo_rd_en_eth1), .data_out(krd_if.rx_fifo_data_out_eth1), 
        .fifo_empty(krd_if.rx_fifo_empty_eth1), .fifo_full()
    );
    dual_port_FIFO #( .PARAM_DATA_WIDTH(8), .PARAM_FIFO_SIZE("18Kb") ) RX_ETH2 (
        .rst_n(rst_n), .wr_clk(clk_eth2), .data_in(krd_if.rx_fifo_data_in_eth2), .wr_en(krd_if.rx_fifo_wr_en_eth2),
        .rd_clk(clk), .rd_en(krd_if.rx_fifo_rd_en_eth2), .data_out(krd_if.rx_fifo_data_out_eth2), 
        .fifo_empty(krd_if.rx_fifo_empty_eth2), .fifo_full()
    );
    dual_port_FIFO #( .PARAM_DATA_WIDTH(8), .PARAM_FIFO_SIZE("18Kb") ) RX_ETH3 (
        .rst_n(rst_n), .wr_clk(clk_eth3), .data_in(krd_if.rx_fifo_data_in_eth3), .wr_en(krd_if.rx_fifo_wr_en_eth3),
        .rd_clk(clk), .rd_en(krd_if.rx_fifo_rd_en_eth3), .data_out(krd_if.rx_fifo_data_out_eth3), 
        .fifo_empty(krd_if.rx_fifo_empty_eth3), .fifo_full()
    );
    dual_port_FIFO #( .PARAM_DATA_WIDTH(8), .PARAM_FIFO_SIZE("18Kb") ) RX_ETH4 (
        .rst_n(rst_n), .wr_clk(clk_eth4), .data_in(krd_if.rx_fifo_data_in_eth4), .wr_en(krd_if.rx_fifo_wr_en_eth4),
        .rd_clk(clk), .rd_en(krd_if.rx_fifo_rd_en_eth4), .data_out(krd_if.rx_fifo_data_out_eth4), 
        .fifo_empty(krd_if.rx_fifo_empty_eth4), .fifo_full()
    );

    // =========================================================
    // 8. DUT Instantiation: kernel_read
    // =========================================================
    kernel_read READ_DUT (
        .clk(clk), 
        .clk_uart(clk_uart), 
        .rst_n(rst_n),
        .rx_clk_eth1(clk_eth1), .rx_clk_eth2(clk_eth2), .rx_clk_eth3(clk_eth3), .rx_clk_eth4(clk_eth4),
        
        .bkp_card_id(bkp_if.bkp_card_id),
        .fpga_card_id(bkp_if.fpga_card_id),
        .bkp_data_dir(bkp_if.bkp_data_dir),
        .bkp_address(bkp_if.bkp_address),
        .bkp_data(bkp_if.bkp_data), 
        .word_start_strobe_pulse(strobe_pulse),
        
        .rx_fifo_data_out_uart1(krd_if.rx_fifo_data_out_uart1), .rx_fifo_data_out_uart2(krd_if.rx_fifo_data_out_uart2), .rx_fifo_data_out_uart3(krd_if.rx_fifo_data_out_uart3),
        .rx_fifo_data_out_eth1(krd_if.rx_fifo_data_out_eth1), .rx_fifo_data_out_eth2(krd_if.rx_fifo_data_out_eth2), .rx_fifo_data_out_eth3(krd_if.rx_fifo_data_out_eth3), .rx_fifo_data_out_eth4(krd_if.rx_fifo_data_out_eth4),
        
        .rx_valid_byte_count_uart1(krd_if.rx_valid_byte_count_uart1), .rx_valid_byte_count_uart2(krd_if.rx_valid_byte_count_uart2), .rx_valid_byte_count_uart3(krd_if.rx_valid_byte_count_uart3),
        .rx_eth_valid_bytes_eth1(krd_if.rx_eth_valid_bytes_eth1), .rx_eth_valid_bytes_eth2(krd_if.rx_eth_valid_bytes_eth2), .rx_eth_valid_bytes_eth3(krd_if.rx_eth_valid_bytes_eth3), .rx_eth_valid_bytes_eth4(krd_if.rx_eth_valid_bytes_eth4),
        
        .rx_corrupt_byte_count_uart1(krd_if.rx_corrupt_byte_count_uart1), .rx_corrupt_byte_count_uart2(krd_if.rx_corrupt_byte_count_uart2), .rx_corrupt_byte_count_uart3(krd_if.rx_corrupt_byte_count_uart3),
        .rx_eth_corrupt_frame_count_eth1(krd_if.rx_eth_corrupt_frame_count_eth1), .rx_eth_corrupt_frame_count_eth2(krd_if.rx_eth_corrupt_frame_count_eth2), .rx_eth_corrupt_frame_count_eth3(krd_if.rx_eth_corrupt_frame_count_eth3), .rx_eth_corrupt_frame_count_eth4(krd_if.rx_eth_corrupt_frame_count_eth4),
        
        .tx_fifo_full_uart1(krd_if.tx_fifo_full_uart1), .tx_fifo_full_uart2(krd_if.tx_fifo_full_uart2), .tx_fifo_full_uart3(krd_if.tx_fifo_full_uart3),
        .tx_fifo_full_eth1(krd_if.tx_fifo_full_eth1), .tx_fifo_full_eth2(krd_if.tx_fifo_full_eth2), .tx_fifo_full_eth3(krd_if.tx_fifo_full_eth3), .tx_fifo_full_eth4(krd_if.tx_fifo_full_eth4), .tx_fifo_full_eth_nrz(krd_if.tx_fifo_full_eth_nrz),
        
        .rx_fifo_full_uart1(krd_if.rx_fifo_full_uart1), .rx_fifo_full_uart2(krd_if.rx_fifo_full_uart2), .rx_fifo_full_uart3(krd_if.rx_fifo_full_uart3),
        .rx_fifo_full_eth1(krd_if.rx_fifo_full_eth1), .rx_fifo_full_eth2(krd_if.rx_fifo_full_eth2), .rx_fifo_full_eth3(krd_if.rx_fifo_full_eth3), .rx_fifo_full_eth4(krd_if.rx_fifo_full_eth4),
        
        .tx_fifo_empty_uart1(krd_if.tx_fifo_empty_uart1), .tx_fifo_empty_uart2(krd_if.tx_fifo_empty_uart2), .tx_fifo_empty_uart3(krd_if.tx_fifo_empty_uart3),
        .tx_fifo_empty_eth1(krd_if.tx_fifo_empty_eth1), .tx_fifo_empty_eth2(krd_if.tx_fifo_empty_eth2), .tx_fifo_empty_eth3(krd_if.tx_fifo_empty_eth3), .tx_fifo_empty_eth4(krd_if.tx_fifo_empty_eth4), .tx_fifo_empty_eth_nrz(krd_if.tx_fifo_empty_eth_nrz),
        
        .rx_fifo_empty_uart1(krd_if.rx_fifo_empty_uart1), .rx_fifo_empty_uart2(krd_if.rx_fifo_empty_uart2), .rx_fifo_empty_uart3(krd_if.rx_fifo_empty_uart3),
        .rx_fifo_empty_eth1(krd_if.rx_fifo_empty_eth1), .rx_fifo_empty_eth2(krd_if.rx_fifo_empty_eth2), .rx_fifo_empty_eth3(krd_if.rx_fifo_empty_eth3), .rx_fifo_empty_eth4(krd_if.rx_fifo_empty_eth4),
        
        .rx_fifo_rd_en_uart1(krd_if.rx_fifo_rd_en_uart1), .rx_fifo_rd_en_uart2(krd_if.rx_fifo_rd_en_uart2), .rx_fifo_rd_en_uart3(krd_if.rx_fifo_rd_en_uart3),
        .rx_fifo_rd_en_eth1(krd_if.rx_fifo_rd_en_eth1), .rx_fifo_rd_en_eth2(krd_if.rx_fifo_rd_en_eth2), .rx_fifo_rd_en_eth3(krd_if.rx_fifo_rd_en_eth3), .rx_fifo_rd_en_eth4(krd_if.rx_fifo_rd_en_eth4),
        
        .tx_data_sent_uart1(krd_if.tx_data_sent_uart1), .tx_data_sent_uart2(krd_if.tx_data_sent_uart2), .tx_data_sent_uart3(krd_if.tx_data_sent_uart3),
        .tx_data_sent_eth1(out_if.eth_tx_data_sent_eth1), .tx_data_sent_eth2(out_if.eth_tx_data_sent_eth2), .tx_data_sent_eth3(out_if.eth_tx_data_sent_eth3), .tx_data_sent_eth4(out_if.eth_tx_data_sent_eth4), .tx_data_sent_eth_nrz(out_if.eth_tx_data_sent_eth_nrz)
    );

    // =========================================================
    // 9. DUT Instantiation: kernel_nrz
    // =========================================================
    kernel_nrz NRZ_DUT (
        .clk                         (clk),
        .clk_eth                     (clk_eth_nrz),
        .rst_n                       (rst_n),
        .bkp_prg_mode_on             (out_if.bkp_prg_mode_force), 
        .clk_20MHz                   (clk_20MHz),
        .data_in_nrz                 (nrz_if.data_in_nrz),
        .config_done_pulse_eth_nrz   (out_if.config_done_eth_nrz),
        .config_done_pulse           (out_if.config_done_pulse),
        
        // ---> These now receive live data from CONFIG_DUT! <---
        .tx_bpw_eth_nrz              (out_if.tx_bpw_eth_nrz),
        .tx_payload_length_eth_nrz   (out_if.tx_payload_length_eth_nrz),
        .tx_zero_endian_eth_nrz      (out_if.tx_zero_endian_eth_nrz),
        .tx_sync_word1_eth_nrz       (out_if.tx_sync_word1_eth_nrz),
        .tx_sync_word2_eth_nrz       (out_if.tx_sync_word2_eth_nrz),
        
        .tx_payload_length_actual    (), 
        .eth_tx_start_pulse_eth_nrz  (nrz_if.eth_tx_start_pulse),
        .tx_fifo_wr_en_eth_nrz       (nrz_if.fifo_wr_en),
        .tx_fifo_data_in_eth_nrz     (nrz_if.fifo_data_in)
    );
    // =========================================================
    // 10. Start UVM Test
    // =========================================================
    initial begin
        uvm_config_db#(virtual bkp_intf)::set(null, "*", "bkp_vif", bkp_if);
        uvm_config_db#(virtual out_intf)::set(null, "*", "out_vif", out_if);
        uvm_config_db#(virtual kwr_intf)::set(null, "*", "kwr_vif", kwr_if); 
        uvm_config_db#(virtual kst_intf)::set(null, "*", "kst_vif", kst_if); 
        uvm_config_db#(virtual krd_intf)::set(null, "*", "krd_vif", krd_if);
        uvm_config_db#(virtual nrz_intf)::set(null, "*", "nrz_vif", nrz_if);

        run_test();
    end
    // =========================================================
    // PHYSICAL HARDWARE PROBES (WIRETAPS)
    // =========================================================
    
    // Wiretap 1: Does the UVM interface wire actually toggle?
    always @(uart_rx_if[0].tx) begin
        $display("HW_PROBE @ %0t: uart_rx_if[0].tx flipped to %b", $time, uart_rx_if[0].tx);
    end

    // Wiretap 2: Does the EIU_TOP input pin actually see the toggle?
    always @(DUT.uart1_rx) begin
        $display("HW_PROBE @ %0t: EIU_TOP.uart1_rx pin saw a transition to %b", $time, DUT.uart1_rx);
    end

    // Wiretap 3: What is the reset state actually doing?
    always @(rst_n or uart_rx_if[0].rst_n) begin
        $display("HW_PROBE @ %0t: Global rst_n = %b | Interface rst_n = %b", $time, rst_n, uart_rx_if[0].rst_n);
    end

endmodule
`endif