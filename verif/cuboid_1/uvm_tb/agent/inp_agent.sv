////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : inp_agent.sv
//  Author        : MR
//  Creation Date : 08/01/2020
//
//  Copyright 2020 Sahil Semiconductor. All Rights Reserved.
//
//  No portions of this material may be reproduced in any form withinp
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
//  Agent at cuboid Ingress port
////////////////////////////////////////////////////////////////////////////////

class inp_agent extends uvm_agent;
  `uvm_component_utils(inp_agent)

  // =============================
  // Constructor Method
  // =============================  
  function new(string name="inp_agent", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  inp_monitor               mntr ; // Monitor handle
  inp_driver                drvr ; // Driver  handle
  uvm_sequencer #(inp_cuboid)   sqncr;     // Sequencer Handle

  // =============================
  // Build Phase Method
  // =============================
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sqncr = uvm_sequencer#(inp_cuboid)::type_id::create("sqncr", this);
    mntr = inp_monitor::type_id::create("mntr", this);
    drvr = inp_driver::type_id::create("drvr", this);
  endfunction

  // =============================
  // Connect Phase Method
  // =============================
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    drvr.seq_item_port.connect(sqncr.seq_item_export);
  endfunction

endclass
