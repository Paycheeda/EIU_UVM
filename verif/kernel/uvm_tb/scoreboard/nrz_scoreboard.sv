////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : nrz_scoreboard.sv
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
//  UVM scoreboard for Kernel NRZ verification
////////////////////////////////////////////////////////////////////////////////

`ifndef NRZ_SCOREBOARD_SV
`define NRZ_SCOREBOARD_SV

class nrz_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(nrz_scoreboard)

    uvm_tlm_analysis_fifo #(nrz_item)     inject_fifo;
    uvm_tlm_analysis_fifo #(nrz_out_item) actual_fifo;

    int total_packets = 0;
    int successful_packets = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        inject_fifo = new("inject_fifo", this);
        actual_fifo = new("actual_fifo", this);
    endfunction

    task run_phase(uvm_phase phase);
        nrz_item     inj_item;
        nrz_out_item act_item;
        bit [7:0]    expected_q[$]; 
        
        forever begin
            inject_fifo.get(inj_item);
            total_packets++; 
            expected_q.delete();

            pack_expected_word(inj_item.sync_word1, inj_item.bpw, inj_item.zero_endian, expected_q);
            pack_expected_word(inj_item.sync_word2, inj_item.bpw, inj_item.zero_endian, expected_q);
            foreach(inj_item.payload[i]) begin
                pack_expected_word(inj_item.payload[i], inj_item.bpw, inj_item.zero_endian, expected_q);
            end

            fork
                begin : wait_for_actual
                    actual_fifo.get(act_item);
                    
                    if (expected_q.size() != act_item.unpacked_bytes.size()) begin
                        `uvm_error("NRZ_SCB", $sformatf("SIZE MISMATCH on Pkt #%0d! Expected %0d bytes, Got %0d bytes.", 
                                   total_packets, expected_q.size(), act_item.unpacked_bytes.size()))
                        
                        $display("\n--- TRIAGE HEX DUMP (FIRST 4 BYTES) ---");
                        for(int i=0; i<4; i++) begin
                            if (i < expected_q.size() && i < act_item.unpacked_bytes.size())
                                $display("Byte %0d | Expected: 'h%0h | Actual RTL Got: 'h%0h", i, expected_q[i], act_item.unpacked_bytes[i]);
                        end
                        $display("---------------------------------------\n");
                        
                    end else begin
                        bit packet_passed = 1'b1;
                        foreach(expected_q[i]) begin
                            if (expected_q[i] !== act_item.unpacked_bytes[i]) begin
                                `uvm_error("NRZ_SCB", $sformatf("DATA MISMATCH at Byte %0d! Exp: 'h%0h, Got: 'h%0h", 
                                           i, expected_q[i], act_item.unpacked_bytes[i]))
                                packet_passed = 1'b0;
                            end
                        end

                        if (packet_passed) begin
                            successful_packets++;
                            `uvm_info("NRZ_SCB", $sformatf("[MATCH] NRZ Packet #%0d verified! (%0d Bytes, BPW: %0d)", 
                                      total_packets, expected_q.size(), get_bpw_num(inj_item.bpw)), UVM_LOW)
                        end
                    end
                end
                
                begin : timeout_thread
                    // ---> FIXED: Extended timeout to 5 milliseconds to prevent false-drops of large packets
                    #5000000ns;
                    `uvm_error("NRZ_SCB", $sformatf("[FATAL DROP] RTL completely ignored Packet #%0d. FSM Deadlock?", total_packets))
                end
            join_any
            
            disable fork; 
        end
    endtask

    function void pack_expected_word(bit [11:0] word, bit [1:0] bpw, bit zero_endian, ref bit [7:0] exp_q[$]);
        case (bpw)
            2'd0: begin // 8 BITS
                exp_q.push_back(word[7:0]);
            end
            2'd1: begin // 9 BITS
                if (!zero_endian) begin
                    exp_q.push_back({7'd0, word[8]});
                    exp_q.push_back(word[7:0]);
                end else begin
                    exp_q.push_back(word[8:1]);
                    exp_q.push_back({word[0], 7'd0});
                end
            end
            2'd2: begin // 10 BITS
                if (!zero_endian) begin
                    exp_q.push_back({6'd0, word[9:8]});
                    exp_q.push_back(word[7:0]);
                end else begin
                    exp_q.push_back(word[9:2]);
                    exp_q.push_back({word[1:0], 6'd0});
                end
            end
            2'd3: begin // 12 BITS
                if (!zero_endian) begin
                    exp_q.push_back({4'd0, word[11:8]});
                    exp_q.push_back(word[7:0]);
                end else begin
                    exp_q.push_back(word[11:4]);
                    exp_q.push_back({word[3:0], 4'd0});
                end
            end
        endcase
    endfunction

    function int get_bpw_num(bit [1:0] bpw);
        case(bpw)
            2'd0: return 8; 2'd1: return 9; 2'd2: return 10; 2'd3: return 12;
        endcase
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        $display("\n==========================================================================");
        $display("|                     KERNEL NRZ SERIAL LEDGER                           |");
        $display("==========================================================================");
        $display("| Total Serial Packets Injected:  %-6d                                 |", total_packets); 
        $display("| Perfect Reconstructions:        %-6d                                 |", successful_packets);
        $display("| Failed Endianness/Padding:      %-6d                                 |", (total_packets - successful_packets));
        $display("==========================================================================\n");
    endfunction

endclass
`endif