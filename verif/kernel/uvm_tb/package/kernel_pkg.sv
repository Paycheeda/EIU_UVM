////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : kernel_pkg.sv
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
//  UVM package for kernel verification
////////////////////////////////////////////////////////////////////////////////

`ifndef KERNEL_PKG_SV
`define KERNEL_PKG_SV

package kernel_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // ---> NEW: Import Peripheral Packages <---
  // This allows the kernel env to instantiate uart_agents and eth_agents
  // import uart_pkg::*;
  // import eth_pkg::*;

  // ==========================================
  // 1. Configurations & Sequence Items
  // ==========================================
  `include "kernel_config.sv"
  `include "bkp_item.sv"
  `include "out_item.sv"
  `include "kwr_item.sv"    
  `include "kst_item.sv"     
  `include "krd_item.sv"       
  `include "nrz_item.sv"
  `include "nrz_out_item.sv"

  // ==========================================
  // 2. Sequences
  // ==========================================
  `include "bkp_sequence.sv"
  `include "kwr_sequence.sv" 
  `include "krd_sequence.sv"   
  `include "bkp_read_seq.sv"   
  `include "bkp_smart_seq.sv"
  `include "nrz_sequence.sv"

  // ==========================================
  // 3. Agents (Config Input/Output)
  // ==========================================
  `include "bkp_monitor.sv"
  `include "bkp_driver.sv"
  `include "bkp_agent.sv"

  `include "out_monitor.sv"
  `include "out_agent.sv"

  // ==========================================
  // 4. Agents (Write Router, Start TX, Read)
  // ==========================================
  `include "kwr_monitor.sv" 
  `include "kwr_agent.sv"   
  
  `include "kst_driver.sv"   
  `include "kst_monitor.sv"  
  `include "kst_agent.sv"    

  `include "krd_driver.sv"     
  `include "krd_monitor.sv"   
  `include "krd_agent.sv"      
  
  `include "nrz_driver.sv"
  `include "nrz_monitor.sv"
  `include "nrz_agent.sv"

  // ==========================================
  // 5. Verification Integrity & Env
  // ==========================================
  `include "scoreboard.sv"
  `include "kwr_scoreboard.sv" 
  `include "kst_scoreboard.sv" 
  `include "krd_scoreboard.sv" 
  `include "nrz_scoreboard.sv"
  
  `include "kernel_env.sv"

endpackage

`endif