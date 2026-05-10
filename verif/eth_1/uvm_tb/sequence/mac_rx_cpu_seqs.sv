`ifndef MAC_RX_CPU_SEQS_SV
`define MAC_RX_CPU_SEQS_SV

class mac_rx_cpu_seqs extends uvm_sequence #(mac_rx_cpu_seq_item);
  `uvm_object_utils(mac_rx_cpu_seqs)

  function new(string name="mac_rx_cpu_seqs"); 
    super.new(name); 
  endfunction

  virtual task body();
    forever begin
        req = mac_rx_cpu_seq_item::type_id::create("req"); 
        start_item(req);
        // We don't need to randomize anything! The driver just needs the object to trigger a read cycle.
        finish_item(req); 
    end
  endtask
endclass

`endif