class fifo_standalone_test extends uvm_test;
  `uvm_component_utils(fifo_standalone_test)

  fifo_env    env;
  fifo_config cfg; // <--- ADDED THE CONFIG HANDLE

  function new(string name="fifo_standalone_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // 1. Build the Config Object (It automatically parses the CLI here!)
    cfg = fifo_config::type_id::create("cfg");
    
    // 2. Push it to the database so any agent can grab it if needed
    uvm_config_db#(fifo_config)::set(this, "*", "fifo_cfg", cfg);

    // 3. Build the Environment
    env = fifo_env::type_id::create("env", this);
  endfunction

  virtual task run_phase(uvm_phase phase);
    fifo_wr_sequence wr_seq;
    fifo_rd_sequence rd_seq;

    phase.raise_objection(this);

    `uvm_info("TEST", "Waiting for Hardware Reset...", UVM_LOW)
    #200; 

    #13;

    wr_seq = fifo_wr_sequence::type_id::create("wr_seq");
    rd_seq = fifo_rd_sequence::type_id::create("rd_seq");

    // ========================================================
    // PRO-SAN: PASS THE DYNAMIC CONFIG VALUES TO THE SEQUENCES!
    // ========================================================
    wr_seq.num_packets = cfg.num_fifo_packets;
    rd_seq.num_packets = cfg.num_fifo_packets;

    `uvm_info("TEST", $sformatf("Launching CDC FIFO Stress Test for %0d packets...", cfg.num_fifo_packets), UVM_LOW)

    // FORK: Run both sequences concurrently in different clock domains!
    fork
      begin
        wr_seq.start(env.wr_agnt.sqncr);
      end
      begin
        rd_seq.start(env.rd_agnt.sqncr);
      end
    join

    // Wait a moment for the final data to flush out of the pipeline
    #5000;

    phase.drop_objection(this);
  endtask
endclass