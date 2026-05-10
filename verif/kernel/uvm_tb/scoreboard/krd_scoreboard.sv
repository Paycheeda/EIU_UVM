`ifndef KRD_SCOREBOARD_SV
`define KRD_SCOREBOARD_SV

class krd_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(krd_scoreboard)

    uvm_tlm_analysis_fifo #(bkp_item) read_fifo;
    uvm_tlm_analysis_fifo #(krd_item) inject_fifo; 

    bit [8:0] uart1_q[$]; bit [7:0] eth1_q[$];
    int exp_vbc_uart1 = 0, exp_vbc_eth1  = 0;
    krd_item latest_state;

    typedef struct {
        time         timestamp;
        string       event_type; 
        string       target;     
        string       action;     
        string       latency;    
        string       expected;   
        string       actual;     
        string       status;     
    } ledger_t;
    
    ledger_t story_ledger[$];

    int total_reads = 0, successful_reads = 0;

    function new(string name, uvm_component parent); super.new(name, parent); endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        read_fifo = new("read_fifo", this);
        inject_fifo = new("inject_fifo", this);
        latest_state = krd_item::type_id::create("latest_state");
    endfunction

    task run_phase(uvm_phase phase);
        bkp_item act_item;
        krd_item inj_item;
        logic [11:0] exp_data;
        
        int diff;
        string stat;

        fork
            forever begin
                inject_fifo.get(inj_item);
                latest_state.copy(inj_item); 
                
                if (inj_item.rx_valid_byte_count_uart1 != exp_vbc_uart1) begin
                    diff = inj_item.rx_valid_byte_count_uart1 - exp_vbc_uart1;
                    if (diff < 0) diff += 2048; 
                    
                    repeat(diff) uart1_q.push_back(inj_item.rx_fifo_data_out_uart1);
                    story_ledger.push_back('{ $time, "WRITE (NET)", "UART1 FIFO", $sformatf("Injected %0d pkts ('h%0h)", diff, inj_item.rx_fifo_data_out_uart1), "--", "--", "--", "--" });
                    exp_vbc_uart1 = inj_item.rx_valid_byte_count_uart1;
                end

                if (inj_item.rx_eth_valid_bytes_eth1 != exp_vbc_eth1) begin
                    diff = inj_item.rx_eth_valid_bytes_eth1 - exp_vbc_eth1;
                    if (diff < 0) diff += 2048; 
                    
                    repeat(diff) eth1_q.push_back(inj_item.rx_fifo_data_out_eth1);
                    story_ledger.push_back('{ $time, "WRITE (NET)", "ETH1 FIFO", $sformatf("Injected %0d pkts ('h%0h)", diff, inj_item.rx_fifo_data_out_eth1), "--", "--", "--", "--" });
                    exp_vbc_eth1 = inj_item.rx_eth_valid_bytes_eth1;
                end
            end

            forever begin
                read_fifo.get(act_item);
                if (act_item.bkp_address >= 0 && act_item.bkp_address <= 24) begin
                    total_reads++;
                    exp_data = calculate_expected(act_item.bkp_address);
                    
                    stat = (act_item.bkp_data === exp_data) ? "MATCH" : "MISMATCH";
                    if (stat == "MATCH") successful_reads++;
                    
                    story_ledger.push_back('{ 
                        $time, "READ (CPU)", get_target_name(act_item.bkp_address), "CPU Polled Bus", 
                        get_latency(act_item.bkp_address), $sformatf("'h%0h", exp_data), $sformatf("'h%0h", act_item.bkp_data), stat 
                    });
                end
            end
        join_none
    endtask

    function logic [11:0] calculate_expected(int addr);
        logic [11:0] data = 12'd0;
        case(addr)
            0: data = (uart1_q.size() > 0) ? {3'd0, uart1_q.pop_front()} : 12'h0;
            1: data = {1'b0, exp_vbc_uart1[10:0]}; // UART1 remains Cumulative Count
            9: data = (eth1_q.size() > 0)  ? {4'd0, eth1_q.pop_front()}  : 12'h0;
            
            // THE FIX: ETH1 now tracks Dynamic Occupancy (Current packets stored)
            10: data = {1'b0, 11'(eth1_q.size())}; 
            
            22: data = 12'hAA8 | {10'd0, latest_state.tx_fifo_empty_eth4, latest_state.tx_fifo_full_eth4};
            23: data = {latest_state.tx_data_sent_eth3, latest_state.tx_data_sent_eth2, latest_state.tx_data_sent_eth1, latest_state.tx_data_sent_uart3, latest_state.tx_data_sent_uart2, latest_state.tx_data_sent_uart1, latest_state.tx_fifo_empty_eth_nrz, latest_state.tx_fifo_full_eth_nrz, 4'hA};
        endcase
        return data;
    endfunction

    function string get_target_name(int addr);
        case(addr)
            0: return "UART1 FIFO"; 1: return "UART1 V_CNT"; 2: return "UART1 C_CNT";
            9: return "ETH1 FIFO"; 10: return "ETH1 V_CNT"; 11: return "ETH1 C_CNT";
            22: return "RX EMP/FULL"; 23: return "TX SENT FLG";
            default: return $sformatf("ADDR_%0d", addr);
        endcase
    endfunction

    function string get_latency(int addr);
        if (addr == 0 || addr == 3 || addr == 6 || addr == 9 || addr == 12 || addr == 15 || addr == 18) return "6 Clocks";
        return "3 Clocks";
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        $display("\n===================================================================================================================================");
        $display("|                                             THE KERNEL READ MASTER STORY LEDGER                                             |");
        $display("===================================================================================================================================");
        $display("| TIME (ns) | EVENT TYPE  | TARGET REG  | ACTION / DESC                | LATENCY  | EXPECTED (THOUGHT) | ACTUAL (GOT) | STATUS   |");
        $display("===================================================================================================================================");
        
        foreach(story_ledger[i]) begin
            $display("| %-9t | %-11s | %-11s | %-28s | %-8s | %-18s | %-12s | %-8s |",
                story_ledger[i].timestamp, story_ledger[i].event_type, story_ledger[i].target, 
                story_ledger[i].action, story_ledger[i].latency, story_ledger[i].expected, 
                story_ledger[i].actual, story_ledger[i].status);
        end
        
        $display("===================================================================================================================================");
        $display("| TOTAL READS: %-4d | PERFECT MATCHES: %-4d | RTL BUGS CAUGHT: %-4d                                                       |", total_reads, successful_reads, (total_reads - successful_reads));
        $display("===================================================================================================================================\n");
    endfunction
endclass
`endif