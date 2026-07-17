////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : scoreboard.sv
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
//  UVM scoreboard for Kernel verification
////////////////////////////////////////////////////////////////////////////////

`ifndef SCOREBOARD_SV
`define SCOREBOARD_SV

class scoreboard extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)

    // FIFOs to receive transactions from the monitors
    uvm_tlm_analysis_fifo #(bkp_item) bkp_fifo;
    uvm_tlm_analysis_fifo #(out_item) out_fifo;

    // =========================================================
    // PREDICTOR MEMORY (The "Golden" Expected State)
    // =========================================================
    bit [2:0]  exp_addr_count [0:40];
    
    // UART Expected
    bit [31:0] exp_baudrate_uart [3];
    bit        exp_parity_en_uart [3];
    bit        exp_parity_odd_even_uart [3];
    bit        exp_data_width_uart [3];

    // ETH Expected (0-3 = ETH1-4, 4 = NRZ)
    bit [47:0] exp_dest_mac_eth [5];
    bit [47:0] exp_source_mac_eth [5];
    bit [31:0] exp_source_ip_eth [5];
    bit [31:0] exp_dest_ip_eth [5];
    bit [15:0] exp_source_port_eth [5];
    bit [15:0] exp_dest_port_eth [5];
    bit [10:0] exp_tx_payload_length_eth [5];

    // ETH NRZ Specific Expected
    bit        exp_tx_zero_endian_nrz;
    bit [1:0]  exp_tx_bpw_nrz;
    bit [11:0] exp_sync_word1_nrz;
    bit [11:0] exp_sync_word2_nrz;

    // String buffer for generating the final table report
    string report_table;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        bkp_fifo = new("bkp_fifo", this);
        out_fifo = new("out_fifo", this);
        
        // Initialize predictor memory
        foreach(exp_addr_count[i]) exp_addr_count[i] = 3'd0;
    endfunction

    task run_phase(uvm_phase phase);
        fork
            process_bkp_traffic();
            process_out_traffic();
        join
    endtask

    // =========================================================
    // THREAD 1: THE PREDICTOR (Simulate RTL Data Assembly)
    // =========================================================
    task process_bkp_traffic();
        bkp_item req;
        forever begin
            bkp_fifo.get(req);
            
            // RTL valid hit condition check
            if (req.bkp_card_id == req.fpga_card_id && req.bkp_data_dir && req.bkp_address <= 6'd40) begin
                
                int addr = req.bkp_address;
                int req_writes = get_required_writes(addr);
                
                // Only shift data in if we haven't hit the required write limit for this address
                if (exp_addr_count[addr] < req_writes) begin
                    exp_addr_count[addr]++;
                    
                    `uvm_info("SCB_PREDICT", $sformatf("🧩 Assembling Config Memory -> Addr: %2d | Pushed partial data: 'h%03x", addr, req.bkp_data), UVM_HIGH)
                    
                    // UART Logic
                    if (addr <= 6'd2) begin
                        int u_idx = addr[1:0];
                        exp_baudrate_uart[u_idx]        = {exp_baudrate_uart[u_idx][23:0], req.bkp_data[7:0]};
                        exp_parity_en_uart[u_idx]       = req.bkp_data[8];
                        exp_parity_odd_even_uart[u_idx] = req.bkp_data[9];
                        exp_data_width_uart[u_idx]      = req.bkp_data[10];
                    end
                    // ETH Logic
                    else if (addr <= 6'd37) begin
                        int e_idx = (addr - 3) / 7;
                        int e_fld = (addr - 3) % 7;
                        
                        case(e_fld)
                            0: exp_dest_mac_eth[e_idx]    = {exp_dest_mac_eth[e_idx][35:0], req.bkp_data[11:0]};
                            1: exp_source_mac_eth[e_idx]  = {exp_source_mac_eth[e_idx][35:0], req.bkp_data[11:0]};
                            2: exp_source_ip_eth[e_idx]   = {exp_source_ip_eth[e_idx][23:0], req.bkp_data[7:0]};
                            3: exp_dest_ip_eth[e_idx]     = {exp_dest_ip_eth[e_idx][23:0], req.bkp_data[7:0]};
                            4: exp_source_port_eth[e_idx] = {exp_source_port_eth[e_idx][7:0], req.bkp_data[7:0]};
                            5: exp_dest_port_eth[e_idx]   = {exp_dest_port_eth[e_idx][7:0], req.bkp_data[7:0]};
                            6: begin 
                                exp_tx_payload_length_eth[e_idx] = req.bkp_data[10:0];
                                if (e_idx == 4) exp_tx_zero_endian_nrz = req.bkp_data[11];
                            end
                        endcase
                    end
                    // Misc NRZ Logic
                    else begin
                        case(addr)
                            38: exp_tx_bpw_nrz     = req.bkp_data[1:0];
                            39: exp_sync_word1_nrz = req.bkp_data[11:0];
                            40: exp_sync_word2_nrz = req.bkp_data[11:0];
                        endcase
                    end
                end
            end
        end
    endtask

    // =========================================================
    // THREAD 2: THE COMPARATOR (Check DUT vs Expected)
    // =========================================================
    task process_out_traffic();
        out_item act;
        forever begin
            out_fifo.get(act);
            
            `uvm_info("SCB", "Config Done Pulse Received! Commencing Full Configuration Verification...", UVM_LOW)
            
            // Build the table header
            report_table = "\n";
            report_table = {report_table, "==================================================================================\n"};
            report_table = {report_table, "| CONFIGURATION PARAMETER         | STATUS | EXPECTED VALUE   | ACTUAL VALUE     |\n"};
            report_table = {report_table, "==================================================================================\n"};
            
            // Compare UARTs
            for(int i=0; i<3; i++) begin
                check_match($sformatf("UART%0d Baudrate", i+1), exp_baudrate_uart[i], act.baudrate_uart[i]);
                check_match($sformatf("UART%0d Parity En", i+1), exp_parity_en_uart[i], act.parity_en_uart[i]);
            end
            
            // Compare ETH 1-4 & NRZ
            for(int i=0; i<5; i++) begin
                string eth_name = (i==4) ? "ETH_NRZ" : $sformatf("ETH%0d", i+1);
                check_match({eth_name, " Dest MAC"}, exp_dest_mac_eth[i], act.dest_mac_eth[i]);
                check_match({eth_name, " Source MAC"}, exp_source_mac_eth[i], act.source_mac_eth[i]);
                check_match({eth_name, " Source IP"}, exp_source_ip_eth[i], act.source_ip_eth[i]);
                check_match({eth_name, " Dest IP"}, exp_dest_ip_eth[i], act.dest_ip_eth[i]);
                check_match({eth_name, " Source Port"}, exp_source_port_eth[i], act.source_port_eth[i]);
                check_match({eth_name, " Dest Port"}, exp_dest_port_eth[i], act.dest_port_eth[i]);
                check_match({eth_name, " Payload Length"}, exp_tx_payload_length_eth[i], act.tx_payload_length_eth[i]);
            end

            // Compare NRZ Specifics
            check_match("NRZ Zero Endian", exp_tx_zero_endian_nrz, act.tx_zero_endian_eth_nrz);
            check_match("NRZ BPW", exp_tx_bpw_nrz, act.tx_bpw_eth_nrz);
            check_match("NRZ Sync Word 1", exp_sync_word1_nrz, act.tx_sync_word1_eth_nrz);
            
            // Add the table footer and print!
            report_table = {report_table, "==================================================================================\n"};
            `uvm_info("SCB_REPORT", report_table, UVM_LOW)
            
        end
    endtask

    // =========================================================
    // HELPER FUNCTIONS
    // =========================================================
    
    // Generic compare function that appends rows to the table
    function void check_match(string name, longint exp_val, longint act_val);
        if (exp_val !== act_val) begin
            // Add FAIL row to table
            report_table = {report_table, $sformatf("| %-31s |  FAIL  | 'h%-14x | 'h%-14x |\n", name, exp_val, act_val)};
            `uvm_error("SCB_MISMATCH", $sformatf("%s mismatch! Expected: 'h%0x, Actual: 'h%0x", name, exp_val, act_val))
        end else begin
            // Add PASS row to table
            report_table = {report_table, $sformatf("| %-31s |  PASS  | 'h%-14x | 'h%-14x |\n", name, exp_val, act_val)};
        end
    endfunction

    // Exact copy of RTL logic to know how many writes per address
    function int get_required_writes(int addr);
        if (addr <= 2) return 4;
        else if (addr <= 37) begin
            int e_fld = (addr - 3) % 7;
            case(e_fld)
                0, 1, 2, 3: return 4;
                4, 5: return 2;
                6: return 1;
                default: return 0;
            endcase
        end
        else if (addr <= 40) return 1;
        return 0;
    endfunction

endclass

`endif