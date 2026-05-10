class loopback_uartfifo_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(loopback_uartfifo_scoreboard)

  uvm_tlm_analysis_fifo #(fifo_item)        tx_fifo;
  uvm_tlm_analysis_fifo #(fifo_item)        rx_fifo;
  uvm_tlm_analysis_fifo #(uart_config_item) cfg_fifo;

  int current_data_width = 8;
  bit current_parity_en  = 0;

  int match_cnt    = 0;
  int mismatch_cnt = 0;
  
  // --- NEW: Negative Testing Trackers ---
  int correctly_dropped_cnt = 0;
  int last_corrupt_cnt      = 0;

  // ==========================================
  // MISMATCH LOGGING INFRASTRUCTURE
  // ==========================================
  typedef struct {
    bit [8:0] expected_val;
    bit [8:0] actual_val;
    int       data_width;
  } mismatch_record_t;

  mismatch_record_t mismatch_log[$]; 

  function new(string name = "loopback_uartfifo_scoreboard", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual uart_config_intf cfg_vif;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tx_fifo  = new("tx_fifo", this);
    rx_fifo  = new("rx_fifo", this);
    cfg_fifo = new("cfg_fifo", this);
    
    if (!uvm_config_db#(virtual uart_config_intf)::get(this, "", "cfg_vif", cfg_vif))
      `uvm_fatal("SCB", "Could not get virtual uart_config_intf")
  endfunction

  virtual task run_phase(uvm_phase phase);
    fork
      // Config Tracker Thread
      forever begin
        uart_config_item cfg_item;
        cfg_fifo.get(cfg_item);
        current_data_width = cfg_item.data_width;
        current_parity_en  = cfg_item.parity_en;
        `uvm_info("SCB", $sformatf("Scoreboard updated internal model: Width=%0d, Parity=%0b", 
                  current_data_width, current_parity_en), UVM_MEDIUM)
      end

      // Data Comparison Thread
      forever begin
        fifo_item tx_item, rx_item;
        bit [8:0] expected_data, actual_data, mask;
        mismatch_record_t new_error; 

        // Wait for a packet to enter the hardware
        tx_fifo.get(tx_item);

        // ---------------------------------------------------------
        // THE FIX: THE "JOIN_ANY" RACE CONDITION
        // ---------------------------------------------------------
        // We isolate this in a block so `disable fork` doesn't kill our Config Thread
        fork begin : isolated_process
          fork
            // THREAD A: Positive Test (Wait for RX FIFO)
            begin : positive_test
              rx_fifo.get(rx_item);
              
              mask = (1 << current_data_width) - 1;
              expected_data = tx_item.data & mask;
              actual_data   = rx_item.data & mask;

              if (expected_data === actual_data) begin
                match_cnt++;
              end else begin
                mismatch_cnt++;
                new_error.expected_val = expected_data;
                new_error.actual_val   = actual_data;
                new_error.data_width   = current_data_width;
                mismatch_log.push_back(new_error);
                `uvm_error("SCB_MISMATCH", $sformatf("\033[1;31m >>> DATA MISMATCH! Expected: 0x%0h | Actual: 0x%0h (Width: %0d) <<<\033[0m", 
                           expected_data, actual_data, current_data_width))
              end
            end
            
            // THREAD B: Negative Test (Wait for RTL Error Flag)
            begin : negative_test
              wait(cfg_vif.hw_rx_corrupt_bytes > last_corrupt_cnt);
              correctly_dropped_cnt++;
              last_corrupt_cnt = cfg_vif.hw_rx_corrupt_bytes;
              `uvm_info("SCB", "\033[1;32m [NEGATIVE TEST PASSED] Packet destroyed on the wire and cleanly dropped by RTL! \033[0m", UVM_LOW)
            end
            
          join_any
          // Instantly kill whichever thread is left hanging!
          disable fork; 
        end join 

      end
    join
  endtask

  // ==========================================
  // THE CONSOLIDATED REPORT
  // ==========================================
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);

    `uvm_info("SCB_SUMMARY", "\n+---------------------------------------+\n| UART LOOPBACK VERIFICATION SUMMARY    |\n+---------------------------------------+", UVM_NONE)
    `uvm_info("SCB_SUMMARY", $sformatf("| POSITIVE MATCHES   : %0d", match_cnt), UVM_NONE)
    `uvm_info("SCB_SUMMARY", $sformatf("| CORRECTLY DROPPED  : %0d", correctly_dropped_cnt), UVM_NONE)
    `uvm_info("SCB_SUMMARY", $sformatf("| MISMATCHES         : %0d", mismatch_cnt), UVM_NONE)
    `uvm_info("SCB_SUMMARY", $sformatf("| ITEMS LEFT IN TX   : %0d", tx_fifo.used()), UVM_NONE)
    `uvm_info("SCB_SUMMARY", "+---------------------------------------+", UVM_NONE)

    if (mismatch_log.size() > 0) begin
      `uvm_info("SCB_REPORT", "\n\033[1;31m=========================================\n          DETAILED MISMATCH LOG\n=========================================\033[0m", UVM_NONE)
      
      foreach (mismatch_log[i]) begin
        `uvm_info("SCB_REPORT", $sformatf(" Error [%0d] -> Width: %0d-bit | Expected: 0x%0h | Actual: 0x%0h", 
                  i+1, 
                  mismatch_log[i].data_width, 
                  mismatch_log[i].expected_val, 
                  mismatch_log[i].actual_val), UVM_NONE)
      end
      
      `uvm_info("SCB_REPORT", "\033[1;31m=========================================\033[0m\n", UVM_NONE)
    end
    
  endfunction
endclass