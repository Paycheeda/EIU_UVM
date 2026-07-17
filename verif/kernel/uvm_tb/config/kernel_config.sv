////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : kernel_config.sv
//  Author        : Ahmed Ali
//  Creation Date : 16/04/2026
//
//  Copyright 2026 Avant Labs PVT LTD. All Rights Reserved.
//
//  No portions of this material may be reproduced in any form without
//  the written permission of:
//
//    First Floor, Jumaira Arcade,
//    Fateh Jang Road,
//    Sector F-17, Islamabad, 45230
//
//  All information contained in this document is Avant Labs PVT LTD
//  company private, proprietary and trade secret.
//
//  Description
//  ===========
//  UVM configuration object for kernel verification
////////////////////////////////////////////////////////////////////////////////

`ifndef KERNEL_CONFIG_SV
`define KERNEL_CONFIG_SV

class kernel_cfg extends uvm_object;
    `uvm_object_utils(kernel_cfg)

    // Kernel Internal Interfaces
    virtual bkp_intf bkp_vif;
    virtual out_intf out_vif;
    virtual kwr_intf kwr_vif; 
    virtual kst_intf kst_vif; 
    virtual krd_intf krd_vif;
    virtual nrz_intf nrz_vif; 

    // Peripheral Interfaces (From previous projects)
    // NOTE: Update these types if your actual interface names differ slightly!
    virtual uart_unified_intf uart_vifs[3];
    virtual eth_if            eth_vifs[5];

    function new(string name = "kernel_cfg");
        super.new(name);
    endfunction

endclass

`endif