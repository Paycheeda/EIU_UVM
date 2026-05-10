class line_tx_agent extends uvm_agent;
  `uvm_component_utils(line_tx_agent)

  function new(string name="line_tx_agent", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  line_tx_monitor mntr; 

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mntr = line_tx_monitor::type_id::create("mntr", this);
    
    if (get_is_active() == UVM_ACTIVE) begin
      `uvm_warning("LINE_TX_AGENT", "This agent is designed to be PASSIVE only. Ignoring ACTIVE flag.")
    end
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

endclass