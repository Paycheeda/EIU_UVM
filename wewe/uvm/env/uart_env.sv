class uart_env extends uvm_env;
  `uvm_component_utils(uart_env)

  // =============================
  // Constructor Method
  // =============================
  function new(string name="uart_env", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  // Internal Signals and Handles Declaration
  inp_agent               ingr_agnt     ;
  out_agent               egrs_agnt     ;
  scoreboard              scrbrd        ;
  
  int                     wd_timer      ;
  uart_config             cfg           ; // Changed to uart_config
  uvm_event               in_scb_evnt   ;

  // =============================
  // Build Phase Method
  // =============================
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);    
    
    // Creating Agents and Scoreboard
    ingr_agnt   = inp_agent::type_id::create("ingr_agnt", this);
    egrs_agnt   = out_agent::type_id::create("egrs_agnt", this);
    scrbrd      = scoreboard::type_id::create("scrbrd", this);
    in_scb_evnt = uvm_event_pool::get_global("ingr_scb_event");
    
    // Getting uart_config
    if(!uvm_config_db #(uart_config)::get(this, "*", "uart_cfg", cfg))
      `uvm_fatal("UART_ENV", "Failed to get uart_cfg from config database")
      
    // Implicit Call for uart_main_sequence to start automatically on the input sequencer
    uvm_config_db#(uvm_object_wrapper)::set(this, "ingr_agnt.sqncr.main_phase", "default_sequence", uart_main_sequence::type_id::get());
  endfunction  

  // =============================
  // Connect Phase Method
  // =============================
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // Connecting monitor analysis ports to scoreboard analysis exports
    ingr_agnt.mntr.mon_analysis_port.connect(scrbrd.ingr_imp_export);
    egrs_agnt.mntr.mon_analysis_port.connect(scrbrd.egrs_imp_export);
  endfunction  

  // =============================
  // Main Phase Method
  // =============================
  virtual task main_phase(uvm_phase phase);
    // Raise objection so the simulation doesn't end immediately
    phase.raise_objection(this);
    
    `uvm_info("UART_ENV", "Starting main_phase.. ", UVM_MEDIUM)
    
    // UART takes a long simulation time. Keep this high!
    wd_timer = cfg.watchdog_timer; 

    fork
      // Thread 1: Watchdog Timeout
      begin
        #wd_timer;
        `uvm_error("UART_ENV", "wd_timer Timed out! Simulation hung.")
      end
      
      // Thread 2: Normal Completion
      begin
        in_scb_evnt.wait_trigger();
        #5000; // Let the final waveforms settle out on the serial line
        `uvm_info("UART_ENV", "Scoreboard Verification Complete..", UVM_MEDIUM)
      end
    join_any // If either thread finishes, move on and end the test
    
    `uvm_info("UART_ENV", "main_phase done.. ", UVM_MEDIUM)
    
    // Drop objection to allow the simulation to finish gracefully
    phase.drop_objection(this);
  endtask 

endclass