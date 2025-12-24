////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : test.sv
//  Author        : MAH
//  Creation Date : 1/2/2022
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
//  Basic new_test for constrained inputs
////////////////////////////////////////////////////////////////////////////////
class new_test extends cuboid_base_test;
  `uvm_component_utils(new_test)
  
  // =============================
  // Costructor Method
  // =============================
  function new(string name = "new_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // =============================
  // Build Phase Method
  // ============================= 
  function void build_phase(uvm_phase phase);
     super.build_phase(phase);
    `uvm_info("new_test", "Starting new_test.... ", UVM_MEDIUM)
  endfunction

endclass 


// class new_test extends cuboid_base_test;
//   `uvm_component_utils(new_test)
  
//   // =============================
//   // Costructor Method
//   // =============================
//   function new(string name = "new_test", uvm_component parent = null);
//     super.new(name, parent);
//   endfunction
//    // new_sequence sequ;

//   // =============================
//   // Build Phase Method
//   // ============================= 
//   function void build_phase(uvm_phase phase);
//      super.build_phase(phase);
//      // factory.set_type_override_by_type(cuboid::get_type(),new_sequence::get_type());
//      // sequ = new_sequence::type_id::create("new_sequence", this);
//     `uvm_info("new_test", "Starting new_test.... ", UVM_MEDIUM)
//   endfunction

// endclass 