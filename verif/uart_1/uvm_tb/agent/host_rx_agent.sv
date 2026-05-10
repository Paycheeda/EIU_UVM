class host_rx_agent extends uvm_agent;
  `uvm_component_utils(host_rx_agent)

  function new(string name="host_rx_agent", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  host_rx_monitor mntr; 

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    mntr = host_rx_monitor::type_id::create("mntr", this);
    
    
    if (get_is_active() == UVM_ACTIVE) begin
      `uvm_warning("HOST_RX_AGENT", "This agent is designed to be PASSIVE only. Ignoring ACTIVE flag.")
    end
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
  endfunction

endclass