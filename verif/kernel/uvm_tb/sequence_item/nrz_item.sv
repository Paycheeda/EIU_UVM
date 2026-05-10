`ifndef NRZ_ITEM_SV
`define NRZ_ITEM_SV

class nrz_item extends uvm_sequence_item;

    // Configuration rules for this specific packet
    rand bit [1:0]  bpw;
    rand bit        zero_endian;
    rand bit [11:0] sync_word1;
    rand bit [11:0] sync_word2;

    // The dynamic array of custom-width words to be serialized
    rand bit [11:0] payload[];

    `uvm_object_utils_begin(nrz_item)
        `uvm_field_int(bpw, UVM_ALL_ON)
        `uvm_field_int(zero_endian, UVM_ALL_ON)
        `uvm_field_int(sync_word1, UVM_ALL_ON)
        `uvm_field_int(sync_word2, UVM_ALL_ON)
        `uvm_field_array_int(payload, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "nrz_item");
        super.new(name);
    endfunction

    // Constrain the packet length to reasonable sizes (e.g., 5 to 150 words)
    constraint payload_size_c {
        payload.size() inside {[5:150]};
    }

    // Mathematically constrain the randomly generated bits to match the BPW setting!
    // This prevents generating "dirty" upper bits when we only want 8 or 10-bit words.
    constraint bit_mask_c {
        if (bpw == 2'd0) { // 8 bits
            sync_word1 < 256; sync_word2 < 256;
            foreach(payload[i]) payload[i] < 256;
        }
        if (bpw == 2'd1) { // 9 bits
            sync_word1 < 512; sync_word2 < 512;
            foreach(payload[i]) payload[i] < 512;
        }
        if (bpw == 2'd2) { // 10 bits
            sync_word1 < 1024; sync_word2 < 1024;
            foreach(payload[i]) payload[i] < 1024;
        }
        // If bpw == 3 (12 bits), no mathematical constraint is needed
    }

endclass

`endif