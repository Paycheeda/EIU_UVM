`ifndef ETH_LOOPBACK_BASE_TEST_SV
`define ETH_LOOPBACK_BASE_TEST_SV

class eth_loopback_base_test extends uvm_test;
  `uvm_component_utils(eth_loopback_base_test)

  eth_loopback_env env;

  function new(string name="eth_loopback_base_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = eth_loopback_env::type_id::create("env", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    // 1. SWAPPED TO THE STRESS SEQUENCE
    eth_tx_stress_seq tx_seq; 

    phase.raise_objection(this);
    
    // 2. CREATE AND START THE STRESS SEQUENCE
    tx_seq = eth_tx_stress_seq::type_id::create("tx_seq");
    tx_seq.start(env.tx_agent.sqr);

    // 3. FIXED THE MASSIVE DELAY
    // Give the PHY loopback a realistic amount of time to drain the final packet 
    #5us; 

    phase.drop_objection(this);
  endtask
endclass

`endif