`ifndef ETH_RX_PKG_SV
`define ETH_RX_PKG_SV

package eth_rx_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // 1. Configuration Object
  `include "eth_rx_env_cfg.sv"

  // 2. Sequence Items (The Transactions)
  `include "phy_rx_seq_item.sv"
  `include "fifo_out_seq_item.sv"

  // 3. Sequences (The Sabotage Attacks)
  `include "eth_rx_test_seqs.sv"

  // 4. PHY Agent Components (Active - Drives physical pins)
  `include "eth_rx_if_driver.sv"
  `include "phy_rx_monitor.sv"
  `include "phy_rx_agent.sv"

  // 5. FIFO Agent Components (Passive - Snoops internal memory)
  `include "fifo_out_monitor.sv"
  `include "fifo_out_agent.sv"

  // 6. Scoreboard & Environment (The Judges)
  `include "eth_rx_scoreboard.sv"
  `include "eth_rx_env.sv"

  // 7. Tests (The Launchpad)
  `include "eth_rx_base_test.sv"

endpackage

`endif