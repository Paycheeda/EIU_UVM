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
        
        // NRZ Variables
        int nrz_en          = 0;
        int nrz_bpw_bits    = 8;
        int nrz_endian      = 0;
        int nrz_payload_len = 50;
        int nrz_sync1_arg   = -1;
        int nrz_sync2_arg   = -1;
        bit [11:0] final_s1, final_s2;
        
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
            end
            for (int i = 0; i < 3; i++) begin
                automatic int j = i;
                if (en_uart[j] == 1) begin
                    uart_seq[j] = uart_main_sequence::type_id::create($sformatf("uart_seq[%0d]", j));
                    uart_seq[j].start(p_sequencer.uart_rx_sqr[j]);
                end
            end
            
            // Generate NRZ Traffic!
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
        join_none 

        poll_seq = bkp_smart_seq::type_id::create("poll_seq");
        poll_seq.target_card_id = 4'h0;

        for (int p = 0; p < num_packets; p++) begin
            `uvm_info("VSEQ", $sformatf("--- ETH PING-PONG: Pushing Packet %0d/%0d to PHY ---", p+1, num_packets), UVM_LOW)
            
            fork
                for (int i = 0; i < 4; i++) begin
                    automatic int j = i;
                    if (en_eth[j] == 1) begin
                        eth_rx_seq[j] = eiu_phy_rx_seq::type_id::create($sformatf("eth_rx_seq[%0d]", j));
                        eth_rx_seq[j].port_id = j; 
                        eth_rx_seq[j].start(p_sequencer.eth_rx_sqr[j]);
                    end
                end
            join
            
            #2000us; 
            
            `uvm_info("VSEQ", $sformatf("--- ETH PING-PONG: Triggering CPU to Extract Packet %0d ---", p+1), UVM_LOW)
            poll_seq.start(p_sequencer.bkp_sqr);
        end
        
        // Wait long enough for the NRZ packets to finish serializing!
        #500us;
        disable fork;
        `uvm_info("VSEQ", "=== ALL DUPLEX STAGES COMPLETE ===", UVM_LOW)
    endtask
endclass
`endif