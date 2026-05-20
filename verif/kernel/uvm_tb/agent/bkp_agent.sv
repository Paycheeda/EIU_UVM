`ifndef BKP_AGENT_SV
`define BKP_AGENT_SV

class bkp_agent extends uvm_agent;
    `uvm_component_utils(bkp_agent)
    
    uvm_sequencer #(bkp_item) sqr;
    bkp_driver                drvr;
    bkp_monitor               mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        mon = bkp_monitor::type_id::create("mon", this);
        
        if(get_is_active() == UVM_ACTIVE) begin
            sqr  = uvm_sequencer#(bkp_item)::type_id::create("sqr", this);
            drvr = bkp_driver::type_id::create("drvr", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        if(get_is_active() == UVM_ACTIVE) begin
            drvr.seq_item_port.connect(sqr.seq_item_export);
        end
    endfunction
endclass

`endif