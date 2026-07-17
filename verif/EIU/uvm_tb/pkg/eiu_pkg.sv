////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : eiu_pkg.sv
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
//  UVM package for EIU verification
////////////////////////////////////////////////////////////////////////////////

`ifndef EIU_PKG_SV
`define EIU_PKG_SV

package eiu_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // ==========================================
    // 1. Import ALL Sub-System Packages
    // ==========================================
    import kernel_pkg::*;
    import uart_pkg::*;
    import eth_pkg::*;
    import eth_rx_pkg::*;  // <-- THE MISSING LINK FOR phy_rx_agent
    import mac_rx_pkg::*;
    import rx_fifo_pkg::*;

    // ==========================================
    // 2. System Level Config & Environment
    // ==========================================
    `include "eiu_config.sv"
    `include "eiu_vsqr.sv"
    `include "eiu_vseq.sv"
    `include "eiu_scoreboard.sv" 
    `include "eiu_env.sv"

    // NOTE: eiu_base_test.sv is NOT included here! 
    // It is compiled separately on the command line.
endpackage

`endif