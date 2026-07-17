////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : kst_monitor.sv
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
//  UVM monitor for Kernel KST verification
////////////////////////////////////////////////////////////////////////////////

`ifndef KST_MONITOR_SV
`define KST_MONITOR_SV

class kst_monitor extends uvm_monitor;
    `uvm_component_utils(kst_monitor)

    virtual kst_intf vif;
    uvm_analysis_port #(kst_item) ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual kst_intf)::get(this, "", "kst_vif", vif))
            `uvm_fatal("NO_VIF", "Could not find kst_vif in config DB!")
    endfunction

    task run_phase(uvm_phase phase);
        `uvm_info("KST_MON", "Starting Multi-Clock Domain Monitor Threads...", UVM_LOW)
        fork
            monitor_uart_done(1);
            monitor_uart_done(2);
            monitor_uart_done(3);
            monitor_eth_start(1);
            monitor_eth_start(2);
            monitor_eth_start(3);
            monitor_eth_start(4);
        join
    endtask

    // FIXED: Now we wait for the exact moment the signal transitions from 0 to 1!
    task monitor_uart_done(int id);
        forever begin
            if (id == 1) begin @(posedge vif.tx_data_sent_uart1); if (vif.rst_n) broadcast_pulse("UART1"); end
            if (id == 2) begin @(posedge vif.tx_data_sent_uart2); if (vif.rst_n) broadcast_pulse("UART2"); end
            if (id == 3) begin @(posedge vif.tx_data_sent_uart3); if (vif.rst_n) broadcast_pulse("UART3"); end
        end
    endtask

    // FIXED: Safely applying posedge to ETH as well
    task monitor_eth_start(int id);
        forever begin
            if (id == 1) begin @(posedge vif.eth_tx_start_pulse_eth1); if (vif.rst_n) broadcast_pulse("ETH1"); end
            if (id == 2) begin @(posedge vif.eth_tx_start_pulse_eth2); if (vif.rst_n) broadcast_pulse("ETH2"); end
            if (id == 3) begin @(posedge vif.eth_tx_start_pulse_eth3); if (vif.rst_n) broadcast_pulse("ETH3"); end
            if (id == 4) begin @(posedge vif.eth_tx_start_pulse_eth4); if (vif.rst_n) broadcast_pulse("ETH4"); end
        end
    endtask

    function void broadcast_pulse(string t_name);
        kst_item item = kst_item::type_id::create("item");
        item.target_name = t_name;
        ap.write(item);
        `uvm_info("KST_MON", item.convert2string(), UVM_HIGH)
    endfunction
endclass

`endif