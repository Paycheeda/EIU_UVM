// 1. Compile for the MAXIMUM physical width (9)
`ifndef UART_WIDTH
  `define UART_WIDTH 9 
`endif

`include "uvm_macros.svh"
import uvm_pkg::*;
import uart_pkg::*; 

module tb_top_loopback;
  bit clk;
  bit rst_n; 

  // ========================================================
  // 1. INSTANTIATE ALL FOUR INTERFACES
  // ========================================================
  // TX Interfaces
  uart_tx_intf     tx_in_vif  (.clk(clk));
  uart_out_intf    tx_out_vif (.clk(clk));

  // RX Interfaces
  uart_rx_in_intf  rx_in_vif  (.clk(clk));
  uart_rx_out_intf rx_out_vif (.clk(clk));

  // Global Reset
  assign tx_in_vif.rst_n = rst_n;
  assign rx_in_vif.rst_n = rst_n;

  // ========================================================
  // 2. THE PHYSICAL LOOPBACK CONNECTION!
  // ========================================================
  // Connect the physical serial transmit wire directly to the receive wire
  assign rx_in_vif.data_rx = tx_out_vif.data_tx;

  // The TX Driver is injecting the random configuration (Baud, Parity, Width).
  // We must broadcast this same configuration to the RX interface so it knows how to listen!
  assign rx_in_vif.parity_en       = tx_in_vif.parity_en;
  assign rx_in_vif.parity_odd_even = tx_in_vif.parity_odd_even;
  assign rx_in_vif.baudrate        = tx_in_vif.baudrate;
  assign rx_in_vif.baudrate_valid  = tx_in_vif.baudrate_valid;
  assign rx_in_vif.data_width      = tx_in_vif.data_width;

  // ========================================================
  // 3. PASS CONFIGURATIONS TO THE OUTPUT MONITORS
  // ========================================================
  // Route TX config to TX Output Monitor
  assign tx_out_vif.parity_en       = tx_in_vif.parity_en;
  assign tx_out_vif.parity_odd_even = tx_in_vif.parity_odd_even;
  assign tx_out_vif.baudrate        = tx_in_vif.baudrate;
  assign tx_out_vif.baudrate_valid  = tx_in_vif.baudrate_valid;
  assign tx_out_vif.data_width      = tx_in_vif.data_width;

  // Route RX config to RX Output Monitor
  assign rx_out_vif.parity_en       = rx_in_vif.parity_en;
  assign rx_out_vif.parity_odd_even = rx_in_vif.parity_odd_even;
  assign rx_out_vif.baudrate        = rx_in_vif.baudrate;
  assign rx_out_vif.baudrate_valid  = rx_in_vif.baudrate_valid;
  assign rx_out_vif.data_width      = rx_in_vif.data_width;

  // ========================================================
  // 4. INSTANTIATE THE RTL MODULES
  // ========================================================
  uart_TX #(.PARAM_MAX_DATA_WIDTH(`UART_WIDTH)) dut_tx (
    .clk              (clk),
    .rst_n            (rst_n),
    .data_in          (tx_in_vif.data_in),
    .parity_en        (tx_in_vif.parity_en),
    .parity_odd_even  (tx_in_vif.parity_odd_even),
    .data_start_pulse (tx_in_vif.data_start_pulse),
    .baudrate         (tx_in_vif.baudrate),
    .baudrate_valid   (tx_in_vif.baudrate_valid),
    .data_width       (tx_in_vif.data_width),
    
    // Outputs
    .data_tx          (tx_out_vif.data_tx),
    .data_ready_pulse (tx_out_vif.data_ready_pulse),
    .uart_tx_busy     (tx_out_vif.uart_tx_busy)
  );

  uart_RX #(.PARAM_MAX_DATA_WIDTH(`UART_WIDTH)) dut_rx (
    .clk                 (clk),
    .rst_n               (rst_n),
    .data_rx             (rx_in_vif.data_rx), // Getting fed from TX!
    .parity_en           (rx_in_vif.parity_en),
    .parity_odd_even     (rx_in_vif.parity_odd_even),
    .baudrate            (rx_in_vif.baudrate),
    .data_width          (rx_in_vif.data_width),
    .baudrate_valid      (rx_in_vif.baudrate_valid),
    
    // Outputs
    .data_out            (rx_out_vif.data_out),
    .data_ready_pulse    (rx_out_vif.data_ready_pulse),
    .flag_packet_corrupt (rx_out_vif.flag_packet_corrupt),
    .uart_rx_busy        (rx_out_vif.uart_rx_busy)
  );

  // ========================================================
  // 5. CLOCK, RESET, AND UVM RUN
  // ========================================================
  initial begin
    rst_n = 0;
    #50 rst_n = 1;
  end

  always #5 clk = ~clk;

  initial begin
    // Push all four interfaces into the configuration database
    uvm_config_db #(virtual uart_tx_intf)::set(null, "*", "uart_tx_intf", tx_in_vif);
    uvm_config_db #(virtual uart_out_intf)::set(null, "*", "uart_out_intf", tx_out_vif);
    uvm_config_db #(virtual uart_rx_in_intf)::set(null, "*", "uart_rx_in_intf", rx_in_vif);
    uvm_config_db #(virtual uart_rx_out_intf)::set(null, "*", "uart_rx_out_intf", rx_out_vif);
    
    run_test();
  end

endmodule : tb_top_loopback