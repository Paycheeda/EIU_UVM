class out_agent extends uvm_agent;
  `uvm_component_utils(out_agent)

  // =====================================================
  // Constructor
  // =====================================================
  function new(string name="out_agent", uvm_component parent=null);
    super.new(name, parent);
  endfunction : new

  // =====================================================
  // Handles
  // =====================================================
  out_monitor mntr;   // Monitor handle (only monitoring outputs in this agent)

  // =====================================================
  // Build Phase
  // =====================================================
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create output monitor
    mntr = out_monitor::type_id::create("mntr", this);
  endfunction : build_phase

  // =====================================================
  // Connect Phase
  // =====================================================
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // No sequencer/driver here since this agent only *monitors* DUT outputs
  endfunction : connect_phase

endclass : out_agent
