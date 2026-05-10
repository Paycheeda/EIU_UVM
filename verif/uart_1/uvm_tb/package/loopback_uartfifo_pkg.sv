package loopback_uartfifo_pkg;
  
  // ==========================================
  // 1. UVM Base Includes
  // ==========================================
  `include "uvm_macros.svh" 
  import uvm_pkg::*; 

  // ==========================================
  // 2. Import Existing Verification IP (VIP)
  // ==========================================
  // This brings in fifo_item, fifo_wr_agent, fifo_rd_agent, etc.
  import fifo_pkg::*; 

  // ==========================================
  // 3. UART Configuration Agent (New)
  // ==========================================
  `include "uart_config_item.sv"
  `include "uart_config_seq.sv"
  `include "uart_config_driver.sv"
  `include "uart_config_monitor.sv"
  `include "uart_config_agent.sv"
  `include "uart_physical_monitor.sv"

  // ==========================================
  // 4. Subsystem Scoreboard & Environment (New)
  // ==========================================
  `include "loopback_uartfifo_scoreboard.sv"
  `include "loopback_uartfifo_env.sv"

  // ==========================================
  // 5. Virtual Sequences (The Orchestrator) (New)
  // ==========================================
  `include "loopback_vsqncr.sv"
  `include "loopback_vseq.sv"


  // ==========================================
  // 6. The Master Test (New)
  // ==========================================
  `include "loopback_test.sv"

  `include "chaos_vseq.sv"
  `include "chaos_test.sv"
  
endpackage