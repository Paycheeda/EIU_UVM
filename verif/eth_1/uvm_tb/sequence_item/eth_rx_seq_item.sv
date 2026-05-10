/*class eth_rx_seq_item extends uvm_sequence_item;
  // Dynamic array to hold the continuous stream of bytes
  bit [7:0] packet_data[];

  `uvm_object_utils_begin(eth_rx_seq_item)
    `uvm_field_array_int(packet_data, UVM_ALL_ON | UVM_HEX)
  `uvm_object_utils_end

  function new(string name = "eth_rx_seq_item"); super.new(name); endfunction
endclass*/ //COMMENTED OUT FOR LOOPBACK VERIFICATION , UNCOMMENT WHEN ONLY TX
`ifndef ETH_RX_SEQ_ITEM_SV
`define ETH_RX_SEQ_ITEM_SV

class eth_rx_seq_item extends uvm_sequence_item;
  
  // The dynamic array holding the raw bytes popped out of the MAC
  byte payload[];

  `uvm_object_utils_begin(eth_rx_seq_item)
    `uvm_field_array_int(payload, UVM_ALL_ON | UVM_HEX)
  `uvm_object_utils_end

  function new(string name="eth_rx_seq_item");
    super.new(name);
  endfunction

endclass

`endif