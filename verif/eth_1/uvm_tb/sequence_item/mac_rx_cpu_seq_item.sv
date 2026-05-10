`ifndef MAC_RX_CPU_SEQ_ITEM_SV
`define MAC_RX_CPU_SEQ_ITEM_SV

class mac_rx_cpu_seq_item extends uvm_sequence_item;

  // The actual bytes pulled from the external FIFO
  bit [7:0] ext_fifo_data[]; 
  
  // HW Status Metrics
  bit        ext_rst_n_toggled; 
  bit        eth_rx_data_valid_seen;
  bit [10:0] hw_corrupt_packet_counter;
  bit [10:0] hw_valid_eth_frame;

  `uvm_object_utils_begin(mac_rx_cpu_seq_item)
    `uvm_field_array_int(ext_fifo_data, UVM_ALL_ON)
    `uvm_field_int(ext_rst_n_toggled, UVM_ALL_ON)
    `uvm_field_int(eth_rx_data_valid_seen, UVM_ALL_ON)
    `uvm_field_int(hw_corrupt_packet_counter, UVM_ALL_ON)
    `uvm_field_int(hw_valid_eth_frame, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name="mac_rx_cpu_seq_item"); 
    super.new(name); 
  endfunction

endclass

`endif