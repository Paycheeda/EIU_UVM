////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : inp_monitor.sv
//  Author        : MR
//  Creation Date : 10/07/2020
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
//  This is the Monitor for inp interface of inp_cuboid module
////////////////////////////////////////////////////////////////////////////////

class inp_monitor extends uvm_monitor;
  `uvm_component_utils(inp_monitor)

  // =============================
  // Constructor Method
  // =============================
  function new(string name="inp_monitor", uvm_component parent=null);
    super.new(name, parent);
  endfunction // new

  uvm_analysis_port#(inp_cuboid) mon_analysis_port;
  virtual cuboid_inp_intf vif   ;
  
  inp_cuboid                  cboid ;
  
  // =============================
  // Build Phase Method
  // =============================
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual cuboid_inp_intf)::get(this, "", "cuboid_in_intf", vif))
      `uvm_fatal("INP_MONITOR", "Could not get vif")
    mon_analysis_port = new ("mon_analysis_port", this);
  endfunction // build_phase

  // =============================
  // Main Phase Method
  // =============================
  virtual task main_phase(uvm_phase phase);
    super.main_phase(phase);
    collect_data();
  endtask // main_phase

  // =============================
  // Collecting data
  // =============================
  task collect_data ;
    forever begin
      //======================================================//
      // collecting inp_cuboid at valid                           //
      //======================================================//
      if (vif.valid) begin
        cboid        = inp_cuboid::type_id::create("INP Monitor Pkt");
        cboid.length = vif.length;
        cboid.width  = vif.width ;
        cboid.height = vif.height;
        mon_analysis_port.write(cboid);
        cboid.display_inp_cuboid("INPUT_MONITOR");      
      end
      @(posedge vif.clk);
    end
  endtask

endclass 
