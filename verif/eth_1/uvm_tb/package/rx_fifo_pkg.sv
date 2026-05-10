`ifndef RX_FIFO_PKG_SV
`define RX_FIFO_PKG_SV

package rx_fifo_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // 1. Sequence Items
  `include "rx_fifo_in_seq_item.sv"
  `include "rx_fifo_out_seq_item.sv"

  // 2. Sequences
  `include "rx_fifo_master_seq.sv"

  // 3. Input Agent (Active RAM Simulator)
  `include "rx_fifo_in_monitor.sv"
  `include "rx_fifo_in_driver.sv"
  `include "rx_fifo_in_agent.sv"

  // 4. Output Agent (Passive Snooper)
  `include "rx_fifo_out_monitor.sv"
  `include "rx_fifo_out_agent.sv"

  // 5. Environment & Scoreboard
  `include "rx_fifo_scoreboard.sv"
  `include "rx_fifo_env.sv"

endpackage

`endif