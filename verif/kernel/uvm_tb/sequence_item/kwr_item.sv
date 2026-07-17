////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : kwr_item.sv
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
//  UVM sequence item for Kernel KWR verification
////////////////////////////////////////////////////////////////////////////////

`ifndef KWR_ITEM_SV
`define KWR_ITEM_SV

// Enum to clearly identify which peripheral received the data
typedef enum {UART1, UART2, UART3, ETH1, ETH2, ETH3, ETH4} kwr_target_e;

class kwr_item extends uvm_sequence_item;

    // The abstracted transaction details
    kwr_target_e target;      // Who is this data for?
    bit [8:0]    payload;     // The actual sliced data (up to 9 bits for UART, 8 for ETH)
    bit          is_write;    // Was fifo_wr_en high?
    bit          is_send;     // Was data_send high?

    `uvm_object_utils_begin(kwr_item)
        `uvm_field_enum(kwr_target_e, target, UVM_ALL_ON)
        `uvm_field_int(payload,  UVM_ALL_ON)
        `uvm_field_int(is_write, UVM_ALL_ON)
        `uvm_field_int(is_send,  UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "kwr_item");
        super.new(name);
    endfunction

    // Helper function for clean printing in the log
    virtual function string convert2string();
        return $sformatf("Target: %5s | Write: %b | Send: %b | Payload: 'h%0x", 
                         target.name(), is_write, is_send, payload);
    endfunction

endclass

`endif