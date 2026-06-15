`ifndef EIU_SCOREBOARD_SV
`define EIU_SCOREBOARD_SV

class eiu_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(eiu_scoreboard)

    uvm_tlm_analysis_fifo #(bkp_item) bkp_fifo;
    
    uvm_tlm_analysis_fifo #(tx_uart)     uart_rx_fifo[3]; 
    uvm_tlm_analysis_fifo #(tx_uart)     uart_tx_fifo[3];
    
    uvm_tlm_analysis_fifo #(phy_rx_seq_item) eth_rx_fifo[4];
    uvm_tlm_analysis_fifo #(eth_tx_seq_item) eth_tx_fifo[4];
    
    // ETH5 Monitor Analysis Port (NRZ Egress Interface)
    uvm_tlm_analysis_fifo #(eth_tx_seq_item) eth_nrz_fifo;
    
    bit [8:0] exp_uart_tx_q[3][$];
    bit [8:0] exp_uart_rx_q[3][$];
    bit [7:0] exp_eth_tx_q[4][$];
    bit [7:0] exp_eth_rx_q[4][$];
    
    // Golden Queue for NRZ -> ETH5 Egress Payload
    bit [7:0] exp_eth_nrz_q[$];
    
    uvm_queue #(phy_rx_seq_item) golden_q[4]; 
    uvm_queue #(nrz_item) golden_nrz_q; 
    
    int uart_tx_inj_cnt[3] = '{0, 0, 0};
    int uart_tx_ver_cnt[3] = '{0, 0, 0};
    int uart_rx_inj_cnt[3] = '{0, 0, 0};
    int uart_rx_ver_cnt[3] = '{0, 0, 0};
    
    int eth_tx_inj_cnt[4]  = '{0, 0, 0, 0};
    int eth_tx_ver_cnt[4]  = '{0, 0, 0, 0};
    int eth_rx_inj_cnt[4]  = '{0, 0, 0, 0};
    int eth_rx_ver_cnt[4]  = '{0, 0, 0, 0};
    
    int nrz_inj_cnt = 0;
    int nrz_ver_cnt = 0;

    // End-of-test packet/transaction summary counters.
    int uart_tx_pkt_inj_cnt[3]  = '{0, 0, 0};
    int uart_tx_pkt_ver_cnt[3]  = '{0, 0, 0};
    int uart_rx_pkt_inj_cnt[3]  = '{0, 0, 0};
    int uart_rx_pkt_ver_cnt[3]  = '{0, 0, 0};
    int eth_tx_pkt_inj_cnt[4]   = '{0, 0, 0, 0};
    int eth_tx_pkt_ver_cnt[4]   = '{0, 0, 0, 0};
    int eth_rx_pkt_inj_cnt[4]   = '{0, 0, 0, 0};
    int eth_rx_pkt_ver_cnt[4]   = '{0, 0, 0, 0};
    int nrz_pkt_inj_cnt         = 0;
    int nrz_pkt_ver_cnt         = 0;

    int uart_tx_fail_cnt[3]     = '{0, 0, 0};
    int uart_rx_fail_cnt[3]     = '{0, 0, 0};
    int eth_tx_fail_cnt[4]      = '{0, 0, 0, 0};
    int eth_rx_fail_cnt[4]      = '{0, 0, 0, 0};
    int nrz_fail_cnt            = 0;

    // ETH RX packets are verified byte-by-byte from the backplane.  Keep the
    // expected packet lengths so the report can count completed ETH RX packets
    // even when multiple expected frames are queued back-to-back.
    int eth_rx_pkt_rem_q[4][$];

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        bkp_fifo     = new("bkp_fifo", this);
        eth_nrz_fifo = new("eth_nrz_fifo", this); 
        
        for(int i=0; i<3; i++) begin
            uart_rx_fifo[i] = new($sformatf("uart_rx_fifo_%0d", i), this);
            uart_tx_fifo[i] = new($sformatf("uart_tx_fifo_%0d", i), this);
        end
        for(int i=0; i<4; i++) begin
            eth_rx_fifo[i] = new($sformatf("eth_rx_fifo_%0d", i), this);
            eth_tx_fifo[i] = new($sformatf("eth_tx_fifo_%0d", i), this);
            
            golden_q[i] = new($sformatf("golden_q_%0d", i));
            uvm_config_db#(uvm_queue#(phy_rx_seq_item))::set(null, "*", $sformatf("golden_eth_rx_q_%0d", i), golden_q[i]);
        end
        
        golden_nrz_q = new("golden_nrz_q");
        uvm_config_db#(uvm_queue#(nrz_item))::set(null, "*", "golden_nrz_q", golden_nrz_q);
    endfunction

    function void print_counts(int id, string proto);
        if (proto == "UART") begin
            `uvm_info("SCB_TRACKER", $sformatf("UART %0d Live Count -> TX [Inj: %0d, Ver: %0d] | RX [Inj: %0d, Ver: %0d]", 
                id+1, uart_tx_inj_cnt[id], uart_tx_ver_cnt[id], uart_rx_inj_cnt[id], uart_rx_ver_cnt[id]), UVM_HIGH)
        end else if (proto == "ETH") begin
            `uvm_info("SCB_TRACKER", $sformatf("ETH %0d Live Count -> TX [Inj: %0d, Ver: %0d] | RX [Inj: %0d, Ver: %0d]", 
                id+1, eth_tx_inj_cnt[id], eth_tx_ver_cnt[id], eth_rx_inj_cnt[id], eth_rx_ver_cnt[id]), UVM_HIGH)
        end else if (proto == "NRZ") begin
            `uvm_info("SCB_TRACKER", $sformatf("NRZ/ETH5 Live Count -> Payload Bytes [Inj: %0d, Ver: %0d]", 
                nrz_inj_cnt, nrz_ver_cnt), UVM_HIGH)
        end
    endfunction

    function bit counts_match();
        bit ok = 1'b1;

        for (int i = 0; i < 3; i++) begin
            if (uart_tx_inj_cnt[i] != uart_tx_ver_cnt[i]) ok = 1'b0;
            if (uart_rx_inj_cnt[i] != uart_rx_ver_cnt[i]) ok = 1'b0;
        end

        for (int i = 0; i < 4; i++) begin
            if (eth_tx_inj_cnt[i] != eth_tx_ver_cnt[i]) ok = 1'b0;
            if (eth_rx_inj_cnt[i] != eth_rx_ver_cnt[i]) ok = 1'b0;
        end

        if (nrz_inj_cnt != nrz_ver_cnt) ok = 1'b0;
        return ok;
    endfunction

    function bit queues_empty();
        bit empty = 1'b1;

        if (bkp_fifo.used() != 0) empty = 1'b0;
        if (eth_nrz_fifo.used() != 0) empty = 1'b0;

        if (exp_eth_nrz_q.size() != 0) empty = 1'b0;
        if (golden_nrz_q != null && golden_nrz_q.size() != 0) empty = 1'b0;

        for (int i = 0; i < 3; i++) begin
            if (uart_rx_fifo[i].used() != 0) empty = 1'b0;
            if (uart_tx_fifo[i].used() != 0) empty = 1'b0;
            if (exp_uart_tx_q[i].size() != 0) empty = 1'b0;
            if (exp_uart_rx_q[i].size() != 0) empty = 1'b0;
        end

        for (int i = 0; i < 4; i++) begin
            if (eth_rx_fifo[i].used() != 0) empty = 1'b0;
            if (eth_tx_fifo[i].used() != 0) empty = 1'b0;
            if (exp_eth_tx_q[i].size() != 0) empty = 1'b0;
            if (exp_eth_rx_q[i].size() != 0) empty = 1'b0;
            if (golden_q[i] != null && golden_q[i].size() != 0) empty = 1'b0;
        end

        return empty;
    endfunction

    function bit is_idle_complete();
        return (counts_match() && queues_empty());
    endfunction

    function string pending_summary();
        string s;

        s = "\n---------------- EIU SCOREBOARD DRAIN STATUS ----------------\n";
        for (int i = 0; i < 3; i++) begin
            s = {s, $sformatf("UART%0d TX inj/ver=%0d/%0d exp_q=%0d fifo=%0d | RX inj/ver=%0d/%0d exp_q=%0d fifo=%0d\n",
                i+1,
                uart_tx_inj_cnt[i], uart_tx_ver_cnt[i], exp_uart_tx_q[i].size(), uart_tx_fifo[i].used(),
                uart_rx_inj_cnt[i], uart_rx_ver_cnt[i], exp_uart_rx_q[i].size(), uart_rx_fifo[i].used())};
        end

        for (int i = 0; i < 4; i++) begin
            s = {s, $sformatf("ETH%0d  TX inj/ver=%0d/%0d exp_q=%0d fifo=%0d | RX inj/ver=%0d/%0d exp_q=%0d golden_q=%0d fifo=%0d\n",
                i+1,
                eth_tx_inj_cnt[i], eth_tx_ver_cnt[i], exp_eth_tx_q[i].size(), eth_tx_fifo[i].used(),
                eth_rx_inj_cnt[i], eth_rx_ver_cnt[i], exp_eth_rx_q[i].size(),
                (golden_q[i] == null) ? 0 : golden_q[i].size(), eth_rx_fifo[i].used())};
        end

        s = {s, $sformatf("NRZ/ETH5 inj/ver=%0d/%0d exp_q=%0d golden_q=%0d fifo=%0d\n",
            nrz_inj_cnt, nrz_ver_cnt, exp_eth_nrz_q.size(),
            (golden_nrz_q == null) ? 0 : golden_nrz_q.size(), eth_nrz_fifo.used())};
        s = {s, $sformatf("Backplane analysis fifo pending=%0d\n", bkp_fifo.used())};
        s = {s, "----------------------------------------------------------------\n"};
        return s;
    endfunction

    task wait_for_done(time timeout);
        time deadline;
        int stable_count;

        deadline = $time + timeout;
        stable_count = 0;

        `uvm_info("SCB_DRAIN", $sformatf("Waiting up to %0t for scoreboard queues/counters to drain", timeout), UVM_LOW)

        forever begin
            if (is_idle_complete()) begin
                stable_count++;
                if (stable_count >= 5) begin
                    `uvm_info("SCB_DRAIN", {"Scoreboard drained successfully.", pending_summary()}, UVM_LOW)
                    return;
                end
            end else begin
                stable_count = 0;
            end

            if ($time >= deadline) begin
                `uvm_error("SCB_DRAIN_TIMEOUT", {"Scoreboard did not drain before timeout.", pending_summary()})
                return;
            end

            #1us;
        end
    endtask

    function bit traffic_passed(string kind, int inj_pkt, int ver_pkt, int inj_byte, int ver_byte, int fail_cnt, int pending_cnt);
        // A row passes only when all packet/byte counts
        // match, there are no pending expected/actual entries, and no compare
        // failure was recorded for that interface/direction.
        return (inj_pkt == ver_pkt) &&
               (inj_byte == ver_byte) &&
               (fail_cnt == 0) &&
               (pending_cnt == 0);
    endfunction

    function string pass_fail(bit pass);
        return pass ? "PASS" : "FAIL";
    endfunction

    function string report_row(string name, string dir, int inj_pkt, int ver_pkt, int inj_byte, int ver_byte, int fail_cnt, int pending_cnt);
        bit pass;
        pass = traffic_passed(name, inj_pkt, ver_pkt, inj_byte, ver_byte, fail_cnt, pending_cnt);
        return $sformatf("| %-8s | %-3s | %10d | %10d | %10d | %10d | %8d | %7d | %-6s |\n",
                         name, dir, inj_pkt, ver_pkt, inj_byte, ver_byte, fail_cnt, pending_cnt, pass_fail(pass));
    endfunction

    function string final_report_table();
        string s;
        bit overall_pass;

        overall_pass = is_idle_complete();

        for (int i = 0; i < 3; i++) begin
            if (!traffic_passed($sformatf("UART%0d", i+1), uart_tx_pkt_inj_cnt[i], uart_tx_pkt_ver_cnt[i],
                                uart_tx_inj_cnt[i], uart_tx_ver_cnt[i], uart_tx_fail_cnt[i],
                                exp_uart_tx_q[i].size() + uart_tx_fifo[i].used())) overall_pass = 1'b0;
            if (!traffic_passed($sformatf("UART%0d", i+1), uart_rx_pkt_inj_cnt[i], uart_rx_pkt_ver_cnt[i],
                                uart_rx_inj_cnt[i], uart_rx_ver_cnt[i], uart_rx_fail_cnt[i],
                                exp_uart_rx_q[i].size() + uart_rx_fifo[i].used())) overall_pass = 1'b0;
        end

        for (int i = 0; i < 4; i++) begin
            if (!traffic_passed($sformatf("ETH%0d", i+1), eth_tx_pkt_inj_cnt[i], eth_tx_pkt_ver_cnt[i],
                                eth_tx_inj_cnt[i], eth_tx_ver_cnt[i], eth_tx_fail_cnt[i],
                                exp_eth_tx_q[i].size() + eth_tx_fifo[i].used())) overall_pass = 1'b0;
            if (!traffic_passed($sformatf("ETH%0d", i+1), eth_rx_pkt_inj_cnt[i], eth_rx_pkt_ver_cnt[i],
                                eth_rx_inj_cnt[i], eth_rx_ver_cnt[i], eth_rx_fail_cnt[i],
                                exp_eth_rx_q[i].size() + eth_rx_fifo[i].used() + eth_rx_pkt_rem_q[i].size() + ((golden_q[i] == null) ? 0 : golden_q[i].size()))) overall_pass = 1'b0;
        end

        if (!traffic_passed("ETH5", nrz_pkt_inj_cnt, nrz_pkt_ver_cnt,
                            nrz_inj_cnt, nrz_ver_cnt, nrz_fail_cnt,
                            exp_eth_nrz_q.size() + eth_nrz_fifo.used() + ((golden_nrz_q == null) ? 0 : golden_nrz_q.size()))) overall_pass = 1'b0;

        s = "\n";
        s = {s, "+----------------------------------------------------------------------------------------------------------+\n"};
        s = {s, "|                                      EIU SCOREBOARD FINAL REPORT                                      |\n"};
        s = {s, "+----------------------------------------------------------------------------------------------------------+\n"};
        s = {s, $sformatf("| Overall Result: %-84s |\n", pass_fail(overall_pass))};
        s = {s, "+----------+-----+------------+------------+------------+------------+----------+---------+--------+\n"};
        s = {s, "| Interface| Dir | Inj Pkts   | Ver Pkts   | Inj Bytes  | Ver Bytes  | Fails    | Pending | Result |\n"};
        s = {s, "+----------+-----+------------+------------+------------+------------+----------+---------+--------+\n"};

        for (int i = 0; i < 3; i++) begin
            s = {s, report_row($sformatf("UART%0d", i+1), "TX", uart_tx_pkt_inj_cnt[i], uart_tx_pkt_ver_cnt[i],
                               uart_tx_inj_cnt[i], uart_tx_ver_cnt[i], uart_tx_fail_cnt[i],
                               exp_uart_tx_q[i].size() + uart_tx_fifo[i].used())};
            s = {s, report_row($sformatf("UART%0d", i+1), "RX", uart_rx_pkt_inj_cnt[i], uart_rx_pkt_ver_cnt[i],
                               uart_rx_inj_cnt[i], uart_rx_ver_cnt[i], uart_rx_fail_cnt[i],
                               exp_uart_rx_q[i].size() + uart_rx_fifo[i].used())};
        end

        for (int i = 0; i < 4; i++) begin
            s = {s, report_row($sformatf("ETH%0d", i+1), "TX", eth_tx_pkt_inj_cnt[i], eth_tx_pkt_ver_cnt[i],
                               eth_tx_inj_cnt[i], eth_tx_ver_cnt[i], eth_tx_fail_cnt[i],
                               exp_eth_tx_q[i].size() + eth_tx_fifo[i].used())};
            s = {s, report_row($sformatf("ETH%0d", i+1), "RX", eth_rx_pkt_inj_cnt[i], eth_rx_pkt_ver_cnt[i],
                               eth_rx_inj_cnt[i], eth_rx_ver_cnt[i], eth_rx_fail_cnt[i],
                               exp_eth_rx_q[i].size() + eth_rx_fifo[i].used() + eth_rx_pkt_rem_q[i].size() + ((golden_q[i] == null) ? 0 : golden_q[i].size()))};
        end

        s = {s, report_row("ETH5", "NRZ", nrz_pkt_inj_cnt, nrz_pkt_ver_cnt,
                           nrz_inj_cnt, nrz_ver_cnt, nrz_fail_cnt,
                           exp_eth_nrz_q.size() + eth_nrz_fifo.used() + ((golden_nrz_q == null) ? 0 : golden_nrz_q.size()))};

        s = {s, "+----------+-----+------------+------------+------------+------------+----------+---------+--------+\n"};
        s = {s, "| PASS requires: injected packets == verified packets, injected bytes == verified bytes, zero fails, zero pending. |\n"};
        s = {s, "+----------------------------------------------------------------------------------------------------------+\n"};
        return s;
    endfunction

    function bit final_report_passed();
        bit ok;
        ok = is_idle_complete();

        for (int i = 0; i < 3; i++) begin
            if (!traffic_passed($sformatf("UART%0d", i+1), uart_tx_pkt_inj_cnt[i], uart_tx_pkt_ver_cnt[i],
                                uart_tx_inj_cnt[i], uart_tx_ver_cnt[i], uart_tx_fail_cnt[i],
                                exp_uart_tx_q[i].size() + uart_tx_fifo[i].used())) ok = 1'b0;
            if (!traffic_passed($sformatf("UART%0d", i+1), uart_rx_pkt_inj_cnt[i], uart_rx_pkt_ver_cnt[i],
                                uart_rx_inj_cnt[i], uart_rx_ver_cnt[i], uart_rx_fail_cnt[i],
                                exp_uart_rx_q[i].size() + uart_rx_fifo[i].used())) ok = 1'b0;
        end

        for (int i = 0; i < 4; i++) begin
            if (!traffic_passed($sformatf("ETH%0d", i+1), eth_tx_pkt_inj_cnt[i], eth_tx_pkt_ver_cnt[i],
                                eth_tx_inj_cnt[i], eth_tx_ver_cnt[i], eth_tx_fail_cnt[i],
                                exp_eth_tx_q[i].size() + eth_tx_fifo[i].used())) ok = 1'b0;
            if (!traffic_passed($sformatf("ETH%0d", i+1), eth_rx_pkt_inj_cnt[i], eth_rx_pkt_ver_cnt[i],
                                eth_rx_inj_cnt[i], eth_rx_ver_cnt[i], eth_rx_fail_cnt[i],
                                exp_eth_rx_q[i].size() + eth_rx_fifo[i].used() + eth_rx_pkt_rem_q[i].size() + ((golden_q[i] == null) ? 0 : golden_q[i].size()))) ok = 1'b0;
        end

        if (!traffic_passed("ETH5", nrz_pkt_inj_cnt, nrz_pkt_ver_cnt,
                            nrz_inj_cnt, nrz_ver_cnt, nrz_fail_cnt,
                            exp_eth_nrz_q.size() + eth_nrz_fifo.used() + ((golden_nrz_q == null) ? 0 : golden_nrz_q.size()))) ok = 1'b0;
        return ok;
    endfunction

    function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (!final_report_passed()) begin
            `uvm_error("SCB_NOT_DONE", {"Simulation ended with failed or pending scoreboard work.", pending_summary()})
        end else begin
            `uvm_info("SCB_DONE", "All expected UART, ETH, and NRZ traffic was verified before end-of-test.", UVM_LOW)
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        if (final_report_passed()) begin
            `uvm_info("SCB_FINAL_REPORT", final_report_table(), UVM_LOW)
        end else begin
            `uvm_error("SCB_FINAL_REPORT", final_report_table())
        end
    endfunction

    function void push_golden_eth_rx(int id, phy_rx_seq_item inj_item);
        bit [15:0] ip_chk, udp_chk;
        int udp_len = inj_item.payload.size() + 8;
        int pkt_len = 42 + inj_item.payload.size();
        
        ip_chk = calc_ipv4_checksum(inj_item);
        udp_chk = calc_udp_checksum(inj_item, udp_len);

        for (int i=5; i>=0; i--) exp_eth_rx_q[id].push_back(inj_item.dest_mac[i*8 +: 8]);
        for (int i=5; i>=0; i--) exp_eth_rx_q[id].push_back(inj_item.source_mac[i*8 +: 8]);
        exp_eth_rx_q[id].push_back(inj_item.eth_type[15:8]); exp_eth_rx_q[id].push_back(inj_item.eth_type[7:0]);

        exp_eth_rx_q[id].push_back({inj_item.version, inj_item.ihl});
        exp_eth_rx_q[id].push_back(inj_item.tos);
        exp_eth_rx_q[id].push_back(inj_item.total_length[15:8]); exp_eth_rx_q[id].push_back(inj_item.total_length[7:0]);
        exp_eth_rx_q[id].push_back(inj_item.id[15:8]);           exp_eth_rx_q[id].push_back(inj_item.id[7:0]);
        exp_eth_rx_q[id].push_back({inj_item.flags, inj_item.frag_offset[12:8]}); exp_eth_rx_q[id].push_back(inj_item.frag_offset[7:0]);
        exp_eth_rx_q[id].push_back(inj_item.ttl);                exp_eth_rx_q[id].push_back(inj_item.protocol);
        exp_eth_rx_q[id].push_back(ip_chk[15:8]);                exp_eth_rx_q[id].push_back(ip_chk[7:0]);
        for (int i=3; i>=0; i--) exp_eth_rx_q[id].push_back(inj_item.src_ip[i*8 +: 8]);
        for (int i=3; i>=0; i--) exp_eth_rx_q[id].push_back(inj_item.dest_ip[i*8 +: 8]);

        exp_eth_rx_q[id].push_back(inj_item.source_port[15:8]);  exp_eth_rx_q[id].push_back(inj_item.source_port[7:0]);
        exp_eth_rx_q[id].push_back(inj_item.dest_port[15:8]);    exp_eth_rx_q[id].push_back(inj_item.dest_port[7:0]);
        exp_eth_rx_q[id].push_back(udp_len[15:8]);               exp_eth_rx_q[id].push_back(udp_len[7:0]);
        exp_eth_rx_q[id].push_back(udp_chk[15:8]);               exp_eth_rx_q[id].push_back(udp_chk[7:0]);
        
        foreach(inj_item.payload[i]) exp_eth_rx_q[id].push_back(inj_item.payload[i]);

        eth_rx_inj_cnt[id] += pkt_len;
        eth_rx_pkt_inj_cnt[id]++;
        eth_rx_pkt_rem_q[id].push_back(pkt_len);
        print_counts(id, "ETH");
    endfunction
    
    function bit [15:0] calc_ipv4_checksum(phy_rx_seq_item req);
        bit [31:0] sum = {req.version, req.ihl, req.tos} + req.total_length + req.id + {req.flags, req.frag_offset} + {req.ttl, req.protocol} + req.src_ip[31:16] + req.src_ip[15:0] + req.dest_ip[31:16] + req.dest_ip[15:0];
        sum = (sum & 32'hFFFF) + (sum >> 16); 
        sum = (sum & 32'hFFFF) + (sum >> 16);
        return ~sum[15:0];
    endfunction

    function bit [15:0] calc_udp_checksum(phy_rx_seq_item req, int udp_len);
        bit [31:0] sum = req.src_ip[31:16] + req.src_ip[15:0] + req.dest_ip[31:16] + req.dest_ip[15:0] + {8'h00, req.protocol} + udp_len + req.source_port + req.dest_port + udp_len;
        for(int i=0; i<req.payload.size(); i=i+2) begin
            sum += (i+1 < req.payload.size()) ? {req.payload[i], req.payload[i+1]} : {req.payload[i], 8'h00};
        end
        sum = (sum & 32'hFFFF) + (sum >> 16); 
        sum = (sum & 32'hFFFF) + (sum >> 16);
        if (~sum[15:0] == 16'h0000) return 16'hFFFF;
        return ~sum[15:0];
    endfunction

    // ----------------------------------------------------
    // [NEW] NRZ Bit-Packing Helper Function
    // ----------------------------------------------------
    function int pack_nrz_word(bit [11:0] word, bit [1:0] bpw, bit zero_endian, ref bit [7:0] q[$]);
        // Exact replica of kernel_nrz.sv payload/header FIFO packing.
        // 8-bit mode emits one byte; 9/10/12-bit modes emit two bytes.
        case (bpw)
            2'b00: begin
                q.push_back(word[7:0]);
                return 1;
            end
            2'b01: begin
                q.push_back((!zero_endian) ? {7'd0, word[8]}   : word[8:1]);
                q.push_back((!zero_endian) ? word[7:0]          : {word[0], 7'd0});
                return 2;
            end
            2'b10: begin
                q.push_back((!zero_endian) ? {6'd0, word[9:8]} : word[9:2]);
                q.push_back((!zero_endian) ? word[7:0]          : {word[1:0], 6'd0});
                return 2;
            end
            2'b11: begin
                q.push_back((!zero_endian) ? {4'd0, word[11:8]} : word[11:4]);
                q.push_back((!zero_endian) ? word[7:0]           : {word[3:0], 4'd0});
                return 2;
            end
            default: begin
                return 0;
            end
        endcase
    endfunction

    task run_phase(uvm_phase phase);
        fork
            process_bkp_traffic();
            
            process_uart_tx(0); process_uart_tx(1); process_uart_tx(2);
            process_uart_rx(0); process_uart_rx(1); process_uart_rx(2);
            
            process_eth_tx(0); process_eth_tx(1); process_eth_tx(2); process_eth_tx(3);
            process_eth_rx(0); process_eth_rx(1); process_eth_rx(2); process_eth_rx(3);
            
            process_nrz_tx();
            process_eth5_verif();
        join
    endtask

    // ----------------------------------------------------
    // NRZ SCORING LOGIC
    // ----------------------------------------------------
    task process_nrz_tx();
        nrz_item inj_item; 
        forever begin
            if (golden_nrz_q.size() > 0) begin
                inj_item = golden_nrz_q.pop_front();
                
                // Pack Sync Words first, just like the Hardware!
                nrz_inj_cnt += pack_nrz_word(inj_item.sync_word1, inj_item.bpw, inj_item.zero_endian, exp_eth_nrz_q);
                nrz_inj_cnt += pack_nrz_word(inj_item.sync_word2, inj_item.bpw, inj_item.zero_endian, exp_eth_nrz_q);
                
                // Pack Payload Words
                foreach(inj_item.payload[i]) begin
                    nrz_inj_cnt += pack_nrz_word(inj_item.payload[i], inj_item.bpw, inj_item.zero_endian, exp_eth_nrz_q);
                end
                nrz_pkt_inj_cnt++;
                
                print_counts(0, "NRZ");
            end else begin
                #1us; // Wait if the queue is empty
            end
        end
    endtask
    
    task process_eth5_verif();
        eth_tx_seq_item act_item;
        bit [7:0] expected_val;
        
        forever begin
            eth_nrz_fifo.get(act_item); // Read packet from ETH5 TX monitor
            
            foreach (act_item.payload[i]) begin
                if (exp_eth_nrz_q.size() > 0) begin
                    expected_val = exp_eth_nrz_q.pop_front();
                    if (!compare_data($sformatf("ETH5_NRZ_PAYLOAD_BYTE[%0d]", i), expected_val, act_item.payload[i])) nrz_fail_cnt++;
                    nrz_ver_cnt++;
                end else begin
                    nrz_fail_cnt++;
                    `uvm_error("SCB_FAIL", $sformatf("ETH5 (NRZ) Transmitted payload byte %0h, but Golden Queue is empty!", act_item.payload[i]))
                end
            end
            nrz_pkt_ver_cnt++;
            print_counts(0, "NRZ");
        end
    endtask

    task process_eth_rx(int id);
        phy_rx_seq_item inj_item; 
        forever begin
            if (golden_q[id].size() > 0) begin
                inj_item = golden_q[id].pop_front();
                push_golden_eth_rx(id, inj_item);
            end else begin
                #1us;
            end
        end
    endtask

    function void mark_eth_rx_byte_verified(int id);
        int completed_pkt_len;

        if (eth_rx_pkt_rem_q[id].size() > 0) begin
            eth_rx_pkt_rem_q[id][0]--;
            if (eth_rx_pkt_rem_q[id][0] <= 0) begin
                completed_pkt_len = eth_rx_pkt_rem_q[id].pop_front();
                eth_rx_pkt_ver_cnt[id]++;
            end
        end else begin
            eth_rx_fail_cnt[id]++;
            `uvm_error("SCB_FAIL", $sformatf("ETH%0d RX byte verified but packet boundary queue is empty", id+1))
        end
    endfunction

    task process_bkp_traffic();
        bkp_item item;
        bit is_send_cmd;
        bit is_eth_data_addr;
        int eth_wr_id;
        forever begin
            bkp_fifo.get(item);
            
            if (item.trans_type == BKP_DATA_WRITE) begin
                is_send_cmd = (item.bkp_data[9] == 1'b1 || (item.bkp_data[8] == 1'b1 && item.bkp_data[9] == 1'b0 && item.bkp_data[7:0] == 8'h00));

                is_eth_data_addr = (item.bkp_address >= 6'd45 && item.bkp_address <= 6'd48);
                eth_wr_id = item.bkp_address - 6'd45;

                if (is_eth_data_addr) begin
                    if (is_send_cmd) begin
                        // One ETH TX packet is requested after its payload bytes
                        // have already been written into the expected queue.
                        eth_tx_pkt_inj_cnt[eth_wr_id]++;
                    end else begin
                        // ETH data-address writes with bit[8]=0 are payload bytes.
                        // Only 12'h100 is the TX start command; there is no
                        // follow-up clear write to ignore.
                        exp_eth_tx_q[eth_wr_id].push_back(item.bkp_data[7:0]);
                        eth_tx_inj_cnt[eth_wr_id]++;
                        print_counts(eth_wr_id, "ETH");
                    end
                end else if (!is_send_cmd) begin
                    case (item.bkp_address)
                        6'd42: begin exp_uart_tx_q[0].push_back(item.bkp_data[8:0]); uart_tx_inj_cnt[0]++; uart_tx_pkt_inj_cnt[0]++; print_counts(0, "UART"); end
                        6'd43: begin exp_uart_tx_q[1].push_back(item.bkp_data[8:0]); uart_tx_inj_cnt[1]++; uart_tx_pkt_inj_cnt[1]++; print_counts(1, "UART"); end
                        6'd44: begin exp_uart_tx_q[2].push_back(item.bkp_data[8:0]); uart_tx_inj_cnt[2]++; uart_tx_pkt_inj_cnt[2]++; print_counts(2, "UART"); end
                    endcase
                end
            end 
            else if (item.trans_type == BKP_READ) begin
                bit [8:0] expected_val, actual_val;
                actual_val = item.bkp_data[8:0]; 

                case (item.bkp_address)
                    6'd0: begin
                        if(exp_uart_rx_q[0].size() > 0) begin
                            expected_val = exp_uart_rx_q[0].pop_front();
                            if (!compare_data("UART1_RX_LINE", expected_val, actual_val)) uart_rx_fail_cnt[0]++; uart_rx_ver_cnt[0]++; uart_rx_pkt_ver_cnt[0]++; print_counts(0, "UART");
                        end else begin uart_rx_fail_cnt[0]++; `uvm_error("SCB_FAIL", $sformatf("[UART1_RX_LINE] MISMATCH! Extracted byte when queue was empty. Actual: %0h", actual_val)) end
                    end
                    6'd3: begin
                        if(exp_uart_rx_q[1].size() > 0) begin
                            expected_val = exp_uart_rx_q[1].pop_front();
                            if (!compare_data("UART2_RX_LINE", expected_val, actual_val)) uart_rx_fail_cnt[1]++; uart_rx_ver_cnt[1]++; uart_rx_pkt_ver_cnt[1]++; print_counts(1, "UART");
                        end else begin uart_rx_fail_cnt[1]++; `uvm_error("SCB_FAIL", $sformatf("[UART2_RX_LINE] MISMATCH! Extracted byte when queue was empty. Actual: %0h", actual_val)) end
                    end
                    6'd6: begin
                        if(exp_uart_rx_q[2].size() > 0) begin
                            expected_val = exp_uart_rx_q[2].pop_front();
                            if (!compare_data("UART3_RX_LINE", expected_val, actual_val)) uart_rx_fail_cnt[2]++; uart_rx_ver_cnt[2]++; uart_rx_pkt_ver_cnt[2]++; print_counts(2, "UART");
                        end else begin uart_rx_fail_cnt[2]++; `uvm_error("SCB_FAIL", $sformatf("[UART3_RX_LINE] MISMATCH! Extracted byte when queue was empty. Actual: %0h", actual_val)) end
                    end
                    
                    6'd9: begin 
                        if(exp_eth_rx_q[0].size() > 0) begin
                            expected_val = exp_eth_rx_q[0].pop_front();
                            if (!compare_data("ETH1_RX_LINE", expected_val, actual_val)) eth_rx_fail_cnt[0]++; eth_rx_ver_cnt[0]++; mark_eth_rx_byte_verified(0); print_counts(0, "ETH");
                        end else begin eth_rx_fail_cnt[0]++; `uvm_error("SCB_FAIL", $sformatf("[ETH1_RX_LINE] MISMATCH! Extracted byte when queue was empty. Actual: %0h", actual_val)) end
                    end
                    6'd12: begin 
                        if(exp_eth_rx_q[1].size() > 0) begin
                            expected_val = exp_eth_rx_q[1].pop_front();
                            if (!compare_data("ETH2_RX_LINE", expected_val, actual_val)) eth_rx_fail_cnt[1]++; eth_rx_ver_cnt[1]++; mark_eth_rx_byte_verified(1); print_counts(1, "ETH");
                        end else begin eth_rx_fail_cnt[1]++; `uvm_error("SCB_FAIL", $sformatf("[ETH2_RX_LINE] MISMATCH! Extracted byte when queue was empty. Actual: %0h", actual_val)) end
                    end
                    6'd15: begin 
                        if(exp_eth_rx_q[2].size() > 0) begin
                            expected_val = exp_eth_rx_q[2].pop_front();
                            if (!compare_data("ETH3_RX_LINE", expected_val, actual_val)) eth_rx_fail_cnt[2]++; eth_rx_ver_cnt[2]++; mark_eth_rx_byte_verified(2); print_counts(2, "ETH");
                        end else begin eth_rx_fail_cnt[2]++; `uvm_error("SCB_FAIL", $sformatf("[ETH3_RX_LINE] MISMATCH! Extracted byte when queue was empty. Actual: %0h", actual_val)) end
                    end
                    6'd18: begin 
                        if(exp_eth_rx_q[3].size() > 0) begin
                            expected_val = exp_eth_rx_q[3].pop_front();
                            if (!compare_data("ETH4_RX_LINE", expected_val, actual_val)) eth_rx_fail_cnt[3]++; eth_rx_ver_cnt[3]++; mark_eth_rx_byte_verified(3); print_counts(3, "ETH");
                        end else begin eth_rx_fail_cnt[3]++; `uvm_error("SCB_FAIL", $sformatf("[ETH4_RX_LINE] MISMATCH! Extracted byte when queue was empty. Actual: %0h", actual_val)) end
                    end
                endcase
            end
        end
    endtask

    task process_eth_tx(int id);
        eth_tx_seq_item act_item;
        bit [7:0] expected_val;
        forever begin
            eth_tx_fifo[id].get(act_item);
            foreach (act_item.payload[i]) begin
                if (exp_eth_tx_q[id].size() > 0) begin
                    expected_val = exp_eth_tx_q[id].pop_front();
                    if (!compare_data($sformatf("ETH%0d_TX_PAYLOAD_BYTE[%0d]", id+1, i), expected_val, act_item.payload[i])) eth_tx_fail_cnt[id]++;
                    eth_tx_ver_cnt[id]++;
                end else begin
                    eth_tx_fail_cnt[id]++;
                    `uvm_error("SCB_FAIL", $sformatf("ETH%0d Transmitted payload byte %0h, but Golden Queue is empty!", id+1, act_item.payload[i]))
                end
            end
            eth_tx_pkt_ver_cnt[id]++;
            print_counts(id, "ETH");
        end
    endtask
    
    task process_uart_tx(int id);
        tx_uart act_item;
        bit [8:0] expected_val;
        forever begin
            uart_tx_fifo[id].get(act_item);
            if (exp_uart_tx_q[id].size() > 0) begin
                expected_val = exp_uart_tx_q[id].pop_front();
                if (!compare_data($sformatf("UART%0d_TX_LINE", id+1), expected_val, act_item.data_in[8:0])) uart_tx_fail_cnt[id]++;
                uart_tx_ver_cnt[id]++;
                uart_tx_pkt_ver_cnt[id]++;
                print_counts(id, "UART");
            end else begin
                uart_tx_fail_cnt[id]++;
                `uvm_error("SCB_FAIL", $sformatf("UART%0d Transmitted a byte but the queue was empty! Data: %0h", id+1, act_item.data_in[8:0]))
            end
        end
    endtask

    task process_uart_rx(int id);
        tx_uart inj_item; 
        forever begin
            uart_rx_fifo[id].get(inj_item); 
            exp_uart_rx_q[id].push_back(inj_item.data_in[8:0]); 
            uart_rx_inj_cnt[id]++;
            uart_rx_pkt_inj_cnt[id]++;
            print_counts(id, "UART");
        end
    endtask

    function bit compare_data(string path, int exp, int act);
        if (exp == act) begin
             `uvm_info("SCB_PASS", $sformatf("[%s] Match! Expected: %0h | Actual: %0h", path, exp, act), UVM_HIGH)
             return 1'b1;
        end else begin
            `uvm_error("SCB_FAIL", $sformatf("[%s] MISMATCH! Expected: %0h | Actual: %0h", path, exp, act))
            return 1'b0;
        end
    endfunction

endclass

`endif