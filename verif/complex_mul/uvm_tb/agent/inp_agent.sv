class inp_agent extends uvm_agent;
  `uvm_component_utils(inp_agent)

  // =====================================================
  // Constructor
  // =====================================================
  function new(string name="inp_agent", uvm_component parent=null);
    super.new(name, parent);
  endfunction : new

  // =====================================================
  // Handles
  // =====================================================
  inp_monitor               mntr   ; // Monitor handle
  inp_driver                drvr   ; // Driver handle
  uvm_sequencer #(inp_cuboid) sqncr ; // Sequencer handle

  // =====================================================
  // Build Phase
  // =====================================================
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // Create components
    sqncr = uvm_sequencer#(inp_cuboid)::type_id::create("sqncr", this);
    mntr  = inp_monitor::type_id::create("mntr",  this);
    drvr  = inp_driver::type_id::create("drvr",  this);
  endfunction : build_phase

  // =====================================================
  // Connect Phase
  // =====================================================
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Connect driver to sequencer
    drvr.seq_item_port.connect(sqncr.seq_item_export);
  endfunction : connect_phase

  // =====================================================
  // Main Phase (Optional)
  // =====================================================
  virtual task main_phase(uvm_phase phase);
    `uvm_info("inp_agent", "Starting main phase", UVM_LOW)
    super.main_phase(phase);
    // No special run-time behavior in agent
  endtask : main_phase

endclass : inp_agent
