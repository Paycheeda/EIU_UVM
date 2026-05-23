`ifndef BKP_SEQUENCE_SV
`define BKP_SEQUENCE_SV

class bkp_sequence extends uvm_sequence #(bkp_item);
    `uvm_object_utils(bkp_sequence)

    bit [3:0] target_card_id;
    
    // --- NRZ Specific Configuration Variables ---
    bit [1:0]  nrz_bpw_code      = 2'd0;    // 0=8bit, 1=9bit, 2=10bit, 3=12bit
    bit        nrz_zero_endian   = 1'b0;
    bit [11:0] nrz_sync_word1    = 12'h0EB;
    bit [11:0] nrz_sync_word2    = 12'h090;
    int        nrz_payload_len   = 50;

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
        int req_width_rtl = 8;     
        int req_parity_en = 0; 
        int req_odd_even = 0;  
        
        int baud_div, ctrl_bits, b0, b1, b2, b3;

        `uvm_info("BKP_SEQ", ">>> Starting FULL Hardware Initialization Sequence...", UVM_LOW)
        
        // Fetch terminal Plusargs!
        $value$plusargs("UART_BAUD=%d", req_baud);
        $value$plusargs("UART_WIDTH=%d", req_width_val); 
        $value$plusargs("UART_PARITY_EN=%d", req_parity_en);
        $value$plusargs("UART_PARITY_OE=%d", req_odd_even);
        
        req_width_rtl = req_width_val; 
        
        // 44.2368MHz Clock Divisor Math
        baud_div = 44236800 / req_baud; 
        
        b0 = (baud_div >> 24) & 12'hFFF;
        b1 = (baud_div >> 16) & 12'hFFF;
        b2 = (baud_div >> 8)  & 12'hFFF;
        
        ctrl_bits = (req_width_rtl << 10) | (req_odd_even << 9) | (req_parity_en << 8);
        b3 = ctrl_bits | (baud_div & 8'hFF);

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
                    else if (w == 3) data_to_send = b3;
                end 
                
                // ----------------------------------------------------
                // ETHERNET 1 CONFIGURATION (Addresses 3-9)
                // ----------------------------------------------------
                else if (addr >= 6'd3 && addr <= 6'd9) begin
                    bit [47:0] eth1_dest_mac = 48'hFF_FF_FF_FF_FF_FF;
                    bit [47:0] eth1_src_mac  = 48'h02_00_00_00_00_01; 
                    bit [31:0] eth1_dest_ip  = 32'hC0A8_0164;         
                    bit [31:0] eth1_src_ip   = 32'hC0A8_010A;         
                    bit [15:0] eth1_dest_port= 16'h0FA0;              
                    bit [15:0] eth1_src_port = 16'h1388;              
                    bit [11:0] eth1_payload_len = 12'd100;            

                    case (addr)
                        6'd3: begin // Dest MAC
                            if (w == 0)      data_to_send = (eth1_dest_mac >> 36) & 12'hFFF;
                            else if (w == 1) data_to_send = (eth1_dest_mac >> 24) & 12'hFFF;
                            else if (w == 2) data_to_send = (eth1_dest_mac >> 12) & 12'hFFF;
                            else if (w == 3) data_to_send = (eth1_dest_mac)       & 12'hFFF;
                        end
                        6'd4: begin // Src MAC
                            if (w == 0)      data_to_send = (eth1_src_mac >> 36) & 12'hFFF;
                            else if (w == 1) data_to_send = (eth1_src_mac >> 24) & 12'hFFF;
                            else if (w == 2) data_to_send = (eth1_src_mac >> 12) & 12'hFFF;
                            else if (w == 3) data_to_send = (eth1_src_mac)       & 12'hFFF;
                        end
                        6'd5: begin // Dest IP
                            if (w == 0)      data_to_send = 12'h000;
                            else if (w == 1) data_to_send = (eth1_dest_ip >> 24) & 12'hFFF;
                            else if (w == 2) data_to_send = (eth1_dest_ip >> 12) & 12'hFFF;
                            else if (w == 3) data_to_send = (eth1_dest_ip)       & 12'hFFF;
                        end
                        6'd6: begin // Src IP
                            if (w == 0)      data_to_send = 12'h000;
                            else if (w == 1) data_to_send = (eth1_src_ip >> 24) & 12'hFFF;
                            else if (w == 2) data_to_send = (eth1_src_ip >> 12) & 12'hFFF;
                            else if (w == 3) data_to_send = (eth1_src_ip)       & 12'hFFF;
                        end
                        6'd7: begin // Dest Port 
                            if (w == 0)      data_to_send = (eth1_dest_port >> 12) & 12'hFFF;
                            else if (w == 1) data_to_send = (eth1_dest_port)       & 12'hFFF;
                        end
                        6'd8: begin // Src Port 
                            if (w == 0)      data_to_send = (eth1_src_port >> 12) & 12'hFFF;
                            else if (w == 1) data_to_send = (eth1_src_port)       & 12'hFFF;
                        end
                        6'd9: begin // Payload Length
                            data_to_send = eth1_payload_len;
                        end
                    endcase
                end
                
                // ----------------------------------------------------
                // ETHERNET 5 / NRZ CONFIGURATION (Addresses 31-40)
                // ----------------------------------------------------
                else if (addr >= 6'd31 && addr <= 6'd40) begin
                    case (addr)
                        31, 32, 33, 34, 35, 36: begin
                            // Dummy standard network configs for ETH5
                            data_to_send = 12'h000;
                        end
                        6'd37: begin // Frame Length & Endianness
                            data_to_send = {nrz_zero_endian, nrz_payload_len[10:0]};
                        end
                        6'd38: begin // BPW Code
                            data_to_send = {10'h000, nrz_bpw_code};
                        end
                        6'd39: begin // Sync Word 1
                            data_to_send = nrz_sync_word1;
                        end
                        6'd40: begin // Sync Word 2
                            data_to_send = nrz_sync_word2;
                        end
                        default: data_to_send = 12'h000;
                    endcase
                end
                
                // ----------------------------------------------------
                // ETHERNET 2 CONFIGURATION (Addresses 10-16)
                // ----------------------------------------------------
                else if (addr >= 6'd10 && addr <= 6'd16) begin
                    bit [47:0] eth2_dest_mac    = 48'hFF_FF_FF_FF_FF_FF;
                    bit [47:0] eth2_src_mac     = 48'h02_00_00_00_00_02;
                    bit [31:0] eth2_dest_ip     = 32'hC0A8_0264;
                    bit [31:0] eth2_src_ip      = 32'hC0A8_020A;
                    bit [15:0] eth2_dest_port   = 16'h0FA1;
                    bit [15:0] eth2_src_port    = 16'h1389;
                    bit [11:0] eth2_payload_len = 12'd100;

                    case (addr)
                        6'd10: begin
                            if (w == 0)      data_to_send = (eth2_dest_mac >> 36) & 12'hFFF;
                            else if (w == 1) data_to_send = (eth2_dest_mac >> 24) & 12'hFFF;
                            else if (w == 2) data_to_send = (eth2_dest_mac >> 12) & 12'hFFF;
                            else if (w == 3) data_to_send = (eth2_dest_mac)       & 12'hFFF;
                        end
                        6'd11: begin
                            if (w == 0)      data_to_send = (eth2_src_mac >> 36) & 12'hFFF;
                            else if (w == 1) data_to_send = (eth2_src_mac >> 24) & 12'hFFF;
                            else if (w == 2) data_to_send = (eth2_src_mac >> 12) & 12'hFFF;
                            else if (w == 3) data_to_send = (eth2_src_mac)       & 12'hFFF;
                        end
                        6'd12: begin
                            if (w == 0)      data_to_send = 12'h000;
                            else if (w == 1) data_to_send = (eth2_dest_ip >> 24) & 12'hFFF;
                            else if (w == 2) data_to_send = (eth2_dest_ip >> 12) & 12'hFFF;
                            else if (w == 3) data_to_send = (eth2_dest_ip)       & 12'hFFF;
                        end
                        6'd13: begin
                            if (w == 0)      data_to_send = 12'h000;
                            else if (w == 1) data_to_send = (eth2_src_ip >> 24) & 12'hFFF;
                            else if (w == 2) data_to_send = (eth2_src_ip >> 12) & 12'hFFF;
                            else if (w == 3) data_to_send = (eth2_src_ip)       & 12'hFFF;
                        end
                        6'd14: begin
                            if (w == 0)      data_to_send = (eth2_dest_port >> 12) & 12'hFFF;
                            else if (w == 1) data_to_send = (eth2_dest_port)       & 12'hFFF;
                        end
                        6'd15: begin
                            if (w == 0)      data_to_send = (eth2_src_port >> 12) & 12'hFFF;
                            else if (w == 1) data_to_send = (eth2_src_port)       & 12'hFFF;
                        end
                        6'd16: data_to_send = eth2_payload_len;
                    endcase
                end

                // ----------------------------------------------------
                // ETHERNET 3 CONFIGURATION (Addresses 17-23)
                // ----------------------------------------------------
                else if (addr >= 6'd17 && addr <= 6'd23) begin
                    bit [47:0] eth3_dest_mac    = 48'hFF_FF_FF_FF_FF_FF;
                    bit [47:0] eth3_src_mac     = 48'h02_00_00_00_00_03;
                    bit [31:0] eth3_dest_ip     = 32'hC0A8_0364;
                    bit [31:0] eth3_src_ip      = 32'hC0A8_030A;
                    bit [15:0] eth3_dest_port   = 16'h0FA2;
                    bit [15:0] eth3_src_port    = 16'h138A;
                    bit [11:0] eth3_payload_len = 12'd100;

                    case (addr)
                        6'd17: begin
                            if (w == 0)      data_to_send = (eth3_dest_mac >> 36) & 12'hFFF;
                            else if (w == 1) data_to_send = (eth3_dest_mac >> 24) & 12'hFFF;
                            else if (w == 2) data_to_send = (eth3_dest_mac >> 12) & 12'hFFF;
                            else if (w == 3) data_to_send = (eth3_dest_mac)       & 12'hFFF;
                        end
                        6'd18: begin
                            if (w == 0)      data_to_send = (eth3_src_mac >> 36) & 12'hFFF;
                            else if (w == 1) data_to_send = (eth3_src_mac >> 24) & 12'hFFF;
                            else if (w == 2) data_to_send = (eth3_src_mac >> 12) & 12'hFFF;
                            else if (w == 3) data_to_send = (eth3_src_mac)       & 12'hFFF;
                        end
                        6'd19: begin
                            if (w == 0)      data_to_send = 12'h000;
                            else if (w == 1) data_to_send = (eth3_dest_ip >> 24) & 12'hFFF;
                            else if (w == 2) data_to_send = (eth3_dest_ip >> 12) & 12'hFFF;
                            else if (w == 3) data_to_send = (eth3_dest_ip)       & 12'hFFF;
                        end
                        6'd20: begin
                            if (w == 0)      data_to_send = 12'h000;
                            else if (w == 1) data_to_send = (eth3_src_ip >> 24) & 12'hFFF;
                            else if (w == 2) data_to_send = (eth3_src_ip >> 12) & 12'hFFF;
                            else if (w == 3) data_to_send = (eth3_src_ip)       & 12'hFFF;
                        end
                        6'd21: begin
                            if (w == 0)      data_to_send = (eth3_dest_port >> 12) & 12'hFFF;
                            else if (w == 1) data_to_send = (eth3_dest_port)       & 12'hFFF;
                        end
                        6'd22: begin
                            if (w == 0)      data_to_send = (eth3_src_port >> 12) & 12'hFFF;
                            else if (w == 1) data_to_send = (eth3_src_port)       & 12'hFFF;
                        end
                        6'd23: data_to_send = eth3_payload_len;
                    endcase
                end

                // ----------------------------------------------------
                // ETHERNET 4 CONFIGURATION (Addresses 24-30)
                // ----------------------------------------------------
                else if (addr >= 6'd24 && addr <= 6'd30) begin
                    bit [47:0] eth4_dest_mac    = 48'hFF_FF_FF_FF_FF_FF;
                    bit [47:0] eth4_src_mac     = 48'h02_00_00_00_00_04;
                    bit [31:0] eth4_dest_ip     = 32'hC0A8_0464;
                    bit [31:0] eth4_src_ip      = 32'hC0A8_040A;
                    bit [15:0] eth4_dest_port   = 16'h0FA3;
                    bit [15:0] eth4_src_port    = 16'h138B;
                    bit [11:0] eth4_payload_len = 12'd100;

                    case (addr)
                        6'd24: begin
                            if (w == 0)      data_to_send = (eth4_dest_mac >> 36) & 12'hFFF;
                            else if (w == 1) data_to_send = (eth4_dest_mac >> 24) & 12'hFFF;
                            else if (w == 2) data_to_send = (eth4_dest_mac >> 12) & 12'hFFF;
                            else if (w == 3) data_to_send = (eth4_dest_mac)       & 12'hFFF;
                        end
                        6'd25: begin
                            if (w == 0)      data_to_send = (eth4_src_mac >> 36) & 12'hFFF;
                            else if (w == 1) data_to_send = (eth4_src_mac >> 24) & 12'hFFF;
                            else if (w == 2) data_to_send = (eth4_src_mac >> 12) & 12'hFFF;
                            else if (w == 3) data_to_send = (eth4_src_mac)       & 12'hFFF;
                        end
                        6'd26: begin
                            if (w == 0)      data_to_send = 12'h000;
                            else if (w == 1) data_to_send = (eth4_dest_ip >> 24) & 12'hFFF;
                            else if (w == 2) data_to_send = (eth4_dest_ip >> 12) & 12'hFFF;
                            else if (w == 3) data_to_send = (eth4_dest_ip)       & 12'hFFF;
                        end
                        6'd27: begin
                            if (w == 0)      data_to_send = 12'h000;
                            else if (w == 1) data_to_send = (eth4_src_ip >> 24) & 12'hFFF;
                            else if (w == 2) data_to_send = (eth4_src_ip >> 12) & 12'hFFF;
                            else if (w == 3) data_to_send = (eth4_src_ip)       & 12'hFFF;
                        end
                        6'd28: begin
                            if (w == 0)      data_to_send = (eth4_dest_port >> 12) & 12'hFFF;
                            else if (w == 1) data_to_send = (eth4_dest_port)       & 12'hFFF;
                        end
                        6'd29: begin
                            if (w == 0)      data_to_send = (eth4_src_port >> 12) & 12'hFFF;
                            else if (w == 1) data_to_send = (eth4_src_port)       & 12'hFFF;
                        end
                        6'd30: data_to_send = eth4_payload_len;
                    endcase
                end

                else begin
                    data_to_send = 12'h000;
                end
                
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