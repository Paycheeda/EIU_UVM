`ifndef BKP_MONITOR_SV
`define BKP_MONITOR_SV

class bkp_monitor extends uvm_monitor;
    `uvm_component_utils(bkp_monitor)
    
    virtual bkp_intf vif;
    uvm_analysis_port #(bkp_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual bkp_intf)::get(this, "", "bkp_vif", vif)) begin
            `uvm_fatal("NO_VIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
        end
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            @(posedge vif.clk);
            if (vif.rst_n && vif.bkp_config_wr_pulse) begin
                bkp_item item = bkp_item::type_id::create("item");
                
                item.bkp_card_id  = vif.bkp_card_id;
                item.fpga_card_id = vif.fpga_card_id;
                item.bkp_data_dir = vif.bkp_data_dir;
                item.bkp_address  = vif.bkp_address;
                item.bkp_data     = vif.bkp_data;
                
                ap.write(item);
            end
        end
    endtask
endclass

`endif