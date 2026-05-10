`ifndef KST_BASE_TEST_SV
`define KST_BASE_TEST_SV

class kst_base_test extends uvm_test;
    `uvm_component_utils(kst_base_test)

    kernel_env    env;
    kernel_cfg    cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        cfg = kernel_cfg::type_id::create("cfg");

        // Grab all VIFs
        if(!uvm_config_db#(virtual bkp_intf)::get(this, "", "bkp_vif", cfg.bkp_vif)) `uvm_fatal("NO_VIF", "No bkp_vif")
        if(!uvm_config_db#(virtual out_intf)::get(this, "", "out_vif", cfg.out_vif)) `uvm_fatal("NO_VIF", "No out_vif")
        if(!uvm_config_db#(virtual kwr_intf)::get(this, "", "kwr_vif", cfg.kwr_vif)) `uvm_fatal("NO_VIF", "No kwr_vif")
        if(!uvm_config_db#(virtual kst_intf)::get(this, "", "kst_vif", cfg.kst_vif)) `uvm_fatal("NO_VIF", "No kst_vif") // NEW

        uvm_config_db#(kernel_cfg)::set(this, "env", "kernel_cfg", cfg);
        env = kernel_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        kwr_routing_seq seq;
        seq = kwr_routing_seq::type_id::create("seq");

        phase.raise_objection(this, "Starting KST Test");
        
        #200ns; 
        
        `uvm_info("TEST", "Starting Kernel Start TX Handshake test...", UVM_LOW)
        
        // We reuse the exact same random sequence!
        seq.start(env.bkp_agt.sqr);
        
        // Give the UART FIFOs time to fully drain and the CDC syncs to clear
        #2000ns; 
        
        phase.drop_objection(this, "Finished KST Test");
    endtask

endclass

`endif