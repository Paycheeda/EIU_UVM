`ifndef NRZ_DRIVER_SV
`define NRZ_DRIVER_SV

class nrz_driver extends uvm_driver #(nrz_item);
    `uvm_component_utils(nrz_driver)
    
    virtual nrz_intf vif;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual nrz_intf)::get(this, "", "nrz_vif", vif))
            `uvm_fatal("NO_VIF", "Could not find nrz_vif in config DB!")
    endfunction

    task run_phase(uvm_phase phase);
        vif.data_in_nrz <= 1'b0;
        
        forever begin
            seq_item_port.get_next_item(req);
            
            // Wait EXACTLY 1 posedge to align with the RTL's sample edge
            @(posedge vif.clk_20mhz);
            
            // Send Sync Words
            send_word(req.sync_word1, req.bpw, req.zero_endian);
            send_word(req.sync_word2, req.bpw, req.zero_endian);
            
            // Send Payload
            foreach(req.payload[i]) begin
                send_word(req.payload[i], req.bpw, req.zero_endian);
            end
            
            // PROTECT THE FINAL BIT: Wait two clock cycles before pulling the line low
            repeat(2) @(posedge vif.clk_20mhz);
            vif.data_in_nrz <= 1'b0;
            
            // Inter-packet Gap
            repeat(10) @(posedge vif.clk_20mhz);
            
            seq_item_port.item_done();
            seq_item_port.put_response(req);
        end
    endtask

    // FIXED: The RTL shifts left continuously: {word_in_buff[10:0], data_in_nrz}
    // This means the FIRST bit sent mathematically becomes the MSB.
    // The driver MUST always transmit MSB -> LSB sequentially!
    task send_word(bit [11:0] word, bit [1:0] bpw, bit zero_endian);
        int num_bits;
        
        case(bpw)
            2'd0: num_bits = 8;
            2'd1: num_bits = 9;
            2'd2: num_bits = 10;
            2'd3: num_bits = 12;
            default: num_bits = 8;
        endcase

        for (int i = 0; i < num_bits; i++) begin
            @(posedge vif.clk_20mhz);
            vif.data_in_nrz <= word[num_bits - 1 - i]; // Always MSB First
        end
    endtask

endclass
`endif