////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : eiu_vseq.sv
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
//  UVM virtual sequence for EIU verification
////////////////////////////////////////////////////////////////////////////////

`ifndef EIU_VSEQ_SV
`define EIU_VSEQ_SV

class eiu_phy_rx_seq extends uvm_sequence #(phy_rx_seq_item);
    `uvm_object_utils(eiu_phy_rx_seq)
    
    int port_id = 0; 
    
    function new(string name="eiu_phy_rx_seq"); 
        super.new(name); 
    endfunction
    
    task body();
        int p_size;
        uvm_queue #(phy_rx_seq_item) g_q; 
        
        req = phy_rx_seq_item::type_id::create("req");
        start_item(req);
        
        req.dest_mac     = 48'hFFFF_FFFF_FFFF; 
        req.source_mac   = 48'h0011_2233_4455;
        req.eth_type     = 16'h0800; // IPv4
        
        req.version      = 4'h4;
        req.ihl          = 4'h5;
        req.tos          = 8'h00;
        req.id           = $urandom_range(0, 65535);
        req.flags        = 3'b000;
        req.frag_offset  = 13'b0;
        req.ttl          = 8'h40;
        req.protocol     = 8'h11; // UDP
        
        req.src_ip       = 32'hC0A8_0101;
        req.dest_ip      = 32'hC0A8_0102;
        req.source_port  = 16'h1234;
        req.dest_port    = 16'h5678;
        
        req.inject_crc_error     = 0;
        req.inject_rx_er_at_byte = 0;
        req.early_drop_at_byte   = 0;
        
        p_size = $urandom_range(18, 40);
        req.payload = new[p_size];
        foreach(req.payload[k]) req.payload[k] = $urandom_range(0, 255);
        
        req.total_length = 16'(p_size + 28);
        
        if (uvm_config_db#(uvm_queue#(phy_rx_seq_item))::get(null, "", $sformatf("golden_eth_rx_q_%0d", port_id), g_q)) begin
            // Push expected data before the driver starts consuming the item so the
            // scoreboard cannot be beaten by a fast DUT/backplane poll.
            g_q.push_back(req);
        end else begin
            `uvm_error("VSEQ", $sformatf("CRITICAL: Could not find golden_eth_rx_q_%0d in config DB!", port_id))
        end

        finish_item(req);
    endtask
endclass

class eiu_vseq extends uvm_sequence;
    `uvm_object_utils(eiu_vseq)
    `uvm_declare_p_sequencer(eiu_vsqr)

    function new(string name = "eiu_vseq");
        super.new(name);
    endfunction

    // --- Helper Functions for NRZ ---
    function automatic bit [1:0] nrz_bpw_code(int bpw_bits);
        case (bpw_bits)
            8 : return 2'd0;
            9 : return 2'd1;
            10: return 2'd2;
            12: return 2'd3;
            default: begin
                `uvm_error("NRZ_CFG", $sformatf("Unsupported NRZ_BPW=%0d. Defaulting to 8-bit.", bpw_bits))
                return 2'd0;
            end
        endcase
    endfunction

    function automatic void get_default_nrz_syncs(input int bpw_bits, output bit [11:0] s1, output bit [11:0] s2);
        case (bpw_bits)
            8 : begin s1 = 12'h0EB; s2 = 12'h090; end
            9 : begin s1 = 12'h1E6; s2 = 12'h140; end
            10: begin s1 = 12'h3B7; s2 = 12'h220; end
            12: begin s1 = 12'hFAF; s2 = 12'h320; end
            default: begin s1 = 12'h0EB; s2 = 12'h090; end
        endcase
    endfunction

    task body();
        bkp_sequence         cfg_seq;
        bkp_smart_seq        poll_seq; 
        kwr_routing_seq      tx_inj_seq;
        uart_main_sequence   uart_seq[3];
        eiu_phy_rx_seq       eth_rx_seq[4]; 
        
        nrz_sequence         nrz_seq;
        
        int num_packets = 10; 
        int en_uart[3]  = '{0, 0, 0};
        int en_eth[4]   = '{1, 1, 1, 1}; 
        
        // NRZ Variables
        int nrz_en          = 0;
        int nrz_bpw_bits    = 8;
        int nrz_endian      = 0;
        int nrz_payload_len = 50;
        int nrz_sync1_arg   = -1;
        int nrz_sync2_arg   = -1;
        bit [11:0] final_s1, final_s2;
        
        bit tx_done = 0;
        bit uart_done[3] = '{0, 0, 0};
        bit nrz_done = 0;
        int bg_timeout_us = 20000;
        int final_drain_passes = 5;
        int final_drain_gap_us = 10;

        $value$plusargs("NUM_PKTS=%d", num_packets);
        $value$plusargs("EN_UART1=%d", en_uart[0]);
        $value$plusargs("EN_UART2=%d", en_uart[1]);
        $value$plusargs("EN_UART3=%d", en_uart[2]);
        $value$plusargs("EN_ETH1=%d", en_eth[0]);
        $value$plusargs("EN_ETH2=%d", en_eth[1]);
        $value$plusargs("EN_ETH3=%d", en_eth[2]);
        $value$plusargs("EN_ETH4=%d", en_eth[3]);

        $value$plusargs("EN_NRZ=%d", nrz_en);
        $value$plusargs("NRZ_BPW=%d", nrz_bpw_bits);
        $value$plusargs("NRZ_PLEN=%d", nrz_payload_len);
        $value$plusargs("NRZ_ENDIAN=%d", nrz_endian);
        $value$plusargs("NRZ_SYNC1=%h", nrz_sync1_arg);
        $value$plusargs("NRZ_SYNC2=%h", nrz_sync2_arg);

        $value$plusargs("BG_TIMEOUT_US=%d", bg_timeout_us);
        $value$plusargs("FINAL_DRAIN_PASSES=%d", final_drain_passes);
        $value$plusargs("FINAL_DRAIN_GAP_US=%d", final_drain_gap_us);
        if (bg_timeout_us < 1) bg_timeout_us = 1;
        if (final_drain_passes < 1) final_drain_passes = 1;
        if (final_drain_gap_us < 0) final_drain_gap_us = 0;

        for (int i = 0; i < 3; i++) uart_done[i] = (en_uart[i] == 0);
        nrz_done = (nrz_en == 0);

        // Auto-assign syncs if they weren't overridden
        get_default_nrz_syncs(nrz_bpw_bits, final_s1, final_s2);
        if (nrz_sync1_arg != -1) final_s1 = nrz_sync1_arg;
        if (nrz_sync2_arg != -1) final_s2 = nrz_sync2_arg;

        `uvm_info("VSEQ", "=== STAGE 1: HARDWARE CONFIGURATION ===", UVM_LOW)
        cfg_seq = bkp_sequence::type_id::create("cfg_seq");
        cfg_seq.target_card_id = 4'h0;
        
        // Inject NRZ mapping into the hardware config sequence
        cfg_seq.nrz_bpw_code    = nrz_bpw_code(nrz_bpw_bits);
        cfg_seq.nrz_zero_endian = nrz_endian;
        cfg_seq.nrz_sync_word1  = final_s1;
        cfg_seq.nrz_sync_word2  = final_s2;
        cfg_seq.nrz_payload_len = nrz_payload_len;
        
        cfg_seq.start(p_sequencer.bkp_sqr); 

        #100us; 

        `uvm_info("VSEQ", $sformatf("=== STAGE 2: EVENT-DRIVEN PING-PONG TRAFFIC (%0d Packets) ===", num_packets), UVM_LOW)
        
        fork
            begin
                tx_inj_seq = kwr_routing_seq::type_id::create("tx_inj_seq");
                tx_inj_seq.num_packets = num_packets; 
                tx_inj_seq.test_card_id = 4'h0; 
                tx_inj_seq.start(p_sequencer.bkp_sqr);
                tx_done = 1;
            end
            begin
                if (en_uart[0] == 1) begin uart_seq[0] = uart_main_sequence::type_id::create("uart_seq[0]"); uart_seq[0].start(p_sequencer.uart_rx_sqr[0]); end
                uart_done[0] = 1;
            end
            begin
                if (en_uart[1] == 1) begin uart_seq[1] = uart_main_sequence::type_id::create("uart_seq[1]"); uart_seq[1].start(p_sequencer.uart_rx_sqr[1]); end
                uart_done[1] = 1;
            end
            begin
                if (en_uart[2] == 1) begin uart_seq[2] = uart_main_sequence::type_id::create("uart_seq[2]"); uart_seq[2].start(p_sequencer.uart_rx_sqr[2]); end
                uart_done[2] = 1;
            end
            
            // Generate NRZ Traffic!
            begin
                if (nrz_en == 1) begin
                    `uvm_info("VSEQ", "Enabling Telemetry Traffic on ETH5 (NRZ)", UVM_LOW)
                    nrz_seq = nrz_sequence::type_id::create("nrz_seq");
                    nrz_seq.cfg_bpw         = nrz_bpw_code(nrz_bpw_bits);
                    nrz_seq.cfg_zero_endian = nrz_endian;
                    nrz_seq.cfg_sync_word1  = final_s1;
                    nrz_seq.cfg_sync_word2  = final_s2;
                    nrz_seq.cfg_payload_len = nrz_payload_len;
                    nrz_seq.cfg_num_packets = num_packets; 
                    nrz_seq.start(p_sequencer.nrz_sqr);
                end
                nrz_done = 1;
            end
        join_none 

        for (int p = 0; p < num_packets; p++) begin
            `uvm_info("VSEQ", $sformatf("--- ETH PING-PONG: Pushing Packet %0d/%0d to PHY ---", p+1, num_packets), UVM_LOW)
            
            fork
                begin
                    if (en_eth[0] == 1) begin eth_rx_seq[0] = eiu_phy_rx_seq::type_id::create("eth_rx_seq[0]"); eth_rx_seq[0].port_id = 0; eth_rx_seq[0].start(p_sequencer.eth_rx_sqr[0]); end
                end
                begin
                    if (en_eth[1] == 1) begin eth_rx_seq[1] = eiu_phy_rx_seq::type_id::create("eth_rx_seq[1]"); eth_rx_seq[1].port_id = 1; eth_rx_seq[1].start(p_sequencer.eth_rx_sqr[1]); end
                end
                begin
                    if (en_eth[2] == 1) begin eth_rx_seq[2] = eiu_phy_rx_seq::type_id::create("eth_rx_seq[2]"); eth_rx_seq[2].port_id = 2; eth_rx_seq[2].start(p_sequencer.eth_rx_sqr[2]); end
                end
                begin
                    if (en_eth[3] == 1) begin eth_rx_seq[3] = eiu_phy_rx_seq::type_id::create("eth_rx_seq[3]"); eth_rx_seq[3].port_id = 3; eth_rx_seq[3].start(p_sequencer.eth_rx_sqr[3]); end
                end
            join
            
            `uvm_info("VSEQ", $sformatf("--- ETH PING-PONG: Triggering CPU to Extract Packet %0d ---", p+1), UVM_LOW)
            poll_seq = bkp_smart_seq::type_id::create($sformatf("poll_seq_pkt_%0d", p));
            poll_seq.target_card_id = 4'h0;
            for (int i = 0; i < 4; i++) poll_seq.wait_for_eth[i] = en_eth[i];
            poll_seq.start(p_sequencer.bkp_sqr);
        end
        
        begin
            bit bg_timeout_hit = 0;
            fork
                begin
                    wait (tx_done && uart_done[0] && uart_done[1] && uart_done[2] && nrz_done);
                end
                begin
                    #(bg_timeout_us * 1us);
                    bg_timeout_hit = 1;
                    `uvm_error("VSEQ_TIMEOUT", $sformatf("Background traffic did not finish within %0d us. TX=%0d UART_DONE=%0d%0d%0d NRZ=%0d",
                        bg_timeout_us, tx_done, uart_done[0], uart_done[1], uart_done[2], nrz_done))
                end
            join_any
            disable fork;

            if (bg_timeout_hit) begin
                return;
            end
        end

        `uvm_info("VSEQ", "Background traffic generators complete. Performing final CPU RX drain.", UVM_LOW)
        for (int drain = 0; drain < final_drain_passes; drain++) begin
            #(final_drain_gap_us * 1us);
            poll_seq = bkp_smart_seq::type_id::create($sformatf("final_poll_seq_%0d", drain));
            poll_seq.target_card_id = 4'h0;
            poll_seq.start(p_sequencer.bkp_sqr);
            if (poll_seq.total_bytes_read == 0) begin
                `uvm_info("VSEQ", $sformatf("Final drain pass %0d found no pending CPU RX data.", drain+1), UVM_HIGH)
            end
        end

        `uvm_info("VSEQ", "=== ALL DUPLEX STAGES COMPLETE ===", UVM_LOW)
    endtask
endclass
`endif