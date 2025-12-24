////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : inp_cuboid.sv
//  Author        : MR
//  Creation Date : 07/01/2020
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
//  sequence item for inp_cuboid example
////////////////////////////////////////////////////////////////////////////////

class inp_cuboid extends uvm_sequence_item;

  function new(string name = "inp_cuboid");
    super.new(name);
  endfunction // new

/*-------------------------------------------------------------------------------
-- Interface, port, fields
-------------------------------------------------------------------------------*/

  rand bit      [16-1:0] length    ;
  rand bit      [16-1:0] width     ;
  rand bit      [16-1:0] height    ;
  cuboid_config          cboid_cfg ;


  `uvm_object_utils_begin(inp_cuboid)
    `uvm_field_int(length, UVM_ALL_ON|UVM_NOCOMPARE)
    `uvm_field_int(width,  UVM_ALL_ON|UVM_NOCOMPARE)
    `uvm_field_int(height, UVM_ALL_ON|UVM_NOCOMPARE)
  `uvm_object_utils_end

  // constraint length_c { length inside{[40:60]};}
  // constraint width_c  { width  inside{[07:00]};}
  // constraint height_c { height <= width; }
  // ========================================
  // Create a new inp_cuboid and copy content
  // ========================================
  function inp_cuboid clone;
    inp_cuboid p;
    $cast(p, super.clone());
    return p;
  endfunction // clone

  // ==============================================================================================
  // 
  // ==============================================================================================
  virtual function void display_inp_cuboid(string name);
    string msg;
    
    msg = $sformatf("\n This is being displayed  from %s \n", name);
    msg = {msg, $sformatf("================================================================\n")};
    msg = {msg, $sformatf("Length = %h, Width = %h, Height =%h \n", length, width, height)};
    `uvm_info(name, msg, UVM_MEDIUM)
  endfunction // display_pkt

endclass // inp_cuboid

