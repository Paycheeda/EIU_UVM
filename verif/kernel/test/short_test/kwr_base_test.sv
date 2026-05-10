`ifndef KWR_BASE_TEST_SV
`define KWR_BASE_TEST_SV

import uvm_pkg::*;
`include "uvm_macros.svh"
import kernel_pkg::*;

class kwr_base_test extends uvm_test;
    `uvm_component_utils(kwr_base_test)

    kernel_env    env;
    kernel_cfg    cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        cfg = kernel_cfg::type_id::create("cfg");

        if(!uvm_config_db#(virtual bkp_intf)::get(this, "", "bkp_vif", cfg.bkp_vif))
            `uvm_fatal("NO_VIF", "Could not get bkp_vif!")
            
        if(!uvm_config_db#(virtual out_intf)::get(this, "", "out_vif", cfg.out_vif))
            `uvm_fatal("NO_VIF", "Could not get out_vif!")
            
        if(!uvm_config_db#(virtual kwr_intf)::get(this, "", "kwr_vif", cfg.kwr_vif))
            `uvm_fatal("NO_VIF", "Could not get kwr_vif!")

        uvm_config_db#(kernel_cfg)::set(this, "env", "kernel_cfg", cfg);

        env = kernel_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        kwr_routing_seq seq;
        seq = kwr_routing_seq::type_id::create("seq");

        phase.raise_objection(this, "Starting KWR Sequence");
        
        #200ns; 

        `uvm_info("TEST", "Starting Kernel Write routing sequence...", UVM_LOW)
        seq.start(env.bkp_agt.sqr);
        
        phase.drop_objection(this, "Finished KWR Sequence");
    endtask

endclass

`endif