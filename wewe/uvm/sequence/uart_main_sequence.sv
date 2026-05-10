class uart_main_sequence extends uvm_sequence #(tx_uart);
  `uvm_object_utils(uart_main_sequence)
 
  uart_tx_sequence   tx_seq;
  
  // Assuming you create a config class for your UART project
  // that holds a variable like 'num_uart_packets'
  uart_config        cfg;  

  function new (string name = "uart_main_sequence");
    super.new(name);    
  endfunction

  // Get the configuration from the database
  virtual task pre_start();
    if (!uvm_config_db#(uart_config)::get(get_sequencer(), "", "uart_cfg", cfg))
      `uvm_fatal("UART_MAIN_SEQ", "Did not get uart_config! Make sure it is set in the test.")
  endtask : pre_start

  virtual task body();
    `uvm_info("UART_MAIN_SEQ", $sformatf("Starting tx_seq for %0d packets..", cfg.num_uart_packets), UVM_MEDIUM)

    // 1. Create the worker sequence
    tx_seq = uart_tx_sequence::type_id::create("tx_seq");
    
    // 2. Pass the configuration data to the worker sequence
    tx_seq.num_packets = cfg.num_uart_packets; 
    
    // 3. Start it!
    tx_seq.start(get_sequencer());
    
    `uvm_info("UART_MAIN_SEQ", "tx_seq finished successfully.", UVM_MEDIUM)
  endtask 
    
endclass // uart_main_sequence