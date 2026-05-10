`uvm_analysis_imp_decl(_rx_ingr)
`uvm_analysis_imp_decl(_rx_egrs)

class rx_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(rx_scoreboard)

  function new(string name="rx_scoreboard", uvm_component parent=null);
    super.new(name, parent);
  endfunction 

  uvm_analysis_imp_rx_ingr #(rx_uart, rx_scoreboard) ingr_imp_export;
  uvm_analysis_imp_rx_egrs #(rx_uart, rx_scoreboard) egrs_imp_export;

  rx_uart ingr_pkt_q[$]; 

  uvm_event    in_scb_evnt;
  uart_config  cfg;           

  int match, mismatch, pkt_count;
  string result_table; 

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ingr_imp_export = new ("ingr_imp_export", this);
    egrs_imp_export = new ("egrs_imp_export", this);
    in_scb_evnt     = uvm_event_pool::get_global("rx_scb_event"); 

    if(!uvm_config_db #(uart_config)::get(this, "", "uart_cfg", cfg))
      `uvm_warning("RX_SCB", "Could not get uart_cfg!")

    // Initialize the Table Header with the NEW Parity Column
    result_table = "\n";
    result_table = {result_table, "+-------+-------+----------+--------+----------+----------+---------+\n"};
    result_table = {result_table, "| Pkt # | Width | Baud     | Parity | Expected | Actual   | Status  |\n"};
    result_table = {result_table, "+-------+-------+----------+--------+----------+----------+---------+\n"};
  endfunction 

  virtual function void write_rx_ingr (rx_uart pkt);
    ingr_pkt_q.push_back(pkt);
  endfunction

  virtual function void write_rx_egrs (rx_uart act_pkt);
    rx_uart exp_pkt;
    string status_str;
    string parity_str; // Variable to hold our beautiful parity text
    
    pkt_count++;

    if (ingr_pkt_q.size() == 0) begin
      `uvm_error("RX_SCB", "Output received but no expected data in queue!")
      mismatch++;
      return;
    end
    
    exp_pkt = ingr_pkt_q.pop_front();
    
    if (exp_pkt.parity_en) begin
        parity_str = exp_pkt.parity_odd_even ? "Odd" : "Even";
    end else begin
        parity_str = "None";
    end

    // Check for match
    if (act_pkt.data_out === exp_pkt.data_in) begin
      match++;
      status_str = "PASS";
    end else begin
      mismatch++;
      status_str = "*FAIL*";
    end

    result_table = {result_table, $sformatf("| %-5d | %-5d | %-8d | %-6s | 0x%-6h | 0x%-6h | %-7s |\n", 
                    pkt_count, exp_pkt.data_width, exp_pkt.baudrate, parity_str, exp_pkt.data_in, act_pkt.data_out, status_str)};
  endfunction  

  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);
    if (cfg != null) begin
      wait(cfg.num_uart_packets == match + mismatch);
      in_scb_evnt.trigger();
    end
  endtask 

  virtual function void report_phase (uvm_phase phase);
    // Close out the table cleanly
    result_table = {result_table, "+-------+-------+----------+--------+----------+----------+---------+\n"};
    result_table = {result_table, $sformatf("| TOTAL | MATCH = %-2d                | MISMATCH = %-2d               |\n", match, mismatch)};
    result_table = {result_table, "+-------+---------------------------+-------------------------------+\n"};

    `uvm_info("RX_SCOREBOARD_SUMMARY", result_table, UVM_NONE)
  endfunction 

endclass