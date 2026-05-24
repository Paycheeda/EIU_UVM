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
        
        finish_item(req);
        
        if (uvm_config_db#(uvm_queue#(phy_rx_seq_item))::get(null, "", $sformatf("golden_eth_rx_q_%0d", port_id), g_q)) begin
            g_q.push_back(req);
        end else begin
            `uvm_error("VSEQ", $sformatf("CRITICAL: Could not find golden_eth_rx_q_%0d in config DB!", port_id))
        end
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

        int nrz_en          = 0;
        int nrz_bpw_bits    = 8;
        int nrz_endian      = 0;
        int nrz_payload_len = 50;
        int nrz_sync1_arg   = -1;
        int nrz_sync2_arg   = -1;
        bit [11:0] final_s1, final_s2;

        $value$plusargs("NUM_PKTS=%d",    num_packets);
        $value$plusargs("EN_UART1=%d",    en_uart[0]);
        $value$plusargs("EN_UART2=%d",    en_uart[1]);
        $value$plusargs("EN_UART3=%d",    en_uart[2]);
        $value$plusargs("EN_ETH1=%d",     en_eth[0]);
        $value$plusargs("EN_ETH2=%d",     en_eth[1]);
        $value$plusargs("EN_ETH3=%d",     en_eth[2]);
        $value$plusargs("EN_ETH4=%d",     en_eth[3]);
        $value$plusargs("EN_NRZ=%d",      nrz_en);
        $value$plusargs("NRZ_BPW=%d",     nrz_bpw_bits);
        $value$plusargs("NRZ_PLEN=%d",    nrz_payload_len);
        $value$plusargs("NRZ_ENDIAN=%d",  nrz_endian);
        $value$plusargs("NRZ_SYNC1=%h",   nrz_sync1_arg);
        $value$plusargs("NRZ_SYNC2=%h",   nrz_sync2_arg);

        get_default_nrz_syncs(nrz_bpw_bits, final_s1, final_s2);
        if (nrz_sync1_arg != -1) final_s1 = nrz_sync1_arg;
        if (nrz_sync2_arg != -1) final_s2 = nrz_sync2_arg;

        // ================================================================
        // STAGE 1: HARDWARE CONFIGURATION (serial on bkp_sqr)
        // ================================================================
        `uvm_info("VSEQ", "=== STAGE 1: HARDWARE CONFIGURATION ===", UVM_LOW)

        cfg_seq = bkp_sequence::type_id::create("cfg_seq");
        cfg_seq.target_card_id  = 4'h0;
        cfg_seq.nrz_bpw_code    = nrz_bpw_code(nrz_bpw_bits);
        cfg_seq.nrz_zero_endian = nrz_endian;
        cfg_seq.nrz_sync_word1  = final_s1;
        cfg_seq.nrz_sync_word2  = final_s2;
        cfg_seq.nrz_payload_len = nrz_payload_len;
        cfg_seq.start(p_sequencer.bkp_sqr);

        `uvm_info("VSEQ", "=== STAGE 1 COMPLETE: Hardware locked and configured ===", UVM_LOW)
        #100us;

        // ================================================================
        // STAGE 2: CONCURRENT TRAFFIC INJECTION
        //   - kwr (BKP TX: UART-TX + ETH-TX) on bkp_sqr
        //   - uart_seqs (UART RX line) each on independent uart_rx_sqr[i]
        //   - eth_rx_seqs (ETH PHY RX) each on independent eth_rx_sqr[i]
        //   - nrz_seq runs in background (independent nrz_sqr)
        // ================================================================
        `uvm_info("VSEQ", $sformatf("=== STAGE 2: CONCURRENT INJECTION (%0d PKT/CHANNEL) ===", num_packets), UVM_LOW)

        // Pre-build sequences so we can set properties before start()
        tx_inj_seq = kwr_routing_seq::type_id::create("tx_inj_seq");
        tx_inj_seq.num_packets  = num_packets;
        tx_inj_seq.test_card_id = 4'h0;

        for (int i = 0; i < 3; i++) begin
            if (en_uart[i]) begin
                uart_seq[i] = uart_main_sequence::type_id::create($sformatf("uart_seq_%0d", i));
                uart_seq[i].num_packets = num_packets;
            end
        end

        if (nrz_en == 1) begin
            `uvm_info("VSEQ", "NRZ/ETH5 enabled — telemetry traffic will be injected", UVM_LOW)
            nrz_seq = nrz_sequence::type_id::create("nrz_seq");
            nrz_seq.cfg_bpw         = nrz_bpw_code(nrz_bpw_bits);
            nrz_seq.cfg_zero_endian = nrz_endian;
            nrz_seq.cfg_sync_word1  = final_s1;
            nrz_seq.cfg_sync_word2  = final_s2;
            nrz_seq.cfg_payload_len = nrz_payload_len;
            nrz_seq.cfg_num_packets = num_packets;
        end

        // NRZ runs in background — scoreboard monitors ETH5 independently
        if (nrz_en == 1) begin
            fork
                nrz_seq.start(p_sequencer.nrz_sqr);
            join_none
        end

        // UART TX + UART RX injection run concurrently; ETH TX (kwr) also here
        fork
            // Thread 1: BKP TX injection (UART-TX bytes + ETH-TX frames via CPU)
            begin
                tx_inj_seq.start(p_sequencer.bkp_sqr);
            end

            // Threads 2-4: UART RX line injection — each on its own sequencer
            begin
                if (en_uart[0]) uart_seq[0].start(p_sequencer.uart_rx_sqr[0]);
            end
            begin
                if (en_uart[1]) uart_seq[1].start(p_sequencer.uart_rx_sqr[1]);
            end
            begin
                if (en_uart[2]) uart_seq[2].start(p_sequencer.uart_rx_sqr[2]);
            end
        join

        `uvm_info("VSEQ", "=== STAGE 2 COMPLETE: UART/ETH-TX injection finished ===", UVM_LOW)

        // ================================================================
        // STAGE 3: ETH RX — inject one packet, immediately read it back,
        //   then inject the next. The DUT RX FIFO is live-stream: each new
        //   incoming packet overwrites the previous one, so burst-then-poll
        //   would lose all packets except the last.
        //   bkp_sqr is free here (kwr finished in Stage 2).
        // ================================================================
        `uvm_info("VSEQ", "=== STAGE 3: ETH RX INTERLEAVED INJECT+POLL ===", UVM_LOW)

        for (int i = 0; i < 4; i++) begin
            if (en_eth[i]) begin
                `uvm_info("VSEQ", $sformatf("ETH%0d: injecting and reading %0d packet(s) one at a time", i+1, num_packets), UVM_LOW)
                for (int p = 0; p < num_packets; p++) begin
                    eth_rx_seq[i] = eiu_phy_rx_seq::type_id::create($sformatf("eth_rx_seq_%0d_pkt%0d", i, p));
                    eth_rx_seq[i].port_id = i;
                    eth_rx_seq[i].start(p_sequencer.eth_rx_sqr[i]);
                    #5us; // CDC settle before readback
                    poll_seq = bkp_smart_seq::type_id::create("poll_seq");
                    poll_seq.target_card_id = 4'h0;
                    poll_seq.eth_target = i;
                    poll_seq.start(p_sequencer.bkp_sqr);
                end
            end
        end

        `uvm_info("VSEQ", "=== STAGE 3 COMPLETE: ETH RX verified ===", UVM_LOW)

        // ================================================================
        // STAGE 4: UART RX READBACK — drain remaining bytes from UART FIFOs.
        // ================================================================
        `uvm_info("VSEQ", "=== STAGE 4: UART RX POLLING ===", UVM_LOW)
        #5us;

        repeat(20) begin
            poll_seq = bkp_smart_seq::type_id::create("poll_seq");
            poll_seq.target_card_id = 4'h0;
            poll_seq.start(p_sequencer.bkp_sqr);
            #10us;
        end

        // Give NRZ serialization time to complete, then clean up
        if (nrz_en == 1) #500us;
        disable fork;

        `uvm_info("VSEQ", "=== ALL STAGES COMPLETE ===", UVM_LOW)
    endtask
endclass
`endif