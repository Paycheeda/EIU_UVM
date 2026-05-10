`ifndef RX_FIFO_BASE_TEST_SV
`define RX_FIFO_BASE_TEST_SV

class rx_fifo_base_test extends uvm_test;
  `uvm_component_utils(rx_fifo_base_test)

  rx_fifo_env env;

  function new(string name = "rx_fifo_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = rx_fifo_env::type_id::create("env", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    rx_fifo_master_seq seq; 
    
    phase.raise_objection(this);
    
    seq = rx_fifo_master_seq::type_id::create("seq");
    // Start the sequence on the active Input Agent's sequencer
    seq.start(env.in_agnt.sqr); 
    
    // Give the RTL time to finish its final flush/transfer before ending simulation
    #5000; 
    
    phase.drop_objection(this);
  endtask
endclass

`endif