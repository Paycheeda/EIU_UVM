`uvm_analysis_imp_decl(_ingr)
`uvm_analysis_imp_decl(_egrs)

class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard)

  // Constructor Function
  function new(string name="scoreboard", uvm_component parent=null);
    super.new(name, parent);
  endfunction 

  uvm_analysis_imp_ingr #(tx_uart, scoreboard) ingr_imp_export;
  uvm_analysis_imp_egrs #(tx_uart, scoreboard) egrs_imp_export;

  tx_uart ingr_pkt_q[$]; 

  uvm_event    in_scb_evnt;
  uart_config  cfg;            

  int match, mismatch, pkt_count;
  string result_table; 

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    ingr_imp_export = new ("ingr_imp_export", this);
    egrs_imp_export = new ("egrs_imp_export", this);
    in_scb_evnt     = uvm_event_pool::get_global("ingr_scb_event");

    if(!uvm_config_db #(uart_config)::get(this, "", "uart_cfg", cfg))
      `uvm_warning("TX_SCB", "Could not get uart_cfg! Event trigger might not work.")

    // Initialize the Table Header
    result_table = "\n";
    result_table = {result_table, "+-------+-------+----------+--------+----------+----------+---------+\n"};
    result_table = {result_table, "| Pkt # | Width | Baud     | Parity | Expected | Actual   | Status  |\n"};
    result_table = {result_table, "+-------+-------+----------+--------+----------+----------+---------+\n"};
  endfunction 

  virtual function void write_ingr (tx_uart pkt);
    ingr_pkt_q.push_back(pkt);
  endfunction

  virtual function void write_egrs (tx_uart act_pkt);
    tx_uart exp_pkt;
    string status_str;
    string parity_str;
    
    pkt_count++;

    if (ingr_pkt_q.size() == 0) begin
      `uvm_error("TX_SCB", "Output received but no expected data in queue!")
      mismatch++;
      return;
    end
    
    exp_pkt = ingr_pkt_q.pop_front();

    // In TX, parity_odd_even == 1 is Even
    if (exp_pkt.parity_en) begin
        parity_str = exp_pkt.parity_odd_even ? "Even" : "Odd";
    end else begin
        parity_str = "None";
    end
    
    // ===================================================
    // Custom Dynamic TX Comparison Logic
    // ===================================================
    if (act_pkt.data_in === exp_pkt.data_in) begin
      
      if (exp_pkt.parity_en == 1'b1) begin
        if (act_pkt.sampled_parity === exp_pkt.expected_parity) begin
          match++;
          status_str = "PASS";
        end else begin
          display_mismatch_pkts(exp_pkt, act_pkt, "Parity Mismatch");
          mismatch++;
          status_str = "*FAIL*";
        end
      end else begin
        match++;
        status_str = "PASS";
      end
      
    end else begin
      display_mismatch_pkts(exp_pkt, act_pkt, "Data Payload Mismatch");
      mismatch++;
      status_str = "*FAIL*";
    end

    // Add row to the beautiful ASCII table
    result_table = {result_table, $sformatf("| %-5d | %-5d | %-8d | %-6s | 0x%-6h | 0x%-6h | %-7s |\n", 
                    pkt_count, exp_pkt.data_width, exp_pkt.baudrate, parity_str, exp_pkt.data_in, act_pkt.data_in, status_str)};
  endfunction  

  // ========================================
  // Main Phase Task
  // ========================================
  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);
    
    if (cfg != null) begin
      wait(cfg.num_uart_packets == match + mismatch);
      in_scb_evnt.trigger();
    end
  endtask 

  // ========================================
  // Report Phase
  // ========================================
  virtual function void report_phase (uvm_phase phase);
    result_table = {result_table, "+-------+-------+----------+--------+----------+----------+---------+\n"};
    result_table = {result_table, $sformatf("| TOTAL | MATCH = %-2d                | MISMATCH = %-2d               |\n", match, mismatch)};
    result_table = {result_table, "+-------+---------------------------+-------------------------------+\n"};

    // Print the final masterpiece!
    `uvm_info("TX_SCOREBOARD_SUMMARY", result_table, UVM_NONE)
  endfunction 

  // ========================================
  // Helper: Display Errors clearly
  // ========================================
  virtual function void display_mismatch_pkts(tx_uart exp_pkt, tx_uart act_pkt, string reason);
    string msg;
    msg = $sformatf("\n[TX SCOREBOARD ERROR] %s\n", reason);
    msg = {msg, "================================================================\n"};
    msg = {msg, $sformatf("EXPECTED: Data=0x%0h (Width: %0d), Parity_En=%0b, Parity_Bit=%0b\n", exp_pkt.data_in, exp_pkt.data_width, exp_pkt.parity_en, exp_pkt.expected_parity)};
    msg = {msg, $sformatf("ACTUAL  : Data=0x%0h (Width: %0d), Parity_Bit=%0b\n", act_pkt.data_in, act_pkt.data_width, act_pkt.sampled_parity)};
    `uvm_error("TX_SCB_MISMATCH", msg)
  endfunction  

endclass