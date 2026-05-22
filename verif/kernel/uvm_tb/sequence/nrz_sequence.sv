`ifndef NRZ_SEQUENCE_SV
`define NRZ_SEQUENCE_SV

class nrz_sequence extends uvm_sequence #(nrz_item);
    `uvm_object_utils(nrz_sequence)

    // These must be set by the Top-Level Virtual Sequence (eiu_vseq.sv)
    bit [1:0]  cfg_bpw;
    bit        cfg_zero_endian;
    bit [11:0] cfg_sync_word1;
    bit [11:0] cfg_sync_word2;
    int        cfg_payload_len = 50; 
    int        cfg_num_packets = 1;  
    
    function new(string name = "nrz_sequence");
        super.new(name);
    endfunction

    task body();
        uvm_queue #(nrz_item) g_q;
        
        `uvm_info("NRZ_SEQ", "Starting Continuous NRZ Serial Injection...", UVM_LOW)

        // Fetch the Golden Queue from the Scoreboard
        if (!uvm_config_db#(uvm_queue#(nrz_item))::get(null, "", "golden_nrz_q", g_q)) begin
            `uvm_error("NRZ_SEQ", "CRITICAL: Could not find golden_nrz_q in config DB!")
        end

        // Uses the dynamic Plusarg packet count
        repeat(cfg_num_packets) begin
            req = nrz_item::type_id::create("req");
            start_item(req);
            
            req.bpw         = cfg_bpw;
            req.zero_endian = cfg_zero_endian;
            req.sync_word1  = cfg_sync_word1;
            req.sync_word2  = cfg_sync_word2;
            
            // Generate the dynamic payload based on the requested length plusarg
            req.generate_payload((cfg_payload_len-2), cfg_bpw);
            
            finish_item(req);
            
            // =================================================================
            // BACKDOOR INJECTION: Push the Golden NRZ Packet to Scoreboard
            // =================================================================
            if (g_q != null) g_q.push_back(req);
            
            get_response(rsp);
            
            // Inter-packet gap (Reduced slightly to keep EIU simulation fast)
            #( 100 * 1us );
        end
    endtask
endclass

`endif