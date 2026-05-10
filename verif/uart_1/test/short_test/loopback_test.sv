class loopback_test extends uvm_test;
  `uvm_component_utils(loopback_test)

  loopback_uartfifo_env env;
  loopback_vsqncr       vsqncr;
  fifo_config           cfg;
  function new(string name = "loopback_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env    = loopback_uartfifo_env::type_id::create("env", this);
    vsqncr = loopback_vsqncr::type_id::create("vsqncr", this);
    
    // <--- ADD THIS BLOCK --->
    cfg = fifo_config::type_id::create("cfg");
    // If your config has any settings, set them here:
    // cfg.is_active = UVM_ACTIVE; 
    
    // Broadcast it to the universe so the monitors can find it!
    uvm_config_db#(fifo_config)::set(this, "*", "fifo_cfg", cfg);
    // <------------------------>
  endfunction
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Connect the Virtual Sequencer to the physical sequencers deep inside the agents
    vsqncr.tx_sqncr  = env.tx_agnt.sqncr;
    vsqncr.rx_sqncr  = env.rx_agnt.sqncr;
    vsqncr.cfg_sqncr = env.cfg_agnt.sqncr;
  endfunction

  virtual task run_phase(uvm_phase phase);
    loopback_vseq vseq;
    vseq = loopback_vseq::type_id::create("vseq");

    // Raise the objection to keep simulation alive
    phase.raise_objection(this, "Starting Master Loopback Sequence");
    
    // Start the orchestra!
    vseq.start(vsqncr);
    
    // Allow a small drain time for the Scoreboard to process the final packet
    #2000;
    
    // Drop the objection to end simulation
    phase.drop_objection(this, "Finished Master Loopback Sequence");
  endtask
endclass