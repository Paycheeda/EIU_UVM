////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : out_agent.sv
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
//  UVM agent for Kernel output verification
////////////////////////////////////////////////////////////////////////////////

`ifndef OUT_AGENT_SV
`define OUT_AGENT_SV

class out_agent extends uvm_agent;
    `uvm_component_utils(out_agent)

    out_monitor mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Always build the monitor
        mon = out_monitor::type_id::create("mon", this);
    endfunction

endclass

`endif