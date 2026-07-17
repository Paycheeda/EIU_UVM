////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : kst_item.sv
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
//  UVM sequence item for Kernel KST verification
////////////////////////////////////////////////////////////////////////////////

`ifndef KST_ITEM_SV
`define KST_ITEM_SV

class kst_item extends uvm_sequence_item;
    `uvm_object_utils(kst_item)

    string target_name; // Swapped to string to avoid compiler enum issues

    function new(string name = "kst_item");
        super.new(name);
    endfunction

    virtual function string convert2string();
        return $sformatf("START/DONE PULSE DETECTED -> Target: %s", target_name);
    endfunction
endclass

`endif