`ifndef KST_AGENT_SV
`define KST_AGENT_SV

class kst_agent extends uvm_agent;
    `uvm_component_utils(kst_agent)

    kst_driver  drv;
    kst_monitor mon; // <-- ADDED: Monitor handle

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        // Instantiate the driver and monitor
        if(get_is_active() == UVM_ACTIVE) begin
            drv = kst_driver::type_id::create("drv", this);
        end
        mon = kst_monitor::type_id::create("mon", this); // <-- ADDED: Build monitor
    endfunction

endclass

`endif