`ifndef KWR_SCOREBOARD_SV
`define KWR_SCOREBOARD_SV

class kwr_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(kwr_scoreboard)

    // FIFOs to receive transactions from the monitors
    uvm_tlm_analysis_fifo #(bkp_item) bkp_fifo;
    uvm_tlm_analysis_fifo #(kwr_item) kwr_fifo;

    // The Predictor Queue (Holds the "Expected" Golden Transactions)
    kwr_item exp_queue[$];

    // String buffer for generating the final table report
    string report_table;
    int total_transactions = 0;
    int passed_transactions = 0;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        bkp_fifo = new("bkp_fifo", this);
        kwr_fifo = new("kwr_fifo", this);
        
        // Initialize the table header
        report_table = "\n=====================================================================================================\n";
        report_table = {report_table, "| KERNEL WRITE ROUTING SUMMARY                                                                      |\n"};
        report_table = {report_table, "=====================================================================================================\n"};
        report_table = {report_table, "| BKP ADDR | TARGET FIFO | EXPECTED PAYLOAD | ACTUAL PAYLOAD | WRITE EN | SEND CMD | STATUS     |\n"};
        report_table = {report_table, "=====================================================================================================\n"};
    endfunction

    task run_phase(uvm_phase phase);
        fork
            process_bkp_traffic(); // The Predictor
            process_kwr_traffic(); // The Comparator
        join
    endtask

    // Prints the final table when the simulation finishes
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        report_table = {report_table, "=====================================================================================================\n"};
        report_table = {report_table, $sformatf("| TOTAL ROUTED: %-4d | SUCCESSFUL ROUTES: %-4d                                                     |\n", total_transactions, passed_transactions)};
        report_table = {report_table, "=====================================================================================================\n"};
        `uvm_info("KWR_REPORT", report_table, UVM_LOW)
    endfunction

    // =========================================================
    // THREAD 1: THE PREDICTOR (Simulate Demux/Routing Logic)
    // =========================================================
    task process_bkp_traffic();
        bkp_item req;
        kwr_item exp_item;
        
        forever begin
            bkp_fifo.get(req);
            
            // Filter: Only process valid writes meant for addresses 41-47
            if (req.bkp_card_id == req.fpga_card_id && req.bkp_data_dir && (req.bkp_address >= 41 && req.bkp_address <= 47)) begin
                
                exp_item = kwr_item::type_id::create("exp_item");
                
                // Store the original address for logging purposes (not part of the base item)
                exp_item.set_name($sformatf("%0d", req.bkp_address)); 
                
                // Route and slice the data exactly like the RTL
                case(req.bkp_address)
                    // UART Logic (9-bit payload, bit 9 is Send Command)
                    6'd41: begin exp_item.target = UART1; exp_item.payload = req.bkp_data[8:0]; exp_item.is_send = req.bkp_data[9]; exp_item.is_write = ~req.bkp_data[9]; end
                    6'd42: begin exp_item.target = UART2; exp_item.payload = req.bkp_data[8:0]; exp_item.is_send = req.bkp_data[9]; exp_item.is_write = ~req.bkp_data[9]; end
                    6'd43: begin exp_item.target = UART3; exp_item.payload = req.bkp_data[8:0]; exp_item.is_send = req.bkp_data[9]; exp_item.is_write = ~req.bkp_data[9]; end
                    
                    // ETH Logic (8-bit payload, bit 8 is Send Command)
                    6'd44: begin exp_item.target = ETH1; exp_item.payload = req.bkp_data[7:0]; exp_item.is_send = req.bkp_data[8]; exp_item.is_write = ~req.bkp_data[8]; end
                    6'd45: begin exp_item.target = ETH2; exp_item.payload = req.bkp_data[7:0]; exp_item.is_send = req.bkp_data[8]; exp_item.is_write = ~req.bkp_data[8]; end
                    6'd46: begin exp_item.target = ETH3; exp_item.payload = req.bkp_data[7:0]; exp_item.is_send = req.bkp_data[8]; exp_item.is_write = ~req.bkp_data[8]; end
                    6'd47: begin exp_item.target = ETH4; exp_item.payload = req.bkp_data[7:0]; exp_item.is_send = req.bkp_data[8]; exp_item.is_write = ~req.bkp_data[8]; end
                endcase
                
                // Push the golden prediction into the queue
                exp_queue.push_back(exp_item);
                
            end
        end
    endtask

    // =========================================================
    // THREAD 2: THE COMPARATOR (Check DUT vs Expected)
    // =========================================================
    task process_kwr_traffic();
        kwr_item act_item;
        kwr_item exp_item;
        bit match_fail;
        string exp_p_str;
        string act_p_str;
        
        forever begin
            kwr_fifo.get(act_item);
            
            // If we get an output but the queue is empty, the DUT is hallucinating data!
            if (exp_queue.size() == 0) begin
                `uvm_error("KWR_SCB_FATAL", $sformatf("DUT generated unexpected output! %s", act_item.convert2string()))
            end 
            else begin
                total_transactions++;
                match_fail = 0;
                
                // Pop the oldest prediction off the queue
                exp_item = exp_queue.pop_front();
                
                // Compare every field (Ignore payload if it's a Send Only command)
                if (act_item.target !== exp_item.target) match_fail = 1;
                else if (exp_item.is_write && (act_item.payload !== exp_item.payload)) match_fail = 1;
                else if (act_item.is_write !== exp_item.is_write) match_fail = 1;
                else if (act_item.is_send !== exp_item.is_send) match_fail = 1;
                
                // Create clean strings for the table
                if (exp_item.is_write) begin
                    exp_p_str = $sformatf("'h%-12x", exp_item.payload);
                    act_p_str = $sformatf("'h%-10x", act_item.payload);
                end else begin
                    // If it's a send command, the hardware payload is ignored!
                    exp_p_str = "IGNORED         "; 
                    act_p_str = "IGNORED     ";
                end

                // Format the row for the table
                if (match_fail) begin
                    report_table = {report_table, $sformatf("| Addr %-3s | %-11s | %-16s | %-14s | %-8b | %-8b | ❌ MISMATCH |\n", 
                                    exp_item.get_name(), exp_item.target.name(), exp_p_str, act_p_str, act_item.is_write, act_item.is_send)};
                    `uvm_error("KWR_MISMATCH", "Routing Error Detected! See final report for details.")
                end 
                else begin
                    passed_transactions++;
                    report_table = {report_table, $sformatf("| Addr %-3s | %-11s | %-16s | %-14s | %-8b | %-8b | ✅ PASS     |\n", 
                                    exp_item.get_name(), exp_item.target.name(), exp_p_str, act_p_str, act_item.is_write, act_item.is_send)};
                end
            end
        end
    endtask

endclass

`endif