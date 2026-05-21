`ifndef BKP_DRIVER_SV
`define BKP_DRIVER_SV

class bkp_driver extends uvm_driver #(bkp_item);
    `uvm_component_utils(bkp_driver)
    
    virtual bkp_intf vif;

    function new(string name, uvm_component parent);
        super.new(name, parent); 
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual bkp_intf)::get(this, "", "bkp_vif", vif)) 
            `uvm_fatal("NO_VIF", "No bkp_vif found in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        // Initialize lines
        vif.bkp_config_wr_pulse <= 0;
        vif.word_start_strobe   <= 0;
        vif.bkp_data_dir        <= 0;
        vif.program_mode        <= 0;
        vif.bkp_card_id         <= 0;
        vif.fpga_card_id        <= 0;
        vif.bkp_data_drive      <= 0;
        
        forever begin
            seq_item_port.get_next_item(req);
            
            // 1. Setup Phase (Wait for a clean clock edge)
            @(posedge vif.clk);
            vif.bkp_card_id  <= req.bkp_card_id;
            vif.fpga_card_id <= req.fpga_card_id;
            
            // 2. Drive Phase based on transaction type
            if (req.trans_type == BKP_CFG_WRITE) begin
                // --- CONFIGURATION WRITE (Used for all 41 Init Addresses) ---
                vif.bkp_address <= req.bkp_address;
                vif.bkp_data_drive <= req.bkp_data;
                repeat(2) @(posedge vif.clk); 
                vif.bkp_config_wr_pulse <= 1'b1; // Config Pulse
                @(posedge vif.clk);
                vif.bkp_config_wr_pulse <= 1'b0;
                vif.bkp_data_drive      <= 12'hZZZ; 
                
            end else if (req.trans_type == BKP_DATA_WRITE) begin
                // --- PAYLOAD DATA WRITE ---
                vif.bkp_data_drive <= req.bkp_data;
                repeat(2) @(posedge vif.clk); 
                vif.word_start_strobe <= 1'b1; 
                @(posedge vif.clk);
                vif.word_start_strobe <= 1'b0;
                vif.bkp_data_drive      <= 12'hZZZ; 
                
            end else if (req.trans_type == BKP_READ) begin
                // --- DATA READ ---
                repeat(2) @(posedge vif.clk); 
                vif.word_start_strobe <= 1'b1;
                @(posedge vif.clk);
                vif.word_start_strobe <= 1'b0;
                
                // Deep Wait to let async FIFOs cross domains
                repeat(8) @(posedge vif.clk);
                
                req.bkp_data = vif.bkp_data;
            end
            
            seq_item_port.item_done();
        end
    endtask
endclass

`endif