`ifndef KERNEL_CONFIG_SV
`define KERNEL_CONFIG_SV

class kernel_cfg extends uvm_object;
    `uvm_object_utils(kernel_cfg)

    // The virtual interfaces
    virtual bkp_intf bkp_vif;
    virtual out_intf out_vif;
    virtual kwr_intf kwr_vif; 
    virtual kst_intf kst_vif; 
    virtual krd_intf krd_vif; 
    
    // ---> NEW: NRZ INTERFACE <---
    virtual nrz_intf nrz_vif; 

    function new(string name = "kernel_cfg");
        super.new(name);
    endfunction

endclass

`endif