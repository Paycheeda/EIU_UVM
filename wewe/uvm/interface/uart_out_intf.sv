interface uart_out_intf (input clk);
  logic          data_tx;
  logic          data_ready_pulse;
  
  // ADDED: So the output monitor knows what kind of packet to expect!
  logic          parity_en;
  logic          parity_odd_even; 
endinterface