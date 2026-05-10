`ifndef ETH_RX_BASE_SEQUENCE_SV
`define ETH_RX_BASE_SEQUENCE_SV

class eth_rx_base_sequence extends uvm_sequence #(eth_rx_seq_item);
  `uvm_object_utils(eth_rx_base_sequence)

  function new(string name = "eth_rx_base_sequence");
    super.new(name);
  endfunction

  virtual task body();
    forever begin
      req = eth_rx_seq_item::type_id::create("req");
      start_item(req);
      finish_item(req);
    end
  endtask
endclass

`endif