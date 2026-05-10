`ifndef ETH_PKG_SV
`define ETH_PKG_SV

package eth_pkg;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // 1. Define the enum AT THE TOP so all classes below can see the type
  typedef enum bit [1:0] { 
    FAULT_NONE     = 2'b00, 
    FAULT_CRC      = 2'b01, 
    FAULT_PHY      = 2'b10, 
    FAULT_PREAMBLE = 2'b11 
  } fault_t;

  // 2. Configs
  `include "eth_loopback_env_cfg.sv"

  // 3. Sequence Items (Must come before Sequences and Agents)
  `include "eth_tx_seq_item.sv"
  `include "eth_rx_seq_item.sv"

  // 4. Sequences (Include your new stress sequence here)
  `include "eth_tx_base_sequence.sv"
  `include "eth_tx_stress_seq.sv" 

  // 5. TX Agent
  `include "eth_tx_driver.sv"
  `include "eth_tx_monitor.sv"
  `include "eth_tx_agent.sv"

  // 6. RX App Agent
  `include "eth_rx_app_monitor.sv"
  `include "eth_rx_app_agent.sv"

  // 7. Scoreboard & Env
  `include "eth_loopback_scoreboard.sv"
  `include "eth_loopback_env.sv"

  // 8. Test
  `include "eth_loopback_base_test.sv"

endpackage
`endif