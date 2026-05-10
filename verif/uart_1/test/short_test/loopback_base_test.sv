class loopback_base_test extends uvm_test;
  `uvm_component_utils(loopback_base_test)

  function new(string name = "loopback_base_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  loopback_env         env;
  uart_config          cfg;
  virtual uart_tx_intf tx_in_vif;

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // 1. Create the Config Object (Parses terminal +num_uart_packets)
    cfg = uart_config::type_id::create("cfg");

    // 2. Push it to the UVM Database
    uvm_config_db #(uart_config)::set(this, "*", "uart_cfg", cfg);
    
    // 3. Build the unified Loopback Environment
    env = loopback_env::type_id::create("env", this);
    
    // 4. Grab the TX interface (This now controls the whole system!)
    if (!uvm_config_db#(virtual uart_tx_intf)::get(this, "", "uart_tx_intf", tx_in_vif))
      `uvm_fatal("LOOPBACK_TEST", "Did not get uart_tx_intf")
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    // Print the massive combined topology!
    uvm_top.print_topology();
  endfunction

  // =========================================================================
  // Full System Hardware Reset Phase
  // =========================================================================
  virtual task reset_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("LOOPBACK_TEST", "Starting Full System Reset..", UVM_LOW)
    
    vif_init_zero(); 
    
    // Give both hardware modules a moment to stabilize
    repeat (10) @(posedge tx_in_vif.clk); 
    
    `uvm_info("LOOPBACK_TEST", "System Reset Complete.", UVM_LOW)
    phase.drop_objection(this);
  endtask 

  task vif_init_zero();
    // Initialize the TX driving pins. 
    // (RX serial data is driven by TX RTL, and config is tied in tb_top)
    tx_in_vif.data_in          <= '0; 
    tx_in_vif.parity_en        <= 1'b0;
    tx_in_vif.parity_odd_even  <= 1'b0;
    tx_in_vif.data_start_pulse <= 1'b0;
    
    tx_in_vif.baudrate         <= 32'd115200; 
    tx_in_vif.data_width       <= 4'd8;       
    tx_in_vif.baudrate_valid   <= 1'b0;
  endtask
  
endclass