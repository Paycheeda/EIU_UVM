class uart_short_test extends uart_base_test;
  `uvm_component_utils(uart_short_test)
  
  function new(string name = "uart_short_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
     super.build_phase(phase);
     `uvm_info("UART_SHORT_TEST", "Starting UART short_test... overriding config.", UVM_MEDIUM)
     cfg.num_uart_packets = 5;
  endfunction
endclass
