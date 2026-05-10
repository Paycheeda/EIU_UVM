`ifndef KWR_SEQUENCE_SV
`define KWR_SEQUENCE_SV

class kwr_routing_seq extends uvm_sequence #(bkp_item);
    `uvm_object_utils(kwr_routing_seq)

    bit [3:0] test_card_id = 4'hA; 
    
    // Set how many random bursts you want to send per FIFO
    int num_packets = 5; 

    function new(string name = "kwr_routing_seq");
        super.new(name);
    endfunction

    task body();
        bit [8:0] rand_uart_payload;
        bit [7:0] rand_eth_payload;
        
        `uvm_info("SEQ", $sformatf("Starting BACK-TO-BACK Burst Test with RANDOM Data: %0d Packets per FIFO...", num_packets), UVM_LOW)

        for (int p = 1; p <= num_packets; p++) begin
            
            // ==========================================
            // 1. Blast UARTs with Random Data
            // ==========================================
            for (int addr = 41; addr <= 43; addr++) begin
                
                // Get a fresh random 9-bit payload
                rand_uart_payload = $urandom(); 
                
                // --- WRITE COMMAND ---
                req = bkp_item::type_id::create("req");
                start_item(req);
                req.bkp_address  = addr;
                req.bkp_card_id  = test_card_id;
                req.fpga_card_id = test_card_id;
                req.bkp_data_dir = 1'b1;
                // Assemble: {padding, send_cmd=0, 9-bit random payload}
                req.bkp_data     = {2'b00, 1'b0, rand_uart_payload}; 
                req.delay_cycles = 3; // 3-cycle FSM reset delay
                finish_item(req);

                // Get another fresh random payload for the send command
                rand_uart_payload = $urandom(); 
                
                // --- SEND COMMAND ---
                req = bkp_item::type_id::create("req");
                start_item(req);
                req.bkp_address  = addr;
                req.bkp_card_id  = test_card_id;
                req.fpga_card_id = test_card_id;
                req.bkp_data_dir = 1'b1;
                // Assemble: {padding, send_cmd=1, 9-bit random payload}
                req.bkp_data     = {2'b00, 1'b1, rand_uart_payload}; 
                req.delay_cycles = 3; 
                finish_item(req);
            end

            // ==========================================
            // 2. Blast ETHERNETs with Random Data
            // ==========================================
            for (int addr = 44; addr <= 47; addr++) begin
                
                // Get a fresh random 8-bit payload
                rand_eth_payload = $urandom();
                
                // --- WRITE COMMAND ---
                req = bkp_item::type_id::create("req");
                start_item(req);
                req.bkp_address  = addr;
                req.bkp_card_id  = test_card_id;
                req.fpga_card_id = test_card_id;
                req.bkp_data_dir = 1'b1;
                // Assemble: {padding, send_cmd=0, 8-bit random payload}
                req.bkp_data     = {3'b000, 1'b0, rand_eth_payload}; 
                req.delay_cycles = 3;
                finish_item(req);

                // Get another fresh random payload for the send command
                rand_eth_payload = $urandom();
                
                // --- SEND COMMAND ---
                req = bkp_item::type_id::create("req");
                start_item(req);
                req.bkp_address  = addr;
                req.bkp_card_id  = test_card_id;
                req.fpga_card_id = test_card_id;
                req.bkp_data_dir = 1'b1;
                // Assemble: {padding, send_cmd=1, 8-bit random payload}
                req.bkp_data     = {3'b000, 1'b1, rand_eth_payload}; 
                req.delay_cycles = 3;
                finish_item(req);
            end
        end
        
        `uvm_info("SEQ", "Random Burst Sequence Complete! Pipeline flushing...", UVM_LOW)
        #200ns;
    endtask
endclass

`endif