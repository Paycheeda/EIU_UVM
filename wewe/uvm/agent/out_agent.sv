class out_agent extends uvm_agent;
  `uvm_component_utils(out_agent)

  // =============================
  // Constructor Method
  // =============================  
  function new(string name="out_agent", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  out_monitor mntr; // Monitor handle

  // =============================
  // Build Phase Method
  // =============================
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mntr = out_monitor::type_id::create("mntr", this);
  endfunction

  // =============================
  // Connect Phase Method
  // =============================
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

endclass
