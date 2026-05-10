class unified_base_test extends uvm_test;
  `uvm_component_utils(unified_base_test)

  unified_env  env;
  uart_config  cfg;

  function new(string name = "unified_base_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    env = unified_env::type_id::create("env", this);
    cfg = uart_config::type_id::create("cfg");
    
    cfg.num_uart_packets = 10; 
    if($value$plusargs("num_uart_packets=%d", cfg.num_uart_packets)) begin end
    
    // FIX: Set watchdog to 5,000,000 ns (5 ms) so it fails fast if hung
    cfg.watchdog_timer = 5000000; 

    uvm_config_db#(uart_config)::set(this, "*", "uart_cfg", cfg);

    // FIX: Override the Env's sequences with our synchronized static sequences!
    uvm_config_db#(uvm_object_wrapper)::set(this, "env.host_tx_agnt.sqncr.main_phase", "default_sequence", static_main_sequence::type_id::get());
    uvm_config_db#(uvm_object_wrapper)::set(this, "env.line_rx_agnt.sqncr.main_phase", "default_sequence", static_main_sequence::type_id::get());
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("UNIFIED_TEST", "Initializing Full-Duplex SoC Testbench...", UVM_NONE)
    #200; 
    `uvm_info("UNIFIED_TEST", "Hardware Reset Complete. Handing over to Env...", UVM_NONE)
    phase.drop_objection(this);
  endtask

endclass