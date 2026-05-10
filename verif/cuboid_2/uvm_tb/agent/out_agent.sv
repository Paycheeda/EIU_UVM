////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : out_agent.sv
//  Author        : MR
//  Creation Date : 08/01/2020
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
//  Agent at cuboid Egress port
////////////////////////////////////////////////////////////////////////////////


class out_agent extends uvm_agent;
  `uvm_component_utils(out_agent)

  // =============================
  // Constructor Method
  // =============================  
  function new(string name="out_agent", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  out_monitor mntr; // Monitor handle

  // =============================
  // Build Phase Method
  // =============================
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mntr = out_monitor::type_id::create("mntr", this);
  endfunction

  // =============================
  // Connect Phase Method
  // =============================
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

endclass
