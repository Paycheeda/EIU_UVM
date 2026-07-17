////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : kwr_monitor.sv
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
//  UVM monitor for Kernel KWR verification
////////////////////////////////////////////////////////////////////////////////

`ifndef KWR_MONITOR_SV
`define KWR_MONITOR_SV

class kwr_monitor extends uvm_monitor;
    `uvm_component_utils(kwr_monitor)
    
    virtual kwr_intf vif;
    uvm_analysis_port #(kwr_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual kwr_intf)::get(this, "", "kwr_vif", vif)) begin
            `uvm_fatal("NO_VIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
        end
    endfunction

    task run_phase(uvm_phase phase);
        kwr_item item;
        forever begin
            @(posedge vif.clk);
            
            // Only capture if we are out of reset
            if (vif.rst_n) begin
                
                // ==========================================
                // UART Checks
                // ==========================================
                if (vif.fifo_wr_en_uart1 || vif.data_send_uart1) begin
                    send_item(UART1, vif.fifo_data_in_uart1, vif.fifo_wr_en_uart1, vif.data_send_uart1);
                end
                else if (vif.fifo_wr_en_uart2 || vif.data_send_uart2) begin
                    send_item(UART2, vif.fifo_data_in_uart2, vif.fifo_wr_en_uart2, vif.data_send_uart2);
                end
                else if (vif.fifo_wr_en_uart3 || vif.data_send_uart3) begin
                    send_item(UART3, vif.fifo_data_in_uart3, vif.fifo_wr_en_uart3, vif.data_send_uart3);
                end
                
                // ==========================================
                // ETHERNET Checks
                // ==========================================
                else if (vif.fifo_wr_en_eth1 || vif.data_send_eth1) begin
                    send_item(ETH1, vif.fifo_data_in_eth1, vif.fifo_wr_en_eth1, vif.data_send_eth1);
                end
                else if (vif.fifo_wr_en_eth2 || vif.data_send_eth2) begin
                    send_item(ETH2, vif.fifo_data_in_eth2, vif.fifo_wr_en_eth2, vif.data_send_eth2);
                end
                else if (vif.fifo_wr_en_eth3 || vif.data_send_eth3) begin
                    send_item(ETH3, vif.fifo_data_in_eth3, vif.fifo_wr_en_eth3, vif.data_send_eth3);
                end
                else if (vif.fifo_wr_en_eth4 || vif.data_send_eth4) begin
                    send_item(ETH4, vif.fifo_data_in_eth4, vif.fifo_wr_en_eth4, vif.data_send_eth4);
                end

            end
        end
    endtask

    // Helper function to keep the run_phase clean
    function void send_item(kwr_target_e target_id, bit [8:0] data, bit write_flag, bit send_flag);
        kwr_item item = kwr_item::type_id::create("item");
        item.target   = target_id;
        item.payload  = data;
        item.is_write = write_flag;
        item.is_send  = send_flag;
        
        ap.write(item);
        
        `uvm_info("KWR_MONITOR", $sformatf("Captured Router Output -> %s", item.convert2string()), UVM_HIGH)
    endfunction

endclass

`endif