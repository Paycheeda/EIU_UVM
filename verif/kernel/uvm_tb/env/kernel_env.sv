////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : kernel_env.sv
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
//  UVM environment for kernel verification
////////////////////////////////////////////////////////////////////////////////

`ifndef KERNEL_ENV_SV
`define KERNEL_ENV_SV

class kernel_env extends uvm_env;
    `uvm_component_utils(kernel_env)

    // Kernel Specific Agents
    bkp_agent      bkp_agt;
    out_agent      out_agt;
    kwr_agent      kwr_agt;
    kst_agent      kst_agt;
    krd_agent      krd_agt;
    nrz_agent      nrz_agt;

    // Peripheral Agents (Reused from your existing folders)
    // Adjust class names if your UART/ETH top-level agents are named differently
    // uart_agent     uart_agts[3];
    // eth_agent      eth_agts[5];

    // Scoreboards
    scoreboard     scb;
    kwr_scoreboard kwr_scb;
    kst_scoreboard kst_scb;
    krd_scoreboard krd_scb;
    nrz_scoreboard nrz_scb;

    kernel_cfg     cfg;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if(!uvm_config_db#(kernel_cfg)::get(this, "", "kernel_cfg", cfg))
            `uvm_fatal("NO_CFG", "Could not find kernel_cfg in config DB!")

        // 1. Build Kernel Agents
        bkp_agt = bkp_agent::type_id::create("bkp_agt", this);
        out_agt = out_agent::type_id::create("out_agt", this);
        kwr_agt = kwr_agent::type_id::create("kwr_agt", this);
        kst_agt = kst_agent::type_id::create("kst_agt", this);
        krd_agt = krd_agent::type_id::create("krd_agt", this);
        nrz_agt = nrz_agent::type_id::create("nrz_agt", this);

        /* // 2. Build Peripheral Agents
        for(int i = 0; i < 3; i++) begin
            uart_agts[i] = uart_agent::type_id::create($sformatf("uart_agt_%0d", i), this);
            // Push specific VIF down to the specific UART agent
            uvm_config_db#(virtual uart_unified_intf)::set(this, $sformatf("uart_agt_%0d*", i), "uart_vif", cfg.uart_vifs[i]);
        end
        
        for(int i = 0; i < 5; i++) begin
            eth_agts[i] = eth_agent::type_id::create($sformatf("eth_agt_%0d", i), this);
            uvm_config_db#(virtual eth_if)::set(this, $sformatf("eth_agt_%0d*", i), "eth_vif", cfg.eth_vifs[i]);
        end
        */

        // 3. Build Scoreboards
        scb     = scoreboard::type_id::create("scb", this);
        kwr_scb = kwr_scoreboard::type_id::create("kwr_scb", this);
        kst_scb = kst_scoreboard::type_id::create("kst_scb", this);
        krd_scb = krd_scoreboard::type_id::create("krd_scb", this);
        nrz_scb = nrz_scoreboard::type_id::create("nrz_scb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        bkp_agt.mon.ap.connect(scb.bkp_fifo.analysis_export);
        out_agt.mon.ap.connect(scb.out_fifo.analysis_export);

        bkp_agt.mon.ap.connect(kwr_scb.bkp_fifo.analysis_export);
        kwr_agt.mon.ap.connect(kwr_scb.kwr_fifo.analysis_export);

        bkp_agt.mon.ap.connect(kst_scb.bkp_fifo.analysis_export);
        kst_agt.mon.ap.connect(kst_scb.kst_fifo.analysis_export);

        krd_agt.mon.ap.connect(krd_scb.read_fifo.analysis_export);
        nrz_agt.mon.ap.connect(nrz_scb.actual_fifo.analysis_export);
    endfunction
endclass

`endif