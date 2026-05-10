// 1. Compile for the MAXIMUM physical width (9)
`ifndef UART_WIDTH
  `define UART_WIDTH 9 
`endif

`include "uvm_macros.svh"
import uvm_pkg::*;
import uart_pkg::*; 

module tb_top_rx;
  bit clk;
  bit rst_n; 

  // ========================================================
  // DUMMY INTERFACES (To satisfy ModelSim's strict checks)
  // ========================================================
  uart_tx_intf  dummy_tx_in (.clk(clk));
  uart_out_intf dummy_tx_out(.clk(clk));
  // ========================================================

  // 1. Instantiate the REAL RX Interfaces
  uart_rx_in_intf  in_vif  (.clk(clk));
  uart_rx_out_intf out_vif (.clk(clk));

  // Connect reset and pass the configuration to the output monitor
  assign in_vif.rst_n            = rst_n;
  assign out_vif.parity_en       = in_vif.parity_en;
  assign out_vif.parity_odd_even = in_vif.parity_odd_even;
  
  // ========================================================
  // Pass the dynamic pins through to the output interface!
  // ========================================================
  assign out_vif.baudrate        = in_vif.baudrate;
  assign out_vif.baudrate_valid  = in_vif.baudrate_valid;
  assign out_vif.data_width      = in_vif.data_width;

  // 2. Instantiate the NEW Dynamic RX RTL
  uart_RX #(
    .PARAM_MAX_DATA_WIDTH(`UART_WIDTH) // Set physical silicon width
  ) dut (
    .clk                 (clk),
    .rst_n               (rst_n),
    .data_rx             (in_vif.data_rx),
    .parity_en           (in_vif.parity_en),
    .parity_odd_even     (in_vif.parity_odd_even),
    
    // NEW DYNAMIC PINS connected to the input interface:
    .baudrate            (in_vif.baudrate),
    .data_width          (in_vif.data_width),
    .baudrate_valid      (in_vif.baudrate_valid),
    
    // Output pins
    .data_out            (out_vif.data_out),
    .data_ready_pulse    (out_vif.data_ready_pulse),
    .flag_packet_corrupt (out_vif.flag_packet_corrupt),
    
    // ========================================================
    // PRO-SAN FIX: WIRED THE BUSY SIGNAL!
    // ========================================================
    .uart_rx_busy        (out_vif.uart_rx_busy) 
  );

  // 3. Generate Reset
  initial begin
    rst_n = 0;
    #50 rst_n = 1;
  end

  // 4. Start UVM
  initial begin
    // Put the RX virtual interfaces into the UVM Database
    uvm_config_db #(virtual uart_rx_in_intf)::set(null, "*", "uart_rx_in_intf", in_vif);
    uvm_config_db #(virtual uart_rx_out_intf)::set(null, "*", "uart_rx_out_intf", out_vif);
    run_test();
  end

  // Clock Generation
  always #5 clk = ~clk;

endmodule : tb_top_rx