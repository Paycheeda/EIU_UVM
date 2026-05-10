`include "uvm_macros.svh"
import uvm_pkg::*;
import uart_pkg::*; 

module tb_top;
  bit clk;
  bit rst_n; 

  uart_tx_intf  in_vif  (.clk(clk));
  uart_out_intf out_vif (.clk(clk));

  // ========================================================
  // DUMMY RX INTERFACES (To satisfy ModelSim's strict checks)
  // ========================================================
  uart_rx_in_intf  dummy_rx_in (.clk(clk));
  uart_rx_out_intf dummy_rx_out(.clk(clk));
  // ========================================================

  assign in_vif.rst_n = rst_n;
  
  // ========================================================
  // PRO-SAN FIX: Route the dynamic config to the Output Monitor!
  // ========================================================
  assign out_vif.parity_en       = in_vif.parity_en;
  assign out_vif.parity_odd_even = in_vif.parity_odd_even;
  assign out_vif.baudrate        = in_vif.baudrate;
  assign out_vif.baudrate_valid  = in_vif.baudrate_valid;
  assign out_vif.data_width      = in_vif.data_width;

  // ========================================================
  // INSTANTIATE THE DYNAMIC RTL
  // ========================================================
  uart_TX #(
    .PARAM_MAX_DATA_WIDTH(`UART_WIDTH) // Only the MAX physical width remains a parameter
  ) dut (
    .clk              (clk),
    .rst_n            (rst_n),
    .data_in          (in_vif.data_in),
    .parity_en        (in_vif.parity_en),
    .parity_odd_even  (in_vif.parity_odd_even),
    .data_start_pulse (in_vif.data_start_pulse),
    
    // NEW DYNAMIC PORTS:
    .baudrate         (in_vif.baudrate),
    .baudrate_valid   (in_vif.baudrate_valid),
    .data_width       (in_vif.data_width),

    .data_tx          (out_vif.data_tx),
    .data_ready_pulse (out_vif.data_ready_pulse),
    .uart_tx_busy     (out_vif.uart_tx_busy) // Added from your updated RTL
  );

  initial begin
    rst_n = 0;
    #50 rst_n = 1;
  end

  initial begin
    uvm_config_db #(virtual uart_tx_intf)::set(null, "*", "uart_tx_intf", in_vif);
    uvm_config_db #(virtual uart_out_intf)::set(null, "*", "uart_out_intf", out_vif);
    run_test();
  end

  always #5 clk = ~clk;
endmodule : tb_top