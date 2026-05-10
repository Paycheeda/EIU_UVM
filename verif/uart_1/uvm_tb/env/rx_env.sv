class rx_env extends uvm_env;
  `uvm_component_utils(rx_env)

  // =============================
  // Constructor Method
  // =============================
  function new(string name="rx_env", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  rx_inp_agent            ingr_agnt     ;
  rx_out_agent            egrs_agnt     ;
  rx_scoreboard           scrbrd        ;
  
  int                     wd_timer      ;
  uart_config             cfg           ; // Reusing the same config class!
  uvm_event               rx_scb_evnt   ; // Changed event name to avoid TX collision

  // =============================
  // Build Phase Method
  // =============================
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);    
    
    // Creating RX Agents and Scoreboard
    ingr_agnt   = rx_inp_agent::type_id::create("ingr_agnt", this);
    egrs_agnt   = rx_out_agent::type_id::create("egrs_agnt", this);
    scrbrd      = rx_scoreboard::type_id::create("scrbrd", this);
    rx_scb_evnt = uvm_event_pool::get_global("rx_scb_event"); // Must match rx_scoreboard!
    
    // Getting uart_config
    if(!uvm_config_db #(uart_config)::get(this, "*", "uart_cfg", cfg))
      `uvm_fatal("RX_ENV", "Failed to get uart_cfg from config database")
      
    // Implicit Call for rx_main_sequence to start automatically on the RX input sequencer
    uvm_config_db#(uvm_object_wrapper)::set(this, "ingr_agnt.sqncr.main_phase", "default_sequence", rx_main_sequence::type_id::get());
  endfunction  

  // =============================
  // Connect Phase Method
  // =============================
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    ingr_agnt.mntr.mon_analysis_port.connect(scrbrd.ingr_imp_export);
    egrs_agnt.mntr.mon_analysis_port.connect(scrbrd.egrs_imp_export);
  endfunction  

  // =============================
  // Main Phase Method
  // =============================
  virtual task main_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    `uvm_info("RX_ENV", "Starting main_phase.. ", UVM_MEDIUM)
    
    wd_timer = cfg.watchdog_timer; 

    fork
      begin
        #wd_timer;
        `uvm_error("RX_ENV", "wd_timer Timed out! Simulation hung.")
      end
      
      begin
        rx_scb_evnt.wait_trigger();
        #5000; 
        `uvm_info("RX_ENV", "Scoreboard Verification Complete..", UVM_MEDIUM)
      end
    join_any 
    
    `uvm_info("RX_ENV", "main_phase done.. ", UVM_MEDIUM)
    
    phase.drop_objection(this);
  endtask 

endclass