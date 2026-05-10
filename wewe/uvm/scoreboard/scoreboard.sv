// Implementation ports macros
`uvm_analysis_imp_decl(_ingr)
`uvm_analysis_imp_decl(_egrs)

class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard)

  // Constructor Function
  function new(string name="scoreboard", uvm_component parent=null);
    super.new(name, parent);
  endfunction 

  // Both ports now accept the EXACT same tx_uart packet type!
  uvm_analysis_imp_ingr #(tx_uart, scoreboard) ingr_imp_export;
  uvm_analysis_imp_egrs #(tx_uart, scoreboard) egrs_imp_export;

  // Queue to hold the expected packets from the input monitor
  tx_uart ingr_pkt_q[$]; 

  uvm_event     in_scb_evnt;
  uart_config   cfg;           // Assuming you made a uart config object

  int match, mismatch, ap_pp_ingr_pkt_cnt;

  // ============================================
  // Create implementation ports in build phase
  // ============================================
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    ingr_imp_export = new ("ingr_imp_export", this);
    egrs_imp_export = new ("egrs_imp_export", this);
    in_scb_evnt     = uvm_event_pool::get_global("ingr_scb_event");

    // Get the UART config to know how many packets to expect
    if(!uvm_config_db #(uart_config)::get(this, "", "uart_cfg", cfg))
      `uvm_warning("SCB", "Could not get uart_cfg! Event trigger might not work.")
  endfunction 

  // ===========================================
  // write_ingr (From Input Monitor)
  // ===========================================
  virtual function void write_ingr (tx_uart pkt);
    tx_uart exp_pkt;
    
    // Always clone the packet before pushing to a queue to avoid memory overwrites
    $cast(exp_pkt, pkt.clone()); 
    
    // Just push it! No math needed since expected_parity was calculated in post_randomize
    ingr_pkt_q.push_back(exp_pkt);
    ap_pp_ingr_pkt_cnt++;
  endfunction

  // =========================================
  // write_egrs (From Output Monitor)
  // =========================================
  virtual function void write_egrs (tx_uart act_pkt);
    tx_uart exp_pkt;
    
    if (ingr_pkt_q.size() == 0) begin
      `uvm_error("SCB", "Output received but no expected data in queue!")
      mismatch++;
      return;
    end
    
    exp_pkt = ingr_pkt_q.pop_front();
    
    // Custom UART Comparison Logic
    if (act_pkt.data_in === exp_pkt.data_in) begin
      
      // Data matched! Now let's check parity ONLY if it was enabled for this packet
      if (exp_pkt.parity_en == 1'b1) begin
        if (act_pkt.sampled_parity === exp_pkt.expected_parity) begin
          `uvm_info("SCB", $sformatf("PASS! Data (%0h) and Parity (%0b) Matched", act_pkt.data_in, act_pkt.sampled_parity), UVM_HIGH)
          match++;
        end else begin
          display_mismatch_pkts(exp_pkt, act_pkt, "Parity Mismatch");
          mismatch++;
        end
      end else begin
        `uvm_info("SCB", $sformatf("PASS! Data (%0h) Matched (Parity Disabled)", act_pkt.data_in), UVM_HIGH)
        match++;
      end
      
    end else begin
      display_mismatch_pkts(exp_pkt, act_pkt, "Data Payload Mismatch");
      mismatch++;
    end
  endfunction  

  // ========================================
  // Main Phase Task
  // ========================================
  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);
    
    if (cfg != null) begin
      // Wait for all packets to be processed
      wait(cfg.num_uart_packets == match + mismatch);
      in_scb_evnt.trigger();
    end
  endtask 

  // ========================================
  // Report Phase
  // ========================================
  virtual function void report_phase (uvm_phase phase);
    `uvm_info("SCB", "==================================================", UVM_NONE)
    `uvm_info("SCB", $sformatf(" SCOREBOARD RESULTS: Matched=%0d, Mismatched=%0d", match, mismatch), UVM_NONE)
    `uvm_info("SCB", "==================================================", UVM_NONE)
  endfunction 

  // ========================================
  // Helper: Display Errors clearly
  // ========================================
  virtual function void display_mismatch_pkts(tx_uart exp_pkt, tx_uart act_pkt, string reason);
    string msg;
    msg = $sformatf("\n[SCOREBOARD ERROR] %s\n", reason);
    msg = {msg, "================================================================\n"};
    msg = {msg, $sformatf("EXPECTED: Data=%0h, Parity_En=%0b, Parity_Bit=%0b\n", exp_pkt.data_in, exp_pkt.parity_en, exp_pkt.expected_parity)};
    msg = {msg, $sformatf("ACTUAL  : Data=%0h, Parity_Bit=%0b\n", act_pkt.data_in, act_pkt.sampled_parity)};
    `uvm_error("SCB_MISMATCH", msg)
  endfunction  

endclass // scoreboard