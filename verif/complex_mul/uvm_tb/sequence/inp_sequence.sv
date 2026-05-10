class inp_sequence extends uvm_sequence #(inp_complex);
  `uvm_object_utils(inp_sequence)

  // Child sequence for generating complex numbers
  complex_sequence cnum_seq;

  // Global/common config
  common_config   common_cfg;

  // --------------------------
  // Constructor
  // --------------------------
  function new (string name = "inp_sequence");
    super.new(name);    
  endfunction

  // --------------------------
  // Pre-start Phase
  // --------------------------
  virtual task pre_start();
    if (!uvm_config_db#(common_config)::get(get_sequencer(), "", "common_cfg", common_cfg))
      `uvm_fatal("inp_sequence", "Did not get common_config")
  endtask : pre_start

  // --------------------------
  // Body
  // --------------------------
  virtual task body();
    `uvm_info("inp_sequence", 
              $sformatf("Starting cnum_seq for %0d packets..", 
                        common_cfg.inp_num_cnums), 
              UVM_MEDIUM)

    cnum_seq = complex_sequence::type_id::create("cnum_seq");
    cnum_seq.num_cnums = common_cfg.inp_num_cnums; 
    cnum_seq.start(get_sequencer());
    
    `uvm_info("inp_sequence", "cnum_seq done..", UVM_MEDIUM)
  endtask 

endclass // inp_sequence
