////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : cuboid_base_test.sv
//  Author        : MR
//  Creation Date : 01/14/2020
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
//  This is Cuboid base test
////////////////////////////////////////////////////////////////////////////////

class cuboid_base_test extends uvm_test;
  `uvm_component_utils(cuboid_base_test)

  // =============================
  // Constructor Method
  // =============================
  function new(string name = "cuboid_base_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  // =============================
  // component handles
  // =============================
  cuboid_env       env          ;
  common_config    common_cfg   ;
  cuboid_config    cboid_cfg    ;
  // =============================
  // Virtual Interfaces
  // =============================
  virtual cuboid_inp_intf            cuboid_in_intf            ;


  // =============================
  // Build Phase Method
  // =============================
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    common_cfg = common_config::type_id::create("common_cfg", this);
    cboid_cfg  = cuboid_config::type_id::create("cboid_cfg", this);
    // common_cfg.randomize();
    
    uvm_config_db #(common_config)::set(null, "*", "common_cfg", common_cfg);
    uvm_config_db #(cuboid_config)::set(null, "*", "cboid_cfg", cboid_cfg);
    
    // creating environment object
    env = cuboid_env::type_id::create("env", this);

    // getting virtual interfaces for vif_init_zero tasks
    if (!uvm_config_db#(virtual cuboid_inp_intf)::get(this, "", "cuboid_in_intf", cuboid_in_intf))
      `uvm_fatal("TEST", "Did not get cuboid_in_intf")

  endfunction


  // =============================
  // Reset Phase Method
  // =============================
  virtual task reset_phase(uvm_phase phase);
    phase.raise_objection(this);

    `uvm_info("cuboid_base_test", $sformatf("Staring reset_phase.."), UVM_MEDIUM)
    super.reset_phase(phase);
    vif_init_zero(); 
    `uvm_info("cuboid_base_test", $sformatf("reset_phase done.."), UVM_MEDIUM)
    repeat (100) @(posedge cuboid_in_intf.clk); //idle cycles
    phase.drop_objection(this);
  endtask // reset_phase

  // ==============================================
  // all interfaces needs to intialize with zeros
  // ==============================================
  task vif_init_zero();
    cuboid_in_intf.length    <= 0 ;
    cuboid_in_intf.width     <= 0 ;
    cuboid_in_intf.height    <= 0 ;
    cuboid_in_intf.valid     <= 0 ;
  endtask

   
  
endclass
