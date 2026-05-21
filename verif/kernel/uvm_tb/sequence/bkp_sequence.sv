`ifndef BKP_SEQUENCE_SV
`define BKP_SEQUENCE_SV

class bkp_sequence extends uvm_sequence #(bkp_item);
    `uvm_object_utils(bkp_sequence)

    bit [3:0] target_card_id;

    function new(string name = "bkp_sequence");
        super.new(name);
        target_card_id = 4'h0; // Default to 0 based on your TB setup
    endfunction

    // Helper function to determine the number of required writes per address based on RTL
    function int get_required_writes(int addr);
        int eth_field;
        if (addr <= 2) begin
            return 4; // UART1, UART2, UART3 baudrate/control
        end else if (addr <= 37) begin
            eth_field = (addr - 3) % 7;
            case (eth_field)
                0, 1, 2, 3: return 4; // MACs and IPs
                4, 5:       return 2; // Ports
                6:          return 1; // Payload Length
            endcase
        end else if (addr <= 40) begin
            return 1; // NRZ specific configs
        end
        return 0;
    endfunction

    task body();
        bkp_item req_item;
        int req_wr;
        int data_to_send;
        
        // Dynamic Parameters (Defaults)
        int req_baud = 115200;
        int req_width_val = 8;
        int req_width_rtl = 8;     // Now defaults to the raw integer 8
        int req_parity_en = 0; 
        int req_odd_even = 0;  
        
        int baud_div, ctrl_bits, b0, b1, b2, b3;

        int        nrz_bpw_bits      = 8;
        bit        nrz_zero_endian   = 0;
        bit [11:0] nrz_sync_word1    = 12'h0EB;
        bit [11:0] nrz_sync_word2    = 12'h090;
        int        nrz_payload_len   = 50;

        `uvm_info("BKP_SEQ", ">>> Starting FULL Hardware Initialization Sequence...", UVM_LOW)
        
        // Fetch terminal Plusargs!
        $value$plusargs("UART_BAUD=%d", req_baud);
        $value$plusargs("UART_WIDTH=%d", req_width_val); 
        $value$plusargs("UART_PARITY_EN=%d", req_parity_en);
        $value$plusargs("UART_PARITY_OE=%d", req_odd_even);
        
        // ---> FIXED: The RTL directly accepts the width integer! (8 = 8-bit, 9 = 9-bit) <---
        req_width_rtl = req_width_val; 
        
        // 44.2368MHz Clock Divisor Math
        baud_div = 44236800 / req_baud; 
        
        b0 = (baud_div >> 24) & 12'hFFF;
        b1 = (baud_div >> 16) & 12'hFFF;
        b2 = (baud_div >> 8)  & 12'hFFF;
        
        // Pack Control Bits using the mapped RTL width!
        ctrl_bits = (req_width_rtl << 10) | (req_odd_even << 9) | (req_parity_en << 8);
        b3 = ctrl_bits | (baud_div & 8'hFF);

        // Loop through ALL 41 Configuration Addresses to satisfy the global lockout
        // Loop through ALL 41 Configuration Addresses to satisfy the global lockout
        for (int addr = 0; addr <= 40; addr++) begin
            req_wr = get_required_writes(addr); 
            
            for (int w = 0; w < req_wr; w++) begin
                req_item = bkp_item::type_id::create("req_item");
                start_item(req_item);
                req_item.randomize_item();
                req_item.trans_type   = BKP_CFG_WRITE;
                req_item.bkp_address  = addr; 
                
                // ----------------------------------------------------
                // UART CONFIGURATION (Addresses 0-2)
                // ----------------------------------------------------
                if (addr >= 6'd0 && addr <= 6'd2) begin
                    if (w == 0)      data_to_send = b0;
                    else if (w == 1) data_to_send = b1;
                    else if (w == 2) data_to_send = b2;
                    else if (w == 3) data_to_send = b3; // The magic packed byte
                end 
                
                // ----------------------------------------------------
                // ETHERNET 1 CONFIGURATION (Addresses 3-9)
                // ----------------------------------------------------
                else if (addr >= 6'd3 && addr <= 6'd30) begin
                        int eth_idx;
                        int eth_field;
                        bit [47:0] eth_dest_mac;
                        bit [47:0] eth_src_mac;
                        bit [31:0] eth_dest_ip;
                        bit [31:0] eth_src_ip;
                        bit [15:0] eth_dest_port;
                        bit [15:0] eth_src_port;
                        bit [10:0] eth_payload_len;
                        eth_idx   = (addr - 3) / 7; // 0=ETH1, 1=ETH2, 2=ETH3, 3=ETH4
                        eth_field = (addr - 3) % 7;
                        eth_dest_mac    = 48'hFF_FF_FF_FF_FF_FF;
                        eth_src_mac     = 48'h02_00_00_00_00_01 + eth_idx;
                        eth_dest_ip     = 32'hC0A8_0164 + eth_idx; // 192.168.1.100+
                        eth_src_ip      = 32'hC0A8_010A + eth_idx; // 192.168.1.10+
                        eth_dest_port   = 16'h0FA0 + eth_idx;
                        eth_src_port    = 16'h1388 + eth_idx;
                        eth_payload_len = 11'd100;
                        case (eth_field)
                            0: begin // Dest MAC
                                if (w == 0)      data_to_send = (eth_dest_mac >> 36) & 12'hFFF;
                                else if (w == 1) data_to_send = (eth_dest_mac >> 24) & 12'hFFF;
                                else if (w == 2) data_to_send = (eth_dest_mac >> 12) & 12'hFFF;
                                else             data_to_send = eth_dest_mac & 12'hFFF;
                            end
                            1: begin // Source MAC
                                if (w == 0)      data_to_send = (eth_src_mac >> 36) & 12'hFFF;
                                else if (w == 1) data_to_send = (eth_src_mac >> 24) & 12'hFFF;
                                else if (w == 2) data_to_send = (eth_src_mac >> 12) & 12'hFFF;
                                else             data_to_send = eth_src_mac & 12'hFFF;
                            end
                            2: begin // Source IP
                                if (w == 0)      data_to_send = 12'h000;
                                else if (w == 1) data_to_send = (eth_src_ip >> 24) & 12'hFFF;
                                else if (w == 2) data_to_send = (eth_src_ip >> 12) & 12'hFFF;
                                else             data_to_send = eth_src_ip & 12'hFFF;
                            end
                            3: begin // Dest IP
                                if (w == 0)      data_to_send = 12'h000;
                                else if (w == 1) data_to_send = (eth_dest_ip >> 24) & 12'hFFF;
                                else if (w == 2) data_to_send = (eth_dest_ip >> 12) & 12'hFFF;
                                else             data_to_send = eth_dest_ip & 12'hFFF;
                            end
                            4: begin // Source Port
                                if (w == 0)      data_to_send = (eth_src_port >> 12) & 12'hFFF;
                                else             data_to_send = eth_src_port & 12'hFFF;
                            end
                            5: begin // Dest Port
                                if (w == 0)      data_to_send = (eth_dest_port >> 12) & 12'hFFF;
                                else             data_to_send = eth_dest_port & 12'hFFF;
                            end
                            6: begin // Payload Length
                                data_to_send = eth_payload_len;
                            end
                        endcase
                    end
                    else begin
                        // Keep dummy writes for unused ETH5/NRZ config and NRZ-specific config
                        // so all_config_received still becomes true.
                        data_to_send = 12'h000;
                end
                
                // Apply the calculated data and standard routing variables
                req_item.bkp_data     = data_to_send; 
                req_item.bkp_card_id  = target_card_id;
                req_item.fpga_card_id = target_card_id;
                
                req_item.apply_trans_type_rules();
                finish_item(req_item);
            end
        end

        `uvm_info("BKP_SEQ", "<<< FULL Hardware Initialization Sequence Complete.", UVM_LOW)
    endtask
endclass

`endif