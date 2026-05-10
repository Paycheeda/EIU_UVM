interface uart_tx_intf (input clk);
  logic [8:0]    data_in;           // MUST be data_in
  logic          parity_en;
  logic          parity_odd_even;
  logic          data_start_pulse;
  logic          rst_n;            // MUST be rst_n
endinterface