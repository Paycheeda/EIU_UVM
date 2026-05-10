////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : out_cuboid.sv
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
//  sequence item for out_cuboid example
////////////////////////////////////////////////////////////////////////////////

class out_cuboid extends uvm_sequence_item;

  function new(string name = "out_cuboid");
    super.new(name);
  endfunction // new

/*-------------------------------------------------------------------------------
-- Interface, port, fields
-------------------------------------------------------------------------------*/

  logic [32-1:0]  out_data  ;
  logic           out_start ;
  logic           out_valid ;


  `uvm_object_utils_begin(out_cuboid)
    `uvm_field_int(out_data,   UVM_ALL_ON)
    `uvm_field_int(out_start,   UVM_ALL_ON)
    `uvm_field_int(out_valid,   UVM_ALL_ON)
  `uvm_object_utils_end

  // constraint length_c { length inside{[40:60]};}
  // constraint width_c  { width  inside{[07:00]};}
  // constraint height_c { height <= width; }
  // ========================================
  // Create a new out_cuboid and copy content
  // ========================================
  function out_cuboid clone;
    out_cuboid p;
    $cast(p, super.clone());
    return p;
  endfunction // clone

  // ==============================================================================================
  // 
  // ==============================================================================================
  virtual function void display_out_cuboid(string name);
    string msg;
    
    msg = $sformatf("\n This is being displayed from %s \n", name);
    msg = {msg, $sformatf("================================================================\n")};
    msg = {msg, $sformatf("Output Data = %h, Start Output = %h, Output Valid = %h \n", out_data, out_start, out_valid)};
    `uvm_info(name, msg, UVM_MEDIUM)
  endfunction // display_pkt

endclass // out_cuboid

