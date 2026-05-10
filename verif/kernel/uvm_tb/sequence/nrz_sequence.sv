`ifndef NRZ_SEQUENCE_SV
`define NRZ_SEQUENCE_SV

class nrz_sequence extends uvm_sequence #(nrz_item);
    `uvm_object_utils(nrz_sequence)

    function new(string name = "nrz_sequence");
        super.new(name);
    endfunction

    task body();
        int payload_size;
        int max_val;
        
        `uvm_info("NRZ_SEQ", "Starting Continuous NRZ Serial Injection...", UVM_LOW)

        repeat(50) begin
            req = nrz_item::type_id::create("req");
            start_item(req);
            
            req.bpw = $urandom_range(0, 3);
            req.zero_endian = $urandom_range(0, 1);
            
            case (req.bpw)
                2'd0: max_val = 255;  // 8 bits
                2'd1: max_val = 511;  // 9 bits
                2'd2: max_val = 1023; // 10 bits
                2'd3: max_val = 4095; // 12 bits
                default: max_val = 255;
            endcase
            
            // STRONG ALTERNATING SYNC WORDS
            // Ensures the RTL doesn't confuse a long string of 0's for a sync word
            if (req.bpw == 2'd0) begin
                req.sync_word1 = 8'hA5; 
                req.sync_word2 = 8'h5A;
            end else begin
                req.sync_word1 = 12'hA5A; 
                req.sync_word2 = 12'h5A5;
            end
            
            payload_size = $urandom_range(10, 50);
            req.payload = new[payload_size];
            
            foreach(req.payload[i]) begin
                req.payload[i] = $urandom_range(0, max_val);
            end
            
            finish_item(req);
            #( $urandom_range(500, 2000) * 1ns );
        end
        
        `uvm_info("NRZ_SEQ", "NRZ Serial Injection Complete.", UVM_LOW)
    endtask

endclass
`endif