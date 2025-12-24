////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : cuboid_pkg.sv
//  Author        : MR
//  Creation Date : 01/15/2021
//
//  Copyright 2020 Sahil Semiconductor. All Rights Reserved.
//
//  No portions of this material may be reproduced in any form without
//  the written permission of:
//
//    Sahil Semiconductor
//    1601 McCarthy Blvd
//    Milpitas CA – 95035
//
//  All information contained in this document is Sahil Semiconductor
//  company private, proprietary and trade secret.
//
//  Description
//  ===========
//  UVM package file for Cuboid processor
////////////////////////////////////////////////////////////////////////////////

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
  
endpackage 

