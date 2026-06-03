`ifndef KWR_SEQUENCE_SV
`define KWR_SEQUENCE_SV

class kwr_routing_seq extends uvm_sequence #(bkp_item);
    `uvm_object_utils(kwr_routing_seq)

    bit [3:0] test_card_id = 4'h0; 
    int num_packets = 5; 
    
    // Enable Flags
    int en_uart[3] = '{0, 0, 0};
    int en_eth[4]  = '{0, 0, 0, 0};

    function new(string name = "kwr_routing_seq");
        super.new(name);
    endfunction
   
    task body();
        bit [8:0] rand_uart_payload; 
        bit [7:0] rand_eth_payload;
        int req_width = 8;
        int eth_payload_len = 100;
        
        // Fetch Plusargs
        $value$plusargs("NUM_PKTS=%d", num_packets);
        $value$plusargs("UART_WIDTH=%d", req_width);
        $value$plusargs("ETH_PLEN=%d", eth_payload_len);
        if (eth_payload_len < 0) eth_payload_len = 0;
        if (eth_payload_len > 2047) begin
            `uvm_warning("SEQ", $sformatf("ETH_PLEN=%0d is larger than the 11-bit RTL field; clamping to 2047", eth_payload_len))
            eth_payload_len = 2047;
        end
        
        $value$plusargs("EN_UART1=%d", en_uart[0]);
        $value$plusargs("EN_UART2=%d", en_uart[1]);
        $value$plusargs("EN_UART3=%d", en_uart[2]);

        $value$plusargs("EN_ETH1=%d", en_eth[0]);
        $value$plusargs("EN_ETH2=%d", en_eth[1]);
        $value$plusargs("EN_ETH3=%d", en_eth[2]);
        $value$plusargs("EN_ETH4=%d", en_eth[3]);
        
        `uvm_info("SEQ", $sformatf("Starting BACK-TO-BACK Burst Test with RANDOM Data: %0d packet(s), %0d ETH byte(s) per enabled FIFO...", num_packets, eth_payload_len), UVM_LOW)

        for (int p = 1; p <= num_packets; p++) begin
            
            // ==========================================
            // 1. Blast UARTs with Random Data
            // ==========================================
            for (int addr = 41; addr <= 43; addr++) begin
                if (addr == 41 && !en_uart[0]) continue;
                if (addr == 42 && !en_uart[1]) continue;
                if (addr == 43 && !en_uart[2]) continue;

                rand_uart_payload = $urandom_range(0, (1 << req_width) - 1); 
                
                // WRITE COMMAND
                req = bkp_item::type_id::create("req");
                start_item(req);
                req.trans_type   = BKP_DATA_WRITE; 
                req.bkp_address  = addr;
                req.bkp_card_id  = test_card_id;
                req.fpga_card_id = test_card_id;
                req.bkp_data_dir = 1'b1; 
                
                if (req_width == 9) begin
                    req.bkp_data = {2'b00, 1'b0, rand_uart_payload[8:0]}; 
                end else begin
                    req.bkp_data = {3'b000, 1'b0, rand_uart_payload[7:0]}; 
                end
                
                req.delay_cycles = 0;
                finish_item(req);

                #1us; 

                // SEND COMMAND (For UART, it's bit 8 or 9 of the data address)
                req = bkp_item::type_id::create("req");
                start_item(req);
                req.trans_type   = BKP_DATA_WRITE; 
                req.bkp_address  = addr;
                req.bkp_card_id  = test_card_id;
                req.fpga_card_id = test_card_id;
                req.bkp_data_dir = 1'b1;
                
                if (req_width == 9) begin
                    req.bkp_data = {2'b00, 1'b1, 9'h000}; 
                end else begin
                    req.bkp_data = {3'b001, 1'b0, 8'h00}; 
                end
                
                req.delay_cycles = 0;
                finish_item(req);
            end

            // ==========================================
            // 2. Blast ETHERNETs with Random Data
            // ==========================================
            for (int eth_idx = 0; eth_idx < 4; eth_idx++) begin
                int data_addr = 44 + eth_idx; // 44, 45, 46, 47
                
                if (!en_eth[eth_idx]) continue;

                // Push Payload Bytes into the FIFO.  Keep this aligned with the
                // ETH_PLEN value programmed into kernel_config by bkp_sequence.
                for (int byte_idx = 0; byte_idx < eth_payload_len; byte_idx++) begin
                    rand_eth_payload = $urandom_range(0, 255); 
                    
                    req = bkp_item::type_id::create("req");
                    start_item(req);
                    req.trans_type   = BKP_DATA_WRITE; 
                    req.bkp_address  = data_addr;
                    req.bkp_card_id  = test_card_id;
                    req.fpga_card_id = test_card_id;
                    req.bkp_data_dir = 1'b1; 
                    
                    req.bkp_data     = {4'b0000, rand_eth_payload}; 
                    req.delay_cycles = 0;
                    finish_item(req);
                end

                // ---> FIX 1: Let the 100 bytes cross the CDC into the FIFO <---
                #5us; 

                // ---> FIX 2: Send Command to data_addr (Addr 44) <---
                req = bkp_item::type_id::create("req");
                start_item(req);
                req.trans_type   = BKP_DATA_WRITE; 
                req.bkp_address  = data_addr; 
                req.bkp_card_id  = test_card_id;
                req.fpga_card_id = test_card_id;
                req.bkp_data_dir = 1'b1;
                req.bkp_data     = 12'h100; // Bit 8 = 1 (Triggers the TX)
                req.delay_cycles = 0;
                finish_item(req);

                // Do NOT write 12'h000 here.  On ETH data addresses bit[8]=0 is
                // payload data, not a control clear, so that write inserts an
                // extra 0x00 into the TX FIFO.  The next frame then starts with
                // that stale zero and every following byte is shifted by one.
                #1us;
            end

            #10us; 
        end
        
        `uvm_info("SEQ", "Random Burst Sequence Complete! Pipeline flushing...", UVM_LOW)
    endtask
endclass

`endif