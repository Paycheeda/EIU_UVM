////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : cuboid.sv
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
//  sequence item for cuboid example
////////////////////////////////////////////////////////////////////////////////

class cuboid extends uvm_sequence_item;

  function new(string name = "cuboid");
    super.new(name);
  endfunction // new

/*-------------------------------------------------------------------------------
-- Interface, port, fields
-------------------------------------------------------------------------------*/

  rand bit      [16-1:0] length    ;
  rand bit      [16-1:0] width     ;
  rand bit      [16-1:0] height    ;
  bit           [32-1:0] area      ;
  bit           [32-1:0] volm      ;
  cuboid_config          cboid_cfg ;


  `uvm_object_utils_begin(cuboid)
    `uvm_field_int(length, UVM_ALL_ON|UVM_NOCOMPARE)
    `uvm_field_int(width,  UVM_ALL_ON|UVM_NOCOMPARE)
    `uvm_field_int(height, UVM_ALL_ON|UVM_NOCOMPARE)
    `uvm_field_int(area,   UVM_ALL_ON)
    `uvm_field_int(volm,   UVM_ALL_ON)
  `uvm_object_utils_end

  // constraint length_c { length inside{[40:60]};}
  // constraint width_c  { width  inside{[07:00]};}
  // constraint height_c { height <= width; }
  // ========================================
  // Create a new cuboid and copy content
  // ========================================
  function cuboid clone;
    cuboid p;
    $cast(p, super.clone());
    return p;
  endfunction // clone

  // ==============================================================================================
  // 
  // ==============================================================================================
  virtual function void display_cuboid(string name);
    string msg;
    
    msg = $sformatf("\n This is being displayed from %s \n", name);
    msg = {msg, $sformatf("================================================================\n")};
    msg = {msg, $sformatf("Length = %h, Width = %h, Height =%h \n", length, width, height)};
    msg = {msg, $sformatf("Area = %h, volm = %h \n", area, volm)};
    `uvm_info(name, msg, UVM_MEDIUM)
  endfunction // display_pkt

endclass // cuboid

