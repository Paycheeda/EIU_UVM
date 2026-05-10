class uart_config_agent extends uvm_agent;
  `uvm_component_utils(uart_config_agent)

  // Standard Components
  uart_config_driver                     drvr;
  uart_config_monitor                    mntr;
  uvm_sequencer #(uart_config_item)      sqncr; 

  function new(string name = "uart_config_agent", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    mntr = uart_config_monitor::type_id::create("mntr", this);
    
    if (get_is_active() == UVM_ACTIVE) begin
      drvr  = uart_config_driver::type_id::create("drvr", this);
      sqncr = uvm_sequencer#(uart_config_item)::type_id::create("sqncr", this);
    end
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if (get_is_active() == UVM_ACTIVE) begin
      drvr.seq_item_port.connect(sqncr.seq_item_export);
    end
  endfunction
endclass