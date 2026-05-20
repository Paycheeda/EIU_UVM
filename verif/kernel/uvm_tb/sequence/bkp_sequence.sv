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
                else if (addr >= 6'd3 && addr <= 6'd9) begin
                    // Standard Config Values for ETH1
                    bit [47:0] eth1_dest_mac = 48'hFF_FF_FF_FF_FF_FF; // Broadcast
                    bit [47:0] eth1_src_mac  = 48'h02_00_00_00_00_01; // Private MAC
                    bit [31:0] eth1_dest_ip  = 32'hC0A8_0164;         // 192.168.1.100
                    bit [31:0] eth1_src_ip   = 32'hC0A8_010A;         // 192.168.1.10
                    bit [15:0] eth1_dest_port= 16'h0FA0;              // 4000
                    bit [15:0] eth1_src_port = 16'h1388;              // 5000
                    bit [11:0] eth1_payload_len = 12'd100;            // 100 bytes

                    case (addr)
                        6'd3: begin // Dest MAC (4 Writes x 12 bits = 48 bits)
                            if (w == 0)      data_to_send = (eth1_dest_mac >> 36) & 12'hFFF;
                            else if (w == 1) data_to_send = (eth1_dest_mac >> 24) & 12'hFFF;
                            else if (w == 2) data_to_send = (eth1_dest_mac >> 12) & 12'hFFF;
                            else if (w == 3) data_to_send = (eth1_dest_mac)       & 12'hFFF;
                        end
                        6'd4: begin // Src MAC (4 Writes x 12 bits = 48 bits)
                            if (w == 0)      data_to_send = (eth1_src_mac >> 36) & 12'hFFF;
                            else if (w == 1) data_to_send = (eth1_src_mac >> 24) & 12'hFFF;
                            else if (w == 2) data_to_send = (eth1_src_mac >> 12) & 12'hFFF;
                            else if (w == 3) data_to_send = (eth1_src_mac)       & 12'hFFF;
                        end
                        6'd5: begin // Dest IP (4 Writes, Top 16 bits padded 0)
                            if (w == 0)      data_to_send = 12'h000;
                            else if (w == 1) data_to_send = (eth1_dest_ip >> 24) & 12'hFFF;
                            else if (w == 2) data_to_send = (eth1_dest_ip >> 12) & 12'hFFF;
                            else if (w == 3) data_to_send = (eth1_dest_ip)       & 12'hFFF;
                        end
                        6'd6: begin // Src IP (4 Writes, Top 16 bits padded 0)
                            if (w == 0)      data_to_send = 12'h000;
                            else if (w == 1) data_to_send = (eth1_src_ip >> 24) & 12'hFFF;
                            else if (w == 2) data_to_send = (eth1_src_ip >> 12) & 12'hFFF;
                            else if (w == 3) data_to_send = (eth1_src_ip)       & 12'hFFF;
                        end
                        6'd7: begin // Dest Port (2 Writes x 12 bits)
                            if (w == 0)      data_to_send = (eth1_dest_port >> 12) & 12'hFFF;
                            else if (w == 1) data_to_send = (eth1_dest_port)       & 12'hFFF;
                        end
                        6'd8: begin // Src Port (2 Writes x 12 bits)
                            if (w == 0)      data_to_send = (eth1_src_port >> 12) & 12'hFFF;
                            else if (w == 1) data_to_send = (eth1_src_port)       & 12'hFFF;
                        end
                        6'd9: begin // Payload Length (1 Write)
                            data_to_send = eth1_payload_len;
                        end
                    endcase
                end
                
                // ----------------------------------------------------
                // STEP 3: Dummy Writes for all other ETH ports to satisfy global lockout
                // ----------------------------------------------------
                else begin
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