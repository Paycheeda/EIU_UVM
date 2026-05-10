`ifndef MAC_RX_IF_SV
`define MAC_RX_IF_SV

interface mac_rx_if (input logic clk, input logic rst_n);

  // ========================================================
  // 1. GIGABIT PHY DOMAIN (Input from Network)
  // ========================================================
  logic [3:0] rxd;
  logic       rx_ctl;

  // ========================================================
  // 2. CPU DOMAIN (Outputs from MAC to System)
  // ========================================================
  logic        eth_rx_data_valid;
  logic [10:0] corrupt_packet_counter;
  logic [10:0] valid_eth_frame;

  // ========================================================
  // 3. EXTERNAL FIFO DOMAIN (Memory Bus)
  // ========================================================
  // MAC to FIFO
  logic       rx_fifo_wr_en;
  logic       rx_fifo_rst_n;
  logic [7:0] rx_fifo_data_in;
  
  // FIFO to CPU (Reader)
  logic       ext_fifo_rd_en;
  logic [7:0] ext_fifo_data_out;
  logic       ext_fifo_empty;

  // ========================================================
  // 4. WHITEBOX PROBES (Passive Taps)
  // ========================================================
  logic       wb_iddr_rx_dv;
  logic       wb_iddr_rx_er;
  logic [1:0] wb_rx_if_state;
  logic [3:0] wb_rx_fifo_if_state;

  // ========================================================
  // 5. UVM DRIVER PARALLEL INJECTION PORT (Pre-ODDR)
  // ========================================================
  logic [7:0] rxd_parallel;
  logic       rx_ctl_parallel;
  logic       rx_er_parallel; // To inject errors

endinterface

`endif