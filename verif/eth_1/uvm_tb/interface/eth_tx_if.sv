/*`ifndef ETH_TX_IF_SV
`define ETH_TX_IF_SV

interface eth_tx_if(input logic clk, input logic rst_n);
  // Configuration
  logic [47:0] dest_mac;
  logic [47:0] source_mac;
  logic [31:0] source_ip;
  logic [31:0] dest_ip;
  logic [15:0] source_port;
  logic [15:0] dest_port;
  logic [10:0] payload_length;

  // Control & Status
  logic eth_tx_start_pulse;
  logic eth_tx_payload_ack;
  logic eth_tx_data_sent;

  // FIFO Interface
  logic       tx_fifo_rd_en;
  logic       tx_fifo_empty;
  logic [7:0] tx_fifo_data_out;
endinterface

`endif*/ //commented out for aaaa whatever

`ifndef ETH_TX_IF_SV
`define ETH_TX_IF_SV

interface eth_tx_if(input logic clk, input logic rst_n);
  // MAC Dynamic Metadata
  logic [47:0] dest_mac;
  logic [47:0] source_mac;
  logic [31:0] source_ip;
  logic [31:0] dest_ip;
  logic [15:0] source_port;
  logic [15:0] dest_port;
  logic [15:0] payload_length;

  // TX Control (UPDATED FOR NEW PIPELINE)
  logic config_done_pulse;      // <--- NEW: Tells RTL to construct the frame
  logic eth_tx_start_pulse;     // <--- Keeps its role: Tells RTL to physically transmit
  logic eth_tx_data_sent;

  // External physical FIFO Write Pins
  logic       ext_tx_fifo_wr_en;
  logic [7:0] ext_tx_fifo_data_in;

  // Old Internal MAC Read Pins (still monitored for debug)
  logic       tx_fifo_rd_en;
  logic [7:0] tx_fifo_data_out;
  logic       tx_fifo_empty;
endinterface

`endif