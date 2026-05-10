`ifndef MAC_RX_BASE_TEST_SV
`define MAC_RX_BASE_TEST_SV

class mac_rx_base_test extends uvm_test;
  `uvm_component_utils(mac_rx_base_test)

  mac_rx_env     env;
  mac_rx_env_cfg cfg;

  function new(string name = "mac_rx_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // 1. Setup the Environment Configuration
    cfg = mac_rx_env_cfg::type_id::create("cfg");
    cfg.is_phy_active = UVM_ACTIVE;
    cfg.is_cpu_active = UVM_ACTIVE;
    uvm_config_db#(mac_rx_env_cfg)::set(this, "*", "cfg", cfg);
    
    // 2. Build the Environment
    env = mac_rx_env::type_id::create("env", this);
  endfunction

virtual task run_phase(uvm_phase phase);
    mac_rx_phy_seqs phy_seq; 
    mac_rx_cpu_seqs cpu_seq;
    
    phase.raise_objection(this);
    
    phy_seq = mac_rx_phy_seqs::type_id::create("phy_seq");
    cpu_seq = mac_rx_cpu_seqs::type_id::create("cpu_seq");
    
    `uvm_info("TEST", "Starting Parallel Sequences...", UVM_NONE)

    // Launch the Infinite CPU Reader Sequence in the background
    fork
        cpu_seq.start(env.cpu_agnt.sqr);
    join_none
    
    // Launch the Network Pkt Generator in the foreground
    // This command blocks until the sequence finishes handing all items to the driver
    phy_seq.start(env.phy_agnt.sqr); 
    
    // ---> NEW SYNCHRONIZATION LOGIC <---
    `uvm_info("TEST", "Sequence generation complete. Waiting for PHY Driver to drain its mailbox...", UVM_NONE)
    
    // Wait for the physical driver to finish the very last packet and return to IDLE
    wait(env.vif.rx_ctl == 1'b0);
    
    // Give the FSMs, the external FIFO, and the Scoreboard enough time to process the final packet
    #50000; 
    
    `uvm_info("TEST", "Test complete. Dropping objections.", UVM_NONE)
    phase.drop_objection(this);
  endtask
endclass

`endif