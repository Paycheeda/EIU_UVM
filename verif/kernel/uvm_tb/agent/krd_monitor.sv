////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : krd_monitor.sv
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
//  UVM monitor for Kernel KRD verification
////////////////////////////////////////////////////////////////////////////////

`ifndef KRD_MONITOR_SV
`define KRD_MONITOR_SV

class krd_monitor extends uvm_monitor;
    `uvm_component_utils(krd_monitor)
    virtual bkp_intf vif;
    uvm_analysis_port #(bkp_item) ap;

    function new(string name, uvm_component parent); super.new(name, parent); ap = new("ap", this); endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual bkp_intf)::get(this, "", "bkp_vif", vif)) `uvm_fatal("NO_VIF", "No bkp_vif")
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            @(posedge vif.clk);
            if (vif.rst_n && vif.bkp_config_wr_pulse && !vif.bkp_data_dir && vif.bkp_card_id == vif.fpga_card_id) begin
                fork capture_read_data(vif.bkp_address); join_none
            end
        end
    endtask

    task capture_read_data(int addr);
        bkp_item item = bkp_item::type_id::create("item");
        item.bkp_address = addr;
        item.bkp_data_dir = 0; 

        // THE FIX: Perfectly aligned to the Driver
        if (addr == 0 || addr == 3 || addr == 6 || addr == 9 || addr == 12 || addr == 15 || addr == 18) begin
            repeat(6) @(posedge vif.clk); 
        end else begin
            repeat(3) @(posedge vif.clk); 
        end

        item.bkp_data = vif.bkp_data; 
        
        `uvm_info("KRD_MON", $sformatf("Captured READ Data -> Addr: %0d, Data: 'h%0h", addr, item.bkp_data), UVM_LOW)
        ap.write(item);
    endtask
endclass
`endif