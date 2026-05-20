`ifndef NRZ_ITEM_SV
`define NRZ_ITEM_SV

class nrz_item extends uvm_sequence_item;

    // Configuration rules for this specific packet (Removed 'rand')
    bit [1:0]  bpw;
    bit        zero_endian;
    bit [11:0] sync_word1;
    bit [11:0] sync_word2;

    // The dynamic array of custom-width words to be serialized (Removed 'rand')
    bit [11:0] payload[];

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

    // ============================================================================
    // CUSTOM RANDOMIZATION (Bypassing free ModelSim limitations)
    // ============================================================================
    function void generate_payload(int size, bit [1:0] current_bpw);
        int max_val;
        
        // Determine mathematical bounds based on Bits Per Word (BPW)
        if (current_bpw == 2'd0)      max_val = 255;  // 8 bits
        else if (current_bpw == 2'd1) max_val = 511;  // 9 bits
        else if (current_bpw == 2'd2) max_val = 1023; // 10 bits
        else                          max_val = 4095; // 12 bits

        payload = new[size];
        foreach(payload[i]) begin
            payload[i] = $urandom_range(0, max_val);
        end
    endfunction

endclass

`endif