`ifndef NRZ_DRIVER_SV
`define NRZ_DRIVER_SV

class nrz_driver extends uvm_driver #(nrz_item);
    `uvm_component_utils(nrz_driver)
    
    virtual nrz_intf vif;
    virtual out_intf out_vif; 
    
    uvm_analysis_port #(nrz_item) ap_inject;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap_inject = new("ap_inject", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual nrz_intf)::get(this, "", "nrz_vif", vif))
            `uvm_fatal("NO_VIF", "Could not find nrz_vif in config DB!")
            
        if(!uvm_config_db#(virtual out_intf)::get(this, "", "out_vif", out_vif))
            `uvm_fatal("NO_VIF", "Could not find out_vif in config DB!")
    endfunction

    task run_phase(uvm_phase phase);
        int total_expected_words;
        
        vif.data_in_nrz <= 1'b0;
        out_vif.bkp_prg_mode_force <= 1'b0;
        
        forever begin
            seq_item_port.get_next_item(req);
            
            // Pass TOTAL WORD COUNT to the configuration
            total_expected_words = req.payload.size() + 2; 
            
            out_vif.drive_nrz_config(
                req.bpw, 
                req.zero_endian, 
                req.sync_word1, 
                req.sync_word2, 
                total_expected_words 
            );
            
            // ====================================================================
            // THE CDC PHASE-LOCK ALIGNMENT
            // ====================================================================
            out_vif.bkp_prg_mode_force <= 1'b1;
            vif.data_in_nrz <= 1'b0;
            repeat(5) @(posedge vif.clk_20mhz); 
            
            out_vif.bkp_prg_mode_force <= 1'b0;
            
            // Wait EXACTLY 1 posedge to align with the RTL's negedge wake-up
            @(posedge vif.clk_20mhz);
            // ====================================================================
            
            ap_inject.write(req);
            
            send_word(req.sync_word1, req.bpw);
            send_word(req.sync_word2, req.bpw);
            
            foreach(req.payload[i]) begin
                send_word(req.payload[i], req.bpw);
            end
            
            // ====================================================================
            // ---> FIXED: PROTECT THE FINAL BIT <---
            // Wait TWO full posedges so the RTL has a massive physical window 
            // to sample the final bit before we pull the line down to 0!
            // ====================================================================
            repeat(2) @(posedge vif.clk_20mhz);
            vif.data_in_nrz <= 1'b0;
            
            repeat(10) @(posedge vif.clk_20mhz);
            seq_item_port.item_done();
        end
    endtask

    task send_word(bit [11:0] word, bit [1:0] bpw);
        int num_bits;
        
        case(bpw)
            2'd0: num_bits = 8;
            2'd1: num_bits = 9;
            2'd2: num_bits = 10;
            2'd3: num_bits = 12;
            default: num_bits = 8;
        endcase

        for (int i = num_bits - 1; i >= 0; i--) begin
            @(posedge vif.clk_20mhz);
            vif.data_in_nrz <= word[i];
        end
    endtask

endclass
`endif