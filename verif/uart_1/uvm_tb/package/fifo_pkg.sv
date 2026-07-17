////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : fifo_pkg.sv
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
//  UVM package for UART FIFO verification
////////////////////////////////////////////////////////////////////////////////

package fifo_pkg;
  
  // ==========================================
  // 1. UVM Base Includes
  // ==========================================
  `include "uvm_macros.svh" 
  import uvm_pkg::*; 

  `include "fifo_config.sv"

  // ==========================================
  // 2. Sequence Items (The Mathematical Payload)
  // ==========================================
  `include "fifo_item.sv"  

  // ==========================================
  // 3. Sequences (The Traffic Generators)
  // ==========================================
  // (Contains both fifo_wr_sequence and fifo_rd_sequence)
  `include "fifo_sequences.sv" 

  // ==========================================
  // 4. Low-Level Components (Drivers & Monitors)
  // ==========================================
  // --- Write Domain (100 MHz Producer) ---
  `include "fifo_wr_driver.sv"
  `include "fifo_wr_monitor.sv"

  // --- Read Domain (44.2 MHz Consumer) ---
  `include "fifo_rd_driver.sv"
  `include "fifo_rd_monitor.sv"

  // ==========================================
  // 5. Mid-Level Components (Agents & Scoreboard)
  // ==========================================
  // --- The Isolated CDC Agents ---
  `include "fifo_wr_agent.sv"
  `include "fifo_rd_agent.sv"

  // --- The Asynchronous Scoreboard ---
  `include "fifo_scoreboard.sv"

  // ==========================================
  // 6. Top-Level Environment
  // ==========================================
  `include "fifo_env.sv"

  // ==========================================
  // 7. Tests
  // ==========================================
  `include "fifo_standalone_test.sv"
  
endpackage