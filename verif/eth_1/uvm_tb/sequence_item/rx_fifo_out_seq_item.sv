`ifndef RX_FIFO_OUT_SEQ_ITEM_SV
`define RX_FIFO_OUT_SEQ_ITEM_SV

class rx_fifo_out_seq_item extends uvm_sequence_item;
  
  // The array of bytes actually pushed to the external FIFO
  bit [7:0] ext_fifo_data[];
  
  // Status tracking
  bit ext_rst_n_toggled; 
  bit eth_rx_data_valid_seen;
  bit [10:0] corrupt_packet_counter_val;
  bit [10:0] valid_eth_frame_val;

  `uvm_object_utils_begin(rx_fifo_out_seq_item)
    `uvm_field_array_int(ext_fifo_data, UVM_ALL_ON)
    `uvm_field_int(ext_rst_n_toggled, UVM_ALL_ON)
    `uvm_field_int(eth_rx_data_valid_seen, UVM_ALL_ON)
    `uvm_field_int(corrupt_packet_counter_val, UVM_ALL_ON)
    `uvm_field_int(valid_eth_frame_val, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "rx_fifo_out_seq_item");
    super.new(name);
  endfunction

endclass

`endif