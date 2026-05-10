class uart_config_item extends uvm_sequence_item;
  `uvm_object_utils(uart_config_item)

  // Configuration Variables
  rand bit [31:0] baudrate;
  rand bit        parity_en;
  rand bit        parity_odd_even;
  rand bit [3:0]  data_width;

  // Real-world Hardware Constraints
  // 1. Only allow standard baud rates supported by your RTL's clock divider
  constraint c_baudrate {
    baudrate inside {9600, 19200, 38400, 57600, 115200, 230400, 460800, 921600};
  }

  // 2. Your RTL parameters dictate max width is 9. Let's test standard 8 and 9.
  constraint c_data_width {
    data_width inside {4'd8, 4'd9};
  }

  function new(string name = "uart_config_item");
    super.new(name);
  endfunction

  virtual function string convert2string();
    return $sformatf("Baud: %0d | Width: %0d | Parity_EN: %0b | Odd/Even: %0b", 
                     baudrate, data_width, parity_en, parity_odd_even);
  endfunction
endclass