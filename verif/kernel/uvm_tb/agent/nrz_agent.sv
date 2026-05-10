`ifndef NRZ_AGENT_SV
`define NRZ_AGENT_SV

class nrz_agent extends uvm_agent;
    `uvm_component_utils(nrz_agent)

    uvm_sequencer #(nrz_item) sqr;
    nrz_driver                drv;
    nrz_monitor               mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        sqr = uvm_sequencer#(nrz_item)::type_id::create("sqr", this);
        drv = nrz_driver::type_id::create("drv", this);
        mon = nrz_monitor::type_id::create("mon", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Connect the driver to the sequencer
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction

endclass
`endif