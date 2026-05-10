/////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : scoreboard.sv
//  Author        : MR
//  Creation Date : 12/01/2021
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
//  Cuboid Scoreboard
////////////////////////////////////////////////////////////////////////////////

// Implementation ports macros
`uvm_analysis_imp_decl(_ingr)
`uvm_analysis_imp_decl(_egrs)

class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard)

  // Constructor Fucntion
  function new(string name="scoreboard", uvm_component parent=null);
    super.new(name, parent);
  endfunction 

  uvm_analysis_imp_ingr #(inp_cuboid, scoreboard) ingr_imp_export;
  uvm_analysis_imp_egrs #(out_cuboid, scoreboard) egrs_imp_export;

  out_cuboid ingr_cboid_q[$]; 

  uvm_event     in_scb_evnt  ;
  common_config common_cfg   ;
  out_cuboid        exp_cboid;
  inp_cuboid        inp_cboid;
  out_cuboid        out_cboid;

  int match, mismatch, cboid_glbl_cnt , ap_pp_ingr_cboid_cnt      ;

  // ============================================
  // Create implementation ports in build phase
  // ============================================

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    out_cboid = out_cuboid::type_id::create("out_cboid");

    ingr_imp_export = new ("ingr_imp_export", this);
    egrs_imp_export = new ("egrs_imp_export", this);
    in_scb_evnt     = uvm_event_pool::get_global("ingr_scb_event");

    // getting pp_common config
    uvm_config_db #(common_config)::get(this, "*", "common_cfg", common_cfg);

  endfunction // build_phase



  // ===========================================
  // write function to push expecter data in que
  // ===========================================
    
  virtual function void write_ingr (inp_cuboid cboid);

    // Calculate expected Output that should be compared
    out_cboid.area = 2 * (cboid.length*cboid.width + cboid.width*cboid.height + cboid.height*cboid.length);
    out_cboid.volm = cboid.length*cboid.width*cboid.height ;
    
    // Pushing the expected cboid in ingr_cboid_q  
    ingr_cboid_q.push_back(out_cboid) ;
    ap_pp_ingr_cboid_cnt++        ;
  endfunction

  // =========================================
  // Popping data from ingr_cboid_q and then 
  // Compare the data with Actual cuboid
  // =========================================
  virtual function void write_egrs (out_cuboid cboid);
    if (ingr_cboid_q.size() == 0)
      `uvm_error("SCB", $sformatf("Data not Present"))
    else 
      exp_cboid = ingr_cboid_q.pop_front();
    
    if(cboid.compare(exp_cboid)) 
      match++;
    else begin
      mismatch++;
    end
  endfunction  


  // ========================================
  // Main Phase Task
  // ========================================
  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);
    wait(common_cfg.inp_num_cboids == match+mismatch );
    in_scb_evnt.trigger();
  endtask // main_phase


  virtual function void report_phase (uvm_phase phase);
    `uvm_info("SCB", $sformatf("cuboid Matched=%0d, Mismatched=%0d", match, mismatch), UVM_MEDIUM)
  endfunction // report_phase




  virtual function void display_mismatch_cboids(out_cuboid exp_cboid, out_cuboid cboid );

    string   msg;
    
    msg = $sformatf("\nMismatch Cuboid: Exp Area = %0d; Actual Area = %0d Exp Vol = %0d; Actual Vol = %0d\n",exp_cboid.area, cboid.area, exp_cboid.volm, cboid.volm);
    msg = {msg, $sformatf("==============================================================================================\n")};
    
    `uvm_error("mismatch cuboids", msg)

  endfunction  


endclass // scoreboard
