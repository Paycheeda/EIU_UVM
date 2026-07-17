////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : eiu_vsqr.sv
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
//  UVM virtual sequencer for EIU verification
////////////////////////////////////////////////////////////////////////////////

`ifndef EIU_VSQR_SV
`define EIU_VSQR_SV

class eiu_vsqr extends uvm_sequencer;
    `uvm_component_utils(eiu_vsqr)

    // Handles to the physical Master sequencers
    uvm_sequencer #(bkp_item) bkp_sqr;
    uvm_sequencer #(nrz_item) nrz_sqr;

    // Handles to the physical Peripheral sequencers
    // Note: Replace 'tx_uart' and 'phy_rx_seq_item' with the exact item names your UART/ETH sequencers use
    uvm_sequencer #(tx_uart)         uart_rx_sqr[3]; 
    uvm_sequencer #(phy_rx_seq_item) eth_rx_sqr[4];

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass

`endif