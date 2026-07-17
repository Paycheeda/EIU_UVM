////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : uart_pkg.sv
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
//  UVM package for UART verification
////////////////////////////////////////////////////////////////////////////////

package uart_pkg;
  
  // ==========================================
  // 1. UVM Base Includes
  // ==========================================
  `include "uvm_macros.svh" 
  import uvm_pkg::*; 

  // ==========================================
  // 2. Configurations & Globals
  // ==========================================
  `include "uart_config.sv"

  // ==========================================
  // 3. Sequence Items (The Mathematical Payload)
  // ==========================================
  `include "tx_uart.sv"  // (Used for both TX and RX flows now!)
  `include "rx_uart.sv"  // (Used purely for the Host RX parallel read)

  // ==========================================
  // 4. Sequences (The Traffic Generators)
  // ==========================================
  `include "uart_tx_sequence.sv"
  `include "uart_main_sequence.sv"
  `include "static_uart_sequence.sv"

  // ==========================================
  // 5. Low-Level Components (Drivers & Monitors)
  // ==========================================
  // --- Path 1: The CPU Bus (Host Side) ---
  `include "host_tx_driver.sv"
  `include "host_tx_monitor.sv"
  `include "host_rx_monitor.sv" // (Passive, no driver)

  // --- Path 2: The Physical Wire (Line Side) ---
  `include "line_rx_driver.sv"
  `include "line_rx_monitor.sv"
  `include "line_tx_monitor.sv" // (Passive, no driver)

  // ==========================================
  // 6. Mid-Level Components (Agents & Scoreboard)
  // ==========================================
  // --- The 4 Agents ---
  `include "host_tx_agent.sv"
  `include "host_rx_agent.sv"
  `include "line_tx_agent.sv"
  `include "line_rx_agent.sv"

  // --- The Dual-Engine Scoreboard ---
  `include "unified_scoreboard.sv"


  // ==========================================
  // 7. Top-Level Environment
  // ==========================================
  `include "unified_env.sv"
  `include "dynamic_duplex_test.sv"
  // ==========================================
  // 8. Tests
  // ==========================================
  `include "unified_base_test.sv"
  
endpackage