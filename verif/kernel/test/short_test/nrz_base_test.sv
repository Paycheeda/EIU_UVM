`ifndef NRZ_BASE_TEST_SV
`define NRZ_BASE_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import kernel_pkg::*;

class nrz_base_test extends uvm_test;
    `uvm_component_utils(nrz_base_test)

    kernel_env  env;
    kernel_cfg  cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        cfg = kernel_cfg::type_id::create("cfg");

        // Retrieve existing interfaces
        if(!uvm_config_db#(virtual bkp_intf)::get(this, "", "bkp_vif", cfg.bkp_vif))
            `uvm_fatal("NO_VIF", "Could not get bkp_vif from config DB!")
            
        if(!uvm_config_db#(virtual out_intf)::get(this, "", "out_vif", cfg.out_vif))
            `uvm_fatal("NO_VIF", "Could not get out_vif from config DB!")
            
        // ---> Retrieve NEW NRZ Interface <---
        if(!uvm_config_db#(virtual nrz_intf)::get(this, "", "nrz_vif", cfg.nrz_vif))
            `uvm_fatal("NO_VIF", "Could not get nrz_vif from config DB!")

        uvm_config_db#(kernel_cfg)::set(this, "env", "kernel_cfg", cfg);

        env = kernel_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        nrz_sequence nrz_seq;
        nrz_seq = nrz_sequence::type_id::create("nrz_seq");

        phase.raise_objection(this, "Starting NRZ Serial Sequence");
        
        // Wait for system resets to complete
        #200ns; 

        `uvm_info("TEST", "Starting NRZ serial packet injection...", UVM_LOW)
        
        // Start the sequence on the NRZ Agent's Sequencer
        nrz_seq.start(env.nrz_agt.sqr);
        
        // Wait a bit for the final packet to fully process through the FIFO
        #1000ns;
        
        phase.drop_objection(this, "Finished NRZ Serial Sequence");
    endtask

endclass
`endif