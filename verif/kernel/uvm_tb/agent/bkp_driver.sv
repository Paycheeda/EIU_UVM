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
        vif.bkp_config_wr_pulse <= 1'b0;
        vif.word_start_strobe   <= 1'b0;
        vif.bkp_data_dir        <= 1'b0;
        vif.program_mode        <= 1'b0;
        vif.bkp_card_id         <= 4'd0;
        vif.fpga_card_id        <= 4'd0;
        vif.bkp_address         <= 6'd0;
        vif.bkp_data_drive      <= 12'hZZZ;
        
        forever begin
            seq_item_port.get_next_item(req);
            
            // Drive every physical control pin from the sequence item.  The old
            // driver only updated card IDs (and the address only for config
            // writes), so reads after configuration were still hitting address
            // 40 with the bus left in the wrong direction.
            @(posedge vif.clk);
            vif.bkp_card_id     <= req.bkp_card_id;
            vif.fpga_card_id    <= req.fpga_card_id;
            vif.bkp_address     <= req.bkp_address;
            vif.bkp_data_dir    <= req.bkp_data_dir;
            vif.program_mode    <= req.program_mode;
            vif.bkp_data_drive  <= (req.bkp_data_dir) ? req.bkp_data : 12'hZZZ;
            
            // Let address, direction and data settle before pulsing the command.
            repeat(2) @(posedge vif.clk);

            if (req.trans_type == BKP_CFG_WRITE) begin
                // --- CONFIGURATION WRITE ---
                vif.bkp_config_wr_pulse <= 1'b1;
                @(posedge vif.clk);
                vif.bkp_config_wr_pulse <= 1'b0;
                vif.bkp_data_drive      <= 12'hZZZ;
                vif.bkp_data_dir        <= 1'b0;
                vif.program_mode        <= 1'b0;
                
            end else if (req.trans_type == BKP_DATA_WRITE) begin
                // --- PAYLOAD DATA WRITE ---
                vif.word_start_strobe <= 1'b1;
                @(posedge vif.clk);
                vif.word_start_strobe <= 1'b0;
                vif.bkp_data_drive    <= 12'hZZZ;
                vif.bkp_data_dir      <= 1'b0;
                
            end else if (req.trans_type == BKP_READ) begin
                // --- DATA READ ---
                vif.bkp_data_drive    <= 12'hZZZ;
                vif.word_start_strobe <= 1'b1;
                @(posedge vif.clk);
                vif.word_start_strobe <= 1'b0;
                
                // Deep wait to let kernel_read update bkp_data_reg and for CDC
                // status values to settle before returning the read data to the sequence.
                repeat(8) @(posedge vif.clk);
                req.bkp_data = vif.bkp_data;
            end
            
            seq_item_port.item_done();
        end
    endtask
endclass

`endif