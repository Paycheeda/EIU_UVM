`ifndef KERNEL_BASE_TEST_SV
`define KERNEL_BASE_TEST_SV

class kernel_base_test extends uvm_test;
    `uvm_component_utils(kernel_base_test)

    // Components
    kernel_env    env;
    kernel_config cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // 1. Create the Config Object
        cfg = kernel_config::type_id::create("cfg");

        // 2. Retrieve Virtual Interfaces from Top Level and put them in Config
        if(!uvm_config_db#(virtual bkp_intf)::get(this, "", "bkp_vif", cfg.bkp_vif))
            `uvm_fatal("NO_VIF", "Could not get bkp_vif from config DB!")
            
        if(!uvm_config_db#(virtual out_intf)::get(this, "", "out_vif", cfg.out_vif))
            `uvm_fatal("NO_VIF", "Could not get out_vif from config DB!")

        // 3. Set the Config Object for the Environment to find
        uvm_config_db#(kernel_config)::set(this, "env", "kernel_cfg", cfg);

        // 4. Build the Environment
        env = kernel_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        bkp_full_config_seq seq;
        seq = bkp_full_config_seq::type_id::create("seq");

        // Tell the simulator not to end the simulation while we are working
        phase.raise_objection(this, "Starting BKP Configuration Sequence");
        
        // Allow reset to pass 
        #200ns; 

        // Start the sequence on the Backplane Agent's Sequencer
        `uvm_info("TEST", "Starting sequence execution...", UVM_LOW)
        seq.start(env.bkp_agt.sqr);
        
        // Let the test end
        phase.drop_objection(this, "Finished BKP Configuration Sequence");
    endtask

endclass

`endif