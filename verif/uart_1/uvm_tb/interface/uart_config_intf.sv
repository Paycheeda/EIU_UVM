`ifndef UART_CONFIG_INTF_SV
`define UART_CONFIG_INTF_SV

interface uart_config_intf (
    input logic clk );

  // Global
  logic        rst_n;

  // UART Configuration Registers
  logic [31:0] baudrate;
  logic        parity_en;
  logic        parity_odd_even;
  logic [3:0]  data_width;
  
  // The trigger pulse to latch the new settings
  logic        config_done_pulse;

  // --- NEW: Hardware Stat Trackers ---
    logic [10:0] hw_rx_corrupt_bytes;
    logic [10:0] hw_rx_valid_bytes;

    logic uart_tx_busy;
    logic uart_rx_busy;

endinterface : uart_config_intf

`endif