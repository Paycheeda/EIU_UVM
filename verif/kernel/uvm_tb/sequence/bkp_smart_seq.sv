`ifndef BKP_SMART_SEQ_SV
`define BKP_SMART_SEQ_SV

class bkp_smart_seq extends uvm_sequence #(bkp_item);
    `uvm_object_utils(bkp_smart_seq)

    // Maintain tracking counts for all 7 modules
    int prev_uart1_cnt = 0, prev_uart2_cnt = 0, prev_uart3_cnt = 0;
    int prev_eth1_cnt  = 0, prev_eth2_cnt  = 0, prev_eth3_cnt  = 0, prev_eth4_cnt  = 0;

    function new(string name = "bkp_smart_seq"); super.new(name); endfunction

    task body();
        `uvm_info("SMART_SEQ", ">>> WAKING UP: CPU Backplane Polling Routine Started...", UVM_LOW)

        poll_and_read(1, 0, prev_uart1_cnt, "UART1");
        // poll_and_read(4, 3, prev_uart2_cnt, "UART2");
        // poll_and_read(7, 6, prev_uart3_cnt, "UART3");

        poll_and_read(10, 9, prev_eth1_cnt, "ETH1");
        // poll_and_read(13, 12, prev_eth2_cnt, "ETH2");
        // poll_and_read(16, 15, prev_eth3_cnt, "ETH3");
        // poll_and_read(19, 18, prev_eth4_cnt, "ETH4");
        
        `uvm_info("SMART_SEQ", "<<< SLEEPING: Polling Routine Complete.\n", UVM_LOW)
    endtask

    task poll_and_read(input int count_addr, input int fifo_addr, ref int prev_cnt, input string name);
        bkp_item rsp_item;
        int current_cnt, new_packets;

        // 1. Read the Count Register
        req = bkp_item::type_id::create("req");
        start_item(req);
        req.bkp_card_id  = 4'hA; // <--- THE FIX: Unlock the hardware!
        req.fpga_card_id = 4'hA; // <--- THE FIX: Unlock the hardware!
        req.bkp_data_dir = 0;    // Read
        req.bkp_address  = count_addr;
        finish_item(req);
        
        get_response(rsp_item); 
        
        current_cnt = rsp_item.bkp_data[10:0];
        new_packets = current_cnt - prev_cnt;

        `uvm_info("SMART_SEQ", $sformatf("[POLL] %s (Addr %0d) -> Prev: %0d | Curr: %0d", name, count_addr, prev_cnt, current_cnt), UVM_LOW)

        if (new_packets > 0) begin
            `uvm_info("SMART_SEQ", $sformatf("       *** %0d NEW PACKETS DETECTED ON %s! Initiating Burst Read at Addr %0d ***", new_packets, name, fifo_addr), UVM_LOW)
            
            // 2. Loop and physically pull the exact number of new packets!
            for (int i = 0; i < new_packets; i++) begin
                req = bkp_item::type_id::create("req");
                start_item(req);
                req.bkp_card_id  = 4'hA; // <--- THE FIX
                req.fpga_card_id = 4'hA; // <--- THE FIX
                req.bkp_data_dir = 0;
                req.bkp_address  = fifo_addr;
                finish_item(req);
                
                get_response(rsp_item); 
                `uvm_info("SMART_SEQ", $sformatf("       -> %s Burst [%0d/%0d] Data Extracted: 'h%0h", name, i+1, new_packets, rsp_item.bkp_data), UVM_LOW)
            end
            
            prev_cnt = current_cnt;
            `uvm_info("SMART_SEQ", $sformatf("       *** %s BURST COMPLETE. State updated. ***", name), UVM_LOW)
        end 
    endtask
endclass
`endif