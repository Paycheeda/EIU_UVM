`ifndef BKP_READ_SEQ_SV
`define BKP_READ_SEQ_SV

class bkp_read_seq extends uvm_sequence #(bkp_item);
    `uvm_object_utils(bkp_read_seq)

    function new(string name = "bkp_read_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info("BKP_READ_SEQ", "Starting CPU Backplane READ Sweep (Addresses 0 to 24)...", UVM_LOW)
        
        for (int i = 0; i <= 24; i++) begin
            req = bkp_item::type_id::create("req");
            
            start_item(req);
            
            // Hardcode the item to be a valid READ command for address 'i'
            req.bkp_card_id  = 4'hA; // Give it a dummy ID
            req.fpga_card_id = 4'hA; // Match the ID to trigger en_detect!
            req.bkp_data_dir = 1'b0; // 0 = READ
            req.bkp_address  = i;    // Sweep from 0 to 24
            
            finish_item(req);
        end
        
        `uvm_info("BKP_READ_SEQ", "Backplane READ Sweep Complete!", UVM_LOW)
    endtask

endclass

`endif