`ifndef ETH_LOOPBACK_ENV_SV
`define ETH_LOOPBACK_ENV_SV

class eth_loopback_env extends uvm_env;
  `uvm_component_utils(eth_loopback_env)

  eth_tx_agent            tx_agent;
  eth_rx_app_agent        rx_agent;
  eth_loopback_scoreboard scoreboard;

  function new(string name="eth_loopback_env", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    tx_agent   = eth_tx_agent::type_id::create("tx_agent", this);
    rx_agent   = eth_rx_app_agent::type_id::create("rx_agent", this);
    scoreboard = eth_loopback_scoreboard::type_id::create("scoreboard", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Wire the Monitors to the Scoreboard
    //tx_agent.mon.mon_ap.connect(scoreboard.tx_fifo.analysis_export);
    //rx_agent.mon.mon_ap.connect(scoreboard.rx_fifo.analysis_export);
    tx_agent.mon.mon_ap.connect(scoreboard.tx_export);
    rx_agent.mon.mon_ap.connect(scoreboard.rx_export);
  endfunction
endclass

`endif