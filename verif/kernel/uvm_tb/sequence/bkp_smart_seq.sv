////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : bkp_smart_seq.sv
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
//  UVM sequence for Kernel BKP smart verification
////////////////////////////////////////////////////////////////////////////////

`ifndef BKP_SMART_SEQ_SV
`define BKP_SMART_SEQ_SV

class bkp_smart_seq extends uvm_sequence #(bkp_item);
    `uvm_object_utils(bkp_smart_seq)

    bit [3:0] target_card_id;

    int wait_for_uart[3] = '{0, 0, 0};
    int wait_for_eth[4]  = '{0, 0, 0, 0};
    int poll_timeout_us  = 2000;
    int poll_interval_us = 5;
    int total_bytes_read = 0;
    bit timed_out = 0;

    function new(string name = "bkp_smart_seq"); 
        super.new(name); 
        target_card_id = 4'h0;
    endfunction

    task body();
        // `uvm_info("SMART_SEQ", ">>> WAKING UP: CPU Backplane Polling Routine Started...", UVM_LOW)

        $value$plusargs("RX_POLL_TIMEOUT_US=%d", poll_timeout_us);
        $value$plusargs("RX_POLL_INTERVAL_US=%d", poll_interval_us);
        if (poll_timeout_us < 1) poll_timeout_us = 1;
        if (poll_interval_us < 1) poll_interval_us = 1;

        total_bytes_read = 0;
        timed_out = 0;

        // Poll UARTs
        poll_and_read(6'd1, 6'd0, "UART1", wait_for_uart[0]);
        poll_and_read(6'd4, 6'd3, "UART2", wait_for_uart[1]);
        poll_and_read(6'd7, 6'd6, "UART3", wait_for_uart[2]);
        
        // Poll ALL Ethernet Ports
        poll_and_read(6'd10, 6'd9,  "ETH1", wait_for_eth[0]);
        poll_and_read(6'd13, 6'd12, "ETH2", wait_for_eth[1]);
        poll_and_read(6'd16, 6'd15, "ETH3", wait_for_eth[2]);
        poll_and_read(6'd19, 6'd18, "ETH4", wait_for_eth[3]);

        // `uvm_info("SMART_SEQ", "<<< SLEEPING: Polling Routine Complete.\n", UVM_LOW)
    endtask

    task read_count(input bit [5:0] count_addr, output int curr_cnt);
        bkp_item req_item;

        req_item = bkp_item::type_id::create("req_item");
        start_item(req_item);
        req_item.trans_type = BKP_READ;
        req_item.bkp_address = count_addr;
        req_item.bkp_data = 12'h000;
        req_item.delay_cycles = 0;
        req_item.bkp_card_id = target_card_id;
        req_item.fpga_card_id = target_card_id;
        req_item.apply_trans_type_rules();
        finish_item(req_item);

        curr_cnt = req_item.bkp_data;
    endtask

    task poll_and_read(input bit [5:0] count_addr, input bit [5:0] data_addr, input string intf_name, input int wait_for_data = 0);
        int curr_cnt;
        time deadline;
        bkp_item req_item;

        deadline = $time + (poll_timeout_us * 1us);

        forever begin
            read_count(count_addr, curr_cnt);

            // The updated kernel_read reports ETH RX bytes as "bytes still unread"
            // (valid_eth_frame - internal_read_count).  After the last byte is read,
            // the RTL only clears its internal ETH read counter when the count address
            // is polled again and returns zero.  Without this post-drain poll, the next
            // ETH packet can be compared against the previous packet's read counter,
            // causing underflow/large byte counts and scoreboard mismatches.
            if (curr_cnt > 0 && curr_cnt <= 2048) begin
            `uvm_info("SMART_SEQ", $sformatf("\t*** %0d BYTES WAITING ON %s! Initiating Burst Read ***", curr_cnt, intf_name), UVM_LOW)
            total_bytes_read += curr_cnt;

            for (int i = 0; i < curr_cnt; i++) begin
                req_item = bkp_item::type_id::create("req_item");
                start_item(req_item);
                req_item.trans_type = BKP_READ;
                req_item.bkp_address = data_addr;
                req_item.bkp_data = 12'h000;
                req_item.delay_cycles = 0;
                req_item.bkp_card_id = target_card_id;
                req_item.fpga_card_id = target_card_id;
                req_item.apply_trans_type_rules();
                finish_item(req_item);

                // Keep this UVM_HIGH so it doesn't flood the terminal
                `uvm_info("SMART_SEQ", $sformatf("\t\t-> %s Burst [%0d/%0d] Data Extracted: 'h%0h", intf_name, i+1, curr_cnt, req_item.bkp_data), UVM_HIGH)
            end

            // Post-drain zero-count poll.  This read is intentionally not used by
            // the scoreboard; it exists to let the new kernel_read clear its ETH
            // RX byte-count bookkeeping before the next packet arrives.
            req_item = bkp_item::type_id::create("req_item_clear_count");
            start_item(req_item);
            req_item.trans_type = BKP_READ;
            req_item.bkp_address = count_addr;
            req_item.bkp_data = 12'h000;
            req_item.delay_cycles = 0;
            req_item.bkp_card_id = target_card_id;
            req_item.fpga_card_id = target_card_id;
            req_item.apply_trans_type_rules();
            finish_item(req_item);

            if (req_item.bkp_data != 12'd0) begin
                `uvm_warning("SMART_SEQ", $sformatf("%s post-drain count poll returned %0d instead of 0", intf_name, req_item.bkp_data))
            end
                return;
            end
            else if (curr_cnt > 2048) begin
                `uvm_warning("SMART_SEQ", $sformatf("Ignoring impossible %s RX byte count %0d. This usually means the previous ETH drain did not clear the new kernel_read counter.", intf_name, curr_cnt))
                return;
            end

            if (!wait_for_data) begin
                return;
            end

            if ($time >= deadline) begin
                timed_out = 1'b1;
                `uvm_error("SMART_SEQ_TIMEOUT", $sformatf("Timed out after %0d us waiting for %s RX count to become non-zero", poll_timeout_us, intf_name))
                return;
            end

            #(poll_interval_us * 1us);
        end
    endtask
endclass

`endif