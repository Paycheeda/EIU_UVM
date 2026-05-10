class unified_env extends uvm_env;
  `uvm_component_utils(unified_env)

  // =============================
  // Constructor Method
  // =============================
  function new(string name="unified_env", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  host_tx_agent  host_tx_agnt; // Active  (Drives CPU bus)
  line_tx_agent  line_tx_agnt; // Passive (Reads TX wire)
  
  line_rx_agent  line_rx_agnt; // Active  (Drives RX wire)
  host_rx_agent  host_rx_agnt; // Passive (Reads CPU bus)

  // =============================
  // 2. The Master Scoreboard
  // =============================
  unified_scoreboard scrbrd;
  
  // =============================
  // 3. Utils
  // =============================
  uart_config  cfg;
  int          wd_timer;
  uvm_event    unified_evnt;

  // =============================
  // Build Phase Method
  // =============================
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    uvm_config_db#(uvm_active_passive_enum)::set(this, "line_tx_agnt", "is_active", UVM_PASSIVE);
    uvm_config_db#(uvm_active_passive_enum)::set(this, "host_rx_agnt", "is_active", UVM_PASSIVE);

    host_tx_agnt = host_tx_agent::type_id::create("host_tx_agnt", this);
    line_tx_agnt = line_tx_agent::type_id::create("line_tx_agnt", this);
    line_rx_agnt = line_rx_agent::type_id::create("line_rx_agnt", this);
    host_rx_agnt = host_rx_agent::type_id::create("host_rx_agnt", this);

    scrbrd = unified_scoreboard::type_id::create("scrbrd", this);
    unified_evnt = uvm_event_pool::get_global("unified_scb_event");

    if(!uvm_config_db #(uart_config)::get(this, "*", "uart_cfg", cfg))
      `uvm_fatal("UNIFIED_ENV", "Failed to get uart_cfg from config database")

  endfunction  

  // =============================
  // Connect Phase Method
  // =============================
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    host_tx_agnt.mntr.mon_analysis_port.connect(scrbrd.host_tx_export); // Expected
    line_tx_agnt.mntr.mon_analysis_port.connect(scrbrd.line_tx_export); // Actual
    
    line_rx_agnt.mntr.mon_analysis_port.connect(scrbrd.line_rx_export); // Expected
    host_rx_agnt.mntr.mon_analysis_port.connect(scrbrd.host_rx_export); // Actual
    
  endfunction  

  // =============================
  // Main Phase Method
  // =============================
  virtual task main_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    `uvm_info("UNIFIED_ENV", "Starting Full-Duplex SoC Verification.. ", UVM_MEDIUM)
    wd_timer = cfg.watchdog_timer; 

    fork
      begin
        #wd_timer;
        `uvm_error("UNIFIED_ENV", "Watchdog Timed out! A state machine is hung.")
      end
      begin
        unified_evnt.wait_trigger();
        #15000; // Let the final bits settle out of both TX and RX paths
        `uvm_info("UNIFIED_ENV", "Unified Verification Complete!", UVM_NONE)
      end
    join_any 
    
    phase.drop_objection(this);
  endtask 

endclass