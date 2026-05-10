`ifndef ETH_RX_DRIVER_SV
`define ETH_RX_DRIVER_SV

class eth_rx_driver extends uvm_driver #(eth_rx_seq_item);
  `uvm_component_utils(eth_rx_driver)
  
  virtual eth_if vif;

  function new(string name = "eth_rx_driver", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if(!uvm_config_db#(virtual eth_if)::get(this, "", "vif", vif))
      `uvm_fatal("NO_VIF", "Virtual IF not found in RX Driver")
  endfunction

  virtual task run_phase(uvm_phase phase);
    wait(vif.rst_n == 1'b1);
    
    forever begin
      seq_item_port.get_next_item(req);
      @(posedge vif.clk);
      seq_item_port.item_done();
    end
  endtask
endclass

`endif