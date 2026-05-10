class rx_base_test extends uvm_test;
  `uvm_component_utils(rx_base_test)

  // =============================
  // Constructor Method
  // =============================
  function new(string name = "rx_base_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  // =============================
  // Component Handles
  // =============================
  rx_env       env;
  uart_config  cfg;
  
  // =============================
  // Virtual Interfaces
  // =============================
  virtual uart_rx_in_intf in_vif;

  // =============================
  // Build Phase Method
  // =============================
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // 1. Create the Config Object
    // NOTE: This automatically scans the terminal for +num_uart_packets= now!
    cfg = uart_config::type_id::create("cfg");
    
    // 2. Put it in the DB so Env and Sequences can see it
    uvm_config_db #(uart_config)::set(this, "*", "uart_cfg", cfg);
    
    // 3. Create the RX Environment
    env = rx_env::type_id::create("env", this);

    // 4. Get the virtual interface so we can initialize it to IDLE
    if (!uvm_config_db#(virtual uart_rx_in_intf)::get(this, "", "uart_rx_in_intf", in_vif))
      `uvm_fatal("RX_BASE_TEST", "Did not get uart_rx_in_intf")

  endfunction

  // =============================
  // End of Elaboration Phase
  // =============================
  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    // Prints your entire RX testbench hierarchy to the log!
    uvm_top.print_topology();
  endfunction

  // =============================
  // Reset Phase Method
  // =============================
  virtual task reset_phase(uvm_phase phase);
    phase.raise_objection(this);

    `uvm_info("RX_BASE_TEST", "Starting reset_phase..", UVM_MEDIUM)
    super.reset_phase(phase);
    
    vif_init_idle(); 
    
    `uvm_info("RX_BASE_TEST", "reset_phase done..", UVM_MEDIUM)
    repeat (100) @(posedge in_vif.clk); // Idle cycles to let reset settle
    
    phase.drop_objection(this);
  endtask 

  // ==============================================
  // Initialize all driving inputs to safe states
  // ==============================================
  task vif_init_idle();
    in_vif.data_rx         <= 1'b1; // CRITICAL: UART Serial Idle is HIGH!
    in_vif.parity_en       <= 1'b0;
    in_vif.parity_odd_even <= 1'b0;
    
    // FIX: Add dynamic config pins and remove the phantom data_start_pulse!
    in_vif.baudrate        <= 32'd0;
    in_vif.baudrate_valid  <= 1'b0;
    in_vif.data_width      <= 4'd0;
  endtask

endclass