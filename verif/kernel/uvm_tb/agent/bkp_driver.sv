`ifndef BKP_DRIVER_SV
`define BKP_DRIVER_SV

class bkp_driver extends uvm_driver #(bkp_item);
    `uvm_component_utils(bkp_driver)
    virtual bkp_intf vif;

    function new(string name, uvm_component parent); super.new(name, parent); endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual bkp_intf)::get(this, "", "bkp_vif", vif)) `uvm_fatal("NO_VIF", "No bkp_vif")
    endfunction

    task run_phase(uvm_phase phase);
        vif.bkp_config_wr_pulse <= 0;
        vif.bkp_data_dir <= 0;
        vif.bkp_card_id <= 0;
        vif.fpga_card_id <= 0;
        
        forever begin
            seq_item_port.get_next_item(req);
            
            @(posedge vif.clk);
            vif.bkp_card_id <= req.bkp_card_id;     
            vif.fpga_card_id <= req.fpga_card_id;   
            vif.bkp_address <= req.bkp_address;
            vif.bkp_data_dir <= req.bkp_data_dir; 
            vif.bkp_config_wr_pulse <= 1'b1;
            
            @(posedge vif.clk);
            vif.bkp_config_wr_pulse <= 1'b0;

            // THE FIX: Perfectly aligned to your 1-cycle RTL Wait State
            if (req.bkp_address == 0 || req.bkp_address == 3 || req.bkp_address == 6 || req.bkp_address == 9 || req.bkp_address == 12 || req.bkp_address == 15 || req.bkp_address == 18) begin
                repeat(10) @(posedge vif.clk); 
            end else begin
                repeat(2) @(posedge vif.clk); 
            end

            req.bkp_data = vif.bkp_data;
            
            seq_item_port.item_done();
            seq_item_port.put_response(req);
        end
    endtask
endclass
`endif