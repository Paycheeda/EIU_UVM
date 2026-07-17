////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : kst_scoreboard.sv
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
//  UVM scoreboard for Kernel KST verification
////////////////////////////////////////////////////////////////////////////////

`ifndef KST_SCOREBOARD_SV
`define KST_SCOREBOARD_SV

class kst_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(kst_scoreboard)

    uvm_tlm_analysis_fifo #(bkp_item) bkp_fifo;
    uvm_tlm_analysis_fifo #(kst_item) kst_fifo;

    // FIXED: Upgraded to an Associative Array to allow Out-Of-Order checking!
    int exp_counts[string]; 

    int total_commands = 0;
    int successful_pulses = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        bkp_fifo = new("bkp_fifo", this);
        kst_fifo = new("kst_fifo", this);
    endfunction

    task run_phase(uvm_phase phase);
        fork
            predict_traffic();
            compare_traffic();
        join
    endtask

    // THREAD 1: THE PREDICTOR
    task predict_traffic();
        bkp_item req;
        forever begin
            bkp_fifo.get(req);
            
            // Only care about writes to addresses 42-48
            if (req.bkp_card_id == req.fpga_card_id && req.bkp_data_dir && (req.bkp_address >= 42 && req.bkp_address <= 48)) begin
                
                // Increment the specific channel's expectation counter
                if (req.bkp_address == 42 && req.bkp_data[9]) begin exp_counts["UART1"]++; total_commands++; end
                if (req.bkp_address == 43 && req.bkp_data[9]) begin exp_counts["UART2"]++; total_commands++; end
                if (req.bkp_address == 44 && req.bkp_data[9]) begin exp_counts["UART3"]++; total_commands++; end
                
                if (req.bkp_address == 45 && req.bkp_data[8]) begin exp_counts["ETH1"]++; total_commands++; end
                if (req.bkp_address == 46 && req.bkp_data[8]) begin exp_counts["ETH2"]++; total_commands++; end
                if (req.bkp_address == 47 && req.bkp_data[8]) begin exp_counts["ETH3"]++; total_commands++; end
                if (req.bkp_address == 48 && req.bkp_data[8]) begin exp_counts["ETH4"]++; total_commands++; end
            end
        end
    endtask

    // THREAD 2: THE COMPARATOR
    task compare_traffic();
        kst_item act_item;
        
        forever begin
            kst_fifo.get(act_item);
            
            // Check if we are expecting a pulse on this specific channel
            if (exp_counts.exists(act_item.target_name) && exp_counts[act_item.target_name] > 0) begin
                
                exp_counts[act_item.target_name]--; // Decrement the counter
                successful_pulses++;
                `uvm_info("KST_MATCH", $sformatf("✅ HANDSHAKE COMPLETE -> Target: %s", act_item.target_name), UVM_LOW)
                
            end 
            else begin
                `uvm_error("KST_MISMATCH", $sformatf("Unexpected Pulse! We were not expecting a pulse from: %s", act_item.target_name))
            end
        end
    endtask

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("KST_REPORT", $sformatf("\n====================================\n| KERNEL START TX SUMMARY          |\n====================================\n| TOTAL COMMANDS: %0d              |\n| PULSES VERIFIED: %0d             |\n====================================\n", total_commands, successful_pulses), UVM_LOW)
    endfunction

endclass

`endif