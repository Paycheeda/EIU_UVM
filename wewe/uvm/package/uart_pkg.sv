/*MARKED FOR WHEN MAKING THE MAKE FILE !!!!!!! REMEMBER 

package cuboid_pkg;                       // package declaration
  `include "uvm_macros.svh" 
  import uvm_pkg::*;                  // import UVM package

  //configs
  `include "cuboid_config.sv"
  `include "common_config.sv"
  // Sequence Item
  // `include "cuboid.sv"
  `include "input_cuboid_seq_item.sv"
  `include "output_cuboid_seq_item.sv"
  // Drivers
  `include "inp_driver.sv"
  // Monitor
  `include "inp_monitor.sv"
  `include "out_monitor.sv"
  // Agents 
  `include "inp_agent.sv"
  `include "out_agent.sv"
  // Scoreboard
  `include "scoreboard.sv"
  // Sequences
  `include "cuboid_sequence.sv"
  `include "inp_sequence.sv"
  // Enironment 
  `include "env.sv"
  // Tests
  `include "cuboid_base_test.sv"
  `include "../test/short_test/test.sv"
  
endpackage */

package uart_pkg;
  
  // 1. UVM Base Includes
  `include "uvm_macros.svh" 
  import uvm_pkg::*; 

  // 2. Configurations (Standalone, no dependencies)
  `include "uart_config.sv"

  // 3. Sequence Items (Everything else depends on this!)
  `include "tx_uart.sv" 

  // 4. Sequences (Depend on tx_uart and uart_config)
  `include "uart_tx_sequence.sv"
  `include "uart_main_sequence.sv"

  // 5. Low-Level Components (Monitors & Drivers)
  `include "inp_driver.sv"
  `include "inp_monitor.sv"
  `include "out_monitor.sv"

  // 6. Mid-Level Components (Agents & Scoreboard)
  `include "inp_agent.sv"
  `include "out_agent.sv"
  `include "scoreboard.sv"

  // 7. Top-Level Environment
  `include "uart_env.sv"

  // 8. Tests (Depend on Env and Sequences)
  `include "uart_base_test.sv"
  `include "uart_short_test.sv"
  
endpackage