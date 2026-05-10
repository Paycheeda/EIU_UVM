class rx_short_test extends rx_base_test;
  `uvm_component_utils(rx_short_test)
  
  function new(string name = "rx_short_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
     super.build_phase(phase);
     `uvm_info("RX_SHORT_TEST", "Starting RX short_test... overriding config.", UVM_MEDIUM)
     
     // Override the config to run super fast!
     cfg.num_uart_packets = 5;
  endfunction

endclass