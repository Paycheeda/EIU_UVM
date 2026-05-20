`ifndef KRD_AGENT_SV
`define KRD_AGENT_SV

class krd_agent extends uvm_agent;
    `uvm_component_utils(krd_agent)

    uvm_sequencer #(krd_item) sqr;
    krd_driver  drv;
    krd_monitor mon; // <-- ADDED: Monitor handle

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if(get_is_active() == UVM_ACTIVE) begin
            sqr = uvm_sequencer#(krd_item)::type_id::create("sqr", this);
            drv = krd_driver::type_id::create("drv", this);
        end
        mon = krd_monitor::type_id::create("mon", this); // <-- ADDED: Build monitor
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if(get_is_active() == UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqr.seq_item_export);
        end
    endfunction
endclass

`endif