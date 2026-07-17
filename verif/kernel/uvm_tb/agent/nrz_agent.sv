////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : nrz_agent.sv
//  Author        : Ahmed Ali
//  Creation Date : 16/04/2026
//
//  Copyright 2026 Avant Labs PVT LTD. All Rights Reserved.
//
//  No portions of this material may be reproduced in any form without
//  the written permission of:
//
//    First Floor, Jumaira Arcade,
//    Fateh Jang Road,
//    Sector F-17, Islamabad, 45230
//
//  All information contained in this document is Avant Labs PVT LTD
//  company private, proprietary and trade secret.
//
//  Description
//  ===========
//  UVM agent for Kernel NRZ verification
////////////////////////////////////////////////////////////////////////////////

`ifndef NRZ_AGENT_SV
`define NRZ_AGENT_SV

class nrz_agent extends uvm_agent;
    `uvm_component_utils(nrz_agent)

    uvm_sequencer #(nrz_item) sqr;
    nrz_driver                drv;
    nrz_monitor               mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        mon = nrz_monitor::type_id::create("mon", this);
        
        // FIXED: Only create sequencer and driver if active
        if(get_is_active() == UVM_ACTIVE) begin
            sqr = uvm_sequencer#(nrz_item)::type_id::create("sqr", this);
            drv = nrz_driver::type_id::create("drv", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        if(get_is_active() == UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqr.seq_item_export);
        end
    endfunction

endclass
`endif