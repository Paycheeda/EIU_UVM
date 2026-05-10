class inp_agent extends uvm_agent;
  `uvm_component_utils(inp_agent)

  // =============================
  // Constructor Method
  // =============================  
  function new(string name="inp_agent", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  inp_monitor                 mntr ; // Monitor handle
  inp_driver                  drvr ; // Driver  handle
  uvm_sequencer #(tx_uart)    sqncr; // Sequencer Handle (Fixed name: tx_uart)

  // =============================
  // Build Phase Method
  // =============================
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // The monitor is ALWAYS built
    mntr = inp_monitor::type_id::create("mntr", this);
    
    // The driver and sequencer are ONLY built if the agent is active
    if (get_is_active() == UVM_ACTIVE) begin
      sqncr = uvm_sequencer#(tx_uart)::type_id::create("sqncr", this); // Fixed name
      drvr  = inp_driver::type_id::create("drvr", this);
    end
  endfunction

  // =============================
  // Connect Phase Method
  // =============================
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    // Only connect if the agent is active (meaning the driver/seq actually exist)
    if (get_is_active() == UVM_ACTIVE) begin
      drvr.seq_item_port.connect(sqncr.seq_item_export);
    end
  endfunction

endclass