class uart_config extends uvm_object;

  // UVM Factory Registration
  `uvm_object_utils(uart_config)

  // Command Line Processor Handle
  uvm_cmdline_processor clp = uvm_cmdline_processor::get_inst();

  // ========================================
  // Configuration Variables
  // ========================================
  
  // Base Test Controls
  int num_uart_packets;
  int watchdog_timer;

  // Protocol Controls (Useful for future test variations)
  int baud_rate;

  // Future Scalability (Architecture toggles for when you add more IP)
  bit has_uart_rx;
  bit has_ethernet;

  // ========================================
  // Constructor & Command Line Parsing
  // ========================================
  function new(string name = "uart_config");
    string arg_value;
    super.new(name);

    // 1. Set Safe Default Values
    num_uart_packets = 50; 
    watchdog_timer   = 99999999;
    baud_rate        = 115200;
    has_uart_rx      = 1'b0; // Disabled by default
    has_ethernet     = 1'b0; // Disabled by default

    // 2. Override with Command Line Arguments (+plusargs)
    if (clp.get_arg_value("+num_uart_packets=", arg_value)) begin
      num_uart_packets = arg_value.atoi();
      `uvm_info("UART_CFG", $sformatf("CLI Override: num_uart_packets = %0d", num_uart_packets), UVM_NONE)
    end

    if (clp.get_arg_value("+watchdog_timer=", arg_value)) begin
      watchdog_timer = arg_value.atoi();
      `uvm_info("UART_CFG", $sformatf("CLI Override: watchdog_timer = %0d", watchdog_timer), UVM_NONE)
    end

    if (clp.get_arg_value("+baud_rate=", arg_value)) begin
      baud_rate = arg_value.atoi();
      `uvm_info("UART_CFG", $sformatf("CLI Override: baud_rate = %0d", baud_rate), UVM_NONE)
    end

    // Toggles for your future agents!
    if (clp.get_arg_value("+has_uart_rx=", arg_value)) begin
      has_uart_rx = arg_value.atoi();
      `uvm_info("UART_CFG", $sformatf("CLI Override: has_uart_rx enabled!"), UVM_NONE)
    end
    
    if (clp.get_arg_value("+has_ethernet=", arg_value)) begin
      has_ethernet = arg_value.atoi();
      `uvm_info("UART_CFG", $sformatf("CLI Override: has_ethernet enabled!"), UVM_NONE)
    end

  endfunction // new

endclass // uart_config