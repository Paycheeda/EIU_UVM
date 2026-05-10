`timescale 1ns/100fs

module tb_top_unified;
  
  import uvm_pkg::*;
  import uart_pkg::*; 
  
  bit clk;
  bit rst_n;

  always #11.3 clk = ~clk;

  uart_unified_intf vif(clk);
  assign vif.rst_n = rst_n;

  // ==========================================
  // THE NEW RTL ADAPTER
  // ==========================================
  uart #(
      .PARAM_MAX_DATA_WIDTH(9)
  ) dut (
      .clk                    (vif.clk),
      .rst_n                  (vif.rst_n),

      .baudrate               (vif.baudrate),
      .parity_en              (vif.parity_en),
      .parity_odd_even        (vif.parity_odd_even),
      .data_width             (vif.data_width),
      
      .data_in_TX             (vif.data_in_TX),
      
      // Mapped to existing UVM Interface!
      .send_data_TX_pulse_in  (vif.send_data_tx), 
      .uart_tx_busy           (vif.uart_tx_busy),
      .data_ready_TX_pulse    (), // Left floating (Unused by UVM)
      
      .data_out_RX            (vif.data_out_RX),
      
      // Mapped to existing UVM Interface!
      .flag_data_received     (vif.RX_DATA_RECEIVED), 
      .flag_packet_RX_corrupt (vif.flag_packet_RX_corrupt),
      .data_ready_RX_pulse    (), // Left floating (Unused by UVM)

      .rx                     (vif.rx),
      .tx                     (vif.tx)
  );

  initial begin
    uvm_config_db#(virtual uart_unified_intf)::set(null, "*", "uart_unified_intf", vif);
    run_test();
  end

  initial begin
    clk = 0;
    rst_n = 0;
    #200; 
    rst_n = 1;
  end

endmodule