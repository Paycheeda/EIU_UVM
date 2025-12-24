////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : inp_sequence.sv
//  Author        : FZ
//  Creation Date : 10/05/2020
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
//  Sequence for AP cuboid sequence. Uses common cboid_sequence
////////////////////////////////////////////////////////////////////////////////

class inp_sequence extends uvm_sequence #(inp_cuboid);
  `uvm_object_utils(inp_sequence)
 
  cuboid_sequence cboid_seq ;
  common_config   common_cfg;

  
  function new (string name = "inp_sequence");
    super.new(name);    
  endfunction

  // Get common_config
  virtual task pre_start();
    if (!uvm_config_db#(common_config)::get(get_sequencer(), "", "common_cfg", common_cfg))
      `uvm_fatal("inp_sequence", "Did not get common_config")

  endtask : pre_start

  virtual task body();
    `uvm_info("inp_sequence", $sformatf("Starting cboid_seq for %0d packets..", common_cfg.inp_num_cboids), UVM_MEDIUM)

    cboid_seq = cuboid_sequence::type_id::create("cboid_seq");
    cboid_seq.num_cboids = common_cfg.inp_num_cboids ; 
    cboid_seq.start(get_sequencer());
    
    `uvm_info("inp_sequence", $sformatf("cboid_seq done.."), UVM_MEDIUM)
  endtask 
  
    
endclass // inp_sequence

