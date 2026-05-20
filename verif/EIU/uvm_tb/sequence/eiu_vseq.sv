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

    task body();
        bkp_sequence         cfg_seq;
        bkp_smart_seq        poll_seq; 
        kwr_routing_seq      tx_inj_seq;
        uart_main_sequence   uart_seq[3];
        eiu_phy_rx_seq       eth_rx_seq[4]; 
        
        // [NEW] NRZ Sequences
        nrz_sequence         nrz_seq;
        
        int num_packets = 10; 
        int en_uart[3] = '{1, 1, 1};
        int en_eth[4]  = '{1, 1, 1, 1}; 
        
        // [NEW] NRZ Configuration Variables
        int nrz_en = 1;
        int nrz_bpw = 1; // Default 1 (8-bits)
        int nrz_endian = 0;
        int nrz_sync1 = 'hFAF;
        int nrz_sync2 = 'h320;
        int nrz_payload_len = 50;
        
        $value$plusargs("NUM_PKTS=%d", num_packets);
        $value$plusargs("EN_UART1=%d", en_uart[0]);
        $value$plusargs("EN_UART2=%d", en_uart[1]);
        $value$plusargs("EN_UART3=%d", en_uart[2]);
        $value$plusargs("EN_ETH1=%d", en_eth[0]);
        $value$plusargs("EN_ETH2=%d", en_eth[1]);
        $value$plusargs("EN_ETH3=%d", en_eth[2]);
        $value$plusargs("EN_ETH4=%d", en_eth[3]);

        // [NEW] Plusargs for NRZ
        $value$plusargs("EN_NRZ=%d", nrz_en);
        $value$plusargs("NRZ_BPW=%d", nrz_bpw); 
        $value$plusargs("NRZ_ENDIAN=%d", nrz_endian);
        $value$plusargs("NRZ_SYNC1=%h", nrz_sync1);
        $value$plusargs("NRZ_SYNC2=%h", nrz_sync2);
        $value$plusargs("NRZ_PLEN=%d", nrz_payload_len);

        `uvm_info("VSEQ", "=== STAGE 1: HARDWARE CONFIGURATION ===", UVM_LOW)
        cfg_seq = bkp_sequence::type_id::create("cfg_seq");
        cfg_seq.target_card_id = 4'h0;
        
        // [NEW] Program the exact NRZ parameters requested by the user into the Kernel Configuration
        cfg_seq.nrz_bpw         = nrz_bpw;
        cfg_seq.nrz_zero_endian = nrz_endian;
        cfg_seq.nrz_sync_word1  = nrz_sync1;
        cfg_seq.nrz_sync_word2  = nrz_sync2;
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
            
            // [NEW] Start the NRZ Generation Sequence
            if (nrz_en == 1) begin
                begin
                    `uvm_info("VSEQ", "Enabling Telemetry Traffic on ETH5 (NRZ)", UVM_LOW)
                    nrz_seq = nrz_sequence::type_id::create("nrz_seq");
                    nrz_seq.cfg_bpw         = nrz_bpw;
                    nrz_seq.cfg_zero_endian = nrz_endian;
                    nrz_seq.cfg_sync_word1  = nrz_sync1;
                    nrz_seq.cfg_sync_word2  = nrz_sync2;
                    nrz_seq.cfg_payload_len = nrz_payload_len; // Custom addition to match the config
                    nrz_seq.start(p_sequencer.nrz_sqr);
                end
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
            
            #3us; 
            
            `uvm_info("VSEQ", $sformatf("--- ETH PING-PONG: Triggering CPU to Extract Packet %0d ---", p+1), UVM_LOW)
            poll_seq.start(p_sequencer.bkp_sqr);
        end
        
        #100us;
        disable fork;
        `uvm_info("VSEQ", "=== ALL DUPLEX STAGES COMPLETE ===", UVM_LOW)
    endtask
endclass
`endif