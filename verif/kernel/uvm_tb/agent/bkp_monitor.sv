////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : bkp_monitor.sv
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
//  UVM monitor for Kernel BKP verification
////////////////////////////////////////////////////////////////////////////////

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
        fork
            watch_writes();
            watch_reads();
        join
    endtask

    // Thread 1: Sniffing Config/Data Writes
    task watch_writes();
        forever begin
            @(posedge vif.clk);
            // ---> FIXED: Catch Config Pulses OR Data Write Strobes (data_dir == 1) <---
            if (vif.rst_n && (vif.bkp_config_wr_pulse || (vif.word_start_strobe && vif.bkp_data_dir == 1'b1))) begin
                bkp_item item = bkp_item::type_id::create("item");
                item.trans_type   = (vif.program_mode) ? BKP_CFG_WRITE : BKP_DATA_WRITE;
                item.bkp_card_id  = vif.bkp_card_id;
                item.fpga_card_id = vif.fpga_card_id;
                item.bkp_data_dir = vif.bkp_data_dir;
                item.program_mode = vif.program_mode;
                item.bkp_address  = vif.bkp_address;
                item.bkp_data     = vif.bkp_data; 
                
                `uvm_info("BKP_MON_WRITE", $sformatf("Captured Write: Addr=%0d, Data='h%0x", item.bkp_address, item.bkp_data), UVM_HIGH)
                ap.write(item);
            end
        end
    endtask

    // Thread 2: Sniffing Status/Data Reads
    task watch_reads();
        forever begin
            @(posedge vif.clk);
            // ---> FIXED: Ensure we only trigger Reads when data_dir == 0 <---
            if (vif.rst_n && vif.word_start_strobe && vif.bkp_data_dir == 1'b0) begin
                fork
                    begin
                        bkp_item item = bkp_item::type_id::create("item");
                        item.trans_type   = BKP_READ;
                        item.bkp_card_id  = vif.bkp_card_id;
                        item.fpga_card_id = vif.fpga_card_id;
                        item.bkp_data_dir = vif.bkp_data_dir;
                        item.program_mode = vif.program_mode;
                        item.bkp_address  = vif.bkp_address;
                        
                        // Match the driver's wait time for CDC resolution
                        repeat(2) @(posedge vif.clk);
                        
                        item.bkp_data = vif.bkp_data; // Sample what the EIU is outputting
                        
                        `uvm_info("BKP_MON_READ", $sformatf("Captured Read: Addr=%0d, Data='h%0x", item.bkp_address, item.bkp_data), UVM_HIGH)
                        ap.write(item);
                    end
                join_none
            end
        end
    endtask

endclass

`endif