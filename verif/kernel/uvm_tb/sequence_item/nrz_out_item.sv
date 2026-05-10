`ifndef NRZ_OUT_ITEM_SV
`define NRZ_OUT_ITEM_SV

class nrz_out_item extends uvm_sequence_item;

    // The final array of 8-bit bytes written to the ETH FIFO by the FSM
    bit [7:0] unpacked_bytes[];

    `uvm_object_utils_begin(nrz_out_item)
        `uvm_field_array_int(unpacked_bytes, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "nrz_out_item");
        super.new(name);
    endfunction

endclass

`endif