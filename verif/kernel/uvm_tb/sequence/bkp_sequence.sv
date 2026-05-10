`ifndef BKP_SEQUENCE_SV
`define BKP_SEQUENCE_SV

class bkp_full_config_seq extends uvm_sequence #(bkp_item);
    `uvm_object_utils(bkp_full_config_seq)

    // Arbitrary card ID to use for this test to ensure hit condition
    bit [3:0] test_card_id = 4'hA; 

    function new(string name = "bkp_full_config_seq");
        super.new(name);
    endfunction

    // Helper function to mimic RTL's required_writes logic
    function int get_required_writes(int addr);
        if (addr <= 2) return 4;
        else if (addr <= 37) begin
            int e_fld = (addr - 3) % 7;
            case(e_fld)
                0, 1, 2, 3: return 4;
                4, 5: return 2;
                6: return 1;
                default: return 0;
            endcase
        end
        else if (addr <= 40) return 1;
        return 0;
    endfunction

    task body();
        int req_writes;
        
        `uvm_info("SEQ", "Starting Full Backplane Configuration Sequence...", UVM_LOW)

        // Loop through all 41 valid configuration addresses
        for (int addr = 0; addr <= 40; addr++) begin
            req_writes = get_required_writes(addr);
            
            // Generate the exact number of writes required for this address
            for (int w = 0; w < req_writes; w++) begin
                
                // 1. Create the item manually
                req = bkp_item::type_id::create("req");
                
                // 2. Start the transaction (wait for driver)
                start_item(req);
                
                // 3. MANUAL ASSIGNMENT (Bypassing randomize() license restriction)
                req.bkp_address  = addr;
                req.bkp_card_id  = test_card_id;
                req.fpga_card_id = test_card_id;
                req.bkp_data_dir = 1'b1;


                
                // Create some deterministic dummy data based on the address and write cycle
                req.bkp_data     = (addr * 10) + w; 
                req.delay_cycles = 1; // 1 cycle delay between writes
                
                // ---> ADDED THIS X-RAY PRINT <---
                `uvm_info("SEQ_TRAFFIC", $sformatf("Generating -> Addr: %2d | Write %0d of %0d | Data: 'h%03x", 
                                                    addr, w+1, req_writes, req.bkp_data), UVM_LOW)


                // 4. Send it to the driver
                finish_item(req);
                
            end
        end
        
        `uvm_info("SEQ", "Full Configuration Sequence Complete! Sent all required writes.", UVM_LOW)
        
        // Add a small delay at the end to allow the DUT to assert config_done_pulse 
        // and the Scoreboard to finish its comparisons before ending the test.
        #500ns;
        
    endtask
endclass

`endif