class loopback_uartfifo_env extends uvm_env;
  `uvm_component_utils(loopback_uartfifo_env)

  fifo_wr_agent         tx_agnt;
  fifo_rd_agent         rx_agnt;
  uart_config_agent     cfg_agnt;
  loopback_uartfifo_scoreboard scrbrd;
  
  uart_physical_monitor phys_mon;

  function new(string name = "loopback_uartfifo_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tx_agnt  = fifo_wr_agent::type_id::create("tx_agnt", this);
    rx_agnt  = fifo_rd_agent::type_id::create("rx_agnt", this);
    cfg_agnt = uart_config_agent::type_id::create("cfg_agnt", this);
    scrbrd   = loopback_uartfifo_scoreboard::type_id::create("scrbrd", this);
    
    phys_mon = uart_physical_monitor::type_id::create("phys_mon", this);
  endfunction
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    tx_agnt.mntr.mon_ap.connect(scrbrd.tx_fifo.analysis_export);
    rx_agnt.mntr.mon_ap.connect(scrbrd.rx_fifo.analysis_export);
    cfg_agnt.mntr.mon_ap.connect(scrbrd.cfg_fifo.analysis_export);
  endfunction
endclass