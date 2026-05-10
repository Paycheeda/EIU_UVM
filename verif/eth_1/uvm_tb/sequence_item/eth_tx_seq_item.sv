`ifndef ETH_TX_SEQ_ITEM_SV
`define ETH_TX_SEQ_ITEM_SV

class eth_tx_seq_item extends uvm_sequence_item;
  // Ethernet & IPv4
  bit [47:0] dest_mac; bit [47:0] source_mac; bit [15:0] eth_type;
  bit [3:0]  version;  bit [3:0]  ihl;        bit [7:0]  tos;
  bit [15:0] total_length; bit [15:0] id;     bit [2:0]  flags;
  bit [12:0] frag_offset;  bit [7:0]  ttl;    bit [7:0]  protocol;
  bit [31:0] src_ip;       bit [31:0] dest_ip;

  rand fault_t fault_type;

  // ---> UDP & Payload <---
  bit [15:0] source_port;
  bit [15:0] dest_port;
  bit [7:0]  payload[]; // Dynamic Array!

  `uvm_object_utils_begin(eth_tx_seq_item)
    `uvm_field_int(dest_mac, UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(src_ip,   UVM_ALL_ON | UVM_HEX)
    `uvm_field_int(source_port, UVM_ALL_ON | UVM_DEC)
    `uvm_field_array_int(payload, UVM_ALL_ON | UVM_HEX)
    `uvm_field_enum(fault_t, fault_type, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "eth_tx_seq_item"); super.new(name); endfunction
endclass
`endif