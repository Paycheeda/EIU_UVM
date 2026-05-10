class chaos_test extends loopback_test; // Inherit your existing working test!
  `uvm_component_utils(chaos_test)

  function new(string name = "chaos_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // We don't even need a build_phase here because loopback_test already builds the env!

  virtual task run_phase(uvm_phase phase);
    chaos_vseq vseq;
    phase.raise_objection(this);
    
    vseq = chaos_vseq::type_id::create("vseq");
    
    // Start it on your virtual sequencer (matching your log outputs)
    vseq.start(vsqncr); 
    
    phase.drop_objection(this);
  endtask
endclass