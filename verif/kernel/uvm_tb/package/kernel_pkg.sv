`ifndef KERNEL_PKG_SV
`define KERNEL_PKG_SV

package kernel_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // ==========================================
  // 1. Configurations & Sequence Items
  // ==========================================
  `include "kernel_config.sv"
  `include "bkp_item.sv"
  `include "out_item.sv"
  `include "kwr_item.sv"    
  `include "kst_item.sv"     
  `include "krd_item.sv"       
  
  // ---> NEW: NRZ Sequence Items <---
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
  
  // ---> NEW: NRZ Sequence <---
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
  
  // ---> NEW: NRZ Agent Components <---
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
  
  // ---> NEW: NRZ Scoreboard <---
  `include "nrz_scoreboard.sv"
  
  `include "kernel_env.sv"

endpackage

`endif