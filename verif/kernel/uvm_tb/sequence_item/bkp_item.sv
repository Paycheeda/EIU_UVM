`ifndef BKP_ITEM_SV
`define BKP_ITEM_SV

class bkp_item extends uvm_sequence_item;

    // Transaction Data
    rand bit [3:0]  bkp_card_id;
    rand bit [3:0]  fpga_card_id;
    rand bit        bkp_data_dir;
    rand bit [5:0]  bkp_address;
    rand bit [11:0] bkp_data;

    // Testbench Control (Delay between writes)
    rand int delay_cycles;

    `uvm_object_utils_begin(bkp_item)
        `uvm_field_int(bkp_card_id,  UVM_ALL_ON)
        `uvm_field_int(fpga_card_id, UVM_ALL_ON)
        `uvm_field_int(bkp_data_dir, UVM_ALL_ON)
        `uvm_field_int(bkp_address,  UVM_ALL_ON)
        `uvm_field_int(bkp_data,     UVM_ALL_ON)
        `uvm_field_int(delay_cycles, UVM_ALL_ON | UVM_NOCOMPARE | UVM_NOPACK)
    `uvm_object_utils_end

    function new(string name = "bkp_item");
        super.new(name);
    endfunction

    // Constraints to easily hit the RTL's "cfg_wr_hit" condition
    constraint valid_hit_c {
        bkp_card_id == fpga_card_id;
        bkp_data_dir == 1'b1;
        bkp_address <= 6'd40; // Max valid address based on your RTL
    }

    // Keep delays small so simulation is fast
    constraint delay_c {
        delay_cycles inside {[1:5]};
    }

endclass

`endif