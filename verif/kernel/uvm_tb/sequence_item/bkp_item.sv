////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : bkp_item.sv
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
//  UVM sequence item for Kernel BKP verification
////////////////////////////////////////////////////////////////////////////////

`ifndef BKP_ITEM_SV
`define BKP_ITEM_SV

typedef enum bit [1:0] {
    BKP_CFG_WRITE  = 2'b00, 
    BKP_DATA_WRITE = 2'b01, 
    BKP_READ       = 2'b10  
} bkp_trans_type_e;

class bkp_item extends uvm_sequence_item;

    // ------------------------------------------
    // Transaction Control & Data (Removed 'rand')
    // ------------------------------------------
    bkp_trans_type_e trans_type;

    bit [3:0]  bkp_card_id;
    bit [3:0]  fpga_card_id;
    bit        bkp_data_dir;
    bit        program_mode;
    bit [5:0]  bkp_address;
    bit [11:0] bkp_data;

    // ------------------------------------------
    // Testbench Control (Removed 'rand')
    // ------------------------------------------
    int delay_cycles;

    `uvm_object_utils_begin(bkp_item)
        `uvm_field_enum(bkp_trans_type_e, trans_type, UVM_ALL_ON)
        `uvm_field_int(bkp_card_id,  UVM_ALL_ON)
        `uvm_field_int(fpga_card_id, UVM_ALL_ON)
        `uvm_field_int(bkp_data_dir, UVM_ALL_ON)
        `uvm_field_int(program_mode, UVM_ALL_ON)
        `uvm_field_int(bkp_address,  UVM_ALL_ON)
        `uvm_field_int(bkp_data,     UVM_ALL_ON)
        `uvm_field_int(delay_cycles, UVM_ALL_ON | UVM_NOCOMPARE | UVM_NOPACK)
    `uvm_object_utils_end

    function new(string name = "bkp_item");
        super.new(name);
    endfunction

    // ============================================================================
    // CUSTOM RANDOMIZATION (Bypassing free ModelSim limitations)
    // ============================================================================
    function void randomize_item();
        int type_choice = $urandom_range(0, 2);
        
        if (type_choice == 0)      trans_type = BKP_CFG_WRITE;
        else if (type_choice == 1) trans_type = BKP_DATA_WRITE;
        else                       trans_type = BKP_READ;

        // Default valid hit assignments
        bkp_card_id  = 4'h0; //$urandom_range(0, 15);
        fpga_card_id = bkp_card_id; // Match IDs so EIU listens
        bkp_address  = $urandom_range(0, 48); // Max valid address
        bkp_data     = $urandom_range(0, 4095);
        
        delay_cycles = $urandom_range(1, 5);

        // Apply physical pin rules based on the chosen trans_type
        apply_trans_type_rules();
    endfunction

    // Explicitly drives the low-level pins to match the high-level intent
    function void apply_trans_type_rules();
        if (trans_type == BKP_CFG_WRITE) begin
            bkp_data_dir = 1'b1;
            program_mode = 1'b1;
        end 
        else if (trans_type == BKP_DATA_WRITE) begin
            bkp_data_dir = 1'b1;
            program_mode = 1'b0;
        end 
        else if (trans_type == BKP_READ) begin
            bkp_data_dir = 1'b0;
            program_mode = 1'b0; 
        end
    endfunction

endclass

`endif
/*
`ifndef BKP_ITEM_SV
`define BKP_ITEM_SV

typedef enum bit [1:0] {
    BKP_CFG_WRITE  = 2'b00, 
    BKP_DATA_WRITE = 2'b01, 
    BKP_READ       = 2'b10  
} bkp_trans_type_e;

class bkp_item extends uvm_sequence_item;

    // ------------------------------------------
    // Transaction Control & Data (Removed 'rand')
    // ------------------------------------------
    bkp_trans_type_e trans_type;

    bit [3:0]  bkp_card_id;
    bit [3:0]  fpga_card_id;
    bit        bkp_data_dir;
    bit        program_mode;
    bit [5:0]  bkp_address;
    bit [11:0] bkp_data;

    // ------------------------------------------
    // Testbench Control (Removed 'rand')
    // ------------------------------------------
    int delay_cycles;

    `uvm_object_utils_begin(bkp_item)
        `uvm_field_enum(bkp_trans_type_e, trans_type, UVM_ALL_ON)
        `uvm_field_int(bkp_card_id,  UVM_ALL_ON)
        `uvm_field_int(fpga_card_id, UVM_ALL_ON)
        `uvm_field_int(bkp_data_dir, UVM_ALL_ON)
        `uvm_field_int(program_mode, UVM_ALL_ON)
        `uvm_field_int(bkp_address,  UVM_ALL_ON)
        `uvm_field_int(bkp_data,     UVM_ALL_ON)
        `uvm_field_int(delay_cycles, UVM_ALL_ON | UVM_NOCOMPARE | UVM_NOPACK)
    `uvm_object_utils_end

    function new(string name = "bkp_item");
        super.new(name);
    endfunction

    // ============================================================================
    // CUSTOM RANDOMIZATION (Bypassing free ModelSim limitations)
    // ============================================================================
    function void randomize_item();
        int type_choice = $urandom_range(0, 2);
        
        if (type_choice == 0)      trans_type = BKP_CFG_WRITE;
        else if (type_choice == 1) trans_type = BKP_DATA_WRITE;
        else                       trans_type = BKP_READ;

        // Default valid hit assignments
        bkp_card_id  = $urandom_range(0, 15);
        fpga_card_id = bkp_card_id; // Match IDs so EIU listens
        bkp_address  = $urandom_range(0, 47); // Max valid address
        bkp_data     = $urandom_range(0, 4095);
        
        delay_cycles = $urandom_range(1, 5);

        // Apply physical pin rules based on the chosen trans_type
        apply_trans_type_rules();
    endfunction

    // Explicitly drives the low-level pins to match the high-level intent
    function void apply_trans_type_rules();
        if (trans_type == BKP_CFG_WRITE) begin
            bkp_data_dir = 1'b1;
            program_mode = 1'b1;
        end 
        else if (trans_type == BKP_DATA_WRITE) begin
            bkp_data_dir = 1'b1;
            program_mode = 1'b0;
        end 
        else if (trans_type == BKP_READ) begin
            bkp_data_dir = 1'b0;
            program_mode = 1'b0; 
        end
    endfunction

endclass

`endif*/