////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : test.sv
//  Author        : MR
//  Creation Date : 1/14/2021
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
//  Basic short_test for less number of cuboids
////////////////////////////////////////////////////////////////////////////////
class short_test extends cuboid_base_test;
  `uvm_component_utils(short_test)
  
  // =============================
  // Costructor Method
  // =============================
  function new(string name = "short_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // =============================
  // Build Phase Method
  // ============================= 
  function void build_phase(uvm_phase phase);
     super.build_phase(phase);
    `uvm_info("short_test", "Starting short_test.... ", UVM_MEDIUM)
  endfunction

endclass 

