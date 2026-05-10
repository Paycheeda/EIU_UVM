`ifndef ETH_RX_BASE_TEST_SV
`define ETH_RX_BASE_TEST_SV

class eth_rx_base_test extends uvm_test;
  `uvm_component_utils(eth_rx_base_test)

  eth_rx_env env;

  function new(string name = "eth_rx_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = eth_rx_env::type_id::create("env", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    eth_rx_master_seq seq; 
    
    phase.raise_objection(this);
    
    seq = eth_rx_master_seq::type_id::create("seq");
    seq.start(env.phy_agnt.sqr); 
    
    #10000; 
    
    phase.drop_objection(this);
  endtask
endclass

`endif