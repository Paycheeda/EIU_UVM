////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : out_monitor.sv
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
//  UVM monitor for Kernel output verification
////////////////////////////////////////////////////////////////////////////////

`ifndef OUT_MONITOR_SV
`define OUT_MONITOR_SV

class out_monitor extends uvm_monitor;
    `uvm_component_utils(out_monitor)
    
    virtual out_intf vif;
    uvm_analysis_port #(out_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual out_intf)::get(this, "", "out_vif", vif)) begin
            `uvm_fatal("NO_VIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
        end
    endfunction

    task run_phase(uvm_phase phase);
        out_item item; // <--- MOVED DECLARATION TO THE TOP!
        
        forever begin
            // 1. Wait for the primary kernel configuration pulse
            @(posedge vif.config_done_pulse);
            
            if (vif.rst_n) begin
                `uvm_info(get_type_name(), "Kernel config_done_pulse seen! Waiting for all CDC synchronizers...", UVM_HIGH)
                
                // 2. Wait for EVERY domain to generate its synchronized pulse!
                fork
                    @(posedge vif.config_done_uart);
                    @(posedge vif.config_done_eth1);
                    @(posedge vif.config_done_eth2);
                    @(posedge vif.config_done_eth3);
                    @(posedge vif.config_done_eth4);
                join
                
                `uvm_info(get_type_name(), "All 5 CDC pulses successfully received! Capturing golden snapshot...", UVM_HIGH)

                // 3. Create and Capture the data (Statement, not a declaration)
                item = out_item::type_id::create("item"); 
                
                // =========================================================
                // Map UARTs (0=UART1, 1=UART2, 2=UART3)
                // =========================================================
                item.baudrate_uart[0] = vif.baudrate_uart1;
                item.baudrate_uart[1] = vif.baudrate_uart2;
                item.baudrate_uart[2] = vif.baudrate_uart3;
                
                item.parity_en_uart[0] = vif.parity_en_uart1;
                item.parity_en_uart[1] = vif.parity_en_uart2;
                item.parity_en_uart[2] = vif.parity_en_uart3;

                item.parity_odd_even_uart[0] = vif.parity_odd_even_uart1;
                item.parity_odd_even_uart[1] = vif.parity_odd_even_uart2;
                item.parity_odd_even_uart[2] = vif.parity_odd_even_uart3;

                item.data_width_uart[0] = vif.data_width_uart1;
                item.data_width_uart[1] = vif.data_width_uart2;
                item.data_width_uart[2] = vif.data_width_uart3;

                // =========================================================
                // Map ETHs (0=ETH1, 1=ETH2, 2=ETH3, 3=ETH4, 4=ETH NRZ)
                // =========================================================
                item.dest_mac_eth[0] = vif.dest_mac_eth1;
                item.dest_mac_eth[1] = vif.dest_mac_eth2;
                item.dest_mac_eth[2] = vif.dest_mac_eth3;
                item.dest_mac_eth[3] = vif.dest_mac_eth4;
                item.dest_mac_eth[4] = vif.dest_mac_eth_nrz;

                item.source_mac_eth[0] = vif.source_mac_eth1;
                item.source_mac_eth[1] = vif.source_mac_eth2;
                item.source_mac_eth[2] = vif.source_mac_eth3;
                item.source_mac_eth[3] = vif.source_mac_eth4;
                item.source_mac_eth[4] = vif.source_mac_eth_nrz;

                item.source_ip_eth[0] = vif.source_ip_eth1;
                item.source_ip_eth[1] = vif.source_ip_eth2;
                item.source_ip_eth[2] = vif.source_ip_eth3;
                item.source_ip_eth[3] = vif.source_ip_eth4;
                item.source_ip_eth[4] = vif.source_ip_eth_nrz;

                item.dest_ip_eth[0] = vif.dest_ip_eth1;
                item.dest_ip_eth[1] = vif.dest_ip_eth2;
                item.dest_ip_eth[2] = vif.dest_ip_eth3;
                item.dest_ip_eth[3] = vif.dest_ip_eth4;
                item.dest_ip_eth[4] = vif.dest_ip_eth_nrz;

                item.source_port_eth[0] = vif.source_port_eth1;
                item.source_port_eth[1] = vif.source_port_eth2;
                item.source_port_eth[2] = vif.source_port_eth3;
                item.source_port_eth[3] = vif.source_port_eth4;
                item.source_port_eth[4] = vif.source_port_eth_nrz;

                item.dest_port_eth[0] = vif.dest_port_eth1;
                item.dest_port_eth[1] = vif.dest_port_eth2;
                item.dest_port_eth[2] = vif.dest_port_eth3;
                item.dest_port_eth[3] = vif.dest_port_eth4;
                item.dest_port_eth[4] = vif.dest_port_eth_nrz;

                item.tx_payload_length_eth[0] = vif.tx_payload_length_eth1;
                item.tx_payload_length_eth[1] = vif.tx_payload_length_eth2;
                item.tx_payload_length_eth[2] = vif.tx_payload_length_eth3;
                item.tx_payload_length_eth[3] = vif.tx_payload_length_eth4;
                item.tx_payload_length_eth[4] = vif.tx_payload_length_eth_nrz;

                // =========================================================
                // Map NRZ Specifics
                // =========================================================
                item.tx_zero_endian_eth_nrz = vif.tx_zero_endian_eth_nrz;
                item.tx_bpw_eth_nrz         = vif.tx_bpw_eth_nrz;
                item.tx_sync_word1_eth_nrz  = vif.tx_sync_word1_eth_nrz;
                item.tx_sync_word2_eth_nrz  = vif.tx_sync_word2_eth_nrz;

                // Send the captured snapshot to the Scoreboard!
                ap.write(item);
                
                `uvm_info(get_type_name(), "Output Configuration Snapshot Captured on ALL 5 DONE pulses!", UVM_LOW)
            end
        end
    endtask
endclass

`endif