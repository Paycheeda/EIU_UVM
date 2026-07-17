////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : krd_sequence.sv
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
//  UVM sequence for Kernel KRD verification
////////////////////////////////////////////////////////////////////////////////

/*`ifndef KRD_SEQUENCE_SV
`define KRD_SEQUENCE_SV

class krd_sequence extends uvm_sequence #(krd_item);
    `uvm_object_utils(krd_sequence)

    int current_uart1_cnt = 0;
    int current_eth1_cnt  = 0;

    function new(string name = "krd_sequence"); super.new(name); endfunction

    task body();
        `uvm_info("KRD_SEQ", "Starting Continuous Background Network Injection...", UVM_LOW)

        // Run continuously for a set number of major network "bursts"
        repeat(10) begin
            // Wait a random amount of time (simulate unpredictable network traffic)
            #( $urandom_range(2000, 5000) * 1ns );

            req = krd_item::type_id::create("req");
            start_item(req);

            // THE FIX: PREVENT 'X' PROPAGATION
            req.rx_fifo_data_out_uart1 = 0; req.rx_fifo_data_out_uart2 = 0; req.rx_fifo_data_out_uart3 = 0;
            req.rx_fifo_data_out_eth1 = 0;  req.rx_fifo_data_out_eth2 = 0;  req.rx_fifo_data_out_eth3 = 0;  req.rx_fifo_data_out_eth4 = 0;
            
            req.rx_corrupt_byte_count_uart1 = 0; req.rx_corrupt_byte_count_uart2 = 0; req.rx_corrupt_byte_count_uart3 = 0;
            req.rx_eth_corrupt_frame_count_eth1 = 0; req.rx_eth_corrupt_frame_count_eth2 = 0; req.rx_eth_corrupt_frame_count_eth3 = 0; req.rx_eth_corrupt_frame_count_eth4 = 0;

            req.tx_fifo_full_uart1 = 0; req.tx_fifo_empty_uart1 = 0; req.tx_data_sent_uart1 = 0; // (Add rest of flags here if needed)

            // 1. Random UART1 Traffic
            if ($urandom_range(0, 10) > 3) begin // 70% chance of UART traffic
                int new_uart_pkts = $urandom_range(1, 3);
                current_uart1_cnt += new_uart_pkts;
                req.rx_valid_byte_count_uart1 = current_uart1_cnt;
                req.rx_fifo_data_out_uart1 = $urandom; 
                `uvm_info("KRD_SEQ", $sformatf("[NETWORK] Injected %0d new UART1 packets! (Total: %0d)", new_uart_pkts, current_uart1_cnt), UVM_LOW)
            end else begin
                req.rx_valid_byte_count_uart1 = current_uart1_cnt;
            end

            // 2. Random ETH1 Traffic
            if ($urandom_range(0, 10) > 2) begin // 80% chance of ETH traffic
                int new_eth_pkts = $urandom_range(2, 5);
                current_eth1_cnt += new_eth_pkts;
                req.rx_eth_valid_bytes_eth1 = current_eth1_cnt;
                req.rx_fifo_data_out_eth1 = $urandom;
                `uvm_info("KRD_SEQ", $sformatf("[NETWORK] Injected %0d new ETH1 packets! (Total: %0d)", new_eth_pkts, current_eth1_cnt), UVM_LOW)
            end else begin
                req.rx_eth_valid_bytes_eth1 = current_eth1_cnt;
            end

            finish_item(req);
        end
        `uvm_info("KRD_SEQ", "Network Injection Complete.", UVM_LOW)
    endtask
endclass
`endif*/

`ifndef KRD_SEQUENCE_SV
`define KRD_SEQUENCE_SV

class krd_sequence extends uvm_sequence #(krd_item);
    `uvm_object_utils(krd_sequence)

    int current_uart1_cnt = 0, current_eth1_cnt  = 0;

    function new(string name = "krd_sequence"); super.new(name); endfunction

    task body();
        req = krd_item::type_id::create("req");
        start_item(req);
        req.rx_fifo_data_out_uart1 = 0; req.rx_fifo_data_out_eth1 = 0; 
        req.rx_valid_byte_count_uart1 = 0; req.rx_eth_valid_bytes_eth1 = 0;
        finish_item(req);

        forever begin
            #( $urandom_range(200, 500) * 1ns ); 

            // THE FIX: Loop per packet injected to ensure distinct random data for EACH
            if ($urandom_range(0, 10) > 3) begin 
                int pkts = $urandom_range(1, 3);
                for(int i = 0; i < pkts; i++) begin
                    req = krd_item::type_id::create("req");
                    start_item(req);
                    current_uart1_cnt++;
                    req.rx_valid_byte_count_uart1 = current_uart1_cnt;
                    req.rx_eth_valid_bytes_eth1   = current_eth1_cnt; // Hold ETH state
                    req.rx_fifo_data_out_uart1    = $urandom; 
                    finish_item(req);
                end
            end 

            if ($urandom_range(0, 10) > 2) begin 
                int pkts = $urandom_range(2, 5);
                for(int i = 0; i < pkts; i++) begin
                    req = krd_item::type_id::create("req");
                    start_item(req);
                    current_eth1_cnt++;
                    req.rx_valid_byte_count_uart1 = current_uart1_cnt; // Hold UART state
                    req.rx_eth_valid_bytes_eth1   = current_eth1_cnt;
                    req.rx_fifo_data_out_eth1     = $urandom;
                    finish_item(req);
                end
            end 

        end
    endtask
endclass
`endif