`ifndef OUT_AGENT_SV
`define OUT_AGENT_SV

class out_agent extends uvm_agent;
    `uvm_component_utils(out_agent)

    out_monitor mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Always build the monitor
        mon = out_monitor::type_id::create("mon", this);
    endfunction

endclass

`endif