`ifndef FIFO_OUT_SEQ_ITEM_SV
`define FIFO_OUT_SEQ_ITEM_SV

class fifo_out_seq_item extends uvm_sequence_item;
  // --- Captured Data ---
  bit [7:0] fifo_data[];
  
  // --- Captured Status Flags ---
  bit        is_corrupt;
  bit [10:0] invalid_bytes;
  bit [10:0] payload_length;

  `uvm_object_utils_begin(fifo_out_seq_item)
    `uvm_field_array_int(fifo_data, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(is_corrupt, UVM_ALL_ON)
    `uvm_field_int(invalid_bytes, UVM_ALL_ON | UVM_DEC)
    `uvm_field_int(payload_length, UVM_ALL_ON | UVM_DEC)
  `uvm_object_utils_end

  function new(string name = "fifo_out_seq_item"); 
    super.new(name); 
  endfunction
endclass

`endif