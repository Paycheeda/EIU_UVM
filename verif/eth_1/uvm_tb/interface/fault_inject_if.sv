////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : fault_inject_if.sv
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
//  SystemVerilog interface for Ethernet fault injection verification
////////////////////////////////////////////////////////////////////////////////

`ifndef FAULT_INJECT_IF_SV
`define FAULT_INJECT_IF_SV

interface fault_inject_if(input logic clk);
  import eth_pkg::*; // MUST IMPORT THE PACKAGE HERE!
  fault_t fault_type; 
endinterface

`endif