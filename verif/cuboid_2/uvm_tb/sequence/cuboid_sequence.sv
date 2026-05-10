////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : cuboid_sequence.sv
//  Author        : MR
//  Creation Date : 10/01/2020
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
//  cuboid_sequence for cuboid class
////////////////////////////////////////////////////////////////////////////////

class cuboid_sequence extends uvm_sequence #(inp_cuboid);
  `uvm_object_utils(cuboid_sequence)

  inp_cuboid        cboid         ;
  cuboid_config cboid_cfg     ;
  int           num_cboids    ;
  int           i             ;
  int           min_w         ;
  int           max_w         ;
  int           min_h         ;
  int           max_h         ;
  int           min_l         ;
  int           max_l         ;
                                   
                              
  function new (string name = "cuboid_sequence");
    super.new(name); 
  endfunction 

  virtual task pre_start();
    if (!uvm_config_db#(cuboid_config)::get(get_sequencer(), "", "cboid_cfg", cboid_cfg))
      `uvm_fatal("cuboid_sequence", "Did not get cuboid Config")
  endtask 
  
  virtual task body();
    cboid = inp_cuboid::type_id::create("cboid");
    `uvm_info("cuboid_sequence", $sformatf("Generating Cuboids = %0d", num_cboids), UVM_MEDIUM)
    min_w = cboid_cfg.weight_min;
    max_w = cboid_cfg.weight_max;
    min_h = cboid_cfg.height_min;
    max_h = cboid_cfg.height_max;
    min_l = cboid_cfg.length_min;
    max_l = cboid_cfg.length_max;
    for (i = 0; i < num_cboids; i++)  begin
      
      start_item(cboid);
      // if (!cboid_cfg.randomize()) `uvm_fatal("cuboid_sequence", "cboid_cfg Randomization Failed");
      cboid.cboid_cfg = cboid_cfg;
      cboid.length = ($urandom_range(min_l, max_l));
      cboid.width  = ($urandom_range(min_w, max_w));
      cboid.height = ($urandom_range(min_l, max_h));
      
      // if(!cboid.randomize()) `uvm_fatal("cuboid_sequence", "cboid Randomization Failed");
            
      finish_item(cboid);  
    end // for (i = 0; i < num_cboids; i++)
    `uvm_info("cuboid_sequence", $sformatf("Done generation of %0d cboid items", i), UVM_LOW)
  endtask // body


endclass // cuboid_sequence
