////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : kernel_base_test.sv
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
//  base UVM test for kernel verification
////////////////////////////////////////////////////////////////////////////////

`ifndef KERNEL_BASE_TEST_SV
`define KERNEL_BASE_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import kernel_pkg::*;

class kernel_base_test extends uvm_test;
    `uvm_component_utils(kernel_base_test)

    // Components
    kernel_env  env;
    kernel_cfg  cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // 1. Create the Config Object
        cfg = kernel_cfg::type_id::create("cfg");

        // 2. Retrieve ALL Virtual Interfaces from Top Level and put them in Config
        if(!uvm_config_db#(virtual bkp_intf)::get(this, "", "bkp_vif", cfg.bkp_vif))
            `uvm_fatal("NO_VIF", "Could not get bkp_vif from config DB!")
        if(!uvm_config_db#(virtual out_intf)::get(this, "", "out_vif", cfg.out_vif))
            `uvm_fatal("NO_VIF", "Could not get out_vif from config DB!")
        if(!uvm_config_db#(virtual kwr_intf)::get(this, "", "kwr_vif", cfg.kwr_vif))
            `uvm_fatal("NO_VIF", "Could not get kwr_vif from config DB!")
        if(!uvm_config_db#(virtual kst_intf)::get(this, "", "kst_vif", cfg.kst_vif))
            `uvm_fatal("NO_VIF", "Could not get kst_vif from config DB!")
        if(!uvm_config_db#(virtual krd_intf)::get(this, "", "krd_vif", cfg.krd_vif))
            `uvm_fatal("NO_VIF", "Could not get krd_vif from config DB!")
        if(!uvm_config_db#(virtual nrz_intf)::get(this, "", "nrz_vif", cfg.nrz_vif))
            `uvm_fatal("NO_VIF", "Could not get nrz_vif from config DB!")

        // 3. Set the Config Object for the Environment to find
        uvm_config_db#(kernel_cfg)::set(this, "env", "kernel_cfg", cfg);

        // 4. Build the Environment
        env = kernel_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        bkp_sequence bkp_seq;
        bkp_seq = bkp_sequence::type_id::create("bkp_seq");

        // Set the Target ID for the sequence to match the EIU hardware
        bkp_seq.target_card_id = 4'hA; 

        // Tell the simulator not to end the simulation while we are working
        phase.raise_objection(this, "Starting BKP Configuration Sequence");
        
        // Allow reset to pass 
        #200ns; 

        // Start the sequence on the Backplane Agent's Sequencer
        `uvm_info("TEST", "Starting Backplane Configuration Sequence...", UVM_LOW)
        bkp_seq.start(env.bkp_agt.sqr);
        
        // Let the test end
        phase.drop_objection(this, "Finished BKP Configuration Sequence");
    endtask

endclass

`endif