////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : mac_rx_pkg.sv
//  Author        : Ahmed Ali
//  Creation Date : 16/04/2026
//
//  Copyright 2026 Avant Labs PVT LTD. All Rights Reserved.
//
//  No portions of this material may be reproduced in any form without
//  the written permission of:
//
//    First Floor, Jumaira Arcade,
//    Fateh Jang Road,
//    Sector F-17, Islamabad, 45230
//
//  All information contained in this document is Avant Labs PVT LTD
//  company private, proprietary and trade secret.
//
//  Description
//  ===========
//  UVM package for Ethernet MAC RX verification
////////////////////////////////////////////////////////////////////////////////

`ifndef MAC_RX_PKG_SV
`define MAC_RX_PKG_SV

package mac_rx_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // 1. Configuration
  `include "mac_rx_env_cfg.sv"

  // 2. Sequence Items
  `include "mac_rx_phy_seq_item.sv"
  `include "mac_rx_cpu_seq_item.sv"

  // 3. Sequences
  `include "mac_rx_phy_seqs.sv"
  `include "mac_rx_cpu_seqs.sv"

  // 4. Gigabit PHY Agent (Input)
  `include "phy_mac_monitor.sv"
  `include "phy_mac_driver.sv"
  `include "phy_mac_agent.sv"

  // 5. Downstream CPU Agent (Output)
  `include "cpu_mac_monitor.sv"
  `include "cpu_mac_driver.sv"
  `include "cpu_mac_agent.sv"

  // 6. Whitebox Probe (Passive)
  `include "whitebox_mac_monitor.sv"
  `include "whitebox_mac_agent.sv"

  // 7. Verification Integrity
  `include "mac_rx_scoreboard.sv"
  `include "mac_rx_env.sv"

endpackage

`endif