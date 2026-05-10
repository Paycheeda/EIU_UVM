`ifndef KRD_BASE_TEST_SV
`define KRD_BASE_TEST_SV

class krd_base_test extends uvm_test;
    `uvm_component_utils(krd_base_test)

    kernel_env    env;
    kernel_cfg    cfg;

    function new(string name, uvm_component parent); super.new(name, parent); endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cfg = kernel_cfg::type_id::create("cfg");
        if(!uvm_config_db#(virtual bkp_intf)::get(this, "", "bkp_vif", cfg.bkp_vif)) `uvm_fatal("NO_VIF", "No bkp_vif")
        if(!uvm_config_db#(virtual out_intf)::get(this, "", "out_vif", cfg.out_vif)) `uvm_fatal("NO_VIF", "No out_vif")
        if(!uvm_config_db#(virtual kwr_intf)::get(this, "", "kwr_vif", cfg.kwr_vif)) `uvm_fatal("NO_VIF", "No kwr_vif")
        if(!uvm_config_db#(virtual kst_intf)::get(this, "", "kst_vif", cfg.kst_vif)) `uvm_fatal("NO_VIF", "No kst_vif") 
        if(!uvm_config_db#(virtual krd_intf)::get(this, "", "krd_vif", cfg.krd_vif)) `uvm_fatal("NO_VIF", "No krd_vif") 

        uvm_config_db#(kernel_cfg)::set(this, "env", "kernel_cfg", cfg);
        env = kernel_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        krd_sequence  krd_seq;
        bkp_smart_seq bkp_smart;
        
        krd_seq   = krd_sequence::type_id::create("krd_seq");
        bkp_smart = bkp_smart_seq::type_id::create("bkp_smart");

        phase.raise_objection(this, "Starting KRD Smart Test");
        
        #500ns; 

        // THE FIX: Fork the network into the background
        fork
            krd_seq.start(env.krd_agt.sqr);
        join_none
        
        // THE FIX: Let the CPU strictly dictate the test length
        repeat(25) begin 
            bkp_smart.start(env.bkp_agt.sqr);
            #2000ns; 
        end
        
        #500ns; 
        phase.drop_objection(this, "Finished KRD Smart Test");
    endtask
endclass
`endif