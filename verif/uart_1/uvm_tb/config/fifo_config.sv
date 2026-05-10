class fifo_config extends uvm_object;

  // UVM Factory Registration
  `uvm_object_utils(fifo_config)

  // Command Line Processor Handle
  uvm_cmdline_processor clp = uvm_cmdline_processor::get_inst();

  // ========================================
  // Configuration Variables
  // ========================================
  int num_fifo_packets;
  int watchdog_timer;
  real wr_freq;
  real rd_freq;

  // ========================================
  // Constructor & Command Line Parsing
  // ========================================
  function new(string name = "fifo_config");
    string arg_value;
    super.new(name);

    num_fifo_packets = 50; 
    watchdog_timer   = 99999999;
    num_fifo_packets = 50; 
    wr_freq = 100.0;
    rd_freq = 44.2;

    if (clp.get_arg_value("+num_fifo_packets=", arg_value)) begin
      num_fifo_packets = arg_value.atoi();
    end

    if (clp.get_arg_value("+wr_freq=", arg_value)) begin
      wr_freq = arg_value.atoreal();
    end
    if (clp.get_arg_value("+rd_freq=", arg_value)) begin
      rd_freq = arg_value.atoreal();
    end

    if (clp.get_arg_value("+num_fifo_packets=", arg_value)) begin
      num_fifo_packets = arg_value.atoi();
      `uvm_info("FIFO_CFG", $sformatf("CLI Override: num_fifo_packets = %0d", num_fifo_packets), UVM_NONE)
    end

    if (clp.get_arg_value("+watchdog_timer=", arg_value)) begin
      watchdog_timer = arg_value.atoi();
      `uvm_info("FIFO_CFG", $sformatf("CLI Override: watchdog_timer = %0d", watchdog_timer), UVM_NONE)
    end

  endfunction

endclass