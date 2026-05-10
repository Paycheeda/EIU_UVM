`ifndef CPU_MAC_AGENT_SV
`define CPU_MAC_AGENT_SV

class cpu_mac_agent extends uvm_agent;
  `uvm_component_utils(cpu_mac_agent)
  
  cpu_mac_driver    drv;
  cpu_mac_monitor   mon;
  uvm_sequencer #(mac_rx_cpu_seq_item) sqr;
  mac_rx_env_cfg    cfg;

  function new(string name="cpu_mac_agent", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    if(!uvm_config_db#(mac_rx_env_cfg)::get(this, "", "cfg", cfg))
      `uvm_fatal("NO_CFG", "Could not get configuration object")
      
    mon = cpu_mac_monitor::type_id::create("mon", this);
    if(cfg.is_cpu_active == UVM_ACTIVE) begin
      drv = cpu_mac_driver::type_id::create("drv", this);
      sqr = uvm_sequencer#(mac_rx_cpu_seq_item)::type_id::create("sqr", this);
    end
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    if(cfg.is_cpu_active == UVM_ACTIVE) begin
      drv.seq_item_port.connect(sqr.seq_item_export);
    end
  endfunction
endclass

`endif